# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# GNU diffutils 3.12 in ff (wave C1b): upstream's tarball, a flake input
# pinned by its hash (DIFFUTILS_SRC in `nix develop`), built by ../port.mk:
# diff, cmp, diff3 and sdiff, each a tree and a program (diff3 and sdiff
# run the diff of their PATH: the tests put src/ first, so both runs use
# their own build's diff).
#
#   make GTARGET=x86_64 ref units ff check
#
# Not built: the translations (NLS). The same for gcc's programs and ttpc's.
PKG := diffutils
PKG_VERSION := 3.12
PKG_SRC = $(DIFFUTILS_SRC)
PKG_LICENSE := GPL-3.0-or-later
PKG_PROGRAMS := src/diff src/cmp src/diff3 src/sdiff
# (mktime: off the machine's own target configure guesses no, and gnulib's
# mktime.o then clashes with libc.a's __mktime_internal, as findutils';
# strcasecmp: its test has no answer for a cross build, configure stops:
# glibc's works, x86_64's configure guessed yes)
PKG_CONFIGURE := --disable-nls \
    gt_cv_locale_fr=fr_FR.ISO-8859-1 gt_cv_locale_fr_utf8=fr_FR.UTF-8 \
    gl_cv_func_working_mktime=yes gl_cv_func_strcasecmp_works=yes
# the test suite: diffutils' own (tests/), not gnulib's tests of its modules
PKG_CHECKTARGET := -C tests check
# the locales its tests ask for (en_US.UTF-8; cmp -bl's en_US.iso8859-1)
PKG_LOCALES := en_US:UTF-8:en_US.utf8 en_US:ISO-8859-1:en_US.iso88591 \
    fr_FR:UTF-8:fr_FR.utf8 fr_FR:ISO-8859-1:fr_FR.iso88591
include ../port.mk
