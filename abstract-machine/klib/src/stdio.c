#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)
static char buffer[32768];
static void init_char(char *str);
int printf(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  init_char(buffer);
  int ret = vsprintf(buffer, fmt, ap);
  for(int i=0; i<ret; i++) {
    putch(buffer[i]);
  }
  va_end(ap);
  return ret;
  
}
static void init_char(char *str){
  int n;
  n=strlen(str);
  for(int i=0; i<n; i++) str[i]=0;
}
static char *number(char *str, int num, int base)
{
  int tmp[100], i = 0;
  if(num == 0) *str++ = '0';
  if(num < 0)
  {
    *str++ = '-';
    num = -num;
  }
  while(num)
  {
    tmp[i++] = num % base;
    num /= base;
  }
  
  i--;
  
  while(i >= 0) *str++ = tmp[i--] + '0';   
  
  return str;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  char *str=out;
  char *temp=NULL;
  int len;
  int num;
  //int zero=0;
  //int width=0;
  while(*fmt!='\0'){
    //putch(*fmt);
    if(*fmt=='%'){
      fmt++;
      //putch(*fmt);
      while((*fmt>='0')&&(*fmt<='9')){
        fmt++;
        //if(*fmt=='0'){zero=1;}
        //else{width=(*fmt-'0');}
      }
      switch(*fmt){
        case 'd':
          num = va_arg(ap, int);
          str = number(str,num,10);
          fmt++;
          break;
        case 's':
          init_char(temp);
          temp = va_arg(ap, char*);
          len = strlen(temp);
          //for(int i=0; i<len; i++) putch(temp[i]);
          while(len--) *str++ = *temp++;
          fmt++;
          //strcpy(str,temp);
          break;
        case 'c':
          *str++ = (unsigned char)va_arg(ap, int);
          fmt++;
          break;
        case 'x':
          num = va_arg(ap, int);
          //init_char(temp);
          str = number(str,num,16);
          /*len = strlen(temp);
            while((width-len)>0){
            if(zero==1){*str++ = '0';}
            else{*str++ = ' ';}
            width--;
          }
          width = 0;
          for(int i=0; i<len; i++) *str++ = temp[i];*/
          fmt++;
          break;
        case 'l':fmt++;
          switch(*fmt){
            case 'd':
              num = va_arg(ap, int);
              str = number(str,num,10);
              break;
            case 'x':
              num = va_arg(ap, int);
              str = number(str,num,16);
              break;
            default:putch('\n');putch('l');putch(*fmt);putch('\n');panic("Not implemented");
              break;
          }
          fmt++;
          break;
        default:putch('\n');putch(*fmt);putch('\n');panic("Not implemented");
          break;
      }

    }else{
      *str++ = *fmt++;
    }
    
  }
  *str = '\0';
  //for(int i=0; i<str-out; i++) {putch(out[i]);}
  return str-out;

}


int sprintf(char *out, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int ret;
  init_char(out);
  ret = vsprintf(out, fmt, ap);
  //for(int k=0; k<ret; k++) putch(out[k]);
  va_end(ap);
  return ret;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
