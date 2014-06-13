#pragma once
#ifndef __PUNYCODE_H__
#define __PUNYCODE_H__

typedef enum PUNYCODE_STATUS {
  punycode_success = 0,
  punycode_bad_input = 1,   /* Input is invalid.                       */
  punycode_big_output = 2,  /* Output would exceed the space provided. */
  punycode_overflow = 3     /* Input needs wider integers to process.  */
}
punycode_status;


/* Punycode encoding (RFC 3492) */
punycode_status
punycode_encode(
  const codepoint_t ucs4[],
  size_t ucs4_l,
  char ascii[],
  size_t *ascii_l);

/* Punycode decoding (RFC 3492) */
punycode_status
punycode_decode(
  const char ascii[],
  size_t ascii_l,
  codepoint_t ucs4[],
  size_t *ucs4_l);

extern const char *punycode_status_string[];

#endif
