# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# GNU gzip 1.14 in ff (wave C1b): upstream's tarball, a flake input pinned
# by its hash (GZIP_SRC in `nix develop`), built by ../port.mk: gzip (its
# gunzip, zcat, zdiff, zgrep, ... are scripts that run it).
#
#   make GTARGET=x86_64 ref units ff check
#
# Not built: the translations (NLS; gzip has none). The same for gcc's
# program and ttpc's. Beside its tests, the lane's round trip: files
# compressed by each program are decompressed by the other.
PKG := gzip
PKG_VERSION := 1.14
PKG_SRC = $(GZIP_SRC)
PKG_LICENSE := GPL-3.0-or-later
PKG_PROGRAM := gzip
# the test suite: gzip's own (tests/); the top's check-local (zdiff of
# gzip.doc, gzip -c | gzip -d of its sources at 4 levels) as one test more
# (results.sh: its exit status)
PKG_CHECKRUN = sh -c '$(SUBMAKE) -j$(JOBS) -C tests check; $(SUBMAKE) check-local > check-local.log 2>&1; echo $$? > check-local.status'
PKG_CHECKFILES := -name '*.trs' -o -name '*.log' -o -name check-local.status
PKG_RESULTS := $(CURDIR)/results.sh
PKG_LOCALES := en_US:UTF-8:en_US.utf8
PKG_ROUNDTRIP := $(CURDIR)/roundtrip.sh
include ../port.mk
