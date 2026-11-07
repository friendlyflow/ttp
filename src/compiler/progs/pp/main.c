/* Copyright (C) 2026 Nico Verrijdt. This file is part of ttp, under the
   GNU General Public License, version 3; no warranty.
   progs/pp: what the C preprocessor in ff (tools/cpp.ff) must write as gcc
   16 -E does, byte for byte (main.i is gcc's): line markers, columns,
   padding, the system header's tokens, the include path's forms. */
#include <s.h>
#include "g.h"
#include <g.h>
#include <n.h>
#define CAT(a, b) a ## b
#define XCAT(a, b) CAT (a, b)
#define F(x, ...) f (x __VA_OPT__(,) __VA_ARGS__)
#define G(x, args...) g (x, ## args)
#define EMPTY
#define LINE __LINE__
#define H(x) x
#define OBJ (1 + 2)
#define FUN() fun
#define PRAGMA(x) _Pragma (#x)
int a = CAT (1, 2) + XCAT (OB, J);
  int *p = NUL ;
  int q = BR (1 + 2) ;
	char *s = STR ( a  "b\n"  'c' ) ;
int l = LINE + __LINE__
  + H (
      __LINE__
    );
int v = F (1) + F (1, 2, 3) + G (1) + G (1, 2);
int w = EMPTY EMPTY OBJ EMPTY;
int fn = FUN () + FUN + (FUN)();
int cb = SYS_CHAR_BIT * __CHAR_BIT__;
PRAGMA (GCC diagnostic push)
#pragma GCC diagnostic ignored "-Wfoo"
#pragma weak   w1  /* a comment */  w2
#pragma GCC visibility push(default)
#pragma STDC FENV_ACCESS ON
#if defined (PRE_INCLUDED) && X == 1 && !defined (Y) && __has_include (<s.h>) && !__has_include ("none.h")
int pre = PRE_INCLUDED, x = X;
#elif 1 / 0
#else
#endif
#if (-1 < 0u) || (1 ? 2 : (1 / 0)) != 2 || 0x7fffffffffffffff + 0 < 0 || ('\377' < 0) != !__CHAR_UNSIGNED__
#error not as gcc does it
#endif
#line 100 "renamed.c"
int renamed = __LINE__; const char *file = __FILE__;
#line 200
int c0 = __COUNTER__, c1 = __COUNTER__, lvl = __INCLUDE_LEVEL__;
a = b+ +c - -d & &e | |f < <g; x = a.b + 1.e+5 + 0x1p-3 + .5;
#define PASTE_OP(a, b) a ## b
int ops = PASTE_OP (+, =) PASTE_OP (<, <) PASTE_OP (-, >) 1;
struct { int b; } t = { .b = 1 };



int after_blank_lines;








int after_more_blank_lines;
/* a comment
   over lines */ int after_comment;
int spliced \
 = 1;
