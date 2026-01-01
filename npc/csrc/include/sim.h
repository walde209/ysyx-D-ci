#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <getopt.h>
#include <regex.h>
#include <elf.h>
#include <dlfcn.h>
#include <stddef.h>
#include <sys/time.h>
#include"verilated.h"
#include"verilated_vcd_c.h"
#include"VysyxSoCFull.h"
#include"VysyxSoCFull___024root.h"
//#include "VysyxSoCFull__Dpi.h"
#include "svdpi.h"
#include "VysyxSoCFull__Dpi.h"
extern VysyxSoCFull *dut;
extern VerilatedVcdC *m_trace;



enum { NPC_RUNNING, NPC_STOP, NPC_END, NPC_ABORT, NPC_QUIT };

typedef struct {
  int state;
  unsigned int halt_pc;
  unsigned int halt_ret;
} NPCState;

extern NPCState npc_state;

typedef struct {
  unsigned int mepc;
  unsigned int mcause;
  unsigned int mtvec;
  unsigned int mstatus;
}riscv32_CSR;
typedef struct {
  unsigned int gpr[32];
  unsigned int pc;
  riscv32_CSR csr;
}CPU_state;

typedef struct {
    char name[64];
    unsigned int addr;      //the function head address
    Elf32_Xword size;
} Symbol;
extern Symbol *symbol;
extern int number; 
void parse_elf(const char *elf_file);
void call_func(unsigned int pc,unsigned int dnpc);
void ret_func(unsigned int pc);



#define ARRLEN(arr) (int)(sizeof(arr) / sizeof(arr[0]))
#define NR_CMD ARRLEN(cmd_table)
void init_sdb();
static char* rl_gets();
void sdb_set_batch_mode();
extern bool is_batch_mode;
void sdb_mainloop();
static int cmd_help(char *args);
static int cmd_si(char *args);
static int cmd_x(char *args);
static int cmd_info(char *args);
static int cmd_p(char *args);
static int cmd_w(char *args);
static int cmd_d(char *args);
static int cmd_c(char *args);
static int cmd_wtrace(char *args);
static int cmd_itrace(char *args);
static int cmd_ftrace(char *args);
static int cmd_mtrace(char *args);
static int cmd_dtrace(char *args);
static int cmd_q(char *args);
extern bool wtrace_flag;
extern bool itrace_flag;
extern bool ftrace_flag;
extern bool mtrace_flag;
extern bool dtrace_flag;
extern bool difftest_flag;

extern const char *regs[];

void get_reg(CPU_state *reg,unsigned int pc);
void isa_reg_display();
int isa_reg_str2val(const char *s, bool *success);

int parse_args(int argc, char *argv[]);
extern char *img_file;



long load_img(char *img_file);
unsigned char* guest_to_host(unsigned int paddr);
unsigned int host_read(void *addr);
void host_write(void *addr, int len, int data);
int pmem_read(int raddr,int mode);
void pmem_write(int waddr, int len,int wdata);
bool in_pmem(unsigned int addr);
extern int sim_time;
extern long img_size;
extern unsigned char pmem[134217728];
#define CONFIG_MBASE 0x00000000
#define CONFIG_MSIZE 0x1000000
#define PMEM_LEFT  ((unsigned int)CONFIG_MBASE)
#define PMEM_RIGHT ((unsigned int)CONFIG_MBASE + CONFIG_MSIZE - 1)



void init_device();
void init_map();
#define NR_MAP 16
#define PAGE_SHIFT        12
#define PAGE_SIZE         (1ul << PAGE_SHIFT)
#define PAGE_MASK         (PAGE_SIZE - 1)
#define IO_SPACE_MAX (2 * 1024 * 1024)
typedef void(*io_callback_t)(unsigned int, int, bool);
unsigned char* new_space(int size);
typedef struct {
  const char *name;
  // we treat ioaddr_t as paddr_t here
  unsigned int low;
  unsigned int high;
  void *space;
  io_callback_t callback;
} IOMap;
IOMap* fetch_mmio_map(unsigned int addr);//取出mapid对应的空间
unsigned int map_read(unsigned int addr, int len, IOMap *map);
void map_write(unsigned int addr, int len, unsigned int data, IOMap *map);
void report_mmio_overlap(const char *name1, unsigned int l1, unsigned int r1,const char *name2, unsigned int l2, unsigned int r2);
void add_mmio_map(const char *name, unsigned int addr,void *space, unsigned int len, io_callback_t callback);
extern IOMap maps[NR_MAP];
extern int nr_map;

#define CONFIG_SERIAL_MMIO 0xa00003f8
void init_serial();
void serial_io_handler(unsigned int offset, int len, bool is_write);

#define CONFIG_RTC_MMIO 0xa0000048
void init_timer();
void rtc_io_handler(unsigned int offset, int len, bool is_write);
unsigned long get_time();
void init_rand();



void init_regex();
typedef struct token {
  int type;
  char str[32];
} Token;
bool make_token(char *e);
bool check_parentheses(int p,int q);
unsigned int eval(int p,int q);
int expr(char *e, bool *success);



typedef struct watchpoint{
  int NO;
  int flag;
  struct watchpoint *next;
  char expr[64];
  int valu;
}WP;
WP* new_wp();
void free_wp(int no);
#define NR_WP 32
extern WP wp_pool[NR_WP];
void sdb_watchpoint_display();
void init_wp_pool();
void check_watchpoint();


void execute_once();
void reset(int num);
void cpu_exec(unsigned long num);


extern CPU_state Reg;
bool isa_difftest_checkregs(CPU_state *ref_r, unsigned int pc);
void init_difftest(char *ref_so_file, long img_size, int port);
void difftest_step(unsigned int pc, unsigned int npc);
void difftest_skip_ref();
void difftest_skip_dut(int nr_ref, int nr_dut);
extern bool is_skip_ref;
extern int skip_dut_nr_inst;
extern char *diff_so_file;

// #if defined(__GNUC__) && !defined(__clang__)
// #pragma GCC diagnostic push
// #pragma GCC diagnostic ignored "-Wmaybe-uninitialized"
// #endif

// #include "llvm/MC/MCAsmInfo.h"
// #include "llvm/MC/MCContext.h"
// #include "llvm/MC/MCDisassembler/MCDisassembler.h"
// #include "llvm/MC/MCInstPrinter.h"
// #if LLVM_VERSION_MAJOR >= 14
// #include "llvm/MC/TargetRegistry.h"
// #if LLVM_VERSION_MAJOR >= 15
// #include "llvm/MC/MCSubtargetInfo.h"
// #endif
// #else
// #include "llvm/Support/TargetRegistry.h"
// #endif
// #include "llvm/Support/TargetSelect.h"

// #if defined(__GNUC__) && !defined(__clang__)
// #pragma GCC diagnostic pop
// #endif

// #if LLVM_VERSION_MAJOR < 11
// #error Please use LLVM with major version >= 11
// #endifs
// extern "C" void init_disasm(const char *triple);
// extern "C" void disassemble(char *str, int size, unsigned long pc, unsigned char *code, int nbyte);

#define ANSI_FG_BLACK   "\33[1;30m"
#define ANSI_FG_RED     "\33[1;31m"
#define ANSI_FG_GREEN   "\33[1;32m"
#define ANSI_FG_YELLOW  "\33[1;33m"
#define ANSI_FG_BLUE    "\33[1;34m"
#define ANSI_FG_MAGENTA "\33[1;35m"
#define ANSI_FG_CYAN    "\33[1;36m"
#define ANSI_FG_WHITE   "\33[1;37m"
#define ANSI_BG_BLACK   "\33[1;40m"
#define ANSI_BG_RED     "\33[1;41m"
#define ANSI_BG_GREEN   "\33[1;42m"
#define ANSI_BG_YELLOW  "\33[1;43m"
#define ANSI_BG_BLUE    "\33[1;44m"
#define ANSI_BG_MAGENTA "\33[1;35m"
#define ANSI_BG_CYAN    "\33[1;46m"
#define ANSI_BG_WHITE   "\33[1;47m"
#define ANSI_NONE       "\33[0m"


#define ANSI_FMT(str, fmt) fmt str ANSI_NONE

#define _Log(...) \
  do { \
    printf(__VA_ARGS__); \
  } while (0)

#define Log(format, ...) \
    _Log(ANSI_FMT("[%s:%d %s] " format, ANSI_FG_BLUE) "\n", \
        __FILE__, __LINE__, __func__, ## __VA_ARGS__)









