#include "sim.h"
CPU_state Reg;
Symbol *symbol = NULL;
int number;
char *diff_so_file = NULL;
static const uint32_t img [] = {
  0x00000297,  // auipc t0,0
  0x00028823,  // sb  zero,16(t0)
  0x0102c503,  // lbu a0,16(t0)
  0x00100073,  // ebreak (used as nemu_trap)
  0xdeadbeef,  // some data
};
int sim_time=0;
long img_size=0;
char *img_file=new char[100];

VysyxSoCFull *dut=new VysyxSoCFull;

#ifdef TRACE
VerilatedVcdC *m_trace=new VerilatedVcdC;
#endif
int main(int argc, char *argv[], char **env){

  #ifdef TRACE
  Verilated::traceEverOn(true);
  dut->trace(m_trace, 0);
  m_trace->open("waveform.vcd");
  #endif
//  printf("\n inhere \n");
  parse_args(argc,argv);
  Log("file name:%s\n",img_file);
  img_size=load_img(img_file);
  Log("\n===============img_size=%ld================\n\n",img_size);
  // for(int addr=0;addr<672656;addr=addr+4 ){
  //     int32_t inst = pmem_read((addr&(0xfffffffc)), 2);
  //     printf("flash addr:0x%08x flash data:0x%08x\n",addr,inst);
  // }




  reset(30);

  init_rand();
  init_sdb();
  init_device();

  if(difftest_flag){init_difftest(diff_so_file, img_size, 1234);}
   Log("Trace: %s",  ANSI_FMT("Please open from sdb", ANSI_FG_GREEN));
  Log("If trace is enabled, a log file will be generated "
        "to record the trace. This may lead to a large log file. "
        "If it is not necessary, you can disable it in menuconfig");
  Log("Build time: %s, %s", __TIME__, __DATE__);
  Log("Welcome to %s-" ANSI_FMT("NPC",ANSI_FG_GREEN) "!", ANSI_FMT("riscv32e", ANSI_FG_RED));
  Log("For help, type \"help\"\n");
	sdb_mainloop();


  printf("release memory\n");

  #ifdef TRACE
  m_trace->close();
  delete m_trace;
  #endif
	delete dut;
	exit(EXIT_SUCCESS);
}









