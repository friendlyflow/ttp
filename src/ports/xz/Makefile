# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# XZ Utils 5.8.4 in ff (wave C1b): upstream's tarball, a flake input
# pinned by its hash (XZ_SRC in `nix develop`), built by ../port.mk: xz,
# xzdec, lzmadec and lzmainfo, and the tests of liblzma (test_check, ...:
# C programs of its API), each a tree and a program, each with the parts
# of liblzma it links (liblzma.a, static: --disable-shared).
#
#   make GTARGET=x86_64 ref units ff check
#
# Not built: the CRC of carryless multiplication (x86_64's pclmul) and of
# arm64's crc32 instructions, whose C is SIMD intrinsics and target
# attributes, which the C in ff has no form for: the generic CRC tables
# instead; the translations (NLS); the docs. The same for gcc's programs
# and ttpc's. Beside its tests, the lane's round trip: files compressed by
# each xz are decompressed by the other.
PKG := xz
PKG_VERSION := 5.8.4
PKG_SRC = $(XZ_SRC)
PKG_LICENSE := 0BSD
PKG_COPYING := COPYING.0BSD
XZ_TESTS := test_check test_hardware test_stream_buffer_decode test_stream_buffer_encode \
    test_stream_flags test_filter_flags test_filter_str test_block_header test_index \
    test_index_hash test_bcj_exact_size test_memlimit test_alone_decoder test_lzip_decoder \
    test_vli test_microlzma
PKG_PROGRAMS := src/xz/xz src/xzdec/xzdec src/xzdec/lzmadec src/lzmainfo/lzmainfo \
    $(XZ_TESTS:%=tests/%)
PKG_CONFIGURE := --disable-shared --disable-nls --disable-doc \
    --disable-clmul-crc --disable-arm64-crc32
# (libtool links a program with LDFLAGS' -static as dynamic still, only
# its own libraries static: xzdec found no /lib/ld-linux-riscv64-lp64d.so.1;
# -all-static is libtool's word for gcc's -static, at make's time, not
# configure's, whose gcc knows no such flag)
# (PTHREAD_CFLAGS empty: no -pthread on the compiles, which cpp (ff) and
# predef.pl know not; it only defines _REENTRANT, which xz reads not and
# glibc's features.h only where _POSIX_C_SOURCE is below 199506, not under
# xz's _GNU_SOURCE; glibc's threads are in libc.a, -lpthread PTHREAD_LIBS)
PKG_BUILDFLAGS = LDFLAGS='$(PKG_LDFLAGS) -all-static' PTHREAD_CFLAGS=
# the tests of liblzma, made after the build (make check would make them)
PKG_REFMORE = -C tests create_compress_files $(XZ_TESTS) $(PKG_BUILDFLAGS)
# the test suite: xz's own (tests/, automake's)
PKG_CHECKTARGET := -C tests check
PKG_ROUNDTRIP := $(CURDIR)/roundtrip.sh
include ../port.mk
