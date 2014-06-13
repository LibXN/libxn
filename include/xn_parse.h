#ifndef __XN_PARSE_H__
#define __XN_PARSE_H__


// ============================================

typedef enum XN_PARSER
{

  xn_parser_Std3ASCII = (1 << 0),
  xn_parser_Hyphen34 = (1 << 0),

  /* Convert ASCII characters to lower case. (XN-Labels are considered
  case-insensitive anyway.) */
  xn_parser_ASCII_To_Lower = (1 << 0),

  xn_parser_UTS46_Map = (1 << 0),
  xn_parser_UTS46_Transitional = (1 << 0),
  xn_parser_UTS46_UseSTD3ASCIIRules = (1 << 0),

  xn_process_NFC = (1 << 0),

  //xn_parser_Normalize_NFC = (1 << 0),

  xn_validate_ASCII_LDH = (1 << 0),

  xn_validate__Label_Length = (1 << 0),


  /*
  4.2.2. Rejection of Characters That Are Not Permitted
    The candidate Unicode string MUST NOT contain characters that appear
    in the "DISALLOWED" and "UNASSIGNED" lists specified in the Tables
    document [RFC5892]. */
  xn_validate__RFC5892_UNASSIGNED = (1 << 0),

  xn_validate__RFC5892_DISALLOWED = (1 << 0),


  xn_validate__Registration = (1 << 1),

  xn_validate__NFC = (1 << 4),


  /* RFC 8591 Registration Protocol
  4.2.3.1. Hyphen Restrictions
    The Unicode string MUST NOT contain "--" (two consecutive hyphens) in
    the third and fourth character positions and MUST NOT start or end
    with a "-" (hyphen). */
  xn_validation__Hyphen_Restrictions = (1 << 1),

  xn_validate__Hyphen34 = (1 << 1),

 xn_validate__Leading_Hyphen = (1 << 1),
 xn_validate__Trailing_Hyphen = (1 << 1),

  /* RFC 8591 Registration Protocol
  4.2.3.2. Leading Combining Marks
    The Unicode string MUST NOT begin with a combining mark or combining
    character (see The Unicode Standard, Section 2.11 [Unicode] for an
    exact definition). */
  xn_validate__Leading_Combining_Marks = (1 << 2),

  /* RFC 8591 Registration Protocol
  4.2.3.3. Contextual Rules
    The Unicode string MUST NOT contain any characters whose validity is
    context-dependent, unless the validity is positively confirmed by a
    contextual rule.  To check this, each code point identified as
    CONTEXTJ or CONTEXTO in the Tables document [RFC5892] MUST have a
    non-null rule.  If such a code point is missing a rule, the label is
    invalid.  If the rule exists but the result of applying the rule is
    negative or inconclusive, the proposed label is invalid. */
  xn_validate__RFC5892_CONTEXTJ = (1 << 3),

  xn_validate__RFC5892_CONTEXTO = (1 << 3),

  /* RFC 8591 Registration Protocol
  4.2.3.4. Labels Containing Characters Written Right to Left
    If the proposed label contains any characters from scripts that are
    written from right to left, it MUST meet the Bidi criteria [RFC5893]. */
  xn_validation__RFC5893_Bidi = (1 << 4),


  xn_validate__RFC5892 = (
    xn_validate__RFC5892_UNASSIGNED |
    xn_validate__RFC5892_DISALLOWED |
    xn_validate__RFC5892_CONTEXTJ |
    xn_validate__RFC5892_CONTEXTO
  )


}
xn_parser;

/* result classification */
enum XN_RESULT_CLASS
{

  /* Fatal program errors, propably indicating a serious bug. */
  xn_result_FATAL     = (1 << 28),

  /* Input processing errors, where further proceeding does not make sense. */
  xn_result_ERROR     = (1 << 27),

  /* Validation errors depending on given validation flags.
    Input will be processed further anyway. */
  xn_result_INVALID   = (1 << 26),

  /* Process termination */
  xn_result_ABORT = (xn_result_FATAL | xn_result_ERROR)

};

#define XN_RESULT_CLASS_MASK ( xn_result_FATAL | xn_result_ERROR | xn_result_INVALID )

#define xn_get_result_class(result) (result & XN_RESULT_CLASS_MASK)
#define xn_get_result_offset(result) (result & ~XN_RESULT_CLASS_MASK)

typedef enum XN_RESULT
{

  xn_result_OK = 0,

  xn_fatal__Unknown_Error = xn_result_FATAL + 1,
  xn_fatal__Memory_Fault = xn_result_FATAL + 2,
  xn_fatal__Integer_Overflow = xn_result_FATAL + 3,
  xn_fatal__Buffer_Exceeded = xn_result_FATAL + 4,

  xn_error__Input_Too_Long = xn_result_ERROR + 5,
  xn_error__Input_Empty = xn_result_ERROR + 6,
  xn_error__Input_Out_Of_Range = xn_result_ERROR + 7,
  xn_error__Puncode_Decoding_Failure = xn_result_ERROR + 8,
  xn_error__Puncode_Encoding_Failure = xn_result_ERROR + 9,
  xn_error__ACE_Non_ASCII = xn_result_ERROR + 10,
  xn_error__ACE_Not_Normalized = xn_result_ERROR + 11,
  xn_error__ACE_Mismatch = xn_result_ERROR + 12,
  xn_error__ACE_Invalid = xn_result_ERROR + 13,

  xn_invalid__Leading_Hyphen = xn_result_INVALID + 14,
  xn_invalid__Trailing_Hyphen = xn_result_INVALID + 15,
  xn_invalid__Hyphen34 = xn_result_INVALID + 16,
  xn_invalid__ASCII_Non_LDH = xn_result_INVALID + 17,
  xn_invalid__Label_Too_Long = xn_result_INVALID + 18,
  xn_invalid__non_NFC = xn_result_INVALID + 19,
  xn_invalid__uts46_DISALLOWED = xn_result_INVALID + 20,
  xn_invalid__uts46_DISALLOWED_STD3 = xn_result_INVALID + 21,
  xn_invalid__rfc5892_UNASSIGNED = xn_result_INVALID + 22,
  xn_invalid__rfc5892_DISALLOWED = xn_result_INVALID + 23,
  xn_invalid__rfc5892_CONTEXT = xn_result_INVALID + 24,
  xn_invalid__Leading_Combining_Mark = xn_result_INVALID + 25

}
xn_result;

typedef struct XN_ERROR_REPORT
{
  xn_result result;
  char message[XN_BUFSZ];
}
xn_error_report;


typedef struct RESULT_LIST
{
  xn_error_report *errors;
  size_t count;
  size_t max_count;
}
result_list;


// ==========================
//
// typedef int32_t xn_flags;
//
// #define XN_NULL         (0)
// #define XN_NON_ASCII    (1 << 1)
//
// #define XN_EMPTY_LABEL       (1 << 2)
// #define XN_LABEL_TOO_LONG    (1 << 3)
// #define XN_DOMAIN_TOO_LONG   (1 << 4)
// #define XN_TOO_MANY_LABELS   (1 << 15)
//
// #define XN_LEADING_HYPHEN    (1 << 5)
// #define XN_TRAILING_HYPHEN   (1 << 6)
// #define XN_INVALID_ACE       (1 << 7)
// #define XN_HYPHEN34          (1 << 8)
// #define XN_NON_LDH           (1 << 9)
//
// #define XN_CONTROL          (1 << 10)
// #define XN_SPACE            (1 << 11)
// #define XN_UNASSIGNED          (1 << 12)
// #define XN_DISALLOWED          (1 << 13)
// #define XN_BIDI             (1 << 14)
//
//
//
// #define XN_NAMEPREP          (1 << 20)
//
// #define XN_INVALID    (1L << 25)
//
// #define XN_BUFFER_EXCEEDED (1L << 28)
// #define XN_ENCODING_ERROR  (1L << 29)
// #define XN_MALLOC_ERROR    (1L << 30)
// #define XN_UNKNOWN_ERROR   (1L << 31)
// #define XN_ERROR           ( XN_INVALID | XN_BUFFER_EXCEEDED | XN_ENCODING_ERROR | XN_MALLOC_ERROR | XN_UNKNOWN_ERROR )
//


#ifdef __cplusplus
extern "C" {
#endif

xn_result
uts46_map_ucd(
  xn_parser processing,
  ucd_record ucd[],
  size_t *ucd_l,
  size_t ucd_maxl,
  bool_t *changed,
  bool_t *ascii,
  result_list *results);


#ifdef __cplusplus
}
#endif



#endif
