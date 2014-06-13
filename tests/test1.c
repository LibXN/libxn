#include <stddef.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>

int main(void)
{

  uint32_t s = 0xD6FC;
  uint32_t t = 0x0334;
  uint32_t c;
  
  printf("s = U+%04X, t = U+%04X\n", s, t);
  
  c = s << 16 | t;
  printf("c = U+%04X\n", c);
  
  c = (uint32_t)-1;
  printf("c = U+%010x\n", c);



  

  return 0;
}