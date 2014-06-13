#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifdef WIN32
#include "config.win32.h"
#endif

#include <stddef.h>
#include <stdlib.h>
#include <stdint.h>

#include "xn.h"
#include "rfc5893_bidi.h"

/*
RFC 5891

4.2.3.4. Labels Containing Characters Written Right to Left

   If the proposed label contains any characters from scripts that are
   written from right to left, it MUST meet the Bidi criteria [RFC5893].


RFC 5893

An RTL label is a label that contains at least one character of type
   R, AL, or AN.

   An LTR label is any label that is not an RTL label.


Dazu passt:
http://cpansearch.perl.org/src/CFAERBER/Net-IDN-Encode-2.001/lib/Net/IDN/UTS46.pm
$bidi++ if !$bidi && ($l =~ m/[\p{Bc:R}\p{Bc:AL}\p{Bc:AN}]/);

*/



/*
RFC 5893                   IDNA Right to Left                August 2010

2. The Bidi Rule


   The following rule, consisting of six conditions, applies to labels
   in Bidi domain names.  The requirements that this rule satisfies are
   described in Section 3.  All of the conditions must be satisfied for
   the rule to be satisfied.

   1.  The first character must be a character with Bidi property L, R,
       or AL.  If it has the R or AL property, it is an RTL label; if it
       has the L property, it is an LTR label.

   2.  In an RTL label, only characters with the Bidi properties R, AL,
       AN, EN, ES, CS, ET, ON, BN, or NSM are allowed.

   3.  In an RTL label, the end of the label must be a character with
       Bidi property R, AL, EN, or AN, followed by zero or more
       characters with Bidi property NSM.

   4.  In an RTL label, if an EN is present, no AN may be present, and
       vice versa.

   5.  In an LTR label, only characters with the Bidi properties L, EN,
       ES, CS, ET, ON, BN, or NSM are allowed.

   6.  In an LTR label, the end of the label must be a character with
       Bidi property L or EN, followed by zero or more characters with
       Bidi property NSM.

*/


#define report_result(cond,pos,res,res_l,res_maxl) \
  if (res_l < res_maxl) { \
    res[res_l].condition = cond, res[(res_l)++].position = pos; }

/* Whether a label need bidi validation. */
int rfc5893_needs_bidi_validation(
  const ucd_record label[],
  size_t label_l)
{

/*
How to determine whether the Bidi Rule (RFC 5893) has to be applied or not?
(Note that, for example, the label "1" doesn't match condition 1, so we
clearly cannot apply the rule to any label.)

RFC 5891
> 4.2.3.4. Labels Containing Characters Written Right to Left
>
>   If the proposed label contains any characters from scripts that are
>   written from right to left, it MUST meet the Bidi criteria [RFC5893].

This sounds a bit obscure, because "Labels Containing RTL-Characters" and
"Labels containing characters from RTL-scripts" is not necessarily the same at
first sight (abbreviating "written from right to left" with "RTL" here).
Moreover, where is the script-direction defined? At least, UCD's Script.txt
doesn't state a RTL-property for scripts.

RFC 5893
> An RTL label is a label that contains at least one character of type
>   R, AL, or AN.
>
>   An LTR label is any label that is not an RTL label.

So, the header of 4.2.3.4. [RFC5891] together with this enumeration of RTL-characters
gives a feasible rule:
  If and only if the proposed label contains any characters of type R, AL, or AN,
  it MUST meet the Bidi criteria.
*/



// TODO

return 0;
}

int rfc5893_validate_bidi(
  const ucd_record label[],
  size_t label_l,
  bidi_direction *dir,
  bidi_result results[],
  size_t *results_l)
{
  int res = 1;
  size_t results_maxl = *results_l, i;

  *results_l = 0;
  *dir = bidi_direction_Undef;

  if (label_l == 0)
    return res;

  /*
   1.  The first character must be a character with Bidi property L, R,
       or AL.  If it has the R or AL property, it is an RTL label; if it
       has the L property, it is an LTR label. */
  switch (label[0].bidi_class)
  {

    case ucd_bidi_L:
      *dir = bidi_direction_LTR;
      break;

    case ucd_bidi_R:
    case ucd_bidi_AL:
      *dir = bidi_direction_RTL;
      break;

    default:
      res = 0; /* condition B1 violated */
      report_result(1,0,results,*results_l,results_maxl);
      break;
  }


  if (*dir == bidi_direction_RTL)  /* RTL conditions 1 - 4 */
  {
    size_t pos_EN, pos_AN; /* condition 4 */

    /*
     2.  In an RTL label, only characters with the Bidi properties R, AL,
         AN, EN, ES, CS, ET, ON, BN, or NSM are allowed. */
    for (i = 0, pos_EN = pos_AN = label_l; i < label_l; i++)
    {
      switch (label[i].bidi_class)
      {
        case ucd_bidi_R:
        case ucd_bidi_AL:
        case ucd_bidi_ES:
        case ucd_bidi_CS:
        case ucd_bidi_ET:
        case ucd_bidi_ON:
        case ucd_bidi_BN:
        case ucd_bidi_NSM:
          break;

        case ucd_bidi_EN:
          if (pos_EN == label_l)
            pos_EN = i;
          break;

        case ucd_bidi_AN:
          if (pos_AN == label_l)
            pos_AN = i;
          break;

        default:
          res = 0; /* condition B2 violated */
          report_result(2,i,results,*results_l,results_maxl);
          break;
      }
    }

    /*
    3.  In an RTL label, the end of the label must be a character with
       Bidi property R, AL, EN, or AN, followed by zero or more
       characters with Bidi property NSM. */
    for (i = label_l - 1; i >= 0; i--)
    {
      if (label[i].bidi_class == ucd_bidi_NSM)
        continue;
      if (!(
        label[i].bidi_class == ucd_bidi_R ||
        label[i].bidi_class == ucd_bidi_AL ||
        label[i].bidi_class == ucd_bidi_EN ||
        label[i].bidi_class == ucd_bidi_AN))
      {
        res = 0; /* condition B3 violated */
        report_result(3,i,results,*results_l,results_maxl);
      }
      break;
    }


    /*
    4.  In an RTL label, if an EN is present, no AN may be present, and
       vice versa. */
    if (pos_EN < label_l && pos_AN < label_l)
    {
      res = 0; /* condition B4 violated */
      size_t pos = pos_EN > pos_AN ? pos_EN : pos_AN;
      report_result(4,pos,results,*results_l,results_maxl);
    }

  }
  
  else if (*dir == bidi_direction_LTR)  /* LTR conditions 5 - 6 */
  {

    /*
    5.  In an LTR label, only characters with the Bidi properties L, EN,
       ES, CS, ET, ON, BN, or NSM are allowed. */
    for (i = 0; i < label_l; i++)
    {
      switch (label[i].bidi_class)
      {
        case ucd_bidi_L:
        case ucd_bidi_EN:
        case ucd_bidi_ES:
        case ucd_bidi_CS:
        case ucd_bidi_ET:
        case ucd_bidi_ON:
        case ucd_bidi_BN:
        case ucd_bidi_NSM:
          break;

        default:
          res = 0; /* condition B5 violated */
          report_result(5,i,results,*results_l,results_maxl);
          break;
      }
    }

    /*
    6.  In an LTR label, the end of the label must be a character with
       Bidi property L or EN, followed by zero or more characters with
       Bidi property NSM.*/
    for (i = label_l - 1; i >= 0; i--)
    {
      if (label[i].bidi_class == ucd_bidi_NSM)
        continue;
      if (!(
        label[i].bidi_class == ucd_bidi_L ||
        label[i].bidi_class == ucd_bidi_EN))
      {
        res = 0; /* condition B6 violated */
        report_result(6,i,results,*results_l,results_maxl);
      }
      break;
    }

  }

  return res;
}


