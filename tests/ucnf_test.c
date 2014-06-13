#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifdef WIN32
#include "config.win32.h"
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "xn.h"
#include "ucnf_normalization.h"

static void process
  (const codepoint_t cps[], size_t cps_l, ucnf_form nf);

int main (int argc, char *argv[])
{
  ucnf_form nf;
  codepoint_t cps[XN_BUFSZ];
  size_t cps_l,i;
  int state = 0;
  
  while (1)
  {
    char buf[256];

    if (state == 0)
    {
      /* Normalization form */
      if (EOF == scanf("%s",buf))
        break;
      if (0 == strcmp(buf,"D"))
        nf = xn_ucnf_form_D;
      else if (0 == strcmp(buf,"C"))
        nf = xn_ucnf_form_C;
      else if (0 == strcmp(buf,"KC"))
        nf = xn_ucnf_form_KC;
      else if (0 == strcmp(buf,"KD"))
        nf = xn_ucnf_form_KD;
      else
      {
        fprintf(stderr,
          "Normalization form not recognized: '%s'\n",buf);
        exit(1);
      }
      state++;
      continue;
    }
    
    if (state == 1)
    {
      /* String length */
      if (EOF == scanf("%u",&cps_l))
        break;
      if (!(cps_l > 0 && cps_l < XN_BUFSZ))
      {
        fprintf(stderr,
          "String length greater than 0 and less than %u expected.\n",XN_BUFSZ);
        exit(1);
      }
      state++, i = 0;
      continue;
    }
    
    if (i == cps_l)
    {
      /* finished reading code points */
      process(cps,cps_l,nf);
      fflush(stdout);
      state = 0;
      continue;
    }
    
    /* Next code point */
    if (EOF == scanf("%X",&cps[i++]))
      break;
  }

  return(0);
}

void process
  (const codepoint_t cps[], size_t cps_l, ucnf_form nf)
{
  ucd_record ucd[XN_BUFSZ], res[XN_BUFSZ];;
  ucnf_quickcheck_result qc;
  size_t res_l,i;

  /* load UCD records */
  for (i = 0; i < cps_l; i++)
  {
    if (!ucd_get_record(cps[i],&ucd[i]))
    {
      fprintf(stderr,
        "Input was not assigned as a Unicode Code point: 0x%X.\n",cps[i]);
      exit(1);
    }
  }

  /* quickcheck result */
  qc = ucnf_quickcheck(ucd,cps_l,nf);
  switch (qc)
  {
    case nf_quick_check_Yes:
      printf("YES");
      break;
    case nf_quick_check_No:
      printf("NO");
      break;
    case nf_quick_check_Maybe:
      printf("MAYBE");
      break;
  }

  /* perform normalization */
  memcpy(res,ucd,cps_l*sizeof(ucd_record)), res_l = cps_l;
  if (0 != ucnf_apply_normalization(res,&res_l,XN_BUFSZ,nf))
  {
    fprintf(stderr,
      "Normalization process failed unexpectedly.\n");
    exit(1);
  }

  /* normalization result */
  for (i = 0; i < res_l; i++)
    printf(" %04X",res[i].cp);
  
  printf("\n");
}


