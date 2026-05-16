; 07c00-07dff : bootloader
; 07e00-07fff : temporary file table
; 10000-10200 : kernel

file_table = 0x7e00

.offset 0x7c00

; bootloader will assume that it is loaded from disk 0
; because the bios doesn't even check other disks
boot {
    mov bx, start_log
    call print_raw

    ; check if disk actually works
    ; rare case it doesnt work
    ; since if the disk doesn't work then this bootloader probably wouldnt run anyway
    mov dx, 0
    int 0x13
    cmp ax, 0
    jnz disk_fail

    ; load sector 1 (file table)
    mov ax, 1
    mov cx, 0
    mov dx, 4
    int 0x13

    mov bx, file_table
    mov dx, 1
    int 0x13
    cmp ax, 0
    jnz disk_fail

    mov bx, load_log
    call print_raw

    call find_kernel

    cmp bx, 34
    jz no_kernel

    ; load kernel
    mov ax, bx
    mov cx, 0
    mov dx, 4
    int 0x13

    mov ds, 0x1000
    mov bx, 0
    mov dx, 1
    int 0x13
    mov ds, 0
    cmp ax, 0
    jnz disk_fail

    mov ds, 0x1000
    mov ss, ds
    mov es, ds
    jmpf 0x1000, 0

}

; bx -> location of kernel
; 34 if not found
; affects all gpr
find_kernel {
    mov bx, 2
    mov cx, 31
    mov ax, 0x7e00

    loop:
        mov dx, boot_target
        call strcmp

        cmp dx, 0
        jz done

        add ax, 0x10
        add bx, 1
        sub cx, 1
        
        cmp cx, 0
        jnz loop ; continue

        add bx, 1

    done:
        ret

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

disk_fail {
    mov bx, disk_fail_err
    call print_raw
    hlt
}

no_kernel {
    mov bx, no_kernel_err
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

disk_fail_err:  .asciiz "Disk Failure\r\n"
no_kernel_err:  .asciiz "No Kernel found\r\n"

start_log:  .asciiz "MiniOS Boot\r\n"
load_log:   .asciiz "Loading\r\n\r\n"

boot_target: .asciiz "KERNEL"
