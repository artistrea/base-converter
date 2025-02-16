# if we want to use cdecl, we need to compile for 32 bits
# if we compile for 64 bits, uses System V ABI for Unix, and another ABI for windows
# so we would need to make 2 different assembly codes depending on the target platform

# ./bin in.txt out.txt


# SE FOR WINDOWS
ifeq ($(OS),Windows_NT)
FORMAT = win32
else
FORMAT = elf32
endif

all: exec

exec: main.o base64.o base64.s main.c
	gcc -m32 base64.o main.o -o bin

main.o: main.c
	gcc -m32 -c main.c -o main.o

base64.o: base64.s
	nasm -f $(FORMAT) base64.s -o base64.o

# to generate and analyse main.c assembly code
main_asm:
	gcc -m32 -S main.c

