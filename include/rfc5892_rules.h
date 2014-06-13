#pragma once
#ifndef __RFC5892_RULES_H__
#define __RFC5892_RULES_H__

/*
Appendix A. Contextual Rules Registry

Each rule is constructed as a Boolean expression that evaluates to
either True or False.  A simple "True;" or "False;" rule sets the
default result value for the rule set.  Subsequent conditional rules
that evaluate to True or False may re-set the result value.

A special value "Undefined" is used to deal with any error
conditions, such as an attempt to test a character before the start
of a label or after the end of a label.  If any term of a rule
evaluates to Undefined, further evaluation of the rule immediately
terminates, as the result value of the rule will itself be Undefined.
*/
typedef enum RFC5892_CONTEXT_RESULT
{
  rfc5892_context_False = 0,
  rfc5892_context_True = 1,
  rfc5892_context_Undef = 2
}
rfc5892_context_result;

#ifdef __cplusplus
extern "C" {
#endif

rfc5892_context_result
rfc5892_check_contextual_rule(
  const ucd_record label[], size_t label_l, size_t pos, int lookup,
  const char **rule_name);


#ifdef __cplusplus
}
#endif

#endif
