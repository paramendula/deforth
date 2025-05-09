%include "macro.inc"
%include "sys/linux.inc"
%include "words/core.asm"

section .bss

return_stack_start resb 1024
return_stack_cap equ $ - return_stack_start
return_stack_end equ return_stack_start + return_stack_cap

input_buffer resb 256
input_buffer_cap equ $ - input_buffer


section .data

state db 0 ; 0 - interpret, -1 - compile
base db 10 ; curret number conversion radix

; System cleanup, indirected for ITC semantics
sys_exit_cfa dq sys_exit

; Fake ITC (indirect threaded code) for bootstrapping DEForth and then properly exiting
forth_init:
  dq word_quit_cfa
  dq sys_exit_cfa


section .text
  global _start

_start:
  call sys_init
  jmp init

init:
  ; Data stack is set up by default (rsp)

  ; Setup the return stack (rbp)
  mov rbp, return_stack_end-8
  mov QWORD [rbp], forth_init+8

  ; HERE is stored in the r9 register (Data space)
  ; data_space_start is defined and set in sys/linux.inc
  mov r9, QWORD [data_space_start]

  ; r10 is used as the current ITC instruction pointer

  ; Enter the interpretation loop
  mov r10, forth_init-8
  NEXT
