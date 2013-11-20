Terminal: Terminal.o
	ld -m elf_i386 -o Terminal Terminal.o

Terminal.o: Terminal.asm
	nasm -f elf -g -F stabs Terminal.asm -l Terminal.lst
