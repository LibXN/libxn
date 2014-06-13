#pragma once
#ifndef __RFC5893_BIDI_H__
#define __RFC5893_BIDI_H__


// typedef enum BIDI_RESULT
// {
//   bidi_result_OK = 0,
//
//   bidi_result_B1 = (1 << 0),
//   bidi_result_B2 = (1 << 1),
//   bidi_result_B3 = (1 << 2),
//   bidi_result_B4 = (1 << 3),
//   bidi_result_B5 = (1 << 4),
//   bidi_result_B6 = (1 << 5)
// }
// bidi_result;

typedef enum BIDI_DIRECTION
{
  bidi_direction_Undef = 0,
  bidi_direction_LTR = 1,
  bidi_direction_RTL = 2
}
bidi_direction;


typedef struct BIDI_RESULT
{
  int condition;
  size_t position;
}
bidi_result;


#endif
