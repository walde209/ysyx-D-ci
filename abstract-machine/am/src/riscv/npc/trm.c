#include <am.h>
#include <klib-macros.h>
#include <npc.h>
extern char _heap_start;
int main(const char *args);

extern char _pmem_start;
#define PMEM_SIZE (128 * 1024 * 1024)
#define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)

Area heap = RANGE(&_heap_start, PMEM_END);
static const char mainargs[MAINARGS_MAX_LEN] = TOSTRING(MAINARGS_PLACEHOLDER); // defined in CFLAGS

void putch(char ch) {
  while(!(inb(SERIAL_PORT+5)&(0x20)));
  // outb(SERIAL_PORT+2,0x04);//清空fifo
  outb(SERIAL_PORT, ch);
  //// while(!(inb(SERIAL_PORT+5)&(0x40)));
}

void halt(int code) {
asm volatile("mv a0, %0; ebreak" : :"r"(code));
  while (1);
}
void uart_init(){
  outb(SERIAL_PORT+3,0x83);//允许设置除数
  outb(SERIAL_PORT+1,0x00);//关闭中断
  outb(SERIAL_PORT,0x2);//设置除数 
  outb(SERIAL_PORT+3,0x03);//禁止设置除数 并设置输出长度
  // outb(SERIAL_PORT+2,0x80);//中断触发字节
}
void _trm_init() {
  uart_init();
  // putch(mainargs[0]);
  // putch('A');
  // putch('\n');
  int ret = main(mainargs);
  halt(ret);
}
