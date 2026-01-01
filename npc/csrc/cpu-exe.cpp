#include "sim.h"
unsigned int pc;
unsigned int next_pc;
bool first=true;
bool one_flag = false;
NPCState npc_state = { .state = NPC_STOP };
unsigned long g_nr_guest_inst = 0;
static unsigned long g_timer = 0; // unit: us
void set_npc_state(int state, unsigned int pc, int halt_ret) {
  npc_state.state = state;
  npc_state.halt_pc = pc;
  npc_state.halt_ret = halt_ret;
}
// char logbuf[128];
void execute_once(){
    dut->clock=1;
		dut->eval();
		#ifdef TRACE
		m_trace->dump(sim_time);
		#endif
		sim_time++;

    get_reg(&Reg,pc); 
    // if(difftest_flag&&!first){difftest_step(pc,next_pc);}
    // first=false;
    // if(wtrace_flag){check_watchpoint();}


    // if(ftrace_flag){
    //   if(((dut->trace_inst&(0x0000007f))==111)&&(((dut->trace_inst>>7)&(0x0000001f))==1)){call_func(dut->trace_pc,dut->trace_npc);}
    //   if(((dut->trace_inst&(0x0000707f))==103)&&(((dut->trace_inst>>7)&(0x0000001f))==1)){call_func(dut->trace_pc,dut->trace_npc);}
    //   else if(((dut->trace_inst&(0x0000707f))==103)&&(((dut->trace_inst>>7)&(0x0000001f))==0)&&(((dut->trace_inst>>15)&(0x1f))==1)){ret_func(dut->trace_pc);}
    // }
    g_nr_guest_inst++;
    if(dut->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wbu_valid==1){
      one_flag = true;
      if(dut->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__inst == 0x00100073)
      {
        set_npc_state(NPC_END,dut->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__PC,Reg.gpr[10]);
        printf("\nsim over please input \"q\" to quit\n\n");
        return;
      }
      pc=dut->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__PC;
      if(itrace_flag){
      printf("current pc:0x%08x,inst:0x%08x\n",dut->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__PC,dut->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__inst);
      }
      

    }
    dut->clock=0;           //execute ones
    dut->eval();
    #ifdef TRACE
    m_trace->dump(sim_time);
    #endif
    sim_time++;
    
    // next_pc=dut->trace_npc;
}
void reset(int num){
  for(int i = 0;i<num;i++){
    dut->clock^=1;
    dut->reset=1;
    dut->eval();
    #ifdef TRACE
    m_trace->dump(sim_time);
    #endif
    sim_time++;
  }
    dut->reset=0;
  
}

static void statistic() {
  Log("host time spent = %lu us", g_timer);
  Log("total guest instructions = %lu" , g_nr_guest_inst);
  if (g_timer > 0) Log("simulation frequency = %lu inst/s", g_nr_guest_inst * 1000000 / g_timer);
  else Log("Finish running in less than 1 us and can not calculate the simulation frequency");
}

void cpu_exec(unsigned long num){

   switch (npc_state.state) {
    case NPC_END: case NPC_ABORT:
      printf("Program execution has ended. To restart the program, exit NEMU and run again.\n");
      return;
    default: npc_state.state = NPC_RUNNING;
  }

  unsigned long timer_start = get_time();

	for(int i=0;i<num;i++){
    while(!one_flag){execute_once();}
    one_flag = false;
		execute_once();
    // if(dut->flag==1){break;}
    if(npc_state.state!=NPC_RUNNING){break;}
	}

  unsigned long timer_end = get_time();
  g_timer += timer_end - timer_start;

  switch (npc_state.state) {
    case NPC_RUNNING: npc_state.state = NPC_STOP; break;

    case NPC_END: case NPC_ABORT:
      Log("npc: %s at pc = 0x%08x" ,
          (npc_state.state == NPC_ABORT ? ANSI_FMT("ABORT", ANSI_FG_RED) :
           (npc_state.halt_ret == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) :
            ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED))),
          npc_state.halt_pc);
          //if(npc_state.state != NPC_ABORT&&npc_state.halt_ret!=0){puts(buf);}
          //puts(buf);
      // fall through
    case NPC_QUIT: statistic();
  }
}
