#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ(2.61)
AC_INIT(xn, 0.1, debug@test1.org)
AC_CONFIG_SRCDIR([lib/xn_parse.c])
AC_CONFIG_AUX_DIR(auto)

# AM_INIT_AUTOMAKE
AM_INIT_AUTOMAKE([-Wall -Werror foreign])
AM_CONFIG_HEADER([config.h])

m4_include([m4/ac_compile_check_sizeof.m4])
m4_include([m4/ax_create_stdint_h.m4])
m4_include([m4/ac_c_enum_size.m4])
m4_include([m4/ac_cxx_have_std.m4])



# Checks for programs.
AC_PROG_CC
AC_PROG_LIBTOOL

AC_PROG_LN_S
AC_PROG_SED
AC_CHECK_PROGS([PERL], [perl])


# https://subversion.umiacs.umd.edu/scriptroute/scriptroute/tags/scriptroute_v0_2_58/configure.ac
AC_CHECK_PROGS([WGET], [wget curl])

AC_MSG_CHECKING(if wget was wget)
if test "X$WGET" = "Xwget"; then
   AC_MSG_RESULT(yes)
   WGET="wget"
else
   AC_MSG_RESULT(no)
fi
AC_MSG_CHECKING(if wget was curl)
if test "X$WGET" = "Xcurl"; then
   AC_MSG_RESULT(yes)
   WGET="curl -O"
else
   AC_MSG_RESULT(no)
fi
AC_MSG_CHECKING(if wget was nothing)
if test -z "$WGET"; then
   AC_MSG_RESULT(yes, but that may be fatal)
else
   AC_MSG_RESULT(no, which is good.)
fi




# Checks for libraries.

# Checks for header files.
AC_HEADER_STDC
AC_CHECK_HEADERS([stddef.h stdint.h stdlib.h])


# libidn
AC_ARG_WITH(libidn, AC_HELP_STRING([--with-libidn=[DIR]],
                                     [Support IDN (needs GNU Libidn)]),
 libidn=$withval, libidn=yes)
if test "$libidn" != "no"; then
 if test "$libidn" != "yes"; then
   LDFLAGS="${LDFLAGS} -L$libidn/lib"
   CPPFLAGS="${CPPFLAGS} -I$libidn/include"
 fi
 AC_CHECK_HEADER(idna.h,
   AC_CHECK_LIB(idn, stringprep_check_version,
     [libidn=yes LIBS="${LIBS} -lidn"], libidn=no),
   libidn=no)
fi
if test "$libidn" != "no" ; then
 AC_DEFINE(LIBIDN, 1, [Define to 1 if you want IDN support.])
else
 AC_MSG_WARN([Libidn not found])
fi
AC_MSG_CHECKING([if Libidn should be used])
AC_MSG_RESULT($libidn)

# Checks for typedefs, structures, and compiler characteristics.
AC_HEADER_STDBOOL
AC_C_CONST
AC_C_INLINE

AC_TYPE_SIZE_T
AC_TYPE_UINT8_T
AC_TYPE_UINT16_T
AC_TYPE_UINT32_T

AC_LANG(C)

AX_CREATE_STDINT_H(include/config-int.h)
AC_DEFINE([HAVE_INCLUDE_CONFIG_INT_H],[1],
  [Define to 1 if a local stdint.h equivalent has been generated.])


AC_ENUM_SIZE

# Checks for library functions.
AC_FUNC_REALLOC


AC_CONFIG_FILES([Makefile
								 gen/Makefile
                 lib/Makefile
                 tests/Makefile])
AC_OUTPUT
