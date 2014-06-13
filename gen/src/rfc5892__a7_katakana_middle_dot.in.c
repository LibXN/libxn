/*
RFC 5892 contextual rule

Appendix A.7. KATAKANA MIDDLE DOT


   Code point:
      U+30FB

   Overview:
      Note that the Script of Katakana Middle Dot is not any of
      "Hiragana", "Katakana", or "Han".  The effect of this rule is to
      require at least one character in the label to be in one of those
      scripts.

   Lookup:
      False

   Rule Set:

      False;

      For All Characters:

         If Script(cp) .in. {Hiragana, Katakana, Han} Then True;

      End For;

*/
static rfc5892_context_result
rfc5892__a7_katakana_middle_dot(
  const ucd_record label[], size_t label_l, size_t pos)
{
  size_t i;
  
  for (i = 0; i < label_l; i++)
    if (
      label[i].script == ucd_script_Hiragana ||
      label[i].script == ucd_script_Katakana ||
      label[i].script == ucd_script_Han)
    return rfc5892_context_True;

  return rfc5892_context_False;
}

