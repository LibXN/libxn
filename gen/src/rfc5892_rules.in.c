

/* Apply a contextual rule to a given label with respect to a specific position. */
rfc5892_context_result rfc5892_check_contextual_rule(
  const ucd_record label[], size_t label_l, size_t pos, int lookup,
  const char **rule_name)
{
  rfc5892_context_result res = rfc5892_context_Undef;
  codepoint_t cp = label[pos].cp;
  size_t i;

  /*
  RFC 5892
  
  A character with the derived property value CONTEXTJ or CONTEXTO
  (CONTEXTUAL RULE REQUIRED) is not to be used unless an appropriate
  rule has been established and the context of the character is
  consistent with that rule.  It is invalid to either register a string
  containing these characters or even to look one up unless such a
  contextual rule is found and satisfied.
  */
  
  /* argument consistence */
  if (!(pos < label_l))
    return rfc5892_context_Undef;
  if (!(label[pos].rfc5892 == rfc5892_CONTEXTJ ||
      label[pos].rfc5892 == rfc5892_CONTEXTO))
    return rfc5892_context_True;

  /* rule registry lookup */
  for (i = 0; i < /*=== RULE_COUNT ===*/; i++)
    if (cp <= registry[i].up && cp >= registry[i].lo)
    {  /* rule found */
    
      /* At lookup time:
        - For CONTEXTO, only the existance of a rule has to be verified.
        - For CONTEXTJ, only the joiner rules (Lookup: True) have to be applied. */
      if (lookup &&
          (label[pos].rfc5892 == rfc5892_CONTEXTO || !registry[i].lookup))
        return rfc5892_context_True;

      /* apply rule */
      if (rfc5892_context_True == (res = (*registry[i].rule)(label,label_l,pos)))
      {   /* A contextual rule is found and satisfied. */
        return rfc5892_context_True;
      }
      else /* Rule not satisfied. */
      {
        /* Taking RFC 5892 literally, we have to check whether another rule
         is satisfied (although actually at most one rule apply). */

        /* remeber the rule name for error reporting */
        *rule_name = registry[i].name;
      }
      
    }

  /* If no rule was found, the code point must be rejected. */
  return res;
}

