#include "sim.h"


Token tokens[655] __attribute__((used)) = {};
int nr_token __attribute__((used))  = 0;
enum {
  TK_NOTYPE = 256, NUM=1, left=2, right=3,EQ=4,NEQ=5,AND=6,HEX=7,RN=8,LEQ=9,OR=10,POINTER=11,NEG=12
  /* TODO: Add more token types */
};
static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {" +", TK_NOTYPE},    // spaces 256
  {"\\+", '+'},         //'+'
  {"\\-",'-'},          //'-'
  {"\\*",'*'},          //'*'
  {"\\/",'/'},          //'/'
  {"\\(",left},         //2
  {"\\)",right},        //3
  {"\\=\\=",EQ},        //4
  {"\\!\\=",NEQ},       //5
  {"\\&\\&",AND},       //6
  {"0[Xx][0-9a-fA-F]+",HEX},    //7
  {"\\$+[a-zA-Z]*[0-9]*",RN},   //8
  {"\\|\\|",OR},         //10
  {"[0-9]*",NUM}       //1
};

#define NR_REGEX ARRLEN(rules)
static regex_t re[NR_REGEX];

void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      printf("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}
bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;
  nr_token=0;
  for(int z=0;z<655;z++){
  tokens[z].type=0;
  strcpy(tokens[z].str,"");
  }

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        //char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        /*Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
            i, rules[i].regex, position, substr_len, substr_len, substr_start);*/

        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */
        switch (rules[i].token_type) {
	   case '+':
	      tokens[nr_token].type='+';
	      nr_token++;break;
           case '-':
	      tokens[nr_token].type='-';
	      nr_token++;break;
           case '*':
	      tokens[nr_token].type='*';
	      nr_token++;break;
           case '/':
	      tokens[nr_token].type='/';
	      nr_token++;break;
           case 2:
	      tokens[nr_token].type='(';
	      nr_token++;break;
           case 3:
	      tokens[nr_token].type=')';
	      nr_token++;break;
           case 1:
           tokens[nr_token].type=1;
           strncpy(tokens[nr_token].str,e+position-substr_len,substr_len);
           nr_token++;break;
           case 4:
           tokens[nr_token].type=4;
           strcpy(tokens[nr_token].str,"==");
           nr_token++;break;
           case 5:
           tokens[nr_token].type=5;
           strcpy(tokens[nr_token].str,"!=");
           nr_token++;break;
           case 6:
           tokens[nr_token].type=6;
           strcpy(tokens[nr_token].str,"&&");
           nr_token++;break;
           case 9:
           tokens[nr_token].type=9;
           strcpy(tokens[nr_token].str,"<=");
           nr_token++;break;
           case 7:
           tokens[nr_token].type=7;
           strncpy(tokens[nr_token].str,e+position-substr_len,substr_len);
           nr_token++;break;
           case 8:
           tokens[nr_token].type=8;
           strncpy(tokens[nr_token].str,e+position-substr_len,substr_len);
           nr_token++;break;
           case 256:break;
           case 10:
           tokens[nr_token].type=10;
           strcpy(tokens[nr_token].str,"||");
           nr_token++;break;
          default: printf("Not find\n");break;
        }
        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  return true;
}

bool check_parentheses(int p,int q){
	if(tokens[p].type!='('||tokens[q].type!=')'){
		return false;
	}
	int i;
	int r,l;
	r=0;l=0;
	for(i=p;i<=q;i++){
		if(tokens[i].type=='('){
			l++;
		}else if(tokens[i].type==')'){
			r++;
	}
	if(r==l&&i<q){
		return false;
	}
	}
	if(l>r){
	return false;
	}
	return true;
}
unsigned int eval(int p,int q){
	if(p>q){
		return 0;
	}else if(p==q){
		if(tokens[p].type==7){
			int s;
			sscanf(tokens[p].str,"%x",&s);
			return s;
		}else if(tokens[p].type==8){
			bool f;
			int x=isa_reg_str2val(tokens[p].str+1,&f);
			if(f){
				return x;
			}else{
				printf("Not find\n");
				return 0;
			}
		}else{
			return atoi(tokens[p].str);
		}
	}else if(check_parentheses(p,q)==true){
	//printf("For tokens[%d] to tokens[%d] need to delete parentheses\n",p,q);
		return eval(p+1,q-1);
	}else{
      int i,cnt;
      cnt=0;
      for(i=p;i<=q;i++){
        if(tokens[i].type=='('){
               cnt++;
         }else if(tokens[i].type==')'){
               cnt--;
         }
	if(cnt<=-1||(cnt>0&&i==q)){
	  printf("Syntax error,Now valu=0\n");
	  return 0;
	   }
         }
		  int j;
			int op=-1;
			int power=0;
		  for(j=p;j<=q;j++){
			  if(tokens[j].type=='('){
			  //int y=j;
			  int ri=1;
			  while(1){
			      j++;
			      if(tokens[j].type=='('){
			      ri++;
			    }else if(tokens[j].type==')'){
			    ri--;
			    }
			    if(ri==0){break;}
			}
			//printf("For tokens[%d] to tokens[%d] need to be skip\n",y,j);
					continue;
				}
				if(tokens[j].type=='+'||tokens[j].type=='-'){
				if(power>5){
				continue;
				}else{
				op=j;
				power=5;
				}
				}else if(tokens[j].type=='*'||tokens[j].type=='/'){
					if(power>4){
						continue;
					}else{
						op=j;
						power=4;
				  }
				}else if(tokens[j].type==4||tokens[j].type==5){
				if(power>3){
				continue;
				}else{
				op=j;
				power=3;
				}
				}else if(tokens[j].type==6||tokens[j].type==10){
				if(power>2){
				continue;
				}else{
				op=j;
				power=2;
				}
				}else if(tokens[j].type==11||tokens[j].type==12){
				if(power>1){
				continue;
				}else{
				op=j;
				power=1;
				}
				}
			}
			if(power==0){
			printf("Not find the location of op\n");
			assert(0);
			}
			int op_type=tokens[op].type;
			//printf("op=%d location:%d\n",op_type,op);
			int val1=eval(p,op-1);
			int val2=eval(op+1,q);
			switch(op_type){
				case '+':/*printf("%d+%d=%d\n",val1,val2,val1+val2);*/return val1+val2;
				case '-':/*printf("%d-%d=%d\n",val1,val2,val1-val2);*/return val1-val2;
				case '*':/*printf("%d*%d=%d\n",val1,val2,val1*val2);*/return val1*val2;
				case '/':{//printf("val1=%d val2=%d -result_abs(/)=%d val1*val2=%d\n",val1,val2,-1*(abs(val1)/abs(val2)),val1*val2);
				                int zz=val1*val2;
				                int l=0;
						if(zz==0){l=0;}
						else if(zz<0){l=-1;}
						else if(zz>0){l=1;}
						return l*(abs(val1)/abs(val2));}
				case 4:{if(val1==val2)return 1;else return 0;}
				case 5:{if(val1!=val2)return 1;else return 0;}
				case 6:{return val1&&val2;}
				case 10:{return val1||val2;}
				case 9:{if(val1<=val2)return 1;else return 0;}
				case 12:{return -1*val2;}
				case 11:
					//int addr=val2;
					//printf("addr=%x\n",addr);
					{return pmem_read(val2,2);}
				default:{printf("position:%d No match and type is %d\n",op,op_type);assert(0);}
			}
	}
}
int expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }
  int i;
  for(i=0;i<nr_token;i++){
  if(tokens[i].type=='*'&&(i==0||(tokens[i-1].type!=1&&tokens[i-1].type!=7&&tokens[i-1].type!=8&&tokens[i-1].type!=')'))){
  tokens[i].type=11;
  }
  if(tokens[i].type=='-'&&(i==0||(tokens[i-1].type!=1&&tokens[i-1].type!=7&&tokens[i-1].type!=8&&tokens[i-1].type!=')'))){
  tokens[i].type=12;
  }
  }
  *success=true;
	return eval(0,nr_token-1);
}
