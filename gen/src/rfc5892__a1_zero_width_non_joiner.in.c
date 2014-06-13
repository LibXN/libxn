/*
RFC 5892 contextual rule

Appendix A.1. ZERO WIDTH NON-JOINER


   Code point:
      U+200C

   Overview:
      This may occur in a formally cursive script (such as Arabic) in a
      context where it breaks a cursive connection as required for
      orthographic rules, as in the Persian language, for example.  It
      also may occur in Indic scripts in a consonant-conjunct context
      (immediately following a virama), to control required display of
      such conjuncts.

   Lookup:
      True

   Rule Set:

      False;

      If Canonical_Combining_Class(Before(cp)) .eq.  Virama Then True;

      If RegExpMatch((Joining_Type:{L,D})(Joining_Type:T)*\u200C

         (Joining_Type:T)*(Joining_Type:{R,D})) Then True;

*/
static rfc5892_context_result
rfc5892__a1_zero_width_non_joiner(
  const ucd_record label[], size_t label_l, size_t pos)
{
  size_t i;
  int valid;

  /* Before(cp) must be defined */
  if (pos == 0)
    return rfc5892_context_Undef;

  /* If Canonical_Combining_Class(Before(cp)) .eq.  Virama Then True; */
  if (label[pos-1].ccc == 9 /* Virama */)
    return rfc5892_context_True;


  /* If RegExpMatch((Joining_Type:{L,D})(Joining_Type:T)*\u200C
         (Joining_Type:T)*(Joining_Type:{R,D})) Then True;
  Thus, \u200C must occur between Joining_Type:{L,D} and Joining_Type:{R,D},
  where arbitrary occurences of Joining_Type:T may be in between. */
  
  /* REM:
  Assuming that "\u200C" within the regex means the code point in question,
  because otherwise the rule would be satisfied already if only the regex
  matches somewhere in the string. This makes a difference, doesn't it? */

  /* check before pos */
  for (valid = 0, i = pos - 1; i >= 0; i--)
  {
    if (label[i].joining_type == ucd_joining_T)
      continue;
    valid = (label[i].joining_type == ucd_joining_L ||
          label[i].joining_type == ucd_joining_D);
    break;
  }
  
  if (valid)
  {
    /* check after pos */
    for (valid = 0, i = pos + 1; i < label_l; i++)
    {
      if (label[i].joining_type == ucd_joining_T)
        continue;
      valid = (label[i].joining_type == ucd_joining_R ||
            label[i].joining_type == ucd_joining_D);
      break;
    }

    if (valid)
      return rfc5892_context_True;
  }

  return rfc5892_context_False;
}

