; Word definition:
; 0-8:        Previous definition address
; 8-9:        Flags byte
; 9-10:       Word's name length (L)
; 10-10+N:    Word's name (N = L + Padding)
; 10+N-18+N:  Code field (address)
; 18+N-*: Optional Data (Parameter) field (variable, constant, value or threaded code)
;
; ^ 10+N % 8 == 0 

section .data

cfa_exit dq STUB_EXIT
cfa_branch dq BRANCH

word_emit:
  dq 0
  db 0
  db 4
  db "EMIT"
  align 8
  word_emit_cfa dq word_emit_exec

word_key:
  dq word_emit
  db 0
  db 3
  db "KEY"
  align 8
  word_key_cfa dq word_key_exec

word_quit:
  dq word_key
  db 0
  db 4
  db "QUIT"
  align 8
  word_quit_cfa dq STUB
  ; THREADED CODE
  dq word_key_cfa
  dq word_key_cfa
  dq word_emit_cfa
  dq word_emit_cfa
  dq cfa_exit


section .text

STUB:
  NEXT

STUB_EXIT:
  add rbp, 8
  mov r10, QWORD [rbp]
  add rbp, 8

  NEXT 

; ( DATA: f -- ) ( r10: 8+ADDR-IF-FALSE -- )
BRANCH:
  pop rax
  jz .false
  NEXT 
.false:
  mov r10, [r10+8]
  sub r10, 8
  NEXT
