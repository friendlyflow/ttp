/* x87.h: what clang reads for x86_64's x87 long double in libgcc's C
   (clangfix.pl --target x86_64: gcc's -mlong-double-80 long double and its
   modes XF and XC), a record of its bytes that c2ff knows by its tag and
   leaves out, with why: ttpc has no x87 long double yet. A host file of
   ttp (src/libgcc), not part of libgcc. */
typedef struct __x87ld { _Alignas(16) unsigned char __b[16]; } __x87ld;
typedef struct __x87lc { _Alignas(16) unsigned char __b[32]; } __x87lc;
