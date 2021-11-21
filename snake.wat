(module
    ;; memory
    (import "env" "memory" (memory 1))
    ;; board width & height
    (global $boardWidth (import "env" "boardWidth") (mut i32))
    (global $boardHeight (import "env" "boardHeight") (mut i32))
    ;; system functionality
    ;; eg pixelOut(x, y, 2 | 1 | 0) (2=cherry, 1=snake, 0=blank)
    (import "env" "pixelOut" (func $pixelOut (param i32) (param i32) (param i32)))
    (export "add" (func $add))
    (func $add (param $a i32) (param $b i32) (result i32)
        i32.const 0
        i32.const 2
        i32.const 1
        call $pixelOut
        get_local $a
        get_local $b
        i32.add
        return    
    )
)
