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
WORD mul,  "*"
WORD eq,   "="
WORD toin, ">IN"
WORD accept, "ACCEPT"
WORD dup,  "DUP"
WORD emit, "EMIT"
WORD find, "FIND"
WORD here, "HERE"
WORD key,  "KEY"
WORD source, "SOURCE"


; Auxiliary macros
; (Please be ware of registers you pass to them, I haven't checked all possible cases)

; ACCEPT <in reg c-addr> <in|out reg +n>
; c-addr and +n can't be the same
; c-addr will be changed if it's rdi
; rdi, rdx, rcx, rax are changed
%macro ACCEPT 2
  %ifnidni %1, rdi
    mov rdi, %1
  %endif
  %ifnidni %2, rdx
    mov rdx, %2
  %endif
  %ifnidni %2, rcx
    mov rcx, %2
  %endif
  %%loop:
    cmp rcx, 0
    je %%end
    SYS_READ_KEY rax
    ; TODO: errorcheck
    cmp rax, CR
    je %%end
    mov BYTE [rdi], al
    inc rdi
    jmp %%loop
  %%end:
  sub rdx, rcx
  %ifnidni %2, rdx
    mov %2, rdx
  %endif
%endmacro

; FIND <in reg c-addr> <in|out reg latest_addr> <out reg result>
; addr should point to a counted string
; latest_addr should be a valid word pointer
; three registers should be different
; you can't use these registers:
;   addr: rsi, rdi, rcx
;   latest_addr: rsi, rdi, rcx
; Return:
; addr is left unchanged
; latest_addr points to the word (if found)
; result: 0 if not found; 1 if immediate, otherwise -1
; Example: FIND rax, rbx, rdx
; rsi, rdi, ecx are changed
%macro FIND 3
  CLD
  %%loop:
    mov rsi, %1
    mov cl, BYTE [rsi]
    lea rdi, [%2+9]
    repe cmpsb
    jz %%found
    mov %2, QWORD [%2]
    cmp %2, 0
    je %%not_found
    jmp %%loop
  %%found:
    movzx %3, BYTE [%2+8]
    and %3, FLAG_IMMEDIATE
    jnz %%end
    mov %3, -1
    jmp %%end
  %%not_found:
    mov %3, 0
  %%end:
%endmacro

; macro for the WORD, PARSE and PARSE-NAME words
; GWORD <in reg|const char> <out reg c-start> <out reg count>
; char must contain in it's lowest byte the delimiter
; c-addr points to the benning of the found word (in SOURCE)
; count is the found word's length
; if count == 0 then c-start is unchanged
; all registers should be different
; c-start can't be rdi and rax
%macro GWORD 3
  ; Skip leading chars
  %ifnidni %1, rax
    mov rax, %1
  %endif
  LEA rdi, [source+r12]
  mov rcx, source_len
  sub rcx, r12
  CLD
  REPE scasb
  ; If start not found, jump out
  cmp rcx, 0
  je %%done
  ; Save the start
  mov %2, rdi
  ; Search for word's end (find SPACE)
  REPNE scasb
%%done: 
  mov %3, rdi
  sub %3, %2
%endmacro

section .text

word_store_exec:
  pop rbx
  pop rax
  mov QWORD [rbx], rax
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

word_toin_exec:
  mov rax, source_in
  push rax
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

word_source_exec:
  mov rax, source
  push rax
  mov rax, [source_len]
  push rax
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
