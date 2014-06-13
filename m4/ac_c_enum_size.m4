dnl @synopsis AC_ENUM_SIZE
dnl
dnl If the compiler supports ISO C++ standard library (i.e., can
dnl include the files iostream, map, iomanip and cmath}), define
dnl HAVE_STD.
dnl
dnl @category C
dnl @author Sebastian Boethin <bugs@libxn.org>
dnl @version 2012-08-01
dnl @license AllPermissive

AC_DEFUN([AC_ENUM_SIZE],
[AC_CACHE_CHECK(if the size of enum is 32bit,
ac_cv_enum_size,
[AC_LANG_SAVE
 AC_LANG_C
 AC_TRY_COMPILE([#include <stdint.h>
 /* TODO */
],[return 0;],
 ac_cv_enum_size=yes, ac_cv_enum_size=no)
 AC_LANG_RESTORE
])
if test "$ac_cv_enum_size" = yes; then
  AC_DEFINE(ENUM_SIZE,,[define whether the size of enum is 32bit])
fi
])
