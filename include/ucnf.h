#ifndef __UCNF_H__
#define __UCNF_H__

/*
  Unicode Normalization Forms
    cf.: http://www.unicode.org/reports/tr15/
*/


enum NF_Mask
{
  nf_mask_compatibility = 1,
  nf_mask_composition = 2
};

typedef enum UCNF_Form
{
  /* (NFD) Canonical Decomposition */
  xn_ucnf_form_D = 0,

  /* (NFC); Canonical Decomposition, followed by Canonical Composition */
  xn_ucnf_form_C = nf_mask_composition, /* 2 */

  /* (NFKD); Compatibility Decomposition */
  xn_ucnf_form_KD = nf_mask_compatibility, /* 1 */

  /* (NFKC); Compatibility Decomposition, followed by Canonical Composition */
  xn_ucnf_form_KC = nf_mask_composition + nf_mask_compatibility /* 3 */

}
ucnf_form;


/* normalization form Quick_Check
  cf.: http://www.unicode.org/reports/tr15/#Detecting_Normalization_Forms
*/
typedef enum UCNF_Quick_Check_result
{
  /* The code point is a starter and can occur in the Normalization Form.
  In addition, for NFKC and NFC, the character may compose with a
  following character, but it never composes with a previous character.*/
  nf_quick_check_Yes = 0,
  
  /* The code point cannot occur in that Normalization Form. */
  nf_quick_check_No = 1,
  
  /* The code point can occur, subject to canonical ordering,
  but with constraints. In particular, the text may not be in
  the specified Normalization Form depending on the context
  in which the character occurs. */
  nf_quick_check_Maybe = 2
  
}
ucnf_quickcheck_result;

/* normalization form Quick_Check values
from Derived Normalization Properties file [NormProps] */
enum UCNF_Quick_Check_value
{
  nfqc_NFD_N = (nf_quick_check_No << (2*xn_ucnf_form_D)), /* 1 */
  nfqc_NFD_M = (nf_quick_check_Maybe << (2*xn_ucnf_form_D)), /* 2 */

  nfqc_NFC_N = (nf_quick_check_No << (2*xn_ucnf_form_C)), /* 16 */
  nfqc_NFC_M = (nf_quick_check_Maybe << (2*xn_ucnf_form_C)), /* 32 */

  nfqc_NFKD_N = (nf_quick_check_No << (2*xn_ucnf_form_KD)), /* 4 */
  nfqc_NFKD_M = (nf_quick_check_Maybe << (2*xn_ucnf_form_KD)), /* 8 */

  nfqc_NFKC_N = (nf_quick_check_No << (2*xn_ucnf_form_KC)), /* 64 */
  nfqc_NFKC_M = (nf_quick_check_Maybe << (2*xn_ucnf_form_KC)) /* 128 */
};


#endif
