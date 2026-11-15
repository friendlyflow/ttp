# 0 "../sysdeps/arm/start.S"
# 1 "/nix/store/gsayi7lir3zzdxf1pa2ycz9yjpj3yfkw-source/csu//"
# 0 "<built-in>"
# 0 "<command-line>"
# 1 "/home/nico/.cache/ttp/glibc-gcc16/arm/obj/libc-modules.h" 1
# 0 "<command-line>" 2
# 1 "./../include/libc-symbols.h" 1
# 62 "./../include/libc-symbols.h"
# 1 "../include/libc-misc.h" 1
# 22 "../include/libc-misc.h"
# 1 "/home/nico/.cache/ttp/glibc-gcc16/arm/obj/config.h" 1
# 23 "../include/libc-misc.h" 2
# 63 "./../include/libc-symbols.h" 2
# 88 "./../include/libc-symbols.h"
# 1 "../sysdeps/generic/libc-symver.h" 1
# 25 "../sysdeps/generic/libc-symver.h"
# 1 "/home/nico/.cache/ttp/glibc-gcc16/arm/obj/config.h" 1
# 26 "../sysdeps/generic/libc-symver.h" 2
# 89 "./../include/libc-symbols.h" 2
# 1 "../include/libc-diag.h" 1
# 90 "./../include/libc-symbols.h" 2
# 661 "./../include/libc-symbols.h"
# 1 "../sysdeps/generic/symbol-hacks.h" 1
# 662 "./../include/libc-symbols.h" 2
# 0 "<command-line>" 2
# 1 "../sysdeps/arm/start.S"
# 62 "../sysdeps/arm/start.S"
 .eabi_attribute 25, 1


 .eabi_attribute 24, 1






 .text
 .globl _start
 .type _start,#function
_start:

       .fnstart

 mov fp, #0
 mov lr, #0


 pop { a2 }
 mov a3, sp


 push { a3 }


 push { a1 }
# 108 "../sysdeps/arm/start.S"
 ldr a1, .L_main_rel
 adr a4, .L_main_rel
 add a1, a4, a1

 mov a4, #0
 push { a4 }

 bl __libc_start_main
# 129 "../sysdeps/arm/start.S"
 bl abort


 .align 2





.L_main_rel:
 .word __wrap_main - .L_main_rel



       .cantunwind
       .fnend







 .type __wrap_main, %function
__wrap_main:
 b main



 .data
 .globl __data_start
__data_start:
 .long 0
 .weak data_start
 data_start = __data_start
