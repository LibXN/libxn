

# read from sources.txt
sources := $(addprefix sources/,$(shell cat sources.txt | sed 's/[^;]\+;\([^;]\+\);.\+/\1/'))

# source files to generate
src_gen = ucd.c ucd.h ucd_block.h ucd_block.c ucnf_composition.c rfc5892_rules.c

# all targets
targets = $(addprefix out/, $(src_gen))

# dependecies
deps = sources.txt $(sources) \
	$(wildcard src/*.in.c) \
	gen.pl $(wildcard scripts/*.pl) $(wildcard modules/*.pm)

#BUILT_SOURCES = $(targets)
#all-am: $(targets)

# Targets are source files here, thus automake should treat them as scripts.
bin_SCRIPTS = $(targets)

$(targets) : $(deps)
	$(PERL) -w -Imodules gen.pl && mv -f tmp/* out/

# Sources from http://www.unicode.org/Public/UNIDATA/
sources/UNIDATA/%.txt:
	cd sources/UNIDATA ; \
	$(WGET) $(subst sources,http://www.unicode.org/Public,$@) && \
	touch $(notdir $@)

# Sources from http://www.unicode.org/Public/idna/latest/
sources/UTS46/%.txt:
	cd sources/UTS46 ; \
	$(WGET) $(subst sources/UTS46,http://www.unicode.org/Public/idna/latest,$@) && \
	touch $(notdir $@)

# Sources from http://www.ietf.org/rfc/
sources/rfc/%.txt:
	cd sources/rfc ; \
	$(WGET) $(subst sources,http://www.ietf.org,$@) && \
	touch $(notdir $@)


check:


