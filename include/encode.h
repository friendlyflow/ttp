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
 * encode.h — the x86-64 instruction encoder, shared by the host compiler (ttpc)
 * and the OS. A `struct insn` is an instruction broken into its fields; encode()
 * fills one from a node tree and assemble() lays the fields out as bytes. The
 * host's decoder (main.c) fills the same struct from bytes, so the two agree on
 * instruction shape. Compiling this one file into both builds keeps the
 * self-hosted compiler and the verified host baseline from diverging.
 */
#ifndef TTP_ENCODE_H
#define TTP_ENCODE_H

struct node;   /* defined in node.h */

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

/* Lay an insn's fields out as machine-code bytes (canonical x86 order). Returns
   the byte count (at most 16, the size of a caller-supplied buf). */
int assemble(const struct insn *in, unsigned char *buf);

/* Encode an instruction node — mnemonic in content, operands as children — for
   CPU mode `mode` (16/32/64) into *out. Returns 1 on success; on failure returns
   0 and points *err at a message. */
int encode(struct node *nd, int mode, struct insn *out, const char **err);

#endif /* TTP_ENCODE_H */
