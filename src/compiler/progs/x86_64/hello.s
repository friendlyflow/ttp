# hello.s — progs/x86_64/hello.ff for GNU as (x86_64-elf-as -mindex-reg),
# linked with ff64.ld: the bytes must be the same. li32, la and bnez are
# macros of ff (macros/x86_64.ff.txt), written out here.
    .code64
    .section .rodata
msg:    .ascii "hello, ff\n"
    .equ msg_len, . - msg

    .section .text
    .globl _start
_start:
    movq    $3, %rbx
1:  call    print
    leaq    count(%rip), %rax
    {disp32} movq %rbx, 0(%rax,%riz,1)
    decq    %rbx
    testq   %rbx, %rbx
    {disp32} jne 1b
    {rex} movl $0, %edi
    {rex} movl $60, %eax
    syscall
print:
    {rex} movl $1, %edi
    leaq    msg(%rip), %rsi
    {rex} movl $msg_len, %edx
    {rex} movl $1, %eax
    syscall
    ret

    .section .bss
    .balign 8
count:  .skip 8
