# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# GNU bc 1.08.2 in ff (the user's choice of 2026-11-11, wave C1a): its
# source as the flake's nixpkgs has it (pkgs.bc.src, BC_SRC in `nix
# develop`, a .tar.lz: lzip), built by ../port.mk: bc and dc, each a tree
# and a program.
#
#   make GTARGET=x86_64 ref units ff check
#
# Not built: readline (nixpkgs builds bc with it: another library to port),
# the same for gcc's programs and ttpc's. bc's libmath.h, scan.c and bc.c
# are its tarball's (no lex, yacc or a bc of the build machine needed).
PKG := bc
PKG_VERSION := 1.08.2
PKG_SRC = $(BC_SRC)
PKG_LICENSE := GPL-3.0-or-later
PKG_PROGRAMS := bc/bc dc/dc
PKG_CONFIGURE := --without-readline --without-libedit
# the tests: bc has them as files, with no make check (tests.sh), each
# file's output and exit status compared (results.sh)
PKG_CHECKRUN = sh $(CURDIR)/tests.sh $(SRCDIR) $(PB)/check-$*/out
PKG_CHECKFILES := -name '*.no-such-file'
PKG_RESULTS := $(CURDIR)/results.sh
include ../port.mk
