#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifdef WIN32
#include "config.win32.h"
#endif

#include <string.h> /* memcpy */

#include "xn.h"
#include "xn_parse.h"

//#include "ucd.h"
//#include "uts46.h"
#include "punycode.h"
#include "rfc5892_rules.h"

//#include "xn_results.h"
#include "ucnf_normalization.h"



// prepare_input:
//   if (is_ascii(input))
//   {
//     if (is_xn(input))
//     {
//       ulabel = punycode_decode(input);
//     }
//     alabel = input;
//   }
//   else
//   {
//     input = uts46_map(input);
//     if (is_ascii(input))
//     {
//       input = ulabel;
//       goto prepare_input;
//     }
//     input = ucd_normalize(input);
//     ulabel = input;
//   }

extern xn_result __report_string_result
	(xn_result,result_list *);

extern xn_result __report_codepoint_result
  (xn_result, codepoint_t, result_list *);


extern xn_result __report_position_result
	(xn_result, codepoint_t, size_t, result_list *);

extern xn_result __report_punycode_result
	(xn_result, punycode_status, result_list *);



/* ASCII test */
#define is_ASCII(cp) (cp < 0x80)

/* convert ASCII letters to lower case */
#define ascii_to_lower(cp) ( \
  (cp <= 'Z' && cp >= 'A') ? cp + 0x20 : cp )

/* 0..2C, 2E..2F, 3A..40, 5B..60, and 7B..7F. */
#define is_non_LDH(cp) ( \
  cp <= 0x2C || cp == 0x2E || cp == 0x2F || \
  (cp >= 0x3A && cp <= 0x40) || \
  (cp >= 0x5B && cp <= 0x60) || \
  (cp >= 0x7B && cp <= 0x7F))

/* hyphen '-' on 3rd and 4th position */
#define has_hyphen34(p,l) \
  ( l >= 4 && (0x2D == (p+2)->cp && 0x2D == (p+3)->cp) )

/* leading hyphen '-' */
#define leading_hyphen(p) \
	( 0x2D == *p )

#define leading_hyphen__rec(p) \
	( 0x2D == (p)->cp )

/* trailing hyphen '-' */
#define trailing_hyphen(p,l) \
	( 0x2D == *(p+(l-1)) )

#define trailing_hyphen__rec(p,l) \
	( 0x2D == (p+(l-1))->cp )

/* starting with "xn" case insensitive */
#define starts_with_xn(p) \
  ( (0x78 == p->cp || 0x58 == p->cp) && \
    (0x6E == (p+1)->cp || 0x4E == (p+1)->cp) )

/* Mark is defined to be the same as:
  Spacing_Mark OR Nonspacing_Mark OR Enclosing_Mark. */
#define is_gc_mark(gc) \
  ( gc == ucd_gc_Mn || gc == ucd_gc_Mc || gc == ucd_gc_Me )


xn_result
xn_parse_label(
  xn_parser processing,
  const ucd_record input[],
  size_t input_l,
  ucd_record u_label[],
  size_t *u_label_l,
  char a_label[],
  size_t *a_label_l,
  result_list *results)
{
  xn_result res = xn_result_OK;
  bool_t is_hyphen34, is_ascii, is_xn, nfc_applied = 0;
  const ucd_record *input_p = input, *up;
  size_t i;

prepare_input:

  /* check for empty label */
  if (input_l == 0)
    return  __report_string_result(
			xn_error__Input_Empty,results);

  /* hyphen in 3rd and 4th position */
  is_hyphen34 = has_hyphen34(input_p,input_l);

  /* check for ACE prefix, case insensitive */
  is_xn = is_hyphen34 && starts_with_xn(input_p);

  /* check whether it's all ASCII and report non-LDH */
  for (is_ascii = 1, i = 0, up = input_p; i < input_l; i++, up++)
  {
    if (is_ASCII(up->cp))
    {
      if ((processing & xn_validate_ASCII_LDH) && is_non_LDH(up->cp))
      {     /* non-LDH ASCII */
        res = __report_position_result(
            xn_invalid__ASCII_Non_LDH,up->cp,i,results);
      }

      /* copy to alabel */
      if (is_xn || (processing & xn_parser_ASCII_To_Lower))
        a_label[i] = (char)ascii_to_lower(up->cp);
      else
        a_label[i] = (char)up->cp;
    }
    else
    {
      if (is_xn)  /* fatal: non-ASCII ACE string */
        return  __report_position_result(
          xn_error__ACE_Non_ASCII,up->cp,i,results);
      is_ascii = 0;
    }
  }
  
  if (is_ascii)
  {
    *a_label_l = input_l;
    goto process_ascii; /* go on with A-label */
  }
    
  /* U-label pre-processing */
  memcpy(u_label,input_p,input_l*sizeof(ucd_record)),
    *u_label_l = input_l;

  /* UTS46 mapping */
  if (processing & xn_parser_UTS46_Map)
  {
    bool_t uts46_changed;

    if (xn_result_ABORT & (res = uts46_map_ucd(
      processing,
      u_label,
      u_label_l,
      XN_BUFSZ,
      &uts46_changed,
      &is_ascii,
      results)))
    {  /* stop processing */
      return res;
    }

    if (is_ascii)
    { /* string has been changed to ASCII during UTS46 mapping. */
      input_p = u_label, input_l = *u_label_l;
      goto prepare_input; /* loop-save: ASCII input never appears here. */
    }
  }

  /* normalization NFC */
  if (processing & xn_process_NFC)
  {
    ucnf_normalization_result nfc_res;

    if (ucnf_OK != (nfc_res = ucnf_normalize(
        u_label,u_label_l,XN_BUFSZ,xn_ucnf_form_C)))
    {  /* normalization failed */
      if (nfc_res == ucnf_Buffer_Exceeded)
        return  __report_string_result(
          xn_fatal__Buffer_Exceeded,results);
      else
        return  __report_string_result(
          xn_fatal__Unknown_Error,results);
    }
    
    nfc_applied = 1; /* remember input has been normalized */
  }

  /* U-label validation */
  goto validate_ulabel;
  
process_ascii:
	/* A-label */

  if (is_xn)
  {
    punycode_status puny_result;
    codepoint_t puny[XN_BUFSZ];
    size_t puny_l;

    /* punycode decoding */
    if (*a_label_l > 4)
    {
      if (punycode_success != (puny_result = punycode_decode(
          a_label+4,*a_label_l-4,puny,&puny_l)))
      {   /* fatal: punycode decoding failed */
        return  __report_punycode_result(
          xn_error__Puncode_Decoding_Failure,puny_result,results);
      }
    }
    else
    {   /* invalid ACE */
      return __report_string_result(
        xn_error__ACE_Invalid,results);
    }

    /* puncode decoding was successful */
    if (!ucd_get_record_string(puny_l,puny,u_label))
      return  __report_string_result( /* out of range */
        xn_error__Input_Out_Of_Range,results);
    *u_label_l = puny_l;

		goto validate_ulabel;
  }
  else
  {
    /* copy to u-label */
    for (i = 0; i < *a_label_l; ++i) {
      if (!ucd_get_record((codepoint_t)a_label[i], &u_label[i]))
        return  __report_string_result( /* cannot actually happen */
          xn_fatal__Unknown_Error,results);
    }
    *u_label_l = *a_label_l;
  }
  
  /* non-XN A-label validation */

	/* The label must not contain a U+002D HYPHEN-MINUS character
	 in both the third position and fourth positions */
  if ((processing & xn_validate__Hyphen34) && is_hyphen34)
    res |=  __report_string_result(
      xn_invalid__Hyphen34,results);

  /* The label must not begin with a U+002D HYPHEN-MINUS character. */
  if ((processing & xn_validate__Leading_Hyphen) &&
      leading_hyphen(a_label))
    res |=  __report_string_result(
      xn_invalid__Leading_Hyphen,results);

  /* The label must not end with a U+002D HYPHEN-MINUS character. */
  if ((processing & xn_invalid__Trailing_Hyphen) &&
      trailing_hyphen(a_label,*a_label_l))
    res |=  __report_string_result(
      xn_invalid__Leading_Hyphen,results);

  goto finish;

validate_ulabel:
  /* U-label validation */

  /* TR#46
  Unicode IDNA Compatibility Processing
  http://unicode.org/reports/tr46/#Validity_Criteria
  4.1 Validity Criteria
    1. The label must be in Unicode Normalization Form NFC.
    2. The label must not contain a U+002D HYPHEN-MINUS character in both the third position and fourth positions.
    3. The label must neither begin nor end with a U+002D HYPHEN-MINUS character.
    4. The label must not contain a U+002E ( . ) FULL STOP.
    5. The label must not begin with a combining mark, that is: General_Category=Mark.
    6. Each code point in the label must only have certain status values according to Section 5, IDNA Mapping Table:
        6.1 For Transitional Processing, each value must be valid.
        6.2 For Nontransitional Processing, each value must be either valid or deviation.
  */
  
  /* The label must be in Unicode Normalization Form NFC. */
  if (!nfc_applied && (processing & xn_validate__NFC))
  {
    if (!ucnf_is_normalized
        (u_label,*u_label_l,xn_ucnf_form_C))
      res |= __report_string_result(
        xn_invalid__non_NFC,results);
  }

	/* The label must not contain a U+002D HYPHEN-MINUS character
	 in both the third position and fourth positions */
	if ((processing & xn_validate__Hyphen34) &&
			has_hyphen34(u_label,*u_label_l))
    res |=  __report_string_result(
      xn_invalid__Hyphen34,results);

  /* The label must not begin with a U+002D HYPHEN-MINUS character. */
  if ((processing & xn_validate__Leading_Hyphen) &&
      leading_hyphen__rec(u_label))
    res |=  __report_string_result(
      xn_invalid__Leading_Hyphen,results);

  /* The label must not end with a U+002D HYPHEN-MINUS character. */
  if ((processing & xn_validate__Trailing_Hyphen) &&
      trailing_hyphen__rec(u_label,*u_label_l))
    res |=  __report_string_result(
      xn_invalid__Leading_Hyphen,results);

  /* The label must not begin with a combining mark, that is:
  General_Category=Mark.*/
  if ((processing & xn_validate__Leading_Combining_Marks) &&
      is_gc_mark(u_label->general_category))
    res |=  __report_codepoint_result(
      xn_invalid__Leading_Combining_Mark,u_label->cp,results);




finish:


  return res;
}

/* ==== static ==== */




