# wide.s — progs/x86_64/wide.ff for GNU as (x86_64-elf-as -mindex-reg),
# linked with ff.ld: the bytes must be the same. Made by mkwide.pl with
# wide.ff, every form of the x86_64 section once. {rex}, {disp32} and
# %riz (no index) make GNU as pick the one form ff has.
    .code64
    .globl _start
_start:
    {rex} movl $0, %edi
    {rex} movl $60, %eax
    syscall
wide_back:
w0:
    {rex} addb %r12b, %r13b
    {rex} addb $-128, %r15b
    {disp32} {rex} addb -2147483648(%r12,%riz,1), %r8b
    {disp32} {rex} addb %cl, 2147483647(%r13,%riz,1)
    {disp32} {rex} addb $127, 0(%r15,%riz,1)
    {disp32} {rex} addb -1(%rsp,%r15,1), %dl
    {disp32} {rex} addb %bl, 127(%rbp,%r9,2)
    {disp32} {rex} addb $255, -128(%r8,%r12,4)
    {rex} addw %sp, %bp
    {rex} addw $-32768, %si
    {rex} addw $-128, %di
    {disp32} {rex} addw 4660(%rbx,%riz,1), %r9w
    {disp32} {rex} addw %r10w, -2147483648(%r11,%riz,1)
    {disp32} {rex} addw $32767, 2147483647(%rdi,%riz,1)
    {disp32} {rex} addw $127, 0(%rcx,%riz,1)
    {disp32} {rex} addw -1(%r12,%rbp,8), %r11w
    {disp32} {rex} addw %r14w, 127(%r13,%r13,1)
    {disp32} {rex} addw $4660, -128(%r15,%rcx,2)
    {disp32} {rex} addw $-1, 4660(%rsp,%rsi,4)
    {rex} addl %r12d, %r13d
    {rex} addl $-2147483648, %r15d
    {rex} addl $0, %r8d
    {disp32} {rex} addl -2147483648(%rbp,%riz,1), %ecx
    {disp32} {rex} addl %edx, 2147483647(%r8,%riz,1)
    {disp32} {rex} addl $2147483647, 0(%rbx,%riz,1)
    {disp32} {rex} addl $-128, -1(%r11,%riz,1)
    {disp32} {rex} addl 127(%rdi,%r8,8), %ebx
    {disp32} {rex} addl %esp, -128(%rcx,%r14,1)
    {disp32} {rex} addl $305419896, 4660(%r12,%r15,2)
    {disp32} {rex} addl $127, -2147483648(%r13,%r9,4)
    {rex} addq %rbp, %rsi
    {rex} addq $1000, %rdi
    {rex} addq $-1, %r9
    {disp32} {rex} addq 2147483647(%r15,%riz,1), %r10
    {disp32} {rex} addq %r11, 0(%rsp,%riz,1)
    {disp32} {rex} addq $-2147483648, -1(%rbp,%riz,1)
    {disp32} {rex} addq $0, 127(%r8,%riz,1)
    {disp32} {rex} addq -128(%rbx,%r12,8), %r14
    {disp32} {rex} addq %r12, 4660(%r11,%rbp,1)
    {disp32} {rex} addq $2147483647, -2147483648(%rdi,%r13,2)
    {disp32} {rex} addq $-128, 2147483647(%rcx,%rcx,4)
    {rex} orb %r13b, %r15b
    {rex} orb $-128, %r8b
    {disp32} {rex} orb 0(%r12,%riz,1), %cl
    {disp32} {rex} orb %dl, -1(%r13,%riz,1)
    {disp32} {rex} orb $127, 127(%r15,%riz,1)
    {disp32} {rex} orb -128(%rsp,%rsi,8), %bl
    {disp32} {rex} orb %spl, 4660(%rbp,%r8,1)
    {disp32} {rex} orb $255, -2147483648(%r8,%r14,2)
    {rex} orw %bp, %si
    {rex} orw $200, %di
    {rex} orw $127, %r9w
    {disp32} {rex} orw 2147483647(%rbx,%riz,1), %r10w
    {disp32} {rex} orw %r11w, 0(%r11,%riz,1)
    {disp32} {rex} orw $-32768, -1(%rdi,%riz,1)
    {disp32} {rex} orw $-1, 127(%rcx,%riz,1)
    {disp32} {rex} orw -128(%r12,%r15,4), %r14w
    {disp32} {rex} orw %r12w, 4660(%r13,%r9,8)
    {disp32} {rex} orw $32767, -2147483648(%r15,%r12,1)
    {disp32} {rex} orw $0, 2147483647(%rsp,%rbp,2)
    {rex} orl %r13d, %r15d
    {rex} orl $305419896, %r8d
    {rex} orl $-128, %ecx
    {disp32} {rex} orl 0(%rbp,%riz,1), %edx
    {disp32} {rex} orl %ebx, -1(%r8,%riz,1)
    {disp32} {rex} orl $1000, 127(%rbx,%riz,1)
    {disp32} {rex} orl $127, -128(%r11,%riz,1)
    {disp32} {rex} orl 4660(%rdi,%r13,4), %esp
    {disp32} {rex} orl %ebp, -2147483648(%rcx,%rcx,8)
    {disp32} {rex} orl $-2147483648, 2147483647(%r12,%rsi,1)
    {disp32} {rex} orl $-1, 0(%r13,%r8,2)
    {rex} orq %rsi, %rdi
    {rex} orq $2147483647, %r9
    {rex} orq $0, %r10
    {disp32} {rex} orq -1(%r15,%riz,1), %r11
    {disp32} {rex} orq %r14, 127(%rsp,%riz,1)
    {disp32} {rex} orq $305419896, -128(%rbp,%riz,1)
    {disp32} {rex} orq $-128, 4660(%r8,%riz,1)
    {disp32} {rex} orq -2147483648(%rbx,%r14,4), %r12
    {disp32} {rex} orq %r13, 2147483647(%r11,%r15,8)
    {disp32} {rex} orq $1000, 0(%rdi,%r9,1)
    {disp32} {rex} orq $127, -1(%rcx,%r12,2)
    {rex} adcb %r15b, %r8b
    {rex} adcb $-128, %cl
    {disp32} {rex} adcb 127(%r12,%riz,1), %dl
    {disp32} {rex} adcb %bl, -128(%r13,%riz,1)
    {disp32} {rex} adcb $127, 4660(%r15,%riz,1)
    {disp32} {rex} adcb -2147483648(%rsp,%rbp,4), %spl
    {disp32} {rex} adcb %bpl, 2147483647(%rbp,%r13,8)
    {disp32} {rex} adcb $255, 0(%r8,%rcx,1)
    {rex} adcw %si, %di
    {rex} adcw $4660, %r9w
    {rex} adcw $-1, %r10w
    {disp32} {rex} adcw -1(%rbx,%riz,1), %r11w
    {disp32} {rex} adcw %r14w, 127(%r11,%riz,1)
    {disp32} {rex} adcw $200, -128(%rdi,%riz,1)
    {disp32} {rex} adcw $0, 4660(%rcx,%riz,1)
    {disp32} {rex} adcw -2147483648(%r12,%rsi,2), %r12w
    {disp32} {rex} adcw %r13w, 2147483647(%r13,%r8,4)
    {disp32} {rex} adcw $-32768, 0(%r15,%r14,8)
    {disp32} {rex} adcw $-128, -1(%rsp,%r15,1)
    {rex} adcl %r15d, %r8d
    {rex} adcl $-2147483648, %ecx
    {rex} adcl $127, %edx
    {disp32} {rex} adcl 127(%rbp,%riz,1), %ebx
    {disp32} {rex} adcl %esp, -128(%r8,%riz,1)
    {disp32} {rex} adcl $2147483647, 4660(%rbx,%riz,1)
    {disp32} {rex} adcl $-1, -2147483648(%r11,%riz,1)
    {disp32} {rex} adcl 2147483647(%rdi,%r9,2), %ebp
    {disp32} {rex} adcl %esi, 0(%rcx,%r12,4)
    {disp32} {rex} adcl $305419896, -1(%r12,%rbp,8)
    {disp32} {rex} adcl $0, 127(%r13,%r13,1)
    {rex} adcq %rdi, %r9
    {rex} adcq $1000, %r10
    {rex} adcq $-128, %r11
    {disp32} {rex} adcq -128(%r15,%riz,1), %r14
    {disp32} {rex} adcq %r12, 4660(%rsp,%riz,1)
    {disp32} {rex} adcq $-2147483648, -2147483648(%rbp,%riz,1)
    {disp32} {rex} adcq $127, 2147483647(%r8,%riz,1)
    {disp32} {rex} adcq 0(%rbx,%rcx,2), %r13
    {disp32} {rex} adcq %r15, -1(%r11,%rsi,4)
    {disp32} {rex} adcq $2147483647, 127(%rdi,%r8,8)
    {disp32} {rex} adcq $-1, -128(%rcx,%r14,1)
    {rex} sbbb %r8b, %cl
    {rex} sbbb $-128, %dl
    {disp32} {rex} sbbb 4660(%r12,%riz,1), %bl
    {disp32} {rex} sbbb %spl, -2147483648(%r13,%riz,1)
    {disp32} {rex} sbbb $127, 2147483647(%r15,%riz,1)
    {disp32} {rex} sbbb 0(%rsp,%r15,2), %bpl
    {disp32} {rex} sbbb %sil, -1(%rbp,%r9,4)
    {disp32} {rex} sbbb $255, 127(%r8,%r12,8)
    {rex} sbbw %di, %r9w
    {rex} sbbw $32767, %r10w
    {rex} sbbw $0, %r11w
    {disp32} {rex} sbbw -128(%rbx,%riz,1), %r14w
    {disp32} {rex} sbbw %r12w, 4660(%r11,%riz,1)
    {disp32} {rex} sbbw $4660, -2147483648(%rdi,%riz,1)
    {disp32} {rex} sbbw $-128, 2147483647(%rcx,%riz,1)
    {disp32} {rex} sbbw 0(%r12,%rbp,1), %r13w
    {disp32} {rex} sbbw %r15w, -1(%r13,%r13,2)
    {disp32} {rex} sbbw $200, 127(%r15,%rcx,4)
    {disp32} {rex} sbbw $127, -128(%rsp,%rsi,8)
    {rex} sbbl %r8d, %ecx
    {rex} sbbl $305419896, %edx
    {rex} sbbl $-1, %ebx
    {disp32} {rex} sbbl 4660(%rbp,%riz,1), %esp
    {disp32} {rex} sbbl %ebp, -2147483648(%r8,%riz,1)
    {disp32} {rex} sbbl $1000, 2147483647(%rbx,%riz,1)
    {disp32} {rex} sbbl $0, 0(%r11,%riz,1)
    {disp32} {rex} sbbl -1(%rdi,%r8,1), %esi
    {disp32} {rex} sbbl %edi, 127(%rcx,%r14,2)
    {disp32} {rex} sbbl $-2147483648, -128(%r12,%r15,4)
    {disp32} {rex} sbbl $-128, 4660(%r13,%r9,8)
    {rex} sbbq %r9, %r10
    {rex} sbbq $2147483647, %r11
    {rex} sbbq $127, %r14
    {disp32} {rex} sbbq -2147483648(%r15,%riz,1), %r12
    {disp32} {rex} sbbq %r13, 2147483647(%rsp,%riz,1)
    {disp32} {rex} sbbq $305419896, 0(%rbp,%riz,1)
    {disp32} {rex} sbbq $-1, -1(%r8,%riz,1)
    {disp32} {rex} sbbq 127(%rbx,%r12,1), %r15
    {disp32} {rex} sbbq %r8, -128(%r11,%rbp,2)
    {disp32} {rex} sbbq $1000, 4660(%rdi,%r13,4)
    {disp32} {rex} sbbq $0, -2147483648(%rcx,%rcx,8)
    {rex} andb %cl, %dl
    {rex} andb $-128, %bl
    {disp32} {rex} andb 2147483647(%r12,%riz,1), %spl
    {disp32} {rex} andb %bpl, 0(%r13,%riz,1)
    {disp32} {rex} andb $127, -1(%r15,%riz,1)
    {disp32} {rex} andb 127(%rsp,%rsi,1), %sil
    {disp32} {rex} andb %dil, -128(%rbp,%r8,2)
    {disp32} {rex} andb $255, 4660(%r8,%r14,4)
    {rex} andw %r9w, %r10w
    {rex} andw $-32768, %r11w
    {rex} andw $-128, %r14w
    {disp32} {rex} andw -2147483648(%rbx,%riz,1), %r12w
    {disp32} {rex} andw %r13w, 2147483647(%r11,%riz,1)
    {disp32} {rex} andw $32767, 0(%rdi,%riz,1)
    {disp32} {rex} andw $127, -1(%rcx,%riz,1)
    {disp32} {rex} andw 127(%r12,%r15,8), %r15w
    {disp32} {rex} andw %r8w, -128(%r13,%r9,1)
    {disp32} {rex} andw $4660, 4660(%r15,%r12,2)
    {disp32} {rex} andw $-1, -2147483648(%rsp,%rbp,4)
    {rex} andl %ecx, %edx
    {rex} andl $-2147483648, %ebx
    {rex} andl $0, %esp
    {disp32} {rex} andl 2147483647(%rbp,%riz,1), %ebp
    {disp32} {rex} andl %esi, 0(%r8,%riz,1)
    {disp32} {rex} andl $2147483647, -1(%rbx,%riz,1)
    {disp32} {rex} andl $-128, 127(%r11,%riz,1)
    {disp32} {rex} andl -128(%rdi,%r13,8), %edi
    {disp32} {rex} andl %r9d, 4660(%rcx,%rcx,1)
    {disp32} {rex} andl $305419896, -2147483648(%r12,%rsi,2)
    {disp32} {rex} andl $127, 2147483647(%r13,%r8,4)
    {rex} andq %r10, %r11
    {rex} andq $1000, %r14
    {rex} andq $-1, %r12
    {disp32} {rex} andq 0(%r15,%riz,1), %r13
    {disp32} {rex} andq %r15, -1(%rsp,%riz,1)
    {disp32} {rex} andq $-2147483648, 127(%rbp,%riz,1)
w1:
    {disp32} {rex} andq $0, -128(%r8,%riz,1)
    {disp32} {rex} andq 4660(%rbx,%r14,8), %r8
    {disp32} {rex} andq %rcx, -2147483648(%r11,%r15,1)
    {disp32} {rex} andq $2147483647, 2147483647(%rdi,%r9,2)
    {disp32} {rex} andq $-128, 0(%rcx,%r12,4)
    {rex} subb %dl, %bl
    {rex} subb $-128, %spl
    {disp32} {rex} subb -1(%r12,%riz,1), %bpl
    {disp32} {rex} subb %sil, 127(%r13,%riz,1)
    {disp32} {rex} subb $127, -128(%r15,%riz,1)
    {disp32} {rex} subb 4660(%rsp,%rbp,8), %dil
    {disp32} {rex} subb %r9b, -2147483648(%rbp,%r13,1)
    {disp32} {rex} subb $255, 2147483647(%r8,%rcx,2)
    {rex} subw %r10w, %r11w
    {rex} subw $200, %r14w
    {rex} subw $127, %r12w
    {disp32} {rex} subw 0(%rbx,%riz,1), %r13w
    {disp32} {rex} subw %r15w, -1(%r11,%riz,1)
    {disp32} {rex} subw $-32768, 127(%rdi,%riz,1)
    {disp32} {rex} subw $-1, -128(%rcx,%riz,1)
    {disp32} {rex} subw 4660(%r12,%rsi,4), %r8w
    {disp32} {rex} subw %cx, -2147483648(%r13,%r8,8)
    {disp32} {rex} subw $32767, 2147483647(%r15,%r14,1)
    {disp32} {rex} subw $0, 0(%rsp,%r15,2)
    {rex} subl %edx, %ebx
    {rex} subl $305419896, %esp
    {rex} subl $-128, %ebp
    {disp32} {rex} subl -1(%rbp,%riz,1), %esi
    {disp32} {rex} subl %edi, 127(%r8,%riz,1)
    {disp32} {rex} subl $1000, -128(%rbx,%riz,1)
    {disp32} {rex} subl $127, 4660(%r11,%riz,1)
    {disp32} {rex} subl -2147483648(%rdi,%r9,4), %r9d
    {disp32} {rex} subl %r10d, 2147483647(%rcx,%r12,8)
    {disp32} {rex} subl $-2147483648, 0(%r12,%rbp,1)
    {disp32} {rex} subl $-1, -1(%r13,%r13,2)
    {rex} subq %r11, %r14
    {rex} subq $2147483647, %r12
    {rex} subq $0, %r13
    {disp32} {rex} subq 127(%r15,%riz,1), %r15
    {disp32} {rex} subq %r8, -128(%rsp,%riz,1)
    {disp32} {rex} subq $305419896, 4660(%rbp,%riz,1)
    {disp32} {rex} subq $-128, -2147483648(%r8,%riz,1)
    {disp32} {rex} subq 2147483647(%rbx,%rcx,4), %rcx
    {disp32} {rex} subq %rdx, 0(%r11,%rsi,8)
    {disp32} {rex} subq $1000, -1(%rdi,%r8,1)
    {disp32} {rex} subq $127, 127(%rcx,%r14,2)
    {rex} xorb %bl, %spl
    {rex} xorb $-128, %bpl
    {disp32} {rex} xorb -128(%r12,%riz,1), %sil
    {disp32} {rex} xorb %dil, 4660(%r13,%riz,1)
    {disp32} {rex} xorb $127, -2147483648(%r15,%riz,1)
    {disp32} {rex} xorb 2147483647(%rsp,%r15,4), %r9b
    {disp32} {rex} xorb %r10b, 0(%rbp,%r9,8)
    {disp32} {rex} xorb $255, -1(%r8,%r12,1)
    {rex} xorw %r11w, %r14w
    {rex} xorw $4660, %r12w
    {rex} xorw $-1, %r13w
    {disp32} {rex} xorw 127(%rbx,%riz,1), %r15w
    {disp32} {rex} xorw %r8w, -128(%r11,%riz,1)
    {disp32} {rex} xorw $200, 4660(%rdi,%riz,1)
    {disp32} {rex} xorw $0, -2147483648(%rcx,%riz,1)
    {disp32} {rex} xorw 2147483647(%r12,%rbp,2), %cx
    {disp32} {rex} xorw %dx, 0(%r13,%r13,4)
    {disp32} {rex} xorw $-32768, -1(%r15,%rcx,8)
    {disp32} {rex} xorw $-128, 127(%rsp,%rsi,1)
    {rex} xorl %ebx, %esp
    {rex} xorl $-2147483648, %ebp
    {rex} xorl $127, %esi
    {disp32} {rex} xorl -128(%rbp,%riz,1), %edi
    {disp32} {rex} xorl %r9d, 4660(%r8,%riz,1)
    {disp32} {rex} xorl $2147483647, -2147483648(%rbx,%riz,1)
    {disp32} {rex} xorl $-1, 2147483647(%r11,%riz,1)
    {disp32} {rex} xorl 0(%rdi,%r8,2), %r10d
    {disp32} {rex} xorl %r11d, -1(%rcx,%r14,4)
    {disp32} {rex} xorl $305419896, 127(%r12,%r15,8)
    {disp32} {rex} xorl $0, -128(%r13,%r9,1)
    {rex} xorq %r14, %r12
    {rex} xorq $1000, %r13
    {rex} xorq $-128, %r15
    {disp32} {rex} xorq 4660(%r15,%riz,1), %r8
    {disp32} {rex} xorq %rcx, -2147483648(%rsp,%riz,1)
    {disp32} {rex} xorq $-2147483648, 2147483647(%rbp,%riz,1)
    {disp32} {rex} xorq $127, 0(%r8,%riz,1)
    {disp32} {rex} xorq -1(%rbx,%r12,2), %rdx
    {disp32} {rex} xorq %rbx, 127(%r11,%rbp,4)
    {disp32} {rex} xorq $2147483647, -128(%rdi,%r13,8)
    {disp32} {rex} xorq $-1, 4660(%rcx,%rcx,1)
    {rex} cmpb %spl, %bpl
    {rex} cmpb $-128, %sil
    {disp32} {rex} cmpb -2147483648(%r12,%riz,1), %dil
    {disp32} {rex} cmpb %r9b, 2147483647(%r13,%riz,1)
    {disp32} {rex} cmpb $127, 0(%r15,%riz,1)
    {disp32} {rex} cmpb -1(%rsp,%rsi,2), %r10b
    {disp32} {rex} cmpb %r11b, 127(%rbp,%r8,4)
    {disp32} {rex} cmpb $255, -128(%r8,%r14,8)
    {rex} cmpw %r14w, %r12w
    {rex} cmpw $32767, %r13w
    {rex} cmpw $0, %r15w
    {disp32} {rex} cmpw 4660(%rbx,%riz,1), %r8w
    {disp32} {rex} cmpw %cx, -2147483648(%r11,%riz,1)
    {disp32} {rex} cmpw $4660, 2147483647(%rdi,%riz,1)
    {disp32} {rex} cmpw $-128, 0(%rcx,%riz,1)
    {disp32} {rex} cmpw -1(%r12,%r15,1), %dx
    {disp32} {rex} cmpw %bx, 127(%r13,%r9,2)
    {disp32} {rex} cmpw $200, -128(%r15,%r12,4)
    {disp32} {rex} cmpw $127, 4660(%rsp,%rbp,8)
    {rex} cmpl %esp, %ebp
    {rex} cmpl $305419896, %esi
    {rex} cmpl $-1, %edi
    {disp32} {rex} cmpl -2147483648(%rbp,%riz,1), %r9d
    {disp32} {rex} cmpl %r10d, 2147483647(%r8,%riz,1)
    {disp32} {rex} cmpl $1000, 0(%rbx,%riz,1)
    {disp32} {rex} cmpl $0, -1(%r11,%riz,1)
    {disp32} {rex} cmpl 127(%rdi,%r13,1), %r11d
    {disp32} {rex} cmpl %r14d, -128(%rcx,%rcx,2)
    {disp32} {rex} cmpl $-2147483648, 4660(%r12,%rsi,4)
    {disp32} {rex} cmpl $-128, -2147483648(%r13,%r8,8)
    {rex} cmpq %r12, %r13
    {rex} cmpq $2147483647, %r15
    {rex} cmpq $127, %r8
    {disp32} {rex} cmpq 2147483647(%r15,%riz,1), %rcx
    {disp32} {rex} cmpq %rdx, 0(%rsp,%riz,1)
    {disp32} {rex} cmpq $305419896, -1(%rbp,%riz,1)
    {disp32} {rex} cmpq $-1, 127(%r8,%riz,1)
    {disp32} {rex} cmpq -128(%rbx,%r14,1), %rbx
    {disp32} {rex} cmpq %rsp, 4660(%r11,%r15,2)
    {disp32} {rex} cmpq $1000, -2147483648(%rdi,%r9,4)
    {disp32} {rex} cmpq $0, 2147483647(%rcx,%r12,8)
    {rex} movb %bpl, %sil
    {rex} movb $-128, %dil
    {disp32} {rex} movb 0(%r12,%riz,1), %r9b
    {disp32} {rex} movb %r10b, -1(%r13,%riz,1)
    {disp32} {rex} movb $127, 127(%r15,%riz,1)
    {disp32} {rex} movb -128(%rsp,%rbp,1), %r11b
    {disp32} {rex} movb %r14b, 4660(%rbp,%r13,2)
    {disp32} {rex} movb $255, -2147483648(%r8,%rcx,4)
    {rex} movb wide_back(%rip), %r12b
    {rex} movb %r13b, wide_fwd(%rip)
    {rex} movw %r15w, %r8w
    {rex} movw $-32768, %cx
    {disp32} {rex} movw 2147483647(%rbx,%riz,1), %dx
    {disp32} {rex} movw %bx, 0(%r11,%riz,1)
    {disp32} {rex} movw $32767, -1(%rdi,%riz,1)
    {disp32} {rex} movw 127(%rcx,%rsi,8), %sp
    {disp32} {rex} movw %bp, -128(%r12,%r8,1)
    {disp32} {rex} movw $4660, 4660(%r13,%r14,2)
    {rex} movw wide_back(%rip), %si
    {rex} movw %di, wide_fwd(%rip)
    {rex} movl %r9d, %r10d
    {rex} movl $-2147483648, %r11d
    {disp32} {rex} movl -2147483648(%r15,%riz,1), %r14d
    {disp32} {rex} movl %r12d, 2147483647(%rsp,%riz,1)
    {disp32} {rex} movl $2147483647, 0(%rbp,%riz,1)
    {disp32} {rex} movl -1(%r8,%r15,4), %r13d
    {disp32} {rex} movl %r15d, 127(%rbx,%r9,8)
    {disp32} {rex} movl $305419896, -128(%r11,%r12,1)
    {rex} movl wide_back(%rip), %r8d
    {rex} movl %ecx, wide_fwd(%rip)
    {rex} movq %rdx, %rbx
    {rex} movq $1000, %rsp
    {disp32} {rex} movq 4660(%rdi,%riz,1), %rbp
    {disp32} {rex} movq %rsi, -2147483648(%rcx,%riz,1)
    {disp32} {rex} movq $-2147483648, 2147483647(%r12,%riz,1)
    {disp32} {rex} movq 0(%r13,%rbp,2), %rdi
    {disp32} {rex} movq %r9, -1(%r15,%r13,4)
    {disp32} {rex} movq $2147483647, 127(%rsp,%rcx,8)
    {rex} movq wide_back(%rip), %r10
    {rex} movq %r11, wide_fwd(%rip)
    movabsq $9223372036854775807, %r14
    {rex} movzbw %r12b, %r13w
    {disp32} {rex} movzbw -128(%rbp,%riz,1), %r15w
    {disp32} {rex} movzbw 4660(%r8,%rsi,1), %r8w
    {rex} movzbl %cl, %edx
    {disp32} {rex} movzbl -2147483648(%rbx,%riz,1), %ebx
    {disp32} {rex} movzbl 2147483647(%r11,%r8,2), %esp
    {rex} movzbq %bpl, %rsi
    {disp32} {rex} movzbq 0(%rdi,%riz,1), %rdi
    {disp32} {rex} movzbq -1(%rcx,%r14,4), %r9
    {rex} movzwl %r10w, %r11d
    {disp32} {rex} movzwl 127(%r12,%riz,1), %r14d
    {disp32} {rex} movzwl -128(%r13,%r15,8), %r12d
    {rex} movzwq %r13w, %r15
    {disp32} {rex} movzwq 4660(%r15,%riz,1), %r8
    {disp32} {rex} movzwq -2147483648(%rsp,%r9,1), %rcx
    {rex} movsbw %dl, %bx
    {disp32} {rex} movsbw 2147483647(%rbp,%riz,1), %sp
    {disp32} {rex} movsbw 0(%r8,%r12,2), %bp
    {rex} movsbl %sil, %edi
    {disp32} {rex} movsbl -1(%rbx,%riz,1), %r9d
    {disp32} {rex} movsbl 127(%r11,%rbp,4), %r10d
    {rex} movsbq %r11b, %r14
    {disp32} {rex} movsbq -128(%rdi,%riz,1), %r12
    {disp32} {rex} movsbq 4660(%rcx,%r13,8), %r13
    {rex} movswl %r15w, %r8d
    {disp32} {rex} movswl -2147483648(%r12,%riz,1), %ecx
    {disp32} {rex} movswl 2147483647(%r13,%rcx,1), %edx
    {rex} movswq %bx, %rsp
    {disp32} {rex} movswq 0(%r15,%riz,1), %rbp
    {disp32} {rex} movswq -1(%rsp,%rsi,2), %rsi
    {rex} movslq %edi, %r9
w2:
    {disp32} {rex} movslq 127(%rbp,%riz,1), %r10
    {disp32} {rex} movslq -128(%r8,%r8,4), %r11
    {disp32} {rex} leal 4660(%rbx,%riz,1), %r14d
    {disp32} {rex} leal -2147483648(%r11,%r14,8), %r12d
    {rex} leal wide_back(%rip), %r13d
    {disp32} {rex} leaq 2147483647(%rdi,%riz,1), %r15
    {disp32} {rex} leaq 0(%rcx,%r15,1), %r8
    {rex} leaq wide_fwd(%rip), %rcx
    {rex} xchgb %dl, %bl
    {disp32} {rex} xchgb %spl, -1(%r12,%riz,1)
    {disp32} {rex} xchgb %bpl, 127(%r13,%r9,2)
    {rex} testb %sil, %dil
    {rex} testb $-128, %r9b
    {disp32} {rex} testb %r10b, -128(%r15,%riz,1)
    {disp32} {rex} testb $127, 4660(%rsp,%riz,1)
    {disp32} {rex} testb %r11b, -2147483648(%rbp,%r12,4)
    {disp32} {rex} testb $255, 2147483647(%r8,%rbp,8)
    {rex} xchgw %r14w, %r12w
    {disp32} {rex} xchgw %r13w, 0(%rbx,%riz,1)
    {disp32} {rex} xchgw %r15w, -1(%r11,%r13,1)
    {rex} testw %r8w, %cx
    {rex} testw $200, %dx
    {disp32} {rex} testw %bx, 127(%rdi,%riz,1)
    {disp32} {rex} testw $-32768, -128(%rcx,%riz,1)
    {disp32} {rex} testw %sp, 4660(%r12,%rcx,2)
    {disp32} {rex} testw $32767, -2147483648(%r13,%rsi,4)
    {rex} xchgl %ebp, %esi
    {disp32} {rex} xchgl %edi, 2147483647(%r15,%riz,1)
    {disp32} {rex} xchgl %r9d, 0(%rsp,%r8,8)
    {rex} testl %r10d, %r11d
    {rex} testl $305419896, %r14d
    {disp32} {rex} testl %r12d, -1(%rbp,%riz,1)
    {disp32} {rex} testl $1000, 127(%r8,%riz,1)
    {disp32} {rex} testl %r13d, -128(%rbx,%r14,1)
    {disp32} {rex} testl $-2147483648, 4660(%r11,%r15,2)
    {rex} xchgq %r15, %r8
    {disp32} {rex} xchgq %rcx, -2147483648(%rdi,%riz,1)
    {disp32} {rex} xchgq %rdx, 2147483647(%rcx,%r9,4)
    {rex} testq %rbx, %rsp
    {rex} testq $2147483647, %rbp
    {disp32} {rex} testq %rsi, 0(%r12,%riz,1)
    {disp32} {rex} testq $305419896, -1(%r13,%riz,1)
    {disp32} {rex} testq %rdi, 127(%r15,%r12,8)
    {disp32} {rex} testq $1000, -128(%rsp,%rbp,1)
    {rex} incb %r9b
    {disp32} {rex} incb 4660(%rbp,%riz,1)
    {disp32} {rex} incb -2147483648(%r8,%r13,2)
    {rex} incw %r10w
    {disp32} {rex} incw 2147483647(%rbx,%riz,1)
    {disp32} {rex} incw 0(%r11,%rcx,4)
    {rex} incl %r11d
    {disp32} {rex} incl -1(%rdi,%riz,1)
    {disp32} {rex} incl 127(%rcx,%rsi,8)
    {rex} incq %r14
    {disp32} {rex} incq -128(%r12,%riz,1)
    {disp32} {rex} incq 4660(%r13,%r8,1)
    {rex} decb %r12b
    {disp32} {rex} decb -2147483648(%r15,%riz,1)
    {disp32} {rex} decb 2147483647(%rsp,%r14,2)
    {rex} decw %r13w
    {disp32} {rex} decw 0(%rbp,%riz,1)
    {disp32} {rex} decw -1(%r8,%r15,4)
    {rex} decl %r15d
    {disp32} {rex} decl 127(%rbx,%riz,1)
    {disp32} {rex} decl -128(%r11,%r9,8)
    {rex} decq %r8
    {disp32} {rex} decq 4660(%rdi,%riz,1)
    {disp32} {rex} decq -2147483648(%rcx,%r12,1)
    {rex} notb %cl
    {disp32} {rex} notb 2147483647(%r12,%riz,1)
    {disp32} {rex} notb 0(%r13,%rbp,2)
    {rex} notw %dx
    {disp32} {rex} notw -1(%r15,%riz,1)
    {disp32} {rex} notw 127(%rsp,%r13,4)
    {rex} notl %ebx
    {disp32} {rex} notl -128(%rbp,%riz,1)
    {disp32} {rex} notl 4660(%r8,%rcx,8)
    {rex} notq %rsp
    {disp32} {rex} notq -2147483648(%rbx,%riz,1)
    {disp32} {rex} notq 2147483647(%r11,%rsi,1)
    {rex} negb %bpl
    {disp32} {rex} negb 0(%rdi,%riz,1)
    {disp32} {rex} negb -1(%rcx,%r8,2)
    {rex} negw %si
    {disp32} {rex} negw 127(%r12,%riz,1)
    {disp32} {rex} negw -128(%r13,%r14,4)
    {rex} negl %edi
    {disp32} {rex} negl 4660(%r15,%riz,1)
    {disp32} {rex} negl -2147483648(%rsp,%r15,8)
    {rex} negq %r9
    {disp32} {rex} negq 2147483647(%rbp,%riz,1)
    {disp32} {rex} negq 0(%r8,%r9,1)
    {rex} mulb %r10b
    {disp32} {rex} mulb -1(%rbx,%riz,1)
    {disp32} {rex} mulb 127(%r11,%r12,2)
    {rex} mulw %r11w
    {disp32} {rex} mulw -128(%rdi,%riz,1)
    {disp32} {rex} mulw 4660(%rcx,%rbp,4)
    {rex} mull %r14d
    {disp32} {rex} mull -2147483648(%r12,%riz,1)
    {disp32} {rex} mull 2147483647(%r13,%r13,8)
    {rex} mulq %r12
    {disp32} {rex} mulq 0(%r15,%riz,1)
    {disp32} {rex} mulq -1(%rsp,%rcx,1)
    {rex} imulb %r13b
    {disp32} {rex} imulb 127(%rbp,%riz,1)
    {disp32} {rex} imulb -128(%r8,%rsi,2)
    {rex} imulw %r15w
    {disp32} {rex} imulw 4660(%rbx,%riz,1)
    {disp32} {rex} imulw -2147483648(%r11,%r8,4)
    {rex} imull %r8d
    {disp32} {rex} imull 2147483647(%rdi,%riz,1)
    {disp32} {rex} imull 0(%rcx,%r14,8)
    {rex} imulq %rcx
    {disp32} {rex} imulq -1(%r12,%riz,1)
    {disp32} {rex} imulq 127(%r13,%r15,1)
    {rex} divb %dl
    {disp32} {rex} divb -128(%r15,%riz,1)
    {disp32} {rex} divb 4660(%rsp,%r9,2)
    {rex} divw %bx
    {disp32} {rex} divw -2147483648(%rbp,%riz,1)
    {disp32} {rex} divw 2147483647(%r8,%r12,4)
    {rex} divl %esp
    {disp32} {rex} divl 0(%rbx,%riz,1)
    {disp32} {rex} divl -1(%r11,%rbp,8)
    {rex} divq %rbp
    {disp32} {rex} divq 127(%rdi,%riz,1)
    {disp32} {rex} divq -128(%rcx,%r13,1)
    {rex} idivb %sil
    {disp32} {rex} idivb 4660(%r12,%riz,1)
    {disp32} {rex} idivb -2147483648(%r13,%rcx,2)
    {rex} idivw %di
    {disp32} {rex} idivw 2147483647(%r15,%riz,1)
    {disp32} {rex} idivw 0(%rsp,%rsi,4)
    {rex} idivl %r9d
    {disp32} {rex} idivl -1(%rbp,%riz,1)
    {disp32} {rex} idivl 127(%r8,%r8,8)
    {rex} idivq %r10
    {disp32} {rex} idivq -128(%rbx,%riz,1)
    {disp32} {rex} idivq 4660(%r11,%r14,1)
    {rex} imulw %r11w, %r14w
    {disp32} {rex} imulw -2147483648(%rdi,%riz,1), %r12w
    {disp32} {rex} imulw 2147483647(%rcx,%r15,2), %r13w
    {rex} imulw $4660, %r15w, %r8w
    {rex} imulw $-128, %cx, %dx
    {rex} imull %ebx, %esp
    {disp32} {rex} imull 0(%r12,%riz,1), %ebp
    {disp32} {rex} imull -1(%r13,%r9,4), %esi
    {rex} imull $-2147483648, %edi, %r9d
    {rex} imull $127, %r10d, %r11d
    {rex} imulq %r14, %r12
    {disp32} {rex} imulq 127(%r15,%riz,1), %r13
    {disp32} {rex} imulq -128(%rsp,%r12,8), %r15
    {rex} imulq $2147483647, %r8, %rcx
    {rex} imulq $-1, %rdx, %rbx
    cbtw
    cwtl
    cltq
    cwtd
    cltd
    cqto
    {rex} rolb %spl
    {rex} rolb $0, %bpl
    {rex} rolb %cl, %sil
    {disp32} {rex} rolb 4660(%rbp,%riz,1)
    {disp32} {rex} rolb $255, -2147483648(%r8,%riz,1)
    {disp32} {rex} rolb %cl, 2147483647(%rbx,%riz,1)
    {disp32} {rex} rolb 0(%r11,%rbp,1)
    {disp32} {rex} rolb $63, -1(%rdi,%r13,2)
    {disp32} {rex} rolb %cl, 127(%rcx,%rcx,4)
    {rex} rolw %di
    {rex} rolw $7, %r9w
    {rex} rolw %cl, %r10w
    {disp32} {rex} rolw -128(%r12,%riz,1)
    {disp32} {rex} rolw $0, 4660(%r13,%riz,1)
    {disp32} {rex} rolw %cl, -2147483648(%r15,%riz,1)
    {disp32} {rex} rolw 2147483647(%rsp,%rsi,8)
    {disp32} {rex} rolw $255, 0(%rbp,%r8,1)
    {disp32} {rex} rolw %cl, -1(%r8,%r14,2)
    {rex} roll %r11d
    {rex} roll $63, %r14d
    {rex} roll %cl, %r12d
    {disp32} {rex} roll 127(%rbx,%riz,1)
    {disp32} {rex} roll $7, -128(%r11,%riz,1)
    {disp32} {rex} roll %cl, 4660(%rdi,%riz,1)
    {disp32} {rex} roll -2147483648(%rcx,%r15,4)
    {disp32} {rex} roll $0, 2147483647(%r12,%r9,8)
    {disp32} {rex} roll %cl, 0(%r13,%r12,1)
    {rex} rolq %r13
    {rex} rolq $255, %r15
    {rex} rolq %cl, %r8
    {disp32} {rex} rolq -1(%r15,%riz,1)
    {disp32} {rex} rolq $63, 127(%rsp,%riz,1)
    {disp32} {rex} rolq %cl, -128(%rbp,%riz,1)
    {disp32} {rex} rolq 4660(%r8,%rbp,2)
    {disp32} {rex} rolq $7, -2147483648(%rbx,%r13,4)
    {disp32} {rex} rolq %cl, 2147483647(%r11,%rcx,8)
    {rex} rorb %cl
    {rex} rorb $0, %dl
    {rex} rorb %cl, %bl
w3:
    {disp32} {rex} rorb 0(%rdi,%riz,1)
    {disp32} {rex} rorb $255, -1(%rcx,%riz,1)
    {disp32} {rex} rorb %cl, 127(%r12,%riz,1)
    {disp32} {rex} rorb -128(%r13,%rsi,1)
    {disp32} {rex} rorb $63, 4660(%r15,%r8,2)
    {disp32} {rex} rorb %cl, -2147483648(%rsp,%r14,4)
    {rex} rorw %sp
    {rex} rorw $7, %bp
    {rex} rorw %cl, %si
    {disp32} {rex} rorw 2147483647(%rbp,%riz,1)
    {disp32} {rex} rorw $0, 0(%r8,%riz,1)
    {disp32} {rex} rorw %cl, -1(%rbx,%riz,1)
    {disp32} {rex} rorw 127(%r11,%r15,8)
    {disp32} {rex} rorw $255, -128(%rdi,%r9,1)
    {disp32} {rex} rorw %cl, 4660(%rcx,%r12,2)
    {rex} rorl %edi
    {rex} rorl $63, %r9d
    {rex} rorl %cl, %r10d
    {disp32} {rex} rorl -2147483648(%r12,%riz,1)
    {disp32} {rex} rorl $7, 2147483647(%r13,%riz,1)
    {disp32} {rex} rorl %cl, 0(%r15,%riz,1)
    {disp32} {rex} rorl -1(%rsp,%rbp,4)
    {disp32} {rex} rorl $0, 127(%rbp,%r13,8)
    {disp32} {rex} rorl %cl, -128(%r8,%rcx,1)
    {rex} rorq %r11
    {rex} rorq $255, %r14
    {rex} rorq %cl, %r12
    {disp32} {rex} rorq 4660(%rbx,%riz,1)
    {disp32} {rex} rorq $63, -2147483648(%r11,%riz,1)
    {disp32} {rex} rorq %cl, 2147483647(%rdi,%riz,1)
    {disp32} {rex} rorq 0(%rcx,%rsi,2)
    {disp32} {rex} rorq $7, -1(%r12,%r8,4)
    {disp32} {rex} rorq %cl, 127(%r13,%r14,8)
    {rex} rclb %r13b
    {rex} rclb $0, %r15b
    {rex} rclb %cl, %r8b
    {disp32} {rex} rclb -128(%r15,%riz,1)
    {disp32} {rex} rclb $255, 4660(%rsp,%riz,1)
    {disp32} {rex} rclb %cl, -2147483648(%rbp,%riz,1)
    {disp32} {rex} rclb 2147483647(%r8,%r15,1)
    {disp32} {rex} rclb $63, 0(%rbx,%r9,2)
    {disp32} {rex} rclb %cl, -1(%r11,%r12,4)
    {rex} rclw %cx
    {rex} rclw $7, %dx
    {rex} rclw %cl, %bx
    {disp32} {rex} rclw 127(%rdi,%riz,1)
    {disp32} {rex} rclw $0, -128(%rcx,%riz,1)
    {disp32} {rex} rclw %cl, 4660(%r12,%riz,1)
    {disp32} {rex} rclw -2147483648(%r13,%rbp,8)
    {disp32} {rex} rclw $255, 2147483647(%r15,%r13,1)
    {disp32} {rex} rclw %cl, 0(%rsp,%rcx,2)
    {rex} rcll %esp
    {rex} rcll $63, %ebp
    {rex} rcll %cl, %esi
    {disp32} {rex} rcll -1(%rbp,%riz,1)
    {disp32} {rex} rcll $7, 127(%r8,%riz,1)
    {disp32} {rex} rcll %cl, -128(%rbx,%riz,1)
    {disp32} {rex} rcll 4660(%r11,%rsi,4)
    {disp32} {rex} rcll $0, -2147483648(%rdi,%r8,8)
    {disp32} {rex} rcll %cl, 2147483647(%rcx,%r14,1)
    {rex} rclq %rdi
    {rex} rclq $255, %r9
    {rex} rclq %cl, %r10
    {disp32} {rex} rclq 0(%r12,%riz,1)
    {disp32} {rex} rclq $63, -1(%r13,%riz,1)
    {disp32} {rex} rclq %cl, 127(%r15,%riz,1)
    {disp32} {rex} rclq -128(%rsp,%r15,2)
    {disp32} {rex} rclq $7, 4660(%rbp,%r9,4)
    {disp32} {rex} rclq %cl, -2147483648(%r8,%r12,8)
    {rex} rcrb %r11b
    {rex} rcrb $0, %r14b
    {rex} rcrb %cl, %r12b
    {disp32} {rex} rcrb 2147483647(%rbx,%riz,1)
    {disp32} {rex} rcrb $255, 0(%r11,%riz,1)
    {disp32} {rex} rcrb %cl, -1(%rdi,%riz,1)
    {disp32} {rex} rcrb 127(%rcx,%rbp,1)
    {disp32} {rex} rcrb $63, -128(%r12,%r13,2)
    {disp32} {rex} rcrb %cl, 4660(%r13,%rcx,4)
    {rex} rcrw %r13w
    {rex} rcrw $7, %r15w
    {rex} rcrw %cl, %r8w
    {disp32} {rex} rcrw -2147483648(%r15,%riz,1)
    {disp32} {rex} rcrw $0, 2147483647(%rsp,%riz,1)
    {disp32} {rex} rcrw %cl, 0(%rbp,%riz,1)
    {disp32} {rex} rcrw -1(%r8,%rsi,8)
    {disp32} {rex} rcrw $255, 127(%rbx,%r8,1)
    {disp32} {rex} rcrw %cl, -128(%r11,%r14,2)
    {rex} rcrl %ecx
    {rex} rcrl $63, %edx
    {rex} rcrl %cl, %ebx
    {disp32} {rex} rcrl 4660(%rdi,%riz,1)
    {disp32} {rex} rcrl $7, -2147483648(%rcx,%riz,1)
    {disp32} {rex} rcrl %cl, 2147483647(%r12,%riz,1)
    {disp32} {rex} rcrl 0(%r13,%r15,4)
    {disp32} {rex} rcrl $0, -1(%r15,%r9,8)
    {disp32} {rex} rcrl %cl, 127(%rsp,%r12,1)
    {rex} rcrq %rsp
    {rex} rcrq $255, %rbp
    {rex} rcrq %cl, %rsi
    {disp32} {rex} rcrq -128(%rbp,%riz,1)
    {disp32} {rex} rcrq $63, 4660(%r8,%riz,1)
    {disp32} {rex} rcrq %cl, -2147483648(%rbx,%riz,1)
    {disp32} {rex} rcrq 2147483647(%r11,%rbp,2)
    {disp32} {rex} rcrq $7, 0(%rdi,%r13,4)
    {disp32} {rex} rcrq %cl, -1(%rcx,%rcx,8)
    {rex} shlb %dil
    {rex} shlb $0, %r9b
    {rex} shlb %cl, %r10b
    {disp32} {rex} shlb 127(%r12,%riz,1)
    {disp32} {rex} shlb $255, -128(%r13,%riz,1)
    {disp32} {rex} shlb %cl, 4660(%r15,%riz,1)
    {disp32} {rex} shlb -2147483648(%rsp,%rsi,1)
    {disp32} {rex} shlb $63, 2147483647(%rbp,%r8,2)
    {disp32} {rex} shlb %cl, 0(%r8,%r14,4)
    {rex} shlw %r11w
    {rex} shlw $7, %r14w
    {rex} shlw %cl, %r12w
    {disp32} {rex} shlw -1(%rbx,%riz,1)
    {disp32} {rex} shlw $0, 127(%r11,%riz,1)
    {disp32} {rex} shlw %cl, -128(%rdi,%riz,1)
    {disp32} {rex} shlw 4660(%rcx,%r15,8)
    {disp32} {rex} shlw $255, -2147483648(%r12,%r9,1)
    {disp32} {rex} shlw %cl, 2147483647(%r13,%r12,2)
    {rex} shll %r13d
    {rex} shll $63, %r15d
    {rex} shll %cl, %r8d
    {disp32} {rex} shll 0(%r15,%riz,1)
    {disp32} {rex} shll $7, -1(%rsp,%riz,1)
    {disp32} {rex} shll %cl, 127(%rbp,%riz,1)
    {disp32} {rex} shll -128(%r8,%rbp,4)
    {disp32} {rex} shll $0, 4660(%rbx,%r13,8)
    {disp32} {rex} shll %cl, -2147483648(%r11,%rcx,1)
    {rex} shlq %rcx
    {rex} shlq $255, %rdx
    {rex} shlq %cl, %rbx
    {disp32} {rex} shlq 2147483647(%rdi,%riz,1)
    {disp32} {rex} shlq $63, 0(%rcx,%riz,1)
    {disp32} {rex} shlq %cl, -1(%r12,%riz,1)
    {disp32} {rex} shlq 127(%r13,%rsi,2)
    {disp32} {rex} shlq $7, -128(%r15,%r8,4)
    {disp32} {rex} shlq %cl, 4660(%rsp,%r14,8)
    {rex} shrb %spl
    {rex} shrb $0, %bpl
    {rex} shrb %cl, %sil
    {disp32} {rex} shrb -2147483648(%rbp,%riz,1)
    {disp32} {rex} shrb $255, 2147483647(%r8,%riz,1)
    {disp32} {rex} shrb %cl, 0(%rbx,%riz,1)
    {disp32} {rex} shrb -1(%r11,%r15,1)
    {disp32} {rex} shrb $63, 127(%rdi,%r9,2)
    {disp32} {rex} shrb %cl, -128(%rcx,%r12,4)
    {rex} shrw %di
    {rex} shrw $7, %r9w
    {rex} shrw %cl, %r10w
    {disp32} {rex} shrw 4660(%r12,%riz,1)
    {disp32} {rex} shrw $0, -2147483648(%r13,%riz,1)
    {disp32} {rex} shrw %cl, 2147483647(%r15,%riz,1)
    {disp32} {rex} shrw 0(%rsp,%rbp,8)
    {disp32} {rex} shrw $255, -1(%rbp,%r13,1)
    {disp32} {rex} shrw %cl, 127(%r8,%rcx,2)
    {rex} shrl %r11d
    {rex} shrl $63, %r14d
    {rex} shrl %cl, %r12d
    {disp32} {rex} shrl -128(%rbx,%riz,1)
    {disp32} {rex} shrl $7, 4660(%r11,%riz,1)
    {disp32} {rex} shrl %cl, -2147483648(%rdi,%riz,1)
    {disp32} {rex} shrl 2147483647(%rcx,%rsi,4)
    {disp32} {rex} shrl $0, 0(%r12,%r8,8)
    {disp32} {rex} shrl %cl, -1(%r13,%r14,1)
    {rex} shrq %r13
    {rex} shrq $255, %r15
    {rex} shrq %cl, %r8
    {disp32} {rex} shrq 127(%r15,%riz,1)
    {disp32} {rex} shrq $63, -128(%rsp,%riz,1)
    {disp32} {rex} shrq %cl, 4660(%rbp,%riz,1)
    {disp32} {rex} shrq -2147483648(%r8,%r15,2)
    {disp32} {rex} shrq $7, 2147483647(%rbx,%r9,4)
    {disp32} {rex} shrq %cl, 0(%r11,%r12,8)
    {rex} sarb %cl
    {rex} sarb $0, %dl
    {rex} sarb %cl, %bl
    {disp32} {rex} sarb -1(%rdi,%riz,1)
    {disp32} {rex} sarb $255, 127(%rcx,%riz,1)
    {disp32} {rex} sarb %cl, -128(%r12,%riz,1)
    {disp32} {rex} sarb 4660(%r13,%rbp,1)
    {disp32} {rex} sarb $63, -2147483648(%r15,%r13,2)
    {disp32} {rex} sarb %cl, 2147483647(%rsp,%rcx,4)
    {rex} sarw %sp
    {rex} sarw $7, %bp
    {rex} sarw %cl, %si
    {disp32} {rex} sarw 0(%rbp,%riz,1)
    {disp32} {rex} sarw $0, -1(%r8,%riz,1)
    {disp32} {rex} sarw %cl, 127(%rbx,%riz,1)
    {disp32} {rex} sarw -128(%r11,%rsi,8)
    {disp32} {rex} sarw $255, 4660(%rdi,%r8,1)
    {disp32} {rex} sarw %cl, -2147483648(%rcx,%r14,2)
    {rex} sarl %edi
    {rex} sarl $63, %r9d
    {rex} sarl %cl, %r10d
    {disp32} {rex} sarl 2147483647(%r12,%riz,1)
    {disp32} {rex} sarl $7, 0(%r13,%riz,1)
w4:
    {disp32} {rex} sarl %cl, -1(%r15,%riz,1)
    {disp32} {rex} sarl 127(%rsp,%r15,4)
    {disp32} {rex} sarl $0, -128(%rbp,%r9,8)
    {disp32} {rex} sarl %cl, 4660(%r8,%r12,1)
    {rex} sarq %r11
    {rex} sarq $255, %r14
    {rex} sarq %cl, %r12
    {disp32} {rex} sarq -2147483648(%rbx,%riz,1)
    {disp32} {rex} sarq $63, 2147483647(%r11,%riz,1)
    {disp32} {rex} sarq %cl, 0(%rdi,%riz,1)
    {disp32} {rex} sarq -1(%rcx,%rbp,2)
    {disp32} {rex} sarq $7, 127(%r12,%r13,4)
    {disp32} {rex} sarq %cl, -128(%r13,%rcx,8)
    {rex} shldw $0, %r13w, %r15w
    {rex} shldw %cl, %r8w, %cx
    {disp32} {rex} shldw $255, %dx, 4660(%r15,%riz,1)
    {disp32} {rex} shldw %cl, %bx, -2147483648(%rsp,%riz,1)
    {disp32} {rex} shldw $63, %sp, 2147483647(%rbp,%rsi,1)
    {disp32} {rex} shldw %cl, %bp, 0(%r8,%r8,2)
    {rex} shldl $7, %esi, %edi
    {rex} shldl %cl, %r9d, %r10d
    {disp32} {rex} shldl $0, %r11d, -1(%rbx,%riz,1)
    {disp32} {rex} shldl %cl, %r14d, 127(%r11,%riz,1)
    {disp32} {rex} shldl $255, %r12d, -128(%rdi,%r14,4)
    {disp32} {rex} shldl %cl, %r13d, 4660(%rcx,%r15,8)
    {rex} shldq $63, %r15, %r8
    {rex} shldq %cl, %rcx, %rdx
    {disp32} {rex} shldq $7, %rbx, -2147483648(%r12,%riz,1)
    {disp32} {rex} shldq %cl, %rsp, 2147483647(%r13,%riz,1)
    {disp32} {rex} shldq $0, %rbp, 0(%r15,%r9,1)
    {disp32} {rex} shldq %cl, %rsi, -1(%rsp,%r12,2)
    {rex} shrdw $255, %di, %r9w
    {rex} shrdw %cl, %r10w, %r11w
    {disp32} {rex} shrdw $63, %r14w, 127(%rbp,%riz,1)
    {disp32} {rex} shrdw %cl, %r12w, -128(%r8,%riz,1)
    {disp32} {rex} shrdw $7, %r13w, 4660(%rbx,%rbp,4)
    {disp32} {rex} shrdw %cl, %r15w, -2147483648(%r11,%r13,8)
    {rex} shrdl $0, %r8d, %ecx
    {rex} shrdl %cl, %edx, %ebx
    {disp32} {rex} shrdl $255, %esp, 2147483647(%rdi,%riz,1)
    {disp32} {rex} shrdl %cl, %ebp, 0(%rcx,%riz,1)
    {disp32} {rex} shrdl $63, %esi, -1(%r12,%rcx,1)
    {disp32} {rex} shrdl %cl, %edi, 127(%r13,%rsi,2)
    {rex} shrdq $7, %r9, %r10
    {rex} shrdq %cl, %r11, %r14
    {disp32} {rex} shrdq $0, %r12, -128(%r15,%riz,1)
    {disp32} {rex} shrdq %cl, %r13, 4660(%rsp,%riz,1)
    {disp32} {rex} shrdq $255, %r15, -2147483648(%rbp,%r8,4)
    {disp32} {rex} shrdq %cl, %r8, 2147483647(%r8,%r14,8)
    {rex} btw %cx, %dx
    {rex} btw $63, %bx
    {disp32} {rex} btw %sp, 0(%rbx,%riz,1)
    {disp32} {rex} btw $7, -1(%r11,%riz,1)
    {disp32} {rex} btw %bp, 127(%rdi,%r15,1)
    {disp32} {rex} btw $0, -128(%rcx,%r9,2)
    {rex} btl %esi, %edi
    {rex} btl $255, %r9d
    {disp32} {rex} btl %r10d, 4660(%r12,%riz,1)
    {disp32} {rex} btl $63, -2147483648(%r13,%riz,1)
    {disp32} {rex} btl %r11d, 2147483647(%r15,%r12,4)
    {disp32} {rex} btl $7, 0(%rsp,%rbp,8)
    {rex} btq %r14, %r12
    {rex} btq $0, %r13
    {disp32} {rex} btq %r15, -1(%rbp,%riz,1)
    {disp32} {rex} btq $255, 127(%r8,%riz,1)
    {disp32} {rex} btq %r8, -128(%rbx,%r13,1)
    {disp32} {rex} btq $63, 4660(%r11,%rcx,2)
    {rex} btsw %cx, %dx
    {rex} btsw $7, %bx
    {disp32} {rex} btsw %sp, -2147483648(%rdi,%riz,1)
    {disp32} {rex} btsw $0, 2147483647(%rcx,%riz,1)
    {disp32} {rex} btsw %bp, 0(%r12,%rsi,4)
    {disp32} {rex} btsw $255, -1(%r13,%r8,8)
    {rex} btsl %esi, %edi
    {rex} btsl $63, %r9d
    {disp32} {rex} btsl %r10d, 127(%r15,%riz,1)
    {disp32} {rex} btsl $7, -128(%rsp,%riz,1)
    {disp32} {rex} btsl %r11d, 4660(%rbp,%r14,1)
    {disp32} {rex} btsl $0, -2147483648(%r8,%r15,2)
    {rex} btsq %r14, %r12
    {rex} btsq $255, %r13
    {disp32} {rex} btsq %r15, 2147483647(%rbx,%riz,1)
    {disp32} {rex} btsq $63, 0(%r11,%riz,1)
    {disp32} {rex} btsq %r8, -1(%rdi,%r9,4)
    {disp32} {rex} btsq $7, 127(%rcx,%r12,8)
    {rex} btrw %cx, %dx
    {rex} btrw $0, %bx
    {disp32} {rex} btrw %sp, -128(%r12,%riz,1)
    {disp32} {rex} btrw $255, 4660(%r13,%riz,1)
    {disp32} {rex} btrw %bp, -2147483648(%r15,%rbp,1)
    {disp32} {rex} btrw $63, 2147483647(%rsp,%r13,2)
    {rex} btrl %esi, %edi
    {rex} btrl $7, %r9d
    {disp32} {rex} btrl %r10d, 0(%rbp,%riz,1)
    {disp32} {rex} btrl $0, -1(%r8,%riz,1)
    {disp32} {rex} btrl %r11d, 127(%rbx,%rcx,4)
    {disp32} {rex} btrl $255, -128(%r11,%rsi,8)
    {rex} btrq %r14, %r12
    {rex} btrq $63, %r13
    {disp32} {rex} btrq %r15, 4660(%rdi,%riz,1)
    {disp32} {rex} btrq $7, -2147483648(%rcx,%riz,1)
    {disp32} {rex} btrq %r8, 2147483647(%r12,%r8,1)
    {disp32} {rex} btrq $0, 0(%r13,%r14,2)
    {rex} btcw %cx, %dx
    {rex} btcw $255, %bx
    {disp32} {rex} btcw %sp, -1(%r15,%riz,1)
    {disp32} {rex} btcw $63, 127(%rsp,%riz,1)
    {disp32} {rex} btcw %bp, -128(%rbp,%r15,4)
    {disp32} {rex} btcw $7, 4660(%r8,%r9,8)
    {rex} btcl %esi, %edi
    {rex} btcl $0, %r9d
    {disp32} {rex} btcl %r10d, -2147483648(%rbx,%riz,1)
    {disp32} {rex} btcl $255, 2147483647(%r11,%riz,1)
    {disp32} {rex} btcl %r11d, 0(%rdi,%r12,1)
    {disp32} {rex} btcl $63, -1(%rcx,%rbp,2)
    {rex} btcq %r14, %r12
    {rex} btcq $7, %r13
    {disp32} {rex} btcq %r15, 127(%r12,%riz,1)
    {disp32} {rex} btcq $0, -128(%r13,%riz,1)
    {disp32} {rex} btcq %r8, 4660(%r15,%r13,4)
    {disp32} {rex} btcq $255, -2147483648(%rsp,%rcx,8)
    {rex} bsfw %cx, %dx
    {disp32} {rex} bsfw 2147483647(%rbp,%riz,1), %bx
    {disp32} {rex} bsfw 0(%r8,%rsi,1), %sp
    {rex} bsfl %ebp, %esi
    {disp32} {rex} bsfl -1(%rbx,%riz,1), %edi
    {disp32} {rex} bsfl 127(%r11,%r8,2), %r9d
    {rex} bsfq %r10, %r11
    {disp32} {rex} bsfq -128(%rdi,%riz,1), %r14
    {disp32} {rex} bsfq 4660(%rcx,%r14,4), %r12
    {rex} bsrw %r13w, %r15w
    {disp32} {rex} bsrw -2147483648(%r12,%riz,1), %r8w
    {disp32} {rex} bsrw 2147483647(%r13,%r15,8), %cx
    {rex} bsrl %edx, %ebx
    {disp32} {rex} bsrl 0(%r15,%riz,1), %esp
    {disp32} {rex} bsrl -1(%rsp,%r9,1), %ebp
    {rex} bsrq %rsi, %rdi
    {disp32} {rex} bsrq 127(%rbp,%riz,1), %r9
    {disp32} {rex} bsrq -128(%r8,%r12,2), %r10
    {rex} popcntw %r11w, %r14w
    {disp32} {rex} popcntw 4660(%rbx,%riz,1), %r12w
    {disp32} {rex} popcntw -2147483648(%r11,%rbp,4), %r13w
    {rex} popcntl %r15d, %r8d
    {disp32} {rex} popcntl 2147483647(%rdi,%riz,1), %ecx
    {disp32} {rex} popcntl 0(%rcx,%r13,8), %edx
    {rex} popcntq %rbx, %rsp
    {disp32} {rex} popcntq -1(%r12,%riz,1), %rbp
    {disp32} {rex} popcntq 127(%r13,%rcx,1), %rsi
    {rex} lzcntw %di, %r9w
    {disp32} {rex} lzcntw -128(%r15,%riz,1), %r10w
    {disp32} {rex} lzcntw 4660(%rsp,%rsi,2), %r11w
    {rex} lzcntl %r14d, %r12d
    {disp32} {rex} lzcntl -2147483648(%rbp,%riz,1), %r13d
    {disp32} {rex} lzcntl 2147483647(%r8,%r8,4), %r15d
    {rex} lzcntq %r8, %rcx
    {disp32} {rex} lzcntq 0(%rbx,%riz,1), %rdx
    {disp32} {rex} lzcntq -1(%r11,%r14,8), %rbx
    {rex} tzcntw %sp, %bp
    {disp32} {rex} tzcntw 127(%rdi,%riz,1), %si
    {disp32} {rex} tzcntw -128(%rcx,%r15,1), %di
    {rex} tzcntl %r9d, %r10d
    {disp32} {rex} tzcntl 4660(%r12,%riz,1), %r11d
    {disp32} {rex} tzcntl -2147483648(%r13,%r9,2), %r14d
    {rex} tzcntq %r12, %r13
    {disp32} {rex} tzcntq 2147483647(%r15,%riz,1), %r15
    {disp32} {rex} tzcntq 0(%rsp,%r12,4), %r8
    {rex} bswapl %ecx
    {rex} bswapq %rdx
    {disp32} jo wide_back
near0:
    {disp8} jo near0
    {disp32} jno wide_fwd
    {disp8} jno near1
near1:
    {disp32} jb wide_back
near2:
    {disp8} jb near2
    {disp32} jae wide_fwd
    {disp8} jae near3
near3:
    {disp32} je wide_back
near4:
    {disp8} je near4
    {disp32} jne wide_fwd
    {disp8} jne near5
near5:
    {disp32} jbe wide_back
near6:
    {disp8} jbe near6
    {disp32} ja wide_fwd
    {disp8} ja near7
near7:
    {disp32} js wide_back
near8:
    {disp8} js near8
    {disp32} jns wide_fwd
    {disp8} jns near9
near9:
    {disp32} jp wide_back
near10:
    {disp8} jp near10
w5:
    {disp32} jnp wide_fwd
    {disp8} jnp near11
near11:
    {disp32} jl wide_back
near12:
    {disp8} jl near12
    {disp32} jge wide_fwd
    {disp8} jge near13
near13:
    {disp32} jle wide_back
near14:
    {disp8} jle near14
    {disp32} jg wide_fwd
    {disp8} jg near15
near15:
    {disp32} jc wide_back
near16:
    {disp8} jc near16
    {disp32} jnae wide_fwd
    {disp8} jnae near17
near17:
    {disp32} jnb wide_back
near18:
    {disp8} jnb near18
    {disp32} jnc wide_fwd
    {disp8} jnc near19
near19:
    {disp32} jz wide_back
near20:
    {disp8} jz near20
    {disp32} jnz wide_fwd
    {disp8} jnz near21
near21:
    {disp32} jna wide_back
near22:
    {disp8} jna near22
    {disp32} jnbe wide_fwd
    {disp8} jnbe near23
near23:
    {disp32} jpe wide_back
near24:
    {disp8} jpe near24
    {disp32} jpo wide_fwd
    {disp8} jpo near25
near25:
    {disp32} jnge wide_back
near26:
    {disp8} jnge near26
    {disp32} jnl wide_fwd
    {disp8} jnl near27
near27:
    {disp32} jng wide_back
near28:
    {disp8} jng near28
    {disp32} jnle wide_fwd
    {disp8} jnle near29
near29:
    {disp32} jmp wide_back
near30:
    {disp8} jmp near30
    call wide_fwd
    {rex} call *%rbx
    {disp32} {rex} call *-1(%rbp,%riz,1)
    {disp32} {rex} call *127(%r8,%rbp,8)
    call *wide_back(%rip)
    {rex} jmp *%rsp
    {disp32} {rex} jmp *-128(%rbx,%riz,1)
    {disp32} {rex} jmp *4660(%r11,%r13,1)
    jmp *wide_fwd(%rip)
    ret
    ret $65535
    {rex} seto %bpl
    {disp32} {rex} seto -2147483648(%rdi,%riz,1)
    {disp32} {rex} seto 2147483647(%rcx,%rcx,2)
    {rex} setno %sil
    {disp32} {rex} setno 0(%r12,%riz,1)
    {disp32} {rex} setno -1(%r13,%rsi,4)
    {rex} setb %dil
    {disp32} {rex} setb 127(%r15,%riz,1)
    {disp32} {rex} setb -128(%rsp,%r8,8)
    {rex} setae %r9b
    {disp32} {rex} setae 4660(%rbp,%riz,1)
    {disp32} {rex} setae -2147483648(%r8,%r14,1)
    {rex} sete %r10b
    {disp32} {rex} sete 2147483647(%rbx,%riz,1)
    {disp32} {rex} sete 0(%r11,%r15,2)
    {rex} setne %r11b
    {disp32} {rex} setne -1(%rdi,%riz,1)
    {disp32} {rex} setne 127(%rcx,%r9,4)
    {rex} setbe %r14b
    {disp32} {rex} setbe -128(%r12,%riz,1)
    {disp32} {rex} setbe 4660(%r13,%r12,8)
    {rex} seta %r12b
    {disp32} {rex} seta -2147483648(%r15,%riz,1)
    {disp32} {rex} seta 2147483647(%rsp,%rbp,1)
    {rex} sets %r13b
    {disp32} {rex} sets 0(%rbp,%riz,1)
    {disp32} {rex} sets -1(%r8,%r13,2)
    {rex} setns %r15b
    {disp32} {rex} setns 127(%rbx,%riz,1)
    {disp32} {rex} setns -128(%r11,%rcx,4)
    {rex} setp %r8b
    {disp32} {rex} setp 4660(%rdi,%riz,1)
    {disp32} {rex} setp -2147483648(%rcx,%rsi,8)
    {rex} setnp %cl
    {disp32} {rex} setnp 2147483647(%r12,%riz,1)
    {disp32} {rex} setnp 0(%r13,%r8,1)
    {rex} setl %dl
    {disp32} {rex} setl -1(%r15,%riz,1)
    {disp32} {rex} setl 127(%rsp,%r14,2)
    {rex} setge %bl
    {disp32} {rex} setge -128(%rbp,%riz,1)
    {disp32} {rex} setge 4660(%r8,%r15,4)
    {rex} setle %spl
    {disp32} {rex} setle -2147483648(%rbx,%riz,1)
    {disp32} {rex} setle 2147483647(%r11,%r9,8)
    {rex} setg %bpl
    {disp32} {rex} setg 0(%rdi,%riz,1)
    {disp32} {rex} setg -1(%rcx,%r12,1)
    {rex} setc %sil
    {disp32} {rex} setc 127(%r12,%riz,1)
    {disp32} {rex} setc -128(%r13,%rbp,2)
    {rex} setnae %dil
    {disp32} {rex} setnae 4660(%r15,%riz,1)
    {disp32} {rex} setnae -2147483648(%rsp,%r13,4)
    {rex} setnb %r9b
    {disp32} {rex} setnb 2147483647(%rbp,%riz,1)
    {disp32} {rex} setnb 0(%r8,%rcx,8)
    {rex} setnc %r10b
    {disp32} {rex} setnc -1(%rbx,%riz,1)
    {disp32} {rex} setnc 127(%r11,%rsi,1)
    {rex} setz %r11b
    {disp32} {rex} setz -128(%rdi,%riz,1)
    {disp32} {rex} setz 4660(%rcx,%r8,2)
    {rex} setnz %r14b
    {disp32} {rex} setnz -2147483648(%r12,%riz,1)
    {disp32} {rex} setnz 2147483647(%r13,%r14,4)
    {rex} setna %r12b
    {disp32} {rex} setna 0(%r15,%riz,1)
    {disp32} {rex} setna -1(%rsp,%r15,8)
    {rex} setnbe %r13b
    {disp32} {rex} setnbe 127(%rbp,%riz,1)
    {disp32} {rex} setnbe -128(%r8,%r9,1)
    {rex} setpe %r15b
    {disp32} {rex} setpe 4660(%rbx,%riz,1)
    {disp32} {rex} setpe -2147483648(%r11,%r12,2)
    {rex} setpo %r8b
    {disp32} {rex} setpo 2147483647(%rdi,%riz,1)
    {disp32} {rex} setpo 0(%rcx,%rbp,4)
    {rex} setnge %cl
    {disp32} {rex} setnge -1(%r12,%riz,1)
    {disp32} {rex} setnge 127(%r13,%r13,8)
    {rex} setnl %dl
    {disp32} {rex} setnl -128(%r15,%riz,1)
    {disp32} {rex} setnl 4660(%rsp,%rcx,1)
    {rex} setng %bl
    {disp32} {rex} setng -2147483648(%rbp,%riz,1)
    {disp32} {rex} setng 2147483647(%r8,%rsi,2)
    {rex} setnle %spl
    {disp32} {rex} setnle 0(%rbx,%riz,1)
    {disp32} {rex} setnle -1(%r11,%r8,4)
    {rex} cmovow %bp, %si
    {disp32} {rex} cmovow 127(%rdi,%riz,1), %di
    {disp32} {rex} cmovow -128(%rcx,%r14,8), %r9w
    {rex} cmovol %r10d, %r11d
    {disp32} {rex} cmovol 4660(%r12,%riz,1), %r14d
    {disp32} {rex} cmovol -2147483648(%r13,%r15,1), %r12d
    {rex} cmovoq %r13, %r15
    {disp32} {rex} cmovoq 2147483647(%r15,%riz,1), %r8
    {disp32} {rex} cmovoq 0(%rsp,%r9,2), %rcx
    {rex} cmovnow %dx, %bx
    {disp32} {rex} cmovnow -1(%rbp,%riz,1), %sp
    {disp32} {rex} cmovnow 127(%r8,%r12,4), %bp
    {rex} cmovnol %esi, %edi
    {disp32} {rex} cmovnol -128(%rbx,%riz,1), %r9d
    {disp32} {rex} cmovnol 4660(%r11,%rbp,8), %r10d
    {rex} cmovnoq %r11, %r14
    {disp32} {rex} cmovnoq -2147483648(%rdi,%riz,1), %r12
    {disp32} {rex} cmovnoq 2147483647(%rcx,%r13,1), %r13
    {rex} cmovbw %r15w, %r8w
    {disp32} {rex} cmovbw 0(%r12,%riz,1), %cx
    {disp32} {rex} cmovbw -1(%r13,%rcx,2), %dx
    {rex} cmovbl %ebx, %esp
    {disp32} {rex} cmovbl 127(%r15,%riz,1), %ebp
    {disp32} {rex} cmovbl -128(%rsp,%rsi,4), %esi
    {rex} cmovbq %rdi, %r9
    {disp32} {rex} cmovbq 4660(%rbp,%riz,1), %r10
    {disp32} {rex} cmovbq -2147483648(%r8,%r8,8), %r11
    {rex} cmovaew %r14w, %r12w
    {disp32} {rex} cmovaew 2147483647(%rbx,%riz,1), %r13w
    {disp32} {rex} cmovaew 0(%r11,%r14,1), %r15w
    {rex} cmovael %r8d, %ecx
    {disp32} {rex} cmovael -1(%rdi,%riz,1), %edx
    {disp32} {rex} cmovael 127(%rcx,%r15,2), %ebx
    {rex} cmovaeq %rsp, %rbp
    {disp32} {rex} cmovaeq -128(%r12,%riz,1), %rsi
    {disp32} {rex} cmovaeq 4660(%r13,%r9,4), %rdi
    {rex} cmovew %r9w, %r10w
    {disp32} {rex} cmovew -2147483648(%r15,%riz,1), %r11w
    {disp32} {rex} cmovew 2147483647(%rsp,%r12,8), %r14w
w6:
    {rex} cmovel %r12d, %r13d
    {disp32} {rex} cmovel 0(%rbp,%riz,1), %r15d
    {disp32} {rex} cmovel -1(%r8,%rbp,1), %r8d
    {rex} cmoveq %rcx, %rdx
    {disp32} {rex} cmoveq 127(%rbx,%riz,1), %rbx
    {disp32} {rex} cmoveq -128(%r11,%r13,2), %rsp
    {rex} cmovnew %bp, %si
    {disp32} {rex} cmovnew 4660(%rdi,%riz,1), %di
    {disp32} {rex} cmovnew -2147483648(%rcx,%rcx,4), %r9w
    {rex} cmovnel %r10d, %r11d
    {disp32} {rex} cmovnel 2147483647(%r12,%riz,1), %r14d
    {disp32} {rex} cmovnel 0(%r13,%rsi,8), %r12d
    {rex} cmovneq %r13, %r15
    {disp32} {rex} cmovneq -1(%r15,%riz,1), %r8
    {disp32} {rex} cmovneq 127(%rsp,%r8,1), %rcx
    {rex} cmovbew %dx, %bx
    {disp32} {rex} cmovbew -128(%rbp,%riz,1), %sp
    {disp32} {rex} cmovbew 4660(%r8,%r14,2), %bp
    {rex} cmovbel %esi, %edi
    {disp32} {rex} cmovbel -2147483648(%rbx,%riz,1), %r9d
    {disp32} {rex} cmovbel 2147483647(%r11,%r15,4), %r10d
    {rex} cmovbeq %r11, %r14
    {disp32} {rex} cmovbeq 0(%rdi,%riz,1), %r12
    {disp32} {rex} cmovbeq -1(%rcx,%r9,8), %r13
    {rex} cmovaw %r15w, %r8w
    {disp32} {rex} cmovaw 127(%r12,%riz,1), %cx
    {disp32} {rex} cmovaw -128(%r13,%r12,1), %dx
    {rex} cmoval %ebx, %esp
    {disp32} {rex} cmoval 4660(%r15,%riz,1), %ebp
    {disp32} {rex} cmoval -2147483648(%rsp,%rbp,2), %esi
    {rex} cmovaq %rdi, %r9
    {disp32} {rex} cmovaq 2147483647(%rbp,%riz,1), %r10
    {disp32} {rex} cmovaq 0(%r8,%r13,4), %r11
    {rex} cmovsw %r14w, %r12w
    {disp32} {rex} cmovsw -1(%rbx,%riz,1), %r13w
    {disp32} {rex} cmovsw 127(%r11,%rcx,8), %r15w
    {rex} cmovsl %r8d, %ecx
    {disp32} {rex} cmovsl -128(%rdi,%riz,1), %edx
    {disp32} {rex} cmovsl 4660(%rcx,%rsi,1), %ebx
    {rex} cmovsq %rsp, %rbp
    {disp32} {rex} cmovsq -2147483648(%r12,%riz,1), %rsi
    {disp32} {rex} cmovsq 2147483647(%r13,%r8,2), %rdi
    {rex} cmovnsw %r9w, %r10w
    {disp32} {rex} cmovnsw 0(%r15,%riz,1), %r11w
    {disp32} {rex} cmovnsw -1(%rsp,%r14,4), %r14w
    {rex} cmovnsl %r12d, %r13d
    {disp32} {rex} cmovnsl 127(%rbp,%riz,1), %r15d
    {disp32} {rex} cmovnsl -128(%r8,%r15,8), %r8d
    {rex} cmovnsq %rcx, %rdx
    {disp32} {rex} cmovnsq 4660(%rbx,%riz,1), %rbx
    {disp32} {rex} cmovnsq -2147483648(%r11,%r9,1), %rsp
    {rex} cmovpw %bp, %si
    {disp32} {rex} cmovpw 2147483647(%rdi,%riz,1), %di
    {disp32} {rex} cmovpw 0(%rcx,%r12,2), %r9w
    {rex} cmovpl %r10d, %r11d
    {disp32} {rex} cmovpl -1(%r12,%riz,1), %r14d
    {disp32} {rex} cmovpl 127(%r13,%rbp,4), %r12d
    {rex} cmovpq %r13, %r15
    {disp32} {rex} cmovpq -128(%r15,%riz,1), %r8
    {disp32} {rex} cmovpq 4660(%rsp,%r13,8), %rcx
    {rex} cmovnpw %dx, %bx
    {disp32} {rex} cmovnpw -2147483648(%rbp,%riz,1), %sp
    {disp32} {rex} cmovnpw 2147483647(%r8,%rcx,1), %bp
    {rex} cmovnpl %esi, %edi
    {disp32} {rex} cmovnpl 0(%rbx,%riz,1), %r9d
    {disp32} {rex} cmovnpl -1(%r11,%rsi,2), %r10d
    {rex} cmovnpq %r11, %r14
    {disp32} {rex} cmovnpq 127(%rdi,%riz,1), %r12
    {disp32} {rex} cmovnpq -128(%rcx,%r8,4), %r13
    {rex} cmovlw %r15w, %r8w
    {disp32} {rex} cmovlw 4660(%r12,%riz,1), %cx
    {disp32} {rex} cmovlw -2147483648(%r13,%r14,8), %dx
    {rex} cmovll %ebx, %esp
    {disp32} {rex} cmovll 2147483647(%r15,%riz,1), %ebp
    {disp32} {rex} cmovll 0(%rsp,%r15,1), %esi
    {rex} cmovlq %rdi, %r9
    {disp32} {rex} cmovlq -1(%rbp,%riz,1), %r10
    {disp32} {rex} cmovlq 127(%r8,%r9,2), %r11
    {rex} cmovgew %r14w, %r12w
    {disp32} {rex} cmovgew -128(%rbx,%riz,1), %r13w
    {disp32} {rex} cmovgew 4660(%r11,%r12,4), %r15w
    {rex} cmovgel %r8d, %ecx
    {disp32} {rex} cmovgel -2147483648(%rdi,%riz,1), %edx
    {disp32} {rex} cmovgel 2147483647(%rcx,%rbp,8), %ebx
    {rex} cmovgeq %rsp, %rbp
    {disp32} {rex} cmovgeq 0(%r12,%riz,1), %rsi
    {disp32} {rex} cmovgeq -1(%r13,%r13,1), %rdi
    {rex} cmovlew %r9w, %r10w
    {disp32} {rex} cmovlew 127(%r15,%riz,1), %r11w
    {disp32} {rex} cmovlew -128(%rsp,%rcx,2), %r14w
    {rex} cmovlel %r12d, %r13d
    {disp32} {rex} cmovlel 4660(%rbp,%riz,1), %r15d
    {disp32} {rex} cmovlel -2147483648(%r8,%rsi,4), %r8d
    {rex} cmovleq %rcx, %rdx
    {disp32} {rex} cmovleq 2147483647(%rbx,%riz,1), %rbx
    {disp32} {rex} cmovleq 0(%r11,%r8,8), %rsp
    {rex} cmovgw %bp, %si
    {disp32} {rex} cmovgw -1(%rdi,%riz,1), %di
    {disp32} {rex} cmovgw 127(%rcx,%r14,1), %r9w
    {rex} cmovgl %r10d, %r11d
    {disp32} {rex} cmovgl -128(%r12,%riz,1), %r14d
    {disp32} {rex} cmovgl 4660(%r13,%r15,2), %r12d
    {rex} cmovgq %r13, %r15
    {disp32} {rex} cmovgq -2147483648(%r15,%riz,1), %r8
    {disp32} {rex} cmovgq 2147483647(%rsp,%r9,4), %rcx
    {rex} pushq %rdx
    {rex} popq %rbx
    pushq $305419896
    pushq $0
    {disp32} {rex} pushq 0(%rbp,%riz,1)
    {disp32} {rex} popq -1(%r8,%riz,1)
    {disp32} {rex} pushq 127(%rbx,%r12,8)
    {disp32} {rex} popq -128(%r11,%rbp,1)
    pushfq
    popfq
    movsb
    movsw
    movsl
    movsq
    cmpsb
    cmpsw
    cmpsl
    cmpsq
    stosb
    stosw
    stosl
    stosq
    lodsb
    lodsw
    lodsl
    lodsq
    scasb
    scasw
    scasl
    scasq
    lock
    rep
    repe
    repz
    repne
    repnz
    {rex} xaddb %spl, %bpl
    {disp32} {rex} xaddb %sil, 4660(%rdi,%riz,1)
    {disp32} {rex} xaddb %dil, -2147483648(%rcx,%r13,2)
    {rex} xaddw %r9w, %r10w
    {disp32} {rex} xaddw %r11w, 2147483647(%r12,%riz,1)
    {disp32} {rex} xaddw %r14w, 0(%r13,%rcx,4)
    {rex} xaddl %r12d, %r13d
    {disp32} {rex} xaddl %r15d, -1(%r15,%riz,1)
    {disp32} {rex} xaddl %r8d, 127(%rsp,%rsi,8)
    {rex} xaddq %rcx, %rdx
    {disp32} {rex} xaddq %rbx, -128(%rbp,%riz,1)
    {disp32} {rex} xaddq %rsp, 4660(%r8,%r8,1)
    {rex} cmpxchgb %bpl, %sil
    {disp32} {rex} cmpxchgb %dil, -2147483648(%rbx,%riz,1)
    {disp32} {rex} cmpxchgb %r9b, 2147483647(%r11,%r14,2)
    {rex} cmpxchgw %r10w, %r11w
    {disp32} {rex} cmpxchgw %r14w, 0(%rdi,%riz,1)
    {disp32} {rex} cmpxchgw %r12w, -1(%rcx,%r15,4)
    {rex} cmpxchgl %r13d, %r15d
    {disp32} {rex} cmpxchgl %r8d, 127(%r12,%riz,1)
    {disp32} {rex} cmpxchgl %ecx, -128(%r13,%r9,8)
    {rex} cmpxchgq %rdx, %rbx
    {disp32} {rex} cmpxchgq %rsp, 4660(%r15,%riz,1)
    {disp32} {rex} cmpxchgq %rbp, -2147483648(%rsp,%r12,1)
    {disp32} {rex} cmpxchg16b 2147483647(%rbp,%riz,1)
    {disp32} {rex} cmpxchg16b 0(%r8,%rbp,2)
    mfence
    lfence
    sfence
    pause
    syscall
    sysretq
    int3
    hlt
    nop
    cli
    sti
    cld
    std
    clc
    stc
    cmc
    cpuid
    rdtsc
    rdtscp
    rdmsr
    wrmsr
    iretq
    swapgs
    wbinvd
    sysretl
    int $63
    {rex} nopw %si
    {disp32} {rex} nopw -1(%rbx,%riz,1)
    {disp32} {rex} nopw 127(%r11,%r13,4)
    {rex} nopl %edi
    {disp32} {rex} nopl -128(%rdi,%riz,1)
    {disp32} {rex} nopl 4660(%rcx,%rcx,8)
    {disp32} {rex} sgdt -2147483648(%r12,%riz,1)
w7:
    {disp32} {rex} sgdt 2147483647(%r13,%rsi,1)
    {disp32} {rex} sidt 0(%r15,%riz,1)
    {disp32} {rex} sidt -1(%rsp,%r8,2)
    {disp32} {rex} lgdt 127(%rbp,%riz,1)
    {disp32} {rex} lgdt -128(%r8,%r14,4)
    {disp32} {rex} lidt 4660(%rbx,%riz,1)
    {disp32} {rex} lidt -2147483648(%r11,%r15,8)
    {disp32} {rex} invlpg 2147483647(%rdi,%riz,1)
    {disp32} {rex} invlpg 0(%rcx,%r9,1)
    {rex} lldt %r9w
    {disp32} {rex} lldt -1(%r12,%riz,1)
    {disp32} {rex} lldt 127(%r13,%r12,2)
    {rex} ltr %r10w
    {disp32} {rex} ltr -128(%r15,%riz,1)
    {disp32} {rex} ltr 4660(%rsp,%rbp,4)
    {rex} mov %r11, %cr0
    {rex} mov %cr2, %r14
    {rex} mov %r12, %dr0
    {rex} mov %dr1, %r13
    inb $7, %al
    inb (%dx), %al
    outb %al, $0
    outb %al, (%dx)
    inw $255, %ax
    inw (%dx), %ax
    outw %ax, $63
    outw %ax, (%dx)
    inl $7, %eax
    inl (%dx), %eax
    outl %eax, $0
    outl %eax, (%dx)
    {rex} movss %xmm15, %xmm8
    {disp32} {rex} movss -2147483648(%rbp,%riz,1), %xmm0
    {disp32} {rex} movss 2147483647(%r8,%r13,8), %xmm12
    {disp32} {rex} movss %xmm13, 0(%rbx,%riz,1)
    {disp32} {rex} movss %xmm1, -1(%r11,%rcx,1)
    {rex} addss %xmm7, %xmm9
    {disp32} {rex} addss 127(%rdi,%riz,1), %xmm2
    {disp32} {rex} addss -128(%rcx,%rsi,2), %xmm14
    {rex} subss %xmm3, %xmm10
    {disp32} {rex} subss 4660(%r12,%riz,1), %xmm4
    {disp32} {rex} subss -2147483648(%r13,%r8,4), %xmm11
    {rex} mulss %xmm5, %xmm6
    {disp32} {rex} mulss 2147483647(%r15,%riz,1), %xmm15
    {disp32} {rex} mulss 0(%rsp,%r14,8), %xmm8
    {rex} divss %xmm0, %xmm12
    {disp32} {rex} divss -1(%rbp,%riz,1), %xmm13
    {disp32} {rex} divss 127(%r8,%r15,1), %xmm1
    {rex} sqrtss %xmm7, %xmm9
    {disp32} {rex} sqrtss -128(%rbx,%riz,1), %xmm2
    {disp32} {rex} sqrtss 4660(%r11,%r9,2), %xmm14
    {rex} minss %xmm3, %xmm10
    {disp32} {rex} minss -2147483648(%rdi,%riz,1), %xmm4
    {disp32} {rex} minss 2147483647(%rcx,%r12,4), %xmm11
    {rex} maxss %xmm5, %xmm6
    {disp32} {rex} maxss 0(%r12,%riz,1), %xmm15
    {disp32} {rex} maxss -1(%r13,%rbp,8), %xmm8
    {rex} cvtsi2ssl %r15d, %xmm0
    {disp32} {rex} cvtsi2ssl 127(%r15,%riz,1), %xmm12
    {disp32} {rex} cvtsi2ssl -128(%rsp,%r13,1), %xmm13
    {rex} cvtsi2ssq %r8, %xmm1
    {disp32} {rex} cvtsi2ssq 4660(%rbp,%riz,1), %xmm7
    {disp32} {rex} cvtsi2ssq -2147483648(%r8,%rcx,2), %xmm9
    {rex} cvttss2si %xmm2, %ecx
    {disp32} {rex} cvttss2si 2147483647(%rbx,%riz,1), %edx
    {disp32} {rex} cvttss2si 0(%r11,%rsi,4), %ebx
    {rex} cvttss2si %xmm14, %rsp
    {disp32} {rex} cvttss2si -1(%rdi,%riz,1), %rbp
    {disp32} {rex} cvttss2si 127(%rcx,%r8,8), %rsi
    {rex} movsd %xmm3, %xmm10
    {disp32} {rex} movsd -128(%r12,%riz,1), %xmm4
    {disp32} {rex} movsd 4660(%r13,%r14,1), %xmm11
    {disp32} {rex} movsd %xmm5, -2147483648(%r15,%riz,1)
    {disp32} {rex} movsd %xmm6, 2147483647(%rsp,%r15,2)
    {rex} addsd %xmm15, %xmm8
    {disp32} {rex} addsd 0(%rbp,%riz,1), %xmm0
    {disp32} {rex} addsd -1(%r8,%r9,4), %xmm12
    {rex} subsd %xmm13, %xmm1
    {disp32} {rex} subsd 127(%rbx,%riz,1), %xmm7
    {disp32} {rex} subsd -128(%r11,%r12,8), %xmm9
    {rex} mulsd %xmm2, %xmm14
    {disp32} {rex} mulsd 4660(%rdi,%riz,1), %xmm3
    {disp32} {rex} mulsd -2147483648(%rcx,%rbp,1), %xmm10
    {rex} divsd %xmm4, %xmm11
    {disp32} {rex} divsd 2147483647(%r12,%riz,1), %xmm5
    {disp32} {rex} divsd 0(%r13,%r13,2), %xmm6
    {rex} sqrtsd %xmm15, %xmm8
    {disp32} {rex} sqrtsd -1(%r15,%riz,1), %xmm0
    {disp32} {rex} sqrtsd 127(%rsp,%rcx,4), %xmm12
    {rex} minsd %xmm13, %xmm1
    {disp32} {rex} minsd -128(%rbp,%riz,1), %xmm7
    {disp32} {rex} minsd 4660(%r8,%rsi,8), %xmm9
    {rex} maxsd %xmm2, %xmm14
    {disp32} {rex} maxsd -2147483648(%rbx,%riz,1), %xmm3
    {disp32} {rex} maxsd 2147483647(%r11,%r8,1), %xmm10
    {rex} cvtsi2sdl %edi, %xmm4
    {disp32} {rex} cvtsi2sdl 0(%rdi,%riz,1), %xmm11
    {disp32} {rex} cvtsi2sdl -1(%rcx,%r14,2), %xmm5
    {rex} cvtsi2sdq %r9, %xmm6
    {disp32} {rex} cvtsi2sdq 127(%r12,%riz,1), %xmm15
    {disp32} {rex} cvtsi2sdq -128(%r13,%r15,4), %xmm8
    {rex} cvttsd2si %xmm0, %r10d
    {disp32} {rex} cvttsd2si 4660(%r15,%riz,1), %r11d
    {disp32} {rex} cvttsd2si -2147483648(%rsp,%r9,8), %r14d
    {rex} cvttsd2si %xmm12, %r12
    {disp32} {rex} cvttsd2si 2147483647(%rbp,%riz,1), %r13
    {disp32} {rex} cvttsd2si 0(%r8,%r12,1), %r15
    {rex} cvtss2sd %xmm13, %xmm1
    {disp32} {rex} cvtss2sd -1(%rbx,%riz,1), %xmm7
    {disp32} {rex} cvtss2sd 127(%r11,%rbp,2), %xmm9
    {rex} cvtsd2ss %xmm2, %xmm14
    {disp32} {rex} cvtsd2ss -128(%rdi,%riz,1), %xmm3
    {disp32} {rex} cvtsd2ss 4660(%rcx,%r13,4), %xmm10
    {rex} ucomiss %xmm4, %xmm11
    {disp32} {rex} ucomiss -2147483648(%r12,%riz,1), %xmm5
    {disp32} {rex} ucomiss 2147483647(%r13,%rcx,8), %xmm6
    {rex} ucomisd %xmm15, %xmm8
    {disp32} {rex} ucomisd 0(%r15,%riz,1), %xmm0
    {disp32} {rex} ucomisd -1(%rsp,%rsi,1), %xmm12
    {rex} comiss %xmm13, %xmm1
    {disp32} {rex} comiss 127(%rbp,%riz,1), %xmm7
    {disp32} {rex} comiss -128(%r8,%r8,2), %xmm9
    {rex} comisd %xmm2, %xmm14
    {disp32} {rex} comisd 4660(%rbx,%riz,1), %xmm3
    {disp32} {rex} comisd -2147483648(%r11,%r14,4), %xmm10
    {rex} andps %xmm4, %xmm11
    {disp32} {rex} andps 2147483647(%rdi,%riz,1), %xmm5
    {disp32} {rex} andps 0(%rcx,%r15,8), %xmm6
    {rex} andpd %xmm15, %xmm8
    {disp32} {rex} andpd -1(%r12,%riz,1), %xmm0
    {disp32} {rex} andpd 127(%r13,%r9,1), %xmm12
    {rex} andnps %xmm13, %xmm1
    {disp32} {rex} andnps -128(%r15,%riz,1), %xmm7
    {disp32} {rex} andnps 4660(%rsp,%r12,2), %xmm9
    {rex} andnpd %xmm2, %xmm14
    {disp32} {rex} andnpd -2147483648(%rbp,%riz,1), %xmm3
    {disp32} {rex} andnpd 2147483647(%r8,%rbp,4), %xmm10
    {rex} orps %xmm4, %xmm11
    {disp32} {rex} orps 0(%rbx,%riz,1), %xmm5
    {disp32} {rex} orps -1(%r11,%r13,8), %xmm6
    {rex} orpd %xmm15, %xmm8
    {disp32} {rex} orpd 127(%rdi,%riz,1), %xmm0
    {disp32} {rex} orpd -128(%rcx,%rcx,1), %xmm12
    {rex} xorps %xmm13, %xmm1
    {disp32} {rex} xorps 4660(%r12,%riz,1), %xmm7
    {disp32} {rex} xorps -2147483648(%r13,%rsi,2), %xmm9
    {rex} xorpd %xmm2, %xmm14
    {disp32} {rex} xorpd 2147483647(%r15,%riz,1), %xmm3
    {disp32} {rex} xorpd 0(%rsp,%r8,4), %xmm10
    {rex} movaps %xmm4, %xmm11
    {rex} movapd %xmm5, %xmm6
    {rex} movd %r8d, %xmm15
    {rex} movd %xmm8, %ecx
    {rex} movq %rdx, %xmm0
    {rex} movq %xmm12, %rbx
edge:
edge_back:
    .skip 126
    {disp8} jmp edge_back
    {disp8} jmp edge_fwd
    .skip 127
edge_fwd:
wide_fwd:
