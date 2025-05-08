%macro NEXT 0
  add r10, 8
  sub rbp, 8
  mov QWORD [rbp], r10

  mov r10, QWORD [r10]
  jmp [r10]
%endmacro

%macro EXIT 0
  mov r10, [rbp]
  add rbp, 8

  NEXT
%endmacro
