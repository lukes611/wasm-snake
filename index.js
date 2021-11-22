async function main() {
    const wasmFile = await fetch('./snake.wasm').then(r => r.arrayBuffer());

    const memory = new WebAssembly.Memory({ initial: 1 });
    const boardWidth = new WebAssembly.Global({value:'i32', mutable:true}, 24);
    const boardHeight = new WebAssembly.Global({value:'i32', mutable:true}, 24);
    const { instance } = await WebAssembly.instantiate(wasmFile, {
        env: {
            memory,
            boardWidth,
            boardHeight,
            pixelOut: (x, y, pixelType) => {
                console.log(x, y, pixelType);
            },
            log: x => console.log(x),
            random: () => Math.random(),
            abort: code => {
                throw new Error(`Aborted, code: ${code}`);
            },
        },
    });
    const boardData = new Uint8Array(memory.buffer);
    const snakeData = new Int8Array(memory.buffer, boardWidth.value * boardHeight.value);

    console.log(instance);
    console.log(instance.exports.add(5, 6));
    console.log(instance.exports.test(15));
    console.log(instance.exports.init());
    console.log(boardData[0]);

    console.log('snake start', snakeData[0], snakeData[1]);
    console.log('cherry start', instance.exports.cherryX.value, instance.exports.cherryY.value);

    const canvas = document.createElement('canvas');
    instance.exports.drawBoard();
    console.log('fin');
    document.body.appendChild(canvas);
    const blockSize = 8;
    canvas.width = boardWidth.value * blockSize;
    canvas.height = boardHeight.value * blockSize;
    const ctx = canvas.getContext('2d');
    function drawBoard() {
        for (let y = 0; y < boardHeight.value; y++) {
            for (let x = 0; x < boardWidth.value; x++) {
                const v = boardData[y * boardWidth.value + x];
                let color = 'black'; // blank
                if (v === 1) { // snake
                    color = 'green';
                } else if (v === 2) { // cherry
                    color = 'red';
                }
                ctx.beginPath();
                ctx.fillStyle = color;
                ctx.fillRect(x * blockSize, y * blockSize, blockSize, blockSize);
                ctx.closePath();
            }
        }
    }

    setInterval(() => {
        instance.exports.tick();
        instance.exports.drawBoard();
        // console.log('offset', instance.exports.snakeOffset.value);
        // console.log('len', instance.exports.snakeLength.value);
        // console.log('snake.x = ', snakeData[
        //     (instance.exports.snakeOffset.value * 2) % instance.exports.maxSnakeLen.value
        // ]);
        drawBoard();
    }, 200);
    
    setTimeout(() => {
        console.log(instance.exports.snakeDir)
        
        // instance.exports.snakeDir.value = 1;
    }, 1000);
    document.addEventListener('keydown', (e) => {
        const newDir = ['ArrowRight', 'ArrowDown', 'ArrowLeft', 'ArrowUp'].indexOf(e.key);
        if (newDir === -1) return;
        instance.exports.snakeDir.value = newDir;
    });
}
main();
