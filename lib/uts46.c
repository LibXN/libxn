#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifdef WIN32
#include "config.win32.h"
#endif

#include <string.h> /* memcpy */

// DEBUG
#include <stdio.h>

#include "xn.h"
//#include "uts46.h"

//#include "ucd.h"
#include "xn_parse.h"


/* "xn_results.c" */
extern xn_result
__report_string_result(xn_result,result_list *);
extern xn_result
__report_codepoint_result(xn_result,codepoint_t,result_list *);


/*
Process the mapping step of the Unicode IDNA Compatibility Processing.
See: http://unicode.org/reports/tr46/#Processing */
xn_result
uts46_map_ucd(
  xn_parser processing,
  ucd_record ucd[],
  size_t *ucd_l,
  size_t ucd_maxl,
  bool_t *changed,
  bool_t *ascii,
  result_list *results)
{
  codepoint_t *cp;
  xn_result res = xn_result_OK;
  ucd_record map[UTS46_mapping_maxlength];
  size_t i, map_l;

  for (i = 0, *changed = 0, *ascii = 1; i < *ucd_l; )
  {

    /* If this status value is mapped, disallowed_STD3_mapped or deviation,
    the table also supplies a mapping value for that code point. */

    switch(ucd[i].uts46_status)
    {
      case uts46_status_Valid:
        /* valid:
        Leave the code point unchanged in the string. */
        if (ucd[i++].cp >= 0x80)
          *ascii = 0;
        break;

      case uts46_status_Ignored:
        /* ignored:
        Remove the code point from the string. This is equivalent
        to mapping the code point to an empty string. */
        memmove (ucd+i, ucd+(i+1), (*ucd_l-i-1)*sizeof(ucd_record)),
          (*ucd_l)--, *changed = 1;
        break;

      case uts46_status_Mapped:
        /* mapped:
        Replace the code point in the string by the value for
        the mapping in Section 5, IDNA Mapping Table. */
        goto do_map;

      case uts46_status_Deviation:
        /* deviation:
          - For Transitional Processing, replace the code point in the string
            by the value for the mapping in Section 5, IDNA Mapping Table.
          - For Nontransitional Processing, leave the code point unchanged
            in the string. */
        if (processing & xn_parser_UTS46_Transitional)
          goto do_map;
        if (ucd[i++].cp >= 0x80)
          *ascii = 0;
        break;

      case uts46_status_Disallowed:
        /* disallowed:
        Leave the code point unchanged in the string,
        and record that there was an error. */
        res = __report_codepoint_result(
            xn_invalid__uts46_DISALLOWED,ucd[i].cp,results);
        if (ucd[i++].cp >= 0x80)
          *ascii = 0;
        break;

      case uts46_status_DisallowedSTD3Valid:
        /* disallowed_STD3_valid:
        the status is disallowed if UseSTD3ASCIIRules=true (the normal case);
        implementations that allow UseSTD3ASCIIRules=false would treat the
        code point as valid.*/
        if (processing & xn_parser_UTS46_UseSTD3ASCIIRules)
        {   /* UseSTD3ASCIIRules=true */
          res = __report_codepoint_result(
              xn_invalid__uts46_DISALLOWED_STD3,ucd[i].cp,results);
        }
        if (ucd[i++].cp >= 0x80)
          *ascii = 0;
        break;

      case uts46_status_DisallowedSTD3Mapped:
        /* disallowed_STD3_mapped:
        the status is disallowed if UseSTD3ASCIIRules=true (the normal case);
        implementations that allow UseSTD3ASCIIRules=false would treat the
        code point as mapped. */
        if (processing & xn_parser_UTS46_UseSTD3ASCIIRules)
        {   /* UseSTD3ASCIIRules=true */
          res = __report_codepoint_result(
              xn_invalid__uts46_DISALLOWED_STD3,ucd[i].cp,results);
        }
        goto do_map;

    }
    
    continue;

    do_map:
      /* load mapping sequence into buffer */
      for (cp = ucd[i].uts46_mapping, map_l = 0; *cp; cp++)
      {
        if (!ucd_get_record(*cp,&map[map_l]))
        {  /* fatal: code point out of range */
          return  __report_string_result(
            xn_error__Input_Out_Of_Range,results);
        }
        if (map[map_l++].cp >= 0x80)
          *ascii = 0;
      }
      
      if (*ucd_l + map_l - 1 >= ucd_maxl)
        return __report_string_result(
          xn_fatal__Buffer_Exceeded,results);

      if (map_l > 1 && *ucd_l > i+1)
      { /* right-shift remaing part */
        memmove(ucd+(map_l+i),ucd+(i+1),(*ucd_l-i-1)*sizeof(ucd_record));
      }

      memcpy(ucd+i,map,map_l*sizeof(ucd_record));
      i += map_l, *ucd_l += map_l - 1, *changed = 1;
  }

  return res;
}
