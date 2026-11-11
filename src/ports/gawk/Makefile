# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# GNU awk 5.4.1 in ff (the user's choice of 2026-11-11, wave C1a): its
# source as the flake's nixpkgs has it (pkgs.gawk.src, GAWK_SRC in `nix
# develop`), built by ../port.mk.
#
#   make GTARGET=x86_64 ref units ff check
#
# Not built: the dynamic extensions (a static program loads none: their
# tests skip), MPFR (-M; nixpkgs builds gawk without it too), the persistent
# memory allocator (PMA), readline, the translations (NLS). The same for
# gcc's program and ttpc's.
PKG := gawk
PKG_VERSION := 5.4.1
PKG_SRC = $(GAWK_SRC)
PKG_LICENSE := GPL-3.0-or-later
PKG_PROGRAM := gawk
PKG_CONFIGURE := --disable-nls --disable-extensions --disable-mpfr --disable-pma --without-readline
# the test suite: gawk's own (test/, not automake's), one job (its tests
# share temporary files); a test passed where it left no _NAME behind
# (results.sh)
PKG_CHECKRUN = $(SUBMAKE) -C test check
PKG_CHECKFILES := -path './test/_*'
PKG_RESULTS := $(CURDIR)/results.sh
PKG_LOCALES := en_US:UTF-8:en_US.utf8 fr_FR:UTF-8:fr_FR.utf8 ja_JP:UTF-8:ja_JP.utf8 ru_RU:UTF-8:ru_RU.utf8
include ../port.mk
