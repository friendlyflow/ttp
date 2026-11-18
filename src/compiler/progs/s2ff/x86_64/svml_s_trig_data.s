# 0 "../sysdeps/x86_64/fpu/svml_s_trig_data.S"
# 1 "/nix/store/gsayi7lir3zzdxf1pa2ycz9yjpj3yfkw-source/mathvec//"
# 0 "<built-in>"
# 0 "<command-line>"
# 1 "/home/nico/.cache/ttp/glibc-gcc16/x86_64/obj/libc-modules.h" 1
# 0 "<command-line>" 2
# 1 "./../include/libc-symbols.h" 1
# 62 "./../include/libc-symbols.h"
# 1 "../include/libc-misc.h" 1
# 22 "../include/libc-misc.h"
# 1 "/home/nico/.cache/ttp/glibc-gcc16/x86_64/obj/config.h" 1
# 23 "../include/libc-misc.h" 2
# 63 "./../include/libc-symbols.h" 2
# 88 "./../include/libc-symbols.h"
# 1 "../sysdeps/generic/libc-symver.h" 1
# 25 "../sysdeps/generic/libc-symver.h"
# 1 "/home/nico/.cache/ttp/glibc-gcc16/x86_64/obj/config.h" 1
# 26 "../sysdeps/generic/libc-symver.h" 2
# 89 "./../include/libc-symbols.h" 2
# 1 "../include/libc-diag.h" 1
# 90 "./../include/libc-symbols.h" 2
# 661 "./../include/libc-symbols.h"
# 1 "../sysdeps/generic/symbol-hacks.h" 1
# 662 "./../include/libc-symbols.h" 2
# 0 "<command-line>" 2
# 1 "../sysdeps/x86_64/fpu/svml_s_trig_data.S"
# 19 "../sysdeps/x86_64/fpu/svml_s_trig_data.S"
# 1 "../sysdeps/x86_64/fpu/svml_s_trig_data.h" 1
# 22 "../sysdeps/x86_64/fpu/svml_s_trig_data.h"
.macro float_vector offset value
.if .-__svml_s_trig_data != \offset
.err
.endif
.rept 16
.long \value
.endr
.endm
# 20 "../sysdeps/x86_64/fpu/svml_s_trig_data.S" 2

 .section .rodata, "a"
 .align 64






 .globl __svml_s_trig_data
__svml_s_trig_data:



float_vector 0 0x7fffffff


float_vector 64 0x461c4000


float_vector 64*2 0x7f800000



float_vector 64*3 0xbe2aaaab


float_vector 64*4 0x3c08885c


float_vector 64*5 0xbf000000


float_vector 64*6 0x3d2aaa7c



float_vector 64*7 0x40490000


float_vector 64*8 0x3a7da000


float_vector 64*9 0x34222000


float_vector 64*10 0x2cb4611a



float_vector 64*11 0x40490fdb


float_vector 64*12 0xb3bbbd2e


float_vector 64*13 0xa7772ced


float_vector 64*14 0xbe2aaaa6
float_vector 64*15 0x3c08876a
float_vector 64*16 0xb94fb7ff
float_vector 64*17 0x362edef8


float_vector 64*18 0x3c088768
float_vector 64*19 0xb94fb6cf
float_vector 64*20 0x362ec335


float_vector 64*21 0x3ea2f983


float_vector 64*22 0x4b400000


float_vector 64*23 0x3fc90fdb


float_vector 64*24 0x3f000000


float_vector 64*25 0x000000ff


float_vector 64*26 0x00000040


float_vector 64*27 0x80000000

 .type __svml_s_trig_data,@object
 .size __svml_s_trig_data,.-__svml_s_trig_data
