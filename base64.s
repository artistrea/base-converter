%macro declare_sequence 2
; %1 = valor inicial, %2 = número de bytes
%assign current %1
%rep %2
    db current          ; Armazena valor na posição atual
    %assign current current + 1  ; Incrementa para próximo byte
%endrep
%endmacro

segment .data
; Tabela Base64 padrão (64 caracteres + padding)
table: db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="

; Tabela de decodificação: mapeia ASCII para valores de 6 bits
; Estrutura: [0-42] (padding)
;            [43]=['+']     <-> 62,
;            [44-46] (padding)
;            [47]=['/']     <-> 63,
;            [48-57]=[0-9]  <-> [52-61],
;            [58-60] (padding)
;            [61]=['=']     <-> 0, (tanto faz, responsabilidade do chamador ignorar padding)
;            [65-90]=[A-B]  <-> [0-25],
;            [91-96] (padding)
;            [97-122]=[a-b] <-> [26-51]
decode_table:
        times 43 db 0x00    ; Caracteres ASCII 0-42 inválidos
        db 62               ; '+' (ASCII 43) → valor 62
        times (47-44) db 0x00 ; ASCII 44-46 inválidos
        db 63               ; '/' (ASCII 47) → valor 63
        declare_sequence 52, 10  ; Dígitos 0-9 (ASCII 48-57 → valores 52-61)
        times (61-58) db 0x00    ; ASCII 58-60 inválidos
        db 0x00            ; Padding para '=' (ASCII 61)
        times (65-62) db 0x00  ; ASCII 62-64 inválidos
        declare_sequence 0, 26  ; Letras maiúsculas A-Z (ASCII 65-90 → 0-25)
        times (97-91) db 0x00   ; ASCII 91-96 inválidos
        declare_sequence 26, 26 ; Letras minúsculas a-z (ASCII 97-122 → 26-51)

segment .text

; Torna as funções visíveis para outros arquivos
global _base64_encode, _base64_decode ; Convenção Windows
global base64_encode, base64_decode   ; Convenção Unix

;----------------------------------------------------------
; Função de codificação Base64
; Entrada: [ebp+8] = número de bytes (1-3)
;          [ebp+12] = bytes de entrada (big-endian)
; Saída: EAX = 4 bytes codificados (big-endian)
;----------------------------------------------------------
_base64_encode:
base64_encode:
        push ebp
        mov ebp, esp

        xor eax, eax        ; Limpa registrador de retorno

        ; ** Calcula endereço da tabela em tempo de execução **
        call get_runtime_addr1
get_runtime_addr1:
        pop ecx             ; Obtém endereço atual
        add ecx, table - get_runtime_addr1 ; Ajusta para tabela real

        ; Processa primeiro caractere (6 bits superiores)
        mov edx, [ebp+12]   ; Carrega bytes de entrada
        shr edx, 0x12       ; Desloca 18 bits à direita (isola bits 23-18)
        and edx, 0x3f       ; Mantém apenas 6 bits
        movzx edx, byte [ecx + edx] ; Busca na tabela
        shl edx, 0x18       ; Posiciona no byte mais significativo
        or eax, edx         ; Armazena resultado

        ; Processa segundo caractere (próximos 6 bits)
        mov edx, [ebp+12]
        shr edx, 0xc        ; Desloca 12 bits (isola bits 17-12)
        and edx, 0x3f
        movzx edx, byte [ecx + edx]
        shl edx, 0x10       ; Posiciona no terceiro byte
        or eax, edx

        ; Verifica se precisa de padding
        cmp dword [ebp + 8], 1
        je fill2            ; Apenas 1 byte de entrada → 2 paddings

        ; Processa terceiro caractere (bits 11-6)
        mov edx, [ebp+12]
        shr edx, 0x6        ; Desloca 6 bits
        and edx, 0x3f
        movzx edx, byte [ecx + edx]
        shl edx, 0x8        ; Posiciona no segundo byte
        or eax, edx

        cmp dword [ebp + 8], 2
        je fill1            ; 2 bytes de entrada → 1 padding

        ; Processa quarto caractere (bits 5-0)
        mov edx, [ebp+12]
        and edx, 0x3f       ; Isola últimos 6 bits
        movzx edx, byte [ecx + edx]
        or eax, edx         ; Armazena no último byte
        jmp encode_ret

fill2:
        ; ** Adiciona dois caracteres de padding **
        movzx edx, byte [ecx + 0x40] ; Índice 64 = '='
        shl edx, 0x8
        or eax, edx
fill1:
        ; ** Adiciona um caractere de padding **
        movzx edx, byte [ecx + 0x40]
        or eax, edx

encode_ret:
        pop ebp
        ret

;----------------------------------------------------------
; Função de decodificação Base64
; Entrada: [ebp+8] = 4 caracteres codificados
; Saída: EAX = 3 bytes decodificados (big-endian, com byte menos significativo sempre = 0)
;----------------------------------------------------------
_base64_decode:
base64_decode:
        push ebp
        mov ebp, esp

        xor eax, eax        ; Limpa registrador de resultado

        ; ** Calcula endereço da tabela de decodificação **
        call get_runtime_addr2
get_runtime_addr2:
        pop ecx
        add ecx, decode_table - get_runtime_addr2

        ; Processa primeiro caractere (6 bits superiores)
        mov edx, [ebp + 8]
        and edx, 0xff       ; Isola primeiro byte
        movzx edx, byte [ecx + edx] ; Decodifica
        or eax, edx         ; Armazena bits 5-0

        ; Processa segundo caractere (próximos 6 bits)
        mov edx, [ebp + 8]
        shr edx, 8          ; Segundo byte
        and edx, 0xff
        movzx edx, byte [ecx + edx]
        shl edx, 6          ; Posiciona nos bits 11-6
        or eax, edx

        ; Processa terceiro caractere
        mov edx, [ebp + 8]
        shr edx, 16         ; Terceiro byte
        and edx, 0xff
        movzx edx, byte [ecx + edx]
        shl edx, 12         ; Posiciona nos bits 17-12
        or eax, edx

        ; Processa quarto caractere
        mov edx, [ebp + 8]
        shr edx, 24         ; Quarto byte
        and edx, 0xff
        movzx edx, byte [ecx + edx]
        shl edx, 18         ; Posiciona nos bits 23-18
        or eax, edx

        pop ebp
        ; ** Alinha resultado para big endian, adicionando padding = 0 nos bits menos significativos **
        shl eax, 8

        ret
