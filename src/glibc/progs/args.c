/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* glibc's own startup: start.S's _start hands __libc_start_main the stack
   the kernel made, which runs main with argc and argv and sets __environ;
   main's status goes to exit, which flushes stdout. The check runs both
   builds as `args one two three` with FF_ARGS=hello in the environment.
   argv[0] (its path) is left out: the two builds have their own. No
   headers, as in stdlib.c. */

int printf (const char *, ...);
char *getenv (const char *);

int
main (int argc, char **argv)
{
  printf ("argc %d\n", argc);
  for (int i = 1; i < argc; i++)
    printf ("argv %d %s\n", i, argv[i]);
  char *v = getenv ("FF_ARGS");
  printf ("FF_ARGS %s\n", v ? v : "(none)");
  printf ("FF_NOT_SET %s\n", getenv ("FF_NOT_SET") ? "set" : "not set");
  return 40 + argc;
}
