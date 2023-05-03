#!/bin/bash
nasm -f elf64 main.asm -o main.o
gcc -no-pie -m64 -o a.out main.o -lraylib -lGL -lm -lpthread -ldl -lrt -lX11
rm main.o
