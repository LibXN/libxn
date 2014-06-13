
AM_CFLAGS = -I$(top_srcdir)/include
AM_CXXFLAGS = -I$(top_srcdir)/include

# Serial Test Harness
TESTS = ucnf_test.sh

# programs to build on 'make check'
check_PROGRAMS = ucnf_test

bin_PROGRAMS = punycode_test ucd_record_test xn_parse_test
#  ucd_record_test \
#  uts46_test \
#  test1
#bin_PROGRAMS = test1

#  xn_parse_test


ucnf_test_SOURCES = ucnf_test.c
ucnf_test_LDADD = $(top_srcdir)/lib/libxn.la


#
#
punycode_test_SOURCES = punycode_test.c
punycode_test_LDADD = $(top_srcdir)/lib/libxn.la

#uts46_test_SOURCES = uts46_test.c
#uts46_test_LDADD = $(top_srcdir)/lib/libxn.la

ucd_record_test_SOURCES = ucd_record_test.c
ucd_record_test_LDADD = $(top_srcdir)/lib/libxn.la

#
#
# #ucd_test_SOURCES = ucd_test.c
# #ucd_test_LDADD = $(top_srcdir)/lib/libxn.la
# #
#
#
# #normalization_test_SOURCES = normalization_test.c
# #normalization_test_LDADD = $(top_srcdir)/lib/libxn.la
#
xn_parse_test_SOURCES = xn_parse_test.c
xn_parse_test_LDADD = $(top_srcdir)/lib/libxn.la

#
# test1_SOURCES = test1.c
#

# temporary script
ucnf_test.sh: ucnf_test sources/UNIDATA/NormalizationTest.txt
	echo 'perl ucnf_test.pl $+' >$@ && chmod +x $@

# retrieve Unicode sources from www.unicode.org
sources/UNIDATA/%.txt:
	$(WGET) --output-document=$@ $(subst sources,http://www.unicode.org/Public,$@)
	touch $@

MOSTLYCLEANFILES = ucnf_test.sh
