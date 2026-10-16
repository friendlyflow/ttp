# wide.s — progs/aarch64/wide.ff for GNU as, made with it by mkwide.pl:
# every instruction of the aarch64 section, offsets at the edges of their
# range, then the macros GNU has as aliases. Assembled with
# -march=armv8.1-a (LSE), linked with ff64.ld, its bytes must equal what
# ttpc --target aarch64 makes of wide.ff after the 120-byte ELF header.
    .globl _start
_start:
    add x1, x2, #4095
    add x3, x4, #4095, lsl #12
    adds x1, x2, #4095
    adds x3, x4, #4095, lsl #12
    sub x1, x2, #4095
    sub x3, x4, #4095, lsl #12
    subs x1, x2, #4095
    subs x3, x4, #4095, lsl #12
    and x5, x6, #0xfffffffffffffffe
    orr x5, x6, #0xaaaaaaaaaaaaaaaa
    eor x5, x6, #0x1
    ands x5, x6, #0x5555555555555555
    movn x7, #0xffff, lsl #48
    movz x8, #0, lsl #0
    movk x9, #0x1234, lsl #48
    sbfm x10, x11, #63, #0
    bfm x12, x13, #0, #63
    ubfm x14, x15, #1, #2
    extr x16, x17, x18, #63
    add w1, w2, #4095
    add w3, w4, #4095, lsl #12
    adds w1, w2, #4095
    adds w3, w4, #4095, lsl #12
    sub w1, w2, #4095
    sub w3, w4, #4095, lsl #12
    subs w1, w2, #4095
    subs w3, w4, #4095, lsl #12
    and w5, w6, #0xfffffffe
    orr w5, w6, #0xe3ffe3ff
    eor w5, w6, #0x1
    ands w5, w6, #0x55555555
    movn w7, #0xffff, lsl #16
    movz w8, #0, lsl #0
    movk w9, #0x1234, lsl #16
    sbfm w10, w11, #31, #0
    bfm w12, w13, #0, #31
    ubfm w14, w15, #1, #2
    extr w16, w17, w18, #31
    add sp, sp, #16
    sub x29, sp, #0
    adr x19, .+1048575
    adr x20, .-1048576
    adrp x21, .+4294963200
    adrp x22, .-4294967296
    add x1, x2, x3
    add x4, x5, x6, lsl #63
    add x7, x8, w9, sxtb #4
    adds x1, x2, x3
    adds x4, x5, x6, lsr #63
    adds x7, x8, w9, sxth #4
    sub x1, x2, x3
    sub x4, x5, x6, asr #63
    sub x7, x8, w9, sxtw #4
    subs x1, x2, x3
    subs x4, x5, x6, lsl #63
    subs x7, x8, w9, uxtb #4
    add x12, x11, x10, sxtx
    and x13, x14, x15
    and x16, x17, x18, lsl #63
    bic x13, x14, x15
    bic x16, x17, x18, lsr #63
    orr x13, x14, x15
    orr x16, x17, x18, asr #63
    orn x13, x14, x15
    orn x16, x17, x18, ror #63
    eor x13, x14, x15
    eor x16, x17, x18, lsl #63
    eon x13, x14, x15
    eon x16, x17, x18, lsr #63
    ands x13, x14, x15
    ands x16, x17, x18, asr #63
    bics x13, x14, x15
    bics x16, x17, x18, ror #63
    adc x19, x20, x21
    adcs x19, x20, x21
    sbc x19, x20, x21
    sbcs x19, x20, x21
    ccmn x22, x23, #15, eq
    ccmp x24, x25, #0, nv
    ccmn x26, #31, #1, al
    ccmp x27, #0, #8, nv
    csel x28, x30, x0, eq
    csinc x28, x30, x0, cc
    csinv x28, x30, x0, vs
    csneg x28, x30, x0, ls
    rbit x1, x2
    rev16 x1, x2
    clz x1, x2
    cls x1, x2
    rev x1, x2
    rev32 x1, x2
    udiv x3, x4, x5
    sdiv x3, x4, x5
    lslv x3, x4, x5
    lsrv x3, x4, x5
    asrv x3, x4, x5
    rorv x3, x4, x5
    madd x7, x8, x9, x10
    msub x11, x12, x13, x14
    add w1, w2, w3
    add w4, w5, w6, lsl #31
    add w7, w8, w9, sxtb #4
    adds w1, w2, w3
    adds w4, w5, w6, lsr #31
    adds w7, w8, w9, sxth #4
    sub w1, w2, w3
    sub w4, w5, w6, asr #31
    sub w7, w8, w9, sxtw #4
    subs w1, w2, w3
    subs w4, w5, w6, lsl #31
    subs w7, w8, w9, uxtb #4
    add w12, w11, w10, sxtw
    and w13, w14, w15
    and w16, w17, w18, lsl #31
    bic w13, w14, w15
    bic w16, w17, w18, lsr #31
    orr w13, w14, w15
    orr w16, w17, w18, asr #31
    orn w13, w14, w15
    orn w16, w17, w18, ror #31
    eor w13, w14, w15
    eor w16, w17, w18, lsl #31
    eon w13, w14, w15
    eon w16, w17, w18, lsr #31
    ands w13, w14, w15
    ands w16, w17, w18, asr #31
    bics w13, w14, w15
    bics w16, w17, w18, ror #31
    adc w19, w20, w21
    adcs w19, w20, w21
    sbc w19, w20, w21
    sbcs w19, w20, w21
    ccmn w22, w23, #15, eq
    ccmp w24, w25, #0, nv
    ccmn w26, #31, #1, al
    ccmp w27, #0, #8, nv
    csel w28, w30, w0, eq
    csinc w28, w30, w0, cc
    csinv w28, w30, w0, vs
    csneg w28, w30, w0, ls
    rbit w1, w2
    rev16 w1, w2
    clz w1, w2
    cls w1, w2
    rev w1, w2
    udiv w3, w4, w5
    sdiv w3, w4, w5
    lslv w3, w4, w5
    lsrv w3, w4, w5
    asrv w3, w4, w5
    rorv w3, w4, w5
    madd w7, w8, w9, w10
    msub w11, w12, w13, w14
    smaddl x1, w2, w3, x4
    smsubl x1, w2, w3, x4
    umaddl x1, w2, w3, x4
    umsubl x1, w2, w3, x4
    smulh x5, x6, x7
    umulh x5, x6, x7
    b .+134217724
    b .-134217728
    bl .+134217724
    bl .-134217728
    b.eq .+1048572
    b.ne .-1048576
    b.cs .+1048572
    b.cc .-1048576
    b.mi .+1048572
    b.pl .-1048576
    b.vs .+1048572
    b.vc .-1048576
    b.hi .+1048572
    b.ls .-1048576
    b.ge .+1048572
    b.lt .-1048576
    b.gt .+1048572
    b.le .-1048576
    b.al .+1048572
    b.nv .-1048576
    b.hs .-4
    b.lo .+8
    cbz x1, .+1048572
    cbnz x2, .-1048576
    cbz w3, .-1048576
    cbnz w4, .+1048572
    tbz x5, #63, .+32764
    tbnz w6, #0, .-32768
    tbz w7, #31, .-32768
    br x16
    blr x17
    ret
    ret x18
    svc #0
    hvc #0xffff
    smc #1
    brk #0x8000
    hlt #0xf000
    nop
    yield
    wfe
    wfi
    sev
    sevl
    clrex
    isb
    eret
    dsb ish
    dmb ishld
    dsb sy
    mrs x1, tpidr_el0
    msr tpidr_el0, x2
    mrs x3, s3_7_c15_c15_7
    strb w1, [x2, #4095]
    strb w1, [x2]
    strb w1, [x2, #-256]!
    strb w1, [x2], #255
    sturb w1, [x2, #255]
    strb w1, [x2, x3, lsl #0]
    strb w1, [x2, w3, sxtw]
    ldrb w2, [x3, #4095]
    ldrb w2, [x3, #-256]!
    ldrb w2, [x3], #255
    ldurb w2, [x3, #-256]
    ldrb w2, [x3, x4, lsl #0]
    ldrb w2, [x3, w4, sxtw]
    ldrsb x3, [x4, #4095]
    ldrsb x3, [x4, #-256]!
    ldrsb x3, [x4], #255
    ldursb x3, [x4, #255]
    ldrsb x3, [x4, x5, lsl #0]
    ldrsb x3, [x4, w5, sxtw]
    ldrsb w4, [x5, #4095]
    ldrsb w4, [x5, #-256]!
    ldrsb w4, [x5], #255
    ldursb w4, [x5, #-256]
    ldrsb w4, [x5, x6, lsl #0]
    ldrsb w4, [x5, w6, sxtw]
    strh w5, [x6, #8190]
    strh w5, [x6]
    strh w5, [x6, #-256]!
    strh w5, [x6], #255
    sturh w5, [x6, #255]
    strh w5, [x6, x7, lsl #1]
    strh w5, [x6, w7, sxtw]
    ldrh w6, [sp, #8190]
    ldrh w6, [sp, #-256]!
    ldrh w6, [sp], #255
    ldurh w6, [sp, #-256]
    ldrh w6, [sp, x8, lsl #1]
    ldrh w6, [sp, w8, sxtw]
    ldrsh x7, [x8, #8190]
    ldrsh x7, [x8, #-256]!
    ldrsh x7, [x8], #255
    ldursh x7, [x8, #255]
    ldrsh x7, [x8, x9, lsl #1]
    ldrsh x7, [x8, w9, sxtw]
    ldrsh w8, [x9, #8190]
    ldrsh w8, [x9, #-256]!
    ldrsh w8, [x9], #255
    ldursh w8, [x9, #-256]
    ldrsh w8, [x9, x10, lsl #1]
    ldrsh w8, [x9, w10, sxtw]
    str w9, [x10, #16380]
    str w9, [x10]
    str w9, [x10, #-256]!
    str w9, [x10], #255
    stur w9, [x10, #255]
    str w9, [x10, x11, lsl #2]
    str w9, [x10, w11, sxtw]
    ldr w10, [x11, #16380]
    ldr w10, [x11, #-256]!
    ldr w10, [x11], #255
    ldur w10, [x11, #-256]
    ldr w10, [x11, x12, lsl #2]
    ldr w10, [x11, w12, sxtw]
    ldrsw x11, [x12, #16380]
    ldrsw x11, [x12, #-256]!
    ldrsw x11, [x12], #255
    ldursw x11, [x12, #255]
    ldrsw x11, [x12, x13, lsl #2]
    ldrsw x11, [x12, w13, sxtw]
    str x12, [x13, #32760]
    str x12, [x13, #-256]!
    str x12, [x13], #255
    stur x12, [x13, #-256]
    str x12, [x13, x14, lsl #3]
    str x12, [x13, w14, sxtw]
    ldr x13, [x14, #32760]
    ldr x13, [x14]
    ldr x13, [x14, #-256]!
    ldr x13, [x14], #255
    ldur x13, [x14, #255]
    ldr x13, [x14, x15, lsl #3]
    ldr x13, [x14, w15, sxtw]
    str s14, [x15, #16380]
    str s14, [x15, #-256]!
    str s14, [x15], #255
    stur s14, [x15, #-256]
    str s14, [x15, x16, lsl #2]
    str s14, [x15, w16, sxtw]
    ldr s15, [x16, #16380]
    ldr s15, [x16, #-256]!
    ldr s15, [x16], #255
    ldur s15, [x16, #255]
    ldr s15, [x16, x17, lsl #2]
    ldr s15, [x16, w17, sxtw]
    str d16, [x17, #32760]
    str d16, [x17, #-256]!
    str d16, [x17], #255
    stur d16, [x17, #-256]
    str d16, [x17, x18, lsl #3]
    str d16, [x17, w18, sxtw]
    ldr d17, [x18, #32760]
    ldr d17, [x18]
    ldr d17, [x18, #-256]!
    ldr d17, [x18], #255
    ldur d17, [x18, #255]
    ldr d17, [x18, x19, lsl #3]
    ldr d17, [x18, w19, sxtw]
    ldr x1, [x2, x3]
    ldrb w1, [x2, w3, uxtw #0]
    ldr x1, .+1048572
    ldr w2, .-1048576
    ldrsw x3, .+4
    ldr s4, .-4
    ldr d5, .+1048572
    stp w1, w11, [x21, #252]
    stp w1, w11, [x21, #-256]!
    stp w1, w11, [x21], #252
    ldp w2, w12, [x22, #252]
    ldp w2, w12, [x22, #-256]!
    ldp w2, w12, [x22], #252
    ldpsw x3, x13, [x23, #252]
    ldpsw x3, x13, [x23, #-256]!
    ldpsw x3, x13, [x23], #252
    stp x4, x14, [x24, #504]
    stp x4, x14, [x24, #-512]!
    stp x4, x14, [x24], #504
    ldp x5, x15, [x25, #504]
    ldp x5, x15, [x25, #-512]!
    ldp x5, x15, [x25], #504
    stp s6, s16, [x26, #252]
    stp s6, s16, [x26, #-256]!
    stp s6, s16, [x26], #252
    ldp s7, s17, [x27, #252]
    ldp s7, s17, [x27, #-256]!
    ldp s7, s17, [x27], #252
    stp d8, d18, [x28, #504]
    stp d8, d18, [x28, #-512]!
    stp d8, d18, [x28], #504
    ldp d9, d19, [x29, #504]
    ldp d9, d19, [x29, #-512]!
    ldp d9, d19, [x29], #504
    stp x29, x30, [sp, #-16]!
    ldp x29, x30, [sp], #16
    stxrb w1, w2, [x3]
    stlxrb w4, w5, [sp]
    ldxrb w6, [x7]
    ldaxrb w8, [x9]
    stlrb w10, [x11]
    ldarb w12, [x13]
    stxrh w1, w2, [x3]
    stlxrh w4, w5, [sp]
    ldxrh w6, [x7]
    ldaxrh w8, [x9]
    stlrh w10, [x11]
    ldarh w12, [x13]
    stxr w1, w2, [x3]
    stlxr w4, w5, [sp]
    ldxr w6, [x7]
    ldaxr w8, [x9]
    stlr w10, [x11]
    ldar w12, [x13]
    stxr w1, x2, [x3]
    stlxr w4, x5, [sp]
    ldxr x6, [x7]
    ldaxr x8, [x9]
    stlr x10, [x11]
    ldar x12, [x13]
    stxp w1, w2, w3, [x4]
    stlxp w5, w6, w7, [x8]
    ldxp w9, w10, [x11]
    ldaxp w12, w13, [x14]
    stxp w1, x2, x3, [x4]
    stlxp w5, x6, x7, [x8]
    ldxp x9, x10, [x11]
    ldaxp x12, x13, [x14]
    ldaddb w0, w7, [x13]
    ldaddh w1, w8, [x14]
    ldadd w2, w9, [x15]
    ldadd x3, x10, [x16]
    ldaddab w4, w11, [x17]
    ldaddah w5, w12, [x18]
    ldadda w6, w13, [x19]
    ldadda x7, x14, [x20]
    ldaddlb w8, w15, [x21]
    ldaddlh w9, w16, [x22]
    ldaddl w10, w17, [x23]
    ldaddl x11, x18, [x24]
    ldaddalb w12, w19, [x25]
    ldaddalh w13, w20, [x26]
    ldaddal w14, w21, [x27]
    ldaddal x15, x22, [x28]
    ldclrb w16, w23, [x29]
    ldclrh w17, w24, [x0]
    ldclr w18, w25, [x1]
    ldclr x19, x26, [x2]
    ldclrab w20, w27, [x3]
    ldclrah w21, w28, [x4]
    ldclra w22, w29, [x5]
    ldclra x23, x0, [x6]
    ldclrlb w24, w1, [x7]
    ldclrlh w25, w2, [x8]
    ldclrl w26, w3, [x9]
    ldclrl x27, x4, [x10]
    ldclralb w28, w5, [x11]
    ldclralh w29, w6, [x12]
    ldclral w0, w7, [x13]
    ldclral x1, x8, [x14]
    ldeorb w2, w9, [x15]
    ldeorh w3, w10, [x16]
    ldeor w4, w11, [x17]
    ldeor x5, x12, [x18]
    ldeorab w6, w13, [x19]
    ldeorah w7, w14, [x20]
    ldeora w8, w15, [x21]
    ldeora x9, x16, [x22]
    ldeorlb w10, w17, [x23]
    ldeorlh w11, w18, [x24]
    ldeorl w12, w19, [x25]
    ldeorl x13, x20, [x26]
    ldeoralb w14, w21, [x27]
    ldeoralh w15, w22, [x28]
    ldeoral w16, w23, [x29]
    ldeoral x17, x24, [x0]
    ldsetb w18, w25, [x1]
    ldseth w19, w26, [x2]
    ldset w20, w27, [x3]
    ldset x21, x28, [x4]
    ldsetab w22, w29, [x5]
    ldsetah w23, w0, [x6]
    ldseta w24, w1, [x7]
    ldseta x25, x2, [x8]
    ldsetlb w26, w3, [x9]
    ldsetlh w27, w4, [x10]
    ldsetl w28, w5, [x11]
    ldsetl x29, x6, [x12]
    ldsetalb w0, w7, [x13]
    ldsetalh w1, w8, [x14]
    ldsetal w2, w9, [x15]
    ldsetal x3, x10, [x16]
    ldsmaxb w4, w11, [x17]
    ldsmaxh w5, w12, [x18]
    ldsmax w6, w13, [x19]
    ldsmax x7, x14, [x20]
    ldsmaxab w8, w15, [x21]
    ldsmaxah w9, w16, [x22]
    ldsmaxa w10, w17, [x23]
    ldsmaxa x11, x18, [x24]
    ldsmaxlb w12, w19, [x25]
    ldsmaxlh w13, w20, [x26]
    ldsmaxl w14, w21, [x27]
    ldsmaxl x15, x22, [x28]
    ldsmaxalb w16, w23, [x29]
    ldsmaxalh w17, w24, [x0]
    ldsmaxal w18, w25, [x1]
    ldsmaxal x19, x26, [x2]
    ldsminb w20, w27, [x3]
    ldsminh w21, w28, [x4]
    ldsmin w22, w29, [x5]
    ldsmin x23, x0, [x6]
    ldsminab w24, w1, [x7]
    ldsminah w25, w2, [x8]
    ldsmina w26, w3, [x9]
    ldsmina x27, x4, [x10]
    ldsminlb w28, w5, [x11]
    ldsminlh w29, w6, [x12]
    ldsminl w0, w7, [x13]
    ldsminl x1, x8, [x14]
    ldsminalb w2, w9, [x15]
    ldsminalh w3, w10, [x16]
    ldsminal w4, w11, [x17]
    ldsminal x5, x12, [x18]
    ldumaxb w6, w13, [x19]
    ldumaxh w7, w14, [x20]
    ldumax w8, w15, [x21]
    ldumax x9, x16, [x22]
    ldumaxab w10, w17, [x23]
    ldumaxah w11, w18, [x24]
    ldumaxa w12, w19, [x25]
    ldumaxa x13, x20, [x26]
    ldumaxlb w14, w21, [x27]
    ldumaxlh w15, w22, [x28]
    ldumaxl w16, w23, [x29]
    ldumaxl x17, x24, [x0]
    ldumaxalb w18, w25, [x1]
    ldumaxalh w19, w26, [x2]
    ldumaxal w20, w27, [x3]
    ldumaxal x21, x28, [x4]
    lduminb w22, w29, [x5]
    lduminh w23, w0, [x6]
    ldumin w24, w1, [x7]
    ldumin x25, x2, [x8]
    lduminab w26, w3, [x9]
    lduminah w27, w4, [x10]
    ldumina w28, w5, [x11]
    ldumina x29, x6, [x12]
    lduminlb w0, w7, [x13]
    lduminlh w1, w8, [x14]
    lduminl w2, w9, [x15]
    lduminl x3, x10, [x16]
    lduminalb w4, w11, [x17]
    lduminalh w5, w12, [x18]
    lduminal w6, w13, [x19]
    lduminal x7, x14, [x20]
    swpb w8, w15, [x21]
    swph w9, w16, [x22]
    swp w10, w17, [x23]
    swp x11, x18, [x24]
    swpab w12, w19, [x25]
    swpah w13, w20, [x26]
    swpa w14, w21, [x27]
    swpa x15, x22, [x28]
    swplb w16, w23, [x29]
    swplh w17, w24, [x0]
    swpl w18, w25, [x1]
    swpl x19, x26, [x2]
    swpalb w20, w27, [x3]
    swpalh w21, w28, [x4]
    swpal w22, w29, [x5]
    swpal x23, x0, [x6]
    casb w24, w1, [x7]
    cash w25, w2, [x8]
    cas w26, w3, [x9]
    cas x27, x4, [x10]
    casab w28, w5, [x11]
    casah w29, w6, [x12]
    casa w0, w7, [x13]
    casa x1, x8, [x14]
    caslb w2, w9, [x15]
    caslh w3, w10, [x16]
    casl w4, w11, [x17]
    casl x5, x12, [x18]
    casalb w6, w13, [x19]
    casalh w7, w14, [x20]
    casal w8, w15, [x21]
    casal x9, x16, [x22]
    fmov s1, s2
    fabs s1, s2
    fneg s1, s2
    fsqrt s1, s2
    frintn s1, s2
    frintp s1, s2
    frintm s1, s2
    frintz s1, s2
    frinta s1, s2
    frintx s1, s2
    frinti s1, s2
    fmov s3, #31.0
    fmov s4, #1.0
    fmul s5, s6, s7
    fdiv s5, s6, s7
    fadd s5, s6, s7
    fsub s5, s6, s7
    fmax s5, s6, s7
    fmin s5, s6, s7
    fmaxnm s5, s6, s7
    fminnm s5, s6, s7
    fnmul s5, s6, s7
    fmadd s8, s9, s10, s11
    fmsub s8, s9, s10, s11
    fnmadd s8, s9, s10, s11
    fnmsub s8, s9, s10, s11
    fcmp s12, s13
    fcmpe s14, s15
    fcmp s16, #0.0
    fcmpe s17, #0.0
    fccmp s18, s19, #15, ne
    fccmpe s20, s21, #0, nv
    fcsel s22, s23, s24, lt
    scvtf s25, w26
    ucvtf s25, w26
    fcvtns w27, s28
    fcvtnu w27, s28
    fcvtas w27, s28
    fcvtau w27, s28
    fcvtps w27, s28
    fcvtpu w27, s28
    fcvtms w27, s28
    fcvtmu w27, s28
    fcvtzs w27, s28
    fcvtzu w27, s28
    scvtf s25, x26
    ucvtf s25, x26
    fcvtns x27, s28
    fcvtnu x27, s28
    fcvtas x27, s28
    fcvtau x27, s28
    fcvtps x27, s28
    fcvtpu x27, s28
    fcvtms x27, s28
    fcvtmu x27, s28
    fcvtzs x27, s28
    fcvtzu x27, s28
    fmov d1, d2
    fabs d1, d2
    fneg d1, d2
    fsqrt d1, d2
    frintn d1, d2
    frintp d1, d2
    frintm d1, d2
    frintz d1, d2
    frinta d1, d2
    frintx d1, d2
    frinti d1, d2
    fmov d3, #-1.9375
    fmov d4, #1.0
    fmul d5, d6, d7
    fdiv d5, d6, d7
    fadd d5, d6, d7
    fsub d5, d6, d7
    fmax d5, d6, d7
    fmin d5, d6, d7
    fmaxnm d5, d6, d7
    fminnm d5, d6, d7
    fnmul d5, d6, d7
    fmadd d8, d9, d10, d11
    fmsub d8, d9, d10, d11
    fnmadd d8, d9, d10, d11
    fnmsub d8, d9, d10, d11
    fcmp d12, d13
    fcmpe d14, d15
    fcmp d16, #0.0
    fcmpe d17, #0.0
    fccmp d18, d19, #15, ne
    fccmpe d20, d21, #0, nv
    fcsel d22, d23, d24, lt
    scvtf d25, w26
    ucvtf d25, w26
    fcvtns w27, d28
    fcvtnu w27, d28
    fcvtas w27, d28
    fcvtau w27, d28
    fcvtps w27, d28
    fcvtpu w27, d28
    fcvtms w27, d28
    fcvtmu w27, d28
    fcvtzs w27, d28
    fcvtzu w27, d28
    scvtf d25, x26
    ucvtf d25, x26
    fcvtns x27, d28
    fcvtnu x27, d28
    fcvtas x27, d28
    fcvtau x27, d28
    fcvtps x27, d28
    fcvtpu x27, d28
    fcvtms x27, d28
    fcvtmu x27, d28
    fcvtzs x27, d28
    fcvtzu x27, d28
    fcvt d29, s30
    fcvt s0, d31
    fmov s2, w1
    fmov w4, s3
    fmov d6, x5
    fmov x8, d7
    mov x1, x2
    mov w3, w4
    mov x5, sp
    mvn x6, x7
    mvn w8, w9
    neg x10, x11
    neg w12, w13
    negs x14, x15
    cmp x16, x17
    cmp w18, w19
    cmp x20, #4095
    cmp w21, #0
    cmn x22, x23
    cmn w24, w25
    cmn x26, #1
    cmn w27, #7
    tst x28, x1
    tst w2, w3
    tst x4, #0xff
    lsl x5, x6, #1
    lsl x5, x6, #63
    lsl w7, w8, #31
    lsr x9, x10, #63
    lsr w11, w12, #1
    asr x13, x14, #3
    asr w15, w16, #31
    ror x17, x18, #17
    ror w19, w20, #5
    sxtb x21, w22
    sxth x23, w24
    sxtw x25, w26
    uxtb w27, w28
    uxth w0, w1
    mov w2, w3
    mul x4, x5, x6
    mul w7, w8, w9
    mneg x10, x11, x12
    smull x13, w14, w15
    umull x16, w17, w18
    cset x19, eq
    csetm x20, lt
    cinc x21, x22, hi
    cneg x23, x24, ge
    movz x25, #0xdef0
    movk x25, #0x9abc, lsl #16
    movk x25, #0x5678, lsl #32
    movk x25, #0x1234, lsl #48
    movz x26, #0xfffe
    movk x26, #0xffff, lsl #16
    movk x26, #0xffff, lsl #32
    movk x26, #0xffff, lsl #48
    movz w27, #1
    movk w27, #0x8000, lsl #16
    adrp x28, _start
    add x28, x28, :lo12:_start
    b _start
    bl _start
