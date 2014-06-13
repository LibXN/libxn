/*
RFC 5892 contextual rule

Appendix A.5. HEBREW PUNCTUATION GERESH


   Code point:
      U+05F3

   Overview:
      The script of the preceding character MUST be Hebrew.

   Lookup:
      False

   Rule Set:

      False;

      If Script(Before(cp)) .eq.  Hebrew Then True;

*/
static rfc5892_context_result
rfc5892__a5_hebrew_punctuation_geresh(
  const ucd_record label[], size_t label_l, size_t pos)
{
  if (pos == 0)
    return rfc5892_context_Undef;

  if (label[pos-1].script == ucd_script_Hebrew)
    return rfc5892_context_True;

  return rfc5892_context_False;
}

