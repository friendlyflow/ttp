# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# GNU sed 4.10 in ff (the user's choice of 2026-11-10: the first program of
# the outside world, Stage C's pilot): its source as the flake's nixpkgs
# has it (pkgs.gnused.src, SED_SRC in `nix develop`), built by ../port.mk.
#
#   make GTARGET=x86_64 ref units ff check
#
# Not built: what needs a library glibc has not (SELinux, ACLs) and the
# translations (NLS), the same for gcc's program and ttpc's.
PKG := sed
PKG_VERSION := 4.10
PKG_SRC = $(SED_SRC)
PKG_LICENSE := GPL-3.0-or-later
PKG_PROGRAM := sed/sed
PKG_CONFIGURE := --disable-nls --without-selinux --disable-acl
# the test suite: sed's own (testsuite/), not gnulib's tests of its modules
# (gnulib-tests/, which never run sed); its helpers built before the run
PKG_CHECKFLAGS := SUBDIRS=.
PKG_CHECKPROGS := testsuite/get-mb-cur-max testsuite/test-mbrtowc
# the locales its tests look for (testsuite/init.cfg), named as glibc's
# normal form of their codeset (en_US.utf8: en_US.UTF-8 finds it too): the
# UTF-8 ones; not el_GR.iso88597 nor ja_JP.sjis, whose charsets a static
# program loads as gconv modules by dlopen, which needs the sysroot's
# libc.so.6 at run time (LD_LIBRARY_PATH, which the shell and make of the
# run would take too)
PKG_LOCALES := en_US:UTF-8:en_US.utf8 ru_RU:UTF-8:ru_RU.utf8
include ../port.mk
