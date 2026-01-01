#include "sim.h"


void init_device() {
  //ioe_init();
  init_map();

  init_serial();
  init_timer();
  //init_vga();
  //init_i8042();
  //init_audio();
  //init_disk();
  //init_sdcard();
  //init_alarm();
}