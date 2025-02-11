# nasm -f elf64 base64.s -o base64.o
# gcc base64.o main.c -o bin
# ./bin in.txt out.txt

all: exec

exec: main.o base64.o
	gcc base64.o main.o -o bin

main.o: main.c
	gcc -c main.c -o main.o

base64.o: base64.s
	nasm -f elf64 base64.s -o base64.o

