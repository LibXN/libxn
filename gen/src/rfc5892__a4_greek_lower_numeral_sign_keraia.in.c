/*
RFC 5892 contextual rule

Appendix A.4. GREEK LOWER NUMERAL SIGN (KERAIA)


   Code point:
      U+0375

   Overview:
      The script of the following character MUST be Greek.

   Lookup:
      False

   Rule Set:

      False;

      If Script(After(cp)) .eq.  Greek Then True;

*/
static rfc5892_context_result
rfc5892__a4_greek_lower_numeral_sign_keraia(
  const ucd_record label[], size_t label_l, size_t pos)
{

  if (pos == label_l-1)
    return rfc5892_context_Undef;
    
  if (label[pos+1].script == ucd_script_Greek)
    return rfc5892_context_True;

  return rfc5892_context_False;
}

