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
    dec rcx
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
    inc rcx
    lea rdi, [WORD_NAMELEN(%2)]
    repe cmpsb
    jz %%found
    mov %2, QWORD [%2]
    cmp %2, 0
    je %%not_found
    jmp %%loop
  %%found:
    movzx %3, BYTE [WORD_FLAGS(%2)]
    and %3, FLAG_IMMEDIATE
    jnz %%end
    mov %3, -1
    jmp %%end
  %%not_found:
    mov %3, 0
  %%end:
%endmacro

; WORD_XT <in|out reg x-addr>
; x-addr should point to a word definition
; result: x-addr points to word's execution token (xt)
; x-addr can't be: rax, rcx, rdx
; rax, rbx, rcx, rdx are changed
%macro WORD_XT 1
  mov rax, [WORD_NAMELEN(%1)]
  mov rcx, rax
  xor rdx, rdx
  mov rbx, 8
  div rbx
  ; get align
  mov rax, 8
  sub rax, rdx
  lea rdx, [WORD_NAME(%1)+rax] ; offset(10) + align(?)
  add rdx, rcx                 ; + name length (?) = x-addr(xt)
  mov %1, rdx
%endmacro

; CHARFIND <in reg|const char> <in reg|const c-addr> <in reg|const max> <out reg count>
; find index of char first occurence in c-addr
; count is -1 if char wasn't found
; rax, rdx, rcx, rdi are changed
%macro CHARFIND 4
  %ifnidni %3, rcx
    mov rcx, %3
  %endif
  %ifnidni %3, rdx
    mov rdx, %3
  %endif
  %ifnidni %2, rdi
    mov rdi, %2
  %endif
  %ifnidni %1, rax
    mov rax, %1
  %endif
  repne scasb
  jne %%notfound
  %ifnidni %4, rdx
    mov %4, rdx
  %endif
  sub %4, rcx
  dec %4
  jmp %%end
%%notfound:
  mov %4, -1
%%end:
%endmacro

; General macro for the WORD, PARSE, PARSE-NAME and so on words
; GWORD <in reg|const char> <out reg c-start> <out reg count>
; char must contain in it's lowest byte the delimiter
; c-addr points to the benning of the found word (in SOURCE)
; count is the found word's length
; if count == 0 then c-start is unchanged
; all registers should be different
; c-start can't be rdi and rax
; rax, rdi, rcx are changed
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
  mov r12, source
  sub r12, rcx ; change >IN
  mov QWORD [source_in], r12
  mov %3, rdi
  sub %3, %2
%endmacro

; CWORD (CORE WORD) macro
; CWORD (in reg char) (opt out reg len)
; r9(HERE) will point to a counted string
; char must contain in it's lowest byte the delimiter
; len is not zero if a word is found
; len can't be rax, rsi or rcx
; rax, rsi and rcx are changed
%macro CWORD 1-2
  %ifnidni %1, rax
    mov rax, %1
  %endif
  GWORD rax, rsi, rcx
  %if %0 > 1
    mov %1, rcx
  %endif
  mov BYTE [rsi], cl
  inc rsi
  mov rdi, r9
  CLD
  rep movsb
%endmacro

; RET_PUSH <in reg|const val>
; push to return stack
%macro RET_PUSH 1
  sub rbp, 8
  mov QWORD [rbp], %1
%endmacro

; RET_POP <out reg dest>
; pop from return stack
%macro RET_POP 1
  mov %1, QWORD [rbp]
  add rbp, 8
%endmacro

; RET_FETCH <out reg dest>
; copy from return stack
%macro RET_FETCH 1
  mov %1, QWORD [rbp]
%endmacro

; RET_STORE <in reg|const dest>
; copy into return stack
%macro RET_STORE 1
  mov QWORD [rbp], %1
%endmacro

; WITIHN <in reg|const b1> <in reg|const b2> <in|out reg num>
; num is not zero if b1 <= num <= b2
%macro WITHIN 3
  cmp %3, %1
  jl %%bad
  cmp %3, %2
  jg %%bad
  %%bad:
    mov %3, 0
  %%end:
%endmacro

; NLOWER <in|out reg char>
; adds 'a' - 'A' to char
%macro NLOWER 1
  add %1, ('a' - 'A')
%endmacro

; NUPPER <in|out reg char>
; removes 'a' - 'A' from char
%macro NUPPER 1
  sub %1, ('a' - 'A')
%endmacro

; ISLOWER <in reg char> <out reg result>
; result is not zero if char is within 'a-z'
%macro ISLOWER 2
  mov %2, %1
  WITHIN 'a', 'z', %2
%endmacro

; ISUPPER <in reg char> <out reg result>
; result is not zero if char is within 'A-Z'
%macro ISUPPER 2
  mov %2, %1
  WITHIN 'A', 'Z', %2
%endmacro

; ISALPHA <in reg char> <out reg result>
; result is not zero if char is within 'a-z' or 'A-Z'
%macro ISALPHA 2
  ISUPPER %1, %2
  cmp %2, 0
  jne %%done
  mov %2, 1
  ISLOWER %1, %2
%%done:
%endmacro

; ISDIGIT <in reg char> <out reg result>
; result is not zero if char is within '0-9'
%macro ISDIGIT 2
  mov %2, %1
  WITHIN '0', '9', %2
%endmacro

; LOWER <in|out reg char> <reg buffer>
; if char is A-Z converts it to a-z
; buffer is needed and changed (can't be equal to char)
%macro LOWER 2
  ISUPPER %1, %2
  cmp %2, 0
  je %%done
  NLOWER %1
%%done:
%endmacro

; UPPER <in|out reg char> <reg buffer>
; if char is a-z converts it to A-Z
; buffer is needed and changed (can't be equal to char)
%macro UPPER 2
  ISLOWER %1, %2
  cmp %2, 0
  je %%done
  NUPPER %1
%%done:
%endmacro

; TONUMBER <in|out reg ud1:low> <in|out reg ud1:high> <in|out reg c-addr> <in|out reg count> <in reg base>
; tries to parse a c-aligned string as a base (reg base) number
; for more details look at >NUMBER in Forth2012 docs
; rax, rdx, rbx, r15 is changed
; Example: TONUMBER rax, rdx, rsi, rcx, r13
%macro TONUMBER 5
  %ifnidni %1, rax
    mov rax, %1
  %endif
  %ifnidni %2, rdx
    mov rdx, %2
  %endif
  xor rbx, rbx
%%loop:
  cmp %4, 0
  je %%end
  mov bl, BYTE [%3]
  cmp rbx, '9'
  jg %%nondec
  cmp rbx, '0'
  jl %%end
  sub rbx, '0'
  jmp %%next
%%nondec:
  mov r15, rbx
  WITHIN 'A', 'Z', r15
  cmp r15, 0
  jne %%next
  mov r15, rbx
  WITHIN 'a', 'z', r15
  cmp r15, 0
  jne %%end
  NUPPER rbx
  sub rbx, 'A'-10
%%next:
  cmp rbx, %5
  jge %%end
  mul %5
  ; Add to rdx:rax
  add rax, rbx
  adc rdx, 0
  inc %3
  dec %4
  jmp %%loop
%%end:
%endmacro

; TODIGIT <in|out reg digit>
%macro TODIGIT 1
  cmp %1, 10
  jl %%end
  add %1, 'A'-'0'-10
%%end:
  add %1, '0'
%endmacro

; INVERSE_STR <in reg c-addr> <in reg count>
; c-addr is changed
; changes rax, rdx, rdi
%macro INVERSE_STR 2
  cmp %2, 0
  je %%end
  mov rdi, %1
  add rdi, %2
  dec rdi
%%loop:
  cmp %1, rdi
  je %%end
  mov al, BYTE [%1]
  mov dl, BYTE [rdi]
  mov BYTE [%1], dl
  mov BYTE [rdi], al
  inc %1
  dec rdi
  jmp %%loop
%%end:
%endmacro

; REFILL <out reg flag>
; flag 0 if no input available
%macro REFILL 1
  mov rax, [source_id]
  cmp rax, 0
  jne %%bad ; if we're reading from string
  mov rdi, source ; input_buffer, no difference
  mov rcx, input_buffer_cap
  ACCEPT rdi, rcx
  mov QWORD [source_len], rcx
  mov r12, 0 ; >IN

  mov %1, -1
  jmp %%done
%%bad:
  mov %1, 0
%%done:
%endmacro
