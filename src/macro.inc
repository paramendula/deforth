; Move to the next instruction's CFA and start executing it
%macro NEXT 0
  add r10, 8
  RET_PUSH r10

  mov r10, QWORD [r10]
  jmp [r10]
%endmacro

; Return to caller's instruction thread (in sense of ITC) and start executing next instruction
%macro EXIT 0
  RET_POP r10
  NEXT
%endmacro

; WORD base_name base_string flags link_value exec_token
%macro WORD 2-5
  word_%1:
    %if %0 > 3
      dq %4
    %else
      dq LASTWORD
    %endif
    %if %0 >2
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
