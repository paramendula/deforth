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

; Fake CFAs for ITC semantics
itc_exit_cfa dq itc_exit
itc_branch_cfa dq itc_branch
itc_literal_cfa dq itc_literal
itc_jump_cfa dq itc_jump

; Words documentation: https://forth-standard.org/standard/core

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
  word_quit_cfa dq next_stub
  ; THREADED CODE
.loop:
  dq word_key_cfa
  dq word_dup_cfa
  dq itc_literal_cfa
  dq 'Q'
  dq word_eq_cfa
  dq itc_branch_cfa
  dq .if_false
  dq word_emit_cfa
  dq itc_jump_cfa
  dq .loop
.if_false:
  dq itc_exit_cfa


section .text



word_store_exec:
  pop rbx
  pop rax
  mov QWORD [rbx], rax
  EXIT

word_here_exec:
  push r9
  EXIT

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

; ITC (Indirect Threaded Code) handlers

; Used as ITC words' CFA (bootstraps the code by jumping to the first instruction)
next_stub:
  NEXT

; Return from the current ITC word
itc_exit:
  add rbp, 8
  mov r10, QWORD [rbp]
  add rbp, 8

  NEXT 

; Pops a value from the data stack, if it's 0, works as itc_jump
; otherwise skips the next item (located at r10+8) and continues execution
; ( DATA: f -- ) ( r10: 8+ADDR-IF-FALSE -- )
itc_branch:
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

; Jumps to the address the next item in the array points at (located at r10+8)
; ( r10: 8+JUMP-ADDRESS )
itc_jump:
  mov r10, QWORD [rbp]
  mov r10, QWORD [r10+8]
  mov QWORD [rbp], r10
  mov r10, QWORD [r10]
  jmp [r10]

; Pushes the next item in the array (located at r10+8) to the data stack
; (DATA : -- x ) ( r10: 8+VALUE -- )
itc_literal:
  mov r10, QWORD [rbp]
  add rbp, 8
  add r10, 8
  mov rax, QWORD [r10]
  push rax

  NEXT
