# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# GNU grep 3.12 in ff (the user's choice of 2026-11-11, wave C1a): its
# source as the flake's nixpkgs has it (pkgs.gnugrep.src, GREP_SRC in
# `nix develop`), built by ../port.mk.
#
#   make GTARGET=x86_64 ref units ff check
#
# Not built: -P (Perl regular expressions), which nixpkgs builds with
# pcre2: a library glibc has not, another port first; the translations
# (NLS). The same for gcc's program and ttpc's.
PKG := grep
PKG_VERSION := 3.12
PKG_SRC = $(GREP_SRC)
PKG_LICENSE := GPL-3.0-or-later
PKG_PROGRAM := src/grep
# the locales of gnulib's tests (configure runs a program in each, which
# off the machine's own target it cannot): named for every target alike
PKG_CONFIGURE := --disable-nls --disable-perl-regexp \
    gt_cv_locale_fr=fr_FR.ISO-8859-1 gt_cv_locale_fr_utf8=fr_FR.UTF-8
# the test suite: grep's own (tests/), not gnulib's tests of its modules
# (gnulib-tests/, which never run grep); its helper built before the run
PKG_CHECKTARGET := -C tests check
PKG_CHECKPROGS := -C tests get-mb-cur-max
# the locales its tests ask for, the UTF-8 ones and fr_FR's ISO-8859-1
# (glibc's own charset, no gconv module); not those whose charsets a static
# program loads by dlopen (KOI8-R, EUC-JP, Shift_JIS, ISO-8859-7, Big5-HKSCS,
# GB18030: see ../sed/Makefile)
PKG_LOCALES := en_US:UTF-8:en_US.utf8 tr_TR:UTF-8:tr_TR.utf8 cs_CZ:UTF-8:cs_CZ.utf8 \
    zh_CN:UTF-8:zh_CN.utf8 de_DE:UTF-8:de_DE.utf8 fr_FR:UTF-8:fr_FR.utf8 \
    fr_FR:ISO-8859-1:fr_FR.iso88591
include ../port.mk
