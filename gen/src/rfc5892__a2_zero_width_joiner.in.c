/*
RFC 5892 contextual rule

Appendix A.2. ZERO WIDTH JOINER


   Code point:
      U+200D

   Overview:
      This may occur in Indic scripts in a consonant-conjunct context
      (immediately following a virama), to control required display of
      such conjuncts.

   Lookup:
      True

   Rule Set:

      False;

      If Canonical_Combining_Class(Before(cp)) .eq.  Virama Then True;

*/
static rfc5892_context_result
rfc5892__a2_zero_width_joiner(
  const ucd_record label[], size_t label_l, size_t pos)
{

  /* Before(cp) required */
  if (pos == 0)
    return rfc5892_context_Undef;

  /* If Canonical_Combining_Class(Before(cp)) .eq.  Virama Then True; */
  if (label[pos-1].ccc == 9 /* Virama */)
    return rfc5892_context_True;

  return rfc5892_context_False;
}

