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
cfa_literal dq LITERAL
cfa_jump dq JUMP

word_eq:
  dq 0
  db 0
  db 1
  db "="
  align 8
  word_eq_cfa dq word_eq_exec

word_dup:
  dq 0
  db 0
  db 3
  db "DUP"
  align 8
  word_dup_cfa dq word_dup_exec

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
.loop:
  dq word_key_cfa
  dq word_dup_cfa
  dq cfa_literal
  dq 'Q'
  dq word_eq_cfa
  dq cfa_branch
  dq .if_false
  dq word_emit_cfa
  dq cfa_jump
  dq .loop
.if_false:
  dq cfa_exit


section .text

word_dup_exec:
  mov rax, QWORD [rsp]
  push rax

  EXIT

word_eq_exec:
  pop rax
  pop rdx
  cmp rax, rdx
  je .true

  push 0
  EXIT
.true:
  push -1
  EXIT

; ITC handlers

STUB:
  NEXT

STUB_EXIT:
  add rbp, 8
  mov r10, QWORD [rbp]
  add rbp, 8

  NEXT 

; ( DATA: f -- ) ( r10: 8+ADDR-IF-FALSE -- )
BRANCH:
  mov r10, QWORD [rbp]

  pop rax
  cmp rax, 0

  jne .true

  add r10, 16
  mov QWORD [rbp], r10
  mov r10, QWORD [r10]
  jmp [r10]
.true:
  add r10, 8
  mov r10, QWORD [r10]
  mov QWORD [rbp], r10 
  mov r10, QWORD [r10]
  jmp [r10]

; ( r10: 8+JUMP-ADDRESS )
JUMP:
  mov r10, QWORD [rbp]
  mov r10, QWORD [r10+8]
  mov QWORD [rbp], r10
  mov r10, QWORD [r10]
  jmp [r10]

; (DATA : -- x ) ( r10: 8+VALUE -- )
LITERAL:
  mov r10, QWORD [rbp]
  add rbp, 8
  add r10, 8
  mov rax, QWORD [r10]
  push rax

  NEXT
