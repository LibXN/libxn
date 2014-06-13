/*
RFC 5892 contextual rule

Appendix A.3. MIDDLE DOT


   Code point:
      U+00B7

   Overview:
      Between 'l' (U+006C) characters only, used to permit the Catalan
      character ela geminada to be expressed.

   Lookup:
      False

   Rule Set:

      False;

      If Before(cp) .eq.  U+006C And

         After(cp) .eq.  U+006C Then True;

*/
static rfc5892_context_result
rfc5892__a3_middle_dot(
  const ucd_record label[], size_t label_l, size_t pos)
{

  if (pos == 0 || pos == label_l-1)
    return rfc5892_context_Undef;
    
  if (label[pos-1].cp == 0x006C && label[pos+1].cp == 0x006C)
    return rfc5892_context_True;

  return rfc5892_context_False;
}

