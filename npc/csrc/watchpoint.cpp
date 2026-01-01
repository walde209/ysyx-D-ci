#include "sim.h"

WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;
void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
  }

  head = NULL;
  free_ = wp_pool;
}
WP* new_wp(){
	WP *p;
	for(p=free_;p->next!=NULL;p=p->next){
		if(p->flag==0){
			p->flag=1;
			if(head==NULL){
				head=p;
			}
			return p;
		}
	}
	if(p->flag==0){
		p->flag=1;
		if(head==NULL){
			head=p;
		}
		return p;
	}
	printf("Without watchpoint can be used\n");
	//assert(0);
	return NULL;

}
void free_wp(int no){
	WP *p;
	if(head!=NULL){
	if(head->NO==no){
		head->flag=0;
		head=NULL;
		printf("Free successfully\n");
		return;
	}
	}
	for(p=free_;p->next!=NULL;p=p->next){
		if(p->next->NO==no){
			p->next->flag=0;
			printf("Free successfully\n");
			return;
		}
	}
}
void sdb_watchpoint_display(){
	int i;
	int flag=0;
	for(i=0;i<NR_WP;i++){
		if(wp_pool[i].flag==1){
			printf("NO:%d  expr:\"%s\"  valu:%d\n",wp_pool[i].NO,wp_pool[i].expr,wp_pool[i].valu);
			flag=1;
		}
	}
	if(flag==0){
		printf("Without watchpoint\n");
	}
}
void check_watchpoint(){
  for(int i=0;i<NR_WP;i++){
		  if(wp_pool[i].flag==1){
			  bool flag=false;
			  int tmp_valu=expr(wp_pool[i].expr,&flag);
			  if(flag){
			  if(tmp_valu!=wp_pool[i].valu){
				  printf("Watchpoint change in NO:%d expr:\"%s\" old_valu:0x%08x new_valu:0x%08x\n",wp_pool[i].NO,wp_pool[i].expr,wp_pool[i].valu,tmp_valu);
				  wp_pool[i].valu=tmp_valu;
			  }
			  }else{
				  printf("Error in make tokens\n");
			  }
		  }
	  }
}