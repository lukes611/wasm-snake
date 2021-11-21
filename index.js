async function main() {
    const wasmFile = await fetch('./snake.wasm').then(r => r.arrayBuffer());

    const memory = new WebAssembly.Memory({ initial: 1 });
    const boardWidth = new WebAssembly.Global({value:'i32', mutable:true}, 25);
    const boardHeight = new WebAssembly.Global({value:'i32', mutable:true}, 25);
    const { instance } = await WebAssembly.instantiate(wasmFile, {
        env: {
            memory,
            boardWidth,
            boardHeight,
            pixelOut: (x, y, pixelType) => {
                console.log(x, y, pixelType);
            }
        },
    });
    console.log(instance);
    console.log(instance.exports.add(5, 6));
}
main();
