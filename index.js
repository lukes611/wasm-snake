async function main() {
    const wasmFile = await fetch('./snake.wasm').then(r => r.arrayBuffer());
    const memory = new WebAssembly.Memory({ initial: 1 });
    const boardWidth = new WebAssembly.Global({ value: 'i32', mutable: true }, 24);
    const boardHeight = new WebAssembly.Global({ value: 'i32', mutable: true }, 24);
    const { instance } = await WebAssembly.instantiate(wasmFile, {
        env: {
            memory,
            boardWidth,
            boardHeight,
            log: x => console.log(x),
            random: () => Math.random(),
            abort: code => {
                throw new Error(`Aborted, code: ${code}`);
            },
            gameOver: () => {
                resetGameButton.style.display = 'block';
                gameOverMessage.style.display = 'block';
            },
        },
    });
    const rawBoardMemory = new Uint8Array(memory.buffer);
    const renderer = createRasterRenderer(
        boardWidth.value,
        boardHeight.value,
        rawBoardMemory,
        new Map([
            [0, 'black'], // nothing
            [1, 'green'], // green for snake
            [2, 'red'], // red for cherry
        ]),
    );

    console.log(instance.exports.init());

    // draw board
    createRasterRenderer();

    setInterval(() => {
        renderer.update();
        instance.exports.tick();
    }, 150);

    document.addEventListener('keydown', (e) => {
        const newDir = ['ArrowRight', 'ArrowDown', 'ArrowLeft', 'ArrowUp'].indexOf(e.key);
        if (newDir === -1) return;
        instance.exports.snakeDir.value = newDir;
    });

    function createRasterRenderer(W, H, boardData, colorMappings, BS = 20) {
        const canvas = document.createElement('canvas');
        document.body.appendChild(canvas);

        const blockSize = BS;
        canvas.width = W * blockSize;
        canvas.height = H * blockSize;
        const ctx = canvas.getContext('2d');
        return {
            update() {
                for (let y = 0; y < H; y++) {
                    for (let x = 0; x < W; x++) {
                        const v = boardData[y * W + x];
                        const color = colorMappings.get(v) || 'black;'
                        ctx.fillStyle = color;
                        ctx.fillRect(x * blockSize, y * blockSize, blockSize, blockSize);
                    }
                }
            }
        };
    }

    const gameOverMessage = document.createElement('h4');
    gameOverMessage.innerText = 'game over';
    document.body.appendChild(gameOverMessage);
    gameOverMessage.style.display = 'none';
    
    const resetGameButton = document.createElement('button');
    resetGameButton.innerText = 'reset';
    document.body.appendChild(resetGameButton);
    resetGameButton.onclick = () => {
        resetGameButton.style.display = 'none';
        gameOverMessage.style.display = 'none';
        instance.exports.init();
    };
    resetGameButton.style.display = 'none';

}
main();
