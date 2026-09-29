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
#include <encode.h>              /* struct insn, rv_ops, encode(), assemble()    */

/*
 * Bootstrap stage: the "compiler" reads the OS boot-flow disassembly and, for
 * every instruction line, places its machine-code bytes into a binary image at
 * the line's *file offset* (the address column in boot_flow.txt — see
 * src/os/DISASSEMBLY.md). The result is a faithful copy of the OS image
 * (os.bin) that boots in QEMU.
 *
 * ttpc breaks each RISC-V instruction into its fields — opcode, funct3/funct7,
 * rd/rs1/rs2 and the un-scrambled immediate, or for a compressed (RVC)
 * instruction its quadrant, funct bits, registers and immediate — by matching
 * it against the shared opcode table (rv_ops, encode.c). It then reassembles
 * the bytes from those fields and verifies they match the originals (PASS).
 * A line whose bytes are no RV64IMAC/Zicsr/Zifencei instruction (the unimp
 * padding, .insn, or the .rodata strings objdump shows as code) is passed
 * through verbatim, so the whole image is always reproduced.
 *
 * Every decoded .text line is also re-encoded from objdump's *text* through
 * encode() — the node-tree assembler — and must give the same bytes, so the
 * encoder is checked against the real toolchain on every run.
 */
#define DEFAULT_INPUT  "src/os/boot_flow.txt"
#define DEFAULT_OUTPUT "build/compiler/ttpos.img"

/* Pad the output to 1 MiB (2048 sectors); QEMU loads the whole raw image at
 * the load address, and the zeros past os.bin are harmless. */
#define IMG_SECTORS    2048

struct stats {
	int count;       /* instructions written                          */
	int decoded;     /* decoded and reassembled byte-exact            */
	int passthru;    /* not an instruction ttpc knows: raw bytes      */
	int fails;       /* decoder or encoder disagreed with the bytes   */
	int enc_total;   /* .text lines re-encoded from objdump's text    */
	int enc_ok;      /* ... that gave the same bytes                  */
};

/*
 * Parse one disassembly line into *out. Returns 1 if the line held an
 * instruction, 0 for headers / comments / labels / blanks.
 *
 * Instruction lines look like (leading whitespace, then):
 *   "3c:\ta1 02       \taddi\tt0,t0,8"
 * i.e. <hexaddr> ':' TAB <space-separated hex bytes> TAB <mnem> <operands>.
 */
static int parse_line(const char *line, struct insn *out)
{
	const char *p = line;

	while (*p == ' ' || *p == '\t')
		p++;

	/* Skip comments, banners and the "0000000080000000 <_start>:" labels. */
	if (*p == '#' || *p == '=' || *p == '[' || *p == '\n' || *p == '\0')
		return 0;

	/* Address: hex digits terminated by ':'. A space before ':' (as in
	 * "0000000080000000 <_start>:") means this is a label, not an insn. */
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

	/* Mnemonic and operands (objdump's text: informational for the image,
	 * and the source the encoder cross-check re-assembles). */
	while (*p == '\t' || *p == ' ')
		p++;
	sscanf(p, "%15s %63[^\n]", out->mnem, out->ops);

	return 1;
}

/*
 * Decode the raw bytes into fields. The low two bits give the length (11 = a
 * 32-bit instruction, else 16-bit compressed); the first table entry whose
 * mask/match fits — and, for a compressed one, whose constraints hold, which
 * rules out the reserved and hint encodings — gives the layout. Returns 1 when
 * that accounts for exactly raw_len bytes, 0 otherwise (then the caller passes
 * the raw bytes through).
 */
static int decode(struct insn *in)
{
	int len = ((in->raw[0] & 3) == 3) ? 4 : 2;
	if (in->raw_len != len)
		return 0;

	uint32_t w = 0;
	for (int k = 0; k < len; k++)
		w |= (uint32_t)in->raw[k] << (8 * k);

	for (const struct rv_op *op = rv_ops; op->name; op++) {
		if ((RV_IS_C(op->fmt) ? 2 : 4) != len || (w & op->mask) != op->match)
			continue;
		rv_fields(op, w, in);
		if (RV_IS_C(op->fmt) && !rv_fits(op, in))
			continue;
		return 1;
	}
	return 0;
}

/* Operands of a (32-bit) table entry, spelled as objdump does. */
static void format_args(const struct insn *in, const char *args, char *buf, size_t n)
{
	size_t k = 0;
	buf[0] = '\0';
	for (const char *a = args; *a && k < n; a++) {
		const char *sep = (a == args) ? "" : ",";
		const char *csr;
		switch (*a) {
		case 'd': case 'D': k += snprintf(buf + k, n - k, "%s%s", sep, rv_abi[in->rd]);  break;
		case 's': k += snprintf(buf + k, n - k, "%s%s", sep, rv_abi[in->rs1]); break;
		case 't': k += snprintf(buf + k, n - k, "%s%s", sep, rv_abi[in->rs2]); break;
		case 'u': k += snprintf(buf + k, n - k, "%s0x%lx", sep, in->imm); break;
		case 'm': k += snprintf(buf + k, n - k, "%s%ld(%s)", sep, in->imm, rv_abi[in->rs1]); break;
		case 'A': k += snprintf(buf + k, n - k, "%s(%s)", sep, rv_abi[in->rs1]); break;
		case 'Z': k += snprintf(buf + k, n - k, "%s%d", sep, in->rs1); break;
		case 'E':
			csr = rv_csr_name((int)in->imm);
			if (csr)
				k += snprintf(buf + k, n - k, "%s%s", sep, csr);
			else
				k += snprintf(buf + k, n - k, "%s0x%lx", sep, in->imm);
			break;
		case 'P': case 'Q': {
			int v = (*a == 'P') ? (in->imm >> 4) & 15 : in->imm & 15;
			k += snprintf(buf + k, n - k, "%s%s%s%s%s", sep,
				      v & 8 ? "i" : "", v & 4 ? "o" : "",
				      v & 2 ? "r" : "", v & 1 ? "w" : "");
			break;
		}
		default:   /* j > p a: plain signed numbers */
			k += snprintf(buf + k, n - k, "%s%ld", sep, in->imm);
			break;
		}
	}
}

static void print_fields(const struct insn *in)
{
	const struct rv_op *base = RV_IS_C(in->fmt) ? rv_find(in->op->base) : in->op;
	char ops[80];

	format_args(in, base->args, ops, sizeof ops);
	printf("addr=0x%lx  len=%d  objdump: %s %s\n", in->addr, in->len, in->mnem, in->ops);
	printf("  ttpc: %s", in->op->name);
	if (RV_IS_C(in->fmt))
		printf("  = %s", base->name);
	printf(" %s\n", ops);
	printf("  opcode=0x%02x  funct3=%u  funct7=0x%02x  funct2=%u  "
	       "rd=%s  rs1=%s  rs2=%s  imm=%ld\n",
	       in->opcode, in->funct3, in->funct7, in->funct2,
	       rv_abi[in->rd], rv_abi[in->rs1], rv_abi[in->rs2], in->imm);
}

static void print_bytes(const char *label, const unsigned char *b, int n)
{
	printf("%s", label);
	for (int i = 0; i < n; i++)
		printf(" %02x", b[i]);
}

static void node_free(struct node *n)
{
	for (int i = 0; i < n->n_children; i++)
		node_free(n->children[i]);
	free(n->children);
	free(n->content);
	free(n);
}

/*
 * Turn objdump's text for an instruction ("sd", "ra,8(sp)") into the node
 * encode() takes: a leaf per operand, `off(base)` as a mem(base, off) node, the
 * `# ...` comment dropped. A branch/jump's last operand ("80000044 <park>") is
 * an absolute runtime address; it becomes an offset from `pc`, the
 * instruction's own runtime address.
 */
static struct node *text_node(const struct insn *in, unsigned long pc)
{
	struct node *nd = node_new(in->mnem);
	char ops[sizeof in->ops], *hash;
	const struct rv_op *base = RV_IS_C(in->fmt) ? rv_find(in->op->base) : in->op;
	int has_target = strpbrk(base->args, "pa") != NULL;

	memcpy(ops, in->ops, sizeof ops);
	if ((hash = strchr(ops, '#')))
		*hash = '\0';

	char *toks[4];
	int   ntok = 0;
	for (char *tok = strtok(ops, ","); tok && ntok < 4; tok = strtok(NULL, ",")) {
		while (*tok == ' ')
			tok++;
		char *e = tok + strlen(tok);
		while (e > tok && e[-1] == ' ')
			*--e = '\0';
		if (*tok)
			toks[ntok++] = tok;
	}

	for (int i = 0; i < ntok; i++) {
		char *tok = toks[i];
		char *lp  = strchr(tok, '(');
		if (has_target && i == ntok - 1) {
			char off[32];
			unsigned long target = strtoul(tok, NULL, 16);
			snprintf(off, sizeof off, "%ld", (long)(target - pc));
			node_kid(nd, off);
		} else if (lp) {
			char *rp = strchr(lp, ')');
			if (rp)
				*rp = '\0';
			*lp = '\0';
			struct node *mem = node_kid(nd, "mem");
			node_kid(mem, lp + 1);
			node_kid(mem, *tok ? tok : "0");
		} else {
			node_kid(nd, tok);
		}
	}
	return nd;
}

/*
 * Decode one instruction, emit its bytes at the instruction's file offset, and
 * bump the counters. Emits the reassembled-from-fields bytes when ttpc decodes
 * the instruction and they match, otherwise the raw bytes verbatim — either
 * way the image byte is correct. A decoded .text line is also re-encoded from
 * objdump's text (see text_node) and checked. Returns -1 on a write error, 0
 * otherwise.
 */
static int emit_insn(struct insn *ins, int is_text, unsigned long load_base,
		     FILE *out, int verbose, struct stats *st)
{
	unsigned char        asm_buf[4];
	const unsigned char *emit     = ins->raw;
	int                  emit_len = ins->raw_len;

	if (decode(ins)) {
		int asm_len = assemble(ins, asm_buf);
		int pass = (asm_len == ins->raw_len &&
			    memcmp(asm_buf, ins->raw, asm_len) == 0);

		if (pass) {
			emit     = asm_buf;
			emit_len = asm_len;
			st->decoded++;
		} else {
			/* Decoder and raw bytes disagree: keep the image
			 * faithful (emit raw) but flag the bug. */
			st->fails++;
		}

		/* Encoder cross-check: objdump's text -> node -> bytes. The
		 * text doesn't record the width the assembler chose (a `.align`
		 * pads with a 4-byte nop), so compress only 2-byte lines. */
		unsigned char enc_buf[4];
		int           enc_len = 0, enc_pass = 0;
		const char   *err = NULL;
		if (is_text) {
			struct node *nd = text_node(ins, load_base + ins->addr);
			struct insn  e;
			if (encode(nd, ins->raw_len == 2, &e, &err)) {
				enc_len  = assemble(&e, enc_buf);
				enc_pass = (enc_len == ins->raw_len &&
					    memcmp(enc_buf, ins->raw, enc_len) == 0);
			}
			node_free(nd);
			st->enc_total++;
			if (enc_pass) {
				st->enc_ok++;
			} else {
				st->fails++;
				fprintf(stderr, "ttpc: 0x%lx: re-encoding \"%s %s\" "
					"does not reproduce its bytes%s%s\n",
					ins->addr, ins->mnem, ins->ops,
					err ? ": " : "", err ? err : "");
			}
		}

		if (verbose) {
			print_fields(ins);
			print_bytes("  reassembled:", asm_buf, asm_len);
			print_bytes("   original:", ins->raw, ins->raw_len);
			printf("   %s\n", pass ? "PASS" : "FAIL");
			if (is_text) {
				print_bytes("  re-encoded: ", enc_buf, enc_len);
				printf("   %s\n", enc_pass ? "PASS" : "FAIL");
			}
			printf("\n");
		}
	} else {
		/* Not an instruction ttpc knows — pass the raw bytes through. */
		st->passthru++;
	}

	if (fseek(out, (long)ins->addr, SEEK_SET) != 0 ||
	    fwrite(emit, 1, emit_len, out) != (size_t)emit_len) {
		fprintf(stderr, "ttpc: write error at 0x%lx\n", ins->addr);
		return -1;
	}
	st->count++;
	return 0;
}

/*
 * Read a node-tree program and print each instruction's machine code as hex
 * (bytes in memory order). An `option` node with child "rvc" / "norvc" turns
 * automatic compression on or off for what follows, like `.option` in GNU as.
 */
static int assemble_nodes(const char *path, int verbose)
{
	FILE *f = fopen(path, "rb");
	if (!f) { fprintf(stderr, "ttpc: cannot open '%s'\n", path); return EXIT_FAILURE; }
	struct node *root = node_read(f);
	fclose(f);
	if (!root) { fprintf(stderr, "ttpc: '%s' is not a node program\n", path); return EXIT_FAILURE; }

	int rvc = 1, total = 0, errors = 0;
	for (int i = 0; i < root->n_children; i++) {
		struct node *nd = root->children[i];
		if (node_is(nd, "option")) {
			if (nd->n_children == 1)
				rvc = !node_is(nd->children[0], "norvc");
			continue;
		}
		struct insn in;
		const char *err = NULL;
		if (!encode(nd, rvc, &in, &err)) {
			fprintf(stderr, "ttpc: cannot assemble '%s': %s\n",
				nd->content, err ? err : "unsupported");
			errors++;
			continue;
		}
		unsigned char buf[4];
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
		if (!in_path) {
			fprintf(stderr, "usage: ttpc -a [-v] <program.nodes>\n");
			return EXIT_FAILURE;
		}
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

	char          line[512];
	struct stats  st = {0};
	unsigned long load_base = 0;     /* runtime address of file offset 0 */
	int           in_text   = 0;     /* inside "section .text"           */

	struct insn cur;                 /* instruction being assembled      */
	int         have     = 0;        /* cur holds a pending instruction  */
	int         cur_text = 0;        /* in_text when cur was read        */

	while (fgets(line, sizeof line, in)) {
		const char *p;
		if ((p = strstr(line, "loads @")))
			load_base = strtoul(p + 7, NULL, 16);
		if (!strncmp(line, "Disassembly of section ", 23))
			in_text = strstr(line, ".text") != NULL;

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
		    emit_insn(&cur, cur_text, load_base, out, verbose, &st) < 0) {
			fclose(in);
			fclose(out);
			return EXIT_FAILURE;
		}

		cur      = tmp;
		cur_text = in_text;
		have     = 1;
	}
	if (have &&
	    emit_insn(&cur, cur_text, load_base, out, verbose, &st) < 0) {
		fclose(in);
		fclose(out);
		return EXIT_FAILURE;
	}

	/* Pad to 1 MiB; the gaps left by objdump's collapsed zero runs become
	 * zero holes, exactly the padding the image needs. */
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
		"(%d decoded, %d passed through, %d failed; "
		"%d/%d .text lines re-encoded)\n",
		st.count, out_path, st.decoded, st.passthru, st.fails,
		st.enc_ok, st.enc_total);

	return st.fails ? EXIT_FAILURE : EXIT_SUCCESS;
}
