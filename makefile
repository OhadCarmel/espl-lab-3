all: task0 hello

task0: start.o main.o util.o
	ld -m elf_i386 start.o main.o util.o -o task0

hello: hello.o
	ld -m elf_i386 -o hello hello.o
start.o: start.s
	nasm -f elf32 start.s -o start.o

util.o: Util.c
	gcc -m32 -Wall -ansi -c -nostdlib -fno-stack-protector Util.c -o util.o

main.o: main.c
	gcc -m32 -Wall -ansi -c -nostdlib -fno-stack-protector main.c -o main.o

hello.o: hello.s
	nasm -f elf32 hello.s -o hello.o



.PHONY: clean

clean:
	rm -f *.o task0 hello