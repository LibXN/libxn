#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifdef WIN32
#include "config.win32.h"
#endif

#include <string.h>
#include <stdio.h>

#include "xn.h"
#include "punycode.h"

static int
assert_encoding(
  const codepoint_t ucs4[], size_t ucs4_l,
  const char result[],
  punycode_status status);

static void
  print_punycode_status(punycode_status status);


int main(void)
{

  /* single ASCII */
  if (!assert_encoding((codepoint_t[]){'a'},1,"a-",punycode_success))
    return(1);

  /* single ASCII upper case */
  if (!assert_encoding((codepoint_t[]){'A'},1,"A-",punycode_success))
    return(1);

  /* U+0001 is ASCII and thus results in {0x1,0x2D} */
  if (!assert_encoding((codepoint_t[]){1},1,(char[]){0x01,0x2D,0},punycode_success))
    return(1);

  /* Non-ASCII control U+0080 */
  if (!assert_encoding((codepoint_t[]){0x80},1,"a",punycode_success))
    return(1);

  /* Non-ASCII control character sequence */
  if (!assert_encoding((codepoint_t[])
    {0x80,0x81,0x82,0x83,0x84,0x85},6,"acdefg",punycode_success))
    return(1);

  /* Non-ASCII U+00EA mixed with ASCII */
  if (!assert_encoding((codepoint_t[])
    {0x00EA,0x0078,0x0061,0x006D,0x0070,0x006C,0x0065},7,"xample-hva",punycode_success))
    return(1);

  if (!assert_encoding((codepoint_t[]){0xF6},1,"nda",punycode_success))
    return(1);

  if (!assert_encoding((codepoint_t[]){0xD6},1,"qca",punycode_success))
    return(1);

  if (!assert_encoding((codepoint_t[]){0x10FFFF},1,"dn32g",punycode_success))
    return(1);

  /* Non Code Point U+FFFFFFFF */
  if (!assert_encoding((codepoint_t[]){-1},1,"ww902716a",punycode_success))
    return(1);

  /* Chinese */
  if (!assert_encoding((codepoint_t[])
    {0x3BD9,0x3BDC,0x3BD9,0x3BDF},4,"domain",punycode_success))
    return(1);

  /* Arabic */
  if (!assert_encoding((codepoint_t[])
    {0x067E,0x0627,0x06A9,0x0633,0x062A,0x0627,0x0646},7,"mgbai9azgqp6j",punycode_success))
    return(1);



  return(0);
}

int
assert_encoding(
  const codepoint_t ucs4[], size_t ucs4_l,
  const char result[],
  punycode_status status)
{
  int i;
  char encoded[XN_BUFSZ];
  size_t encoded_l = XN_BUFSZ;
  punycode_status actual;

  printf("punycode_encode{ ");
  for (i = 0; i < ucs4_l; i++)
    printf("U+%04X ", ucs4[i]);
  printf("} ... ");

  /* punycode_status punycode_encode(
    const codepoint_t ucs4[],
    size_t ucs4_l,
    char ascii[],
    size_t *ascii_l); */
  actual = punycode_encode(ucs4,ucs4_l,encoded,&encoded_l);

  print_punycode_status(actual);

  if (status != actual)
  {
    printf("\nstatus does not match\n  expected: ");
    print_punycode_status(status);
    printf("\n");
    return(0);
  }

  encoded[encoded_l] = '\0';
  printf(": \"%s\"", encoded);
  
  if (0 != strcmp(encoded,result))
  {
    char *cp;
    printf("\nresult does not match\n  expected: \"%s\"\n",result);
    
    for (cp = encoded; *cp; cp++)
      printf (" 0x%02X",*cp);
    printf("\n");
    
    return(0);
  }

  printf(" -> OK.\n");
  return(1);
}

void
  print_punycode_status(punycode_status status)
{
#define test_status(t,f) \
  if (f == t) \
  { \
    printf(#f); \
  }
  test_status(status,punycode_success)
  test_status(status,punycode_bad_input)
  test_status(status,punycode_big_output)
  test_status(status,punycode_overflow)
}

