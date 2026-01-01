#include "sim.h"
static unsigned int *rtc_port_base = NULL;

static unsigned long boot_time = 0;
static unsigned long get_time_internal(){
      struct timeval now;
  gettimeofday(&now, NULL);
  unsigned long us = now.tv_sec * 1000000 + now.tv_usec;
  return us;
}
unsigned long get_time() {
  if (boot_time == 0) boot_time = get_time_internal();
  unsigned long now = get_time_internal();
  return now - boot_time;
}

void init_rand() {
  srand(get_time_internal());
}



void rtc_io_handler(unsigned int offset, int len, bool is_write) {
  assert(offset == 0 || offset == 4);
  if (!is_write && offset == 4) {
    unsigned long us = get_time();
    rtc_port_base[0] = (unsigned int)us;
    rtc_port_base[1] = us >> 32;
  }
}

// #ifndef CONFIG_TARGET_AM
// static void timer_intr() {
//   if (nemu_state.state == NEMU_RUNNING) {
//     extern void dev_raise_intr();
//     dev_raise_intr();
//   }
// }
// #endif

void init_timer() {
  rtc_port_base = (uint32_t *)new_space(8);
  add_mmio_map("rtc", CONFIG_RTC_MMIO, rtc_port_base, 8, rtc_io_handler);
}