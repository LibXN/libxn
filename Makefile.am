##
## Copyright (C) 2011 Sebastian Böthin.
##
## Project home: <http://www.LibXN.org>
## Author: Sebastian Böthin <sebastian@boethin.eu>
##
## This file is part of LibXN.
##
## LibXN is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## LibXN is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with LibXN. If not, see <http://www.gnu.org/licenses/>.
##

## Process this file with automake to produce Makefile.in

ACLOCAL_AMFLAGS =
SUBDIRS = lib tests
EXTRA_DIST =
include gen/EXTRA_DIST

TESTS =

# Special target for re-generating source files.
gen:
	cd gen; $(MAKE) $(MFLAGS)

.PHONY: gen

