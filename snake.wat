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
    ;; 0-right, 1-down, 2-left, 3-up
    (global $snakeDir (export "snakeDir") (mut i32) (i32.const 0))

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
        i32.const 555
        call $log
        i32.const 0
        call $getSnakeXByOffset
        call $log
        i32.const 500
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

    (export "tick" (func $tick))
    (func $tick
        (local $headX i32)
        (local $headY i32)
        ;; get new head
        i32.const 0
        call $getSnakeXByOffset
        set_local $headX
        i32.const 0
        call $getSnakeYByOffset
        set_local $headY

        get_local $headX
        get_global $snakeDir
        call $getMoveX
        set_local $headX

        get_local $headY
        get_global $snakeDir
        call $getMoveY
        set_local $headY

        get_local $headX
        get_local $headY
        call $snakeUnshift
        call $snakePop
        ;; just restoring, instead we want to push
        ;; i32.const 0
        ;; call $getSnakeXPtrByOffset
        ;; get_local $headX
        ;; i32.store8

        ;; i32.const 0
        ;; call $getSnakeYPtrByOffset
        ;; get_local $headY
        ;; i32.store8


        ;; set it (later implement push / pop system)
    )

    ;; computes a new x, given a movement by 1 in a direction (see snakeDir at top)
    (func $getMoveX (param $oldX i32) (param $direction i32) (result i32)
        (local $tmp i32)
        ;; if direction === 1(down) || direction === 3(up), return oldX
        get_local $direction
        i32.const 1
        i32.const 3
        call $eqOneOf
        if
            get_local $oldX
            return
        end
        ;; if direction === 0(right) or direction === 2(left), perform wrapAdd
        get_local $direction
        i32.eqz
        if
            i32.const 1
            set_local $tmp
        else
            i32.const -1
            set_local $tmp
        end
        get_local $oldX
        get_local $tmp
        get_global $boardWidth
        call $wrapAdd
        return
    )

    ;; computes a new y, given a movement by 1 in a direction (see snakeDir at top)
    (func $getMoveY (param $oldY i32) (param $direction i32) (result i32)
        (local $tmp i32)
        ;; if direction === 0(right) || direction === 2(left), return oldY
        get_local $direction
        i32.const 0
        i32.const 2
        call $eqOneOf
        if
            get_local $oldY
            return
        end
        ;; if direction === 1(down) or direction === 3(up), perform wrapAdd
        get_local $direction
        i32.const 1
        i32.sub
        i32.eqz
        if
            i32.const 1
            set_local $tmp
        else
            i32.const -1
            set_local $tmp
        end
        get_local $oldY
        get_local $tmp
        get_global $boardHeight
        call $wrapAdd
        return
    )

    ;; performs an addition with wrapping arround -1 and $max
    ;; note: $inc should only be  -1 or 1
    ;; eg wrappAdd(2, 1, 3) -> 0
    ;; eg wrappAdd(1, 1, 3) -> 2
    ;; eg wrappAdd(1, -1, 3) -> 0
    ;; eg wrappAdd(0, -1, 3) -> 2
    (func $wrapAdd (param $v i32) (param $inc i32) (param $max i32) (result i32)
        (local $tmp i32)
        get_local $inc
        get_local $v
        i32.add
        get_local $max
        i32.rem_s
        set_local $tmp
        get_local $tmp
        i32.const -1
        i32.sub
        i32.eqz
        if ;; tmp === -1 -> return max-1
            get_local $max
            i32.const 1
            i32.sub
            return
        end
        get_local $tmp
        return
    )

    (export "drawBoard" (func $drawBoard))
    (func $drawBoard
        (local $x i32)
        (local $y i32)
        (local $tmp i32)
        ;; setup x, y
        i32.const 0
        set_local $y

        ;; looping
        loop $yBlock
            ;; loop x
            i32.const 0
            set_local $x
            loop $xBlock

                ;; get coord state
                get_local $x
                get_local $y
                call $computePixelState
                set_local $tmp

                ;; set coord state
                get_local $x
                get_local $y
                get_local $tmp
                call $setPixel

                ;; inc x
                i32.const 1
                get_local $x
                i32.add
                set_local $x

                ;; break if less than
                get_local $x
                get_global $boardHeight
                i32.lt_s
                br_if $xBlock
            end
            ;; end loop x

            ;; inc y
            i32.const 1
            get_local $y
            i32.add
            set_local $y

            ;; break if less than
            get_local $y
            get_global $boardHeight
            i32.lt_s
            br_if $yBlock
        end
    )

    ;; get block pixel type (0-blank, 1-snake, 2-cherry)
    (func $computePixelState (param $x i32) (param $y i32) (result i32)
        (local $snakeHeadX i32)
        (local $snakeHeadY i32)
        get_local $x
        get_local $y
        get_global $cherryX
        get_global $cherryY
        call $posEq
        if
            i32.const 2
            return
        end
        get_local $x
        get_local $y
        call $touchingSnake
        i32.eqz
        if
            i32.const 0
            return
        end
        i32.const 1
        return
    )

    (func $posEq (param $x1 i32) (param $y1 i32) (param $x2 i32) (param $y2 i32) (result i32)
        (local $xEq i32)
        (local $yEq i32)
        get_local $x1
        get_local $x2
        i32.sub
        i32.eqz
        i32.eqz
        if ;; if x1 != x2
            i32.const 0
            return
        end
        get_local $y1
        get_local $y2
        i32.sub
        i32.eqz
        return
    )

    ;; sets a pixel value
    (func $setPixel (param $x i32) (param $y i32) (param $v i32)
        (local $idx i32)
        get_global $boardWidth
        get_local $y
        i32.mul
        get_local $x
        i32.add
        get_local $v
        i32.store8
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

    ;; check if point collides with snake
    ;; returns 0 if not touching
    ;; returns 1 if touching head
    ;; returns 2 if touching body
    (func $touchingSnake (param $x i32) (param $y i32) (result i32)
        (local $i i32)
        (local $sx i32)
        (local $sy i32)
        ;; loop through all snake body parts
        i32.const 0
        set_local $i
        loop $loopStart
            ;; get snake pos at offset $i
            get_local $i
            call $getSnakeXByOffset
            set_local $sx
            get_local $i
            call $getSnakeYByOffset
            set_local $sy

            ;; if pos equal to x, y
            get_local $x
            get_local $y
            get_local $sx
            get_local $sy
            call $posEq
            if
                get_local $i
                i32.eqz
                if
                    i32.const 1
                    return
                end
                i32.const 2
                return
            end

            ;; increment $i
            get_local $i
            i32.const 1
            i32.add
            set_local $i

            ;; loop back again if $i < $snakeLength
            get_local $i
            get_global $snakeLength
            i32.lt_s
            br_if $loopStart
        end
        i32.const 0
        return
    )

    ;; set snakeX by offset
    (func $setSnakeXByOffset (param $offset i32) (param $newX i32)
        get_local $offset
        call $getSnakeXPtrByOffset
        get_local $newX
        i32.store8
    )
    ;; set snakeY by offset
    (func $setSnakeYByOffset (param $offset i32) (param $newY i32)
        get_local $offset
        call $getSnakeYPtrByOffset
        get_local $newY
        i32.store8
    )
    ;; get snakeX by offset
    (func $getSnakeXByOffset (param $offset i32) (result i32)
        get_local $offset
        call $getSnakeXPtrByOffset
        i32.load8_s
    )
    ;; get snakeY by offset
    (func $getSnakeYByOffset (param $offset i32) (result i32)
        get_local $offset
        call $getSnakeYPtrByOffset
        i32.load8_s
    )
    
    ;; get snakeY ptr by offset
    (func $getSnakeYPtrByOffset (param $offset i32) (result i32)
        get_local $offset
        call $getSnakeXPtrByOffset ;; yes, use x, since y is right after
        i32.const 1
        i32.add
    )

    ;; get snakeX ptr by offset
    (func $getSnakeXPtrByOffset (param $offset i32) (result i32)
        (local $tmp i32)
        (local $maxSnakeLen2 i32)
        get_global $maxSnakeLen
        i32.const 2
        i32.add
        set_local $maxSnakeLen2
        ;; x = ptr + ((snakeOffset + offset) * 2) % (maxSnakeLen * 2)
        get_global $snakeOffset
        get_local $offset
        i32.add
        i32.const 2
        i32.mul
        get_local $maxSnakeLen2
        i32.rem_s
        call $getSnakeBodyPtr
        i32.add
        return
    )

    (func $getSnakeBodyPtr (result i32)
        get_global $boardWidth
        get_global $boardHeight
        i32.mul
        return
    )

    ;; unshift new x,y position onto snake head
    (func $snakeUnshift (param $x i32) (param $y i32)
        ;; decrease offset
        get_global $snakeOffset
        i32.const -1
        get_global $maxSnakeLen
        call $wrapAdd
        set_global $snakeOffset
        ;; increase length
        get_global $snakeLength
        i32.const 1
        i32.add
        set_global $snakeLength
        ;; set new position
        i32.const 0 ;; set head
        get_local $x
        call $setSnakeXByOffset
        i32.const 0 ;; set head
        get_local $y
        call $setSnakeYByOffset
    )
    ;; pop x,y position from snake tail
    (func $snakePop
        ;; increase offset
        ;; get_global $snakeOffset
        ;; i32.const 1
        ;; get_global $maxSnakeLen
        ;; call $wrapAdd
        ;; set_global $snakeOffset
        ;; decrease length
        get_global $snakeLength
        i32.const 1
        i32.sub
        set_global $snakeLength
    )

    ;; returns 1 if v==a || v == b, else 0
    (func $eqOneOf (param $v i32) (param $a i32) (param $b i32) (result i32)
        get_local $v
        get_local $a
        i32.sub
        i32.eqz
        if
            i32.const 1
            return
        end
        get_local $v
        get_local $b
        i32.sub
        i32.eqz
        return
    )

    ;; returns 1 if a==b, else 0
    (func $eqTo (param $a i32) (param $b i32) (result i32)
        get_local $a
        get_local $b
        i32.sub
        i32.eqz
        return
    )
)
