#ifndef __XN_BOOL_H__
#define __XN_BOOL_H__

/*
** Ensure that type bool with constants false = 0 and true = 1 are defined.
** C++ (ISO/IEC 14882:1998/2003/2011) has bool, true and false intrinsically.
** C (ISO/IEC 9899:1999) has bool, true and false by including <stdbool.h>
** C99 <stdbool.h> also defines __bool_true_false_are_defined when included
** MacOS X <dlfcn.h> manages to include <stdbool.h> when compiling without
** -std=c89 or -std=c99 or -std=gnu89 or -std=gnu99 (and __STDC_VERSION__
** is not then 199901L or later), so check the test macro before defining
** bool, true, false.  Tested on MacOS X Lion (10.7.1) and Leopard (10.5.2)
** with both:
**      #include "ourbool.h"
**      #include <stdbool.h>
** and:
**      #include <stdbool.h>
**      #include "ourbool.h"
**
** C99 (ISO/IEC 9899:1999) says:
**
** 7.16 Boolean type and values <stdbool.h>
** 1 The header <stdbool.h> defines four macros.
** 2 The macro
**       bool
**   expands to _Bool.
** 3 The remaining three macros are suitable for use in #if preprocessing
**   directives.  They are
**       true
**   which expands to the integer constant 1,
**       false
**   which expands to the integer constant 0, and
**       __bool_true_false_are_defined
**   which expands to the integer constant 1.
** 4 Notwithstanding the provisions of 7.1.3, a program may undefine and
**   perhaps then redefine the macros bool, true, and false.213)
**
** 213) See 'future library directions' (7.26.7).
**
** 7.26.7 Boolean type and values <stdbool.h>
** 1 The ability to undefine and perhaps then redefine the macros bool, true,
**   and false is an obsolescent feature.
**
** Use 'unsigned char' instead of _Bool because the compiler does not claim
** to support _Bool.  This takes advantage of the license of paragraph 4.
*/

#if !defined(__cplusplus)

#if __STDC_VERSION__ >= 199901L
#include <stdbool.h>
#elif !defined(__bool_true_false_are_defined)
#undef bool
#undef false
#undef true
#define bool    unsigned char
#define false   0
#define true    1
#define __bool_true_false_are_defined 1
#endif

#endif /* !_cplusplus */

#endif /* __XN_BOOL_H__ */
