#include "sim.h"
unsigned char pmem[134217728] = {0};
unsigned char* guest_to_host(unsigned int paddr) { return pmem + paddr - CONFIG_MBASE; }
unsigned int host_read(void *addr) {
    return *(unsigned int *)addr;
}
void host_write(void *addr, int len, int data) {
  switch (len) {
    case 1: *(unsigned int *)addr = ((*(unsigned int *)addr)&(~0x000000ff))|(data&0x000000ff); return;
    case 2: *(unsigned int *)addr = ((*(unsigned int *)addr)&(~0x0000ffff))|(data&0x0000ffff); return;
    case 4: *(unsigned int *)addr = ((*(unsigned int *)addr)&(~0xffffffff))|(data&0xffffffff); return;
    default: assert(0);
  }
}
int pmem_read(int raddr, int mode){
  int ret;
  
  if(in_pmem(raddr)){
    ret = host_read(guest_to_host(raddr));
    if(mtrace_flag){
      switch(mode){
        case 0:printf("read 1B, addr:0x%08x read data:0x%08x\n",raddr,ret);break;
        case 1:printf("read 2B, addr:0x%08x read data:0x%08x\n",raddr,ret);break;
        case 4:printf("read 1Bu, addr:0x%08x read data:0x%08x\n",raddr,ret);break;
        case 5:printf("read 2Bu, addr:0x%08x read data:0x%08x\n",raddr,ret);break;
        default:printf("read 4B, addr:0x%08x read data:0x%08x\n",raddr,ret);break;
      }
    }
    // if(mode == 0){if(mtrace_flag){printf("read 1B, addr:0x%08x ",raddr);}ret=((host_read(guest_to_host(raddr)))<<24)>>24;if(mtrace_flag){printf("read data:0x%08x\n",ret);}}//1B
    // else if(mode == 1){if(mtrace_flag){printf("read 2B, addr:0x%08x ",raddr);}ret=((host_read(guest_to_host(raddr)))<<16)>>16;if(mtrace_flag){printf("read data:0x%08x\n",ret);}}//2B
    // else if(mode == 4){if(mtrace_flag){printf("read 1Bu, addr:0x%08x ",raddr);}ret=(host_read(guest_to_host(raddr)))&(0x000000ff);if(mtrace_flag){printf("read data:0x%08x\n",ret);}}//1Bu
    // else if(mode == 5){if(mtrace_flag){printf("read 2Bu, addr:0x%08x ",raddr);}ret=(host_read(guest_to_host(raddr)))&(0x0000ffff);if(mtrace_flag){printf("read data:0x%08x\n",ret);}}//2Bu
    // else{if(mtrace_flag){printf("read 4B, addr:0x%08x ",raddr);}ret=host_read(guest_to_host(raddr));if(mtrace_flag){printf("read data:0x%08x\n",ret);}}
  }else{
    //ret=map_read(raddr, len, fetch_mmio_map(raddr));
    if(mode == 0){ret=((map_read(raddr, 1, fetch_mmio_map(raddr)))<<24)>>24;}
    else if(mode == 1){ret=((map_read(raddr, 2, fetch_mmio_map(raddr)))<<16)>>16;}
    else if(mode == 4){ret=(map_read(raddr, 1, fetch_mmio_map(raddr)))&(0x000000ff);}
    else if(mode == 5){ret=(map_read(raddr, 2, fetch_mmio_map(raddr)))&(0x0000ffff);}
    else{ret=map_read(raddr, 4, fetch_mmio_map(raddr));}
  }
  return ret;
  //return 0;
}

void pmem_write(int waddr, int len,int wdata){
  //printf("write memory\n");
  if(in_pmem(waddr)){
    host_write(guest_to_host(waddr), len, wdata);
    switch (len){
      case 1:if(mtrace_flag){printf("write 1B, addr:0x%08x, data:0x%08x\n",waddr,wdata);}break;
      case 2:if(mtrace_flag){printf("write 2B, addr:0x%08x, data:0x%08x\n",waddr,wdata);}break;
      case 4:if(mtrace_flag){printf("write 4B, addr:0x%08x, data:0x%08x\n",waddr,wdata);}break;
      default:;
    }
  }else{
      map_write(waddr, len, wdata, fetch_mmio_map(waddr));
  }
} 

bool in_pmem(unsigned int addr) {
  return addr - CONFIG_MBASE < CONFIG_MSIZE;
}

long load_img(char *img_file) {
  if (img_file == NULL) {
    Log(ANSI_FMT("No image is given. Use the default build-in image.", ANSI_FG_RED));
    return 4096; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  //Assert(fp, "Can not open '%s'", img_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  Log(ANSI_FMT("The image is %s, size = %ld",ANSI_FG_CYAN), img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(guest_to_host(CONFIG_MBASE), size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
}
extern "C" void flash_read(int32_t addr, int32_t *data) {
    // printf("flash addr:0x%08x\n",addr);
  int32_t inst = pmem_read((addr&(0xfffffffc)), 2);
  // printf("flash data:0x%08x\n",inst);
  *data = inst;
  // *data = 0x00100073;
}

