# Codificador/Decodificador Base64 em Assembly x86_32

Implementação eficiente de codificação/decodificação Base64 seguindo RFC 4648, escrita em assembly NASM (x86_32).

## Características

- Rotinas completas de codificação/decodificação Base64
- Código independente de posição com endereçamento dinâmico de tabelas
- Tratamento de padding (=) para grupos de entrada incompletos
- Tabela de consulta para decodificação gerada por macro

## Compilação

Para compilar é necessário ter gcc e nasm.

```bash
make
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
- Manipulação de bits para extração ou geração de grupos de 6 bits na codificação e decodificação respectivamente.

