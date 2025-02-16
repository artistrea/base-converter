segment .data
table: db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="

segment .text

; Need to make it global so it can be accessed in another file with extern
; this function receives (uint32_t, uint32_t)
; with first parameter being the number of bytes to base64 encode (can be 1 to 3)
; and the second parameter contains the bytes in big endian order, with the first 8 bits
; being ignored
; WARNING: it is the responsibility of the caller to make sure there is
; no trash in bytes 2 and 3 in case only 1 or 2 bytes are being encoded
global base64_encode

base64_encode:
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
        call get_runtime_addr
get_runtime_addr:
        ; realizando o pop do endereço de retorno para ecx, temos o endereço de `get_runtime_addr`
        ; em tempo de execução
        pop ecx
        ; já se sabe o valor do offset `table - get_runtime_addr` em tempo de compilação
        ; então obtemos o endereço de `table` em tempo de execução
        add ecx, table - get_runtime_addr

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

