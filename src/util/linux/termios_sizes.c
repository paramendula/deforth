#include <stddef.h>
#include <stdio.h>
#include <termios.h>

int main(int argc, char **argv) {
  printf("sizeof(struct termios) = %zu\n", sizeof(struct termios));
  printf("sizeof(tcflag_t) = %zu)\n", sizeof(tcflag_t));
  printf("sizeof(cc_t) = %zu\n", sizeof(cc_t));
  printf("sizeof(speed_t) = %zu\n", sizeof(speed_t));
  printf("NCCS = %zu\n", NCCS);
  printf("%zu = %zu*4 + %zu + %zu*%zu + %zu*2 + align\n",
         sizeof(struct termios), sizeof(tcflag_t), sizeof(cc_t), sizeof(cc_t),
         NCCS, sizeof(speed_t));

  printf(
      "termios {\n  %zu:c_iflag\n  %zu:c_oflag\n  %zu:c_cflag\n  %zu:c_lflag\n "
      " %zu:c_line\n  %zu:c_cc[%zu]\n  %zu:c_ispeed\n  %zu:c_ospeed\n}\n",
      offsetof(struct termios, c_iflag), offsetof(struct termios, c_oflag),
      offsetof(struct termios, c_cflag), offsetof(struct termios, c_lflag),
      offsetof(struct termios, c_line), offsetof(struct termios, c_cc), NCCS,
      offsetof(struct termios, c_ispeed), offsetof(struct termios, c_ospeed));

  return 0;
}
