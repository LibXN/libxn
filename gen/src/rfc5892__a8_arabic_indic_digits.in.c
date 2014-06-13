/*
RFC 5892 contextual rule

Appendix A.8. ARABIC-INDIC DIGITS


   Code point:
      0660..0669

   Overview:
      Can not be mixed with Extended Arabic-Indic Digits.

   Lookup:
      False

   Rule Set:

      True;

      For All Characters:

         If cp .in. 06F0..06F9 Then False;

      End For;

*/
static rfc5892_context_result
rfc5892__a8_arabic_indic_digits(
  const ucd_record label[], size_t label_l, size_t pos)
{
  size_t i;

  for (i = 0; i < label_l; i++)
    if (label[i].cp >= 0x06F0 && label[i].cp <= 0x06F9)
      return rfc5892_context_False;

  return rfc5892_context_True;
}

