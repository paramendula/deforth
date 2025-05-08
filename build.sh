#!/usr/bin/env bash

# Important directory variables
PWD=$(pwd)
DIR_SRC="$PWD/src"
DIR_OUT="$PWD/out"

# Make sure out/ exists
mkdir -p "$DIR_OUT"

# Feed deforth assembly implementation to NASM (get object file)
cd "$DIR_SRC"
nasm -g -f elf64 -o "$DIR_OUT/deforth.o" deforth.asm

# Feed assembled object file to the linker (get executable)
cd "$DIR_OUT"
ld -o deforth deforth.o

cd "$PWD"
