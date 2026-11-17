/* A C call of an asm function whose declaration returns a floating value
   (make asmcall-check, each target): ttpc takes an asm function's value as
   a long (rax, a0, x0, r0), so csema calls it through a pointer of the
   declaration's type, whose call takes the result where the ABI returns it
   (xmm0 or st0 on x86_64, fa0 on riscv64, d0 on aarch64 and arm). The asm
   functions are progs/asmcall-<target>.ff.txt's, each its argument times 2.
   The exit status is what the C makes of their results. */
extern double asmd (double);
#ifdef __x86_64__
extern long double asmld (long double);
extern float asmf (float);
#endif
static volatile double one = 1.5;
#ifdef __x86_64__
static volatile long double lone = 2.25L;
static volatile float fone = 0.75f;
#endif

int main (void)
{
  int s = (int) (asmd (one) * 4);
#ifdef __x86_64__
  s += (int) (asmld (lone) * 8) + (int) (asmf (fone) * 64);
#endif
  return s;
}
