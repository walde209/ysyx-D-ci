#include <am.h>
#include <npc.h>

// 内联汇编读 CSR（mcycle=0xB00，mcycleh=0xB80）
#define read_csr(addr) ({ \
    uint32_t val; \
    __asm__ __volatile__ ("csrr %0, %1" : "=r"(val) : "i"(addr)); \
    val; \
})

#define CSR_MCYCLE    0xB00  // mcycle 低32位 CSR 地址
#define CSR_MCYCLEH   0xB80  // mcycleh 高32位 CSR 地址


void __am_timer_init() {
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  //  uint32_t h=inl(0x02000000 + 0x4c);
  //  uint32_t l=inl(0x02000000 + 0x48);
    uint32_t h, l;
        h  = read_csr(CSR_MCYCLEH);  // 读 CSR 高位
        l  = read_csr(CSR_MCYCLE);   // 读 CSR 低位

   uint64_t time=((uint64_t)h)<<32|(uint64_t)l;
   uptime->us = (time)/(5); //- boot_time;
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}



