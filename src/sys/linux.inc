section .bss

; List of Linux syscalls:
; https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md

data_space_start resq 1
data_space_end resq 1

temp_buffer resb 16
temp_buffer_cap equ $ - temp_buffer

; 60 BYTES (struct termios)
linux_termios:
  linux_termios_iflag resb 4  ; 0-4
  linux_termios_oflag resb 4  ; 4-8
  linux_termios_cflag resb 4  ; 8-12
  linux_termios_lflag resb 4  ; 12-16
  linux_termios_line resb 1   ; 16-17
  linux_termios_cc resb 32    ; 17-49
  resb 3                      ; 49-52 PADDING
  linux_termios_ispeed resb 4 ; 52-56
  linux_termios_ospeed resb 4 ; 56-60

; Save the old value here while DEForth works
linux_termios_lflag_old resb 4


section .text

; This is called first when DEForth is launched
sys_init:
  ; brk(0x0C)(0)
  ; Get current break point (data segment end)
  mov rax, 0x0C
  mov rdi, 0
  syscall

  ; TODO: errorcheck

  mov [data_space_start], rax

  mov rdi, rax 
  add rdi, 8192 ; 8 KiB - data space size 

  ; brk(0x0C)(data_space_end)
  ; Extend break point by 8 KiB (extend data segment)
  mov rax, 0x0C
  syscall

  ; TODO: errorcheck

  mov [data_space_end], rax

  ; ioctl(0x10)(STDIN(0), TCGETS(0x5401), &linux_termios)
  ; Save STDIN terminal io settings
  mov rax, 0x10
  mov rdi, 0
  mov rsi, 0x5401 ; TCGETS
  lea rdx, [linux_termios]
  syscall

  ; TODO: errorcheck

  ; Save LFLAG, because we're going to change it
  ; LFLAG - Local Flag, terminal behavior and user input
  mov rax, [linux_termios_lflag]
  mov [linux_termios_lflag_old], rax

  ; Disable canonical mode and echo (ICANON | ECHO)
  ; ICANON buffers user input (can't capture keys one-byone)
  ;   and allows immediate in-line editing (backspace works and so on)
  ; ECHO immediately shows keys you enter into the terminal
  mov rax, [linux_termios_lflag]
  and rax, ~(002 | 010)
  mov [linux_termios_lflag], rax

  ; ioctl(0x10)(STDIN(0), TCSETS(0x5402), &linux_termios)
  ; Save changes to STDIN terminal io settings
  mov rax, 0x10
  mov rdi, 0
  mov rsi, 0x5402
  lea rdx, [linux_termios]
  syscall

  ; TODO: errorcheck

  ret

; This is what DEForth runs when it exits
sys_exit:
  ; Restore old LFLAG
  mov rax, [linux_termios_lflag_old]
  mov [linux_termios_lflag], rax

  ; ioctl(0x10)(STDIN(0), TCSETS(0x5402), &linux_termios)
  ; Revert changes to STDIN terminal io settings
  mov rax, 0x10
  mov rdi, 0
  mov rsi, 0x5402
  lea rdx, [linux_termios]
  syscall

  ; TODO: errorcheck

  ; exit(0x3c)(0)
  mov rax, 0x3c
  mov rdi, 0 ; No error
  syscall

; Wait for a key to be pressed by the user and move it into %1
; %1 must be either a register containing an address of some buffer OR
;   must be this pointer itself (e.g., 0x500 or temp_buffer)
; the buffer must be at least 1 byte long
; key -> BYTE [%1]
%macro SYS_READ_KEY 1
  %ifnidni %1, rsi
    mov rsi, %1 
  %endif
  ; read(0x0)(STDIN(0), buffer(%1), 1)
  mov rax, 0
  mov rdi, 0
  mov rdx, 1
  syscall
  ; TODO: errorcheck
%endmacro

; Read one byte from %1 and then output it into the standard output
;   immediately.
;  %1 must be either a register containing an address of some buffer OR
;    must be this pointer itself (e.g., 0x700 or last_string)
; the buffer must be at least 1 byte long
; emit BYTE [%1]
%macro SYS_WRITE_KEY 1
  %ifnidni %1, rsi
    mov rsi, %1 
  %endif
  ; write(0x1)(STDOUT(1), buffer(%1), 1)
  mov rax, 1
  mov rdi, 1
  mov rdx, 1
  syscall
  ; TODO: erorcheck
%endmacro
