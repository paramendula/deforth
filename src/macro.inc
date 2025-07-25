; Move to the next instruction's CFA and start executing it
%macro NEXT 0
  add r10, 8
  RET_PUSH r10
  ; ^ so that after EXIT we continue with the next instruction

  mov r10, QWORD [r10]
  jmp [r10]
%endmacro

; Return to caller's instruction thread (in sense of ITC) and start executing next instruction
%macro EXIT 0
  RET_POP r10
  NEXT
%endmacro

; word structure
; (0-8) 8 bytes: previous word (link)
; (8-9) 1 byte: flags byte
; (9-10) 1 byte: word's name length (N)
; (10-10+N+A) N bytes: word's name (10+N+A is 8 bytes aligned, where A is alignment)
; (10+N+A - 18+N+A) 8 bytes: Code Field Address
; ^ This is also available in core.asm

; ^ I should probably redo how I store word's name

; WORD base_name base_string flags link_value exec_token
%macro WORD 2-5
  word_%1:
    %if %0 > 3
      dq %4
    %else
      dq LASTWORD
    %endif
    %if %0 > 2
      db %3
    %else
      db 0
    %endif
    db %strlen(%2)
    db %2
    align 8
    word_%1_cfa:
      %if %0 == 5
        dq %5
      %else
        dq word_%1_exec
      %endif

    %define LASTWORD word_%1
%endmacro

%define WORD_LAST(x) (x)
%define WORD_FLAGS(x) (x+8)
%define WORD_NAMELEN(x) (x+9)
%define WORD_NAME(x) (x+10)
