#include <string.h>
#include <stdio.h>

#include "xn.h"
#include "ucd.gen.h"
#include "xn_parse.h"

static int test(
  const codepoint_t input[],
  size_t input_l);


int main(void)
{

  printf("Unicode Version: %s\n\n", ucd_version());


   test((codepoint_t[]){'A'},1);
//
//
   // non-LDH
   test((codepoint_t[]){'a',0x7f,'b'},3);

//
//   // Fake A-Label
   test((codepoint_t[]){'x','n','-','-','b'},5);
//
//
//
//   // punycode_decode('a') = U+0080
//   test((codepoint_t[]){'x','n','-','-','a'},5);
//


//    test((codepoint_t[]){'b',0x2060,'a'},3);



//   // 0x1103,0x1171,0x11BE => NFC: 0xB4BB
//   test((codepoint_t[]){0x1103,0x1171,0x11BE},3);
//
//   // punycode_encode(0x1103,0x1171,0x11BE) = 1pd4t2h
//   test((codepoint_t[]){'x','n','-','-','1','p','d','4','t','2','h'},11);
//
//   // lower(U+00C4) = U+00E4
//   test((codepoint_t[]){0x00C4},1);
//
//   // xn--u-ccb.com
//   test((codepoint_t[]){'x','n','-','-','u','-','c','c','b'},9);
//
//   // a\u200Cb
//   test((codepoint_t[]){'a',0x200C,'b'},3);
//
//   // \u066E.\uDB07\uDE6C\uD933\uDD23\uD955\uDEA8
//   test((codepoint_t[]){0xDB07, 0xDE6C, 0xD933, 0xDD23, 0xD955, 0xDEA8},6);
//


  return(0);
}

int test(
  const codepoint_t input[],
  size_t input_l)
{
  int i;

  //xn_error_report errors[XN_BUFSZ];
  //size_t errors_l = XN_BUFSZ;
  
  char alabel[XN_BUFSZ];
  size_t alabel_l = XN_BUFSZ;

  codepoint_t ulabel[XN_BUFSZ];
  size_t ulabel_l = XN_BUFSZ;

  ucd_record ucd[XN_BUFSZ];
  size_t ucd_record_l = XN_BUFSZ;

  xn_parser parser = (xn_parser)-1;

  xn_result result;
  result_list results;
  results.max_count = 3;
  results.count = 0;
  results.errors = (xn_error_report *)malloc(results.max_count*sizeof(xn_error_report));

  
//   printf("input(%d):",input_l);
//   for (i = 0; i < input_l; i++)
//     printf(" U+%04X",input[i]);
//   printf("\n");


  /* int ucd_get_record_string(size_t, codepoint_t[], ucd_record[]); */
  if (!ucd_get_record_string( input_l, input, ucd))
  {
    printf("ucd_get_record_string() failed\n");
    return 0;
  }

  printf("ucd(%d):",input_l);
  for (i = 0; i < input_l; i++)
    printf(" U+%04X",ucd[i].cp);
  printf("\n");

//return 0;

  /*
  xn_result
  xn_parse_label(
    xn_parser processing,
    const ucd_record input[],
    size_t input_l,
    ucd_record u_label[],
    size_t *u_label_l,
    char a_label[],
    size_t *a_label_l,
    result_list *results)  */
  result = xn_parse_label(
    parser,
    ucd,
    input_l,
    ulabel,
    &ulabel_l,
    alabel,
    &alabel_l,
    &results);
    
  if (result == 0)
  {
    printf("ulabel(%d):",ulabel_l);
    for (i = 0; i < ulabel_l; i++)
      printf(" U+%04X",ulabel[i]);
    printf("\n");

    printf("alabel(%d):",alabel_l);
    for (i = 0; i < alabel_l; i++)
      printf(" '%c'",alabel[i]);
    printf("\n");

  }
  else
  {
    int offs = xn_get_result_offset(result);
    printf("result-offset: %d\n", offs);

  }

  if (results.count > 0)
  {
    for (i = 0; i < results.count; i++)
    {
      int res_class = xn_get_result_class(results.errors[i].result);
      int res_offset = xn_get_result_offset(results.errors[i].result);

      printf("error[%d]: ",i);
      switch (res_class)
      {
        case xn_result_FATAL:
          printf("xn_result_FATAL");
          break;
        case xn_result_ERROR:
          printf("xn_result_ERROR");
          break;
        case xn_result_INVALID:
          printf("xn_result_INVALID");
          break;
      }
      printf (" (%d)", res_offset);
      printf(" \"%s\"\n", results.errors[i].message);

    }
  }

  printf("--\n");


  return result == xn_result_OK;
}






