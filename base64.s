%macro declare_sequence 2
; %1 = valor inicial, %2 = número de bytes
%assign current %1
%rep %2
    db current
    %assign current current + 1
%endrep
%endmacro

segment .data
table: db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="

; Podemos contar com o fato de que conhecemos todos os caracteres de entrada,
; seus códigos ascii e suas contrapartes de entrada
; +<>43; /<>47; [0-9]<>[48-57]; =<>61; [A-Z]<>[65-90]; [a-z]<>[97-122];
decode_table:
        times 43 db 0x00
        db 62
        times (47-44) db 0x00
        db 63
        declare_sequence 52, 10
        times (61-58) db 0x00
        db 0x00 ; preenchimento aqui, ainda não sei como lidar com isso
        times (65-62) db 0x00
        declare_sequence 0, 26
        times (97-91) db 0x00
        declare_sequence 26, 26

segment .text

; Precisa torná-lo global para que possa ser acessado em outro arquivo com extern
; Precisamos colocar as duas assinaturas, com _ para windows e sem para unix like
global _base64_encode, _base64_decode
global base64_encode, base64_decode

_base64_encode:
base64_encode:
        push ebp
        mov ebp, esp

        ; zerando o registrador de retorno
        xor eax, eax

        ; Para termos código independente de posição
        ; não podemos simplesmente fazer `mov ecx, table`, pois
        ; o segmento de texto dependeria de um endereço de memória desconhecido em tempo de compilação,
        ; e o segmento de código, que deveria ser somente leitura, teria que ser modificado em tempo de execução
        ; gerando o aviso "warning: relocation in read-only section `.text'"
        ; em vez disso, usamos o seguinte truque para calcular o endereço em tempo de execução
        call get_runtime_addr1
get_runtime_addr1:
        ; realizando o pop do endereço de retorno para ecx, temos o endereço de `get_runtime_addr1` em tempo de execução
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
        ; pegar o byte correto na tabela com deslocamento edx
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
        ; caractere especial
        movzx edx, byte [ecx + 0x40]
        shl edx, 0x8
        or eax, edx
fill1:
        ; caractere especial
        movzx edx, byte [ecx + 0x40]
        or eax, edx

encode_ret:
        pop ebp
        ; retorno já em eax

        ret

_base64_decode:
base64_decode:
        ; primeiro parâmetro em [ebp + 8], desde o push ebp
        push ebp
        mov ebp, esp

        xor eax, eax

        call get_runtime_addr2
get_runtime_addr2:
        ; realizando o pop do endereço de retorno para ecx, temos o endereço de `get_runtime_addr2` em tempo de execução
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
