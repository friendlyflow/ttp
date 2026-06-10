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

/*
 * Bootstrap stage: the "compiler" reads the OS boot-flow disassembly, breaks
 * each instruction into its component fields (the opcode in its own variable,
 * plus prefix / modrm / sib / disp / imm), reassembles the machine-code bytes,
 * and writes them into a binary image at each instruction's memory address.
 *
 * For now we assemble the first 3 instructions only. They are all simple 2-byte
 * register/register forms (byte[0] = opcode, byte[1] = modrm), so the decode is
 * trivial; real decoding for the rest of the ISA comes later (see PLAN.md).
 */
#define DEFAULT_INPUT  "src/os/boot_flow.txt"
#define DEFAULT_OUTPUT "build/compiler/ttpos.img"
#define INSN_LIMIT     3

struct insn {
	unsigned long addr;             /* memory address (load VMA) from file  */

	int           has_prefix;
	unsigned char prefix;
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
 * Parse one disassembly line into *out. Returns 1 if the line held an
 * instruction, 0 for headers / comments / labels / blanks.
 *
 * Instruction lines look like (leading whitespace, then):
 *   "7c00:\t31 c0                \txor    ax,ax"
 * i.e. <hexaddr> ':' TAB <space-separated hex bytes> TAB <mnem> <operands>.
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

	/* Mnemonic and operands (best-effort; purely informational here). */
	while (*p == '\t' || *p == ' ')
		p++;
	sscanf(p, "%15s %47[^\n]", out->mnem, out->ops);

	return 1;
}

/*
 * Decode the raw bytes into fields. Bootstrap rule for the first 3 (2-byte
 * reg/reg) instructions: opcode = raw[0], modrm = raw[1]; no prefix/sib/disp/
 * imm. Returns 0 if the instruction isn't in the supported shape.
 */
static int decode(struct insn *in)
{
	if (in->raw_len != 2)
		return 0;
	in->opcode    = in->raw[0];
	in->has_modrm = 1;
	in->modrm     = in->raw[1];
	return 1;
}

/* Reassemble fields back into bytes, in canonical x86 order. */
static int assemble(const struct insn *in, unsigned char *buf)
{
	int n = 0;
	if (in->has_prefix)
		buf[n++] = in->prefix;
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

int main(int argc, char **argv)
{
	const char *in_path  = (argc > 1) ? argv[1] : DEFAULT_INPUT;
	const char *out_path = (argc > 2) ? argv[2] : DEFAULT_OUTPUT;

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
	int  count = 0, fails = 0;

	while (count < INSN_LIMIT && fgets(line, sizeof line, in)) {
		struct insn ins;
		if (!parse_line(line, &ins))
			continue;

		if (!decode(&ins)) {
			fprintf(stderr, "ttpc: cannot decode insn at 0x%lx "
				"(%d raw bytes)\n", ins.addr, ins.raw_len);
			fails++;
			count++;
			continue;
		}

		unsigned char asm_buf[16];
		int asm_len = assemble(&ins, asm_buf);

		int pass = (asm_len == ins.raw_len &&
			memcmp(asm_buf, ins.raw, asm_len) == 0);

		/* Field breakdown, matching build/compiler/assembled.txt. */
		printf("addr=0x%lx  mnem=%s ops=%s\n", ins.addr, ins.mnem, ins.ops);
		printf("  ");
		print_byte("prefix", ins.has_prefix, ins.prefix);
		printf("opcode=0x%02x  ", ins.opcode);
		print_byte("modrm", ins.has_modrm, ins.modrm);
		print_byte("sib", ins.has_sib, ins.sib);
		printf("disp=0x0(%dB)  imm=0x0(%dB)\n", ins.disp_len, ins.imm_len);

		printf("  reassembled:");
		for (int i = 0; i < asm_len; i++)
			printf(" %02x", asm_buf[i]);
		printf("   original:");
		for (int i = 0; i < ins.raw_len; i++)
			printf(" %02x", ins.raw[i]);
		printf("   %s\n\n", pass ? "PASS" : "FAIL");

		/* Emit the bytes at the instruction's memory address. */
		if (fseek(out, (long)ins.addr, SEEK_SET) != 0 ||
		    fwrite(asm_buf, 1, asm_len, out) != (size_t)asm_len) {
			fprintf(stderr, "ttpc: write error at 0x%lx\n", ins.addr);
			fclose(in);
			fclose(out);
			return EXIT_FAILURE;
		}

		if (!pass)
			fails++;
		count++;
	}

	fclose(in);
	fclose(out);

	fprintf(stderr, "ttpc: assembled %d instruction(s) into '%s' (%d failed)\n",
		count, out_path, fails);

	return fails ? EXIT_FAILURE : EXIT_SUCCESS;
}
