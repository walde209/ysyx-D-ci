/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <cpu/cpu.h>
#include <difftest-def.h>
#include <memory/paddr.h>
#include <common.h>
__EXPORT uint32_t cur_regs[32];
__EXPORT void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  if(direction==DIFFTEST_TO_REF)
  {
    memcpy(guest_to_host(addr),buf,n);
  }
  else{
    memcpy(buf,guest_to_host(addr),n);
  }
}

__EXPORT void difftest_regcpy(void *dut, bool direction) {
  CPU_state *ref_regs = &(cpu);
  if(direction==DIFFTEST_TO_REF)
  {
    memcpy(ref_regs->gpr,dut,32*sizeof(uint32_t));
  }
  else{
    memcpy(dut,ref_regs->gpr,32*sizeof(uint32_t));
  }
}

__EXPORT void difftest_exec(uint64_t n) {

  cpu_exec(n);
  difftest_regcpy(cur_regs, DIFFTEST_TO_DUT);

}

__EXPORT void difftest_raise_intr(word_t NO) {
  assert(0);
}

__EXPORT void difftest_init(int port) {
  void init_mem();
  init_mem();
  /* Perform ISA dependent initialization. */
  init_isa();
  init_device();
  init_map();
}
