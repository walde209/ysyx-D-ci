#include "sim.h"
#define CH_OFFSET 0

static unsigned char *serial_base = NULL;


static void serial_putc(char ch) {
  //putch(ch);
  //printf("into callback,%c\n",ch);
  putc(ch, stderr);
}

void serial_io_handler(unsigned int offset, int len, bool is_write) {
  assert(len == 1);
  switch (offset) {
    /* We bind the serial port with the host stderr in NEMU. */
    case CH_OFFSET:
      if (is_write) serial_putc(serial_base[0]);
      else Log("do not support read");
      break;
    default: Log("do not support offset = %d", offset);
  }
}

void init_serial() {
  serial_base = new_space(8);
#ifdef CONFIG_HAS_PORT_IO
  add_pio_map ("serial", CONFIG_SERIAL_PORT, serial_base, 8, serial_io_handler);
#else
  add_mmio_map("serial", CONFIG_SERIAL_MMIO, serial_base, 8, serial_io_handler);
#endif

}