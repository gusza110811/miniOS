; program shouldnt assume their cs
; but the a program started by the kernel
; is always at 2000:0000

main {
    mov bx, text
    call print_raw

    int 0x20 ; back to kernel shell
}

; does not convert LF to CRLF
; bx <- string
print_raw {
    pusha
    mov dx, 1

    loop:
        mov ax, [b bx]
        cmp ax, 0
        jz done
        int 0x14
        add bx, 1
        jmp loop

    done:
    popa
    ret
}

text:   .asciiz "Hello, World!\r\n"
