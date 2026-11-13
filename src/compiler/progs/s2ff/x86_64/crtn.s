# 0 "../sysdeps/x86_64/crtn.S"
# 1 "/nix/store/gsayi7lir3zzdxf1pa2ycz9yjpj3yfkw-source/csu//"
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
# 1 "../sysdeps/x86_64/crtn.S"
# 39 "../sysdeps/x86_64/crtn.S"
 .section .init,"ax",@progbits
 addq $8, %rsp
 ret

 .section .fini,"ax",@progbits
 addq $8, %rsp
 ret
