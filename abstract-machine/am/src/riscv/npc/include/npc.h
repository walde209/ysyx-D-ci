#include <klib-macros.h>
#include <klib.h>
#include <riscv/riscv.h>

#define SERIAL_PORT     (0x10000000)
// #define SERIAL_PORT     (0xa00003f8)//nemu
#define KBD_ADDR        ()
#define RTC_ADDR        (0x02000000)
// #define RTC_ADDR        (0xa0000048)//nemu
#define VGACTL_ADDR     (0x211ffff8)
#define FB_ADDR         (0x21000000)
#define AUDIO_ADDR      ()
#define DISK_ADDR       ()
#define AUDIO_SBUF_ADDR ()

extern uint32_t keymap[57599];
void init_keymap();
extern char _pmem_start;
extern char _heap_start;
#define PSRAM_START 0x80000000
#define PSRAM_SIZE (4*1024*1024)
#define SDRAM_START 0xa0000000
#define SDRAM_SIZE (64*1024*1024)
#define SRAM_START 0x0f000000
#define SRAM_SIZE (8*1024)
#define FLASH_START 0x30000000
#define FLASH_SIZE (16*1024*1024)
#define SPI_BASE 0x10001000
#define HEAP_END  ((uintptr_t)&_heap_start + ((SDRAM_SIZE)/2))
#define NEMU_PADDR_SPACE \
  RANGE(&_pmem_start, PMEM_END), \
  RANGE(FB_ADDR, FB_ADDR + 0x200000), \
  RANGE(MMIO_BASE, MMIO_BASE + 0x1000) /* serial, rtc, screen, keyboard */

typedef uintptr_t PTE;

#define PGSIZE    4096

