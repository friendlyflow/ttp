# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# GNU make 4.4.1 in ff (wave C1b): upstream's tarball, a flake input
# pinned by its hash (MAKE_SRC in `nix develop`), built by ../port.mk: make,
# its own C and gnulib's.
#
#   make GTARGET=x86_64 ref units ff check
#
# Not built: the load directive (a static program loads no shared object:
# its tests skip), GNU Guile, the translations (NLS). The same for gcc's
# program and ttpc's.
PKG := make
PKG_VERSION := 4.4.1
PKG_SRC = $(MAKE_SRC)
PKG_LICENSE := GPL-3.0-or-later
PKG_PROGRAM := make
PKG_CONFIGURE := --disable-nls --disable-load --without-guile
# the test suite: make's own (tests/, run_make_tests.pl, not automake's:
# make check-regression; each category's result from its log, results.sh)
PKG_CHECKTARGET := check-regression
PKG_CHECKFILES := -name test-suite.log
PKG_RESULTS := $(CURDIR)/results.sh
include ../port.mk
