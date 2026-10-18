/* M4, floats: glibc's printf of double and long double (printf_fp,
   printf_fphex): %f %F %e %E %g %G %a %A, with flags, width and precision,
   rounding, the large and the small, infinity and NaN, and the same with L
   for long double, computed at run time (soft-fp in ff, as libgcc's in gcc's
   build). Both builds must print the rest of floats.expect and exit with its
   status, the sum of what printf returned. No headers, as in stdio.c. */

int printf (const char *, ...);

union bits { unsigned long u; double d; };

int
main (void)
{
  int t = 0;
  union bits nan = { 0x7ff8000000000000UL }, mnan = { 0xfff8000000000000UL };
  union bits sub = { 1 };
  double third = 1.0, big = 1e300, zero = 0.0;
  long double l = 3, ltiny = 1e-300;
  third /= 3;
  t += printf ("%f %f %f %f\n", 0.0, 1.5, -2.25, third);
  t += printf ("%.0f %.0f %.0f %.1f %.10f %.20f\n", 0.5, 1.5, 2.5, 0.05, third, 0.1);
  t += printf ("%e %E %.3e %.0e %e\n", 12345.678, 0.000123, 1e300, 5e-5, -zero);
  t += printf ("%g %g %g %G %g %g %g\n", 100000.0, 1000000.0, 0.0001, 1e-5, 123.456, 0.0, third);
  t += printf ("%a %A %.2a %a %a\n", 1.0, -0.5, 1.1, 0.0, sub.d);
  t += printf ("[%10.3f] [%-10.3f] [%+f] [% f] [%010.2f] [%-+12.4e]\n", 3.14159, 3.14159, 2.0, 2.0, -3.5, 6.02e23);
  t += printf ("[%#.0f] [%#g] [%#.3g] [%#x]\n", 7.0, 1.0, 2.0, 0);
  t += printf ("[%*.*f] [%.*e]\n", 9, 2, 1.005, 3, 2.5e-10);
  t += printf ("%f %F %e %g %f %5.1f|\n", big * big, -big * big, big * big, -big * big, nan.d, mnan.d);
  t += printf ("%f\n", 1e20);
  t += printf ("%g %e %.17g\n", sub.d, 1.7976931348623157e308, 0.1);
  t += printf ("%Lf %Le %Lg %La\n", l / 7, l / 7, l / 7, l / 7);
  t += printf ("%.30Lf %.25Le\n", l / 7, ltiny * ltiny);
  t += printf ("%Lg %Lg %LG %Le\n", (long double) big * big, l * 1e10, -l / 1e30, (long double) 0);
  t += printf ("[%15.4Lf] [%-15.3Le] [%+.0Lf]\n", l * 1000 / 7, l, l / 2);
  return t & 255;
}
