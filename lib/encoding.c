/*
 * Copyright (C) 2011 Sebastian Böthin.
 *
 * Project home: <http://www.LibXN.org>
 * Author: Sebastian Böthin <sebastian@boethin.eu>
 *
 * This file is part of LibXN.
 *
 * LibXN is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * LibXN is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with LibXN. If not, see <http://www.gnu.org/licenses/>.
 *
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifdef WIN32
#include "config.win32.h"
#endif

#include <stdint.h>
#include <stdlib.h>

#include "xn.h"
#include "encoding.h"

/* utf-16 surrpgates */
#define surrogate_offset (0x10000 - (0xD800 << 10) - 0xDC00)

int
  utf16_decode
  (const uint16_t **utf16, uint32_t *ucs4)
{
  if (0xD800 <= **utf16 && **utf16 <= 0xDBFF) /* leading surrogate */
  {
    uint16_t lead = **utf16;
    (*utf16)++;
    if (0xDC00 <= **utf16 && **utf16 <= 0xDFFF) /* trailing surrogate */
    {
      uint16_t trail = **utf16;
      *ucs4 = (lead << 10) + trail + surrogate_offset;
      return 1;
    }
    return 0;
  }
  *ucs4 = **utf16; /* non-surrogate */
  return 1;
}



char *
  utf8_encode
  (uint32_t ucs4[], size_t ucs4_l)
{


  return NULL;
}

//
// int
// utf8_decode
//   (const char *utf8, uint32_t **ucs4_ptr, size_t *ucs4_len, xn_flags f)
// {
//   xn_flags ret = XN_NULL;
//   size_t ucs4_bufl = 0, ucs4_buf_add = 0, ucs4_l;
//   uint32_t *ucs4_p = NULL, u = 1;
//
//   for (*ucs4_ptr = NULL, *ucs4_len = ucs4_l = 0; u; )
//   {
//     uint32_t *ucs4_tp;
//     ucs4_buf_add += 256, ucs4_bufl += ucs4_buf_add;
//     if (!(ucs4_tp = (uint32_t *)realloc(ucs4_p,ucs4_bufl*sizeof(uint32_t))))
//     {
//       free(ucs4_p);
//       return 1; /* XN_MALLOC_ERROR; */
//     }
//     ucs4_p = ucs4_tp;
//
//     while ((u = (uint32_t)(*utf8++ & 0xFF)) && (ucs4_l < ucs4_bufl))
//     {
//
//       if (u < 0x80) /* ASCII */
//       {
//         ucs4_p[(ucs4_l)++] = u;
//       }
//       else
//       {
//         int d, s = 30, ok = 0;
//         uint32_t m = 0xFC;
//
//         for (d = 5; d > 0; d--, s -= 6, m = (m << 1) & 0xFC)
//         {
//           uint32_t m2 = (1 << (6 - d)) - 1;
//           uint32_t v = ((u & m2) << s);
//           if (m == (u & m))
//           {
//             while (s > 0)
//             {
//               if (!*utf8) /* missing next byte */
//               {
//                 free(ucs4_p);
//                 return 1; /* XN_ENCODING_ERROR; */
//               }
//               s -= 6, v |= (((uint32_t)*utf8++ & 0x3F) << s);
//             }
//             ucs4_p[(ucs4_l)++] = v, ok = 1;
//             break;
//           }
//         }
//         if (!ok) /* not understood */
//         {
//           free(ucs4_p);
//           return 1; /* XN_ENCODING_ERROR; */
//         }
//       }
//     }
//   }
//
//   *ucs4_ptr = ucs4_p, *ucs4_len = ucs4_l;
//   /*return (xn_flags)(f & ret); */
// 	return 0;
// }
//

