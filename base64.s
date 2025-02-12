section .data
table: db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="

section .text

; Need to make it global so it can be accessed in another file with extern
; this function receives (uint32_t, uint32_t)
; with first parameter being the number of bytes to base64 encode (can be 1 to 3)
; and the second parameter contains the bytes in big endian order, with the first 8 bits
; being ignored
; it is the responsibility of the caller to make sure there is no trash in bytes 2 and 3 in case
; only 1 or 2 bytes are being encoded (though maybe this should change)
global base64_encode

get_encoded_byte:
        ; arg at dil, make sure to clean rdi before getting addr
        and rdi, 0x1ff
        lea rax, [rel table]
        mov al, [rax + rdi]
        ret

; can use rdi, rsi, rdx, rcx, r8, r9, r10 and r11
base64_encode:
        ; edi receives first arg
        ; esi receives second
        push r12

        mov r12d, edi

        mov r8d, esi
        mov r9d, esi
        mov r10d, esi
        mov r11d, esi

        shr r8d, 0x12
        and r8b, 0x3f
        mov dil, r8b
        call get_encoded_byte
        mov r8b, al
        shl r8, 8

        shr r9d, 0xc
        and r9b, 0x3f
        mov dil, r9b
        call get_encoded_byte
        mov r8b, al
        shl r8, 8

        cmp r12d, 1
        jz fill2

        shr r10d, 0x6
        and r10b, 0x3f
        mov dil, r10b
        call get_encoded_byte
        mov r8b, al
        shl r8, 8

        cmp r12d, 2
        jz fill1

        and r11b, 0x3f
        mov dil, r11b
        call get_encoded_byte
        mov r8b, al
        jmp encode_ret

fill2:
        ; special char
        mov rdi, 0x40
        call get_encoded_byte
        mov r8b, al
        shl r8, 8
fill1:
        ; special char
        mov rdi, 0x40
        call get_encoded_byte
        mov r8b, al

encode_ret:
        ; put return in eax
        mov eax, r8d

        pop r12

        ret

