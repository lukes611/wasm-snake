(module
    ;; memory
    (import "env" "memory" (memory 1))
    ;; Memory plan:
    ;; boardWidth*boardHeight bytes = board
    ;; snake body positions 
    ;; board width & height

    ;; system functionality
    ;; eg pixelOut(x, y, 2 | 1 | 0) (2=cherry, 1=snake, 0=blank)
    (import "env" "pixelOut" (func $pixelOut (param i32) (param i32) (param i32)))
    (import "env" "log" (func $log (param i32)))
    (import "env" "random" (func $random (result f32)))
    (import "env" "abort" (func $abort (param i32)))

    (global $boardWidth (import "env" "boardWidth") (mut i32))
    (global $boardHeight (import "env" "boardHeight") (mut i32))

    (global $snakeLength (export "snakeLength") (mut i32) (i32.const 1))
    (global $snakeOffset (export "snakeOffset") (mut i32) (i32.const 0))
    (global $maxSnakeLen (export "maxSnakeLen") (mut i32) (i32.const 15))

    (global $cherryX (export "cherryX") (mut i32) (i32.const 0))
    (global $cherryY (export "cherryY") (mut i32) (i32.const 0))
    
    ;; functionality
    (export "add" (func $add))
    (func $add (param $a i32) (param $b i32) (result i32)
        i32.const 0
        i32.const 2
        get_global $boardWidth
        call $pixelOut
        get_local $a
        get_local $b
        i32.add
        return    
    )

    (export "test" (func $test))
    (func $test (param $a i32) (result i32)
        (local $tmp i32)
        i32.const 43
        call $log
        i32.const 10
        call $randInt
        set_local $tmp
        i32.const 0
        get_local $tmp
        i32.store8
        get_local $tmp
        return
    )

    (export "init" (func $init))
    (func $init
        (local $sptr i32)
        (local $tmp i32)
        ;; set snake head position randomly
        call $getSnakeBodyPtr
        set_local $sptr

        ;; random snake head
        get_local $sptr
        call $randBoardX
        i32.store8
        get_local $sptr
        i32.const 1
        i32.add
        call $randBoardY
        i32.store8

        ;; random cherry
        call $randBoardX
        set_global $cherryX
        call $randBoardY
        set_global $cherryY
    )

    (export "drawBoard" (func $drawBoard))
    (func $drawBoard
        (local $x i32)
        (local $y i32)
        ;; setup x, y
        i32.const 0
        set_local $y

        ;; looping
        loop $yBlock
            ;; inc y
            i32.const 1
            get_local $y
            i32.add
            set_local $y

            ;; loop x
            i32.const 0
            set_local $x
            loop $xBlock

                ;; inc x
                i32.const 1
                get_local $x
                i32.add
                set_local $x

                ;; break if less than
                get_local $x
                get_global $boardHeight
                i32.lt_s
                br_if $yBlock
            end
            ;; end loop x


            ;; break if less than
            get_local $y
            get_global $boardHeight
            i32.lt_s
            br_if $yBlock
        end
        ;; loop y
        ;; loop x

    )

    ;; get a random x pos on the board
    (func $randBoardX (result i32)
        get_global $boardWidth
        call $randInt
        return
    )

    ;; get a random y pos on the board
    (func $randBoardY (result i32)
        get_global $boardHeight
        call $randInt
        return
    )

    ;; get a random integer between 0 and $max
    (func $randInt (param $max i32) (result i32)
        (local $maxf f32)
        get_local $max
        f32.convert_i32_s
        set_local $maxf
        call $random
        get_local $maxf
        f32.mul
        f32.floor
        i32.trunc_f32_s
        return
    )

    ;; (func $setSnake)

    (func $getSnakeBodyPtr (result i32)
        get_global $boardWidth
        get_global $boardHeight
        i32.mul
        return
    )
)
