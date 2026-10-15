@ wide.s — progs/arm/wide.ff for GNU as, made with it by mkwide.pl: every
@ instruction of the arm section, offsets at the edges of their range.
@ Linked with ff32.ld, its bytes must equal what ttpc writes after its
@ 84-byte ELF header.
    .syntax unified
    .arch armv7-a
    .arch_extension idiv
    .fpu vfpv3
    .text
    .globl _start
    .arm
_start:
    and r2, r11, #255, 30
    and r5, r0, #1, 0
    and r8, r3, #63, 2
    andeq r7, r2, #255, 30
    andle r10, r5, #1, 0
    andhi lr, r8, #63, 2
    and r11, r6, r1
    andeq r2, r11, r6
    andle r5, r0, r9
    andhi r8, r3, r12
    and r2, r11, r6, lsl #1
    and r5, r0, r9, lsl #31
    and r2, r11, r6, lsr #1
    and r5, r0, r9, lsr #31
    and r2, r11, r6, asr #1
    and r5, r0, r9, asr #31
    and r2, r11, r6, ror #1
    and r5, r0, r9, ror #31
    and r11, r6, r1, rrx
    and r2, r11, r6, lsl r1
    and r2, r11, r6, lsr r1
    and r2, r11, r6, asr r1
    and r2, r11, r6, ror r1
    ands r2, r11, #255, 30
    ands r5, r0, #1, 0
    ands r8, r3, #63, 2
    ands r11, r6, r1
    ands r2, r11, r6, lsl #1
    ands r5, r0, r9, lsl #31
    ands r2, r11, r6, lsr #1
    ands r5, r0, r9, lsr #31
    ands r2, r11, r6, asr #1
    ands r5, r0, r9, asr #31
    ands r2, r11, r6, ror #1
    ands r5, r0, r9, ror #31
    ands r11, r6, r1, rrx
    ands r2, r11, r6, lsl r1
    ands r2, r11, r6, lsr r1
    ands r2, r11, r6, asr r1
    ands r2, r11, r6, ror r1
    eor r2, r11, #255, 30
    eor r5, r0, #1, 0
    eor r8, r3, #63, 2
    eoreq r7, r2, #255, 30
    eorle r10, r5, #1, 0
    eorhi lr, r8, #63, 2
    eor r11, r6, r1
    eoreq r2, r11, r6
    eorle r5, r0, r9
    eorhi r8, r3, r12
    eor r2, r11, r6, lsl #1
    eor r5, r0, r9, lsl #31
    eor r2, r11, r6, lsr #1
    eor r5, r0, r9, lsr #31
    eor r2, r11, r6, asr #1
    eor r5, r0, r9, asr #31
    eor r2, r11, r6, ror #1
    eor r5, r0, r9, ror #31
    eor r11, r6, r1, rrx
    eor r2, r11, r6, lsl r1
    eor r2, r11, r6, lsr r1
    eor r2, r11, r6, asr r1
    eor r2, r11, r6, ror r1
    eors r2, r11, #255, 30
    eors r5, r0, #1, 0
    eors r8, r3, #63, 2
    eors r11, r6, r1
    eors r2, r11, r6, lsl #1
    eors r5, r0, r9, lsl #31
    eors r2, r11, r6, lsr #1
    eors r5, r0, r9, lsr #31
    eors r2, r11, r6, asr #1
    eors r5, r0, r9, asr #31
    eors r2, r11, r6, ror #1
    eors r5, r0, r9, ror #31
    eors r11, r6, r1, rrx
    eors r2, r11, r6, lsl r1
    eors r2, r11, r6, lsr r1
    eors r2, r11, r6, asr r1
    eors r2, r11, r6, ror r1
    sub r2, r11, #255, 30
    sub r5, r0, #1, 0
    sub r8, r3, #63, 2
    subeq r7, r2, #255, 30
    suble r10, r5, #1, 0
    subhi lr, r8, #63, 2
    sub r11, r6, r1
    subeq r2, r11, r6
    suble r5, r0, r9
    subhi r8, r3, r12
    sub r2, r11, r6, lsl #1
    sub r5, r0, r9, lsl #31
    sub r2, r11, r6, lsr #1
    sub r5, r0, r9, lsr #31
    sub r2, r11, r6, asr #1
    sub r5, r0, r9, asr #31
    sub r2, r11, r6, ror #1
    sub r5, r0, r9, ror #31
    sub r11, r6, r1, rrx
    sub r2, r11, r6, lsl r1
    sub r2, r11, r6, lsr r1
    sub r2, r11, r6, asr r1
    sub r2, r11, r6, ror r1
    subs r2, r11, #255, 30
    subs r5, r0, #1, 0
    subs r8, r3, #63, 2
    subs r11, r6, r1
    subs r2, r11, r6, lsl #1
    subs r5, r0, r9, lsl #31
    subs r2, r11, r6, lsr #1
    subs r5, r0, r9, lsr #31
    subs r2, r11, r6, asr #1
    subs r5, r0, r9, asr #31
    subs r2, r11, r6, ror #1
    subs r5, r0, r9, ror #31
    subs r11, r6, r1, rrx
    subs r2, r11, r6, lsl r1
    subs r2, r11, r6, lsr r1
    subs r2, r11, r6, asr r1
    subs r2, r11, r6, ror r1
    rsb r2, r11, #255, 30
    rsb r5, r0, #1, 0
    rsb r8, r3, #63, 2
    rsb r11, r6, r1
    rsb r2, r11, r6, lsl #1
    rsb r5, r0, r9, lsl #31
    rsb r2, r11, r6, lsr #1
    rsb r5, r0, r9, lsr #31
    rsb r2, r11, r6, asr #1
    rsb r5, r0, r9, asr #31
    rsb r2, r11, r6, ror #1
    rsb r5, r0, r9, ror #31
    rsb r11, r6, r1, rrx
    rsb r2, r11, r6, lsl r1
    rsb r2, r11, r6, lsr r1
    rsb r2, r11, r6, asr r1
    rsb r2, r11, r6, ror r1
    rsbs r2, r11, #255, 30
    rsbs r5, r0, #1, 0
    rsbs r8, r3, #63, 2
    rsbs r11, r6, r1
    rsbs r2, r11, r6, lsl #1
    rsbs r5, r0, r9, lsl #31
    rsbs r2, r11, r6, lsr #1
    rsbs r5, r0, r9, lsr #31
    rsbs r2, r11, r6, asr #1
    rsbs r5, r0, r9, asr #31
    rsbs r2, r11, r6, ror #1
    rsbs r5, r0, r9, ror #31
    rsbs r11, r6, r1, rrx
    rsbs r2, r11, r6, lsl r1
    rsbs r2, r11, r6, lsr r1
    rsbs r2, r11, r6, asr r1
    rsbs r2, r11, r6, ror r1
    add r2, r11, #255, 30
    add r5, r0, #1, 0
    add r8, r3, #63, 2
    addeq r7, r2, #255, 30
    addle r10, r5, #1, 0
    addhi lr, r8, #63, 2
    add r11, r6, r1
    addeq r2, r11, r6
    addle r5, r0, r9
    addhi r8, r3, r12
    add r2, r11, r6, lsl #1
    add r5, r0, r9, lsl #31
    add r2, r11, r6, lsr #1
    add r5, r0, r9, lsr #31
    add r2, r11, r6, asr #1
    add r5, r0, r9, asr #31
    add r2, r11, r6, ror #1
    add r5, r0, r9, ror #31
    add r11, r6, r1, rrx
    add r2, r11, r6, lsl r1
    add r2, r11, r6, lsr r1
    add r2, r11, r6, asr r1
    add r2, r11, r6, ror r1
    adds r2, r11, #255, 30
    adds r5, r0, #1, 0
    adds r8, r3, #63, 2
    adds r11, r6, r1
    adds r2, r11, r6, lsl #1
    adds r5, r0, r9, lsl #31
    adds r2, r11, r6, lsr #1
    adds r5, r0, r9, lsr #31
    adds r2, r11, r6, asr #1
    adds r5, r0, r9, asr #31
    adds r2, r11, r6, ror #1
    adds r5, r0, r9, ror #31
    adds r11, r6, r1, rrx
    adds r2, r11, r6, lsl r1
    adds r2, r11, r6, lsr r1
    adds r2, r11, r6, asr r1
    adds r2, r11, r6, ror r1
    adc r2, r11, #255, 30
    adc r5, r0, #1, 0
    adc r8, r3, #63, 2
    adc r11, r6, r1
    adc r2, r11, r6, lsl #1
    adc r5, r0, r9, lsl #31
    adc r2, r11, r6, lsr #1
    adc r5, r0, r9, lsr #31
    adc r2, r11, r6, asr #1
    adc r5, r0, r9, asr #31
    adc r2, r11, r6, ror #1
    adc r5, r0, r9, ror #31
    adc r11, r6, r1, rrx
    adc r2, r11, r6, lsl r1
    adc r2, r11, r6, lsr r1
    adc r2, r11, r6, asr r1
    adc r2, r11, r6, ror r1
    adcs r2, r11, #255, 30
    adcs r5, r0, #1, 0
    adcs r8, r3, #63, 2
    adcs r11, r6, r1
    adcs r2, r11, r6, lsl #1
    adcs r5, r0, r9, lsl #31
    adcs r2, r11, r6, lsr #1
    adcs r5, r0, r9, lsr #31
    adcs r2, r11, r6, asr #1
    adcs r5, r0, r9, asr #31
    adcs r2, r11, r6, ror #1
    adcs r5, r0, r9, ror #31
    adcs r11, r6, r1, rrx
    adcs r2, r11, r6, lsl r1
    adcs r2, r11, r6, lsr r1
    adcs r2, r11, r6, asr r1
    adcs r2, r11, r6, ror r1
    sbc r2, r11, #255, 30
    sbc r5, r0, #1, 0
    sbc r8, r3, #63, 2
    sbc r11, r6, r1
    sbc r2, r11, r6, lsl #1
    sbc r5, r0, r9, lsl #31
    sbc r2, r11, r6, lsr #1
    sbc r5, r0, r9, lsr #31
    sbc r2, r11, r6, asr #1
    sbc r5, r0, r9, asr #31
    sbc r2, r11, r6, ror #1
    sbc r5, r0, r9, ror #31
    sbc r11, r6, r1, rrx
    sbc r2, r11, r6, lsl r1
    sbc r2, r11, r6, lsr r1
    sbc r2, r11, r6, asr r1
    sbc r2, r11, r6, ror r1
    sbcs r2, r11, #255, 30
    sbcs r5, r0, #1, 0
    sbcs r8, r3, #63, 2
    sbcs r11, r6, r1
    sbcs r2, r11, r6, lsl #1
    sbcs r5, r0, r9, lsl #31
    sbcs r2, r11, r6, lsr #1
    sbcs r5, r0, r9, lsr #31
    sbcs r2, r11, r6, asr #1
    sbcs r5, r0, r9, asr #31
    sbcs r2, r11, r6, ror #1
    sbcs r5, r0, r9, ror #31
    sbcs r11, r6, r1, rrx
    sbcs r2, r11, r6, lsl r1
    sbcs r2, r11, r6, lsr r1
    sbcs r2, r11, r6, asr r1
    sbcs r2, r11, r6, ror r1
    rsc r2, r11, #255, 30
    rsc r5, r0, #1, 0
    rsc r8, r3, #63, 2
    rsc r11, r6, r1
    rsc r2, r11, r6, lsl #1
    rsc r5, r0, r9, lsl #31
    rsc r2, r11, r6, lsr #1
    rsc r5, r0, r9, lsr #31
    rsc r2, r11, r6, asr #1
    rsc r5, r0, r9, asr #31
    rsc r2, r11, r6, ror #1
    rsc r5, r0, r9, ror #31
    rsc r11, r6, r1, rrx
    rsc r2, r11, r6, lsl r1
    rsc r2, r11, r6, lsr r1
    rsc r2, r11, r6, asr r1
    rsc r2, r11, r6, ror r1
    rscs r2, r11, #255, 30
    rscs r5, r0, #1, 0
    rscs r8, r3, #63, 2
    rscs r11, r6, r1
    rscs r2, r11, r6, lsl #1
    rscs r5, r0, r9, lsl #31
    rscs r2, r11, r6, lsr #1
    rscs r5, r0, r9, lsr #31
    rscs r2, r11, r6, asr #1
    rscs r5, r0, r9, asr #31
    rscs r2, r11, r6, ror #1
    rscs r5, r0, r9, ror #31
    rscs r11, r6, r1, rrx
    rscs r2, r11, r6, lsl r1
    rscs r2, r11, r6, lsr r1
    rscs r2, r11, r6, asr r1
    rscs r2, r11, r6, ror r1
    orr r2, r11, #255, 30
    orr r5, r0, #1, 0
    orr r8, r3, #63, 2
    orreq r7, r2, #255, 30
    orrle r10, r5, #1, 0
    orrhi lr, r8, #63, 2
    orr r11, r6, r1
    orreq r2, r11, r6
    orrle r5, r0, r9
    orrhi r8, r3, r12
    orr r2, r11, r6, lsl #1
    orr r5, r0, r9, lsl #31
    orr r2, r11, r6, lsr #1
    orr r5, r0, r9, lsr #31
    orr r2, r11, r6, asr #1
    orr r5, r0, r9, asr #31
    orr r2, r11, r6, ror #1
    orr r5, r0, r9, ror #31
    orr r11, r6, r1, rrx
    orr r2, r11, r6, lsl r1
    orr r2, r11, r6, lsr r1
    orr r2, r11, r6, asr r1
    orr r2, r11, r6, ror r1
    orrs r2, r11, #255, 30
    orrs r5, r0, #1, 0
    orrs r8, r3, #63, 2
    orrs r11, r6, r1
    orrs r2, r11, r6, lsl #1
    orrs r5, r0, r9, lsl #31
    orrs r2, r11, r6, lsr #1
    orrs r5, r0, r9, lsr #31
    orrs r2, r11, r6, asr #1
    orrs r5, r0, r9, asr #31
    orrs r2, r11, r6, ror #1
    orrs r5, r0, r9, ror #31
    orrs r11, r6, r1, rrx
    orrs r2, r11, r6, lsl r1
    orrs r2, r11, r6, lsr r1
    orrs r2, r11, r6, asr r1
    orrs r2, r11, r6, ror r1
    bic r2, r11, #255, 30
    bic r5, r0, #1, 0
    bic r8, r3, #63, 2
    bic r11, r6, r1
    bic r2, r11, r6, lsl #1
    bic r5, r0, r9, lsl #31
    bic r2, r11, r6, lsr #1
    bic r5, r0, r9, lsr #31
    bic r2, r11, r6, asr #1
    bic r5, r0, r9, asr #31
    bic r2, r11, r6, ror #1
    bic r5, r0, r9, ror #31
    bic r11, r6, r1, rrx
    bic r2, r11, r6, lsl r1
    bic r2, r11, r6, lsr r1
    bic r2, r11, r6, asr r1
    bic r2, r11, r6, ror r1
    bics r2, r11, #255, 30
    bics r5, r0, #1, 0
    bics r8, r3, #63, 2
    bics r11, r6, r1
    bics r2, r11, r6, lsl #1
    bics r5, r0, r9, lsl #31
    bics r2, r11, r6, lsr #1
    bics r5, r0, r9, lsr #31
    bics r2, r11, r6, asr #1
    bics r5, r0, r9, asr #31
    bics r2, r11, r6, ror #1
    bics r5, r0, r9, ror #31
    bics r11, r6, r1, rrx
    bics r2, r11, r6, lsl r1
    bics r2, r11, r6, lsr r1
    bics r2, r11, r6, asr r1
    bics r2, r11, r6, ror r1
    mov r11, #255, 30
    mov r0, #1, 0
    mov r3, #63, 2
    moveq r2, #255, 30
    movle r5, #1, 0
    movhi r8, #63, 2
    mov r6, r1
    moveq r11, r6
    movle r0, r9
    movhi r3, r12
    mov r11, r6, lsl #1
    mov r0, r9, lsl #31
    mov r11, r6, lsr #1
    mov r0, r9, lsr #31
    mov r11, r6, asr #1
    mov r0, r9, asr #31
    mov r11, r6, ror #1
    mov r0, r9, ror #31
    mov r6, r1, rrx
    mov r11, r6, lsl r1
    mov r11, r6, lsr r1
    mov r11, r6, asr r1
    mov r11, r6, ror r1
    movs r11, #255, 30
    movs r0, #1, 0
    movs r3, #63, 2
    movs r6, r1
    movs r11, r6, lsl #1
    movs r0, r9, lsl #31
    movs r11, r6, lsr #1
    movs r0, r9, lsr #31
    movs r11, r6, asr #1
    movs r0, r9, asr #31
    movs r11, r6, ror #1
    movs r0, r9, ror #31
    movs r6, r1, rrx
    movs r11, r6, lsl r1
    movs r11, r6, lsr r1
    movs r11, r6, asr r1
    movs r11, r6, ror r1
    mvn r11, #255, 30
    mvn r0, #1, 0
    mvn r3, #63, 2
    mvneq r2, #255, 30
    mvnle r5, #1, 0
    mvnhi r8, #63, 2
    mvn r6, r1
    mvneq r11, r6
    mvnle r0, r9
    mvnhi r3, r12
    mvn r11, r6, lsl #1
    mvn r0, r9, lsl #31
    mvn r11, r6, lsr #1
    mvn r0, r9, lsr #31
    mvn r11, r6, asr #1
    mvn r0, r9, asr #31
    mvn r11, r6, ror #1
    mvn r0, r9, ror #31
    mvn r6, r1, rrx
    mvn r11, r6, lsl r1
    mvn r11, r6, lsr r1
    mvn r11, r6, asr r1
    mvn r11, r6, ror r1
    mvns r11, #255, 30
    mvns r0, #1, 0
    mvns r3, #63, 2
    mvns r6, r1
    mvns r11, r6, lsl #1
    mvns r0, r9, lsl #31
    mvns r11, r6, lsr #1
    mvns r0, r9, lsr #31
    mvns r11, r6, asr #1
    mvns r0, r9, asr #31
    mvns r11, r6, ror #1
    mvns r0, r9, ror #31
    mvns r6, r1, rrx
    mvns r11, r6, lsl r1
    mvns r11, r6, lsr r1
    mvns r11, r6, asr r1
    mvns r11, r6, ror r1
    tst r11, #255, 30
    tst r0, #1, 0
    tst r3, #63, 2
    tst r6, r1
    tst r11, r6, lsl #1
    tst r0, r9, lsl #31
    tst r11, r6, lsr #1
    tst r0, r9, lsr #31
    tst r11, r6, asr #1
    tst r0, r9, asr #31
    tst r11, r6, ror #1
    tst r0, r9, ror #31
    tst r6, r1, rrx
    tst r11, r6, lsl r1
    tst r11, r6, lsr r1
    tst r11, r6, asr r1
    tst r11, r6, ror r1
    teq r11, #255, 30
    teq r0, #1, 0
    teq r3, #63, 2
    teq r6, r1
    teq r11, r6, lsl #1
    teq r0, r9, lsl #31
    teq r11, r6, lsr #1
    teq r0, r9, lsr #31
    teq r11, r6, asr #1
    teq r0, r9, asr #31
    teq r11, r6, ror #1
    teq r0, r9, ror #31
    teq r6, r1, rrx
    teq r11, r6, lsl r1
    teq r11, r6, lsr r1
    teq r11, r6, asr r1
    teq r11, r6, ror r1
    cmp r11, #255, 30
    cmp r0, #1, 0
    cmp r3, #63, 2
    cmpeq r2, #255, 30
    cmple r5, #1, 0
    cmphi r8, #63, 2
    cmp r6, r1
    cmpeq r11, r6
    cmple r0, r9
    cmphi r3, r12
    cmp r11, r6, lsl #1
    cmp r0, r9, lsl #31
    cmp r11, r6, lsr #1
    cmp r0, r9, lsr #31
    cmp r11, r6, asr #1
    cmp r0, r9, asr #31
    cmp r11, r6, ror #1
    cmp r0, r9, ror #31
    cmp r6, r1, rrx
    cmp r11, r6, lsl r1
    cmp r11, r6, lsr r1
    cmp r11, r6, asr r1
    cmp r11, r6, ror r1
    cmn r11, #255, 30
    cmn r0, #1, 0
    cmn r3, #63, 2
    cmn r6, r1
    cmn r11, r6, lsl #1
    cmn r0, r9, lsl #31
    cmn r11, r6, lsr #1
    cmn r0, r9, lsr #31
    cmn r11, r6, asr #1
    cmn r0, r9, asr #31
    cmn r11, r6, ror #1
    cmn r0, r9, ror #31
    cmn r6, r1, rrx
    cmn r11, r6, lsl r1
    cmn r11, r6, lsr r1
    cmn r11, r6, asr r1
    cmn r11, r6, ror r1
    lsl r11, r6, #1
    lsl r0, r9, #31
    lsl r11, r6, r1
    lsr r11, r6, #1
    lsr r0, r9, #31
    lsr r11, r6, r1
    asr r11, r6, #1
    asr r0, r9, #31
    asr r11, r6, r1
    ror r11, r6, #1
    ror r0, r9, #31
    ror r11, r6, r1
    rrx r6, r1
    lsls r11, r6, #1
    lsls r0, r9, #31
    lsls r11, r6, r1
    lsrs r11, r6, #1
    lsrs r0, r9, #31
    lsrs r11, r6, r1
    asrs r11, r6, #1
    asrs r0, r9, #31
    asrs r11, r6, r1
    rors r11, r6, #1
    rors r0, r9, #31
    rors r11, r6, r1
    rrxs r6, r1
    mul r11, r6, r1
    mla r2, r11, r6, r1
    umull r2, r11, r6, r1
    umlal r2, r11, r6, r1
    smull r2, r11, r6, r1
    smlal r2, r11, r6, r1
    muls r11, r6, r1
    mlas r2, r11, r6, r1
    umulls r2, r11, r6, r1
    umlals r2, r11, r6, r1
    smulls r2, r11, r6, r1
    smlals r2, r11, r6, r1
    mls r2, r11, r6, r1
    sdiv r11, r6, r1
    udiv r11, r6, r1
    movw r6, #0
    movw r9, #65535
    movw r12, #4660
    movweq r11, #0
    movwle r0, #65535
    movwhi r3, #4660
    movt r6, #0
    movt r9, #65535
    movt r12, #4660
    movteq r11, #0
    movtle r0, #65535
    movthi r3, #4660
    clz r6, r1
    rev r6, r1
    rev16 r6, r1
    revsh r6, r1
    rbit r6, r1
    sxtb r11, r6, ror #8
    sxtb r0, r9, ror #24
    sxtb r3, r12, ror #16
    sxth r11, r6, ror #8
    sxth r0, r9, ror #24
    sxth r3, r12, ror #16
    uxtb r11, r6, ror #8
    uxtb r0, r9, ror #24
    uxtb r3, r12, ror #16
    uxth r11, r6, ror #8
    uxth r0, r9, ror #24
    uxth r3, r12, ror #16
    bfc r11, #0, #32
    bfc r0, #31, #1
    bfc r3, #4, #8
    bfi r2, r11, #0, #32
    bfi r5, r0, #31, #1
    bfi r8, r3, #4, #8
    ubfx r2, r11, #0, #31
    ubfx r5, r0, #31, #1
    ubfx r8, r3, #4, #8
    sbfx r2, r11, #0, #31
    sbfx r5, r0, #31, #1
    sbfx r8, r3, #4, #8
    str r11, [r6, #-4095]
    str r0, [r9, #4095]
    str r3, [r12, #0]
    streq r2, [r11, #-4095]
    strle r5, [r0, #4095]
    strhi r8, [r3, #0]
    str r11, [r6, #-4095]!
    str r0, [r9, #4095]!
    str r3, [r12, #0]!
    str r11, [r6], #-4095
    str r0, [r9], #4095
    str r3, [r12], #0
    str r2, [r11, r6, lsl #0]
    str r5, [r0, r9, lsl #31]
    str r8, [r3, r12, lsl #2]
    str r2, [r11, r6, lsl #1]!
    str r5, [r0, r9, lsl #31]!
    str r2, [r11], r6, lsl #1
    str r5, [r0], r9, lsl #31
    ldr r11, [r6, #-4095]
    ldr r0, [r9, #4095]
    ldr r3, [r12, #0]
    ldreq r2, [r11, #-4095]
    ldrle r5, [r0, #4095]
    ldrhi r8, [r3, #0]
    ldr r11, [r6, #-4095]!
    ldr r0, [r9, #4095]!
    ldr r3, [r12, #0]!
    ldr r11, [r6], #-4095
    ldr r0, [r9], #4095
    ldr r3, [r12], #0
    ldr r2, [r11, r6, lsl #0]
    ldr r5, [r0, r9, lsl #31]
    ldr r8, [r3, r12, lsl #2]
    ldr r2, [r11, r6, lsl #1]!
    ldr r5, [r0, r9, lsl #31]!
    ldr r2, [r11], r6, lsl #1
    ldr r5, [r0], r9, lsl #31
    strb r11, [r6, #-4095]
    strb r0, [r9, #4095]
    strb r3, [r12, #0]
    strbeq r2, [r11, #-4095]
    strble r5, [r0, #4095]
    strbhi r8, [r3, #0]
    strb r11, [r6, #-4095]!
    strb r0, [r9, #4095]!
    strb r3, [r12, #0]!
    strb r11, [r6], #-4095
    strb r0, [r9], #4095
    strb r3, [r12], #0
    strb r2, [r11, r6, lsl #0]
    strb r5, [r0, r9, lsl #31]
    strb r8, [r3, r12, lsl #2]
    strb r2, [r11, r6, lsl #1]!
    strb r5, [r0, r9, lsl #31]!
    strb r2, [r11], r6, lsl #1
    strb r5, [r0], r9, lsl #31
    ldrb r11, [r6, #-4095]
    ldrb r0, [r9, #4095]
    ldrb r3, [r12, #0]
    ldrbeq r2, [r11, #-4095]
    ldrble r5, [r0, #4095]
    ldrbhi r8, [r3, #0]
    ldrb r11, [r6, #-4095]!
    ldrb r0, [r9, #4095]!
    ldrb r3, [r12, #0]!
    ldrb r11, [r6], #-4095
    ldrb r0, [r9], #4095
    ldrb r3, [r12], #0
    ldrb r2, [r11, r6, lsl #0]
    ldrb r5, [r0, r9, lsl #31]
    ldrb r8, [r3, r12, lsl #2]
    ldrb r2, [r11, r6, lsl #1]!
    ldrb r5, [r0, r9, lsl #31]!
    ldrb r2, [r11], r6, lsl #1
    ldrb r5, [r0], r9, lsl #31
    strh r11, [r6, #-255]
    strh r0, [r9, #255]
    strh r3, [r12, #0]
    strh r11, [r6, #-255]!
    strh r0, [r9, #255]!
    strh r3, [r12, #0]!
    strh r11, [r6], #-255
    strh r0, [r9], #255
    strh r3, [r12], #0
    strh r11, [r6, r1]
    strh r11, [r6, r1]!
    strh r11, [r6], r1
    ldrd r0, r1, [r3, #-255]
    ldrd r10, r11, [r12, #255]
    ldrd r4, r5, [r1, #0]
    ldrd r0, r1, [r3, #-255]!
    ldrd r10, r11, [r12, #255]!
    ldrd r4, r5, [r1, #0]!
    ldrd r0, r1, [r3], #-255
    ldrd r10, r11, [r12], #255
    ldrd r4, r5, [r1], #0
    ldrd r0, r1, [r3, r5]
    ldrd r10, r11, [r12, r1]
    ldrd r0, r1, [r3, r5]!
    ldrd r10, r11, [r12, r1]!
    ldrd r0, r1, [r3], r5
    ldrd r10, r11, [r12], r1
    strd r0, r1, [r3, #-255]
    strd r10, r11, [r12, #255]
    strd r4, r5, [r1, #0]
    strd r0, r1, [r3, #-255]!
    strd r10, r11, [r12, #255]!
    strd r4, r5, [r1, #0]!
    strd r0, r1, [r3], #-255
    strd r10, r11, [r12], #255
    strd r4, r5, [r1], #0
    strd r0, r1, [r3, r5]
    strd r10, r11, [r12, r1]
    strd r0, r1, [r3, r5]!
    strd r10, r11, [r12, r1]!
    strd r0, r1, [r3], r5
    strd r10, r11, [r12], r1
    ldrh r11, [r6, #-255]
    ldrh r0, [r9, #255]
    ldrh r3, [r12, #0]
    ldrh r11, [r6, #-255]!
    ldrh r0, [r9, #255]!
    ldrh r3, [r12, #0]!
    ldrh r11, [r6], #-255
    ldrh r0, [r9], #255
    ldrh r3, [r12], #0
    ldrh r11, [r6, r1]
    ldrh r11, [r6, r1]!
    ldrh r11, [r6], r1
    ldrsb r11, [r6, #-255]
    ldrsb r0, [r9, #255]
    ldrsb r3, [r12, #0]
    ldrsb r11, [r6, #-255]!
    ldrsb r0, [r9, #255]!
    ldrsb r3, [r12, #0]!
    ldrsb r11, [r6], #-255
    ldrsb r0, [r9], #255
    ldrsb r3, [r12], #0
    ldrsb r11, [r6, r1]
    ldrsb r11, [r6, r1]!
    ldrsb r11, [r6], r1
    ldrsh r11, [r6, #-255]
    ldrsh r0, [r9, #255]
    ldrsh r3, [r12, #0]
    ldrsh r11, [r6, #-255]!
    ldrsh r0, [r9, #255]!
    ldrsh r3, [r12, #0]!
    ldrsh r11, [r6], #-255
    ldrsh r0, [r9], #255
    ldrsh r3, [r12], #0
    ldrsh r11, [r6, r1]
    ldrsh r11, [r6, r1]!
    ldrsh r11, [r6], r1
    stmia r0, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    stmia r12, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11}
    stmia r0!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    stmia r12!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11}
    ldmia r0, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    ldmia r12, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11}
    ldmia r0!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    ldmia r12!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11}
    stmib r0, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    stmib r12, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11}
    stmib r0!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    stmib r12!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11}
    ldmib r0, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    ldmib r12, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11}
    ldmib r0!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    ldmib r12!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11}
    stmda r0, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    stmda r12, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11}
    stmda r0!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    stmda r12!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11}
    ldmda r0, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    ldmda r12, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11}
    ldmda r0!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    ldmda r12!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11}
    stmdb r0, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    stmdb r12, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11}
    stmdb r0!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    stmdb r12!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11}
    ldmdb r0, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    ldmdb r12, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11}
    ldmdb r0!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    ldmdb r12!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11}
    push {r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    push {r0, r1}
    pop {r4, r5, r6, r7, r8, r9, r10, r11, r12, pc}
    pop {r0, r1}
    ldrex r6, [r1]
    ldrexb r6, [r1]
    ldrexh r6, [r1]
    ldrexd r0, r1, [r3]
    ldrexd r10, r11, [r12]
    strex r11, r6, [r1]
    strexb r11, r6, [r1]
    strexh r11, r6, [r1]
    strexd r5, r0, r1, [r3]
    strexd r1, r10, r11, [r12]
    clrex
    dmb sy
    dmb st
    dmb ish
    dmb ishst
    dmb nsh
    dmb nshst
    dmb osh
    dmb oshst
    dsb sy
    dsb st
    dsb ish
    dsb ishst
    dsb nsh
    dsb nshst
    dsb osh
    dsb oshst
    isb sy
    b .-33554424
    b .+33554436
    b .+8
    bl .-33554424
    bl .+33554436
    bl .+8
    bleq .-33554424
    blle .+33554436
    blhi .+8
    beq .-33554424
    beq .+33554436
    beq .+8
    bne .-33554424
    bne .+33554436
    bne .+8
    bcs .-33554424
    bcs .+33554436
    bcs .+8
    bhs .-33554424
    bhs .+33554436
    bhs .+8
    bcc .-33554424
    bcc .+33554436
    bcc .+8
    blo .-33554424
    blo .+33554436
    blo .+8
    bmi .-33554424
    bmi .+33554436
    bmi .+8
    bpl .-33554424
    bpl .+33554436
    bpl .+8
    bvs .-33554424
    bvs .+33554436
    bvs .+8
    bvc .-33554424
    bvc .+33554436
    bvc .+8
    bhi .-33554424
    bhi .+33554436
    bhi .+8
    bls .-33554424
    bls .+33554436
    bls .+8
    bge .-33554424
    bge .+33554436
    bge .+8
    blt .-33554424
    blt .+33554436
    blt .+8
    bgt .-33554424
    bgt .+33554436
    bgt .+8
    ble .-33554424
    ble .+33554436
    ble .+8
    bx r1
    bxeq r6
    bxle r9
    bxhi r12
    blx r1
    blxeq r6
    blxle r9
    blxhi r12
    blx .-33554424
    blx .+33554438
    blx .+10
    svc #0
    svc #16777215
    svceq #0
    svcle #16777215
    svchi #0
    mrs r1, cpsr
    mrs r1, spsr
    msr cpsr_f, r1
    msr cpsr_fc, r4
    msr cpsr_fsxc, r7
    msr spsr_f, r1
    msr spsr_fc, r4
    msr spsr_fsxc, r7
    msr cpsr_f, #0x3fc
    msr cpsr_fc, #0x1
    msr cpsr_fsxc, #0xc000000f
    msr spsr_f, #0x3fc
    msr spsr_fc, #0x1
    msr spsr_fsxc, #0xc000000f
    cpsie aif
    cpsie f
    cpsie a
    cpsid aif
    cpsid f
    cpsid a
    cps #16
    cps #31
    cps #19
    nop
    yield
    wfe
    wfi
    sev
    bkpt #0
    bkpt #65535
    bkpt #4660
    udf #0
    udf #65535
    udf #4660
    vmla.f32 s21, s10, s31
    vmls.f32 s21, s10, s31
    vnmul.f32 s21, s10, s31
    vmul.f32 s21, s10, s31
    vadd.f32 s21, s10, s31
    vsub.f32 s21, s10, s31
    vdiv.f32 s21, s10, s31
    vmov.f32 s10, s31
    vabs.f32 s10, s31
    vneg.f32 s10, s31
    vsqrt.f32 s10, s31
    vcmp.f32 s10, s31
    vcmpe.f32 s10, s31
    vcmp.f32 s31, #0
    vcmpe.f32 s31, #0
    vmov.f32 s10, #1
    vmov.f32 s17, #2
    vmov.f32 s24, #-1.9375
    vmov.f32 s31, #-2
    vcvt.s32.f32 s10, s31
    vcvt.u32.f32 s10, s31
    vcvt.f32.s32 s10, s31
    vcvt.f32.u32 s10, s31
    vmla.f64 d21, d10, d31
    vmls.f64 d21, d10, d31
    vnmul.f64 d21, d10, d31
    vmul.f64 d21, d10, d31
    vadd.f64 d21, d10, d31
    vsub.f64 d21, d10, d31
    vdiv.f64 d21, d10, d31
    vmov.f64 d10, d31
    vabs.f64 d10, d31
    vneg.f64 d10, d31
    vsqrt.f64 d10, d31
    vcmp.f64 d10, d31
    vcmpe.f64 d10, d31
    vcmp.f64 d31, #0
    vcmpe.f64 d31, #0
    vmov.f64 d10, #1
    vmov.f64 d17, #2
    vmov.f64 d24, #-1.9375
    vmov.f64 d31, #-2
    vcvt.s32.f64 s10, d31
    vcvt.u32.f64 s10, d31
    vcvt.f64.s32 d10, s31
    vcvt.f64.u32 d10, s31
    vcvt.f64.f32 d10, s31
    vcvt.f32.f64 s10, d31
    vldr.32 s21, [r6, #-1020]
    vldr.32 s28, [r9, #1020]
    vldr.32 s3, [r12, #0]
    vstr.32 s21, [r6, #-1020]
    vstr.32 s28, [r9, #1020]
    vstr.32 s3, [r12, #0]
    vldr.64 d21, [r6, #-1020]
    vldr.64 d28, [r9, #1020]
    vldr.64 d3, [r12, #0]
    vstr.64 d21, [r6, #-1020]
    vstr.64 d28, [r9, #1020]
    vstr.64 d3, [r12, #0]
    vpush.32 {s0-s31}
    vpush.32 {s16-s31}
    vpush.32 {s31}
    vpop.32 {s0-s31}
    vpop.32 {s16-s31}
    vpop.32 {s31}
    vpush.64 {d0-d15}
    vpush.64 {d16-d31}
    vpush.64 {d8-d15}
    vpush.64 {d31}
    vpop.64 {d0-d15}
    vpop.64 {d16-d31}
    vpop.64 {d8-d15}
    vpop.64 {d31}
    vmov s10, r1
    vmov r6, s31
    vmov d21, r6, r1
    vmov r11, r6, d31
    vmrs r1, fpscr
    vmrs APSR_nzcv, fpscr
    vmsr fpscr, r1
    .thumb
    lsls r7, r4, #1
    lsls r2, r7, #31
    lsrs r7, r4, #1
    lsrs r2, r7, #31
    asrs r7, r4, #1
    asrs r2, r7, #31
    adds r7, r4, r1
    subs r7, r4, r1
    adds r7, r4, #0
    adds r2, r7, #7
    subs r7, r4, #0
    subs r2, r7, #7
    movs r4, #0
    movs r7, #255
    cmp r4, #0
    cmp r7, #255
    adds r4, #0
    adds r7, #255
    subs r4, #0
    subs r7, #255
    ands r4, r1
    eors r4, r1
    lsls r4, r1
    lsrs r4, r1
    asrs r4, r1
    adcs r4, r1
    sbcs r4, r1
    rors r4, r1
    tst r4, r1
    rsbs r4, r1, #0
    cmp r4, r1
    cmn r4, r1
    orrs r4, r1
    muls r4, r1, r4
    bics r4, r1
    mvns r4, r1
    add r8, r9
    add r12, lr
    add r1, r10
    cmp r8, r9
    cmp r12, lr
    cmp r1, r10
    mov r8, r9
    mov r12, lr
    mov r1, r10
    bx r1
    blx r1
    ldr r4, [pc, #0]
    ldr r7, [pc, #1020]
    str r7, [r4, r1]
    strh r7, [r4, r1]
    strb r7, [r4, r1]
    ldrsb r7, [r4, r1]
    ldr r7, [r4, r1]
    ldrh r7, [r4, r1]
    ldrb r7, [r4, r1]
    ldrsh r7, [r4, r1]
    str r7, [r4, #0]
    str r2, [r7, #124]
    ldr r7, [r4, #0]
    ldr r2, [r7, #124]
    strb r7, [r4, #0]
    strb r2, [r7, #31]
    ldrb r7, [r4, #0]
    ldrb r2, [r7, #31]
    strh r7, [r4, #0]
    strh r2, [r7, #62]
    ldrh r7, [r4, #0]
    ldrh r2, [r7, #62]
    str r4, [sp, #0]
    str r7, [sp, #1020]
    ldr r4, [sp, #0]
    ldr r7, [sp, #1020]
    add r4, pc, #0
    add r7, pc, #1020
    add r4, sp, #0
    add r7, sp, #1020
    add sp, sp, #0
    add sp, sp, #508
    sub sp, sp, #0
    sub sp, sp, #508
    cbz r4, .+4
    cbz r7, .+130
    cbnz r4, .+4
    cbnz r7, .+130
    sxth r4, r1
    sxtb r4, r1
    uxth r4, r1
    uxtb r4, r1
    push {r0, r1, r2, r3, r4, r5, r6, r7, lr}
    push {r0}
    push {lr}
    pop {r0, r1, r2, r3, r4, r5, r6, r7, pc}
    pop {r7}
    pop {pc}
    cpsie aif
    cpsie f
    cpsie a
    cpsid aif
    cpsid f
    cpsid a
    rev r4, r1
    rev16 r4, r1
    revsh r4, r1
    bkpt #0
    bkpt #255
    it eq
    moveq r8, r9
    ite le
    movle r8, r9
    movgt r8, r9
    itt ne
    movne r8, r9
    movne r8, r9
    nop
    yield
    wfe
    wfi
    sev
    stmia r0!, {r1, r2, r3, r4, r5, r6, r7}
    stmia r7!, {r0, r1, r2, r3, r4, r5, r6}
    ldmia r0!, {r1, r2, r3, r4, r5, r6, r7}
    ldmia r7!, {r0, r1, r2, r3, r4, r5, r6}
    beq .-252
    beq .+258
    beq .+4
    bne .-252
    bne .+258
    bne .+4
    bcs .-252
    bcs .+258
    bcs .+4
    bhs .-252
    bhs .+258
    bhs .+4
    bcc .-252
    bcc .+258
    bcc .+4
    blo .-252
    blo .+258
    blo .+4
    bmi .-252
    bmi .+258
    bmi .+4
    bpl .-252
    bpl .+258
    bpl .+4
    bvs .-252
    bvs .+258
    bvs .+4
    bvc .-252
    bvc .+258
    bvc .+4
    bhi .-252
    bhi .+258
    bhi .+4
    bls .-252
    bls .+258
    bls .+4
    bge .-252
    bge .+258
    bge .+4
    blt .-252
    blt .+258
    blt .+4
    bgt .-252
    bgt .+258
    bgt .+4
    ble .-252
    ble .+258
    ble .+4
    udf #0
    udf #255
    svc #0
    svc #255
    b .-2044
    b .+2050
    b .+4
    and.w r11, r6, #0xff
    and.w r0, r9, #0xa500a5
    and.w r3, r12, #0x5a005a00
    and.w r6, r1, #0xc3c3c3c3
    and.w r9, r4, #0x1fe
    and.w r12, r7, #0x80000000
    and.w r11, r6, r1
    and.w r2, r11, r6, lsl #1
    and.w r5, r0, r9, lsl #31
    and.w r2, r11, r6, lsr #1
    and.w r5, r0, r9, lsr #31
    and.w r2, r11, r6, asr #1
    and.w r5, r0, r9, asr #31
    and.w r2, r11, r6, ror #1
    and.w r5, r0, r9, ror #31
    ands.w r11, r6, #0xff
    ands.w r0, r9, #0xa500a5
    ands.w r3, r12, #0x5a005a00
    ands.w r6, r1, #0xc3c3c3c3
    ands.w r9, r4, #0x1fe
    ands.w r12, r7, #0x80000000
    ands.w r11, r6, r1
    ands.w r2, r11, r6, lsl #1
    ands.w r5, r0, r9, lsl #31
    ands.w r2, r11, r6, lsr #1
    ands.w r5, r0, r9, lsr #31
    ands.w r2, r11, r6, asr #1
    ands.w r5, r0, r9, asr #31
    ands.w r2, r11, r6, ror #1
    ands.w r5, r0, r9, ror #31
    bic.w r11, r6, #0xff
    bic.w r0, r9, #0xa500a5
    bic.w r3, r12, #0x5a005a00
    bic.w r6, r1, #0xc3c3c3c3
    bic.w r9, r4, #0x1fe
    bic.w r12, r7, #0x80000000
    bic.w r11, r6, r1
    bic.w r2, r11, r6, lsl #1
    bic.w r5, r0, r9, lsl #31
    bic.w r2, r11, r6, lsr #1
    bic.w r5, r0, r9, lsr #31
    bic.w r2, r11, r6, asr #1
    bic.w r5, r0, r9, asr #31
    bic.w r2, r11, r6, ror #1
    bic.w r5, r0, r9, ror #31
    bics.w r11, r6, #0xff
    bics.w r0, r9, #0xa500a5
    bics.w r3, r12, #0x5a005a00
    bics.w r6, r1, #0xc3c3c3c3
    bics.w r9, r4, #0x1fe
    bics.w r12, r7, #0x80000000
    bics.w r11, r6, r1
    bics.w r2, r11, r6, lsl #1
    bics.w r5, r0, r9, lsl #31
    bics.w r2, r11, r6, lsr #1
    bics.w r5, r0, r9, lsr #31
    bics.w r2, r11, r6, asr #1
    bics.w r5, r0, r9, asr #31
    bics.w r2, r11, r6, ror #1
    bics.w r5, r0, r9, ror #31
    orr.w r11, r6, #0xff
    orr.w r0, r9, #0xa500a5
    orr.w r3, r12, #0x5a005a00
    orr.w r6, r1, #0xc3c3c3c3
    orr.w r9, r4, #0x1fe
    orr.w r12, r7, #0x80000000
    orr.w r11, r6, r1
    orr.w r2, r11, r6, lsl #1
    orr.w r5, r0, r9, lsl #31
    orr.w r2, r11, r6, lsr #1
    orr.w r5, r0, r9, lsr #31
    orr.w r2, r11, r6, asr #1
    orr.w r5, r0, r9, asr #31
    orr.w r2, r11, r6, ror #1
    orr.w r5, r0, r9, ror #31
    orrs.w r11, r6, #0xff
    orrs.w r0, r9, #0xa500a5
    orrs.w r3, r12, #0x5a005a00
    orrs.w r6, r1, #0xc3c3c3c3
    orrs.w r9, r4, #0x1fe
    orrs.w r12, r7, #0x80000000
    orrs.w r11, r6, r1
    orrs.w r2, r11, r6, lsl #1
    orrs.w r5, r0, r9, lsl #31
    orrs.w r2, r11, r6, lsr #1
    orrs.w r5, r0, r9, lsr #31
    orrs.w r2, r11, r6, asr #1
    orrs.w r5, r0, r9, asr #31
    orrs.w r2, r11, r6, ror #1
    orrs.w r5, r0, r9, ror #31
    orn.w r11, r6, #0xff
    orn.w r0, r9, #0xa500a5
    orn.w r3, r12, #0x5a005a00
    orn.w r6, r1, #0xc3c3c3c3
    orn.w r9, r4, #0x1fe
    orn.w r12, r7, #0x80000000
    orn.w r11, r6, r1
    orn.w r2, r11, r6, lsl #1
    orn.w r5, r0, r9, lsl #31
    orn.w r2, r11, r6, lsr #1
    orn.w r5, r0, r9, lsr #31
    orn.w r2, r11, r6, asr #1
    orn.w r5, r0, r9, asr #31
    orn.w r2, r11, r6, ror #1
    orn.w r5, r0, r9, ror #31
    orns.w r11, r6, #0xff
    orns.w r0, r9, #0xa500a5
    orns.w r3, r12, #0x5a005a00
    orns.w r6, r1, #0xc3c3c3c3
    orns.w r9, r4, #0x1fe
    orns.w r12, r7, #0x80000000
    orns.w r11, r6, r1
    orns.w r2, r11, r6, lsl #1
    orns.w r5, r0, r9, lsl #31
    orns.w r2, r11, r6, lsr #1
    orns.w r5, r0, r9, lsr #31
    orns.w r2, r11, r6, asr #1
    orns.w r5, r0, r9, asr #31
    orns.w r2, r11, r6, ror #1
    orns.w r5, r0, r9, ror #31
    eor.w r11, r6, #0xff
    eor.w r0, r9, #0xa500a5
    eor.w r3, r12, #0x5a005a00
    eor.w r6, r1, #0xc3c3c3c3
    eor.w r9, r4, #0x1fe
    eor.w r12, r7, #0x80000000
    eor.w r11, r6, r1
    eor.w r2, r11, r6, lsl #1
    eor.w r5, r0, r9, lsl #31
    eor.w r2, r11, r6, lsr #1
    eor.w r5, r0, r9, lsr #31
    eor.w r2, r11, r6, asr #1
    eor.w r5, r0, r9, asr #31
    eor.w r2, r11, r6, ror #1
    eor.w r5, r0, r9, ror #31
    eors.w r11, r6, #0xff
    eors.w r0, r9, #0xa500a5
    eors.w r3, r12, #0x5a005a00
    eors.w r6, r1, #0xc3c3c3c3
    eors.w r9, r4, #0x1fe
    eors.w r12, r7, #0x80000000
    eors.w r11, r6, r1
    eors.w r2, r11, r6, lsl #1
    eors.w r5, r0, r9, lsl #31
    eors.w r2, r11, r6, lsr #1
    eors.w r5, r0, r9, lsr #31
    eors.w r2, r11, r6, asr #1
    eors.w r5, r0, r9, asr #31
    eors.w r2, r11, r6, ror #1
    eors.w r5, r0, r9, ror #31
    add.w r11, r6, #0xff
    add.w r0, r9, #0xa500a5
    add.w r3, r12, #0x5a005a00
    add.w r6, r1, #0xc3c3c3c3
    add.w r9, r4, #0x1fe
    add.w r12, r7, #0x80000000
    add.w r11, r6, r1
    add.w r2, r11, r6, lsl #1
    add.w r5, r0, r9, lsl #31
    add.w r2, r11, r6, lsr #1
    add.w r5, r0, r9, lsr #31
    add.w r2, r11, r6, asr #1
    add.w r5, r0, r9, asr #31
    add.w r2, r11, r6, ror #1
    add.w r5, r0, r9, ror #31
    adds.w r11, r6, #0xff
    adds.w r0, r9, #0xa500a5
    adds.w r3, r12, #0x5a005a00
    adds.w r6, r1, #0xc3c3c3c3
    adds.w r9, r4, #0x1fe
    adds.w r12, r7, #0x80000000
    adds.w r11, r6, r1
    adds.w r2, r11, r6, lsl #1
    adds.w r5, r0, r9, lsl #31
    adds.w r2, r11, r6, lsr #1
    adds.w r5, r0, r9, lsr #31
    adds.w r2, r11, r6, asr #1
    adds.w r5, r0, r9, asr #31
    adds.w r2, r11, r6, ror #1
    adds.w r5, r0, r9, ror #31
    adc.w r11, r6, #0xff
    adc.w r0, r9, #0xa500a5
    adc.w r3, r12, #0x5a005a00
    adc.w r6, r1, #0xc3c3c3c3
    adc.w r9, r4, #0x1fe
    adc.w r12, r7, #0x80000000
    adc.w r11, r6, r1
    adc.w r2, r11, r6, lsl #1
    adc.w r5, r0, r9, lsl #31
    adc.w r2, r11, r6, lsr #1
    adc.w r5, r0, r9, lsr #31
    adc.w r2, r11, r6, asr #1
    adc.w r5, r0, r9, asr #31
    adc.w r2, r11, r6, ror #1
    adc.w r5, r0, r9, ror #31
    adcs.w r11, r6, #0xff
    adcs.w r0, r9, #0xa500a5
    adcs.w r3, r12, #0x5a005a00
    adcs.w r6, r1, #0xc3c3c3c3
    adcs.w r9, r4, #0x1fe
    adcs.w r12, r7, #0x80000000
    adcs.w r11, r6, r1
    adcs.w r2, r11, r6, lsl #1
    adcs.w r5, r0, r9, lsl #31
    adcs.w r2, r11, r6, lsr #1
    adcs.w r5, r0, r9, lsr #31
    adcs.w r2, r11, r6, asr #1
    adcs.w r5, r0, r9, asr #31
    adcs.w r2, r11, r6, ror #1
    adcs.w r5, r0, r9, ror #31
    sbc.w r11, r6, #0xff
    sbc.w r0, r9, #0xa500a5
    sbc.w r3, r12, #0x5a005a00
    sbc.w r6, r1, #0xc3c3c3c3
    sbc.w r9, r4, #0x1fe
    sbc.w r12, r7, #0x80000000
    sbc.w r11, r6, r1
    sbc.w r2, r11, r6, lsl #1
    sbc.w r5, r0, r9, lsl #31
    sbc.w r2, r11, r6, lsr #1
    sbc.w r5, r0, r9, lsr #31
    sbc.w r2, r11, r6, asr #1
    sbc.w r5, r0, r9, asr #31
    sbc.w r2, r11, r6, ror #1
    sbc.w r5, r0, r9, ror #31
    sbcs.w r11, r6, #0xff
    sbcs.w r0, r9, #0xa500a5
    sbcs.w r3, r12, #0x5a005a00
    sbcs.w r6, r1, #0xc3c3c3c3
    sbcs.w r9, r4, #0x1fe
    sbcs.w r12, r7, #0x80000000
    sbcs.w r11, r6, r1
    sbcs.w r2, r11, r6, lsl #1
    sbcs.w r5, r0, r9, lsl #31
    sbcs.w r2, r11, r6, lsr #1
    sbcs.w r5, r0, r9, lsr #31
    sbcs.w r2, r11, r6, asr #1
    sbcs.w r5, r0, r9, asr #31
    sbcs.w r2, r11, r6, ror #1
    sbcs.w r5, r0, r9, ror #31
    sub.w r11, r6, #0xff
    sub.w r0, r9, #0xa500a5
    sub.w r3, r12, #0x5a005a00
    sub.w r6, r1, #0xc3c3c3c3
    sub.w r9, r4, #0x1fe
    sub.w r12, r7, #0x80000000
    sub.w r11, r6, r1
    sub.w r2, r11, r6, lsl #1
    sub.w r5, r0, r9, lsl #31
    sub.w r2, r11, r6, lsr #1
    sub.w r5, r0, r9, lsr #31
    sub.w r2, r11, r6, asr #1
    sub.w r5, r0, r9, asr #31
    sub.w r2, r11, r6, ror #1
    sub.w r5, r0, r9, ror #31
    subs.w r11, r6, #0xff
    subs.w r0, r9, #0xa500a5
    subs.w r3, r12, #0x5a005a00
    subs.w r6, r1, #0xc3c3c3c3
    subs.w r9, r4, #0x1fe
    subs.w r12, r7, #0x80000000
    subs.w r11, r6, r1
    subs.w r2, r11, r6, lsl #1
    subs.w r5, r0, r9, lsl #31
    subs.w r2, r11, r6, lsr #1
    subs.w r5, r0, r9, lsr #31
    subs.w r2, r11, r6, asr #1
    subs.w r5, r0, r9, asr #31
    subs.w r2, r11, r6, ror #1
    subs.w r5, r0, r9, ror #31
    rsb.w r11, r6, #0xff
    rsb.w r0, r9, #0xa500a5
    rsb.w r3, r12, #0x5a005a00
    rsb.w r6, r1, #0xc3c3c3c3
    rsb.w r9, r4, #0x1fe
    rsb.w r12, r7, #0x80000000
    rsb.w r11, r6, r1
    rsb.w r2, r11, r6, lsl #1
    rsb.w r5, r0, r9, lsl #31
    rsb.w r2, r11, r6, lsr #1
    rsb.w r5, r0, r9, lsr #31
    rsb.w r2, r11, r6, asr #1
    rsb.w r5, r0, r9, asr #31
    rsb.w r2, r11, r6, ror #1
    rsb.w r5, r0, r9, ror #31
    rsbs.w r11, r6, #0xff
    rsbs.w r0, r9, #0xa500a5
    rsbs.w r3, r12, #0x5a005a00
    rsbs.w r6, r1, #0xc3c3c3c3
    rsbs.w r9, r4, #0x1fe
    rsbs.w r12, r7, #0x80000000
    rsbs.w r11, r6, r1
    rsbs.w r2, r11, r6, lsl #1
    rsbs.w r5, r0, r9, lsl #31
    rsbs.w r2, r11, r6, lsr #1
    rsbs.w r5, r0, r9, lsr #31
    rsbs.w r2, r11, r6, asr #1
    rsbs.w r5, r0, r9, asr #31
    rsbs.w r2, r11, r6, ror #1
    rsbs.w r5, r0, r9, ror #31
    mov.w r6, #0xff
    mov.w r9, #0xa500a5
    mov.w r12, #0x5a005a00
    mov.w r1, #0xc3c3c3c3
    mov.w r4, #0x1fe
    mov.w r7, #0x80000000
    mov.w r6, r1
    mov.w r11, r6, lsl #1
    mov.w r0, r9, lsl #31
    mov.w r11, r6, lsr #1
    mov.w r0, r9, lsr #31
    mov.w r11, r6, asr #1
    mov.w r0, r9, asr #31
    mov.w r11, r6, ror #1
    mov.w r0, r9, ror #31
    movs.w r6, #0xff
    movs.w r9, #0xa500a5
    movs.w r12, #0x5a005a00
    movs.w r1, #0xc3c3c3c3
    movs.w r4, #0x1fe
    movs.w r7, #0x80000000
    movs.w r6, r1
    movs.w r11, r6, lsl #1
    movs.w r0, r9, lsl #31
    movs.w r11, r6, lsr #1
    movs.w r0, r9, lsr #31
    movs.w r11, r6, asr #1
    movs.w r0, r9, asr #31
    movs.w r11, r6, ror #1
    movs.w r0, r9, ror #31
    mvn.w r6, #0xff
    mvn.w r9, #0xa500a5
    mvn.w r12, #0x5a005a00
    mvn.w r1, #0xc3c3c3c3
    mvn.w r4, #0x1fe
    mvn.w r7, #0x80000000
    mvn.w r6, r1
    mvn.w r11, r6, lsl #1
    mvn.w r0, r9, lsl #31
    mvn.w r11, r6, lsr #1
    mvn.w r0, r9, lsr #31
    mvn.w r11, r6, asr #1
    mvn.w r0, r9, asr #31
    mvn.w r11, r6, ror #1
    mvn.w r0, r9, ror #31
    mvns.w r6, #0xff
    mvns.w r9, #0xa500a5
    mvns.w r12, #0x5a005a00
    mvns.w r1, #0xc3c3c3c3
    mvns.w r4, #0x1fe
    mvns.w r7, #0x80000000
    mvns.w r6, r1
    mvns.w r11, r6, lsl #1
    mvns.w r0, r9, lsl #31
    mvns.w r11, r6, lsr #1
    mvns.w r0, r9, lsr #31
    mvns.w r11, r6, asr #1
    mvns.w r0, r9, asr #31
    mvns.w r11, r6, ror #1
    mvns.w r0, r9, ror #31
    tst.w r6, #0xff
    tst.w r9, #0xa500a5
    tst.w r12, #0x5a005a00
    tst.w r1, #0xc3c3c3c3
    tst.w r4, #0x1fe
    tst.w r7, #0x80000000
    tst.w r6, r1
    tst.w r11, r6, lsl #1
    tst.w r0, r9, lsl #31
    tst.w r11, r6, lsr #1
    tst.w r0, r9, lsr #31
    tst.w r11, r6, asr #1
    tst.w r0, r9, asr #31
    tst.w r11, r6, ror #1
    tst.w r0, r9, ror #31
    teq.w r6, #0xff
    teq.w r9, #0xa500a5
    teq.w r12, #0x5a005a00
    teq.w r1, #0xc3c3c3c3
    teq.w r4, #0x1fe
    teq.w r7, #0x80000000
    teq.w r6, r1
    teq.w r11, r6, lsl #1
    teq.w r0, r9, lsl #31
    teq.w r11, r6, lsr #1
    teq.w r0, r9, lsr #31
    teq.w r11, r6, asr #1
    teq.w r0, r9, asr #31
    teq.w r11, r6, ror #1
    teq.w r0, r9, ror #31
    cmn.w r6, #0xff
    cmn.w r9, #0xa500a5
    cmn.w r12, #0x5a005a00
    cmn.w r1, #0xc3c3c3c3
    cmn.w r4, #0x1fe
    cmn.w r7, #0x80000000
    cmn.w r6, r1
    cmn.w r11, r6, lsl #1
    cmn.w r0, r9, lsl #31
    cmn.w r11, r6, lsr #1
    cmn.w r0, r9, lsr #31
    cmn.w r11, r6, asr #1
    cmn.w r0, r9, asr #31
    cmn.w r11, r6, ror #1
    cmn.w r0, r9, ror #31
    cmp.w r6, #0xff
    cmp.w r9, #0xa500a5
    cmp.w r12, #0x5a005a00
    cmp.w r1, #0xc3c3c3c3
    cmp.w r4, #0x1fe
    cmp.w r7, #0x80000000
    cmp.w r6, r1
    cmp.w r11, r6, lsl #1
    cmp.w r0, r9, lsl #31
    cmp.w r11, r6, lsr #1
    cmp.w r0, r9, lsr #31
    cmp.w r11, r6, asr #1
    cmp.w r0, r9, asr #31
    cmp.w r11, r6, ror #1
    cmp.w r0, r9, ror #31
    addw r11, r6, #0
    addw r0, r9, #4095
    addw r3, r12, #291
    subw r11, r6, #0
    subw r0, r9, #4095
    subw r3, r12, #291
    movw r6, #0
    movw r9, #65535
    movw r12, #4660
    movt r6, #0
    movt r9, #65535
    movt r12, #4660
    lsl.w r11, r6, r1
    lsr.w r11, r6, r1
    asr.w r11, r6, r1
    ror.w r11, r6, r1
    lsls.w r11, r6, r1
    lsrs.w r11, r6, r1
    asrs.w r11, r6, r1
    rors.w r11, r6, r1
    mul.w r11, r6, r1
    mla r2, r11, r6, r1
    mls r2, r11, r6, r1
    smull r2, r11, r6, r1
    umull r2, r11, r6, r1
    smlal r2, r11, r6, r1
    umlal r2, r11, r6, r1
    sdiv r11, r6, r1
    udiv r11, r6, r1
    clz r6, r1
    rbit r6, r1
    rev.w r6, r1
    rev16.w r6, r1
    revsh.w r6, r1
    sxth.w r11, r6, ror #8
    sxth.w r0, r9, ror #24
    sxth.w r3, r12, ror #16
    uxth.w r11, r6, ror #8
    uxth.w r0, r9, ror #24
    uxth.w r3, r12, ror #16
    sxtb.w r11, r6, ror #8
    sxtb.w r0, r9, ror #24
    sxtb.w r3, r12, ror #16
    uxtb.w r11, r6, ror #8
    uxtb.w r0, r9, ror #24
    uxtb.w r3, r12, ror #16
    bfc r11, #0, #32
    bfc r0, #31, #1
    bfc r3, #4, #8
    bfi r2, r11, #0, #32
    bfi r5, r0, #31, #1
    bfi r8, r3, #4, #8
    ubfx r2, r11, #0, #31
    ubfx r5, r0, #31, #1
    ubfx r8, r3, #4, #8
    sbfx r2, r11, #0, #31
    sbfx r5, r0, #31, #1
    sbfx r8, r3, #4, #8
    str.w r11, [r6, #0]
    str.w r0, [r9, #4095]
    str.w r3, [r12, #291]
    str r11, [r6, #-1]
    str r0, [r9, #-255]
    str r11, [r6, #-255]!
    str r0, [r9, #255]!
    str r11, [r6], #-255
    str r0, [r9], #255
    str.w r2, [r11, r6, lsl #0]
    str.w r5, [r0, r9, lsl #3]
    str.w r8, [r3, r12, lsl #1]
    strb.w r11, [r6, #0]
    strb.w r0, [r9, #4095]
    strb.w r3, [r12, #291]
    strb r11, [r6, #-1]
    strb r0, [r9, #-255]
    strb r11, [r6, #-255]!
    strb r0, [r9, #255]!
    strb r11, [r6], #-255
    strb r0, [r9], #255
    strb.w r2, [r11, r6, lsl #0]
    strb.w r5, [r0, r9, lsl #3]
    strb.w r8, [r3, r12, lsl #1]
    strh.w r11, [r6, #0]
    strh.w r0, [r9, #4095]
    strh.w r3, [r12, #291]
    strh r11, [r6, #-1]
    strh r0, [r9, #-255]
    strh r11, [r6, #-255]!
    strh r0, [r9, #255]!
    strh r11, [r6], #-255
    strh r0, [r9], #255
    strh.w r2, [r11, r6, lsl #0]
    strh.w r5, [r0, r9, lsl #3]
    strh.w r8, [r3, r12, lsl #1]
    ldr.w r11, [r6, #0]
    ldr.w r0, [r9, #4095]
    ldr.w r3, [r12, #291]
    ldr r11, [r6, #-1]
    ldr r0, [r9, #-255]
    ldr r11, [r6, #-255]!
    ldr r0, [r9, #255]!
    ldr r11, [r6], #-255
    ldr r0, [r9], #255
    ldr.w r2, [r11, r6, lsl #0]
    ldr.w r5, [r0, r9, lsl #3]
    ldr.w r8, [r3, r12, lsl #1]
    ldrb.w r11, [r6, #0]
    ldrb.w r0, [r9, #4095]
    ldrb.w r3, [r12, #291]
    ldrb r11, [r6, #-1]
    ldrb r0, [r9, #-255]
    ldrb r11, [r6, #-255]!
    ldrb r0, [r9, #255]!
    ldrb r11, [r6], #-255
    ldrb r0, [r9], #255
    ldrb.w r2, [r11, r6, lsl #0]
    ldrb.w r5, [r0, r9, lsl #3]
    ldrb.w r8, [r3, r12, lsl #1]
    ldrh.w r11, [r6, #0]
    ldrh.w r0, [r9, #4095]
    ldrh.w r3, [r12, #291]
    ldrh r11, [r6, #-1]
    ldrh r0, [r9, #-255]
    ldrh r11, [r6, #-255]!
    ldrh r0, [r9, #255]!
    ldrh r11, [r6], #-255
    ldrh r0, [r9], #255
    ldrh.w r2, [r11, r6, lsl #0]
    ldrh.w r5, [r0, r9, lsl #3]
    ldrh.w r8, [r3, r12, lsl #1]
    ldrsb.w r11, [r6, #0]
    ldrsb.w r0, [r9, #4095]
    ldrsb.w r3, [r12, #291]
    ldrsb r11, [r6, #-1]
    ldrsb r0, [r9, #-255]
    ldrsb r11, [r6, #-255]!
    ldrsb r0, [r9, #255]!
    ldrsb r11, [r6], #-255
    ldrsb r0, [r9], #255
    ldrsb.w r2, [r11, r6, lsl #0]
    ldrsb.w r5, [r0, r9, lsl #3]
    ldrsb.w r8, [r3, r12, lsl #1]
    ldrsh.w r11, [r6, #0]
    ldrsh.w r0, [r9, #4095]
    ldrsh.w r3, [r12, #291]
    ldrsh r11, [r6, #-1]
    ldrsh r0, [r9, #-255]
    ldrsh r11, [r6, #-255]!
    ldrsh r0, [r9, #255]!
    ldrsh r11, [r6], #-255
    ldrsh r0, [r9], #255
    ldrsh.w r2, [r11, r6, lsl #0]
    ldrsh.w r5, [r0, r9, lsl #3]
    ldrsh.w r8, [r3, r12, lsl #1]
    strd r2, r11, [r6, #-1020]
    strd r5, r0, [r9, #1020]
    strd r8, r3, [r12, #0]
    strd r2, r11, [r6, #-1020]!
    strd r5, r0, [r9, #1020]!
    strd r8, r3, [r12, #0]!
    strd r2, r11, [r6], #-1020
    strd r5, r0, [r9], #1020
    strd r8, r3, [r12], #0
    ldrd r2, r11, [r6, #-1020]
    ldrd r5, r0, [r9, #1020]
    ldrd r8, r3, [r12, #0]
    ldrd r2, r11, [r6, #-1020]!
    ldrd r5, r0, [r9, #1020]!
    ldrd r8, r3, [r12, #0]!
    ldrd r2, r11, [r6], #-1020
    ldrd r5, r0, [r9], #1020
    ldrd r8, r3, [r12], #0
    stmia.w r0, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    stmia.w r12, {r1, r2}
    stmia.w r0!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    stmia.w r12!, {r1, r2}
    ldmia.w r0, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    ldmia.w r12, {r1, r2}
    ldmia.w r0!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    ldmia.w r12!, {r1, r2}
    stmdb.w r0, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    stmdb.w r12, {r1, r2}
    stmdb.w r0!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    stmdb.w r12!, {r1, r2}
    ldmdb.w r0, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    ldmdb.w r12, {r1, r2}
    ldmdb.w r0!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    ldmdb.w r12!, {r1, r2}
    push.w {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
    push.w {r8, r9}
    pop.w {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, pc}
    pop.w {r8, r9}
    ldrex r11, [r6, #0]
    ldrex r0, [r9, #1020]
    strex r2, r11, [r6, #0]
    strex r5, r0, [r9, #1020]
    dmb sy
    dmb st
    dmb ish
    dmb ishst
    dmb nsh
    dmb nshst
    dmb osh
    dmb oshst
    dsb sy
    dsb st
    dsb ish
    dsb ishst
    dsb nsh
    dsb nshst
    dsb osh
    dsb oshst
    isb sy
    b.w .-16777212
    b.w .+16777218
    b.w .+4
    bl .-16777212
    bl .+16777218
    bl .+4
    beq.w .-1048572
    beq.w .+1048578
    beq.w .+4
    bne.w .-1048572
    bne.w .+1048578
    bne.w .+4
    bcs.w .-1048572
    bcs.w .+1048578
    bcs.w .+4
    bhs.w .-1048572
    bhs.w .+1048578
    bhs.w .+4
    bcc.w .-1048572
    bcc.w .+1048578
    bcc.w .+4
    blo.w .-1048572
    blo.w .+1048578
    blo.w .+4
    bmi.w .-1048572
    bmi.w .+1048578
    bmi.w .+4
    bpl.w .-1048572
    bpl.w .+1048578
    bpl.w .+4
    bvs.w .-1048572
    bvs.w .+1048578
    bvs.w .+4
    bvc.w .-1048572
    bvc.w .+1048578
    bvc.w .+4
    bhi.w .-1048572
    bhi.w .+1048578
    bhi.w .+4
    bls.w .-1048572
    bls.w .+1048578
    bls.w .+4
    bge.w .-1048572
    bge.w .+1048578
    bge.w .+4
    blt.w .-1048572
    blt.w .+1048578
    blt.w .+4
    bgt.w .-1048572
    bgt.w .+1048578
    bgt.w .+4
    ble.w .-1048572
    ble.w .+1048578
    ble.w .+4
