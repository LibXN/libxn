## Process this file with automake to produce Makefile.in

XN_LIBRARY_VERSION=1:0:0
lib_LTLIBRARIES = libxn.la

# header location
include_dir = $(top_srcdir)/include

# generated files
gen_dir = $(top_srcdir)/gen
gen_out = $(gen_dir)/out
gen_sources = ucd.c ucd_block.c ucnf_composition.c rfc5892_rules.c
gen_headers = ucd.h ucd_block.h

# source files
all_sources = \
	xn_parse.c xn_results.c \
	ucnf_normalization.c uts46.c \
  rfc5893_bidi.c encoding.c punycode.c \
  $(gen_sources:.c=.gen.c)

# header files
all_headers = \
	config-int.h xn-int.h xn-bool.h xn-def.h \
	xn.h xn_parse.h ucnf.h ucnf_composition.h ucnf_normalization.h \
	rfc5892_rules.h rfc5893_bidi.h encoding.h punycode.h \
  $(gen_headers:.h=.gen.h)

libxn_la_LDFLAGS = -rpath '$(libdir)' $(all_libraries) -version-info $(XN_LIBRARY_VERSION) -no-undefined
libxn_la_SOURCES = $(all_sources)

pkginclude_HEADERS = $(addprefix $(include_dir)/,$(all_headers))


# Link generated sources.
%.gen.c: $(gen_out)/%.c
	cp -f $< $@

$(include_dir)/%.gen.h: $(gen_out)/%.h
	cp -f $< $@

$(gen_out)/%:
	cd $(gen_dir); $(MAKE) $(MFLAGS)

# Prevent automatic deletion of intermediate files.
.SECONDARY: $(addprefix $(gen_out)/,$(gen_sources))

BUILT_SOURCES =  $(addprefix $(include_dir)/,$(gen_headers:.h=.gen.h))

AM_CFLAGS = $(all_includes) -I$(include_dir) -Wall
AM_CPPFLAGS = $(all_includes) -I$(include_dir) -Wall

METASOURCES = AUTO
