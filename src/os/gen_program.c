/*
 * ttp — the trust project: a self-hosting OS and compiler.
 * Copyright (C) 2026  Nico Verrijdt
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

/*
 * gen_program.c — bootstrap authoring of a node program.
 *
 * The "new asm" is a tree of nodes: an instruction is a node whose content is
 * the mnemonic, with one child per operand (a register/immediate leaf, or a
 * "mem" node). Until a node editor exists, this host tool builds a
 * representative program with the node-builder API in <node.h> and serializes
 * it to `program.nodes`, which `ttpc -a` then assembles to machine code.
 *
 * The selection below exercises every encoder family so the output can be
 * byte-checked against nasm / the OS image. Branch operands are *relative*
 * displacements (the assembler emits addressless hex).
 */

#include <stdarg.h>
#include <node.h>

static struct node *prog;

/* Append an instruction `mnem` with leaf operands (NULL-terminated). */
static struct node *I(const char *mnem, ...)
{
	struct node *n = node_new(mnem);
	node_add(prog, n);
	va_list ap;
	va_start(ap, mnem);
	const char *o;
	while ((o = va_arg(ap, const char *)) != NULL)
		node_kid(n, o);
	va_end(ap);
	return n;
}

/* A memory operand node: size seg base index scale disp ("-" = absent). */
static struct node *MEM(const char *size, const char *seg, const char *base,
			const char *index, const char *scale, const char *disp)
{
	struct node *n = node_new("mem");
	node_kid(n, size); node_kid(n, seg);   node_kid(n, base);
	node_kid(n, index); node_kid(n, scale); node_kid(n, disp);
	return n;
}

/* Append an instruction with a leading register/immediate then a mem operand. */
static void Im(const char *mnem, const char *op0, struct node *mem)
{
	struct node *n = node_new(mnem);
	node_add(prog, n);
	if (op0) node_kid(n, op0);
	node_add(n, mem);
}

/* Append an instruction whose first operand is memory, then a leaf operand. */
static void Mi(const char *mnem, struct node *mem, const char *op1)
{
	struct node *n = node_new(mnem);
	node_add(prog, n);
	node_add(n, mem);
	if (op1) node_kid(n, op1);
}

static void bits(const char *n) { I("bits", n, NULL); }

int main(int argc, char **argv)
{
	const char *out = (argc > 1) ? argv[1] : "program.nodes";
	prog = node_new("program");

	/* ---- 16-bit real mode (boot.bin shapes) ------------------------- */
	bits("16");
	I("xor", "ax", "ax", NULL);              /* 31 c0                  */
	I("mov", "ds", "ax", NULL);              /* 8e d8                  */
	I("mov", "sp", "0x7c00", NULL);          /* bc 00 7c               */
	I("mov", "ah", "0x2", NULL);             /* b4 02                  */
	I("mov", "dl", "0x80", NULL);            /* b2 80                  */
	I("int", "0x13", NULL);                  /* cd 13                  */
	Im("lgdt", NULL, MEM("-","-","-","-","-","0xa5"));  /* 0f 01 16 a5 00 */

	/* ---- 32-bit protected mode (kernel32 shapes) -------------------- */
	bits("32");
	I("mov", "ax", "0x10", NULL);            /* 66 b8 10 00            */
	I("mov", "esp", "0x90000", NULL);        /* bc 00 00 09 00         */
	I("mov", "edi", "0x1000", NULL);         /* bf 00 10 00 00         */
	I("xor", "eax", "eax", NULL);            /* 31 c0                  */
	{ struct node *r = node_new("rep");      /* rep stosd -> f3 ab     */
	  node_add(prog, r); node_kid(r, "stosd"); }
	Mi("mov", MEM("dword","-","-","-","-","0x1000"), "0x2007"); /* c7 05 ... */
	I("or", "eax", "0x1", NULL);             /* 83 c8 01               */
	I("mov", "cr0", "eax", NULL);            /* 0f 22 c0               */
	I("mov", "eax", "cr0", NULL);            /* 0f 20 c0               */

	/* ---- 64-bit long mode (kernel shapes + broad coverage) ---------- */
	bits("64");
	I("xor", "rax", "rax", NULL);            /* 48 31 c0               */
	I("xor", "eax", "eax", NULL);            /* 31 c0                  */
	I("xor", "r8d", "r8d", NULL);            /* 45 31 c0               */
	I("mov", "rbp", "rsp", NULL);            /* 48 89 e5               */
	I("mov", "r8d", "esi", NULL);            /* 41 89 f0               */
	I("and", "rsp", "-16", NULL);            /* 48 83 e4 f0            */
	I("sub", "rsp", "0x38", NULL);           /* 48 83 ec 38            */
	I("add", "rcx", "0x1", NULL);            /* 48 83 c1 01            */
	I("mov", "esi", "0xe", NULL);            /* be 0e 00 00 00         */
	I("movabs", "rax", "0x11180", NULL);     /* 48 b8 80 11 01 ...     */
	I("movabs", "rdi", "0x116b8", NULL);     /* 48 bf b8 16 01 ...     */
	Im("movabs", "eax", MEM("-","-","-","-","-","0x12004")); /* a1 04 20 ... */
	I("call", "rax", NULL);                  /* ff d0                  */
	I("call", "rbx", NULL);                  /* ff d3                  */
	I("jmp", "rax", NULL);                   /* ff e0                  */
	I("push", "rbp", NULL);                  /* 55                     */
	I("push", "rbx", NULL);                  /* 53                     */
	I("push", "0x1b", NULL);                 /* 6a 1b                  */
	I("push", "0x202", NULL);                /* 68 02 02 00 00         */
	I("pop", "rbp", NULL);                   /* 5d                     */
	I("leave", NULL);                        /* c9                     */
	I("ret", NULL);                          /* c3                     */
	Im("lea", "rax", MEM("-","-","rcx","-","-","-0xa0"));  /* 48 8d 81 60 ff ff ff */
	Im("lea", "ecx", MEM("-","-","rsi","rsi","4","0"));    /* 8d 0c b6 */
	Mi("mov", MEM("word","-","rcx","-","-","0xb8000"), "dx"); /* 66 89 91 ... */
	Mi("mov", MEM("dword","-","rax","-","-","0"), "0x0");  /* c7 00 00 00 00 00 */
	I("shl", "edx", "0x4", NULL);            /* c1 e2 04               */
	I("shr", "rax", "0x23", NULL);           /* 48 c1 e8 23            */
	I("test", "edi", "edi", NULL);           /* 85 ff                  */
	I("cmp", "eax", "0x4f", NULL);           /* 83 f8 4f               */
	I("cmp", "dil", "0xa", NULL);            /* 40 80 ff 0a            */
	I("movsx", "di", "dil", NULL);           /* 66 40 0f be ff         */
	I("movsxd", "rcx", "ecx", NULL);         /* 48 63 c9               */
	I("imul", "rax", "rbx", NULL);           /* 48 0f af c3            */
	I("not", "eax", NULL);                   /* f7 d0                  */
	I("neg", "r9d", NULL);                   /* 41 f7 d9               */
	I("inc", "ebx", NULL);                   /* ff c3                  */
	I("bswap", "eax", NULL);                 /* 0f c8                  */
	I("bsf", "eax", "ebx", NULL);            /* 0f bc c3               */
	I("setne", "al", NULL);                  /* 0f 95 c0               */
	I("cmove", "eax", "ebx", NULL);          /* 0f 44 c3               */
	I("je", "0x3f", NULL);                   /* 74 3f                  */
	I("jmp", "-2", NULL);                    /* eb fe                  */
	I("mov", "cr3", "rax", NULL);            /* 0f 22 d8               */
	I("syscall", NULL);                      /* 0f 05                  */
	I("rdmsr", NULL);                        /* 0f 32                  */
	I("wrmsr", NULL);                        /* 0f 30                  */
	I("swapgs", NULL);                       /* 0f 01 f8               */
	I("iretq", NULL);                        /* 48 cf                  */
	I("hlt", NULL);                          /* f4                     */
	I("nop", NULL);                          /* 90                     */

	FILE *f = fopen(out, "wb");
	if (!f) { perror(out); return 1; }
	if (node_write(f, prog) != 0) { fprintf(stderr, "gen_program: write failed\n"); return 1; }
	fclose(f);
	fprintf(stderr, "gen_program: wrote %d node(s) to %s\n", prog->n_children, out);
	return 0;
}
