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
#include <encode.h>              /* struct insn, encode(), assemble() — shared */

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

/* struct insn lives in encode.h (shared with the OS); assemble()/encode() too. */

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
			/* More prefixes than the field holds is not a real
			 * instruction (it is data the dump decoded as code) —
			 * bail so the caller passes the raw bytes through
			 * instead of reassembling a truncated, mismatched run. */
			if (in->n_legacy >= (int)sizeof in->legacy)
				return 0;
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
