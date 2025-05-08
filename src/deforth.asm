%include "sys/linux.inc"


section .bss

input_buffer resb 256
input_buffer_cap equ $ - input_buffer

section .text
  global _start

_start:
  call sys_init

  call sys_exit
