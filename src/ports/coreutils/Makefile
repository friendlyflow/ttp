# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# GNU coreutils 9.11 in ff (the user's choice of 2026-11-11, wave C1a): its
# source as the flake's nixpkgs has it (pkgs.coreutils.src, COREUTILS_SRC
# in `nix develop`), built by ../port.mk as nixpkgs builds it: one program
# of every tool (--enable-single-binary=symlinks: src/coreutils, each tool
# a symlink to it that it tells by its name), so one tree and one program
# of ttpc's; arch, kill and uptime too, as nixpkgs installs them; not
# stdbuf, whose libstdbuf.so a static build cannot make (configure says
# yes on aarch64 alone, whose link of it then
# fails: libc.a in a .so) and a static program would never load.
#
#   make GTARGET=x86_64 ref units ff check
#
# Not built: what needs a library glibc has not (SELinux, which nixpkgs
# builds with; ACLs, xattrs, capabilities, GMP: factor and expr use their
# own big numbers then; OpenSSL), the translations (NLS). The same for gcc's
# program and ttpc's.
PKG := coreutils
PKG_VERSION := 9.11
PKG_SRC = $(COREUTILS_SRC)
PKG_LICENSE := GPL-3.0-or-later
PKG_PROGRAM := src/coreutils
PKG_CONFIGURE := --disable-nls --without-selinux --disable-acl --disable-xattr --disable-libcap \
    --without-libgmp --without-openssl --enable-single-binary=symlinks \
    --enable-install-program=arch,kill,uptime --enable-no-install-program=stdbuf gl_cv_have_proc_uptime=yes \
    gt_cv_locale_fr=fr_FR.ISO-8859-1 gt_cv_locale_fr_utf8=fr_FR.UTF-8 \
    gl_cv_func_working_mktime=yes \
    utils_cv_avx2_intrinsic_exists=no utils_cv_avx2_pclmul_intrinsic_exists=no \
    utils_cv_avx512_intrinsic_exists=no utils_cv_avx512_pclmul_intrinsic_exists=no \
    utils_cv_pclmul_intrinsic_exists=no utils_cv_neon_intrinsic_exists=no utils_cv_vmull_intrinsic_exists=no \
    gl_cv_crc_pclmul=no
# (no SIMD variants of cksum and wc: they pick one at run time by
# __builtin_cpu_supports, gcc's cpu model, which glibc in ff has not; the
# plain C of each for both programs)
# (mktime: as ../findutils/Makefile says)
# the test suite: coreutils' own (tests/, by the top Makefile), not gnulib's
# tests of its modules (gnulib-tests/); those that need root, or are
# expensive, skip on both runs
PKG_CHECKFLAGS := SUBDIRS=.
PKG_CHECKSECS := 14400
PKG_CSHEAP := 64
# (factor's longlong.h without its inline asm: its C, which csema translates;
# the asm of each target is what ttpc's C layer has no form for yet)
PKG_DEFINES := -DNO_ASM
PKG_LOCALES := en_US:UTF-8:en_US.utf8 fr_FR:UTF-8:fr_FR.utf8 fr_FR:ISO-8859-1:fr_FR.iso88591
include ../port.mk
