# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# GNU tar 1.35 in ff (wave C1b): upstream's tarball, a flake input pinned
# by its hash (TAR_SRC in `nix develop`), built by ../port.mk: tar (not
# rmt, the remote tape server, which its tests never run).
#
#   make GTARGET=x86_64 ref units ff check
#
# Not built: the translations (NLS), SELinux, POSIX ACLs (libacl: another
# library). The same for gcc's program and ttpc's. Beside its tests, the
# lane's round trip: archives made by each program are listed and
# extracted by the other.
PKG := tar
PKG_VERSION := 1.35
PKG_SRC = $(TAR_SRC)
PKG_LICENSE := GPL-3.0-or-later
PKG_PROGRAM := src/tar
# (mktime: as findutils')
PKG_CONFIGURE := --disable-nls --without-selinux --without-posix-acls \
    gt_cv_locale_fr=fr_FR.ISO-8859-1 gt_cv_locale_fr_utf8=fr_FR.UTF-8 \
    gl_cv_func_working_mktime=yes
# the test suite: tar's own (tests/, autotest's testsuite, not automake's:
# each test's result from its testsuite.log, results.sh), not gnulib's;
# its helpers (genfile, ...) built before the run
PKG_CHECKTARGET := -C tests check
PKG_CHECKPROGS := -C tests genfile checkseekhole ckmtime
PKG_CHECKFILES := -name testsuite.log
PKG_RESULTS := $(CURDIR)/results.sh
PKG_LOCALES := fr_FR:UTF-8:fr_FR.utf8 fr_FR:ISO-8859-1:fr_FR.iso88591
PKG_ROUNDTRIP := $(CURDIR)/roundtrip.sh
include ../port.mk
