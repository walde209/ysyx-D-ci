#include "sim.h"
bool wtrace_flag=false;
bool itrace_flag=false;
bool ftrace_flag=false;
bool mtrace_flag=false;
bool dtrace_flag=false;
bool difftest_flag=false;
bool is_batch_mode=false;
static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },
  { "si" , "execute program            " ANSI_FMT("format:si [num]",ANSI_FG_CYAN) , cmd_si },
  { "x" , "print the content of memory " ANSI_FMT("format:x [num] [0x80000000-0x87ffffff]",ANSI_FG_CYAN) , cmd_x },
  { "info" , "print reg or watchpoint  " ANSI_FMT("format:info [r/w]",ANSI_FG_CYAN) , cmd_info },
  { "p" , "calculate expression        " ANSI_FMT("format:p [expr]",ANSI_FG_CYAN) , cmd_p},
  { "w" , "set watchpoint              " ANSI_FMT("format:w [expr]",ANSI_FG_CYAN) , cmd_w},
  { "d" , "delete watchpoint           " ANSI_FMT("format:d [num]",ANSI_FG_CYAN) , cmd_d},
  { "wtrace" , "Turn on/off wtrace     " ANSI_FMT("format:wtrace [1/0]",ANSI_FG_CYAN) , cmd_wtrace },
  { "itrace" , "Turn on/off itrace     " ANSI_FMT("format:itrace [1/0]",ANSI_FG_CYAN) , cmd_itrace },
  { "ftrace" , "Turn on/off ftrace     " ANSI_FMT("format:ftrace [1/0]",ANSI_FG_CYAN) , cmd_ftrace },
  { "mtrace" , "Turn on/off mtrace     " ANSI_FMT("format:mtrace [1/0]",ANSI_FG_CYAN) , cmd_mtrace },
  { "dtrace" , "Turn on/off dtrace     " ANSI_FMT("format:dtrace [1/0]",ANSI_FG_CYAN) , cmd_dtrace }
  };

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline(ANSI_FMT("(npc of zjt)",ANSI_FG_CYAN));

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}
static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}
static int cmd_x(char *args){
	if(args==NULL){
	printf("No args\n");
	return 0;
	}
	char *n1=strtok(args," ");
	char *n2=strtok(NULL," ");
	int len;
	int addr;
	//char ex[655]="";
	sscanf(n1,"%d",&len);
	sscanf(n2,"%x",&addr);
	//bool f=0;
	//int addr_char=expr(ex,&f) ;
	int i;
	for(i=0;i<len;i++){
		//printf("%d\n",addr);
		printf("0x%08x:0x%08x\n",addr,pmem_read(addr,2));
		addr=addr+4;
	}
	return 0;
}
static int cmd_si(char *args){
	int step;
	if(args==NULL){
		step=1;
	}else{
		sscanf(args,"%d",&step);
	}
	cpu_exec(step);
	return 0;
}
static int cmd_info(char *args){
  	if(args==NULL){
		printf("NO args.\n");
	}else if(strcmp(args,"r")==0){
		isa_reg_display();
	}else if(strcmp(args,"w")==0){
		sdb_watchpoint_display();
	}
	return 0;
}
static int cmd_w(char *args){
	if(args==NULL){
	printf("No args\n");
	return 0;
	}
	WP *p=new_wp();
	printf("For new watchpoint,NO:%d\n",p->NO);
	strcpy(p->expr,args);
	bool flag;
	int evalu=expr(p->expr,&flag);
	printf("valu:%d\n",evalu);
	if(flag){
		p->valu=evalu;
		printf("Valu remain successfully\n");
	}else{
		printf("For expr of watchpoint NO:%d,Error in make tokens\n",p->NO);
	}
	return 0;
}
static int cmd_d(char *args){
	if(args==NULL){
		printf("No args\n");
	}else{
		free_wp(atoi(args));
	}
	return 0;
}
static int cmd_p(char *args){
  	if(args==NULL){
	printf("No args\n");
	return 0;
	}
	bool flag=false;
	//expr(args,&flag);
	printf("valu=%d\n",expr(args,&flag));
	return 0;
}
static int cmd_wtrace(char *args){
	if(atoi(args)==0){
		wtrace_flag=false;
		printf("wtrace off\n");
	}else if(atoi(args)==1){
		wtrace_flag=true;
		printf("wtrace on\n");
	}else if(args==NULL){
		printf("please input 1 or 0\n");}
		return 0;  
}
static int cmd_itrace(char *args){
	if(atoi(args)==0){
		itrace_flag=false;
		printf("itrace off\n");
	}else if(atoi(args)==1){
		itrace_flag=true;
		printf("itrace on\n");
	}else if(args==NULL){
		printf("please input 1 or 0\n");}
		return 0;  
}
static int cmd_ftrace(char *args){
	if(atoi(args)==0){
		ftrace_flag=false;
		printf("ftrace off\n");
	}else if(atoi(args)==1){
		ftrace_flag=true;
		printf("ftrace on\n");
	}else if(args==NULL){
		printf("please input 1 or 0\n");}
		return 0;
}
static int cmd_mtrace(char *args){
	if(atoi(args)==0){
		mtrace_flag=false;
		printf("mtrace off\n");
	}else if(atoi(args)==1){
		mtrace_flag=true;
		printf("mtrace on\n");
	}else if(args==NULL){
		printf("please input 1 or 0\n");}
		return 0;
}
static int cmd_dtrace(char *args){
	if(atoi(args)==0){
		dtrace_flag=false;
		printf("dtrace off\n");
	}else if(atoi(args)==1){
		dtrace_flag=true;
		printf("dtrace on\n");
	}else if(args==NULL){
		printf("please input 1 or 0\n");}
		return 0;
}

static int cmd_c(char *args) {
  //while(!(dut->flag)){execute_once();}
  //printf("\nsim over please input \"q\" to quit\n\n");
  cpu_exec(-1);
  return 0;
}
static int cmd_q(char *args) {
  return -1;
}
void sdb_set_batch_mode() {
  is_batch_mode = true;
}
void sdb_mainloop() {
	//sdb_set_batch_mode();
    if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }
  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }
    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}
int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"batch"    , no_argument      , NULL, 'b'},
    //{"log"      , required_argument, NULL, 'l'},
    {"diff"     , required_argument, NULL, 'd'},
    //{"port"     , required_argument, NULL, 'p'},
    {"help"     , no_argument      , NULL, 'h'},
    {"ftrace"   , required_argument, NULL, 'f'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-bhl:d:p:f:", table, NULL)) != -1) {
    switch (o) {
      case 'b': sdb_set_batch_mode(); break;
      //case 'p': sscanf(optarg, "%d", &difftest_port); break;
      //case 'l': log_file = optarg; break;
      case 'd': diff_so_file = optarg; break;
      case 1: img_file = optarg; return 0;
      case 'f':parse_elf(optarg);break;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-b,--batch              run with batch mode\n");
        //printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
        //printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
        printf("\t-f,--ftrace=ELF         turn on ftrace for ELF\n");
        printf("\n");
        exit(0);
    }
  }
  return 0;
}
