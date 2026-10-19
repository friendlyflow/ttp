// The GNU twin of simd.ff (written by mksimd.pl).
	.text
	.globl _start
_start:
	cmeq v3.16b, v1.16b, v0.16b
	cmhs v3.16b, v1.16b, v0.16b
	umaxp v3.16b, v1.16b, v0.16b
	uminp v3.16b, v1.16b, v0.16b
	addp v3.16b, v1.16b, v0.16b
	sshl v3.16b, v1.16b, v0.16b
	and v3.16b, v1.16b, v0.16b
	bic v3.16b, v1.16b, v0.16b
	orr v3.16b, v1.16b, v0.16b
	eor v3.16b, v1.16b, v0.16b
	bit v3.16b, v1.16b, v0.16b
	cmeq v12.16b, v30.16b, v7.16b
	umaxp v12.16b, v30.16b, v7.16b
	and v12.16b, v30.16b, v7.16b
	cmeq v3.16b, v1.16b, #0
	cmeq v3.8b, v1.8b, #0
	cmlt v2.16b, v31.16b, #0
	addhn v3.8b, v1.8h, v0.8h
	ushr v3.16b, v1.16b, #3
	ushr v3.16b, v1.16b, #8
	ushr v3.16b, v1.16b, #1
	shrn v3.8b, v1.8h, #2
	shrn v0.8b, v2.8h, #4
	dup v3.16b, w1
	dup v3.4s, w9
	movi v3.16b, #0x5a
	movi v29.16b, #0xff
	mvni v3.4s, #0x5a
	mvni v3.4s, #0x5a, lsl 8
	bic v3.8h, #0x5a
	bic v4.8h, #0xf, lsl 8
	tbl v3.16b, {v4.16b, v5.16b}, v1.16b
	ld1 {v3.16b}, [x1]
	ld1 {v3.16b}, [x1], #16
	ld1 {v3.16b, v4.16b}, [x1]
	ld1 {v30.16b, v31.16b}, [x5], #32
	ld1 {v3.2d, v4.2d}, [sp]
	ld1 {v3.2d, v4.2d}, [sp], #32
	ldr q3, [x1, #32]
	str q31, [sp, #65520]
	ldr q3, [x1, #32]!
	str q3, [x1, #-256]!
	ldr q3, [x1], #32
	str q3, [x1], #255
	ldr q3, [x1, x2]
	str q3, [x1, x2, lsl #4]
	ldur q3, [x1, #-3]
	stur q3, [x1, #17]
	ldp q3, q4, [x1, #32]
	stp q3, q4, [sp, #-1024]
	ldp q3, q4, [x1, #32]!
	stp q0, q0, [x1, #1008]!
	ldp q3, q4, [x1], #32
	stp q8, q9, [x2], #64
	str b3, [x1]
	ldr b3, [x1, #4095]
	stur h3, [x1, #-1]
	ldr h3, [x1, #8190]
	str s3, [x1, x2, lsl #2]
	ldnp x3, x4, [x1, #16]
	stnp x3, x4, [sp, #-512]
	prfm pstl1keep, [x3, #4352]
	prfm pldl1keep, [x3]
	bti
	bti c
	bti j
	bti jc
	paciasp
	autiasp
	hint 40
	dc zva, x3
	dc gva, x3
	dc gzva, x3
	sys #3, c7, c7, #2, x3
	sysl xzr, #3, c7, c7, #3
	sysl x4, #3, c7, c7, #1
	whilelo p1.b, x2, x3
	whilelo p15.b, x9, xzr
	ld1b {z3.b}, p1/z, [x1]
	ld1b {z3.b}, p1/z, [x1, #-2, mul vl]
	ld1b {z31.b}, p7/z, [sp, #7, mul vl]
	ld1b {z3.b}, p1/z, [x1, x2]
	st1b {z3.b}, p1, [x1, #-8, mul vl]
	st1b {z0.b}, p0, [x0]
	st1b {z3.b}, p1, [x1, x2]
	cmpne p2.b, p1/z, z3.b, z4.b
	cmphi p2.b, p1/z, z3.b, z4.b
	ptrue p2.b
	ptrue p9.b, vl1
	cntb x3
	cntb x3, all, mul #3
	dup z3.b, w1
	addsvl x3, x1, #-2
	addsvl sp, sp, #31
	str za[w13, 5], [x1, #5, mul vl]
	str za[w12, 0], [sp]
	smstop
	smstop za
	stg x3, [x1, #32]
	stg x3, [sp, #-4096]!
	stg sp, [x1], #4080
	stzg x3, [x1, #32]
	stzg x3, [sp, #-4096]!
	stzg sp, [x1], #4080
	st2g x3, [x1, #32]
	st2g x3, [sp, #-4096]!
	st2g sp, [x1], #4080
	stz2g x3, [x1, #32]
	stz2g x3, [sp, #-4096]!
	stz2g sp, [x1], #4080
	cpyfp [x3]!, [x1]!, x2!
	cpyfm [x3]!, [x1]!, x2!
	cpyfe [x3]!, [x1]!, x2!
	cpyp [x3]!, [x1]!, x2!
	cpym [x3]!, [x1]!, x2!
	cpye [x3]!, [x1]!, x2!
	setp [x3]!, x2!, x1
	setm [x3]!, x2!, x1
	sete [x3]!, x2!, x1
