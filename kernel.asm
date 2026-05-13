; assume kernel is loaded to 1000:0000
; with all segments set to 1000

kmain {
    mov bx, text
    call print_raw
    hlt
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

text:   .asciiz "Hi from kernel\r\n"
