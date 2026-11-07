# 0 "progs/pp/main.c"
# 0 "<built-in>"
# 0 "<command-line>"
# 1 "./progs/pp/pre.h" 1
# 0 "<command-line>" 2
# 1 "progs/pp/main.c"





# 1 "progs/pp/sys/s.h" 1 3



       
# 7 "progs/pp/main.c" 2
# 1 "progs/pp/inc/g.h" 1





int g_once;
# 8 "progs/pp/main.c" 2

# 1 "progs/pp/inc/n.h" 1


# 1 "progs/pp/inc2/n.h" 1
# 4 "progs/pp/inc/n.h" 2
int n_first = 2;
# 10 "progs/pp/main.c" 2
# 20 "progs/pp/main.c"
int a = 12 + (1 + 2);
  int *p = 
# 21 "progs/pp/main.c" 3
          ((void *)0) 
# 21 "progs/pp/main.c"
              ;
  int q = 
# 22 "progs/pp/main.c" 3
         [
# 22 "progs/pp/main.c"
         1 + 2
# 22 "progs/pp/main.c" 3
         ] 
# 22 "progs/pp/main.c"
                    ;
 char *s = "a \"b\\n\" 'c'" ;
int l = 24 + 24
  + 26

     ;
int v = f (1 ) + f (1 , 2, 3) + g (1) + g (1, 2);
int w = (1 + 2) ;
int fn = fun + FUN + (FUN)();
int cb = 8 
# 31 "progs/pp/main.c"
                     * 8;

# 32 "progs/pp/main.c"
#pragma GCC diagnostic push
 
# 33 "progs/pp/main.c"
#pragma GCC diagnostic ignored "-Wfoo"
#pragma weak w1 w2
#pragma GCC visibility push(default)
#pragma STDC FENV_ACCESS ON

int pre = 1, x = 1;
# 100 "renamed.c"
int renamed = 100; const char *file = "renamed.c";
# 200 "renamed.c"
int c0 = 0, c1 = 1, lvl = 0;
a = b+ +c - -d & &e | |f < <g; x = a.b + 1.e+5 + 0x1p-3 + .5;

int ops = += << -> 1;
struct { int b; } t = { .b = 1 };



int after_blank_lines;
# 217 "renamed.c"
int after_more_blank_lines;

                 int after_comment;
int spliced
 = 1;
