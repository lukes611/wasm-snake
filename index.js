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
    const snakeData = new Int8Array(memory.buffer, boardWidth.value * boardHeight.value + 0);

    // const I = 15;
    // instance.exports.init();
    // instance.exports.maxSnakeLen.value = 15;
    // const O = boardWidth.value * boardHeight.value;
    // const ptr = (((I + instance.exports.snakeOffset.value)) % instance.exports.maxSnakeLen.value) * 2 + O;
    // const ptr2 = instance.exports.getSnakeXPtrByOffset(I);
    // boardData[ptr] = 34;
    // const x2 = instance.exports.getSnakeXByOffset(I);
    // const x = boardData[ptr];
    // console.log(ptr, ptr2)
    // console.log(x, x2)

    // return;

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
        console.log('00 -> ', boardData[0]);
        for (let y = 0; y < boardHeight.value; y++) {
            for (let x = 0; x < boardWidth.value; x++) {
                const v = boardData[y * boardWidth.value + x];
                let color = 'black'; // blank
                if (v === 1) { // snake
                    color = 'green';
                } else if (v === 2) { // cherry
                    color = 'red';
                }
                // ctx.beginPath();
                ctx.fillStyle = color;
                ctx.fillRect(x * blockSize, y * blockSize, blockSize, blockSize);
                // ctx.closePath();

            }
        }
    }

    setInterval(() => {
        drawBoard();
        instance.exports.tick();
        instance.exports.drawBoard();
        // console.log('offset', instance.exports.snakeOffset.value);
        // console.log('len', instance.exports.snakeLength.value);
        // console.log('snake.x = ', snakeData[
        //     (instance.exports.snakeOffset.value * 2) % instance.exports.maxSnakeLen.value
        // ]);
        // printSnake();
    }, 100);

    function printSnake() {
        const offset = instance.exports.snakeOffset.value;
        const snakeLen = instance.exports.snakeLength.value;
        const maxLen = instance.exports.maxSnakeLen.value;
        const out = [];
        const out2 = [];
        console.log('offset=', offset);
        console.log('len=', snakeLen);
        for (let i = 0; i < snakeLen; i++) {
            const ptr = (i + offset) % maxLen;
            const x = snakeData[ptr * 2];
            const y = snakeData[ptr * 2 + 1];
            out.push(`${x},${y}`);
            const x2 = instance.exports.getSnakeXByOffset(i);
            if (x !== x2) {
                const O = boardWidth.value * boardHeight.value;
                const _ = instance.exports.getSnakeXPtrByOffset(i);
                const __ = ptr * 2 + O;
                debugger;
            }
        }
        console.log('snake=\n');
        console.log(out.join('\n'));
        
    }
    function printSnake2() {
        const offset = instance.exports.snakeOffset.value;
        const snakeLen = instance.exports.snakeLength.value;
        const maxLen = instance.exports.maxSnakeLen.value;
        const out = [];
        console.log('offset=', offset);
        console.log('len=', snakeLen);
        for (let i = 0; i < maxLen; i++) {
            const ptr = (i + offset) % maxLen;
            const x = snakeData[i * 2];
            const y = snakeData[i * 2 + 1];
            out.push(x);
            out.push(y);
        }
        console.log('snake=', out.map(x=>x.toString()).map(x => x.length ===1?'0'+x:x).join(' '));
        // console.log(outy.join(' '));
    }
    
    document.addEventListener('keydown', (e) => {
        const newDir = ['ArrowRight', 'ArrowDown', 'ArrowLeft', 'ArrowUp'].indexOf(e.key);
        if (newDir === -1) return;
        instance.exports.snakeDir.value = newDir;
    });
}
main();
