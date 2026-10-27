#!/bin/sh
# mkref.sh LBUILD TOP TRIPLE JOBS: the reference libgcc (src/glibc's
# libgcc-ref), libgcc.a and libgcc_eh.a as gcc's own are, built from gcc's
# source in LBUILD:
# - gcc 16's source as flake.nix pins it (nixpkgs' gcc16, the derivation
#   of GLIBC_CC: its tarball, unpacked, and its patches), in
#   LBUILD/gcc-<version> (LIBGCC_SRC);
# - gcc configured with that derivation's own flags (LBUILD/build), and of
#   its folder gcc/ only what libgcc reads (tm.h, libgcc.mvars, options.h,
#   insn-modes.h ...), not the compiler;
# - libgcc configured and built with GLIBC_CC itself (the compiler glibc and
#   gcc's libgcc were built with) and the C library's headers gcc's libgcc
#   was built with (LIBGCC_HEADERS, nixpkgs' glibc for the target):
#   LBUILD/build/TRIPLE/libgcc, its commands in build.log there;
# - then each object's .text is compared with gcc's own libgcc.a's and
#   libgcc_eh.a's: the same bytes, or it fails.
# TOP is the repository (its flake.lock pins nixpkgs). Needs the dev shell
# (GLIBC_CC, LIBGCC_HEADERS and the target's binutils).
set -e
b=$1 top=$2 triple=$3 jobs=${4:-4}
case $triple in
riscv64-unknown-linux-gnu) cross=riscv64;;
*) echo "mkref: no libgcc for $triple yet"; exit 1;;
esac
drv="--inputs-from $top nixpkgs#pkgsCross.$cross.buildPackages.gcc16.cc"
: "${GLIBC_CC:?run this in nix develop}" "${LIBGCC_HEADERS:?run this in nix develop}"
mkdir -p "$b"
cd "$b"
v=$("$GLIBC_CC" -dumpversion)
rm -rf "gcc-$v" build
nix develop $drv --unpack > unpack.log 2>&1
(cd "gcc-$v" && nix develop $drv --phase patch > ../patch.log 2>&1)
flags=$(nix eval --raw $drv.configureFlags --apply 'l: builtins.concatStringsSep " " l')
mkdir build
cd build
nix develop $drv -c sh -c "../gcc-$v/configure --prefix=$b/prefix $flags > ../configure.log 2>&1 &&
    make configure-gcc > ../configure-gcc.log 2>&1 &&
    make -j$jobs all-build-libiberty all-build-libcpp > ../build-tools.log 2>&1 &&
    make -C gcc -j$jobs -o xgcc -o specs libgcc.mvars tconfig.h tm.h options.h insn-constants.h insn-modes.h insn-flags.h > ../gcc-headers.log 2>&1" \
    || { tail -20 ../configure.log ../configure-gcc.log ../build-tools.log ../gcc-headers.log 2> /dev/null; exit 1; }
mkdir -p "$triple/libgcc"
cd "$triple/libgcc"
x=$triple-
CC="$GLIBC_CC -isystem $LIBGCC_HEADERS" CFLAGS='-g -O2' AR=${x}ar NM=${x}nm RANLIB=${x}ranlib STRIP=${x}strip AS=${x}as LD=${x}ld \
    OBJDUMP=${x}objdump LIPO=: CONFIG_SITE=no-such-file sh "../../../gcc-$v/libgcc/configure" --srcdir="../../../gcc-$v/libgcc" \
    --cache-file=./config.cache --prefix="$b/prefix" --disable-multilib --enable-threads=posix --enable-languages=c,c++,lto \
    --enable-__cxa_atexit --enable-default-pie --with-cross-host=x86_64-unknown-linux-gnu --with-target-subdir="$triple" \
    --build=x86_64-unknown-linux-gnu --host="$triple" --target="$triple" --disable-option-checking > configure.log 2>&1 \
    || { tail -20 configure.log; exit 1; }
make -j"$jobs" libgcc.a libgcc_eh.a > build.log 2>&1 || { grep -m5 -i error build.log; exit 1; }
# the same .text as gcc's own, object by object
ref=$(dirname "$("$GLIBC_CC" -print-libgcc-file-name)")
rm -rf cmp && mkdir -p cmp/ref cmp/ours
n=0
for a in libgcc.a libgcc_eh.a; do
    (cd cmp/ref && ${x}ar x "$ref/$a") && (cd cmp/ours && ${x}ar x "../../$a")
    for o in $(${x}ar t "$ref/$a"); do
        ${x}objcopy -O binary -j .text "cmp/ref/$o" cmp/ref.bin && ${x}objcopy -O binary -j .text "cmp/ours/$o" cmp/ours.bin
        cmp -s cmp/ref.bin cmp/ours.bin || { echo "mkref: $a($o): its .text is not gcc's own"; exit 1; }
        n=$((n + 1))
    done
done
rm -rf cmp
echo "libgcc-ref: $b/build/$triple/libgcc: libgcc.a and libgcc_eh.a, $n objects, each .text as gcc's own"
