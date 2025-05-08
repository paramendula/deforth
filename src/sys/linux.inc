section .bss

data_space_start resq 1
data_space_end resq 1

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

linux_termios_lflag_old resb 4


section .text

sys_init:
  ; brk(0x0C)(0)
  ; Get current break point (data segment end)
  mov rax, 0x0C
  mov rdi, 0
  syscall

  ; TODO: errorcheck

  mov [data_space_start], rax

  mov rdi, rax 
  add rdi, 8192 ; 8 KiB

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
  mov rsi, 0x5401
  lea rdx, [linux_termios]
  syscall

  ; TODO: errorcheck

  ; Save LFLAG, because we're going to change it
  mov rax, [linux_termios_lflag]
  mov [linux_termios_lflag_old], rax

  ; Disable canonical mode and echo (ICANON | ECHO)
  mov rax, [linux_termios_lflag]
  and rax, ~(002 | 010)
  mov [linux_termios_lflag], rax

  ; ioctl(0x10)(STDIN(0), TCGETS(0x5402), &linux_termios)
  ; Save changes to STDIN terminal io settings
  mov rax, 0x10
  mov rdi, 0
  mov rsi, 0x5402
  lea rdx, [linux_termios]
  syscall

  ; TODO: errorcheck

  ret

sys_exit:
  ; Restore old LFLAG
  mov rax, [linux_termios_lflag_old]
  mov [linux_termios_lflag], rax

  ; ioctl(0x10)(STDIN(0), TCGETS(0x5402), &linux_termios)
  ; Revert changes to STDIN terminal io settings
  mov rax, 0x10
  mov rdi, 0
  mov rsi, 0x5402
  lea rdx, [linux_termios]
  syscall

  ; TODO: errorcheck

  ; exit(0x3c)(0)
  mov rax, 0x3c
  mov rdi, 0
  syscall
