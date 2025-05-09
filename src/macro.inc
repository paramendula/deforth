; Move to the next instruction's CFA and start executing it
%macro NEXT 0
  add r10, 8
  sub rbp, 8
  mov QWORD [rbp], r10

  mov r10, QWORD [r10]
  jmp [r10]
%endmacro

; Return to caller's instruction thread (in sense of ITC) and start executing next instruction
%macro EXIT 0
  mov r10, [rbp]
  add rbp, 8

  NEXT
%endmacro

; WORD base_name base_string link_value exec_token
%macro WORD 2-4
  word_%1:
    %if %0 > 2
      dq %3
    %else
      dq LASTWORD
    %endif
    db %strlen(%2)
    db %2
    align 8
    word_%1_cfa:
      %if %0 == 4
        dq %4
      %else
        dq word_%1_exec
      %endif

    %define LASTWORD word_%1
%endmacro
