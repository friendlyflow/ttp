/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* s2ff.c: dev source of tools/s2ff.ff, gen/s2ff.pl in ff: the functions
   of a preprocessed .S file (the .s its build assembled), each an asm
   function of ttpc's C layer, from the .s and what GNU as made of it (its
   objdump). The same output, messages and status as the Perl, which stays
   as a cross-check (make s2ff-crosscheck).

     s2ff [--page name | --items | --size | --facts FILE] file.s file.dump
     s2ff --header file.s ...

   Each Perl pattern is one of lib.c's (the same text), the Perl's steps in
   its order. */

#include "lib.c"
#include "header.c"

static struct str *src_s, *dump_s, *page;
static int o_size, o_items, o_align, o_header, o_locals, o_skip;
static char *tgt_name;
static struct str *facts_f;
static struct vec *zero_v, *then_v, *files;
static struct str *where;
static void fail_s (struct str *msg)
{
  struct str *x = s_of ("s2ff: ");
  s_app (x, where); s_cat (x, ": "); s_app (x, msg); s_cat (x, "\n");
  pdie (x);
}
static void fail_c (char *msg) { fail_s (s_of (msg)); }
static void fail2 (char *a, struct str *b) { struct str *x = s_of (a); s_app (x, b); fail_s (x); }
static void facts_write (struct str *t)
{
  long fd;
  if (!facts_f) return;
  fd = cp_create ((char *) facts_f->p);
  if (fd < 0) { struct str *x = s_of ("s2ff: cannot write "); perrno = -fd; s_app (x, facts_f); s_cat (x, ": "); s_cat (x, strerror_of (-fd)); s_cat (x, "\n"); pdie (x); }
  cp_write ((int) fd, t->p, t->n);
  perrno = 25;
}

/* ---- numbers: a constant expression, as Perl's eval "use integer; ..." takes it */
static long dec (struct str *v) { long r = 0, i; for (i = 0; i < v->n && is_digit (v->p[i]); i++) r = r * 10 + v->p[i] - '0'; return r; }
static int isnum (struct str *v) { return m (v, "\\d") && mf (v, "^[\\s\\da-fx()+\\-*/%<>&|~^]+$", "i"); }
static unsigned char *ep; static long en, ei; static int ebad;
static void e_ws (void) { while (ei < en && is_space (ep[ei])) ei++; }
static long e_or (void);
static long e_unary (void)
{
  e_ws ();
  if (ei < en && ep[ei] == '-') { ei++; return -e_unary (); }
  if (ei < en && ep[ei] == '+') { ei++; return e_unary (); }
  if (ei < en && ep[ei] == '~') { ei++; return ~e_unary (); }
  if (ei < en && ep[ei] == '(') {
    long v;
    ei++;
    v = e_or ();
    e_ws ();
    if (ei < en && ep[ei] == ')') ei++; else ebad = 1;
    return v;
  }
  if (ei < en && is_digit (ep[ei])) {
    long v = 0;
    if (ep[ei] == '0' && ei + 1 < en && is_digit (ep[ei + 1])) {   /* octal, as Perl reads 010 */
      while (ei < en && is_digit (ep[ei])) { if (ep[ei] > '7') ebad = 1; v = v * 8 + (ep[ei] - '0'); ei++; }
      return v;
    }
    while (ei < en && is_digit (ep[ei])) { v = v * 10 + (ep[ei] - '0'); ei++; }
    return v;
  }
  ebad = 1;
  return 0;
}
static long e_pow (void)
{
  long b = e_unary ();
  e_ws ();
  if (ei + 1 < en && ep[ei] == '*' && ep[ei + 1] == '*') {
    long x, r = 1;
    ei += 2;
    x = e_pow ();
    while (x-- > 0) r = r * b;
    return r;
  }
  return b;
}
static long e_mul (void)
{
  long v = e_pow ();
  for (;;) {
    e_ws ();
    if (ei < en && ep[ei] == '*' && !(ei + 1 < en && ep[ei + 1] == '*')) { ei++; v = v * e_pow (); }
    else if (ei < en && (ep[ei] == '/' || ep[ei] == '%')) {
      int c = ep[ei];
      long d;
      ei++;
      d = e_pow ();
      if (d == 0) { ebad = 1; return 0; }
      v = c == '/' ? v / d : v % d;
    } else return v;
  }
}
static long e_add (void)
{
  long v = e_mul ();
  for (;;) {
    e_ws ();
    if (ei < en && ep[ei] == '+') { ei++; v = v + e_mul (); }
    else if (ei < en && ep[ei] == '-') { ei++; v = v - e_mul (); }
    else return v;
  }
}
static long e_shift (void)
{
  long v = e_add ();
  for (;;) {
    e_ws ();
    if (ei + 1 < en && ep[ei] == '<' && ep[ei + 1] == '<') { ei += 2; v = (long) ((unsigned long) v << e_add ()); }
    else if (ei + 1 < en && ep[ei] == '>' && ep[ei + 1] == '>') { ei += 2; v = v >> e_add (); }
    else return v;
  }
}
static long e_rel (void)
{
  long v = e_shift ();
  for (;;) {
    e_ws ();
    if (ei < en && ep[ei] == '<') { ei++; v = v < e_shift (); }
    else if (ei < en && ep[ei] == '>') { ei++; v = v > e_shift (); }
    else return v;
  }
}
static long e_and (void)
{
  long v = e_rel ();
  for (;;) {
    e_ws ();
    if (ei < en && ep[ei] == '&' && !(ei + 1 < en && ep[ei + 1] == '&')) { ei++; v = v & e_rel (); }
    else return v;
  }
}
static long e_bor (void)
{
  long v = e_and ();
  for (;;) {
    e_ws ();
    if (ei < en && ep[ei] == '|' && !(ei + 1 < en && ep[ei + 1] == '|')) { ei++; v = v | e_and (); }
    else if (ei < en && ep[ei] == '^') { ei++; v = v ^ e_and (); }
    else return v;
  }
}
static long e_land (void)
{
  long v = e_bor ();
  for (;;) {
    e_ws ();
    if (ei + 1 < en && ep[ei] == '&' && ep[ei + 1] == '&') { long w; ei += 2; w = e_bor (); v = v && w; }
    else return v;
  }
}
static long e_or (void)
{
  long v = e_land ();
  for (;;) {
    e_ws ();
    if (ei + 1 < en && ep[ei] == '|' && ep[ei + 1] == '|') { long w; ei += 2; w = e_land (); v = v ? v : w; }
    else return v;
  }
}
static long num (struct str *v)
{
  struct str *e;
  long r;
  if (!isnum (v)) fail2 ("not a number: ", v);
  /* s/\b0x([0-9a-f]+)\b/hex($1)/gie */
  e = s_of ("");
  {
    long at = 0, last = 0;
    struct rx *rr = rx_get ("\\b0x([0-9a-f]+)\\b", "i");
    while (at <= v->n && rx_exec (rr, v->p, v->n, at)) {
      unsigned long h = 0;
      long k;
      s_add (e, v->p + last, rc[0] - last);
      for (k = rc[2]; k < rc[3]; k++) h = h * 16 + (unsigned long) hexv (v->p[k]);
      s_app (e, s_unum (h));
      last = rc[1];
      at = rc[1] > rc[0] ? rc[1] : rc[0] + 1;
    }
    s_add (e, v->p + last, v->n - last);
  }
  if (!m (e, "^[\\s\\d()+\\-*/%<>&|~^]+$")) fail2 ("not a number: ", v);
  ep = e->p; en = e->n; ei = 0; ebad = 0;
  r = e_or ();
  e_ws ();
  if (ebad || ei != en) fail2 ("not a number: ", v);
  return r;
}

/* ---- operands */
static struct vec *split_ops (struct str *s)
{
  struct vec *ops = v_new ();
  struct str *cur = s_of ("");
  long depth = 0, i;
  for (i = 0; i < s->n; i++) {
    int c = s->p[i];
    if (c == '(') depth++;
    if (c == ')') depth--;
    if (c == ',' && !depth) { v_push (ops, cur); cur = s_of (""); continue; }
    s_chr (cur, c);
  }
  if (m (cur, "\\S")) v_push (ops, cur);
  for (i = 0; i < ops->n; i++) ops->v[i] = s_trim (ops->v[i]);
  return ops;
}
static struct str *O (struct vec *o, long i) { if (i < 0) i += o->n; return i >= 0 && i < o->n ? o->v[i] : s_of (""); }

static char *abi_names[32];
static struct str *reg (struct str *r)
{
  long k;
  if (s_is (r, "fp")) return s_of ("s0");
  if (r->n >= 2 && r->n <= 3 && r->p[0] == 'x' && is_digit (r->p[1]) && (r->n == 2 || is_digit (r->p[2])) && !(r->n == 3 && r->p[1] == '0')) {
    k = r->p[1] - '0';
    if (r->n == 3) k = k * 10 + r->p[2] - '0';
    if (k < 32) return s_of (abi_names[k]);
  }
  return r;
}
/* off(base) of a load or store */
static long mem_off; static struct str *mem_base;
static void mem (struct str *x)
{
  struct str *o;
  if (!m (x, "^(.*)\\((\\w+)\\)$")) fail2 ("not off(base): ", x);
  o = g (1); mem_base = reg (g (2));
  mem_off = num (o->n == 0 ? s_of ("0") : o);
}

static struct hash *csr, *sew, *lmul;
static long vtype (struct vec *o, long from)
{
  struct str *s = O (o, from), *l = O (o, from + 1), *ta = O (o, from + 2), *ma = O (o, from + 3);
  if (!(from < o->n && from + 1 < o->n && h_has (sew, s) && h_has (lmul, l))) {
    struct str *x = s_of ("not a vtype: ");
    long i;
    for (i = from; i < o->n; i++) { if (i > from) s_cat (x, " "); s_app (x, o->v[i]); }
    fail_s (x);
  }
  return (s_is (ma, "ma") ? 1 : 0) << 7 | (s_is (ta, "ta") ? 1 : 0) << 6 | h_iv (sew, s) << 3 | h_iv (lmul, l);
}

/* a leaf for each operand: a register, a number, or a label of the function */
static struct nd *leaf (struct str *o)
{
  if (m (o, "^[a-z][a-z0-9]*$") && !h_has (csr, o)) return nd_new (reg (o));
  if (isnum (o)) return nd_new (s_num (num (o)));
  return nd_new (o);
}
static struct nd *LO (struct str *o) { return leaf (o); }
static struct nd *LC (char *o) { return leaf (s_of (o)); }
static struct nd *LN (long v) { return nd_new (s_num (v)); }
static struct nd *ins0 (struct str *op) { return nd_new (op); }
static struct nd *ins1 (struct str *op, struct nd *a) { return nd1 (op, a); }
static struct nd *ins2 (struct str *op, struct nd *a, struct nd *b) { return nd2 (op, a, b); }
static struct nd *ins3 (struct str *op, struct nd *a, struct nd *b, struct nd *c) { return nd_add (nd2 (op, a, b), c); }
static struct nd *ins4 (struct str *op, struct nd *a, struct nd *b, struct nd *c, struct nd *d) { return nd_add (ins3 (op, a, b, c), d); }
static struct nd *ins5 (struct str *op, struct nd *a, struct nd *b, struct nd *c, struct nd *d, struct nd *e) { return nd_add (ins4 (op, a, b, c, d), e); }
static struct nd *rel (struct str *t) { return nd1 (s_of ("rel"), nd_new (t)); }
/* ins(op, reverse @o) */
static struct nd *ins_rev (struct str *op, struct vec *o)
{
  struct nd *x = nd_new (op);
  long i;
  for (i = o->n - 1; i >= 0; i--) nd_add (x, LO (o->v[i]));
  return x;
}
static struct nd *ins_all (struct str *op, struct vec *o, long from)
{
  struct nd *x = nd_new (op);
  long i;
  for (i = from; i < o->n; i++) nd_add (x, LO (o->v[i]));
  return x;
}

static struct hash *rtype, *itype, *loadk, *storek, *btype, *macro, *vmask;
static unsigned long cur_enc;
static int op_is (struct str *op, char *c) { return s_is (op, c); }
static struct str *S (char *c) { return s_of (c); }
/* a source instruction GNU as left at 4 bytes */
static struct nd *full (struct str *op, struct vec *o)
{
  long vm = 1;
  long rm;
  if (op_is (op, "csrr")) {
    struct hent *e = h_find (csr, O (o, 1));
    return ins2 (op, e ? LN (e->iv) : LN (num (O (o, 1))), LO (O (o, 0)));
  }
  if (m (op, "^(ecall|ebreak|fence\\.i)$") && !o->n) return ins0 (op);
  if (o->n && s_is (o->v[o->n - 1], "v0.t")) { o->n--; vm = 0; }
  if (m (op, "^(add|and|or|xor)$") && o->n == 3 && mf (o->v[2], "^-?(?:0x[0-9a-f]+|\\d+)$", "i")) { struct str *x = s_dup (op); s_cat (x, "i"); return ins_rev (x, o); }
  if (h_has (rtype, op) || h_has (itype, op) || h_has (macro, op)) return ins_rev (op, o);
  if (op_is (op, "jal") && o->n <= 2 && !isnum (O (o, -1))) return ins2 (op, rel (O (o, -1)), o->n == 2 ? LO (O (o, 0)) : LC ("ra"));
  if (op_is (op, "jalr")) {
    if (o->n == 1) return ins3 (op, LN (0), LO (O (o, 0)), LC ("ra"));
    if (o->n == 2) { mem (O (o, 1)); return ins3 (op, LN (mem_off), LO (mem_base), LO (O (o, 0))); }
    return ins3 (op, LN (num (O (o, 2))), LO (O (o, 1)), LO (O (o, 0)));
  }
  if (h_has (loadk, op)) { mem (O (o, 1)); return ins3 (op, LN (mem_off), LO (mem_base), LO (O (o, 0))); }
  if (h_has (storek, op)) { mem (O (o, 1)); return ins3 (op, LN (mem_off), LO (O (o, 0)), LO (mem_base)); }
  if (h_has (btype, op)) return ins3 (op, rel (O (o, 2)), LO (O (o, 1)), LO (O (o, 0)));
  if (op_is (op, "sltz")) return ins3 (S ("slt"), LC ("zero"), LO (O (o, 1)), LO (O (o, 0)));
  if (op_is (op, "sgtz")) return ins3 (S ("slt"), LO (O (o, 1)), LC ("zero"), LO (O (o, 0)));
  if (op_is (op, "snez")) return ins3 (S ("sltu"), LO (O (o, 1)), LC ("zero"), LO (O (o, 0)));
  if (op_is (op, "sgtu")) return ins3 (S ("sltu"), LO (O (o, 1)), LO (O (o, 2)), LO (O (o, 0)));
  if (op_is (op, "sgt")) return ins3 (S ("slt"), LO (O (o, 1)), LO (O (o, 2)), LO (O (o, 0)));
  if (op_is (op, "not")) return ins3 (S ("xori"), LN (-1), LO (O (o, 1)), LO (O (o, 0)));
  if (op_is (op, "negw")) return ins3 (S ("subw"), LO (O (o, 1)), LC ("zero"), LO (O (o, 0)));
  if (op_is (op, "sext.w")) return ins3 (S ("addiw"), LN (0), LO (O (o, 1)), LO (O (o, 0)));
  if (op_is (op, "frsr") || op_is (op, "frcsr")) return ins3 (S ("csrrs"), LN (3), LC ("zero"), LO (O (o, 0)));
  if (op_is (op, "fssr") || op_is (op, "fscsr")) return ins3 (S ("csrrw"), LN (3), LO (O (o, -1)), o->n == 2 ? LO (O (o, 0)) : LC ("zero"));
  rm = (long) ((cur_enc >> 12) & 7);
  if (m (op, "^f(add|sub|mul|div)\\.[sd]$")) return ins4 (op, LO (O (o, 2)), LO (O (o, 1)), LN (rm), LO (O (o, 0)));
  if (m (op, "^f(n?madd|n?msub)\\.[sd]$")) return ins5 (op, LO (O (o, 3)), LO (O (o, 2)), LO (O (o, 1)), LN (rm), LO (O (o, 0)));
  if (m (op, "^f(sqrt\\.[sd]|cvt\\.\\w+\\.\\w+)$")) return ins3 (op, LO (O (o, 1)), LN (rm), LO (O (o, 0)));
  if (m (op, "^f(sgnjn?|sgnjx|min|max|eq|lt|le)\\.[sd]$")) return ins3 (op, LO (O (o, 2)), LO (O (o, 1)), LO (O (o, 0)));
  if (m (op, "^f(class\\.[sd]|mv\\.x\\.[wd]|mv\\.[wd]\\.x)$")) return ins2 (op, LO (O (o, 1)), LO (O (o, 0)));
  if (m (op, "^f(?|mv()|neg(n)|abs(x))\\.([sd])$")) { struct str *x = S ("fsgnj"); s_app (x, g0 (1)); s_cat (x, "."); s_app (x, g0 (2)); return ins3 (x, LO (O (o, 1)), LO (O (o, 1)), LO (O (o, 0))); }
  if (m (op, "^f(?|gt(lt)|ge(le))\\.([sd])$")) { struct str *x = S ("f"); s_app (x, g0 (1)); s_cat (x, "."); s_app (x, g0 (2)); return ins3 (x, LO (O (o, 1)), LO (O (o, 2)), LO (O (o, 0))); }
  if (op_is (op, "frflags")) return ins3 (S ("csrrs"), LN (1), LC ("zero"), LO (O (o, 0)));
  if (op_is (op, "fsflags")) return ins3 (S ("csrrw"), LN (1), LO (O (o, -1)), o->n == 2 ? LO (O (o, 0)) : LC ("zero"));
  if (op_is (op, "vsetvli")) return ins3 (op, LN (vtype (o, 2)), LO (O (o, 1)), LO (O (o, 0)));
  if (op_is (op, "vsetivli")) return ins3 (op, LN (vtype (o, 2)), LN (num (O (o, 1))), LO (O (o, 0)));
  if (op_is (op, "vsetvl")) return ins3 (op, LO (O (o, 2)), LO (O (o, 1)), LO (O (o, 0)));
  if (m (op, "^v[ls]e\\d+(ff)?\\.v$")) {
    struct str *b;
    if (!m (O (o, 1), "^\\((\\w+)\\)$")) fail2 ("not (base): ", O (o, 1));
    b = g (1);
    return ins3 (op, LN (vm), LO (b), LO (O (o, 0)));
  }
  if (m (op, "^(\\w+)\\.(vv|vx|vi|vs)$") && h_has (vmask, g (1))) return ins4 (op, LN (vm), LO (O (o, 1)), LO (O (o, 2)), LO (O (o, 0)));
  if (m (op, "^(vfirst|vcpop|vmsbf|vmsof|vmsif)\\.m$")) return ins3 (op, LN (vm), LO (O (o, 1)), LO (O (o, 0)));
  if (op_is (op, "vid.v")) return ins2 (op, LN (vm), LO (O (o, 0)));
  if (m (op, "^vmv\\.(v\\.[vxi]|x\\.s|s\\.x)$")) return ins2 (op, LO (O (o, 1)), LO (O (o, 0)));
  if (m (op, "^vm\\w+\\.mm$")) return ins3 (op, LO (O (o, 1)), LO (O (o, 2)), LO (O (o, 0)));
  fail2 ("no ff form for ", op);
  return 0;
}

/* what GNU as made: the size and the canonical form of each instruction */
struct made { long bytes; struct str *op, *args; unsigned long enc; };
static struct made **made;
static long nmade;

/* an instruction GNU as compressed, in its canonical form; a branch target is the source's label */
static struct nd *short_ (struct made *mm, struct str *label)
{
  struct str *op = mm->op;
  struct vec *o = split_ops (ssub (mm->args, "\\s*<.*>$", "", ""));
  if (m (op, "^c\\.(mv|add|sub|xor|or|and|subw|addw)$")) return ins_all (op, o, 0);
  if (m (op, "^c\\.(jr|jalr)$")) return ins1 (op, LO (O (o, 0)));
  if (m (op, "^c\\.(li|addi|addiw|slli|srli|srai|andi)$")) return ins2 (op, LO (O (o, 1)), LO (O (o, 0)));
  if (m (op, "^c\\.(beqz|bnez)$")) return ins2 (op, rel (label ? label : s_of ("")), LO (O (o, 0)));
  if (op_is (op, "c.j")) return ins1 (op, rel (label ? label : s_of ("")));
  if (m (op, "^c\\.(ld|lw|fld)$")) { mem (O (o, 1)); return ins3 (op, LN (mem_off), LO (mem_base), LO (O (o, 0))); }
  if (m (op, "^c\\.(sd|sw|fsd)$")) { mem (O (o, 1)); return ins3 (op, LN (mem_off), LO (mem_base), LO (O (o, 0))); }
  if (m (op, "^c\\.(ldsp|lwsp|sdsp|swsp|fldsp|fsdsp)$")) { mem (O (o, 1)); return ins2 (op, LN (mem_off), LO (O (o, 0))); }
  if (op_is (op, "c.lui")) { long v = num (O (o, 1)) << 12; if (v >= 2147483648L) v -= 4294967296L; return ins2 (op, LN (v), LO (O (o, 0))); }
  if (op_is (op, "c.addi4spn")) return ins2 (op, LN (num (O (o, 2))), LO (O (o, 0)));
  if (op_is (op, "c.addi16sp")) return ins1 (op, LN (num (O (o, 1))));
  if (m (op, "^c\\.(nop|ebreak)$")) return ins0 (op);
  fail2 ("no ff form for ", op);
  return 0;
}
/* an instruction of a li as GNU as made it, from its dump */
static struct nd *canon (struct made *mm)
{
  struct vec *o;
  if (mm->bytes == 2) return short_ (mm, 0);
  o = split_ops (ssub (mm->args, "\\s*#.*$", "", ""));
  if (op_is (mm->op, "lui")) { long v = num (O (o, 1)) << 12; if (v >= 2147483648L) v -= 4294967296L; return ins2 (S ("lui"), LN (v), LO (O (o, 0))); }
  if (m (mm->op, "^(addi|addiw)$")) return ins3 (mm->op, LN (num (O (o, 2))), LO (O (o, 1)), LO (O (o, 0)));
  { struct str *x = s_of ("no ff form for "); s_app (x, mm->op); s_cat (x, " in a li"); fail_s (x); }
  return 0;
}

/* ---- the source */
static struct vec *fns;
static struct nd *fn, *block;
static long n_at, pos, ends;
static struct hash *tls, *got, *numeric, *dlabel, *datadef;
static struct str *label;
static struct str *dname (struct str *l)
{
  struct str *x;
  if (!h_iv (dlabel, l)) return l;
  x = ssub (l, "^\\.", "", "");
  s_cat (x, " ");
  s_app (x, ssub (ssub (src_s, ".*/", "", ""), "\\.\\w+$", "", ""));
  return x;
}
static struct made *take (void)
{
  struct made *mm;
  if (n_at >= nmade) { struct str *x = s_of ("GNU as made fewer instructions than "); s_app (x, src_s); s_cat (x, " has"); fail_s (x); }
  mm = made[n_at++];
  pos += mm->bytes;
  ends = m (mm->op, "^c\\.(jr|j)$") || (m (mm->op, "^(jal|jalr)$") && m (mm->args, "^zero\\b")) ? 1 : 0;
  return mm;
}
static void finish (void)
{
  struct vec *k;
  long i;
  if (!(fn && (tls->n || got->n))) return;
  nd_add (fn, nd1 (S ("align"), ndc ("8")));
  k = h_sorted (tls);
  for (i = 0; i < k->n; i++) { struct str *x = S (".Ltls "); s_app (x, k->v[i]); s_cat (x, ":"); nd_add (fn, nd1 (x, nd1 (S ("dword"), nd1 (S ("tprel"), nd_new (k->v[i]))))); }
  k = h_sorted (got);
  for (i = 0; i < k->n; i++) { struct str *x = S (".Lgot "); s_app (x, k->v[i]); s_cat (x, ":"); nd_add (fn, nd1 (x, nd1 (S ("dword"), nd_new (k->v[i])))); }
  h_clear (tls); h_clear (got);
}
static struct nd *into_of (void) { return block ? block : fn; }
static struct nd *fn_head (struct str *name, struct str *file, long lineno)
{
  struct str *x = s_dup (name), *c = s_dup (label);
  s_cat (x, ":");
  s_cat (c, " "); s_app (c, file); s_cat (c, ":"); s_app (c, s_num (lineno));
  return nd2 (x, ndc ("asm"), nd1 (S ("comment"), nd_new (c)));
}
static struct nd *alias_of (struct str *a, struct str *b) { struct str *x = s_dup (a); s_cat (x, ":"); return nd2 (x, ndc ("alias"), nd_new (b)); }

/* gcc's read-only data */
struct dobj { struct str *name, *sec; unsigned char *b; long nb, room; };
static struct vec *dobjs, *dset;
static void dob_add (struct dobj *o, long v) { if (o->nb == o->room) { long r = o->room ? o->room * 2 : 64, i; unsigned char *x = alloc (r); for (i = 0; i < o->nb; i++) x[i] = o->b[i]; o->b = x; o->room = r; } o->b[o->nb++] = (unsigned char) v; }
struct dset_e { struct str *x, *y; long k; };
static void dset_push (struct str *x, struct str *y, long k) { struct dset_e *e = alloc (sizeof (struct dset_e)); e->x = x; e->y = y; e->k = k; v_push (dset, e); }

static int isasm (struct nd *f) { return ndn (f) && s_is (ndk (f, 0)->c, "asm"); }
static int is_labelnode (struct nd *x) { return ndn (x) && x->c->n && x->c->p[x->c->n - 1] == ':'; }
static struct str *unlabel (struct str *c) { return c->n && c->p[c->n - 1] == ':' ? s_sub (c, 0, c->n - 1) : c; }
static struct hash *labels_of (struct nd *f)
{
  struct hash *h = h_new ();
  long i;
  for (i = 0; i < ndn (f); i++) if (is_labelnode (ndk (f, i))) h_set (h, unlabel (ndk (f, i)->c), 1);
  return h;
}
static void targets_of (struct nd *f, struct vec *t)
{
  long i;
  for (i = 0; i < ndn (f); i++) { struct nd *x = ndk (f, i); if (s_is (x->c, "rel")) v_push (t, ndk (x, 0)->c); targets_of (x, t); }
}
static int any_label_in (struct nd *f, struct hash *t)
{
  long i;
  for (i = 0; i < ndn (f); i++) if (is_labelnode (ndk (f, i)) && h_has (t, unlabel (ndk (f, i)->c))) return 1;
  return 0;
}
static struct hash *aliases;
static void alias_walk (struct nd *f, struct hash *own)
{
  long i;
  for (i = 0; i < ndn (f); i++) {
    struct nd *x = ndk (f, i);
    if (s_is (x->c, "rel")) {
      struct str *a = h_pv (aliases, ndk (x, 0)->c);
      if (a && h_has (own, a)) ndk (x, 0)->c = a;
    }
    alias_walk (x, own);
  }
}

static void rv_main (void)
{
  struct str *dumpt, *srct;
  struct lines *ls;
  struct str *file;
  long lineno = 0, li;
  struct str *other = 0;
  struct vec *pending = v_new ();
  struct dobj *dobj = 0;
  /* GNU as's instructions */
  dumpt = p_slurp ((char *) dump_s->p, "s2ff");
  ls = split_lines (dumpt);
  made = alloc ((ls->n + 1) * sizeof (struct made *));
  for (li = 0; li < ls->n; li++) {
    struct made *mm;
    struct str *hx;
    long k;
    if (!m (ls->l[li], "^\\s*([0-9a-f]+):\\t([0-9a-f ]+?)\\s*\\t(\\S+)\\s*(.*)$")) continue;
    mm = alloc (sizeof (struct made));
    mm->op = g (3); mm->args = g (4);
    hx = ssub (g (2), " ", "g", "");
    mm->bytes = hx->n / 2;
    for (k = 0; k < hx->n; k++) mm->enc = mm->enc * 16 + (unsigned long) hexv (hx->p[k]);
    made[nmade++] = mm;
  }
  file = ssub (src_s, ".*/", "", "");
  label = unit_label (src_s);
  /* gcc's read-only data labels, known before the code that names them */
  srct = p_slurp ((char *) src_s->p, "s2ff");
  ls = split_lines (srct);
  {
    struct str *sec = S (".text");
    for (li = 0; li < ls->n; li++) {
      struct str *l = ls->l[li];
      if (m (l, "^\\s*\\.(data|bss|text|section\\s+([^,\\s]+))")) { if (gdef (2)) sec = g (2); else { sec = S ("."); s_app (sec, g (1)); } }
      if (m (l, "^\\s*\\.text\\b")) sec = S (".text");
      if (!m (sec, "^\\.s?rodata")) continue;
      if (m (l, "^([.\\w]+):") || m (l, "^\\s*\\.set\\s+([.\\w]+)\\s*,")) h_set (dlabel, g (1), 1);
    }
  }
  perrno = 25;   /* (open my $s: it is read line by line) */
  for (li = 0; li < ls->n; li++) {
    struct str *l = chomp (ls->l[li]);
    struct vec *sts;
    long sx;
    if (m (l, "^# (\\d+) \"([^\"]*)\"")) {
      lineno = dec (g (1)) - 1;
      file = ssub (ssub (g (2), "^(\\.\\./)+", "", ""), "^gcc-[\\d.]+/", "", "");
      continue;
    }
    lineno++;
    if (!m (l, "\"")) l = ssub (l, "\\s*#.*$", "", "");
    where = s_dup (src_s); s_cat (where, " ("); s_app (where, file); s_cat (where, ":"); s_app (where, s_num (lineno)); s_cat (where, ")");
    sts = ssplit (";", l, 0);
    for (sx = 0; sx < sts->n; sx++) {
      struct str *st = s_trim (sts->v[sx]), *op, *rest;
      struct vec *o;
      struct nd *into;
      struct made *mm;
      long i;
      if (st->n == 0) continue;
      if (m (st, "^\\.(data|bss|section\\s+([^,\\s]+)(,.*)?)$")) {
        struct str *sec;
        if (gdef (2)) sec = g (2); else { sec = S ("."); s_app (sec, g (1)); }
        if (s_is (sec, ".text")) { other = 0; continue; }
        other = sec;
        pending = v_new ();
        dobj = 0;
        if (m (sec, "^\\.(pre)?init_array$|^\\.fini_array$")) { struct str *x = S ("s2ff: "); s_app (x, where); s_cat (x, ": "); s_app (x, sec); s_cat (x, " left out\n"); o_flush (); e_s (x); }
        continue;
      }
      if (s_is (st, ".text")) { other = 0; continue; }
      if (other) {
        if (m (st, "^\\.(globl|global|weak|type|size|hidden|align|p2align|balign|ident|file)\\b")) continue;
        if (m (st, "^([.\\w]+):$")) { v_push (pending, g (1)); dobj = 0; continue; }
        if (m (st, "^([.\\w]+)\\s*=\\s*([.\\w]+)$")) { struct str *a = g (1), *b = g (2); if (h_iv (datadef, b)) v_push (fns, alias_of (a, b)); continue; }
        if (m (other, "^\\.(pre)?init_array$|^\\.fini_array$") && m (st, "^\\.dc\\.a\\s+[.\\w]+$")) continue;
        if (m (other, "^\\.s?rodata")) {
          if (m (st, "^\\.set\\s+([.\\w]+)\\s*,\\s*([.\\w]+)(?:\\s*\\+\\s*(\\d+))?$")) { struct str *a = g (1), *b = g (2), *c = g (3); dset_push (a, b, c ? num (c) : 0); continue; }
          if (m (st, "^\\.(byte|half|2byte|word|4byte|dword|8byte|zero)\\s+(-?\\w+)$")) {
            struct str *k = g (1), *v = g (2);
            long nb;
            if (pending->n) {
              dobj = alloc (sizeof (struct dobj));
              dobj->name = v_shift (pending); dobj->sec = other;
              v_push (dobjs, dobj);
              for (i = 0; i < pending->n; i++) dset_push (pending->v[i], dobj->name, 0);
              pending = v_new ();
            }
            if (!dobj) fail2 ("data without a label: ", st);
            nb = s_is (k, "byte") ? 1 : s_is (k, "half") || s_is (k, "2byte") ? 2 : s_is (k, "word") || s_is (k, "4byte") ? 4 : 8;
            if (s_is (k, "zero")) { long z = num (v); for (i = 0; i < z; i++) dob_add (dobj, 0); }
            else { long x = num (v); for (i = 0; i < nb; i++) dob_add (dobj, (x >> (8 * i)) & 255); }
            continue;
          }
        }
        if (m (st, "^\\.(zero|space)\\s+(\\d+)$") && pending->n) {
          struct str *first = pending->v[0], *x;
          for (i = 0; i < pending->n; i++) h_set (datadef, pending->v[i], 1);
          for (i = 1; i < pending->n; i++) v_push (fns, alias_of (pending->v[i], first));
          x = S ("s2ff: "); s_app (x, where); s_cat (x, ": "); s_app (x, first); s_cat (x, " is zero, c2ff --zero "); s_app (x, first); s_cat (x, " makes it\n");
          o_flush (); e_s (x);
          pending = v_new ();
          continue;
        }
        { struct str *x = S ("bytes in "); s_app (x, other); s_cat (x, ": "); s_app (x, st); fail_s (x); }
      }
      while (m (st, "^([.\\w]+):\\s*")) {
        struct str *name = g (1);
        st = s_sub (st, rc[1], st->n);
        if (m (name, "^\\d+$")) {
          long c = h_iv (numeric, name) + 1;
          struct str *x = S (".L");
          h_set (numeric, name, c);
          s_app (x, name); s_cat (x, " "); s_app (x, s_num (c));
          name = x;
        }
        if (m (name, "^\\.L")) {
          struct str *x;
          if (!fn) { x = S ("label "); s_app (x, name); s_cat (x, " outside a function"); fail_s (x); }
          x = s_dup (name); s_cat (x, ":");
          block = nd_new (x);
          nd_add (fn, block);
        } else if (fn && !ends) {
          block = fn_head (name, file, lineno);
          nd_add (fn, block);
        } else {
          finish ();
          fn = fn_head (name, file, lineno);
          v_push (fns, fn);
          block = 0;
          ends = 0;
        }
      }
      if (st->n == 0) continue;
      if (m (st, "^([.\\w]+)\\s*=\\s*([.\\w]+)$") || m (st, "^\\.set\\s+([.\\w]+)\\s*,\\s*([.\\w]+)$")) { struct str *a = g (1), *b = g (2); v_push (fns, alias_of (a, b)); continue; }
      m (st, "^(\\S+)\\s*(.*)$");
      op = g (1); rest = g (2);
      if (op->p[0] == '.') {
        if (m (op, "^\\.(p2)?align$") && fn) {
          long a = 1, e = num (O (split_ops (rest), 0));
          while (e-- > 0) a = a * 2;
          while (pos % a && n_at < nmade && m (made[n_at]->op, "^(c\\.addi|c\\.nop|addi)$") && m (made[n_at]->args, "^zero,(zero,)?0$")) {
            mm = take ();
            nd_add (into_of (), mm->bytes == 2 ? ndc ("c.nop") : ins3 (S ("addi"), LN (0), LC ("zero"), LC ("zero")));
            ends = 0;
          }
          continue;
        }
        if (m (op, "^\\.(globl|global|weak|hidden|type|size|align|p2align|text|attribute|cfi_\\w+|file|ident)$")) continue;
        if (op_is (op, ".option") && m (rest, "^(push|pop|arch\\b.*|norelax|relax|pic|nopic|rvc|norvc)$")) continue;
        fail2 ("a directive with no ff form: ", st);
      }
      if (!fn) fail2 ("an instruction outside a function: ", st);
      if (op_is (op, "scall")) op = S ("ecall");
      else if (op_is (op, "sbreak")) op = S ("ebreak");
      else if (op_is (op, "fmv.s.x")) op = S ("fmv.w.x");
      else if (op_is (op, "fmv.x.s")) op = S ("fmv.x.w");
      o = split_ops (rest);
      for (i = 0; i < o->n; i++) {
        struct str *x = o->v[i];
        if (m (x, "^(\\d+)([fb])$")) {
          struct str *d = g (1), *y = S (".L");
          int f = g (2)->p[0] == 'f';
          s_app (y, d); s_cat (y, " "); s_app (y, s_num (h_iv (numeric, d) + (f ? 1 : 0)));
          o->v[i] = y;
        } else o->v[i] = ssub (x, "@plt$", "", "");
      }
      into = into_of ();
      if (op_is (op, "li")) {
        long v = num (O (o, 1)), count = v >= -2048 && v < 2048 ? 1 : (v & 0xfff) == 0 ? 1 : 2;
        if (!(v >= -2147483648L && v < 2147483648L)) { struct str *x = S ("li of "); s_app (x, s_num (v)); s_cat (x, ", wider than 32 bits"); fail_s (x); }
        if (count == 1 && n_at < nmade && m (made[n_at]->op, "^(addi|c\\.li)$")) {
          mm = take ();
          nd_add (into, mm->bytes == 2 ? short_ (mm, 0) : full (op, o));
        } else for (i = 0; i < count; i++) nd_add (into, canon (take ()));
        continue;
      }
      if (op_is (op, "la.tls.ie")) {
        struct str *w = S (".Ltls ");
        take (); take ();
        s_app (w, O (o, 1));
        h_set (tls, O (o, 1), 1);
        nd_add (into, ins2 (S ("auipc"), nd1 (S ("pcrel_hi"), nd_new (w)), LO (O (o, 0))));
        nd_add (into, ins3 (S ("ld"), nd1 (S ("pcrel_lo"), nd_new (w)), LO (O (o, 0)), LO (O (o, 0))));
        continue;
      }
      if (op_is (op, "la") && n_at + 1 < nmade && s_is (made[n_at]->op, "auipc") && s_is (made[n_at + 1]->op, "ld")) {
        struct str *w = S (".Lgot ");
        take (); take ();
        s_app (w, O (o, 1));
        h_set (got, O (o, 1), 1);
        nd_add (into, ins2 (S ("auipc"), nd1 (S ("pcrel_hi"), nd_new (w)), LO (O (o, 0))));
        nd_add (into, ins3 (S ("ld"), nd1 (S ("pcrel_lo"), nd_new (w)), LO (O (o, 0)), LO (O (o, 0))));
        continue;
      }
      if (op_is (op, "la") || op_is (op, "lla")) { take (); take (); nd_add (into, ins2 (S ("la"), LO (dname (O (o, 1))), LO (O (o, 0)))); continue; }
      if (h_has (loadk, op) && o->n >= 2 && !m (O (o, 1), "\\(") && !isnum (O (o, 1))) {
        struct str *w = dname (O (o, 1)), *rt = o->n > 2 ? O (o, 2) : O (o, 0);
        take (); take ();
        nd_add (into, ins2 (S ("auipc"), nd1 (S ("pcrel_hi"), nd_new (w)), LO (rt)));
        nd_add (into, ins3 (op, nd1 (S ("pcrel_lo"), nd_new (w)), LO (rt), LO (O (o, 0))));
        continue;
      }
      mm = take ();
      if (m (op, "^(call|tail)$")) { take (); nd_add (into, nd1 (op, nd_new (O (o, -1)))); continue; }
      if (mm->bytes == 2) {
        struct str *tgt = 0;
        for (i = 0; i < o->n && !tgt; i++) if (m (o->v[i], "^\\.L")) tgt = o->v[i];
        if (!tgt && m (mm->op, "^c\\.(j|beqz|bnez)$") && o->n) tgt = O (o, -1);
        nd_add (into, short_ (mm, tgt));
      } else {
        cur_enc = mm->enc;
        nd_add (into, full (op, o));
      }
    }
  }
  perrno = 0;   /* (the end of the .s read) */
  finish ();
  /* gcc's read-only data: an asm function of its words, a .set name a copy of the part it names */
  {
    struct hash *by = h_new ();
    long i, j;
    for (i = 0; i < dobjs->n; i++) h_setp (by, ((struct dobj *) dobjs->v[i])->name, dobjs->v[i]);
    for (i = 0; i < dset->n; i++) {
      struct dset_e *e = dset->v[i];
      struct dobj *o = h_pv (by, e->y), *x;
      if (!o) { struct str *msg = S ("a .set of "); s_app (msg, e->y); s_cat (msg, ", which is no data"); fail_s (msg); }
      if (e->k > o->nb) { struct str *msg = S (".set "); s_app (msg, e->x); s_cat (msg, ": past "); s_app (msg, e->y); fail_s (msg); }
      x = alloc (sizeof (struct dobj));
      x->name = e->x; x->sec = o->sec;
      for (j = e->k; j < o->nb; j++) dob_add (x, o->b[j]);
      v_push (dobjs, x);
      h_setp (by, e->x, x);
    }
    for (i = 0; i < dobjs->n; i++) {
      struct dobj *o = dobjs->v[i];
      struct str *nm = s_dup (dname (o->name)), *cm = S ("gcc's ");
      struct nd *f;
      long b = 0;
      s_cat (nm, ":");
      s_app (cm, o->sec);
      f = nd2 (nm, ndc ("asm"), nd1 (S ("comment"), nd_new (cm)));
      while (o->nb - b >= 4) { nd_add (f, nd1 (S ("word"), LN ((long) o->b[b] | (long) o->b[b + 1] << 8 | (long) o->b[b + 2] << 16 | (long) o->b[b + 3] << 24))); b += 4; }
      while (b < o->nb) { nd_add (f, nd1 (S ("byte"), LN (o->b[b]))); b++; }
      v_push (fns, f);
    }
  }
  /* what is left is the padding GNU as puts at the end of the section */
  while (nmade > n_at && m (made[nmade - 1]->op, "^c\\.(addi|nop)$|^addi$") && m (made[nmade - 1]->args, "^zero,(zero,)?0$")) nmade--;
  if (n_at != nmade) { struct str *x = S ("GNU as made "); s_app (x, s_num (nmade)); s_cat (x, " instructions, "); s_app (x, src_s); s_cat (x, " has "); s_app (x, s_num (n_at)); fail_s (x); }
  {
    long b = 0, i;
    for (i = 0; i < nmade; i++) b += made[i]->bytes;
    if (o_size) { o_s (s_num (b)); o_str ("\n"); o_flush (); cp_exit (0); }
    { struct str *x = S ("size "); s_app (x, s_num (b)); s_cat (x, "\n"); facts_write (x); }
  }
  /* a function that jumps to a block label of another: the functions from the one to the other one asm function */
  {
    long i, j;
    for (i = 0; i < fns->n; i++) {
      struct nd *f = fns->v[i], *into;
      struct hash *own, *t;
      struct vec *tv, *kept;
      long lo = -1, hi = -1, from, to;
      if (!isasm (f)) continue;
      own = labels_of (f);
      tv = v_new (); targets_of (f, tv);
      t = h_new ();
      for (j = 0; j < tv->n; j++) if (!h_has (own, tv->v[j])) h_set (t, tv->v[j], 1);
      if (!t->n) continue;
      for (j = 0; j < i && lo < 0; j++) if (isasm (fns->v[j]) && any_label_in (fns->v[j], t)) lo = j;
      for (j = fns->n - 1; j > i && hi < 0; j--) if (isasm (fns->v[j]) && any_label_in (fns->v[j], t)) hi = j;
      from = lo >= 0 ? lo : i;
      to = hi >= 0 ? hi : i;
      if (from == to) continue;
      into = fns->v[from];
      kept = v_new ();
      for (j = from + 1; j <= to; j++) {
        struct nd *gg = fns->v[j], *own_n;
        long q;
        int later = 0;
        if (!isasm (gg)) { v_push (kept, gg); continue; }
        own_n = nd_add (nd_new (gg->c), ndc ("asm"));
        {
          struct vec *lat = v_new ();
          for (q = 1; q < ndn (gg); q++) {
            struct nd *x = ndk (gg, q);
            if (later || (is_labelnode (x) && q != 1)) { later = 1; v_push (lat, x); } else nd_add (own_n, x);
          }
          nd_add (into, own_n);
          for (q = 0; q < lat->n; q++) nd_add (into, lat->v[q]);
        }
      }
      {
        struct vec *nf = v_new ();
        for (j = 0; j <= from; j++) v_push (nf, fns->v[j]);
        for (j = 0; j < kept->n; j++) v_push (nf, kept->v[j]);
        for (j = to + 1; j < fns->n; j++) v_push (nf, fns->v[j]);
        fns = nf;
      }
      i = from - 1;
    }
    aliases = h_new ();
    for (i = 0; i < fns->n; i++) {
      struct nd *f = fns->v[i];
      if (ndn (f) == 2 && s_is (ndk (f, 0)->c, "alias")) h_setp (aliases, unlabel (f->c), ndk (f, 1)->c);
    }
    for (i = 0; i < fns->n; i++) if (isasm (fns->v[i])) alias_walk (fns->v[i], labels_of (fns->v[i]));
  }
}

#include "a64.c"
#include "arm.c"
#include "x86.c"

static int is_opt (char *a, char *o) { long n = slen (o); return slen (a) == n && msame ((unsigned char *) a, (unsigned char *) o, n); }
static void init_tables (void)
{
  char *abi = "zero ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6";
  long i = 0, k = 0;
  while (k < 32) {
    long a = i;
    char *w;
    while (abi[i] && abi[i] != ' ') i++;
    w = alloc (i - a + 1);
    mcopy ((unsigned char *) w, (unsigned char *) abi + a, i - a);
    abi_names[k++] = w;
    if (abi[i]) i++;
  }
  csr = h_new ();
  h_set (csr, S ("vstart"), 0x008); h_set (csr, S ("vxsat"), 0x009); h_set (csr, S ("vxrm"), 0x00a); h_set (csr, S ("vcsr"), 0x00f);
  h_set (csr, S ("vl"), 0xc20); h_set (csr, S ("vtype"), 0xc21); h_set (csr, S ("vlenb"), 0xc22);
  sew = h_new (); h_set (sew, S ("e8"), 0); h_set (sew, S ("e16"), 1); h_set (sew, S ("e32"), 2); h_set (sew, S ("e64"), 3);
  lmul = h_new (); h_set (lmul, S ("m1"), 0); h_set (lmul, S ("m2"), 1); h_set (lmul, S ("m4"), 2); h_set (lmul, S ("m8"), 3);
  h_set (lmul, S ("mf8"), 5); h_set (lmul, S ("mf4"), 6); h_set (lmul, S ("mf2"), 7);
  rtype = h_words ("add sub and or xor sll srl sra slt sltu addw subw sllw srlw sraw mul mulh mulhu mulhsu div divu rem remu mulw divw divuw remw remuw");
  itype = h_words ("addi andi ori xori slti sltiu slli srli srai addiw slliw srliw sraiw");
  loadk = h_words ("lb lh lw ld lbu lhu lwu flw fld");
  storek = h_words ("sb sh sw sd fsw fsd");
  btype = h_words ("beq bne blt bge bltu bgeu");
  macro = h_words ("mv li neg seqz j jr ret beqz bnez bltz bgez blez bgtz bgt ble bgtu bleu csrr");
  vmask = h_words ("vmseq vmsne vmsltu vmsleu vmsgtu vadd vsub vand vor vxor vrgather vredmaxu vredminu vredsum vredor");
  tls = h_new (); got = h_new (); numeric = h_new (); dlabel = h_new (); datadef = h_new (); zeroed = h_new (); inverses = h_new ();
  fns = v_new (); dobjs = v_new (); dset = v_new ();
}

int s2ff_main (int argc, char **argv)
{
  long i = 1;
  struct str *dt;
  envp_of = argv + argc + 1;
  header_init ();
  init_tables ();
  page = S ("glibc asm");
  files = v_new (); zero_v = v_new (); then_v = v_new ();
  tgt_name = "riscv64";
  /* (s2ff's own, first: --target T, whose Perl it is: s2ff.pl, s2ff-aarch64.pl, s2ff-arm.pl; --shared FILE, the shared page) */
  for (;;) {
    if (i + 1 < argc && is_opt (argv[i], "--target")) { tgt_name = argv[i + 1]; i += 2; continue; }
    if (i + 1 < argc && is_opt (argv[i], "--shared")) { shared_f = s_of (argv[i + 1]); i += 2; continue; }
    if (i + 1 < argc && is_opt (argv[i], "--tables")) { tables_f = s_of (argv[i + 1]); i += 2; continue; }
    if (i + 1 < argc && is_opt (argv[i], "--gnu")) { gnu_f = s_of (argv[i + 1]); i += 2; continue; }
    break;
  }
  if (is_opt (tgt_name, "aarch64")) {
    while (i < argc) {
      char *a = argv[i++];
      if (is_opt (a, "--page")) { page = i < argc ? s_of (argv[i++]) : s_of (""); continue; }
      if (is_opt (a, "--size")) { o_size = 1; continue; }
      if (is_opt (a, "--items")) { o_items = 1; continue; }
      if (is_opt (a, "--locals")) { o_locals = 1; continue; }
      if (is_opt (a, "--skip")) { o_skip = 1; continue; }
      if (is_opt (a, "--facts")) { facts_f = i < argc ? s_of (argv[i++]) : 0; continue; }
      if (is_opt (a, "--then")) { long k; then_v = v_new (); for (k = 0; k < 2 && i < argc; k++) v_push (then_v, s_of (argv[i++])); continue; }
      if (is_opt (a, "--zero")) { h_set (zeroed, i < argc ? s_of (argv[i++]) : s_of (""), 1); continue; }
      v_push (files, s_of (a));
    }
    a64_main (files);
    return 0;
  }
  if (is_opt (tgt_name, "arm")) {
    aplt = h_new ();
    while (i < argc) {
      char *a = argv[i++];
      if (is_opt (a, "--page")) { page = i < argc ? s_of (argv[i++]) : s_of (""); continue; }
      if (is_opt (a, "--then")) { long k; then_v = v_new (); for (k = 0; k < 2 && i < argc; k++) v_push (then_v, s_of (argv[i++])); continue; }
      if (is_opt (a, "--zero")) { h_set (zeroed, i < argc ? s_of (argv[i++]) : s_of (""), 1); continue; }
      if (is_opt (a, "--plt")) { h_set (aplt, i < argc ? s_of (argv[i++]) : s_of (""), 1); continue; }
      if (is_opt (a, "--size")) { o_size = 1; continue; }
      if (is_opt (a, "--facts")) { facts_f = i < argc ? s_of (argv[i++]) : 0; continue; }
      if (is_opt (a, "--items")) { o_items = 1; continue; }
      v_push (files, s_of (a));
    }
    arm_main (files);
    return 0;
  }
  if (!is_opt (tgt_name, "riscv64") && !is_opt (tgt_name, "x86_64")) { e_str ("s2ff: --target riscv64, x86_64, aarch64 or arm\n"); cp_exit (2); }
  while (i < argc) {
    char *a = argv[i++];
    if (is_opt (a, "--page")) { page = i < argc ? s_of (argv[i++]) : s_of (""); continue; }
    if (is_opt (a, "--size")) { o_size = 1; continue; }
    if (is_opt (a, "--items")) { o_items = 1; continue; }
    if (is_opt (a, "--header")) { o_header = 1; continue; }
    if (is_opt (a, "--align")) { o_align = 1; continue; }
    if (is_opt (a, "--facts")) { facts_f = i < argc ? s_of (argv[i++]) : 0; continue; }
    if (is_opt (a, "--zero")) { if (i < argc) v_push (zero_v, s_of (argv[i++])); continue; }
    if (is_opt (a, "--then")) { long k; then_v = v_new (); for (k = 0; k < 2 && i < argc; k++) v_push (then_v, s_of (argv[i++])); continue; }
    v_push (files, s_of (a));
  }
  if (o_header) { o_s (write_txt (license_nodes (files))); o_flush (); return 0; }
  if (files->n != 2) { e_str ("usage: s2ff.pl [--page name | --items | --size] file.s file.dump\n"); o_flush (); cp_exit (255); }
  src_s = files->v[0]; dump_s = files->v[1];
  where = src_s;
  dt = p_slurp ((char *) dump_s->p, "s2ff");
  if (m (dt, "file format elf64-x86-64")) { x86_init (); x86_main (); return 0; }
  rv_main ();
  {
    struct vec *out = fns;
    if (!o_items) {
      struct str *pg = s_dup (page);
      struct nd *top;
      struct vec *one = v_new (), *lic;
      s_cat (pg, ":");
      top = nd_new (pg);
      v_push (one, src_s);
      lic = license_nodes (one);
      for (i = 0; i < lic->n; i++) nd_add (top, lic->v[i]);
      for (i = 0; i < fns->n; i++) nd_add (top, fns->v[i]);
      out = v_new (); v_push (out, top);
    }
    o_s (write_txt (out));
  }
  o_flush ();
  return 0;
}
