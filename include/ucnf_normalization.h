#pragma once
#ifndef __UCD_NORMALIZATION_H__
#define __UCD_NORMALIZATION_H__

typedef enum UCNF_NORMALIZATION_RESULT
{
  ucnf_OK = 0,
  ucnf_Buffer_Exceeded = 1, /* user error */
  ucnf_Unexpeted = -1  /* possibly program bug */
}
ucnf_normalization_result;


#ifdef __cplusplus
extern "C" {
#endif

/*
  Unicode normalization form quick check
  see: http://www.unicode.org/reports/tr15/#Detecting_Normalization_Forms */
ucnf_quickcheck_result
ucnf_quickcheck
  (const ucd_record ucd[], size_t ucd_l, ucnf_form nf);

/*
  Check whether a string is normalized:
  Try quickcheck, apply normalization otherwise. */
bool_t
ucnf_is_normalized
  (const ucd_record[], size_t, ucnf_form);

/*
  Apply normalization unless quickcheck equals nf_quick_check_Yes. */
ucnf_normalization_result
ucnf_normalize
  (ucd_record[], size_t *, size_t, ucnf_form);

/*
  Apply Unicode Normalization.
  see: http://unicode.org/reports/tr15/#Description_Norm */
ucnf_normalization_result
ucnf_apply_normalization
  (ucd_record[], size_t *, size_t, ucnf_form);


#ifdef __cplusplus
}
#endif

#endif
