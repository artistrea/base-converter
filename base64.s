%macro declare_sequence 2
; %1 = starting value, %2 = number of bytes
%assign current %1
%rep %2
    db current
    %assign current current + 1
%endrep
%endmacro


segment .data
table: db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="

; we can rely on the fact that we know all input chars,
; their ascii codes and their input counterpart
; +<>43; /<>47; [0-9]<>[48-57]; =<>61; [A-Z]<>[65-90]; [a-z]<>[97-122];
decode_table:
        times 43 db 0x00
        db 62
        times (47-44) db 0x00
        db 63
        declare_sequence 52, 10
        times (61-58) db 0x00
        db 0x00 ; padding here, not sure yet on how to deal with it
        times (65-62) db 0x00
        declare_sequence 0, 26
        times (97-91) db 0x00
        declare_sequence 26, 26

segment .text

; Need to make it global so it can be accessed in another file with extern
; this function receives (uint32_t, uint32_t)
; with first parameter being the number of bytes to base64 encode (can be 1 to 3)
; and the second parameter contains the bytes in big endian order, with the first 8 bits
; being ignored
; WARNING: it is the responsibility of the caller to make sure there is
; no trash in bytes 2 and 3 in case only 1 or 2 bytes are being encoded
global _base64_encode, _base64_decode

_base64_encode:
        push ebp
        mov ebp, esp

        ; zerando o registrador de retorno
        xor eax, eax

        ; Para termos código independente de posição
        ; não podemos simplesmente fazer `mov ecx, table`, pois
        ; o segmento de texto dependeria de um endereço de memória que não
        ; se sabe qual em tempo de compilação,
        ; e o segmento de código, que deveria ser read-only, terá que ser modificado em runtime
        ; gerando o aviso "warning: relocation in read-only section `.text'"
        ; mov ecx, table
        ; ^ ao invés disso, utilizamos o seguinte truque para calcular o endereço em runtime
        call get_runtime_addr1
get_runtime_addr1:
        ; realizando o pop do endereço de retorno para ecx, temos o endereço de `get_runtime_addr1`
        ; em tempo de execução
        pop ecx
        ; já se sabe o valor do offset `table - get_runtime_addr1` em tempo de compilação
        ; então obtemos o endereço de `table` em tempo de execução
        add ecx, table - get_runtime_addr1

        ; pegando o segundo argumento
        mov edx, [ebp+12]
        ; pegar o primeiro byte (de 3)
        shr edx, 0x12
        ; pegar apenas os 6 bits menos significativos
        and edx, 0x3f
        ; pegar o byte correto na tabela com offset edx
        ; e preenche os outros bits com 0
        movzx edx, byte [ecx + edx]
        ; posicionando como o primeiro byte (de 4)
        shl edx, 0x18
        ; adicionando ao resultado de retorno
        or eax, edx

        mov edx, [ebp+12]
        shr edx, 0xc
        and edx, 0x3f
        movzx edx, byte [ecx + edx]
        shl edx, 0x10
        or eax, edx

        ; verificando se o primeiro argumento é 1
        cmp dword [ebp + 8], 1
        je fill2

        mov edx, [ebp+12]
        shr edx, 0x6
        and edx, 0x3f
        movzx edx, byte [ecx + edx]
        shl edx, 0x8
        or eax, edx

        ; verificando se o primeiro argumento é 2
        cmp dword [ebp + 8], 2
        je fill1

        mov edx, [ebp+12]
        and edx, 0x3f
        movzx edx, byte [ecx + edx]
        or eax, edx
        jmp encode_ret

fill2:
        ; special char
        movzx edx, byte [ecx + 0x40]
        shl edx, 0x8
        or eax, edx
fill1:
        ; special char
        movzx edx, byte [ecx + 0x40]
        or eax, edx

encode_ret:
        pop ebp
        ; return already in eax

        ret

_base64_decode:
        ; first param at [ebp + 8], since pushing ebp
        push ebp
        mov ebp, esp

        xor eax, eax

        call get_runtime_addr2
get_runtime_addr2:
        ; realizando o pop do endereço de retorno para ecx, temos o endereço de `get_runtime_addr2`
        ; em tempo de execução
        pop ecx
        ; já se sabe o valor do offset `decode_table - get_runtime_addr2` em tempo de compilação
        ; então obtemos o endereço de `decode_table` em tempo de execução
        add ecx, decode_table - get_runtime_addr2

        mov edx, [ebp + 8]
        and edx, 0xff
        movzx edx, byte [ecx + edx]
        or eax, edx

        mov edx, [ebp + 8]
        shr edx, 8
        and edx, 0xff
        movzx edx, byte [ecx + edx]
        shl edx, 6
        or eax, edx

        mov edx, [ebp + 8]
        shr edx, 16
        and edx, 0xff
        movzx edx, byte [ecx + edx]
        shl edx, 12
        or eax, edx

        mov edx, [ebp + 8]
        shr edx, 24
        and edx, 0xff
        movzx edx, byte [ecx + edx]
        shl edx, 18
        or eax, edx

        pop ebp

        shl eax, 8

        ret

