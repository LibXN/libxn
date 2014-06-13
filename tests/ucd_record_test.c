#include <stdio.h>

#include "xn.h"
#include "ucd.gen.h"



int main(void)
{

  uint32_t cp = 0x10C7;
  struct UCD_RECORD rec;
  
  printf("struct UCD_RECORD: %d\n", sizeof(struct UCD_RECORD));
  
  // U+FDFA ARABIC LIGATURE SALLALLAHOU ALAYHE WASALLAM
  // -> 18 decomposition points
  
  
  // >> U+1D163 MUSICAL SYMBOL SIXTY-FOURTH NOTE: (2): U+1D15F, U+1D171
  // -> decomposition > 0xFFFF
  
  // 00EA;LATIN SMALL LETTER E WITH CIRCUMFLEX;Ll;0;L;0065 0302;;;;N;LATIN SMALL LETTER E CIRCUMFLEX;;00CA;;00CA
  if (ucd_get_record(cp, &rec))
  {
    int i;
    
    printf("ok: U+%04X %s\n", rec.cp, rec.name);
    printf("script: %d\n", rec.script);
    printf("general_category: %d\n", rec.general_category);
    printf("uppercase: U+%04X\n", rec.uppercase);
    printf("lowercase: U+%04X\n", rec.lowercase);
    printf("rfc5892: %d\n", rec.rfc5892);
    printf("dt: %d\n", rec.dt);
    printf("joining_type: %d\n", rec.joining_type);
    
    printf("uts46_status: %d\n", rec.uts46_status);
    printf("uts46_mapping:");
    for (i=0; rec.uts46_mapping[i]; i++)
    {
      printf(" U+%04X", rec.uts46_mapping[i]);
    }
    printf("\n");

    //printf("decomposition_map_length: %d\n", rec.decomposition_map_length);
    printf("decomposition_map:");
    for (i=0; rec.decomp[i]; i++)
    {
      printf(" U+%04X", rec.decomp[i]);
    }
    printf("\n");
    

  }




  return (0);
}
