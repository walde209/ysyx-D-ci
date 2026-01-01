#include "sim.h"

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};
static int reg_num;
void isa_reg_display(){
  for(int i=0;i<32;i++){
    printf("%s:0x%08x  ",regs[i],dut->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__regfile__DOT__rf[i]);
    reg_num++;
    if(reg_num==4){
      printf("\n");
      reg_num=0;
    }
  }
}
int isa_reg_str2val(const char *s, bool *success) {
	//printf("name is %s\n",s);
	// if(strcmp(s,"pc")==0){
	// *success=true;
	// char pc[32]="";
	// sprintf(pc,"0x%08x",dut->trace_pc);
	// printf("pc:%s\n",pc);
	// return dut->trace_pc;
	// }
  for(int i=0;i<32;i++){
    if(strcmp(s,regs[i])==0){
      *success=true;
	    char r[32]="";
	    sprintf(r,"0x%08x",dut->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__regfile__DOT__rf[i]);
	    printf("%d;%s:%s\n",i,regs[i],r);
      return dut->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__regfile__DOT__rf[i];
    }
  }
  *success=false;
  return 0;
}
void get_reg(CPU_state *reg,unsigned int pc){
  reg->pc=pc;
  for(int i=0;i<32;i++){
    reg->gpr[i]=dut->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__regfile__DOT__rf[i];
  }
  // reg->csr.mepc=dut->rootp->top_cpu__DOT__Csr1__DOT__mepc;
  // reg->csr.mtvec=dut->rootp->top_cpu__DOT__Csr1__DOT__mtvec;
  // reg->csr.mcause=dut->rootp->top_cpu__DOT__Csr1__DOT__mcause;
  // reg->csr.mstatus=dut->rootp->top_cpu__DOT__Csr1__DOT__mstatus;
}
bool isa_difftest_checkregs(CPU_state *ref_r, unsigned int pc) {
  for(int i = 0; i < 32; i++) {
    if (ref_r->gpr[i] == Reg.gpr[i]) {
      continue;
    }else{
      Log("%d:In" ANSI_FMT("\"%s\"",ANSI_FG_RED) "---" ANSI_FMT("ref_reg: 0x%08x ",ANSI_FG_GREEN) "!=" ANSI_FMT("dut_reg:0x%08x",ANSI_FG_RED),i,regs[i],ref_r->gpr[i], Reg.gpr[i]);
      Log("Now pc is" ANSI_FMT("0x%08x", ANSI_FG_RED), pc);
      return false;
    }
  }
  return true;
}
