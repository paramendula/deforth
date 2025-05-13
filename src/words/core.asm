; core.asm - the most important primitives and INTERPRET are defined here
; for the rest of Core wordset see core.fs, for Core-ext see core-ext.fs

; Word definition:
; 0-8:        Previous definition address
; 8-9:        Flags byte
; 9-10:       Word's name length (L)
; 10-10+N:    Word's name (N = L + Padding)
; 10+N-18+N:  Code field (address)
; 18+N-*: Optional Data (Parameter) field (variable, constant, value or threaded code)
;
; ^ 10+N % 8 == 0 

%include "words/aux.asm"

FLAG_IMMEDIATE equ 1

section .data

; Fake CFAs for ITC semantics
itc_exit_cfa dq itc_exit
itc_0branch_cfa dq itc_0branch
itc_literal_cfa dq itc_literal
itc_jump_cfa dq itc_jump

; Words documentation: https://forth-standard.org/standard/core

%define LASTWORD 0

WORD store, "!"
WORD ns, "#"
WORD ns_great, "#>"
WORD ns_sign, "#S"
WORD mul,  "*"
WORD eq,   "="
WORD ns_less, "<#"
WORD toin, ">IN"
WORD tonumber, ">NUMBER"
WORD toret, ">R"
WORD accept, "ACCEPT"
WORD dup,  "DUP"
WORD emit, "EMIT"
WORD find, "FIND"
WORD here, "HERE"
WORD key,  "KEY"
WORD rfrom, "R>"
WORD rfetch, "R@"
WORD source, "SOURCE"
WORD word, "WORD"

section .text

word_store_exec:
  pop rbx
  pop rax
  mov QWORD [rbx], rax
  EXIT

word_ns_exec:
  mov r15, QWORD [base]
  pop rdx
  pop rax
  div r15
  ; TODO: convert and write
  EXIT

word_ns_great_exec:
  ; TODO: reverse string
  RET_POP rax ; current
  RET_POP rbx ; begin
  sub rax, rbx
  push rbx
  push rax
  EXIT

word_ns_sign_exec:
  ; TODO: pop and write
  EXIT

word_mul_exec:
  pop rcx
  pop rax
  imul rcx
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

word_ns_less_exec:
  ; push begin and cur
  RET_PUSH r9
  RET_PUSH r9
  EXIT

word_toin_exec:
  mov rax, source_in
  push rax
  EXIT

word_tonumber_exec:
  pop rcx
  pop rsi
  pop rdx
  pop rax
  mov r13, QWORD [base]
  TONUMBER rax, rdx, rsi, rcx, r13
  push rax
  push rdx
  push rsi
  push rcx
  EXIT

word_toret_exec:
  pop rax
  RET_PUSH rax
  EXIT

word_accept_exec:
  pop rdx
  pop rdi
  ACCEPT rdi, rdx
  push rdx
  EXIT

word_dup_exec:
  mov rax, QWORD [rsp]
  push rax
  EXIT

word_emit_exec:
  mov rsi, rsp
  SYS_WRITE_KEY rsi
  pop rax
  EXIT

word_here_exec:
  push r9
  EXIT

word_find_exec: 
  mov rax, QWORD [rsp]
  mov rbx, r8
  FIND rax, rbx, rdx
  cmp rdx, 0
  je .end
  pop rax
  movzx rax, BYTE [rax]
  add rbx, rax
  add rbx, 9
  push rbx
.end:
  push rdx
  EXIT

word_key_exec:
  push 0
  mov rsi, rsp
  SYS_READ_KEY rsi
  EXIT

word_rfrom_exec:
  RET_POP rax
  push rax
  EXIT

word_rfetch_exec:
  RET_FETCH rax
  push rax
  EXIT

word_source_exec:
  mov rax, source
  push rax
  mov rax, [source_len]
  push rax
  EXIT

word_word_exec:
  pop rax
  CWORD rax
  push r9
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
itc_0branch:
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
