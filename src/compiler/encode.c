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
 * encode.c — node tree -> RISC-V machine code, the inverse of main.c's decode().
 *
 * An instruction node carries the mnemonic in its content and its operands as
 * children. Operands are leaf nodes — a register ("a0", "sp", "x5"), a CSR name
 * ("mtvec"), or an immediate literal ("-16", "0x10000") — or a "mem" node with
 * children `base offset` for a load/store address: `ld a0, 8(sp)` is the node
 * "ld" with children "a0" and mem("sp", "8"). Branch and jump targets are
 * pc-relative offsets. The common pseudo-instructions (li, mv, j, ret, beqz,
 * csrr, ...) expand to their base instruction first.
 *
 * Everything is driven by one opcode table, rv_ops: the decoder matches bytes
 * against it and the encoder looks mnemonics up in it, and both go through
 * rv_fields() / assemble() for the bit layouts, so the encoder and decoder share
 * one notion of instruction shape. This file is compiled into both the host
 * ttpc and (later) the OS; the only difference is where the small libc subset
 * below comes from.
 */
#include <encode.h>
#include <node.h>
#include <stddef.h>
#include <stdint.h>

#ifdef TTP_HOSTED
  #include <string.h>
  #include <stdlib.h>
#else
  /* Freestanding: the OS implements these (string.c). */
  int        strcmp(const char *, const char *);
  int        strncmp(const char *, const char *, size_t);
  void      *memset(void *, int, size_t);
  long long  strtoll(const char *, char **, int);
#endif

/*
 * Operand spec letters (rv_op.args), one per operand, in assembler order:
 *   d rd   s rs1   t rs2   D rd, which is also rs1 (compressed two-address forms)
 *   j I-immediate          u U-immediate (20-bit field)   > shift amount
 *   m mem(base, offset) -> rs1, imm (a bare register means offset 0)
 *   A mem(base) with no offset -> rs1 (atomics)
 *   p branch offset        a jump offset (both pc-relative)
 *   E CSR (name or number) Z 5-bit CSR immediate, lives in rs1
 *   P Q fence predecessor / successor set ("iorw" letters)
 */

#define MR   0xfe00707fu   /* funct7 + funct3 + opcode          */
#define MI   0x0000707fu   /* funct3 + opcode                   */
#define MSH  0xfc00707fu   /* funct6 + funct3 + opcode          */
#define MO   0x0000007fu   /* opcode                            */
#define MALL 0xffffffffu   /* every bit fixed                   */
#define MAMO 0xf800707fu   /* funct5 + funct3 + opcode; aq/rl free */
#define MLR  0xf9f0707fu   /* ... and rs2 = 0                   */

#define ENC(f7, f3, op) (((uint32_t)(f7) << 25) | ((uint32_t)(f3) << 12) | (op))

#define OP(n, m, x, f, a) \
	{ n, m, x, f, a, NULL, K_ANY, K_ANY, K_ANY, 0, 0, 0, 0 }
#define AMO(n, f5, f3) \
	OP(n, MAMO, ((uint32_t)(f5) << 27) | ENC(0, f3, 0x2f), RV_R, "dtA")
#define C(n, m, x, f, a, b, rd, rs1, rs2, lo, hi, al, nz) \
	{ n, m, x, f, a, b, rd, rs1, rs2, lo, hi, al, nz }

const struct rv_op rv_ops[] = {
	/* ---- RV64I -------------------------------------------------------- */
	OP("lui",    MO, 0x37, RV_U, "du"),
	OP("auipc",  MO, 0x17, RV_U, "du"),
	OP("jal",    MO, 0x6f, RV_J, "da"),
	OP("jalr",   MI, ENC(0, 0, 0x67), RV_I, "dm"),
	OP("beq",    MI, ENC(0, 0, 0x63), RV_B, "stp"),
	OP("bne",    MI, ENC(0, 1, 0x63), RV_B, "stp"),
	OP("blt",    MI, ENC(0, 4, 0x63), RV_B, "stp"),
	OP("bge",    MI, ENC(0, 5, 0x63), RV_B, "stp"),
	OP("bltu",   MI, ENC(0, 6, 0x63), RV_B, "stp"),
	OP("bgeu",   MI, ENC(0, 7, 0x63), RV_B, "stp"),
	OP("lb",     MI, ENC(0, 0, 0x03), RV_I, "dm"),
	OP("lh",     MI, ENC(0, 1, 0x03), RV_I, "dm"),
	OP("lw",     MI, ENC(0, 2, 0x03), RV_I, "dm"),
	OP("ld",     MI, ENC(0, 3, 0x03), RV_I, "dm"),
	OP("lbu",    MI, ENC(0, 4, 0x03), RV_I, "dm"),
	OP("lhu",    MI, ENC(0, 5, 0x03), RV_I, "dm"),
	OP("lwu",    MI, ENC(0, 6, 0x03), RV_I, "dm"),
	OP("sb",     MI, ENC(0, 0, 0x23), RV_S, "tm"),
	OP("sh",     MI, ENC(0, 1, 0x23), RV_S, "tm"),
	OP("sw",     MI, ENC(0, 2, 0x23), RV_S, "tm"),
	OP("sd",     MI, ENC(0, 3, 0x23), RV_S, "tm"),
	OP("addi",   MI, ENC(0, 0, 0x13), RV_I, "dsj"),
	OP("slti",   MI, ENC(0, 2, 0x13), RV_I, "dsj"),
	OP("sltiu",  MI, ENC(0, 3, 0x13), RV_I, "dsj"),
	OP("xori",   MI, ENC(0, 4, 0x13), RV_I, "dsj"),
	OP("ori",    MI, ENC(0, 6, 0x13), RV_I, "dsj"),
	OP("andi",   MI, ENC(0, 7, 0x13), RV_I, "dsj"),
	OP("slli",   MSH, ENC(0x00, 1, 0x13), RV_ISH, "ds>"),
	OP("srli",   MSH, ENC(0x00, 5, 0x13), RV_ISH, "ds>"),
	OP("srai",   MSH, ENC(0x20, 5, 0x13), RV_ISH, "ds>"),
	OP("add",    MR, ENC(0x00, 0, 0x33), RV_R, "dst"),
	OP("sub",    MR, ENC(0x20, 0, 0x33), RV_R, "dst"),
	OP("sll",    MR, ENC(0x00, 1, 0x33), RV_R, "dst"),
	OP("slt",    MR, ENC(0x00, 2, 0x33), RV_R, "dst"),
	OP("sltu",   MR, ENC(0x00, 3, 0x33), RV_R, "dst"),
	OP("xor",    MR, ENC(0x00, 4, 0x33), RV_R, "dst"),
	OP("srl",    MR, ENC(0x00, 5, 0x33), RV_R, "dst"),
	OP("sra",    MR, ENC(0x20, 5, 0x33), RV_R, "dst"),
	OP("or",     MR, ENC(0x00, 6, 0x33), RV_R, "dst"),
	OP("and",    MR, ENC(0x00, 7, 0x33), RV_R, "dst"),
	OP("addiw",  MI, ENC(0, 0, 0x1b), RV_I, "dsj"),
	OP("slliw",  MR, ENC(0x00, 1, 0x1b), RV_ISH, "ds>"),
	OP("srliw",  MR, ENC(0x00, 5, 0x1b), RV_ISH, "ds>"),
	OP("sraiw",  MR, ENC(0x20, 5, 0x1b), RV_ISH, "ds>"),
	OP("addw",   MR, ENC(0x00, 0, 0x3b), RV_R, "dst"),
	OP("subw",   MR, ENC(0x20, 0, 0x3b), RV_R, "dst"),
	OP("sllw",   MR, ENC(0x00, 1, 0x3b), RV_R, "dst"),
	OP("srlw",   MR, ENC(0x00, 5, 0x3b), RV_R, "dst"),
	OP("sraw",   MR, ENC(0x20, 5, 0x3b), RV_R, "dst"),
	OP("fence",  0x000fffffu, ENC(0, 0, 0x0f), RV_IU, "PQ"),
	OP("fence.i", MALL, ENC(0, 1, 0x0f), RV_IU, ""),
	OP("ecall",  MALL, 0x00000073, RV_I, ""),
	OP("ebreak", MALL, 0x00100073, RV_I, ""),
	OP("sret",   MALL, 0x10200073, RV_I, ""),
	OP("mret",   MALL, 0x30200073, RV_I, ""),
	OP("wfi",    MALL, 0x10500073, RV_I, ""),
	OP("sfence.vma", 0xfe007fffu, ENC(0x09, 0, 0x73), RV_R, "st"),

	/* ---- Zicsr -------------------------------------------------------- */
	OP("csrrw",  MI, ENC(0, 1, 0x73), RV_IU, "dEs"),
	OP("csrrs",  MI, ENC(0, 2, 0x73), RV_IU, "dEs"),
	OP("csrrc",  MI, ENC(0, 3, 0x73), RV_IU, "dEs"),
	OP("csrrwi", MI, ENC(0, 5, 0x73), RV_IU, "dEZ"),
	OP("csrrsi", MI, ENC(0, 6, 0x73), RV_IU, "dEZ"),
	OP("csrrci", MI, ENC(0, 7, 0x73), RV_IU, "dEZ"),

	/* ---- M ------------------------------------------------------------ */
	OP("mul",    MR, ENC(0x01, 0, 0x33), RV_R, "dst"),
	OP("mulh",   MR, ENC(0x01, 1, 0x33), RV_R, "dst"),
	OP("mulhsu", MR, ENC(0x01, 2, 0x33), RV_R, "dst"),
	OP("mulhu",  MR, ENC(0x01, 3, 0x33), RV_R, "dst"),
	OP("div",    MR, ENC(0x01, 4, 0x33), RV_R, "dst"),
	OP("divu",   MR, ENC(0x01, 5, 0x33), RV_R, "dst"),
	OP("rem",    MR, ENC(0x01, 6, 0x33), RV_R, "dst"),
	OP("remu",   MR, ENC(0x01, 7, 0x33), RV_R, "dst"),
	OP("mulw",   MR, ENC(0x01, 0, 0x3b), RV_R, "dst"),
	OP("divw",   MR, ENC(0x01, 4, 0x3b), RV_R, "dst"),
	OP("divuw",  MR, ENC(0x01, 5, 0x3b), RV_R, "dst"),
	OP("remw",   MR, ENC(0x01, 6, 0x3b), RV_R, "dst"),
	OP("remuw",  MR, ENC(0x01, 7, 0x3b), RV_R, "dst"),

	/* ---- A (aq/rl: a ".aq" / ".rl" / ".aqrl" mnemonic suffix) ---------- */
	OP("lr.w", MLR, ((uint32_t)0x02 << 27) | ENC(0, 2, 0x2f), RV_R, "dA"),
	OP("lr.d", MLR, ((uint32_t)0x02 << 27) | ENC(0, 3, 0x2f), RV_R, "dA"),
	AMO("sc.w", 0x03, 2),      AMO("sc.d", 0x03, 3),
	AMO("amoswap.w", 0x01, 2), AMO("amoswap.d", 0x01, 3),
	AMO("amoadd.w", 0x00, 2),  AMO("amoadd.d", 0x00, 3),
	AMO("amoxor.w", 0x04, 2),  AMO("amoxor.d", 0x04, 3),
	AMO("amoand.w", 0x0c, 2),  AMO("amoand.d", 0x0c, 3),
	AMO("amoor.w", 0x08, 2),   AMO("amoor.d", 0x08, 3),
	AMO("amomin.w", 0x10, 2),  AMO("amomin.d", 0x10, 3),
	AMO("amomax.w", 0x14, 2),  AMO("amomax.d", 0x14, 3),
	AMO("amominu.w", 0x18, 2), AMO("amominu.d", 0x18, 3),
	AMO("amomaxu.w", 0x1c, 2), AMO("amomaxu.d", 0x1c, 3),

	/* ---- C (RV64, integer) --------------------------------------------
	 * Constraints are on the 32-bit expansion's fields. Order matters twice:
	 * the decoder takes the first entry that matches *and* fits, and the
	 * compressor tries entries in order (c.addi before c.addi16sp, as GNU as
	 * does for `addi sp,sp,-16`). */
	C("c.addi4spn", 0xe003, 0x0000, C_CIW, "dsj", "addi", K_P, K_SP, K_Z, 4, 1020, 4, 1),
	C("c.lw",   0xe003, 0x4000, C_CLW, "dm", "lw", K_P, K_P, K_Z, 0, 124, 4, 0),
	C("c.ld",   0xe003, 0x6000, C_CLD, "dm", "ld", K_P, K_P, K_Z, 0, 248, 8, 0),
	C("c.sw",   0xe003, 0xc000, C_CSW, "tm", "sw", K_Z, K_P, K_P, 0, 124, 4, 0),
	C("c.sd",   0xe003, 0xe000, C_CSD, "tm", "sd", K_Z, K_P, K_P, 0, 248, 8, 0),
	C("c.nop",  0xef83, 0x0001, C_CI, "", "addi", K_Z, K_Z, K_Z, 0, 0, 1, 0),
	C("c.addi", 0xe003, 0x0001, C_CI, "Dj", "addi", K_NZ, K_RD, K_Z, -32, 31, 1, 1),
	C("c.addiw", 0xe003, 0x2001, C_CI, "Dj", "addiw", K_NZ, K_RD, K_Z, -32, 31, 1, 0),
	C("c.li",   0xe003, 0x4001, C_CI, "dj", "addi", K_NZ, K_Z, K_Z, -32, 31, 1, 0),
	C("c.addi16sp", 0xef83, 0x6101, C_ADDI16SP, "Dj", "addi", K_SP, K_RD, K_Z, -512, 496, 16, 1),
	C("c.lui",  0xe003, 0x6001, C_LUI, "du", "lui", K_NZSP, K_Z, K_Z, -32, 31, 1, 1),
	C("c.srli", 0xec03, 0x8001, C_CBSH, "D>", "srli", K_P, K_RD, K_Z, 1, 63, 1, 0),
	C("c.srai", 0xec03, 0x8401, C_CBSH, "D>", "srai", K_P, K_RD, K_Z, 1, 63, 1, 0),
	C("c.andi", 0xec03, 0x8801, C_CBI, "Dj", "andi", K_P, K_RD, K_Z, -32, 31, 1, 0),
	C("c.sub",  0xfc63, 0x8c01, C_CA, "Dt", "sub",  K_P, K_RD, K_P, 0, 0, 1, 0),
	C("c.xor",  0xfc63, 0x8c21, C_CA, "Dt", "xor",  K_P, K_RD, K_P, 0, 0, 1, 0),
	C("c.or",   0xfc63, 0x8c41, C_CA, "Dt", "or",   K_P, K_RD, K_P, 0, 0, 1, 0),
	C("c.and",  0xfc63, 0x8c61, C_CA, "Dt", "and",  K_P, K_RD, K_P, 0, 0, 1, 0),
	C("c.subw", 0xfc63, 0x9c01, C_CA, "Dt", "subw", K_P, K_RD, K_P, 0, 0, 1, 0),
	C("c.addw", 0xfc63, 0x9c21, C_CA, "Dt", "addw", K_P, K_RD, K_P, 0, 0, 1, 0),
	C("c.j",    0xe003, 0xa001, C_CJ, "a", "jal", K_Z, K_Z, K_Z, -2048, 2046, 2, 0),
	C("c.beqz", 0xe003, 0xc001, C_CBB, "sp", "beq", K_Z, K_P, K_Z, -256, 254, 2, 0),
	C("c.bnez", 0xe003, 0xe001, C_CBB, "sp", "bne", K_Z, K_P, K_Z, -256, 254, 2, 0),
	C("c.slli", 0xe003, 0x0002, C_CISH, "D>", "slli", K_NZ, K_RD, K_Z, 1, 63, 1, 0),
	C("c.lwsp", 0xe003, 0x4002, C_LWSP, "dm", "lw", K_NZ, K_SP, K_Z, 0, 252, 4, 0),
	C("c.ldsp", 0xe003, 0x6002, C_LDSP, "dm", "ld", K_NZ, K_SP, K_Z, 0, 504, 8, 0),
	C("c.jr",   0xf07f, 0x8002, C_CRJ, "s", "jalr", K_Z, K_NZ, K_Z, 0, 0, 1, 0),
	C("c.mv",   0xf003, 0x8002, C_CRM, "dt", "add", K_NZ, K_Z, K_NZ, 0, 0, 1, 0),
	C("c.ebreak", 0xffff, 0x9002, C_CRJ, "", "ebreak", K_Z, K_Z, K_Z, 1, 1, 1, 0),
	C("c.jalr", 0xf07f, 0x9002, C_CRJ, "s", "jalr", K_RA, K_NZ, K_Z, 0, 0, 1, 0),
	C("c.add",  0xf003, 0x9002, C_CRM, "Dt", "add", K_NZ, K_RD, K_NZ, 0, 0, 1, 0),
	C("c.swsp", 0xe003, 0xc002, C_SWSP, "tm", "sw", K_Z, K_SP, K_ANY, 0, 252, 4, 0),
	C("c.sdsp", 0xe003, 0xe002, C_SDSP, "tm", "sd", K_Z, K_SP, K_ANY, 0, 504, 8, 0),

	OP(NULL, 0, 0, 0, NULL)
};

const char *const rv_abi[32] = {
	"zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
	"s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
	"a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
	"s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6",
};

static const struct { const char *name; int csr; } CSRS[] = {
	{"fflags", 0x001}, {"frm", 0x002}, {"fcsr", 0x003},
	{"cycle", 0xc00}, {"time", 0xc01}, {"instret", 0xc02},
	{"sstatus", 0x100}, {"sie", 0x104}, {"stvec", 0x105},
	{"scounteren", 0x106}, {"senvcfg", 0x10a}, {"sscratch", 0x140},
	{"sepc", 0x141}, {"scause", 0x142}, {"stval", 0x143}, {"sip", 0x144},
	{"satp", 0x180},
	{"mstatus", 0x300}, {"misa", 0x301}, {"medeleg", 0x302},
	{"mideleg", 0x303}, {"mie", 0x304}, {"mtvec", 0x305},
	{"mcounteren", 0x306}, {"menvcfg", 0x30a}, {"mscratch", 0x340},
	{"mepc", 0x341}, {"mcause", 0x342}, {"mtval", 0x343}, {"mip", 0x344},
	{"mtinst", 0x34a}, {"mtval2", 0x34b},
	{"pmpcfg0", 0x3a0}, {"pmpcfg2", 0x3a2}, {"pmpaddr0", 0x3b0},
	{"pmpaddr1", 0x3b1}, {"pmpaddr2", 0x3b2}, {"pmpaddr3", 0x3b3},
	{"mcycle", 0xb00}, {"minstret", 0xb02},
	{"mvendorid", 0xf11}, {"marchid", 0xf12}, {"mimpid", 0xf13},
	{"mhartid", 0xf14}, {"mconfigptr", 0xf15},
};

const char *rv_csr_name(int csr)
{
	for (size_t i = 0; i < sizeof CSRS / sizeof CSRS[0]; i++)
		if (CSRS[i].csr == csr)
			return CSRS[i].name;
	return NULL;
}

const struct rv_op *rv_find(const char *name)
{
	for (const struct rv_op *op = rv_ops; op->name; op++)
		if (!RV_IS_C(op->fmt) && !strcmp(op->name, name))
			return op;
	return NULL;
}

/* ---- field layouts ------------------------------------------------------ */

/* Bits hi..lo of w, shifted down. */
static uint32_t bits(uint32_t w, int hi, int lo)
{
	return (w >> lo) & ((1u << (hi - lo + 1)) - 1);
}

/* Sign-extend the low n bits of v. */
static long sx(uint32_t v, int n)
{
	long m = 1L << (n - 1);
	return ((long)(v & ((1u << n) - 1)) ^ m) - m;
}

/* The fixed (non-operand) fields: opcode and functs. */
static void fields_funct(int fmt, uint32_t w, struct insn *in)
{
	in->opcode = in->funct3 = in->funct7 = in->funct2 = 0;
	if (!RV_IS_C(fmt)) {
		in->opcode = bits(w, 6, 0);
		if (fmt != RV_U && fmt != RV_J)
			in->funct3 = bits(w, 14, 12);
		if (fmt == RV_R)
			in->funct7 = bits(w, 31, 25);
		if (fmt == RV_ISH)
			in->funct7 = bits(w, 31, 26);
		return;
	}
	in->opcode = bits(w, 1, 0);
	in->funct3 = bits(w, 15, 13);
	if (fmt == C_CRJ || fmt == C_CRM)
		in->funct7 = bits(w, 15, 12);
	if (fmt == C_CA) {
		in->funct7 = bits(w, 15, 10);
		in->funct2 = bits(w, 6, 5);
	}
	if (fmt == C_CBSH || fmt == C_CBI)
		in->funct2 = bits(w, 11, 10);
}

void rv_fields(const struct rv_op *op, uint32_t w, struct insn *in)
{
	int fmt = op->fmt;

	in->op  = op;
	in->fmt = fmt;
	in->len = RV_IS_C(fmt) ? 2 : 4;
	in->rd = in->rs1 = in->rs2 = 0;
	in->imm = 0;
	fields_funct(fmt, w, in);

	int rd = bits(w, 11, 7), rs1 = bits(w, 19, 15), rs2 = bits(w, 24, 20);
	int cr = bits(w, 11, 7), cs = bits(w, 6, 2);           /* full regs     */
	int ch = 8 + bits(w, 9, 7), cl = 8 + bits(w, 4, 2);    /* rd'/rs1'/rs2' */

	switch (fmt) {
	case RV_R:   in->rd = rd; in->rs1 = rs1; in->rs2 = rs2; break;
	case RV_I:   in->rd = rd; in->rs1 = rs1; in->imm = sx(w >> 20, 12); break;
	case RV_IU:  in->rd = rd; in->rs1 = rs1; in->imm = bits(w, 31, 20); break;
	case RV_ISH: in->rd = rd; in->rs1 = rs1; in->imm = bits(w, 25, 20); break;
	case RV_S:
		in->rs1 = rs1; in->rs2 = rs2;
		in->imm = sx(bits(w, 31, 25) << 5 | bits(w, 11, 7), 12);
		break;
	case RV_B:
		in->rs1 = rs1; in->rs2 = rs2;
		in->imm = sx(bits(w, 31, 31) << 12 | bits(w, 7, 7) << 11 |
			     bits(w, 30, 25) << 5 | bits(w, 11, 8) << 1, 13);
		break;
	case RV_U:   in->rd = rd; in->imm = bits(w, 31, 12); break;
	case RV_J:
		in->rd = rd;
		in->imm = sx(bits(w, 31, 31) << 20 | bits(w, 19, 12) << 12 |
			     bits(w, 20, 20) << 11 | bits(w, 30, 21) << 1, 21);
		break;

	case C_CIW:
		in->rd = cl; in->rs1 = 2;
		in->imm = bits(w, 12, 11) << 4 | bits(w, 10, 7) << 6 |
			  bits(w, 6, 6) << 2 | bits(w, 5, 5) << 3;
		break;
	case C_CLW: case C_CSW:
		if (fmt == C_CLW) in->rd = cl; else in->rs2 = cl;
		in->rs1 = ch;
		in->imm = bits(w, 12, 10) << 3 | bits(w, 6, 6) << 2 | bits(w, 5, 5) << 6;
		break;
	case C_CLD: case C_CSD:
		if (fmt == C_CLD) in->rd = cl; else in->rs2 = cl;
		in->rs1 = ch;
		in->imm = bits(w, 12, 10) << 3 | bits(w, 6, 5) << 6;
		break;
	case C_CI:
		in->rd = cr;
		in->imm = sx(bits(w, 12, 12) << 5 | bits(w, 6, 2), 6);
		break;
	case C_ADDI16SP:
		in->rd = cr;
		in->imm = sx(bits(w, 12, 12) << 9 | bits(w, 6, 6) << 4 |
			     bits(w, 5, 5) << 6 | bits(w, 4, 3) << 7 |
			     bits(w, 2, 2) << 5, 10);
		break;
	case C_LUI:
		in->rd = cr;
		in->imm = sx(bits(w, 12, 12) << 5 | bits(w, 6, 2), 6) & 0xfffff;
		break;
	case C_CISH:
		in->rd = cr;
		in->imm = bits(w, 12, 12) << 5 | bits(w, 6, 2);
		break;
	case C_LWSP:
		in->rd = cr; in->rs1 = 2;
		in->imm = bits(w, 12, 12) << 5 | bits(w, 6, 4) << 2 | bits(w, 3, 2) << 6;
		break;
	case C_LDSP:
		in->rd = cr; in->rs1 = 2;
		in->imm = bits(w, 12, 12) << 5 | bits(w, 6, 5) << 3 | bits(w, 4, 2) << 6;
		break;
	case C_SWSP:
		in->rs2 = cs; in->rs1 = 2;
		in->imm = bits(w, 12, 9) << 2 | bits(w, 8, 7) << 6;
		break;
	case C_SDSP:
		in->rs2 = cs; in->rs1 = 2;
		in->imm = bits(w, 12, 10) << 3 | bits(w, 9, 7) << 6;
		break;
	case C_CBSH:
		in->rd = ch;
		in->imm = bits(w, 12, 12) << 5 | bits(w, 6, 2);
		break;
	case C_CBI:
		in->rd = ch;
		in->imm = sx(bits(w, 12, 12) << 5 | bits(w, 6, 2), 6);
		break;
	case C_CA:   in->rd = ch; in->rs2 = cl; break;
	case C_CJ:
		in->imm = sx(bits(w, 12, 12) << 11 | bits(w, 11, 11) << 4 |
			     bits(w, 10, 9) << 8 | bits(w, 8, 8) << 10 |
			     bits(w, 7, 7) << 6 | bits(w, 6, 6) << 7 |
			     bits(w, 5, 3) << 1 | bits(w, 2, 2) << 5, 12);
		break;
	case C_CBB:
		in->rs1 = ch;
		in->imm = sx(bits(w, 12, 12) << 8 | bits(w, 11, 10) << 3 |
			     bits(w, 6, 5) << 6 | bits(w, 4, 3) << 1 |
			     bits(w, 2, 2) << 5, 9);
		break;
	case C_CRJ:  in->rs1 = cr; in->rs2 = cs; break;
	case C_CRM:  in->rd = cr; in->rs2 = cs; break;
	}

	/* Fields a compressed layout leaves implicit follow from its constraints,
	   so the fields describe the 32-bit expansion. */
	if (RV_IS_C(fmt)) {
		if (op->rs1 == K_RD)
			in->rs1 = in->rd;
		if (op->rd == K_RA)
			in->rd = 1;
		if (fmt == C_CRJ || fmt == C_CRM || fmt == C_CA)
			in->imm = op->lo;           /* c.ebreak's expansion: imm 1 */
	}
}

static int reg_ok(int k, int r, int rd)
{
	switch (k) {
	case K_ANY:  return 1;
	case K_Z:    return r == 0;
	case K_NZ:   return r != 0;
	case K_P:    return r >= 8 && r <= 15;
	case K_SP:   return r == 2;
	case K_RA:   return r == 1;
	case K_RD:   return r == rd;
	case K_NZSP: return r != 0 && r != 2;
	}
	return 0;
}

int rv_fits(const struct rv_op *op, const struct insn *in)
{
	if (!reg_ok(op->rd, in->rd, 0) || !reg_ok(op->rs1, in->rs1, in->rd) ||
	    !reg_ok(op->rs2, in->rs2, 0))
		return 0;
	long v = in->imm;
	if (op->fmt == C_LUI)
		v = sx((uint32_t)v, 20);            /* the 20-bit field, signed */
	return v >= op->lo && v <= op->hi && v % op->align == 0 &&
	       (!op->nz || v != 0);
}

/* Reassemble fields back into bytes: the inverse of rv_fields(). */
int assemble(const struct insn *in, unsigned char *buf)
{
	uint32_t u = (uint32_t)in->imm;
	uint32_t rd = in->rd, rs1 = in->rs1, rs2 = in->rs2;
	uint32_t w;

	if (!RV_IS_C(in->fmt)) {
		w = in->opcode | rd << 7 | in->funct3 << 12 | rs1 << 15 | rs2 << 20;
		switch (in->fmt) {
		case RV_R:   w |= in->funct7 << 25; break;
		case RV_I: case RV_IU:
			w = in->opcode | rd << 7 | in->funct3 << 12 | rs1 << 15 |
			    bits(u, 11, 0) << 20;
			break;
		case RV_ISH:
			w = in->opcode | rd << 7 | in->funct3 << 12 | rs1 << 15 |
			    bits(u, 5, 0) << 20 | in->funct7 << 26;
			break;
		case RV_S:
			w = in->opcode | bits(u, 4, 0) << 7 | in->funct3 << 12 |
			    rs1 << 15 | rs2 << 20 | bits(u, 11, 5) << 25;
			break;
		case RV_B:
			w = in->opcode | bits(u, 11, 11) << 7 | bits(u, 4, 1) << 8 |
			    in->funct3 << 12 | rs1 << 15 | rs2 << 20 |
			    bits(u, 10, 5) << 25 | bits(u, 12, 12) << 31;
			break;
		case RV_U:
			w = in->opcode | rd << 7 | bits(u, 19, 0) << 12;
			break;
		case RV_J:
			w = in->opcode | rd << 7 | bits(u, 19, 12) << 12 |
			    bits(u, 11, 11) << 20 | bits(u, 10, 1) << 21 |
			    bits(u, 20, 20) << 31;
			break;
		}
	} else {
		uint32_t cl = (in->fmt == C_CLW || in->fmt == C_CLD) ? rd : rs2;

		w = in->opcode | in->funct3 << 13;
		switch (in->fmt) {
		case C_CIW:
			w |= (rd - 8) << 2 | bits(u, 3, 3) << 5 | bits(u, 2, 2) << 6 |
			     bits(u, 9, 6) << 7 | bits(u, 5, 4) << 11;
			break;
		case C_CLW: case C_CSW:
			w |= (cl - 8) << 2 | bits(u, 6, 6) << 5 | bits(u, 2, 2) << 6 |
			     (rs1 - 8) << 7 | bits(u, 5, 3) << 10;
			break;
		case C_CLD: case C_CSD:
			w |= (cl - 8) << 2 | bits(u, 7, 6) << 5 |
			     (rs1 - 8) << 7 | bits(u, 5, 3) << 10;
			break;
		case C_CI: case C_LUI: case C_CISH:
			w |= bits(u, 4, 0) << 2 | rd << 7 | bits(u, 5, 5) << 12;
			break;
		case C_ADDI16SP:
			w |= bits(u, 5, 5) << 2 | bits(u, 8, 7) << 3 | bits(u, 6, 6) << 5 |
			     bits(u, 4, 4) << 6 | rd << 7 | bits(u, 9, 9) << 12;
			break;
		case C_LWSP:
			w |= bits(u, 7, 6) << 2 | bits(u, 4, 2) << 4 | rd << 7 |
			     bits(u, 5, 5) << 12;
			break;
		case C_LDSP:
			w |= bits(u, 8, 6) << 2 | bits(u, 4, 3) << 5 | rd << 7 |
			     bits(u, 5, 5) << 12;
			break;
		case C_SWSP:
			w |= rs2 << 2 | bits(u, 7, 6) << 7 | bits(u, 5, 2) << 9;
			break;
		case C_SDSP:
			w |= rs2 << 2 | bits(u, 8, 6) << 7 | bits(u, 5, 3) << 10;
			break;
		case C_CBSH: case C_CBI:
			w |= bits(u, 4, 0) << 2 | (rd - 8) << 7 | in->funct2 << 10 |
			     bits(u, 5, 5) << 12;
			break;
		case C_CA:
			w |= (rs2 - 8) << 2 | in->funct2 << 5 | (rd - 8) << 7 |
			     in->funct7 << 10;
			break;
		case C_CJ:
			w |= bits(u, 5, 5) << 2 | bits(u, 3, 1) << 3 | bits(u, 7, 7) << 6 |
			     bits(u, 6, 6) << 7 | bits(u, 10, 10) << 8 |
			     bits(u, 9, 8) << 9 | bits(u, 4, 4) << 11 |
			     bits(u, 11, 11) << 12;
			break;
		case C_CBB:
			w |= bits(u, 5, 5) << 2 | bits(u, 2, 1) << 3 | bits(u, 7, 6) << 5 |
			     (rs1 - 8) << 7 | bits(u, 4, 3) << 10 | bits(u, 8, 8) << 12;
			break;
		case C_CRJ:
			w |= rs2 << 2 | rs1 << 7 | in->funct7 << 12;
			break;
		case C_CRM:
			w |= rs2 << 2 | rd << 7 | in->funct7 << 12;
			break;
		}
	}

	for (int k = 0; k < in->len; k++)
		buf[k] = (unsigned char)(w >> (8 * k));
	return in->len;
}

/* ---- encoder ------------------------------------------------------------ */

enum { OPD_REG, OPD_IMM, OPD_SYM, OPD_MEM };

struct operand {
	int         kind;   /* OPD_*                                  */
	int         reg;    /* register, or a mem operand's base      */
	long        imm;    /* immediate, or a mem operand's offset   */
	const char *sym;    /* a bare name: CSR, fence set            */
};

static int parse_reg(const char *s)
{
	for (int i = 0; i < 32; i++)
		if (!strcmp(s, rv_abi[i]))
			return i;
	if (!strcmp(s, "fp"))
		return 8;
	if (s[0] == 'x' && s[1] >= '0' && s[1] <= '9') {
		char *end;
		long n = strtoll(s + 1, &end, 10);
		if (*end == '\0' && n < 32)
			return (int)n;
	}
	return -1;
}

static int parse_num(const char *s, long *v)
{
	char *end;
	if (!*s)
		return 0;
	*v = (long)strtoll(s, &end, 0);
	return *end == '\0';
}

static int parse_operand(struct node *nd, struct operand *op, const char **err)
{
	memset(op, 0, sizeof *op);
	if (node_is(nd, "mem") && nd->n_children > 0) {
		op->kind = OPD_MEM;
		op->reg = parse_reg(nd->children[0]->content);
		if (op->reg < 0) { *err = "bad mem base register"; return 0; }
		if (nd->n_children > 1 && !parse_num(nd->children[1]->content, &op->imm)) {
			*err = "bad mem offset"; return 0;
		}
		return 1;
	}
	if ((op->reg = parse_reg(nd->content)) >= 0) {
		op->kind = OPD_REG;
		return 1;
	}
	if (parse_num(nd->content, &op->imm)) {
		op->kind = OPD_IMM;
		return 1;
	}
	op->kind = OPD_SYM;
	op->sym = nd->content;
	return 1;
}

/* A fence set: "iorw" letters -> bits i=8 o=4 r=2 w=1. */
static int fence_set(const char *s)
{
	int v = 0;
	for (; *s; s++) {
		if      (*s == 'i') v |= 8;
		else if (*s == 'o') v |= 4;
		else if (*s == 'r') v |= 2;
		else if (*s == 'w') v |= 1;
		else return -1;
	}
	return v;
}

/* Put operand o into the field(s) spec letter c names. */
static int put_arg(char c, const struct operand *o, struct insn *in, const char **err)
{
	switch (c) {
	case 'd': case 's': case 't': case 'D':
		if (o->kind != OPD_REG) { *err = "expected a register"; return 0; }
		if (c == 'd' || c == 'D') in->rd  = o->reg;
		if (c == 's' || c == 'D') in->rs1 = o->reg;
		if (c == 't')             in->rs2 = o->reg;
		return 1;
	case 'j': case 'u': case '>': case 'p': case 'a':
		if (o->kind != OPD_IMM) { *err = "expected an immediate"; return 0; }
		in->imm = o->imm;
		if (c == 'u' && in->imm < 0 && in->imm >= -0x80000)
			in->imm &= 0xfffff;     /* lui a0, -8 == lui a0, 0xffff8 */
		return 1;
	case 'm': case 'A':
		if (o->kind != OPD_MEM && o->kind != OPD_REG) {
			*err = "expected a memory operand"; return 0;
		}
		if (c == 'A' && o->imm) { *err = "atomics take no offset"; return 0; }
		in->rs1 = o->reg;
		if (c == 'm')
			in->imm = o->kind == OPD_MEM ? o->imm : 0;
		return 1;
	case 'E':
		if (o->kind == OPD_IMM) { in->imm = o->imm; return 1; }
		if (o->kind == OPD_SYM)
			for (size_t i = 0; i < sizeof CSRS / sizeof CSRS[0]; i++)
				if (!strcmp(o->sym, CSRS[i].name)) {
					in->imm = CSRS[i].csr;
					return 1;
				}
		*err = "unknown CSR";
		return 0;
	case 'Z':
		if (o->kind != OPD_IMM || o->imm < 0 || o->imm > 31) {
			*err = "CSR immediate must be 0..31"; return 0;
		}
		in->rs1 = (int)o->imm;
		return 1;
	case 'P': case 'Q': {
		int v = o->kind == OPD_SYM ? fence_set(o->sym) : -1;
		if (v < 0) { *err = "bad fence set"; return 0; }
		in->imm |= (c == 'P') ? v << 4 : v;
		return 1;
	}
	}
	*err = "bad operand spec";
	return 0;
}

/* Range-check a 32-bit instruction's immediate against its layout. */
static int imm_ok(const struct insn *in, const char **err)
{
	long v = in->imm;
	switch (in->fmt) {
	case RV_I: case RV_S:
		if (v < -2048 || v > 2047) { *err = "immediate out of range (12-bit)"; return 0; }
		break;
	case RV_IU:
		if (v < 0 || v > 4095) { *err = "CSR out of range"; return 0; }
		break;
	case RV_ISH:
		if (v < 0 || v > (in->opcode == 0x1b ? 31 : 63)) {
			*err = "shift amount out of range"; return 0;
		}
		break;
	case RV_B:
		if (v < -4096 || v > 4094 || (v & 1)) {
			*err = "branch offset out of range or odd"; return 0;
		}
		break;
	case RV_U:
		if (v < 0 || v > 0xfffff) { *err = "immediate out of range (20-bit)"; return 0; }
		break;
	case RV_J:
		if (v < -(1L << 20) || v > (1L << 20) - 2 || (v & 1)) {
			*err = "jump offset out of range or odd"; return 0;
		}
		break;
	}
	return 1;
}

/* Swap a 32-bit instruction for its compressed form when one fits. */
static void compress(struct insn *in)
{
	struct insn t = *in;
	const char *base = in->op->name;

	/* mv is addi rd,rs,0; RVC spells it c.mv, whose expansion is add rd,x0,rs. */
	if (!strcmp(base, "addi") && t.imm == 0 && t.rs1 != 0) {
		t.rs2 = t.rs1;
		t.rs1 = 0;
		base = "add";
	}
	for (const struct rv_op *c = rv_ops; c->name; c++) {
		if (!RV_IS_C(c->fmt) || strcmp(c->base, base) || !rv_fits(c, &t))
			continue;
		t.op  = c;
		t.fmt = c->fmt;
		t.len = 2;
		fields_funct(c->fmt, c->match, &t);
		*in = t;
		return;
	}
}

/*
 * Pseudo-instructions: `name` with `nops` operands is `base` with the operands
 * `tmpl` spells: '0'..'3' copy a pseudo operand, 'z' is x0, 'r' is ra, 'k' 'o'
 * 'm' 'f' are the immediates 0, 1, -1, 255, and 'w' is the fence set "iorw".
 */
static const struct { const char *name; int nops; const char *base, *tmpl; } PSEUDO[] = {
	{"nop",    0, "addi",   "zzk"},
	{"li",     2, "addi",   "0z1"},
	{"mv",     2, "addi",   "01k"},
	{"not",    2, "xori",   "01m"},
	{"neg",    2, "sub",    "0z1"},
	{"negw",   2, "subw",   "0z1"},
	{"sext.w", 2, "addiw",  "01k"},
	{"zext.b", 2, "andi",   "01f"},
	{"seqz",   2, "sltiu",  "01o"},
	{"snez",   2, "sltu",   "0z1"},
	{"sltz",   2, "slt",    "01z"},
	{"sgtz",   2, "slt",    "0z1"},
	{"beqz",   2, "beq",    "0z1"},
	{"bnez",   2, "bne",    "0z1"},
	{"blez",   2, "bge",    "z01"},
	{"bgez",   2, "bge",    "0z1"},
	{"bltz",   2, "blt",    "0z1"},
	{"bgtz",   2, "blt",    "z01"},
	{"bgt",    3, "blt",    "102"},
	{"ble",    3, "bge",    "102"},
	{"bgtu",   3, "bltu",   "102"},
	{"bleu",   3, "bgeu",   "102"},
	{"j",      1, "jal",    "z0"},
	{"jal",    1, "jal",    "r0"},
	{"jr",     1, "jalr",   "z0"},
	{"jalr",   1, "jalr",   "r0"},
	{"ret",    0, "jalr",   "zr"},
	{"csrr",   2, "csrrs",  "01z"},
	{"csrw",   2, "csrrw",  "z01"},
	{"csrs",   2, "csrrs",  "z01"},
	{"csrc",   2, "csrrc",  "z01"},
	{"csrwi",  2, "csrrwi", "z01"},
	{"csrsi",  2, "csrrsi", "z01"},
	{"csrci",  2, "csrrci", "z01"},
	{"fence",  0, "fence",  "ww"},
};

int encode(struct node *nd, int rvc, struct insn *out, const char **err)
{
	const char     *m = nd->content;
	struct operand  ops[4];
	int             nops = node_noperands(nd);  /* meta child, if any, is skipped */

	if (nops > 4) { *err = "too many operands"; return 0; }
	for (int i = 0; i < nops; i++)
		if (!parse_operand(node_operand(nd, i), &ops[i], err))
			return 0;

	/* Pseudo-instruction: rewrite into its base instruction's operands. */
	for (size_t p = 0; p < sizeof PSEUDO / sizeof PSEUDO[0]; p++) {
		if (strcmp(m, PSEUDO[p].name) || nops != PSEUDO[p].nops)
			continue;
		struct operand base[4];
		const char *t = PSEUDO[p].tmpl;
		int n = 0;
		for (; t[n]; n++) {
			struct operand *o = &base[n];
			memset(o, 0, sizeof *o);
			switch (t[n]) {
			case 'z': o->kind = OPD_REG; o->reg = 0;   break;
			case 'r': o->kind = OPD_REG; o->reg = 1;   break;
			case 'k': o->kind = OPD_IMM; o->imm = 0;   break;
			case 'o': o->kind = OPD_IMM; o->imm = 1;   break;
			case 'm': o->kind = OPD_IMM; o->imm = -1;  break;
			case 'f': o->kind = OPD_IMM; o->imm = 255; break;
			case 'w': o->kind = OPD_SYM; o->sym = "iorw"; break;
			default:  *o = ops[t[n] - '0'];            break;
			}
		}
		memcpy(ops, base, sizeof base);
		nops = n;
		m = PSEUDO[p].base;
		break;
	}

	/* Atomics' ordering suffix: .aq / .rl / .aqrl set funct7's low bits. */
	char name[24];
	unsigned aqrl = 0;
	size_t len = strlen(m);
	if (len >= sizeof name) { *err = "unsupported mnemonic"; return 0; }
	memcpy(name, m, len + 1);
	if (!strncmp(name, "amo", 3) || !strncmp(name, "lr.", 3) || !strncmp(name, "sc.", 3)) {
		static const struct { const char *sfx; unsigned bits; } SFX[] = {
			{".aqrl", 3}, {".aq", 2}, {".rl", 1},
		};
		for (int k = 0; k < 3; k++) {
			size_t sl = strlen(SFX[k].sfx);
			if (len > sl && !strcmp(name + len - sl, SFX[k].sfx)) {
				name[len - sl] = '\0';
				aqrl = SFX[k].bits;
				break;
			}
		}
	}

	/* Explicit c.* mnemonics are compressed entries; the rest are 32-bit. */
	const struct rv_op *op = NULL;
	for (const struct rv_op *o = rv_ops; o->name && !op; o++)
		if (!strcmp(o->name, name))
			op = o;
	if (!op) { *err = "unsupported mnemonic"; return 0; }
	if ((int)strlen(op->args) != nops) { *err = "wrong number of operands"; return 0; }

	/* Start from the entry's fixed bits (e.g. mret's funct12), then place
	   the operands. */
	memset(out, 0, sizeof *out);
	rv_fields(op, op->match, out);
	for (int i = 0; i < nops; i++)
		if (!put_arg(op->args[i], &ops[i], out, err))
			return 0;

	if (RV_IS_C(op->fmt)) {
		if (!rv_fits(op, out)) { *err = "operands do not fit this compressed form"; return 0; }
		return 1;
	}
	if (!imm_ok(out, err))
		return 0;
	out->funct7 |= aqrl;
	if (rvc)
		compress(out);
	return 1;
}
