# Codificador/Decodificador Base64 em Assembly IA-32

Implementação eficiente de codificação/decodificação Base64 seguindo RFC 4648, escrita em assembly NASM para arquitetura IA-32.

## Características

- Rotinas completas de codificação/decodificação Base64
- Código independente de posição com endereçamento dinâmico de tabelas
- Tratamento de padding (=) para grupos de entrada incompletos
- Tabela de consulta para decodificação gerada por macro
- Processamento de entrada em big-endian

## Compilação

```bash
nasm -f elf32 base64.asm -o base64.o
gcc -m32 -o bin main.c base64.o
```

## Uso

Codificar binário para Base64:

```bash
./bin -e entrada.bin saida.txt
```

Decodificar Base64 para binário:

```bash
./bin -d entrada.txt saida.bin
```

## Detalhes Técnicos

- Uso de macros para geração de tabelas
- Cálculo de endereço em tempo de execução para código independente de posição
- Manipulação de bits para extração de grupos de 6 bits

# Como rodar

Para compilar é necessário ter gcc e nasm.

```bash
make
# encodes any binary, e.g. an jpeg
./bin -e img.jpeg out.txt
# decodes base64 to binary
./bin -d out.txt img2.jpeg
```


