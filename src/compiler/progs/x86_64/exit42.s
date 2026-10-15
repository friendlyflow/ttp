# exit42.s — progs/x86_64/exit42.ff for GNU as (x86_64-elf-as -mindex-reg),
# linked with ff.ld: the bytes must be the same. exit(42) comes first, the
# lines after it only check encodings. ff always gives a register or memory
# operand a REX prefix ({rex}) and memory a SIB byte and a disp32
# ({disp32}, %riz as the index for none).
    .code64
    .globl  _start
_start:
    {rex} movl $42, %edi
    {rex} movl $60, %eax
    syscall
    {disp32} {rex} addq 8(%rsp,%riz,1), %rax
    {disp32} {rex} movq %rcx, -8(%rbp,%riz,1)
    {rex} leaq _start(%rip), %rsi
    call _start
    {disp32} je _start
    {rex} pushq %r12
    {rex} popq %r13
