section .data
table: db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/00="

section .text

; Need to make it global so it can be accessed in another file with extern
global base64_encode

; can use rdi, rsi, rdx, rcx, r8, r9, r10 and r11
base64_encode:
        ; edi receives first arg
        ; esi receives second

        mov r8d, esi
        mov r9d, esi
        mov r10d, esi
        mov r11d, esi

        and r8d, 0x3f

        shr r9d, 0x6
        and r9d, 0x3f

        shr r10d, 0xc
        and r10d, 0x3f

        shr r11d, 0x10
        and r11d, 0x3f

        ; put return in eax
        mov eax, edx
        

        ret

