
#ifndef _ENCODING_H_
#define _ENCODING_H_


// http://developers.sun.com/solaris/articles/mixing.html#c_from_cpp


#ifdef __cplusplus
extern "C" {
#endif

extern char *
  utf8_encode
  (uint32_t ucs4[], size_t ucs4_l);

// extern int
// utf8_decode
//   (const char *utf, uint32_t **ucs4, size_t *ucs4_l, xn_flags f);

extern int
utf16_decode
  (const uint16_t **utf16, uint32_t *ucs4);

//
// /* punycode */
// xn_flags
//   idna2_punycode_decode
//   (const char *ascii, size_t ascii_l, uint32_t **ucs4, size_t *ucs4_l);
//
// xn_flags
//   idna2_punycode_encode
//   (uint32_t **ucs4, size_t *ucs4_l);
//
//


#ifdef __cplusplus
}
#endif

#endif
