#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  size_t n=0;
  if(s==NULL){return 0;}
  while(s[n]!='\0'){
	  n++;
  }
  return n;
}

char *strcpy(char *dst, const char *src) {
	if(src==NULL){return dst;}
	char *reg=dst;
	while(*src!='\0'){
		*reg=*src;
		reg++;
		src++;
	}
	*reg='\0';
	return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  if(src==NULL){return dst;}
  char *reg=dst;
  size_t i;
  for(i=0;i<n;i++){
	  if(src[i]=='\0'){dst[i]='\0';break;}
	  dst[i]=src[i];
  }
  if(i==n){dst[i]='\0';}
  return reg;
}

char *strcat(char *dst, const char *src) {
	char *reg=dst;
	while(*reg!='\0'){
		reg++;
		}
	while(*src!='\0'){
		*reg=*src;
		reg++;
		src++;
	}
	*reg='\0';
	return dst;
}

int strcmp(const char *s1, const char *s2) {
  size_t i=0;
  while(s1[i]!='\0'&&s2[i]!='\0'){
	  if(s1[i]==s2[i]){i++;continue;}
	  else{
		  if(s1[i]>s2[i]){return 1;}
		  else{return -1;}
	  }
  }
  if(s1[i]!='\0'&&s2[i]=='\0'){return 1;}
  if(s1[i]=='\0'&&s2[i]!='\0'){return -1;}
  return 0;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  size_t i=0;
  for(i=0;i<n;i++){
	  if(s1[i]=='\0'&&s2[i]!='\0'){return -1;}
	  if(s1[i]!='\0'&&s2[i]=='\0'){return 1;}
	  if(s1[i]=='\0'&&s2[i]=='\0'){return 0;}
	  if(s1[i]==s2[i]){continue;}
	  else{
		  if(s1[i]>s2[i]){return 1;}
		  else{return -1;}
	  }
  }
  return 0;

}

void *memset(void *s, int c, size_t n) {
	char *r=(char *)s;
	while(n--){
		*(r++)=c;
	}
	return s;
}

void *memmove(void *dst, const void *src, size_t n) {
	if(dst<src){
		char *d=(char *)dst;
		char *s=(char *)src;
		while(n){
			*d=*s;
			d++;
			s++;
			n--;
		}
	}else{
		char *d=(char *)(dst+n-1);
		char *s=(char *)(src+n-1);
		while(n--){
			*d--=*s--;
		}
	}
	return dst;
}


void *memcpy(void *out, const void *in, size_t n) {
	char *o=(char *)out;
	char *i=(char *)in;
	while(n){
		*o=*i;
		o++;
		i++;
		n--;
	}
	return out;
}

int memcmp(const void *s1, const void *s2, size_t n) {
	char *x=(char *)s1;
	char *y=(char *)s2;
	size_t i;
	for(i=0;i<n;i++){
		if(x[i]==y[i]){continue;}
		else{
			if(x[i]<y[i]){return -1;}
			else{return 1;}
		}
	}
	return 0;
}

#endif
