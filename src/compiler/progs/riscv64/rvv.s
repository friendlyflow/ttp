# The GNU twin of rvv.ff (written by mkrvv.pl).
	.option norvc
	.text
	.globl _start
_start:
	vsetvli a2, a0, e8, m2, ta, ma
	vsetivli a5, 31, e8, m2, ta, ma
	vsetvli a2, a0, e64, m1, tu, mu
	vsetivli a5, 31, e64, m1, tu, mu
	vsetvli a2, a0, e16, mf2, ta, mu
	vsetivli a5, 31, e16, mf2, ta, mu
	vsetvli a2, a0, e32, m8, tu, ma
	vsetivli a5, 31, e32, m8, tu, ma
	vsetvl a2, a0, a1
	vle8.v v8, (a1)
	vle8ff.v v30, (a3)
	vse8.v v16, (s1)
	vle8.v v8, (a1), v0.t
	vle8ff.v v30, (a3), v0.t
	vse8.v v16, (s1), v0.t
	vle16.v v8, (a1)
	vle16ff.v v30, (a3)
	vse16.v v16, (s1)
	vle16.v v8, (a1), v0.t
	vle16ff.v v30, (a3), v0.t
	vse16.v v16, (s1), v0.t
	vle32.v v8, (a1)
	vle32ff.v v30, (a3)
	vse32.v v16, (s1)
	vle32.v v8, (a1), v0.t
	vle32ff.v v30, (a3), v0.t
	vse32.v v16, (s1), v0.t
	vle64.v v8, (a1)
	vle64ff.v v30, (a3)
	vse64.v v16, (s1)
	vle64.v v8, (a1), v0.t
	vle64ff.v v30, (a3), v0.t
	vse64.v v16, (s1), v0.t
	vmseq.vv v2, v4, v6
	vmsne.vv v2, v4, v6
	vmsltu.vv v2, v4, v6
	vmsleu.vv v2, v4, v6
	vadd.vv v2, v4, v6
	vsub.vv v2, v4, v6
	vand.vv v2, v4, v6
	vor.vv v2, v4, v6
	vxor.vv v2, v4, v6
	vrgather.vv v2, v4, v6
	vmseq.vx v12, v10, t6
	vmsne.vx v12, v10, t6
	vmsltu.vx v12, v10, t6
	vmsleu.vx v12, v10, t6
	vmsgtu.vx v12, v10, t6
	vadd.vx v12, v10, t6
	vsub.vx v12, v10, t6
	vand.vx v12, v10, t6
	vor.vx v12, v10, t6
	vxor.vx v12, v10, t6
	vrgather.vx v12, v10, t6
	vmseq.vi v20, v14, -16
	vmsne.vi v20, v14, -16
	vmsleu.vi v20, v14, -16
	vmsgtu.vi v20, v14, -16
	vadd.vi v20, v14, -16
	vand.vi v20, v14, -16
	vor.vi v20, v14, -16
	vxor.vi v20, v14, -16
	vmseq.vi v20, v14, 15
	vmsne.vi v20, v14, 15
	vmsleu.vi v20, v14, 15
	vmsgtu.vi v20, v14, 15
	vadd.vi v20, v14, 15
	vand.vi v20, v14, 15
	vor.vi v20, v14, 15
	vxor.vi v20, v14, 15
	vrgather.vi v20, v14, 0
	vrgather.vi v20, v14, 31
	vredmaxu.vs v28, v24, v26
	vredminu.vs v28, v24, v26
	vredsum.vs v28, v24, v26
	vredor.vs v28, v24, v26
	vcpop.m a4, v2
	vfirst.m a4, v2
	vmsbf.m v8, v6
	vmsof.m v8, v6
	vmsif.m v8, v6
	vid.v v31
	vmseq.vv v2, v4, v6, v0.t
	vmsne.vv v2, v4, v6, v0.t
	vmsltu.vv v2, v4, v6, v0.t
	vmsleu.vv v2, v4, v6, v0.t
	vadd.vv v2, v4, v6, v0.t
	vsub.vv v2, v4, v6, v0.t
	vand.vv v2, v4, v6, v0.t
	vor.vv v2, v4, v6, v0.t
	vxor.vv v2, v4, v6, v0.t
	vrgather.vv v2, v4, v6, v0.t
	vmseq.vx v12, v10, t6, v0.t
	vmsne.vx v12, v10, t6, v0.t
	vmsltu.vx v12, v10, t6, v0.t
	vmsleu.vx v12, v10, t6, v0.t
	vmsgtu.vx v12, v10, t6, v0.t
	vadd.vx v12, v10, t6, v0.t
	vsub.vx v12, v10, t6, v0.t
	vand.vx v12, v10, t6, v0.t
	vor.vx v12, v10, t6, v0.t
	vxor.vx v12, v10, t6, v0.t
	vrgather.vx v12, v10, t6, v0.t
	vmseq.vi v20, v14, -16, v0.t
	vmsne.vi v20, v14, -16, v0.t
	vmsleu.vi v20, v14, -16, v0.t
	vmsgtu.vi v20, v14, -16, v0.t
	vadd.vi v20, v14, -16, v0.t
	vand.vi v20, v14, -16, v0.t
	vor.vi v20, v14, -16, v0.t
	vxor.vi v20, v14, -16, v0.t
	vmseq.vi v20, v14, 15, v0.t
	vmsne.vi v20, v14, 15, v0.t
	vmsleu.vi v20, v14, 15, v0.t
	vmsgtu.vi v20, v14, 15, v0.t
	vadd.vi v20, v14, 15, v0.t
	vand.vi v20, v14, 15, v0.t
	vor.vi v20, v14, 15, v0.t
	vxor.vi v20, v14, 15, v0.t
	vrgather.vi v20, v14, 0, v0.t
	vrgather.vi v20, v14, 31, v0.t
	vredmaxu.vs v28, v24, v26, v0.t
	vredminu.vs v28, v24, v26, v0.t
	vredsum.vs v28, v24, v26, v0.t
	vredor.vs v28, v24, v26, v0.t
	vcpop.m a4, v2, v0.t
	vfirst.m a4, v2, v0.t
	vmsbf.m v8, v6, v0.t
	vmsof.m v8, v6, v0.t
	vmsif.m v8, v6, v0.t
	vid.v v31, v0.t
	vmv.v.v v1, v3
	vmv.v.x v1, a7
	vmv.v.i v1, -7
	vmv.x.s a0, v9
	vmv.s.x v9, t3
	vmandn.mm v1, v5, v7
	vmand.mm v1, v5, v7
	vmor.mm v1, v5, v7
	vmxor.mm v1, v5, v7
	vmorn.mm v1, v5, v7
	vmnand.mm v1, v5, v7
	vmnor.mm v1, v5, v7
	vmxnor.mm v1, v5, v7
	csrr a2, vl
	csrr t0, vlenb
