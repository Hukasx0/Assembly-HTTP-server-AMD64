set -xe
nasm -f elf64 -o server.o server.asm
ld -o server server.o
rm server.o
