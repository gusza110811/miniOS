; assume kernel is loaded to 1000:0000
; with all segments set to 1000

KERNEL_SEGMENT = 0x1000
PROGRAM_SEGMENT = 0x2000

file_table = 0x8000

input_buffer = 0x8200

kload {
    mov bx, splash
    call print_raw

    ; load interrupt vectors
    mov ax, ivt
    mov dx, 0x80
    mov es, 0
    mov cx, ivt_length
    call memcpy

    ; load sector 1 (file table)
    call read_table

    call list_file
}

kmain {

    mov ax, 0
    mov [input_buffer], ax

    ; prompt
    mov bx, prompt
    call print_raw
    mov bx, input_buffer
    call input

    mov ax, [input_buffer]
    cmp ax, 0
    jz kmain

    mov dx, input_buffer
    call find_file
    cmp bx, 32
    jz kmain

    mov ax, bx
    mov bx, 0
    mov ds, PROGRAM_SEGMENT
    call load
    mov ds, KERNEL_SEGMENT

    call run_file

}

read_table {
    pusha

    mov ax, 1
    mov cx, 0
    mov dx, 4
    int 0x13

    mov bx, file_table
    mov dx, 1
    int 0x13
    cmp ax, 0
    jnz disk_fail

    popa
    ret
}

list_file {
    pusha
    mov bx, file_table
    mov cx, 31

    loop:
        mov ax, [b bx]
        cmp ax, 0
        jz skip
        call print_raw
        call newline
        skip:
        add bx, 0x10
        sub cx, 1
        cmp cx, 0
        jnz loop

    popa
    ret

}

; dx <- filename
; bx -> location
; find index of file
; 32 if not found
find_file {
    mov bx, 0
    mov cx, 31
    mov ax, file_table

    loop:
        push dx
        call strcmp

        cmp dx, 0
        jz done
        pop dx

        add ax, 0x10
        add bx, 1
        sub cx, 1
        
        cmp cx, 0
        jnz loop ; continue

        push dx

        add bx, 1

    done:
        pop dx
        ret

}

; ax <- file index
; bx <- load address
load {
    pusha
    add ax, 2
    mov cx, 0
    mov dx, 4
    int 0x13

    mov dx, 1
    int 0x13
    mov ds, 0
    cmp ax, 0
    jnz disk_fail
    popa
    ret
}

; bx <- pointer to buffer
input {
    pusha
    loop:
    mov dx, 0xffff
    in ax, dx
    cmp ax, 0
    jz loop

    cmp ax, '\b'
    bz bksp

    cmp ax, '\n'
    jz crlf

    cmp ax, '\r'
    jz crlf

    out dx, ax

    mov [b bx], ax
    add bx, 1
    jmp loop

    ; affect cx
    crlf {
        mov cx, '\r'
        out dx, cx
        mov cx, '\n'
        out dx, cx
        mov cx, 0
        mov [b bx], cx
        popa
        ret
    }

    ; affect cx, bx--
    bksp {
        mov cx, ' '
        out dx, ax
        out dx, cx
        out dx, ax
        sub bx, 1
        mov ax, [b bx]
        jmp loop
    }
}

; assume the binary loaded at 20000
; sets all segment to 2000
; then far jump to 2000:0000
run_file {
    mov ds, PROGRAM_SEGMENT
    mov ss, ds
    mov es, ds
    mov bp, 0
    mov sp, 0
    jmpf PROGRAM_SEGMENT, 0
}

; ax <- string 0
; dx <- string 1
; dx -> result
; 0 -> equal, 1 -> not equal
strcmp {
    push ax
    push bx
    push cx
    mov bx, 1
    push bx
    loop:
        mov bx, dx
        mov cx, [b bx]
        mov bx, ax
        mov bx, [b bx]

        cmp bx, cx
        jnz nequal

        cmp bx, 0
        jz equal

        add ax, 1
        add dx, 1

        jmp loop

    equal:
        pop dx
        mov dx, 0
        push dx
    nequal:
        popa
        ret

}

; ax <- source
; ds <- source segment
; dx <- dest
; es <- dest segment
; cx -> length
memcpy {
    ; gonna do some fuckery with base pointer

    pusha
    push bp

    mov bx, ax
    mov bp, dx

    loop:
        sub cx, 1
        cmp cx, 0
        jz done
        mov ax, [b bx]
        mov [b es:bp], ax
        add bx, 1
        add bp, 1
    jmp loop
    done:
    
    pop bp
    popa
    ret
}

reset {
    mov ds, KERNEL_SEGMENT
    mov ss, ds
    mov es, ds

    mov bp, 0
    mov sp, 0

    jmp kmain
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

newline {
    pusha
    mov dx, 1
    mov ax, '\r'
    int 0x14
    mov ax, '\n'
    int 0x14
    popa
    ret
}

disk_fail {
    mov bx, disk_fail_err
    call print_raw
    hlt
}

ivt {
    .offset 0x20*4

    ; int 0x20
    .word reset
    .word KERNEL_SEGMENT

    ; int 0x21
    .word find_file
    .word KERNEL_SEGMENT

    ; int 0x22
    .word load
    .word KERNEL_SEGMENT

    ;int 0x21
    .word
    .word KERNEL_SEGMENT

}
ivt_end:
ivt_length = ivt_end-ivt

disk_fail_err:  .asciiz "Disk Fail\r\n"

prompt:     .asciiz "run > "

splash:     .asciiz "MiniOS\r\n"
