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
 * encode.h — the RISC-V (RV64IMAC + Zicsr + Zifencei) instruction encoder,
 * shared by the host compiler (ttpc) and, later, the OS. A `struct insn` is an
 * instruction broken into its fields; encode() fills one from a node tree and
 * assemble() lays the fields out as bytes. The host's decoder (main.c) fills
 * the same struct from bytes through the same opcode table (rv_ops) and field
 * layouts (rv_fields), so the two agree on instruction shape. Compiling this
 * one file into both builds keeps the self-hosted compiler and the verified
 * host baseline from diverging.
 */
#ifndef TTP_ENCODE_H
#define TTP_ENCODE_H

#include <stdint.h>

struct node;   /* defined in node.h */

/*
 * Field layouts. The first group are the 32-bit base formats; the C_* group
 * are the 16-bit compressed layouts, one per distinct immediate scramble (RVC
 * scatters immediate bits differently per instruction, not per format).
 */
enum {
	RV_R,        /* funct7 rs2 rs1 funct3 rd opcode                      */
	RV_I,        /* imm[11:0] rs1 funct3 rd opcode, imm signed           */
	RV_IU,       /* same, imm unsigned: CSR number, fence fm/pred/succ   */
	RV_ISH,      /* funct6 shamt[5:0] rs1 funct3 rd opcode (RV64 shifts) */
	RV_S,        /* imm[11:5] rs2 rs1 funct3 imm[4:0] opcode             */
	RV_B,        /* branch: S with imm[12|10:5] / imm[4:1|11]            */
	RV_U,        /* imm[31:12] rd opcode, imm = the 20-bit field          */
	RV_J,        /* jal: imm[20|10:1|11|19:12] rd opcode                 */

	C_CIW,       /* c.addi4spn                                           */
	C_CLW,       /* c.lw                                                 */
	C_CLD,       /* c.ld                                                 */
	C_CSW,       /* c.sw                                                 */
	C_CSD,       /* c.sd                                                 */
	C_CI,        /* c.nop c.addi c.addiw c.li: signed imm[5:0]           */
	C_ADDI16SP,  /* c.addi16sp                                           */
	C_LUI,       /* c.lui                                                */
	C_CISH,      /* c.slli: shamt[5:0]                                   */
	C_LWSP,      /* c.lwsp                                               */
	C_LDSP,      /* c.ldsp                                               */
	C_SWSP,      /* c.swsp                                               */
	C_SDSP,      /* c.sdsp                                               */
	C_CBSH,      /* c.srli c.srai                                        */
	C_CBI,       /* c.andi                                               */
	C_CA,        /* c.sub c.xor c.or c.and c.subw c.addw                 */
	C_CJ,        /* c.j                                                  */
	C_CBB,       /* c.beqz c.bnez                                        */
	C_CRJ,       /* c.jr c.jalr c.ebreak: bits 11:7 are rs1              */
	C_CRM,       /* c.mv c.add: bits 11:7 are rd                         */
};
#define RV_IS_C(fmt) ((fmt) >= C_CIW)

/* Register constraints of a compressed instruction, checked by rv_fits(). */
enum { K_ANY, K_Z, K_NZ, K_P, K_SP, K_RA, K_RD, K_NZSP };

/*
 * One opcode-table entry: an encoding is this instruction when
 * (word & mask) == match. `args` spells its operands (see encode.c). A
 * compressed entry also names the 32-bit instruction it expands to and the
 * register/immediate constraints under which that expansion compresses.
 */
struct rv_op {
	const char  *name;
	uint32_t     mask, match;
	int          fmt;           /* RV_* / C_* field layout                */
	const char  *args;          /* operand spec                           */
	const char  *base;          /* compressed: the 32-bit expansion       */
	signed char  rd, rs1, rs2;  /* compressed: K_* register constraints   */
	int          lo, hi;        /* compressed: immediate range            */
	int          align, nz;     /* compressed: multiple of, must be != 0  */
};

/* The opcode table (32-bit entries, then compressed), ended by a NULL name. */
extern const struct rv_op rv_ops[];

struct insn {
	unsigned long       addr;       /* file offset, from the address column */

	const struct rv_op *op;         /* the table entry: name, layout, args  */
	int                 len;        /* 2 (compressed) or 4                  */
	int                 fmt;        /* RV_* / C_* field layout              */
	unsigned            opcode;     /* bits 6:0, or the quadrant bits 1:0   */
	unsigned            funct3;
	unsigned            funct7;     /* R: funct7, ISH: funct6, CR: funct4,
	                                   CA: funct6                           */
	unsigned            funct2;     /* CA: bits 6:5, CB: bits 11:10         */
	int                 rd, rs1, rs2;   /* x0..x31, also for rd'/rs1'/rs2'  */
	long                imm;        /* logical value: sign-extended and
	                                   un-scrambled (U: the 20-bit field)   */

	unsigned char       raw[24];    /* bytes as parsed (a .insn line can hold
	                                   up to 22), for the PASS check        */
	int                 raw_len;
	char                mnem[16];
	char                ops[64];
};

/* Fill in's fields from `word` laid out as table entry `op`. A compressed
   entry's implicit registers (e.g. c.addi's rs1 = rd) are filled in too, so
   the fields always describe the 32-bit expansion. */
void rv_fields(const struct rv_op *op, uint32_t word, struct insn *in);

/* Do the (expansion's) fields satisfy compressed entry op's constraints? */
int rv_fits(const struct rv_op *op, const struct insn *in);

/* The 32-bit entry named `name`, or NULL. */
const struct rv_op *rv_find(const char *name);

/* ABI register names (x0..x31), and a CSR number's name or NULL. */
extern const char *const rv_abi[32];
const char *rv_csr_name(int csr);

/* Lay an insn's fields out as machine-code bytes (little-endian). Returns the
   byte count: 2 or 4. */
int assemble(const struct insn *in, unsigned char *buf);

/* Encode an instruction node — mnemonic in content, operands as children —
   into *out. With rvc set it picks the compressed form whenever one fits, as
   GNU as does for a target with C. Returns 1 on success; on failure returns 0
   and points *err at a message. */
int encode(struct node *nd, int rvc, struct insn *out, const char **err);

#endif /* TTP_ENCODE_H */
