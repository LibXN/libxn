/*
RFC 5892 contextual rule

Appendix A.9. EXTENDED ARABIC-INDIC DIGITS


   Code point:
      06F0..06F9

   Overview:
      Can not be mixed with Arabic-Indic Digits.

   Lookup:
      False

   Rule Set:

      True;

      For All Characters:

         If cp .in. 0660..0669 Then False;

      End For;

*/
static rfc5892_context_result
rfc5892__a9_extended_arabic_indic_digits(
  const ucd_record label[], size_t label_l, size_t pos)
{
  size_t i;

  for (i = 0; i < label_l; i++)
    if (label[i].cp >= 0x0660 && label[i].cp <= 0x0669)
      return rfc5892_context_False;

  return rfc5892_context_True;
}

