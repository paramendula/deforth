%include "macro.inc"
%include "sys/linux.inc"
%include "words/core.asm"

section .bss

return_stack_start resb 1024
return_stack_cap equ $ - return_stack_start
return_stack_end equ return_stack_start + return_stack_cap

stack_start resq 1

; default input buffer
input_buffer resb 256
input_buffer_cap equ $ - input_buffer


section .data

blob_corefs incbin "words/core.fs"
blob_corefs_len equ $ - blob_corefs
blob_core_extfs incbin "words/core-ext.fs"
blob_core_extfs_len equ $ - blob_core_extfs

CR equ '\n'
SPACE equ ' '

; variables
state   db 0 ; 0 - interpret, -1 - compile
base    db 10 ; current number conversion radix
source  dq input_buffer
source_len dq 0
; >IN
source_in dq 0
source_id dq 0 ; 0 - user input (stdin), -1 - string

; For now, it will lie here
WORD bye, "BYE"


section .text
  global _start

word_bye_exec:
  jmp sys_exit

_start:
  call sys_init
  jmp init

init:
  ; Data stack is set up by default (rsp)
  ; Saving it for DEPTH and probably for underflow checks
  mov [stack_start], rsp

  ; Setup the return stack (rbp)
  mov rbp, return_stack_end

  ; LATEST is stored in the r8 register
  ; LASTWORD is first defined in words/core.asm, each WORD macro usage updates it
  mov r8, LASTWORD

  ; HERE is stored in the r9 register (Data space)
  ; data_space_start is defined and set in sys/linux.inc
  mov r9, QWORD [data_space_start]

  ; r10 is used as the current ITC instruction pointer

  ; r12 contains >IN
  mov r12, 0

  ; TODO:
  ; INTERPRET core.fs and core-ext.fs (file.fs in the future?)
  ; call word_quit_exec
  jmp sys_exit
