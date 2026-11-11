# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# GNU findutils 4.11.0 in ff (the user's choice of 2026-11-11, wave C1a):
# its source as the flake's nixpkgs has it (pkgs.findutils.src,
# FINDUTILS_SRC in `nix develop`), built by ../port.mk: find, xargs, locate
# and frcode (locate's database coder, which updatedb, a script, runs),
# each a tree and a program.
#
#   make GTARGET=x86_64 ref units ff check
#
# Not built: SELinux, the translations (NLS). The same for gcc's programs and
# ttpc's.
PKG := findutils
PKG_VERSION := 4.11.0
PKG_SRC = $(FINDUTILS_SRC)
PKG_LICENSE := GPL-3.0-or-later
PKG_PROGRAMS := find/find xargs/xargs locate/locate locate/frcode
# (mktime: glibc's works; off the machine's own target configure cannot run
# its test, guesses no, and gnulib's mktime.o then clashes with libc.a's
# __mktime_internal in the static link)
PKG_CONFIGURE := --disable-nls --without-selinux \
    gt_cv_locale_fr=fr_FR.ISO-8859-1 gt_cv_locale_fr_utf8=fr_FR.UTF-8 \
    gl_cv_func_working_mktime=yes
# the tests: tests/ (automake's) and the DejaGnu suites of find, xargs and
# locate (runtest: nix develop's dejagnu; nixpkgs runs them not), not
# gnulib's tests of its modules nor lib/'s; their helper built before the run
PKG_CHECKFLAGS := 'SUBDIRS=find xargs locate'
PKG_CHECKPROGS := tests/xargs/test-sigusr
PKG_CHECKFILES := -name '*.trs' -o -name '*.log' -o -name '*.sum'
PKG_RESULTS := $(CURDIR)/results.sh
PKG_LOCALES := fr_FR:UTF-8:fr_FR.utf8 fr_FR:ISO-8859-1:fr_FR.iso88591
include ../port.mk
