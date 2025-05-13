: QUIT
  ( empty the return stack and set the input source to the user input device )
  POSTPONE [
   REFILL
  WHILE
   ['] INTERPRET CATCH
   CASE
   0 OF STATE @ 0= IF ." OK" THEN CR ENDOF
   -1 OF ( TODO: Aborted ) ENDOF
   -2 OF ( TODO: Display message from ABORT" ) ENDOF
   ( default ) DUP ."Exception #" .
   ENDCASE
  REPEAT BYE
;

: . DUP ABS 0 <# #S ROT SIGN #> TYPE SPACE ;
