#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifdef WIN32
#include "config.win32.h"
#endif

#include <stdio.h>
#include <string.h>


#include "xn.h"
#include "punycode.h"
#include "xn_parse.h"
#include "rfc5892_rules.h"
//#include "xn_results.h"

/* Error reporting utilities and strings. */

static const char *result_messages[];

/* get message offset from result code */
#define message_index(res) ( \
  ((int)res & ~( xn_result_FATAL | xn_result_ERROR | xn_result_INVALID )) - 1)

/* Get a friendly code point string representaion. */
static void __codepoint_sprintf(char buf[],codepoint_t cp);


/* Report a result concerning the whole string. */
xn_result
  __report_string_result(
    xn_result result,
    result_list *result_p)
{
  if (result_p->errors && result_p->count < result_p->max_count)
  {
    (result_p->errors + result_p->count)->result = result;
    strcpy(
      (result_p->errors + result_p->count++)->message,
      result_messages[message_index(result)]);
  }
  return result;
}

/* Report a result concerning a particular code point,
expecting a message containing a single '%s'. */
xn_result
__report_codepoint_result(
  xn_result result,
  codepoint_t cp,
  result_list *result_p)
{
  if (result_p->errors && result_p->count < result_p->max_count)
  {
    char buf[100];

    __codepoint_sprintf(buf,cp);
    (result_p->errors + result_p->count)->result = result;
    sprintf(
      (result_p->errors + result_p->count++)->message,
      result_messages[message_index(result)],buf);
  }
  return result;
}

/* Report a result concerning a particular code point on a specific position,
expecting a message containing '%s' and '%d'.
The position parameter is expected to start by 0 and incremented by 1. */
xn_result
  __report_position_result(
    xn_result result,
    codepoint_t cp,
    size_t pos,
    result_list *result_p)
{
  if (result_p->errors && result_p->count < result_p->max_count)
  {
    char buf[100];

    __codepoint_sprintf(buf,cp);
    (result_p->errors + result_p->count)->result = result;
    sprintf(
      (result_p->errors + result_p->count++)->message,
      result_messages[message_index(result)],buf,pos+1);
  }
  return result;
}

/* Report punycode status */
xn_result
  __report_punycode_result(
    xn_result result,
    punycode_status status,
    result_list *result_p)
{
  if (result_p->errors && result_p->count < result_p->max_count)
  {
    (result_p->errors + result_p->count)->result = result;
    sprintf(
      (result_p->errors + result_p->count++)->message,
      result_messages[message_index(result)],
      punycode_status_string[status]);
  }
  return result;
}

/* Report rfc5892 contextual rule result. */
xn_result
  __report_rfc5892_context_result(
    xn_result result,
    codepoint_t cp,
    enum RFC5892_Property rfc5892,
    rfc5892_context_result context_result,
    const char *rule_name,
    result_list *result_p)
{
  if (result_p->errors && result_p->count < result_p->max_count)
  {
    char buf[100],rule_info[100];
      
    if (rule_name != NULL)
    {  /* A rule was found but not satisfied */
      sprintf(rule_info,"'%s' evaluates to %s",rule_name,
        ((context_result == rfc5892_context_False) ?
          "False" : "Undef"));
    }
    else
    {
      strcpy(rule_info,"no rule was found");
    }

    __codepoint_sprintf(buf,cp);
    (result_p->errors + result_p->count)->result = result;
    sprintf(
      (result_p->errors + result_p->count++)->message,
      result_messages[message_index(result)],
      buf, ((rfc5892 == rfc5892_CONTEXTJ) ? "CONTEXTJ" : "CONTEXTJ"),
      rule_info);
  }
  return result;
}


/* ==== static ==== */

void __codepoint_sprintf(char buf[],codepoint_t cp)
{
  if ((cp >= 0x20 && cp <= 0x7E) && cp != 0x27)
  {
    sprintf(buf,"'%c'",(char)cp);  /* printable ASCII */
  }
  else
  {
    ucd_record r;
    if (ucd_get_record(cp,&r))
      sprintf(buf,"U+%04X (%s)",cp,r.name);
    else
      sprintf(buf,"U+%04X",cp);
  }
    
}

/* common phrases */
#define serious_bug_warning " This may indicate a serious bug."
#define invalid_RFC8591 " (invalid according to RFC 8591)"
#define rejected_RFC8592 " - string rejected according to RFC 8592"

/* Keep in sync with enum XN_RESULT ("xn_parse.h")! */
static const char *result_messages[] = {

  /* xn_fatal__Unknown_Error */
  "An unknown error occured." serious_bug_warning,

  /* xn_fatal__Memory_Fault */
  "Memory access failure." serious_bug_warning,
  
  /* xn_fatal__Integer_Overflow */
  "An integer overflow has been detected." serious_bug_warning,

  /* xn_fatal__Buffer_Exceeded */
  "Input exceeds the maximum length of 256 characters.",

  /* xn_error__Input_Too_Long */
  "Output would exceed the given buffer size.",
  
  /* xn_error__Input_Empty */
  "Input was empty.",

  /* xn_error__Input_Out_Of_Range */
  "Input contains a value outside the Unicode Code Point Range.",

  /* xn_error__Puncode_Decoding_Failure */
  "The Punycode decoding procedure failed with status '%s'.",

  /* xn_error__Puncode_Encoding_Failure */
  "The Punycode encoding procedure failed with status '%s'.",

  /* xn_error__ACE_Non_ASCII */
  "Label starts with the ACE-prefix but contains non-ASCII "
  "character %s at position %d.",

  /* xn_error__ACE_Not_Normalized */
  "The decoding of the given ACE string is not normalized (NFC).",

  /* xn_error__ACE_Mismatch */
  "The given ACE string is invalid because it doesn't match the one obtained "
  "from re-encoding the Unicode sequence.",

  /* xn_error__ACE_Invalid */
  "Invalid ACE string.",

  /* xn_invalid__Leading_Hyphen */
  "Label has leading hyphen '-'" invalid_RFC8591 ".",

  /* xn_invalid__Trailing_Hyphen */
  "Label has trailing hyphen '-'" invalid_RFC8591 ".",

  /* xn_invalid__Hyphen34 */
  "Label has hyphen '-' on 3rd and 4th position" invalid_RFC8591 ".",

  /* xn_invalid__ASCII_Non_LDH */
  "Label contains non-LDH character %s at position %d" invalid_RFC8591 ".",

  /* xn_invalid__Label_Too_Long */
  "Label exceeds the maximum length of 63 characters" invalid_RFC8591 ".",

  /* xn_invalid__non_NFC */
  "Label is not in Unicode Normalization Form NFC.",

  /* xn_invalid__uts46_DISALLOWED */
  "Label contains the code point %s, wich is DISALLOWED "
  "according to Unicode Technical Standard #46.",

  /* xn_invalid__uts46_DISALLOWED_STD3 */
  "Label contains the code point %s, wich is DISALLOWED "
  "according to Unicode Technical Standard #46, where UseSTD3ASCIIRules is true.",

  /* xn_invalid__rfc5892_UNASSIGNED */
  "Label contains the code point %s, wich is UNASSIGNED" rejected_RFC8592 ".",

  /* xn_invalid__rfc5892_DISALLOWED */
  "Label contains the code point %s, wich is DISALLOWED" rejected_RFC8592 ".",

  /* xn_invalid__rfc5892_CONTEXT */
  "A contextual rule is required for code point %s, wich is %s: %s"
  rejected_RFC8592 ".",
  
  /* xn_invalid__Leading_Combining_Mark */
  "Label starts with the character %s wich has General Category Mark"

};

