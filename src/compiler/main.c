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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <node.h>                /* the node tree that `-a` assembles (-Iinclude) */

/*
 * Bootstrap stage: the "compiler" reads the OS boot-flow disassembly and, for
 * every instruction line, places its machine-code bytes into a binary image at
 * the line's *disk offset* (the address column in boot_flow.txt — see
 * src/os/DISASSEMBLY.md, which dumps each region with objdump --adjust-vma set
 * to where the bytes live in the image, not their runtime load address). The
 * result is a faithful copy of the OS disk image that boots in QEMU.
 *
 * ttpc breaks each instruction into its component fields — legacy prefixes, the
 * REX byte, the opcode (with its 0F / 0F 38 / 0F 3A escapes), ModRM, SIB,
 * displacement and immediate — using hard-coded x86-64 opcode-attribute tables
 * (see ONEBYTE / TWOBYTE below). It then reassembles the bytes from those
 * fields and verifies they match the originals (PASS). Field lengths depend on
 * the CPU mode (16/32/64-bit), which is tracked from the region banners in the
 * file, plus the 66/67 size prefixes and REX.W. An instruction whose bytes the
 * decoder cannot fully account for on its line (an unknown encoding, or one
 * objdump wrapped past what was merged) is passed through verbatim — its raw
 * bytes go straight into the image — so the whole disk is always reproduced
 * even where decoding falls short.
 */
#define DEFAULT_INPUT  "src/os/boot_flow.txt"
#define DEFAULT_OUTPUT "build/compiler/ttpos.img"
#define DEFAULT_NODES  "src/os/ff/program.nodes"   /* -a: the node program */

/* Pad the output to a full disk so BIOS/QEMU can read every sector the boot
 * code loads (boot.bin pulls in 50 sectors). Matches the 2048-sector (1 MiB)
 * image src/os/Makefile builds with dd. */
#define IMG_SECTORS    2048

struct insn {
	unsigned long addr;             /* memory address (load VMA) from file  */

	unsigned char legacy[4];        /* legacy prefixes, in original order   */
	int           n_legacy;
	int           has_rex;          /* REX prefix (64-bit mode only)        */
	unsigned char rex;
	int           opmap;            /* 0=1-byte 1=0F 2=0F38 3=0F3A          */
	unsigned char opcode;           /* the opcode number — its own variable */
	int           has_modrm;
	unsigned char modrm;
	int           has_sib;
	unsigned char sib;
	int           disp_len;
	unsigned char disp[4];
	int           imm_len;
	unsigned char imm[8];

	unsigned char raw[16];          /* bytes as parsed, for the PASS check  */
	int           raw_len;
	char          mnem[16];
	char          ops[48];
};

/*
 * Per-opcode attribute: the high bit marks a ModRM byte, the low 3 bits select
 * the immediate's size class. The class is resolved against the operand/address
 * size at decode time (16/32/64-bit), so e.g. IZ is 2 bytes with a 16-bit
 * operand size and 4 otherwise.
 */
#define M  0x80   /* instruction has a ModRM byte                            */
#define IB 1      /* imm8                                                    */
#define IW 2      /* imm16                                                   */
#define ID 3      /* imm32 (fixed)                                           */
#define IZ 4      /* imm16/imm32 by operand size (never 64)                  */
#define IV 5      /* imm16/imm32/imm64 by operand size                       */
#define IA 6      /* moffs: 2/4/8 by address size                            */
#define IP 7      /* far pointer: operand-size offset (2/4) + 2-byte selector */

/* One-byte opcode map (rows of 16). Segment/size/REX/escape bytes are consumed
 * as prefixes before this lookup, so their slots here are inert. */
static const unsigned char ONEBYTE[256] = {
/* 0 */ M,M,M,M,IB,IZ,0,0,        M,M,M,M,IB,IZ,0,0,
/* 1 */ M,M,M,M,IB,IZ,0,0,        M,M,M,M,IB,IZ,0,0,
/* 2 */ M,M,M,M,IB,IZ,0,0,        M,M,M,M,IB,IZ,0,0,
/* 3 */ M,M,M,M,IB,IZ,0,0,        M,M,M,M,IB,IZ,0,0,
/* 4 */ 0,0,0,0,0,0,0,0,          0,0,0,0,0,0,0,0,
/* 5 */ 0,0,0,0,0,0,0,0,          0,0,0,0,0,0,0,0,
/* 6 */ 0,0,M,M,0,0,0,0,          IZ,M|IZ,IB,M|IB,0,0,0,0,
/* 7 */ IB,IB,IB,IB,IB,IB,IB,IB,  IB,IB,IB,IB,IB,IB,IB,IB,
/* 8 */ M|IB,M|IZ,M|IB,M|IB,M,M,M,M, M,M,M,M,M,M,M,M,
/* 9 */ 0,0,0,0,0,0,0,0,          0,0,IP,0,0,0,0,0,
/* A */ IA,IA,IA,IA,0,0,0,0,      IB,IZ,0,0,0,0,0,0,
/* B */ IB,IB,IB,IB,IB,IB,IB,IB,  IV,IV,IV,IV,IV,IV,IV,IV,
/* C */ M|IB,M|IB,IW,0,M,M,M|IB,M|IZ, 0,0,IW,0,0,IB,0,0,
/* D */ M,M,M,M,IB,IB,0,0,        M,M,M,M,M,M,M,M,
/* E */ IB,IB,IB,IB,IB,IB,IB,IB,  IZ,IZ,IP,IB,0,0,0,0,
/* F */ 0,0,0,0,0,0,M,M,          0,0,0,0,0,0,M,M,
};

/* Two-byte (0F) opcode map. 0F 38 / 0F 3A escapes are handled before lookup. */
static const unsigned char TWOBYTE[256] = {
/* 0 */ M,M,M,M,0,0,0,0,          0,0,0,0,0,M,0,M|IB,
/* 1 */ M,M,M,M,M,M,M,M,          M,M,M,M,M,M,M,M,
/* 2 */ M,M,M,M,0,0,0,0,          M,M,M,M,M,M,M,M,
/* 3 */ 0,0,0,0,0,0,0,0,          0,0,0,0,0,0,0,0,
/* 4 */ M,M,M,M,M,M,M,M,          M,M,M,M,M,M,M,M,
/* 5 */ M,M,M,M,M,M,M,M,          M,M,M,M,M,M,M,M,
/* 6 */ M,M,M,M,M,M,M,M,          M,M,M,M,M,M,M,M,
/* 7 */ M|IB,M|IB,M|IB,M|IB,M,M,M,0, M,M,M,M,M,M,M,M,
/* 8 */ IZ,IZ,IZ,IZ,IZ,IZ,IZ,IZ,  IZ,IZ,IZ,IZ,IZ,IZ,IZ,IZ,
/* 9 */ M,M,M,M,M,M,M,M,          M,M,M,M,M,M,M,M,
/* A */ 0,0,0,M,M|IB,M,0,0,        0,0,0,M,M|IB,M,M,M,
/* B */ M,M,M,M,M,M,M,M,          M,M,M|IB,M,M,M,M,M,
/* C */ M,M,M|IB,M,M|IB,M|IB,M|IB,M, 0,0,0,0,0,0,0,0,
/* D */ M,M,M,M,M,M,M,M,          M,M,M,M,M,M,M,M,
/* E */ M,M,M,M,M,M,M,M,          M,M,M,M,M,M,M,M,
/* F */ M,M,M,M,M,M,M,M,          M,M,M,M,M,M,M,M,
};

/*
 * Parse one disassembly line into *out. Returns 1 if the line held an
 * instruction, 0 for headers / comments / labels / blanks.
 *
 * Instruction lines look like (leading whitespace, then):
 *   "7c00:\t31 c0                \txor    ax,ax"
 * i.e. <hexaddr> ':' TAB <space-separated hex bytes> TAB <mnem> <operands>.
 *
 * objdump wraps instructions longer than 7 bytes onto extra lines that carry an
 * address and bytes but no mnemonic; those parse as instructions here with an
 * empty mnem[], and the caller stitches them onto the preceding instruction.
 */
static int parse_line(const char *line, struct insn *out)
{
	const char *p = line;

	while (*p == ' ' || *p == '\t')
		p++;

	/* Skip comments, banners and the "00007c00 <.data>:" label lines. */
	if (*p == '#' || *p == '=' || *p == '[' || *p == '\n' || *p == '\0')
		return 0;

	/* Address: hex digits terminated by ':'. A space before ':' (as in
	 * "00007c00 <.data>:") means this is a label, not an instruction. */
	char *end;
	unsigned long addr = strtoul(p, &end, 16);
	if (end == p || *end != ':')
		return 0;
	p = end + 1;
	if (*p != '\t')
		return 0;
	p++;

	memset(out, 0, sizeof *out);
	out->addr = addr;

	/* Raw bytes: pairs of hex digits separated by spaces, up to the TAB. */
	while (*p != '\t' && *p != '\n' && *p != '\0') {
		if (*p == ' ') {
			p++;
			continue;
		}
		unsigned int byte;
		if (sscanf(p, "%2x", &byte) != 1)
			break;
		if (out->raw_len < (int)sizeof out->raw)
			out->raw[out->raw_len++] = (unsigned char)byte;
		p += 2;
	}
	if (out->raw_len == 0)
		return 0;

	/* Mnemonic and operands (best-effort; purely informational here). A
	 * continuation line has no text past the bytes, so mnem stays empty. */
	while (*p == '\t' || *p == ' ')
		p++;
	sscanf(p, "%15s %47[^\n]", out->mnem, out->ops);

	return 1;
}

/* Scan a region banner for its mode keyword and update *mode. Only banner lines
 * carry "16-bit" / "32-bit" / "64-bit", so this is a no-op on everything else. */
static void update_mode(const char *line, int *mode)
{
	if (strstr(line, "64-bit"))
		*mode = 64;
	else if (strstr(line, "32-bit"))
		*mode = 32;
	else if (strstr(line, "16-bit"))
		*mode = 16;
}

/*
 * Decode the raw bytes into fields for the given CPU mode (16/32/64). Walks the
 * bytes left-to-right — legacy prefixes, REX, opcode (+escapes), ModRM, SIB,
 * displacement, immediate — capturing each field's actual bytes. Returns 1 when
 * the fields account for exactly raw_len bytes, 0 otherwise (unknown encoding
 * or a wrapped line), in which case the caller passes the raw bytes through.
 */
static int decode(struct insn *in, int mode)
{
	const unsigned char *b = in->raw;
	int len = in->raw_len;
	int i = 0;
	int o66 = 0, a67 = 0;

	in->n_legacy = 0;
	in->has_rex = 0;
	in->rex = 0;
	in->opmap = 0;
	in->has_modrm = 0;
	in->has_sib = 0;
	in->disp_len = 0;
	in->imm_len = 0;

	/* Legacy prefixes (segment, operand/address size, lock/rep). */
	while (i < len) {
		unsigned char c = b[i];
		if (c == 0x66 || c == 0x67 || c == 0xF0 || c == 0xF2 || c == 0xF3 ||
		    c == 0x26 || c == 0x2E || c == 0x36 || c == 0x3E ||
		    c == 0x64 || c == 0x65) {
			if (in->n_legacy < (int)sizeof in->legacy)
				in->legacy[in->n_legacy++] = c;
			if (c == 0x66)
				o66 = 1;
			if (c == 0x67)
				a67 = 1;
			i++;
		} else {
			break;
		}
	}
	if (i >= len)
		return 0;

	/* REX prefix: a 0x40–0x4F byte, last before the opcode, in 64-bit mode. */
	if (mode == 64 && b[i] >= 0x40 && b[i] <= 0x4F) {
		in->has_rex = 1;
		in->rex = b[i];
		i++;
	}
	if (i >= len)
		return 0;

	/* Opcode, possibly behind a 0F / 0F 38 / 0F 3A escape. */
	unsigned char attr;
	if (b[i] == 0x0F) {
		i++;
		if (i >= len)
			return 0;
		if (b[i] == 0x38) {
			in->opmap = 2;
			i++;
			if (i >= len)
				return 0;
			in->opcode = b[i++];
			attr = M;               /* 0F 38: ModRM, no immediate */
		} else if (b[i] == 0x3A) {
			in->opmap = 3;
			i++;
			if (i >= len)
				return 0;
			in->opcode = b[i++];
			attr = M | IB;          /* 0F 3A: ModRM + imm8 */
		} else {
			in->opmap = 1;
			in->opcode = b[i++];
			attr = TWOBYTE[in->opcode];
		}
	} else {
		in->opmap = 0;
		in->opcode = b[i++];
		attr = ONEBYTE[in->opcode];
	}

	int cls = attr & 7;
	int has_modrm = attr & M;

	/* Resolve operand and address size from mode + prefixes + REX.W. */
	int osize = (mode == 16) ? 16 : 32;
	if (o66)
		osize = (osize == 16) ? 32 : 16;
	if (in->has_rex && (in->rex & 0x08))
		osize = 64;
	int asize = (mode == 16) ? 16 : (mode == 64 ? 64 : 32);
	if (a67)
		asize = (mode == 16) ? 32 : (mode == 64 ? 32 : 16);

	/* ModRM, SIB and displacement. */
	if (has_modrm) {
		if (i >= len)
			return 0;
		in->has_modrm = 1;
		in->modrm = b[i++];
		int mod = (in->modrm >> 6) & 3;
		int rm  = in->modrm & 7;

		if (mod != 3) {
			int base = -1;
			if (asize != 16 && rm == 4) {
				if (i >= len)
					return 0;
				in->has_sib = 1;
				in->sib = b[i++];
				base = in->sib & 7;
			}

			int dl = 0;
			if (asize == 16) {
				if (mod == 0 && rm == 6)
					dl = 2;
				else if (mod == 1)
					dl = 1;
				else if (mod == 2)
					dl = 2;
			} else {
				if (mod == 0 && rm == 5)
					dl = 4;                 /* disp32 / RIP-relative */
				else if (mod == 0 && rm == 4 && base == 5)
					dl = 4;
				else if (mod == 1)
					dl = 1;
				else if (mod == 2)
					dl = 4;
			}
			for (int k = 0; k < dl; k++) {
				if (i >= len)
					return 0;
				in->disp[k] = b[i++];
			}
			in->disp_len = dl;
		}

		/* F6/F7 carry an immediate only for their TEST forms (/0, /1). */
		if (in->opmap == 0 && (in->opcode == 0xF6 || in->opcode == 0xF7)) {
			int reg = (in->modrm >> 3) & 7;
			if (reg <= 1)
				cls = (in->opcode == 0xF6) ? IB : IZ;
			else
				cls = 0;
		}
	}

	/* Immediate. */
	int il = 0;
	if (in->opmap == 0 && in->opcode == 0xC8) {
		il = 3;                                 /* ENTER iw, ib */
	} else {
		switch (cls) {
		case IB: il = 1; break;
		case IW: il = 2; break;
		case ID: il = 4; break;
		case IZ: il = (osize == 16) ? 2 : 4; break;
		case IV: il = (osize == 16) ? 2 : (osize == 64 ? 8 : 4); break;
		case IA: il = (asize == 16) ? 2 : (asize == 64 ? 8 : 4); break;
		case IP: il = (osize == 16 ? 2 : 4) + 2; break;
		default: il = 0; break;
		}
	}
	for (int k = 0; k < il; k++) {
		if (i >= len)
			return 0;
		in->imm[k] = b[i++];
	}
	in->imm_len = il;

	/* The fields must account for exactly the bytes on the line. */
	if (i != len)
		return 0;
	return 1;
}

/* Reassemble fields back into bytes, in canonical x86 order. */
static int assemble(const struct insn *in, unsigned char *buf)
{
	int n = 0;
	for (int i = 0; i < in->n_legacy; i++)
		buf[n++] = in->legacy[i];
	if (in->has_rex)
		buf[n++] = in->rex;
	if (in->opmap >= 1)
		buf[n++] = 0x0F;
	if (in->opmap == 2)
		buf[n++] = 0x38;
	else if (in->opmap == 3)
		buf[n++] = 0x3A;
	buf[n++] = in->opcode;
	if (in->has_modrm)
		buf[n++] = in->modrm;
	if (in->has_sib)
		buf[n++] = in->sib;
	for (int i = 0; i < in->disp_len; i++)
		buf[n++] = in->disp[i];
	for (int i = 0; i < in->imm_len; i++)
		buf[n++] = in->imm[i];
	return n;
}

static void print_byte(const char *label, int present, unsigned char val)
{
	if (present)
		printf("%s=0x%02x  ", label, val);
	else
		printf("%s=--  ", label);
}

/*
 * Decode one (possibly line-wrap-merged) instruction, emit its bytes at the
 * instruction's disk offset, and bump the counters. Emits the reassembled-from-
 * fields bytes when ttpc decodes the instruction and they match, otherwise the
 * raw bytes verbatim — either way the image byte is correct. Returns -1 on a
 * write error, 0 otherwise.
 */
static int emit_insn(struct insn *ins, int mode, FILE *out, int verbose,
		     int *count, int *decoded, int *passthru, int *fails)
{
	unsigned char        asm_buf[16];
	const unsigned char *emit     = ins->raw;
	int                  emit_len  = ins->raw_len;

	if (decode(ins, mode)) {
		int asm_len = assemble(ins, asm_buf);
		int pass = (asm_len == ins->raw_len &&
			memcmp(asm_buf, ins->raw, asm_len) == 0);

		if (pass) {
			emit     = asm_buf;
			emit_len = asm_len;
			(*decoded)++;
		} else {
			/* Decoder and raw bytes disagree: keep the image
			 * faithful (emit raw) but flag the bug. */
			(*fails)++;
		}

		if (verbose) {
			printf("addr=0x%lx  mode=%d  mnem=%s ops=%s\n",
				ins->addr, mode, ins->mnem, ins->ops);
			printf("  legacy=");
			if (ins->n_legacy == 0)
				printf("--  ");
			else
				for (int i = 0; i < ins->n_legacy; i++)
					printf("%02x ", ins->legacy[i]);
			print_byte("rex", ins->has_rex, ins->rex);
			printf("opmap=%d  opcode=0x%02x\n", ins->opmap, ins->opcode);
			printf("  ");
			print_byte("modrm", ins->has_modrm, ins->modrm);
			print_byte("sib", ins->has_sib, ins->sib);
			printf("disp=%dB  imm=%dB\n", ins->disp_len, ins->imm_len);
			printf("  reassembled:");
			for (int i = 0; i < asm_len; i++)
				printf(" %02x", asm_buf[i]);
			printf("   original:");
			for (int i = 0; i < ins->raw_len; i++)
				printf(" %02x", ins->raw[i]);
			printf("   %s\n\n", pass ? "PASS" : "FAIL");
		}
	} else {
		/* Not an encoding ttpc can fully account for on this line —
		 * pass the raw bytes through unchanged. */
		(*passthru)++;
	}

	if (fseek(out, (long)ins->addr, SEEK_SET) != 0 ||
	    fwrite(emit, 1, emit_len, out) != (size_t)emit_len) {
		fprintf(stderr, "ttpc: write error at 0x%lx\n", ins->addr);
		return -1;
	}
	(*count)++;
	return 0;
}

/* ===========================================================================
 * Assembler (`-a`): node tree -> machine code.
 *
 * The inverse of decode(): an instruction node carries the mnemonic in its
 * content and its operands as children. Operands are leaf nodes (a register
 * name like "rax", or an immediate literal like "0x7c00"), or a "mem" node with
 * six children — size seg base index scale disp ("-" = absent). A "bits" node
 * (one child 16/32/64) switches the assembler mode for what follows.
 *
 * Each handler fills a struct insn's fields and reuses assemble() to lay the
 * bytes out, so the encoder and decoder share one notion of instruction shape —
 * feeding -a's output back through decode() round-trips.
 * =========================================================================== */

enum { RC_GPR, RC_SEG, RC_CR, RC_DR, RC_RIP };
enum { OP_NONE, OP_REG, OP_IMM, OP_MEM };

struct operand {
	int       kind;     /* OP_*                                            */
	int       size;     /* operand size in bits (8/16/32/64), 0 = unknown  */
	int       rc;       /* RC_* (register class)                           */
	int       regnum;   /* 0..15                                           */
	int       r8rex;    /* spl/bpl/sil/dil — forces a REX prefix           */
	int       r8high;   /* ah/ch/dh/bh — forbids a REX prefix              */
	long long imm;
	int       base;     /* memory: base reg or -1                          */
	int       index;    /* memory: index reg or -1                         */
	int       scale;    /* memory: 1/2/4/8                                 */
	int       addrsize; /* memory: 16/32/64 from base/index regs           */
	int       rip;      /* memory: RIP-relative                            */
	long      disp;
	int       seg;      /* memory: seg reg 0..5, or -1                      */
};

/* Encoder context: prefix/REX state accumulated while building one insn. */
struct enc {
	struct insn *in;
	int mode;
	int rexW, rexR, rexX, rexB;
	int p66, p67;
	int seg;            /* segment-override reg (fs/gs) or -1              */
	int need_rex8;      /* an operand is spl/bpl/sil/dil                   */
	int bad_rex8;       /* an operand is ah/ch/dh/bh                       */
};

static const char *GPR64[16] = {"rax","rcx","rdx","rbx","rsp","rbp","rsi","rdi",
	"r8","r9","r10","r11","r12","r13","r14","r15"};
static const char *GPR32[16] = {"eax","ecx","edx","ebx","esp","ebp","esi","edi",
	"r8d","r9d","r10d","r11d","r12d","r13d","r14d","r15d"};
static const char *GPR16[16] = {"ax","cx","dx","bx","sp","bp","si","di",
	"r8w","r9w","r10w","r11w","r12w","r13w","r14w","r15w"};
static const char *GPR8[16]  = {"al","cl","dl","bl","spl","bpl","sil","dil",
	"r8b","r9b","r10b","r11b","r12b","r13b","r14b","r15b"};
static const char *GPR8H[4]  = {"ah","ch","dh","bh"};
static const char *SEG[6]    = {"es","cs","ss","ds","fs","gs"};

static int size_kw(const char *s)
{
	if (!strcmp(s, "byte"))  return 8;
	if (!strcmp(s, "word"))  return 16;
	if (!strcmp(s, "dword")) return 32;
	if (!strcmp(s, "qword")) return 64;
	return 0;
}

static int parse_reg(const char *s, struct operand *op)
{
	for (int i = 0; i < 16; i++) {
		if (!strcmp(s, GPR64[i])) { op->kind=OP_REG; op->rc=RC_GPR; op->size=64; op->regnum=i; return 1; }
		if (!strcmp(s, GPR32[i])) { op->kind=OP_REG; op->rc=RC_GPR; op->size=32; op->regnum=i; return 1; }
		if (!strcmp(s, GPR16[i])) { op->kind=OP_REG; op->rc=RC_GPR; op->size=16; op->regnum=i; return 1; }
		if (!strcmp(s, GPR8[i]))  { op->kind=OP_REG; op->rc=RC_GPR; op->size=8;  op->regnum=i; op->r8rex=(i>=4&&i<=7); return 1; }
	}
	for (int i = 0; i < 4; i++)
		if (!strcmp(s, GPR8H[i])) { op->kind=OP_REG; op->rc=RC_GPR; op->size=8; op->regnum=4+i; op->r8high=1; return 1; }
	for (int i = 0; i < 6; i++)
		if (!strcmp(s, SEG[i]))   { op->kind=OP_REG; op->rc=RC_SEG; op->size=16; op->regnum=i; return 1; }
	if (s[0]=='c' && s[1]=='r' && s[2]) { op->kind=OP_REG; op->rc=RC_CR; op->size=64; op->regnum=atoi(s+2); return 1; }
	if (s[0]=='d' && s[1]=='r' && s[2]) { op->kind=OP_REG; op->rc=RC_DR; op->size=64; op->regnum=atoi(s+2); return 1; }
	if (!strcmp(s, "rip")) { op->kind=OP_REG; op->rc=RC_RIP; op->size=64; op->regnum=0; return 1; }
	return 0;
}

static int parse_mem(struct node *nd, struct operand *op, const char **err)
{
	if (nd->n_children != 6) {
		*err = "mem node needs 6 children: size seg base index scale disp";
		return 0;
	}
	op->kind = OP_MEM; op->base = -1; op->index = -1; op->scale = 1;
	op->seg = -1; op->disp = 0; op->size = 0; op->addrsize = 0; op->rip = 0;

	const char *sz = nd->children[0]->content, *sg = nd->children[1]->content;
	const char *bs = nd->children[2]->content, *ix = nd->children[3]->content;
	const char *sc = nd->children[4]->content, *dp = nd->children[5]->content;

	if (strcmp(sz, "-")) op->size = size_kw(sz);
	if (strcmp(sg, "-")) for (int i = 0; i < 6; i++) if (!strcmp(sg, SEG[i])) op->seg = i;
	if (strcmp(bs, "-")) {
		if (!strcmp(bs, "rip")) { op->rip = 1; op->addrsize = 64; }
		else {
			struct operand t; memset(&t, 0, sizeof t);
			if (!parse_reg(bs, &t) || t.rc != RC_GPR) { *err = "bad mem base register"; return 0; }
			op->base = t.regnum; op->addrsize = t.size;
		}
	}
	if (strcmp(ix, "-")) {
		struct operand t; memset(&t, 0, sizeof t);
		if (!parse_reg(ix, &t) || t.rc != RC_GPR) { *err = "bad mem index register"; return 0; }
		op->index = t.regnum; op->addrsize = t.size;
	}
	if (strcmp(sc, "-")) op->scale = atoi(sc);
	if (strcmp(dp, "-")) op->disp = (dp[0]=='-') ? (long)strtoll(dp,NULL,0)
						      : (long)strtoull(dp,NULL,0);
	return 1;
}

static int parse_operand(struct node *nd, struct operand *op, const char **err)
{
	memset(op, 0, sizeof *op);
	op->base = -1; op->index = -1; op->scale = 1; op->seg = -1;
	if (nd->n_children > 0 && !strcmp(nd->content, "mem"))
		return parse_mem(nd, op, err);
	if (parse_reg(nd->content, op))
		return 1;
	op->kind = OP_IMM;
	op->imm = (nd->content[0]=='-') ? (long long)strtoll(nd->content,NULL,0)
					: (long long)strtoull(nd->content,NULL,0);
	return 1;
}

static int is_acc(const struct operand *o)
{
	return o->kind==OP_REG && o->rc==RC_GPR && o->regnum==0;
}

static void put_imm(struct insn *in, long long v, int bytes)
{
	for (int k = 0; k < bytes; k++)
		in->imm[k] = (unsigned char)((v >> (8*k)) & 0xff);
	in->imm_len = bytes;
}

/* Choose the operand-size prefix / REX.W for an `osize`-bit operation. */
static void enc_opsize(struct enc *e, int osize)
{
	if (osize == 16 && e->mode != 16)      e->p66 = 1;
	else if (osize == 32 && e->mode == 16) e->p66 = 1;
	else if (osize == 64)                  e->rexW = 1;
}

/* Build ModRM (+ SIB + disp) for an r/m operand with `regfield` in reg. */
static int enc_rm(struct enc *e, const struct operand *rm, int regfield, const char **err)
{
	struct insn *in = e->in;
	e->rexR = (regfield >= 8);

	if (rm->kind == OP_REG) {
		in->has_modrm = 1;
		in->modrm = (3<<6) | ((regfield&7)<<3) | (rm->regnum&7);
		e->rexB = (rm->regnum >= 8);
		return 1;
	}
	if (rm->kind != OP_MEM) { *err = "expected register or memory operand"; return 0; }
	if (rm->seg == 4 || rm->seg == 5) e->seg = rm->seg;     /* fs/gs override */

	int defaddr = (e->mode==16) ? 16 : (e->mode==64 ? 64 : 32);
	int addr = rm->addrsize ? rm->addrsize : defaddr;
	if (addr != defaddr) e->p67 = 1;

	if (addr == 16) {
		if (rm->base < 0 && rm->index < 0) {
			in->has_modrm = 1;
			in->modrm = ((regfield&7)<<3) | 6;     /* mod=0, rm=110 */
			in->disp[0] = rm->disp & 0xff;
			in->disp[1] = (rm->disp >> 8) & 0xff;
			in->disp_len = 2;
			return 1;
		}
		*err = "16-bit register addressing unsupported"; return 0;
	}
	if (rm->rip) {
		in->has_modrm = 1;
		in->modrm = ((regfield&7)<<3) | 5;             /* mod=0, rm=101 */
		for (int k = 0; k < 4; k++) in->disp[k] = (rm->disp >> (8*k)) & 0xff;
		in->disp_len = 4;
		return 1;
	}

	int base = rm->base, index = rm->index;
	if (index == 4) { *err = "rsp/esp cannot be a memory index"; return 0; }

	/* Pure absolute [disp32]: 64-bit addressing must route it through a SIB
	 * (mod=0,rm=101 is RIP-relative there); 32-bit can use mod=0,rm=101. */
	if (base < 0 && index < 0) {
		in->has_modrm = 1;
		if (addr == 64) {
			in->modrm = ((regfield&7)<<3) | 4;
			in->has_sib = 1;
			in->sib = (4<<3) | 5;          /* no index, no base, disp32 */
		} else {
			in->modrm = ((regfield&7)<<3) | 5;
		}
		for (int k = 0; k < 4; k++) in->disp[k] = (rm->disp >> (8*k)) & 0xff;
		in->disp_len = 4;
		return 1;
	}

	int need_sib = (index >= 0) || ((base&7) == 4);
	int mod, dl;
	if (base < 0)                              { mod = 0; dl = 4; }   /* index-only */
	else if (rm->disp == 0 && (base&7) != 5)   { mod = 0; dl = 0; }
	else if (rm->disp >= -128 && rm->disp <= 127) { mod = 1; dl = 1; }
	else                                       { mod = 2; dl = 4; }

	int rmf;
	if (need_sib) {
		rmf = 4;
		int ss = rm->scale==8?3 : rm->scale==4?2 : rm->scale==2?1 : 0;
		int idx3 = (index >= 0) ? (index&7) : 4;       /* 4 = no index */
		int bas3 = (base  >= 0) ? (base&7)  : 5;       /* 5 = no base  */
		in->has_sib = 1;
		in->sib = (ss<<6) | (idx3<<3) | bas3;
		if (index >= 0) e->rexX = (index >= 8);
		if (base  >= 0) e->rexB = (base  >= 8);
		if (base < 0)   { mod = 0; dl = 4; }
	} else {
		rmf = base & 7;
		e->rexB = (base >= 8);
	}
	in->has_modrm = 1;
	in->modrm = (mod<<6) | ((regfield&7)<<3) | rmf;
	for (int k = 0; k < dl; k++) in->disp[k] = (rm->disp >> (8*k)) & 0xff;
	in->disp_len = dl;
	return 1;
}

/* Lay down legacy prefixes (in canonical order) and the REX byte. */
static int enc_finalize(struct enc *e, const char **err)
{
	struct insn *in = e->in;
	static const unsigned char SEGP[6] = {0x26,0x2e,0x36,0x3e,0x64,0x65};

	/* (rep is prepended by its own handler) seg, then 66, then 67. */
	if (e->seg >= 0) in->legacy[in->n_legacy++] = SEGP[e->seg];
	if (e->p66)      in->legacy[in->n_legacy++] = 0x66;
	if (e->p67)      in->legacy[in->n_legacy++] = 0x67;

	int wantrex = e->rexW || e->rexR || e->rexX || e->rexB || e->need_rex8;
	if (wantrex) {
		if (e->mode != 64) { *err = "this form requires `bits 64`"; return 0; }
		if (e->bad_rex8)   { *err = "ah/ch/dh/bh cannot be used with a REX prefix"; return 0; }
		in->has_rex = 1;
		in->rex = 0x40 | (e->rexW<<3) | (e->rexR<<2) | (e->rexX<<1) | e->rexB;
	}
	return 1;
}

/* Condition code from a jcc/setcc/cmovcc suffix, or -1. */
static int cc_lookup(const char *s)
{
	static const struct { const char *n; int cc; } T[] = {
		{"o",0},{"no",1},{"b",2},{"c",2},{"nae",2},{"ae",3},{"nb",3},{"nc",3},
		{"e",4},{"z",4},{"ne",5},{"nz",5},{"be",6},{"na",6},{"a",7},{"nbe",7},
		{"s",8},{"ns",9},{"p",10},{"pe",10},{"np",11},{"po",11},
		{"l",12},{"nge",12},{"ge",13},{"nl",13},{"le",14},{"ng",14},{"g",15},{"nle",15},
	};
	for (size_t i = 0; i < sizeof T/sizeof T[0]; i++)
		if (!strcmp(s, T[i].n)) return T[i].cc;
	return -1;
}

static int encode(struct node *nd, int mode, struct insn *out, const char **err);

/* Fixed (no-ModRM) instructions: returns 1 if `m` was one. */
static int enc_fixed(const char *m, struct enc *e)
{
	struct insn *in = e->in;
	struct { const char *m; int opmap; unsigned char op; int rexw; int modrm; } F[] = {
		{"nop",0,0x90,0,-1}, {"hlt",0,0xf4,0,-1}, {"cli",0,0xfa,0,-1},
		{"sti",0,0xfb,0,-1}, {"cld",0,0xfc,0,-1}, {"std",0,0xfd,0,-1},
		{"clc",0,0xf8,0,-1}, {"stc",0,0xf9,0,-1}, {"cmc",0,0xf5,0,-1},
		{"ret",0,0xc3,0,-1}, {"retf",0,0xcb,0,-1}, {"leave",0,0xc9,0,-1},
		{"int3",0,0xcc,0,-1}, {"into",0,0xce,0,-1},
		{"pushf",0,0x9c,0,-1}, {"popf",0,0x9d,0,-1},
		{"iret",0,0xcf,0,-1}, {"iretd",0,0xcf,0,-1}, {"iretq",0,0xcf,1,-1},
		{"cwd",0,0x99,0,-1}, {"cdq",0,0x99,0,-1}, {"cqo",0,0x99,1,-1},
		{"cbw",0,0x98,0,-1}, {"cwde",0,0x98,0,-1}, {"cdqe",0,0x98,1,-1},
		{"syscall",1,0x05,0,-1}, {"sysret",1,0x07,0,-1}, {"sysretq",1,0x07,1,-1},
		{"rdmsr",1,0x32,0,-1}, {"wrmsr",1,0x30,0,-1}, {"rdtsc",1,0x31,0,-1},
		{"rdpmc",1,0x33,0,-1}, {"cpuid",1,0xa2,0,-1}, {"ud2",1,0x0b,0,-1},
		{"clts",1,0x06,0,-1}, {"invd",1,0x08,0,-1}, {"wbinvd",1,0x09,0,-1},
		{"sysenter",1,0x34,0,-1}, {"sysexit",1,0x35,0,-1},
		{"swapgs",1,0x01,0,0xf8},
		{NULL,0,0,0,-1}
	};
	for (int i = 0; F[i].m; i++) {
		if (strcmp(m, F[i].m)) continue;
		in->opmap = F[i].opmap;
		in->opcode = F[i].op;
		if (F[i].rexw) e->rexW = 1;
		/* cwde/cdqe/cwd/cdq pick width by mnemonic via the 66 prefix. */
		if (!strcmp(m,"cbw") || !strcmp(m,"cwd")) e->p66 = (e->mode != 16);
		if ((!strcmp(m,"cwde") || !strcmp(m,"cdq")) && e->mode == 16) e->p66 = 1;
		if (F[i].modrm >= 0) { in->has_modrm = 1; in->modrm = (unsigned char)F[i].modrm; }
		return 1;
	}
	return 0;
}

static int encode(struct node *nd, int mode, struct insn *out, const char **err)
{
	const char *m = nd->content;

	/* rep / repne wrapper: encode the child, prepend the prefix. */
	if (!strcmp(m,"rep")||!strcmp(m,"repe")||!strcmp(m,"repz")||
	    !strcmp(m,"repne")||!strcmp(m,"repnz")) {
		if (nd->n_children != 1) { *err = "rep takes one child instruction"; return 0; }
		if (!encode(nd->children[0], mode, out, err)) return 0;
		unsigned char pfx = (m[3]=='n') ? 0xf2 : 0xf3;
		if (out->n_legacy >= (int)sizeof out->legacy) { *err = "too many prefixes"; return 0; }
		for (int k = out->n_legacy; k > 0; k--) out->legacy[k] = out->legacy[k-1];
		out->legacy[0] = pfx;
		out->n_legacy++;
		return 1;
	}

	memset(out, 0, sizeof *out);
	struct enc e; memset(&e, 0, sizeof e);
	e.in = out; e.mode = mode; e.seg = -1;

	struct operand ops[4];
	int nops = nd->n_children;
	if (nops > 4) { *err = "too many operands"; return 0; }
	for (int i = 0; i < nops; i++) {
		if (!parse_operand(nd->children[i], &ops[i], err)) return 0;
		if (ops[i].kind==OP_REG && ops[i].r8rex)  e.need_rex8 = 1;
		if (ops[i].kind==OP_REG && ops[i].r8high) e.bad_rex8  = 1;
	}
	struct operand *d = nops>0 ? &ops[0] : NULL;
	struct operand *s = nops>1 ? &ops[1] : NULL;

	int handled = 0;

	/* --- ALU group: add/or/adc/sbb/and/sub/xor/cmp --------------------- */
	static const struct { const char *m; int base; } ALU[] = {
		{"add",0x00},{"or",0x08},{"adc",0x10},{"sbb",0x18},
		{"and",0x20},{"sub",0x28},{"xor",0x30},{"cmp",0x38},
	};
	for (int a = 0; a < 8 && !handled; a++) {
		if (strcmp(m, ALU[a].m)) continue;
		if (nops != 2) { *err = "binary op needs two operands"; return 0; }
		int base = ALU[a].base;
		if (s->kind == OP_IMM) {
			int os = d->size;
			if (!os) { *err = "operation needs an operand size"; return 0; }
			enc_opsize(&e, os);
			if (os == 8) {                       /* no imm8 sign-extend form */
				if (is_acc(d)) { out->opcode = base+4; put_imm(out, s->imm, 1); }
				else { out->opcode = 0x80; if (!enc_rm(&e,d,base>>3,err)) return 0; put_imm(out, s->imm, 1); }
			} else if (s->imm >= -128 && s->imm <= 127) {   /* 0x83: shortest, even for acc */
				out->opcode = 0x83;
				if (!enc_rm(&e, d, base>>3, err)) return 0;
				put_imm(out, s->imm, 1);
			} else if (is_acc(d)) {
				out->opcode = base + 5;
				put_imm(out, s->imm, os==16?2:4);
			} else {
				out->opcode = 0x81;
				if (!enc_rm(&e, d, base>>3, err)) return 0;
				put_imm(out, s->imm, os==16?2:4);
			}
		} else if (d->kind==OP_REG && s->kind==OP_MEM) {
			int os = d->size; enc_opsize(&e, os);
			out->opcode = base + (os==8?2:3);
			if (!enc_rm(&e, s, d->regnum, err)) return 0;
		} else if (s->kind==OP_REG) {
			int os = (d->kind==OP_REG) ? d->size : (d->size?d->size:s->size);
			enc_opsize(&e, os);
			out->opcode = base + (os==8?0:1);
			if (!enc_rm(&e, d, s->regnum, err)) return 0;
		} else { *err = "bad operands"; return 0; }
		handled = 1;
	}

	/* --- mov / movabs -------------------------------------------------- */
	if (!handled && !strcmp(m, "mov")) {
		if (nops != 2) { *err = "mov needs two operands"; return 0; }
		if (d->rc==RC_SEG) {                       /* mov sreg, r/m16 */
			out->opcode = 0x8e;
			if (!enc_rm(&e, s, d->regnum, err)) return 0;
		} else if (s->rc==RC_SEG) {                /* mov r/m16, sreg */
			out->opcode = 0x8c;
			if (!enc_rm(&e, d, s->regnum, err)) return 0;
		} else if (s->rc==RC_CR) {                 /* mov r64, cr */
			out->opmap=1; out->opcode=0x20;
			if (!enc_rm(&e, d, s->regnum, err)) return 0;
		} else if (d->rc==RC_CR) {                 /* mov cr, r64 */
			out->opmap=1; out->opcode=0x22;
			if (!enc_rm(&e, s, d->regnum, err)) return 0;
		} else if (s->rc==RC_DR) {
			out->opmap=1; out->opcode=0x21;
			if (!enc_rm(&e, d, s->regnum, err)) return 0;
		} else if (d->rc==RC_DR) {
			out->opmap=1; out->opcode=0x23;
			if (!enc_rm(&e, s, d->regnum, err)) return 0;
		} else if (s->kind==OP_IMM) {
			if (d->kind==OP_REG) {
				int os = d->size; enc_opsize(&e, os);
				if (os==8) { out->opcode=0xb0+(d->regnum&7); e.rexB=(d->regnum>=8); put_imm(out,s->imm,1); }
				else if (os==16||os==32) { out->opcode=0xb8+(d->regnum&7); e.rexB=(d->regnum>=8); put_imm(out,s->imm,os==16?2:4); }
				else { /* mov r64, imm32 (sign-extended) */
					if (s->imm < -2147483648LL || s->imm > 2147483647LL) { *err="64-bit immediate needs movabs"; return 0; }
					out->opcode=0xc7;
					if (!enc_rm(&e, d, 0, err)) return 0;
					put_imm(out, s->imm, 4);
				}
			} else {
				int os = d->size; if (!os) { *err="memory store needs a size"; return 0; }
				enc_opsize(&e, os);
				out->opcode = (os==8)?0xc6:0xc7;
				if (!enc_rm(&e, d, 0, err)) return 0;
				put_imm(out, s->imm, os==8?1:(os==16?2:4));
			}
		} else if (s->kind==OP_REG) {              /* mov r/m, r */
			int os = s->size; enc_opsize(&e, os);
			out->opcode = (os==8)?0x88:0x89;
			if (!enc_rm(&e, d, s->regnum, err)) return 0;
		} else if (d->kind==OP_REG) {              /* mov r, r/m */
			int os = d->size; enc_opsize(&e, os);
			out->opcode = (os==8)?0x8a:0x8b;
			if (!enc_rm(&e, s, d->regnum, err)) return 0;
		} else { *err="bad mov operands"; return 0; }
		handled = 1;
	}
	if (!handled && !strcmp(m, "movabs")) {
		if (nops != 2) { *err="movabs needs two operands"; return 0; }
		if (s->kind==OP_IMM && d->kind==OP_REG && d->size==64) {
			e.rexW=1; out->opcode=0xb8+(d->regnum&7); e.rexB=(d->regnum>=8);
			put_imm(out, s->imm, 8);
		} else if (is_acc(d) && s->kind==OP_MEM) {        /* movabs acc, [moffs] */
			int os=d->size; enc_opsize(&e, os);
			int a = s->addrsize ? s->addrsize : (mode==64?64:32);
			if (s->seg==4||s->seg==5) e.seg=s->seg;
			out->opcode = (os==8)?0xa0:0xa1;
			put_imm(out, s->disp, a/8);
		} else if (is_acc(s) && d->kind==OP_MEM) {        /* movabs [moffs], acc */
			int os=s->size; enc_opsize(&e, os);
			int a = d->addrsize ? d->addrsize : (mode==64?64:32);
			if (d->seg==4||d->seg==5) e.seg=d->seg;
			out->opcode = (os==8)?0xa2:0xa3;
			put_imm(out, d->disp, a/8);
		} else { *err="bad movabs operands"; return 0; }
		handled = 1;
	}

	/* --- test / lea / xchg -------------------------------------------- */
	if (!handled && !strcmp(m, "test")) {
		if (nops!=2) { *err="test needs two operands"; return 0; }
		int os = d->size ? d->size : s->size;
		if (s->kind==OP_IMM) {
			enc_opsize(&e, os);
			if (is_acc(d)) { out->opcode=(os==8?0xa8:0xa9); put_imm(out,s->imm,os==8?1:(os==16?2:4)); }
			else { out->opcode=(os==8?0xf6:0xf7); if(!enc_rm(&e,d,0,err))return 0; put_imm(out,s->imm,os==8?1:(os==16?2:4)); }
		} else if (s->kind==OP_REG) {
			enc_opsize(&e, s->size);
			out->opcode=(s->size==8?0x84:0x85);
			if (!enc_rm(&e, d, s->regnum, err)) return 0;
		} else { *err="bad test operands"; return 0; }
		handled = 1;
	}
	if (!handled && !strcmp(m, "lea")) {
		if (nops!=2 || d->kind!=OP_REG || s->kind!=OP_MEM) { *err="lea needs reg, mem"; return 0; }
		enc_opsize(&e, d->size);
		out->opcode = 0x8d;
		if (!enc_rm(&e, s, d->regnum, err)) return 0;
		handled = 1;
	}
	if (!handled && !strcmp(m, "xchg")) {
		if (nops!=2) { *err="xchg needs two operands"; return 0; }
		struct operand *rm = (d->kind==OP_MEM)?d:s, *rg = (d->kind==OP_MEM)?s:d;
		if (rg->kind!=OP_REG) { *err="bad xchg operands"; return 0; }
		enc_opsize(&e, rg->size);
		out->opcode = (rg->size==8)?0x86:0x87;
		if (!enc_rm(&e, rm, rg->regnum, err)) return 0;
		handled = 1;
	}

	/* --- push / pop ---------------------------------------------------- */
	if (!handled && !strcmp(m, "push")) {
		if (nops!=1) { *err="push needs one operand"; return 0; }
		if (d->kind==OP_IMM) {
			if (d->imm>=-128 && d->imm<=127) { out->opcode=0x6a; put_imm(out,d->imm,1); }
			else { out->opcode=0x68; put_imm(out,d->imm,4); }
		} else if (d->kind==OP_REG && d->rc==RC_GPR) {
			if (d->size==16) e.p66=1;
			out->opcode=0x50+(d->regnum&7); e.rexB=(d->regnum>=8);
		} else if (d->rc==RC_SEG && (d->regnum==4||d->regnum==5)) {
			out->opmap=1; out->opcode=(d->regnum==4)?0xa0:0xa8;
		} else if (d->kind==OP_MEM) {
			out->opcode=0xff; if(!enc_rm(&e,d,6,err))return 0;
		} else { *err="bad push operand"; return 0; }
		handled = 1;
	}
	if (!handled && !strcmp(m, "pop")) {
		if (nops!=1) { *err="pop needs one operand"; return 0; }
		if (d->kind==OP_REG && d->rc==RC_GPR) {
			if (d->size==16) e.p66=1;
			out->opcode=0x58+(d->regnum&7); e.rexB=(d->regnum>=8);
		} else if (d->rc==RC_SEG && (d->regnum==4||d->regnum==5)) {
			out->opmap=1; out->opcode=(d->regnum==4)?0xa1:0xa9;
		} else if (d->kind==OP_MEM) {
			out->opcode=0x8f; if(!enc_rm(&e,d,0,err))return 0;
		} else { *err="bad pop operand"; return 0; }
		handled = 1;
	}

	/* --- unary group3/4/5: not/neg/mul/imul1/div/idiv/inc/dec --------- */
	if (!handled) {
		static const struct { const char *m; unsigned char op; int digit; } U[] = {
			{"not",0xf7,2},{"neg",0xf7,3},{"mul",0xf7,4},
			{"div",0xf7,6},{"idiv",0xf7,7},{"inc",0xff,0},{"dec",0xff,1},
		};
		for (int u = 0; u < 7 && !handled; u++) {
			if (strcmp(m, U[u].m)) continue;
			if (nops!=1) { *err="needs one operand"; return 0; }
			int os = d->size; if(!os){*err="operand needs a size";return 0;}
			enc_opsize(&e, os);
			out->opcode = (os==8) ? (U[u].op==0xf7?0xf6:0xfe) : U[u].op;
			if (!enc_rm(&e, d, U[u].digit, err)) return 0;
			handled = 1;
		}
	}

	/* --- imul (1/2/3-operand) ----------------------------------------- */
	if (!handled && !strcmp(m, "imul")) {
		if (nops==1) {
			int os=d->size; if(!os){*err="imul needs a size";return 0;}
			enc_opsize(&e,os); out->opcode=(os==8?0xf6:0xf7);
			if(!enc_rm(&e,d,5,err))return 0;
		} else if (nops==2) {
			enc_opsize(&e,d->size); out->opmap=1; out->opcode=0xaf;
			if(!enc_rm(&e,s,d->regnum,err))return 0;
		} else if (nops==3) {
			struct operand *imm=&ops[2];
			enc_opsize(&e,d->size);
			if (imm->imm>=-128&&imm->imm<=127){ out->opcode=0x6b; if(!enc_rm(&e,s,d->regnum,err))return 0; put_imm(out,imm->imm,1);}
			else { out->opcode=0x69; if(!enc_rm(&e,s,d->regnum,err))return 0; put_imm(out,imm->imm,d->size==16?2:4);}
		} else { *err="bad imul"; return 0; }
		handled = 1;
	}

	/* --- shifts / rotates --------------------------------------------- */
	if (!handled) {
		static const struct { const char *m; int digit; } SH[] = {
			{"rol",0},{"ror",1},{"rcl",2},{"rcr",3},
			{"shl",4},{"sal",4},{"shr",5},{"sar",7},
		};
		for (int h = 0; h < 8 && !handled; h++) {
			if (strcmp(m, SH[h].m)) continue;
			if (nops!=2) { *err="shift needs two operands"; return 0; }
			int os=d->size; if(!os){*err="shift needs a size";return 0;}
			enc_opsize(&e, os);
			if (s->kind==OP_REG && s->size==8 && s->regnum==1) out->opcode=(os==8?0xd2:0xd3);
			else if (s->kind==OP_IMM && s->imm==1)             out->opcode=(os==8?0xd0:0xd1);
			else if (s->kind==OP_IMM)                          out->opcode=(os==8?0xc0:0xc1);
			else { *err="shift count must be cl, 1, or imm8"; return 0; }
			if (!enc_rm(&e, d, SH[h].digit, err)) return 0;
			if (out->opcode==0xc0||out->opcode==0xc1) put_imm(out, s->imm, 1);
			handled = 1;
		}
	}

	/* --- movzx / movsx / movsxd --------------------------------------- */
	if (!handled && (!strcmp(m,"movzx")||!strcmp(m,"movsx"))) {
		if (nops!=2 || d->kind!=OP_REG) { *err="needs reg, r/m"; return 0; }
		int ss = (s->kind==OP_REG)?s->size:s->size;
		if (ss!=8 && ss!=16) { *err="source must be 8- or 16-bit"; return 0; }
		enc_opsize(&e, d->size);
		out->opmap=1;
		out->opcode = (!strcmp(m,"movzx")) ? (ss==8?0xb6:0xb7) : (ss==8?0xbe:0xbf);
		if (!enc_rm(&e, s, d->regnum, err)) return 0;
		handled = 1;
	}
	if (!handled && !strcmp(m,"movsxd")) {
		if (nops!=2 || d->kind!=OP_REG) { *err="needs reg, r/m"; return 0; }
		e.rexW=1; out->opcode=0x63;
		if (!enc_rm(&e, s, d->regnum, err)) return 0;
		handled = 1;
	}

	/* --- bit ops: bt/bts/btr/btc, bsf/bsr, bswap ---------------------- */
	if (!handled) {
		static const struct { const char *m; unsigned char rop; int digit; } BT[] = {
			{"bt",0xa3,4},{"bts",0xab,5},{"btr",0xb3,6},{"btc",0xbb,7},
		};
		for (int b = 0; b < 4 && !handled; b++) {
			if (strcmp(m, BT[b].m)) continue;
			if (nops!=2) { *err="bit op needs two operands"; return 0; }
			out->opmap=1;
			if (s->kind==OP_IMM) {
				int os=d->size?d->size:32; enc_opsize(&e,os);
				out->opcode=0xba;
				if(!enc_rm(&e,d,BT[b].digit,err))return 0;
				put_imm(out,s->imm,1);
			} else if (s->kind==OP_REG) {
				enc_opsize(&e,s->size);
				out->opcode=BT[b].rop;
				if(!enc_rm(&e,d,s->regnum,err))return 0;
			} else { *err="bad bit op"; return 0; }
			handled = 1;
		}
	}
	if (!handled && (!strcmp(m,"bsf")||!strcmp(m,"bsr"))) {
		if (nops!=2 || d->kind!=OP_REG) { *err="needs reg, r/m"; return 0; }
		enc_opsize(&e,d->size); out->opmap=1; out->opcode=(!strcmp(m,"bsf")?0xbc:0xbd);
		if(!enc_rm(&e,s,d->regnum,err))return 0;
		handled = 1;
	}
	if (!handled && !strcmp(m,"bswap")) {
		if (nops!=1 || d->kind!=OP_REG) { *err="bswap needs a register"; return 0; }
		enc_opsize(&e,d->size); out->opmap=1; out->opcode=0xc8+(d->regnum&7); e.rexB=(d->regnum>=8);
		handled = 1;
	}

	/* --- control flow: jmp/call/jcc/setcc/cmovcc ---------------------- */
	if (!handled && (!strcmp(m,"jmp")||!strcmp(m,"call"))) {
		if (nops!=1) { *err="needs one operand"; return 0; }
		int call = !strcmp(m,"call");
		if (d->kind==OP_IMM) {                     /* relative displacement */
			if (!call && d->imm>=-128 && d->imm<=127) { out->opcode=0xeb; put_imm(out,d->imm,1); }
			else { out->opcode=call?0xe8:0xe9; put_imm(out,d->imm,4); }
		} else {                                   /* indirect r/m64 */
			out->opcode=0xff;
			if (!enc_rm(&e, d, call?2:4, err)) return 0;
		}
		handled = 1;
	}
	if (!handled && m[0]=='j' && cc_lookup(m+1) >= 0) {
		if (nops!=1 || d->kind!=OP_IMM) { *err="jcc needs a displacement"; return 0; }
		int cc = cc_lookup(m+1);
		if (d->imm>=-128 && d->imm<=127) { out->opcode=0x70+cc; put_imm(out,d->imm,1); }
		else { out->opmap=1; out->opcode=0x80+cc; put_imm(out,d->imm,4); }
		handled = 1;
	}
	if (!handled && !strncmp(m,"set",3) && cc_lookup(m+3) >= 0) {
		if (nops!=1) { *err="setcc needs one operand"; return 0; }
		out->opmap=1; out->opcode=0x90+cc_lookup(m+3);
		if (!enc_rm(&e, d, 0, err)) return 0;
		handled = 1;
	}
	if (!handled && !strncmp(m,"cmov",4) && cc_lookup(m+4) >= 0) {
		if (nops!=2 || d->kind!=OP_REG) { *err="cmovcc needs reg, r/m"; return 0; }
		enc_opsize(&e, d->size);
		out->opmap=1; out->opcode=0x40+cc_lookup(m+4);
		if (!enc_rm(&e, s, d->regnum, err)) return 0;
		handled = 1;
	}

	/* --- string ops --------------------------------------------------- */
	if (!handled) {
		static const struct { const char *m; unsigned char op8; unsigned char opv; int os; } ST[] = {
			{"movsb",0xa4,0,8},{"movsw",0,0xa5,16},{"movsd",0,0xa5,32},{"movsq",0,0xa5,64},
			{"stosb",0xaa,0,8},{"stosw",0,0xab,16},{"stosd",0,0xab,32},{"stosq",0,0xab,64},
			{"lodsb",0xac,0,8},{"lodsw",0,0xad,16},{"lodsd",0,0xad,32},{"lodsq",0,0xad,64},
			{"scasb",0xae,0,8},{"scasw",0,0xaf,16},{"scasd",0,0xaf,32},{"scasq",0,0xaf,64},
			{"cmpsb",0xa6,0,8},{"cmpsw",0,0xa7,16},{"cmpsd",0,0xa7,32},{"cmpsq",0,0xa7,64},
		};
		for (int t = 0; t < (int)(sizeof ST/sizeof ST[0]) && !handled; t++) {
			if (strcmp(m, ST[t].m)) continue;
			if (ST[t].os==8) out->opcode=ST[t].op8;
			else { enc_opsize(&e, ST[t].os); out->opcode=ST[t].opv; }
			handled = 1;
		}
	}

	/* --- int imm8 ----------------------------------------------------- */
	if (!handled && !strcmp(m,"int")) {
		if (nops!=1 || d->kind!=OP_IMM) { *err="int needs an immediate"; return 0; }
		out->opcode=0xcd; put_imm(out,d->imm,1);
		handled = 1;
	}

	/* --- system descriptor-table / segment ops (0F 00 / 0F 01) -------- */
	if (!handled) {
		static const struct { const char *m; unsigned char op; int digit; } S0[] = {
			{"sgdt",0x01,0},{"sidt",0x01,1},{"lgdt",0x01,2},{"lidt",0x01,3},
			{"smsw",0x01,4},{"lmsw",0x01,6},
			{"sldt",0x00,0},{"str",0x00,1},{"lldt",0x00,2},{"ltr",0x00,3},
			{"verr",0x00,4},{"verw",0x00,5},
		};
		for (int t = 0; t < (int)(sizeof S0/sizeof S0[0]) && !handled; t++) {
			if (strcmp(m, S0[t].m)) continue;
			if (nops!=1) { *err="needs one operand"; return 0; }
			out->opmap=1; out->opcode=S0[t].op;
			if (!enc_rm(&e, d, S0[t].digit, err)) return 0;
			handled = 1;
		}
	}

	/* --- fixed (no-operand) instructions ------------------------------ */
	if (!handled && enc_fixed(m, &e))
		handled = 1;

	if (!handled) { *err = "unsupported mnemonic"; return 0; }
	return enc_finalize(&e, err);
}

/* Read a node-tree program and print each instruction's machine code as hex. */
static int assemble_nodes(const char *path, int verbose)
{
	FILE *f = fopen(path, "rb");
	if (!f) { fprintf(stderr, "ttpc: cannot open '%s'\n", path); return EXIT_FAILURE; }
	struct node *root = node_read(f);
	fclose(f);
	if (!root) { fprintf(stderr, "ttpc: '%s' is not a node program\n", path); return EXIT_FAILURE; }

	int mode = 64, total = 0, errors = 0;
	for (int i = 0; i < root->n_children; i++) {
		struct node *nd = root->children[i];
		if (!strcmp(nd->content, "bits")) {
			if (nd->n_children == 1) mode = atoi(nd->children[0]->content);
			continue;
		}
		struct insn in;
		const char *err = NULL;
		if (!encode(nd, mode, &in, &err)) {
			fprintf(stderr, "ttpc: cannot assemble '%s': %s\n",
				nd->content, err ? err : "unsupported");
			errors++;
			continue;
		}
		unsigned char buf[16];
		int n = assemble(&in, buf);
		for (int k = 0; k < n; k++)
			printf("%02x%s", buf[k], k+1<n ? " " : "");
		if (verbose) {
			printf("   ; %s", nd->content);
			for (int k = 0; k < nd->n_children; k++)
				printf(" %s", nd->children[k]->content);
		}
		printf("\n");
		total++;
	}
	fprintf(stderr, "ttpc: assembled %d node(s), %d error(s)\n", total, errors);
	return errors ? EXIT_FAILURE : EXIT_SUCCESS;
}

int main(int argc, char **argv)
{
	const char *in_path  = NULL;
	const char *out_path = NULL;
	int         verbose  = 0;        /* -v: print the field breakdown */
	int         assemble = 0;        /* -a: assemble a node program to hex */

	for (int i = 1; i < argc; i++) {
		if (strcmp(argv[i], "-v") == 0)
			verbose = 1;
		else if (strcmp(argv[i], "-a") == 0)
			assemble = 1;
		else if (!in_path)
			in_path = argv[i];
		else if (!out_path)
			out_path = argv[i];
	}

	/* Assembler mode: node tree -> machine code (hex on stdout). */
	if (assemble) {
		if (!in_path)
			in_path = DEFAULT_NODES;
		return assemble_nodes(in_path, verbose);
	}

	if (!in_path)
		in_path = DEFAULT_INPUT;
	if (!out_path)
		out_path = DEFAULT_OUTPUT;

	FILE *in = fopen(in_path, "rb");
	if (!in) {
		fprintf(stderr, "ttpc: cannot open '%s'\n", in_path);
		return EXIT_FAILURE;
	}

	FILE *out = fopen(out_path, "wb");
	if (!out) {
		fprintf(stderr, "ttpc: cannot open '%s' for writing\n", out_path);
		fclose(in);
		return EXIT_FAILURE;
	}

	char line[512];
	int  count = 0, decoded = 0, passthru = 0, fails = 0;
	int  mode = 16;                  /* current CPU mode (from banners)      */

	struct insn cur;                 /* instruction being assembled          */
	int         have     = 0;        /* cur holds a pending instruction      */
	int         cur_mode = 16;       /* mode when cur's primary line was read */

	while (fgets(line, sizeof line, in)) {
		update_mode(line, &mode);

		struct insn tmp;
		if (!parse_line(line, &tmp))
			continue;

		/* A mnemonic-less line whose address continues the pending
		 * instruction is an objdump line-wrap: append its bytes. */
		if (have && tmp.mnem[0] == '\0' &&
		    tmp.addr == cur.addr + (unsigned long)cur.raw_len) {
			for (int k = 0; k < tmp.raw_len; k++)
				if (cur.raw_len < (int)sizeof cur.raw)
					cur.raw[cur.raw_len++] = tmp.raw[k];
			continue;
		}

		if (have &&
		    emit_insn(&cur, cur_mode, out, verbose,
			      &count, &decoded, &passthru, &fails) < 0) {
			fclose(in);
			fclose(out);
			return EXIT_FAILURE;
		}

		cur      = tmp;
		cur_mode = mode;
		have     = 1;
	}
	if (have &&
	    emit_insn(&cur, cur_mode, out, verbose,
		      &count, &decoded, &passthru, &fails) < 0) {
		fclose(in);
		fclose(out);
		return EXIT_FAILURE;
	}

	/* Pad to a full disk; the gaps left by objdump's collapsed zero runs
	 * become zero holes, exactly the padding the image needs. */
	if (fseek(out, (long)IMG_SECTORS * 512 - 1, SEEK_SET) != 0 ||
	    fputc(0, out) == EOF) {
		fprintf(stderr, "ttpc: cannot pad image to %d sectors\n",
			IMG_SECTORS);
		fclose(in);
		fclose(out);
		return EXIT_FAILURE;
	}

	fclose(in);
	fclose(out);

	fprintf(stderr,
		"ttpc: assembled %d instruction(s) into '%s' "
		"(%d decoded, %d passed through, %d failed)\n",
		count, out_path, decoded, passthru, fails);

	return fails ? EXIT_FAILURE : EXIT_SUCCESS;
}
