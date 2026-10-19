# gnu.s — progs/x86_64/gnu.ff for GNU as (x86_64-elf-as), linked with
# ff64.ld: the bytes must be the same. Made by mkgnu.pl with gnu.ff, every
# form of isa/x86_64gnu.pl once, its operands such that GNU as, left to
# itself, picks that form's encoding.
    .code64
    .globl _start
_start:
    {rex} movl $0, %edi
    {rex} movl $60, %eax
    syscall
gnu_back:
g0:
    addb %r8b, 0(%rcx)
    addb %r12b, -128(%rcx)
    addb %spl, -2147483648(%r8)
    addb %r13b, 0(%rsp)
    addb %bpl, 127(%r12)
    addb %r15b, 2147483647(%rsp)
    addb %sil, 0(%rax,%rcx,1)
    addb %dil, -1(%rax,%r9,2)
    addb %r8b, 4660(%r9,%rbp,4)
    addb %r12b, gnu_back(%rip)
    addb %spl, 128
    addb %cl, %dl
    addb %bl, 0(%rcx)
    addb %dh, 64(%rcx)
    addb %bh, -129(%rdx)
    addb %ch, 0(%rsp)
    addb %ah, 8(%rsp)
    addb %cl, -2147483648(%rsp)
    addb %dl, 0(%rax,%rax,8)
    addb %bl, -128(%rax,%rcx,1)
    addb %dh, 2147483647(%rcx,%rdx,2)
    addb %bh, gnu_fwd(%rip)
    addb %ch, 4660
    addb 0(%r8), %r13b
    addb 127(%rbp), %bpl
    addb 128(%r13), %r15b
    addb 0(%r12), %sil
    addb -1(%rsp), %dil
    addb -129(%r12), %r8b
    addb 0(%r8,%r12,4), %r12b
    addb 64(%rsp,%rax,8), %spl
    addb -2147483648(%r13,%r15,1), %r13b
    addb gnu_back(%rip), %bpl
    addb 2147483647, %r15b
    addb 0(%rdx), %ah
    addb 8(%rbx), %cl
    addb 4660(%rbp), %dl
    addb 0(%rsp), %bl
    addb -128(%rsp), %dh
    addb 128(%rsp), %bh
    addb 0(%rcx,%rbx,2), %ch
    addb 127(%rdx,%rbp,4), %ah
    addb -129(%rbx,%rsi,8), %cl
    addb gnu_fwd(%rip), %dl
    addb -2147483648, %bl
    addb $-128, 0(%r8)
    addb $127, -1(%r8)
    addb $255, 2147483647(%r9)
    addb $-128, 0(%r12)
    addb $127, 64(%r12)
    addb $255, 4660(%r12)
    addb $-128, 0(%r8,%rsi,1)
    addb $127, 8(%r8,%rcx,2)
    addb $255, 128(%r9,%r9,4)
    addb $-128, %dh
    addb $127, 0(%rbx)
    addb $255, -128(%rsi)
    addb $-128, -129(%rdi)
    addb $127, 0(%rsp)
    addb $255, 127(%rsp)
    addb $-128, -2147483648(%rsp)
    addb $127, 0(%rdx,%rdi,8)
    addb $255, -1(%rsp,%rax,1)
    addb $-128, 2147483647(%rbp,%rcx,2)
    addb $127, gnu_back(%rip)
    addb $255, 4660
    addw %r8w, 0(%rdx)
    addw %r12w, 64(%rdx)
    addw %r13w, 128(%r9)
    addw %r15w, 0(%rsp)
    addw %r9w, 8(%r12)
    addw %r10w, -129(%rsp)
    addw %r11w, 0(%rcx,%rbp,4)
    addw %r14w, -128(%rbp,%r12,8)
    addw %r8w, -2147483648(%r12,%rax,1)
    addw %r12w, gnu_fwd(%rip)
    addw %r13w, 2147483647
    addw %cx, %dx
    addw %bx, 0(%rsi)
    addw %si, 127(%rcx)
    addw %di, 4660(%rdx)
    addw %bp, 0(%rsp)
    addw %sp, -1(%rsp)
    addw %cx, 128(%rsp)
    addw %dx, 0(%rbx,%rdx,2)
    addw %bx, 64(%rsi,%rbx,4)
    addw %si, -129(%rdi,%rbp,8)
    addw %di, gnu_back(%rip)
    addw %bp, -2147483648
    addw 0(%r9), %r15w
    addw 8(%rbx), %r9w
    addw 2147483647(%r10), %r10w
    addw 0(%r12), %r11w
    addw -128(%rsp), %r14w
    addw 4660(%r12), %r8w
    addw 0(%r12,%r15,1), %r12w
    addw 127(%rdi,%rsi,2), %r13w
    addw 128(%r15,%rcx,4), %r15w
    addw gnu_fwd(%rip), %r9w
    addw -129, %r10w
    addw 0(%rdi), %sp
    addw -1(%rbx), %cx
    addw -2147483648(%rbp), %dx
    addw 0(%rsp), %bx
    addw 64(%rsp), %si
    addw 2147483647(%rsp), %di
    addw 0(%rsp,%rsi,8), %bp
    addw 8(%rax,%rdi,1), %sp
    addw 4660(%rcx,%rax,2), %cx
    addw gnu_back(%rip), %dx
    addw 128, %bx
    addw $-32768, 0(%r9)
    addw $32767, -128(%r10)
    addw $4660, -129(%r11)
    addw $200, 0(%r12)
    addw $-32768, 127(%r12)
    addw $32767, -2147483648(%r12)
    addw $4660, 0(%r9,%r9,4)
    addw $200, -1(%r12,%rbp,8)
    addw $-32768, 2147483647(%r13,%r12,1)
    addw $32767, %si
    addw $4660, 0(%rcx)
    addw $200, 64(%rsi)
    addw $-32768, 4660(%rdi)
    addw $32767, 0(%rsp)
    addw $4660, 8(%rsp)
    addw $200, 128(%rsp)
    addw $-32768, 0(%rsi,%rcx,2)
    addw $32767, -128(%rdx,%rdx,4)
    addw $4660, -129(%rbx,%rbx,8)
    addw $200, gnu_fwd(%rip)
    addw $-32768, -2147483648
    addw $-128, 0(%r10)
    addw $127, 127(%r13)
    addw $-1, 2147483647(%r14)
    addw $0, 0(%r12)
    addw $-128, -1(%r12)
    addw $127, 4660(%r12)
    addw $-1, 0(%r10,%rax,1)
    addw $0, 64(%r15,%r15,2)
    addw $-128, 128(%r8,%rsi,4)
    addw $127, %di
    addw $-1, 0(%rdx)
    addw $0, 8(%rcx)
    addw $-128, -129(%rdx)
    addw $127, 0(%rsp)
    addw $-1, -128(%rsp)
    addw $0, -2147483648(%rsp)
    addw $-128, 0(%rdi,%rbp,8)
    addw $127, 127(%rsp,%rsi,1)
    addw $-1, 2147483647(%rbp,%rdi,2)
    addw $0, gnu_back(%rip)
    addw $-128, 4660
    addl %r11d, 0(%rbx)
    addl %r14d, -1(%rsi)
    addl %r8d, 128(%r11)
    addl %r12d, 0(%rsp)
    addl %r13d, 64(%r12)
    addl %r15d, -129(%rsp)
    addl %r9d, 0(%rdx,%rcx,4)
    addl %r10d, 8(%rax,%r9,8)
    addl %r11d, -2147483648(%r9,%rbp,1)
    addl %r14d, gnu_fwd(%rip)
    addl %r8d, 2147483647
    addl %ebp, %esp
    addl %ecx, 0(%rbx)
    addl %edx, -128(%rbx)
    addl %ebx, 4660(%rbp)
    addl %esi, 0(%rsp)
    addl %edi, 127(%rsp)
    addl %ebp, 128(%rsp)
    addl %esp, 0(%rax,%rax,2)
    addl %ecx, -1(%rsi,%rcx,4)
    addl %edx, -129(%rdi,%rdx,8)
    addl %ebx, gnu_back(%rip)
    addl %esi, -2147483648
    addl 0(%r10), %r12d
    addl 64(%rdi), %r13d
    addl 2147483647(%r14), %r15d
    addl 0(%r12), %r9d
    addl 8(%rsp), %r10d
    addl 4660(%r12), %r11d
    addl 0(%r9,%r12,1), %r14d
    addl -128(%rsp,%rax,2), %r8d
    addl 128(%r13,%r15,4), %r12d
    addl gnu_fwd(%rip), %r13d
    addl -129, %r15d
    addl 0(%rsi), %edi
    addl 127(%rsi), %ebp
    addl -2147483648(%rdi), %esp
    addl 0(%rsp), %ecx
    addl -1(%rsp), %edx
    addl 2147483647(%rsp), %ebx
    addl 0(%rcx,%rbx,8), %esi
    addl 64(%rax,%rbp,1), %edi
    addl 4660(%rcx,%rsi,2), %ebp
    addl gnu_back(%rip), %esp
    addl 128, %ecx
    addl $-2147483648, 0(%r11)
    addl $2147483647, 8(%r15)
g1:
    addl $305419896, -129(%r8)
    addl $1000, 0(%r12)
    addl $-2147483648, -128(%r12)
    addl $2147483647, -2147483648(%r12)
    addl $305419896, 0(%r11,%rsi,4)
    addl $1000, 127(%r9,%rcx,8)
    addl $-2147483648, 2147483647(%r12,%r9,1)
    addl $2147483647, %edx
    addl $305419896, 0(%rdi)
    addl $1000, -1(%rcx)
    addl $-2147483648, 4660(%rdx)
    addl $2147483647, 0(%rsp)
    addl $305419896, 64(%rsp)
    addl $1000, 128(%rsp)
    addl $-2147483648, 0(%rdx,%rdi,2)
    addl $2147483647, 8(%rdx,%rax,4)
    addl $305419896, -129(%rbx,%rcx,8)
    addl $1000, gnu_fwd(%rip)
    addl $-2147483648, -2147483648
    addl $127, 0(%r14)
    addl $-1, -128(%r9)
    addl $0, 2147483647(%r10)
    addl $-128, 0(%r12)
    addl $127, 127(%r12)
    addl $-1, 4660(%r12)
    addl $0, 0(%r12,%rbp,1)
    addl $-128, -1(%r13,%r12,2)
    addl $127, 128(%r15,%rax,4)
    addl $-1, %ebx
    addl $0, 0(%rcx)
    addl $-128, 64(%rbx)
    addl $127, -129(%rbp)
    addl $-1, 0(%rsp)
    addl $0, 8(%rsp)
    addl $-128, -2147483648(%rsp)
    addl $127, 0(%rbx,%rdx,8)
    addl $-1, -128(%rsp,%rbx,1)
    addl $0, 2147483647(%rbp,%rbp,2)
    addl $-128, gnu_back(%rip)
    addl $127, 4660
    addq %r9, 0(%rsi)
    addq %r10, 127(%r15)
    addq %r11, 128(%rcx)
    addq %r14, 0(%rsp)
    addq %r8, -1(%r12)
    addq %r12, -129(%rsp)
    addq %r13, 0(%rsp,%r15,4)
    addq %r15, 64(%rbp,%rsi,8)
    addq %r9, -2147483648(%r12,%rcx,1)
    addq %r10, gnu_fwd(%rip)
    addq %r11, 2147483647
    addq 0(%r11), %r14
    addq 8(%r8), %r8
    addq 4660(%rbp), %r12
    addq 0(%r12), %r13
    addq -128(%rsp), %r15
    addq 128(%r12), %r9
    addq 0(%r14,%r9,2), %r10
    addq 127(%rdi,%rbp,4), %r11
    addq -129(%r15,%r12,8), %r14
    addq gnu_back(%rip), %r8
    addq -2147483648, %r12
    addq $2147483647, 0(%rdi)
    addq $305419896, -1(%r13)
    addq $1000, 2147483647(%rdx)
    addq $-2147483648, 0(%rsp)
    addq $2147483647, 64(%r12)
    addq $305419896, 4660(%rsp)
    addq $1000, 0(%rsi,%rax,1)
    addq $-2147483648, 8(%rax,%r15,2)
    addq $2147483647, 128(%r9,%rsi,4)
    addq $305419896, gnu_fwd(%rip)
    addq $1000, -129
    addq $-1, 0(%r14)
    addq $0, -128(%r9)
    addq $-128, -2147483648(%rbx)
    addq $127, 0(%r12)
    addq $-1, 127(%rsp)
    addq $0, 2147483647(%r12)
    addq $-128, 0(%r15,%rcx,8)
    addq $127, -1(%rsp,%r9,1)
    addq $-1, 4660(%r13,%rbp,2)
    addq $0, gnu_back(%rip)
    addq $-128, 128
    orb %sil, 0(%r15)
    orb %dil, 64(%r10)
    orb %r8b, -129(%rsi)
    orb %r12b, 0(%rsp)
    orb %spl, 8(%r12)
    orb %r13b, -2147483648(%rsp)
    orb %bpl, 0(%rax,%r12,4)
    orb %r15b, -128(%rbp,%rax,8)
    orb %sil, 2147483647(%r12,%r15,1)
    orb %dil, gnu_fwd(%rip)
    orb %r8b, 4660
    orb %bh, %ch
    orb %ah, 0(%rdx)
    orb %cl, 127(%rsi)
    orb %dl, 128(%rdi)
    orb %bl, 0(%rsp)
    orb %dh, -1(%rsp)
    orb %bh, -129(%rsp)
    orb %ch, 0(%rsp,%rsi,2)
    orb %ah, 64(%rsi,%rdi,4)
    orb %cl, -2147483648(%rdi,%rax,8)
    orb %dl, gnu_back(%rip)
    orb %bl, 2147483647
    orb 0(%rcx), %r12b
    orb 8(%r11), %spl
    orb 4660(%rdi), %r13b
    orb 0(%r12), %bpl
    orb -128(%rsp), %r15b
    orb 128(%r12), %sil
    orb 0(%r8,%rsi,1), %dil
    orb 127(%rdi,%rcx,2), %r8b
    orb -129(%r15,%r9,4), %r12b
    orb gnu_fwd(%rip), %spl
    orb -2147483648, %r13b
    orb 0(%rbx), %dh
    orb -1(%rcx), %bh
    orb 2147483647(%rdx), %ch
    orb 0(%rsp), %ah
    orb 64(%rsp), %cl
    orb 4660(%rsp), %dl
    orb 0(%rsi,%rcx,8), %bl
    orb 8(%rax,%rdx,1), %dh
    orb 128(%rcx,%rbx,2), %bh
    orb gnu_back(%rip), %ch
    orb -129, %ah
    orb $-128, 0(%r15)
    orb $127, -128(%r11)
    orb $255, -2147483648(%r13)
    orb $-128, 0(%r12)
    orb $127, 127(%r12)
    orb $255, 2147483647(%r12)
    orb $-128, 0(%r14,%rbp,4)
    orb $127, -1(%r8,%r12,8)
    orb $255, 4660(%r9,%rax,1)
    orb $-128, %cl
    orb $127, 0(%rsi)
    orb $255, 64(%rbx)
    orb $-128, 128(%rbp)
    orb $127, 0(%rsp)
    orb $255, 8(%rsp)
    orb $-128, -129(%rsp)
    orb $127, 0(%rdi,%rbp,2)
    orb $255, -128(%rdx,%rsi,4)
    orb $-128, -2147483648(%rbx,%rdi,8)
    orb $127, gnu_fwd(%rip)
    orb $255, 2147483647
    orw %r13w, 0(%r8)
    orw %r15w, 127(%r14)
    orw %r9w, 4660(%r15)
    orw %r10w, 0(%rsp)
    orw %r11w, -1(%r12)
    orw %r14w, 128(%rsp)
    orw %r8w, 0(%rcx,%r15,1)
    orw %r12w, 64(%rax,%rsi,2)
    orw %r13w, -129(%r9,%rcx,4)
    orw %r15w, gnu_back(%rip)
    orw %r9w, -2147483648
    orw %si, %di
    orw %bp, 0(%rdi)
    orw %sp, 8(%rsi)
    orw %cx, 2147483647(%rdi)
    orw %dx, 0(%rsp)
    orw %bx, -128(%rsp)
    orw %si, 4660(%rsp)
    orw %di, 0(%rax,%rax,8)
    orw %bp, 127(%rsp,%rcx,1)
    orw %sp, 128(%rbp,%rdx,2)
    orw %cx, gnu_fwd(%rip)
    orw %dx, -129
    orw 0(%rdx), %r10w
    orw -1(%rcx), %r11w
    orw -2147483648(%r8), %r14w
    orw 0(%r12), %r8w
    orw 64(%rsp), %r12w
    orw 2147483647(%r12), %r13w
    orw 0(%r12,%r9,4), %r15w
    orw 8(%rsp,%rbp,8), %r9w
    orw 4660(%r13,%r12,1), %r10w
    orw gnu_back(%rip), %r11w
    orw 128, %r14w
    orw 0(%rcx), %bx
    orw -128(%rcx), %si
    orw -129(%rdx), %di
    orw 0(%rsp), %bp
    orw 127(%rsp), %sp
    orw -2147483648(%rsp), %cx
    orw 0(%rcx,%rbx,2), %dx
    orw -1(%rsi,%rbp,4), %bx
    orw 2147483647(%rdi,%rsi,8), %si
    orw gnu_fwd(%rip), %di
    orw 4660, %bp
    orw $32767, 0(%r8)
    orw $4660, 64(%r14)
    orw $200, 128(%r15)
    orw $-32768, 0(%r12)
    orw $32767, 8(%r12)
g2:
    orw $4660, -129(%r12)
    orw $200, 0(%r15,%rax,1)
    orw $-32768, -128(%r12,%r15,2)
    orw $32767, -2147483648(%r13,%rsi,4)
    orw $4660, %sp
    orw $200, 0(%rdx)
    orw $-32768, 127(%rbx)
    orw $32767, 2147483647(%rbp)
    orw $4660, 0(%rsp)
    orw $200, -1(%rsp)
    orw $-32768, 4660(%rsp)
    orw $32767, 0(%rdx,%rdi,8)
    orw $4660, 64(%rax,%rax,1)
    orw $200, 128(%rcx,%rcx,2)
    orw $-32768, gnu_back(%rip)
    orw $32767, -129
    orw $127, 0(%r9)
    orw $-1, 8(%r8)
    orw $0, -2147483648(%r9)
    orw $-128, 0(%r12)
    orw $127, -128(%r12)
    orw $-1, 2147483647(%r12)
    orw $0, 0(%r8,%rcx,4)
    orw $-128, 127(%r15,%r9,8)
    orw $127, 4660(%r8,%rbp,1)
    orw $-1, %cx
    orw $0, 0(%rbx)
    orw $-128, -1(%rsi)
    orw $127, 128(%rdi)
    orw $-1, 0(%rsp)
    orw $0, 64(%rsp)
    orw $-128, -129(%rsp)
    orw $127, 0(%rbx,%rdx,2)
    orw $-1, 8(%rdx,%rbx,4)
    orw $0, -2147483648(%rbx,%rbp,8)
    orw $-128, gnu_fwd(%rip)
    orw $127, 2147483647
    orl %r8d, 0(%r9)
    orl %r12d, -128(%rbp)
    orl %r13d, 4660(%r13)
    orl %r15d, 0(%rsp)
    orl %r9d, 127(%r12)
    orl %r10d, 128(%rsp)
    orl %r11d, 0(%rdx,%r12,1)
    orl %r14d, -1(%rbp,%rax,2)
    orl %r8d, -129(%r12,%r15,4)
    orl %r12d, gnu_back(%rip)
    orl %r13d, -2147483648
    orl %edx, %ebx
    orl %esi, 0(%rsi)
    orl %edi, 64(%rcx)
    orl %ebp, 2147483647(%rdx)
    orl %esp, 0(%rsp)
    orl %ecx, 8(%rsp)
    orl %edx, 4660(%rsp)
    orl %ebx, 0(%rsp,%rsi,8)
    orl %esi, -128(%rsp,%rdi,1)
    orl %edi, 128(%rbp,%rax,2)
    orl %ebp, gnu_fwd(%rip)
    orl %esp, -129
    orl 0(%rbx), %r15d
    orl 127(%rdx), %r9d
    orl -2147483648(%r9), %r10d
    orl 0(%r12), %r11d
    orl -1(%rsp), %r14d
    orl 2147483647(%r12), %r8d
    orl 0(%r9,%rsi,4), %r12d
    orl 64(%rdi,%rcx,8), %r13d
    orl 4660(%r15,%r9,1), %r15d
    orl gnu_back(%rip), %r9d
    orl 128, %r10d
    orl 0(%rdi), %ecx
    orl 8(%rbx), %edx
    orl -129(%rbp), %ebx
    orl 0(%rsp), %esi
    orl -128(%rsp), %edi
    orl -2147483648(%rsp), %ebp
    orl 0(%rsi,%rcx,2), %esp
    orl 127(%rsi,%rdx,4), %ecx
    orl 2147483647(%rdi,%rbx,8), %edx
    orl gnu_fwd(%rip), %ebx
    orl 4660, %esi
    orl $-2147483648, 0(%r10)
    orl $2147483647, -1(%r10)
    orl $305419896, 128(%r11)
    orl $1000, 0(%r12)
    orl $-2147483648, 64(%r12)
    orl $2147483647, -129(%r12)
    orl $305419896, 0(%r9,%rbp,1)
    orl $1000, 8(%r9,%r12,2)
    orl $-2147483648, -2147483648(%r12,%rax,4)
    orl $2147483647, %edi
    orl $305419896, 0(%rcx)
    orl $1000, -128(%rsi)
    orl $-2147483648, 2147483647(%rdi)
    orl $2147483647, 0(%rsp)
    orl $305419896, 127(%rsp)
    orl $1000, 4660(%rsp)
    orl $-2147483648, 0(%rdi,%rbp,8)
    orl $2147483647, -1(%rax,%rsi,1)
    orl $305419896, 128(%rcx,%rdi,2)
    orl $1000, gnu_back(%rip)
    orl $-2147483648, -129
    orl $-1, 0(%r11)
    orl $0, 64(%r13)
    orl $-128, -2147483648(%r14)
    orl $127, 0(%r12)
    orl $-1, 8(%r12)
    orl $0, 2147483647(%r12)
    orl $-128, 0(%r10,%r15,4)
    orl $127, -128(%r13,%rsi,8)
    orl $-1, 4660(%r15,%rcx,1)
    orl $0, %ebp
    orl $-128, 0(%rdx)
    orl $127, 127(%rcx)
    orl $-1, 128(%rdx)
    orl $0, 0(%rsp)
    orl $-128, -1(%rsp)
    orl $127, -129(%rsp)
    orl $-1, 0(%rax,%rax,2)
    orl $0, 64(%rdx,%rcx,4)
    orl $-128, -2147483648(%rbx,%rdx,8)
    orl $127, gnu_fwd(%rip)
    orl $-1, 2147483647
    orq %r11, 0(%r10)
    orq %r14, 8(%rbx)
    orq %r8, 4660(%r10)
    orq %r12, 0(%rsp)
    orq %r13, -128(%r12)
    orq %r15, 128(%rsp)
    orq %r9, 0(%rsp,%r9,1)
    orq %r10, 127(%rax,%rbp,2)
    orq %r11, -129(%r9,%r12,4)
    orq %r14, gnu_back(%rip)
    orq %r8, -2147483648
    orq 0(%rsi), %r12
    orq -1(%rsi), %r13
    orq 2147483647(%r11), %r15
    orq 0(%r12), %r9
    orq 64(%rsp), %r10
    orq 4660(%r12), %r11
    orq 0(%r14,%rax,8), %r14
    orq 8(%rsp,%r15,1), %r8
    orq 128(%r13,%rsi,2), %r12
    orq gnu_fwd(%rip), %r13
    orq -129, %r15
    orq $2147483647, 0(%r11)
    orq $305419896, -128(%rdi)
    orq $1000, -2147483648(%r14)
    orq $-2147483648, 0(%rsp)
    orq $2147483647, 127(%r12)
    orq $305419896, 2147483647(%rsp)
    orq $1000, 0(%rsi,%rcx,4)
    orq $-2147483648, -1(%rbp,%r9,8)
    orq $2147483647, 4660(%r12,%rbp,1)
    orq $305419896, gnu_back(%rip)
    orq $1000, 128
    orq $0, 0(%rdi)
    orq $-128, 64(%r15)
    orq $127, -129(%rcx)
    orq $-1, 0(%r12)
    orq $0, 8(%rsp)
    orq $-128, -2147483648(%r12)
    orq $127, 0(%r15,%r12,2)
    orq $-1, -128(%rdi,%rax,4)
    orq $0, 2147483647(%r15,%r15,8)
    orq $-128, gnu_fwd(%rip)
    orq $127, 4660
    adcb %bpl, 0(%r14)
    adcb %r15b, 127(%r8)
    adcb %sil, 128(%rbp)
    adcb %dil, 0(%rsp)
    adcb %r8b, -1(%r12)
    adcb %r12b, -129(%rsp)
    adcb %spl, 0(%rax,%rsi,1)
    adcb %r13b, 64(%rax,%rcx,2)
    adcb %bpl, -2147483648(%r9,%r9,4)
    adcb %r15b, gnu_back(%rip)
    adcb %sil, 2147483647
    adcb %dl, %bl
    adcb %dh, 0(%rbx)
    adcb %bh, 8(%rbx)
    adcb %ch, 4660(%rbp)
    adcb %ah, 0(%rsp)
    adcb %cl, -128(%rsp)
    adcb %dl, 128(%rsp)
    adcb %bl, 0(%rcx,%rbx,8)
    adcb %dh, 127(%rsp,%rbp,1)
    adcb %bh, -129(%rbp,%rsi,2)
    adcb %ch, gnu_fwd(%rip)
    adcb %ah, -2147483648
    adcb 0(%r15), %dil
    adcb -1(%r13), %r8b
    adcb 2147483647(%rdx), %r12b
    adcb 0(%r12), %spl
    adcb 64(%rsp), %r13b
    adcb 4660(%r12), %bpl
    adcb 0(%r8,%rbp,4), %r15b
    adcb 8(%rsp,%r12,8), %sil
    adcb 128(%r13,%rax,1), %dil
g3:
    adcb gnu_back(%rip), %r8b
    adcb -129, %r12b
    adcb 0(%rsi), %cl
    adcb -128(%rsi), %dl
    adcb -2147483648(%rdi), %bl
    adcb 0(%rsp), %dh
    adcb 127(%rsp), %bh
    adcb 2147483647(%rsp), %ch
    adcb 0(%rdx,%rdi,2), %ah
    adcb -1(%rsi,%rax,4), %cl
    adcb 4660(%rdi,%rcx,8), %dl
    adcb gnu_fwd(%rip), %bl
    adcb 128, %dh
    adcb $-128, 0(%r14)
    adcb $127, 64(%r15)
    adcb $255, -129(%r8)
    adcb $-128, 0(%r12)
    adcb $127, 8(%r12)
    adcb $255, -2147483648(%r12)
    adcb $-128, 0(%r11,%r15,1)
    adcb $127, -128(%r8,%rsi,2)
    adcb $255, 2147483647(%r9,%rcx,4)
    adcb $-128, %bh
    adcb $127, 0(%rdi)
    adcb $255, 127(%rcx)
    adcb $-128, 4660(%rdx)
    adcb $127, 0(%rsp)
    adcb $255, -1(%rsp)
    adcb $-128, 128(%rsp)
    adcb $127, 0(%rbx,%rdx,8)
    adcb $255, 64(%rax,%rbx,1)
    adcb $-128, -129(%rcx,%rbp,2)
    adcb $127, gnu_back(%rip)
    adcb $255, -2147483648
    adcw %r9w, 0(%rcx)
    adcw %r10w, 8(%r9)
    adcw %r11w, 2147483647(%rbx)
    adcw %r14w, 0(%rsp)
    adcw %r8w, -128(%r12)
    adcw %r12w, 4660(%rsp)
    adcw %r13w, 0(%rcx,%r9,4)
    adcw %r15w, 127(%rbp,%rbp,8)
    adcw %r9w, 128(%r12,%r12,1)
    adcw %r10w, gnu_fwd(%rip)
    adcw %r11w, -129
    adcw %sp, %cx
    adcw %dx, 0(%rcx)
    adcw %bx, -1(%rbx)
    adcw %si, -2147483648(%rbp)
    adcw %di, 0(%rsp)
    adcw %bp, 64(%rsp)
    adcw %sp, 2147483647(%rsp)
    adcw %cx, 0(%rsp,%rsi,2)
    adcw %dx, 8(%rdx,%rdi,4)
    adcw %bx, 4660(%rbx,%rax,8)
    adcw %si, gnu_back(%rip)
    adcw %di, 128
    adcw 0(%r8), %r14w
    adcw -128(%r10), %r8w
    adcw -129(%rsi), %r12w
    adcw 0(%r12), %r13w
    adcw 127(%rsp), %r15w
    adcw -2147483648(%r12), %r9w
    adcw 0(%r12,%rax,1), %r10w
    adcw -1(%rdi,%r15,2), %r11w
    adcw 2147483647(%r15,%rsi,4), %r14w
    adcw gnu_fwd(%rip), %r8w
    adcw 4660, %r12w
    adcw 0(%rdx), %bp
    adcw 64(%rsi), %sp
    adcw 128(%rdi), %cx
    adcw 0(%rsp), %dx
    adcw 8(%rsp), %bx
    adcw -129(%rsp), %si
    adcw 0(%rsi,%rcx,8), %di
    adcw -128(%rsp,%rdx,1), %bp
    adcw -2147483648(%rbp,%rbx,2), %sp
    adcw gnu_back(%rip), %cx
    adcw 2147483647, %dx
    adcw $4660, 0(%r15)
    adcw $200, 127(%r9)
    adcw $-32768, 4660(%r10)
    adcw $32767, 0(%r12)
    adcw $4660, -1(%r12)
    adcw $200, 128(%r12)
    adcw $-32768, 0(%r12,%rcx,4)
    adcw $32767, 64(%r12,%r9,8)
    adcw $4660, -129(%r13,%rbp,1)
    adcw $200, %bx
    adcw $-32768, 0(%rbx)
    adcw $32767, 8(%rcx)
    adcw $4660, -2147483648(%rdx)
    adcw $200, 0(%rsp)
    adcw $-32768, -128(%rsp)
    adcw $32767, 2147483647(%rsp)
    adcw $4660, 0(%rdi,%rbp,2)
    adcw $200, 127(%rsi,%rsi,4)
    adcw $-32768, 4660(%rdi,%rdi,8)
    adcw $32767, gnu_fwd(%rip)
    adcw $4660, 128
    adcw $-1, 0(%r8)
    adcw $0, -1(%r11)
    adcw $-128, -129(%r13)
    adcw $127, 0(%r12)
    adcw $-1, 64(%r12)
    adcw $0, -2147483648(%r12)
    adcw $-128, 0(%r14,%r12,1)
    adcw $127, 8(%r15,%rax,2)
    adcw $-1, 2147483647(%r8,%r15,4)
    adcw $0, %si
    adcw $-128, 0(%rsi)
    adcw $127, -128(%rbx)
    adcw $-1, 4660(%rbp)
    adcw $0, 0(%rsp)
    adcw $-128, 127(%rsp)
    adcw $127, 128(%rsp)
    adcw $-1, 0(%rax,%rax,8)
    adcw $0, -1(%rax,%rcx,1)
    adcw $-128, -129(%rcx,%rdx,2)
    adcw $127, gnu_back(%rip)
    adcw $-1, -2147483648
    adcl %r13d, 0(%rdx)
    adcl %r15d, 64(%r11)
    adcl %r9d, 2147483647(%rdi)
    adcl %r10d, 0(%rsp)
    adcl %r11d, 8(%r12)
    adcl %r14d, 4660(%rsp)
    adcl %r8d, 0(%rdx,%rsi,4)
    adcl %r12d, -128(%rax,%rcx,8)
    adcl %r13d, 128(%r9,%r9,1)
    adcl %r15d, gnu_fwd(%rip)
    adcl %r9d, -129
    adcl %edi, %ebp
    adcl %esp, 0(%rdi)
    adcl %ecx, 127(%rsi)
    adcl %edx, -2147483648(%rdi)
    adcl %ebx, 0(%rsp)
    adcl %esi, -1(%rsp)
    adcl %edi, 2147483647(%rsp)
    adcl %ebp, 0(%rcx,%rbx,2)
    adcl %esp, 64(%rdx,%rbp,4)
    adcl %ecx, 4660(%rbx,%rsi,8)
    adcl %edx, gnu_back(%rip)
    adcl %ebx, 128
    adcl 0(%r9), %r10d
    adcl 8(%r14), %r11d
    adcl -129(%r15), %r14d
    adcl 0(%r12), %r8d
    adcl -128(%rsp), %r12d
    adcl -2147483648(%r12), %r13d
    adcl 0(%r9,%rbp,1), %r15d
    adcl 127(%rsp,%r12,2), %r9d
    adcl 2147483647(%r13,%rax,4), %r10d
    adcl gnu_fwd(%rip), %r11d
    adcl 4660, %r14d
    adcl 0(%rcx), %esi
    adcl -1(%rcx), %edi
    adcl 128(%rdx), %ebp
    adcl 0(%rsp), %esp
    adcl 64(%rsp), %ecx
    adcl -129(%rsp), %edx
    adcl 0(%rdx,%rdi,8), %ebx
    adcl 8(%rsp,%rax,1), %esi
    adcl -2147483648(%rbp,%rcx,2), %edi
    adcl gnu_back(%rip), %ebp
    adcl 2147483647, %esp
    adcl $-2147483648, 0(%r9)
    adcl $2147483647, -128(%r14)
    adcl $305419896, 4660(%r15)
    adcl $1000, 0(%r12)
    adcl $-2147483648, 127(%r12)
    adcl $2147483647, 128(%r12)
    adcl $305419896, 0(%r15,%r15,4)
    adcl $1000, -1(%r9,%rsi,8)
    adcl $-2147483648, -129(%r12,%rcx,1)
    adcl $2147483647, %ecx
    adcl $305419896, 0(%rdx)
    adcl $1000, 64(%rbx)
    adcl $-2147483648, -2147483648(%rbp)
    adcl $2147483647, 0(%rsp)
    adcl $305419896, 8(%rsp)
    adcl $1000, 2147483647(%rsp)
    adcl $-2147483648, 0(%rbx,%rdx,2)
    adcl $2147483647, -128(%rsi,%rbx,4)
    adcl $305419896, 4660(%rdi,%rbp,8)
    adcl $1000, gnu_fwd(%rip)
    adcl $-2147483648, 128
    adcl $0, 0(%r10)
    adcl $-128, 127(%r8)
    adcl $127, -129(%r9)
    adcl $-1, 0(%r12)
    adcl $0, -1(%r12)
    adcl $-128, -2147483648(%r12)
    adcl $127, 0(%r8,%r9,1)
    adcl $-1, 64(%r13,%rbp,2)
    adcl $0, 2147483647(%r15,%r12,4)
    adcl $-128, %edx
    adcl $127, 0(%rbx)
    adcl $-1, 8(%rsi)
    adcl $0, 4660(%rdi)
g4:
    adcl $-128, 0(%rsp)
    adcl $127, -128(%rsp)
    adcl $-1, 128(%rsp)
    adcl $0, 0(%rsp,%rsi,8)
    adcl $-128, 127(%rax,%rdi,1)
    adcl $127, -129(%rcx,%rax,2)
    adcl $-1, gnu_back(%rip)
    adcl $0, -2147483648
    adcq %r8, 0(%rbx)
    adcq %r12, -1(%rcx)
    adcq %r13, 2147483647(%r8)
    adcq %r15, 0(%rsp)
    adcq %r9, 64(%r12)
    adcq %r10, 4660(%rsp)
    adcq %r11, 0(%rsp,%rax,4)
    adcq %r14, 8(%rbp,%r15,8)
    adcq %r8, 128(%r12,%rsi,1)
    adcq %r12, gnu_fwd(%rip)
    adcq %r13, -129
    adcq 0(%r10), %r15
    adcq -128(%rbp), %r9
    adcq -2147483648(%r13), %r10
    adcq 0(%r12), %r11
    adcq 127(%rsp), %r14
    adcq 2147483647(%r12), %r8
    adcq 0(%r14,%rcx,2), %r12
    adcq -1(%rdi,%r9,4), %r13
    adcq 4660(%r15,%rbp,8), %r15
    adcq gnu_back(%rip), %r9
    adcq 128, %r10
    adcq $2147483647, 0(%rsi)
    adcq $305419896, 64(%rdx)
    adcq $1000, -129(%r9)
    adcq $-2147483648, 0(%rsp)
    adcq $2147483647, 8(%r12)
    adcq $305419896, -2147483648(%rsp)
    adcq $1000, 0(%rsi,%r12,1)
    adcq $-2147483648, -128(%rax,%rax,2)
    adcq $2147483647, 2147483647(%r9,%r15,4)
    adcq $305419896, gnu_fwd(%rip)
    adcq $1000, 4660
    adcq $-128, 0(%r11)
    adcq $127, 127(%rbx)
    adcq $-1, 128(%r10)
    adcq $0, 0(%r12)
    adcq $-128, -1(%rsp)
    adcq $127, -129(%r12)
    adcq $-1, 0(%r15,%rsi,8)
    adcq $0, 64(%rsp,%rcx,1)
    adcq $-128, -2147483648(%r13,%r9,2)
    adcq $127, gnu_back(%rip)
    adcq $-1, 2147483647
    sbbb %spl, 0(%rdi)
    sbbb %r13b, 8(%rsi)
    sbbb %bpl, 4660(%r11)
    sbbb %r15b, 0(%rsp)
    sbbb %sil, -128(%r12)
    sbbb %dil, 128(%rsp)
    sbbb %r8b, 0(%rax,%rbp,4)
    sbbb %r12b, 127(%rbp,%r12,8)
    sbbb %spl, -129(%r12,%rax,1)
    sbbb %r13b, gnu_fwd(%rip)
    sbbb %bpl, -2147483648
    sbbb %ch, %ah
    sbbb %cl, 0(%rsi)
    sbbb %dl, -1(%rcx)
    sbbb %bl, 2147483647(%rdx)
    sbbb %dh, 0(%rsp)
    sbbb %bh, 64(%rsp)
    sbbb %ch, 4660(%rsp)
    sbbb %ah, 0(%rsi,%rcx,2)
    sbbb %cl, 8(%rdx,%rdx,4)
    sbbb %dl, 128(%rbx,%rbx,8)
    sbbb %bl, gnu_back(%rip)
    sbbb %dh, -129
    sbbb 0(%r14), %r15b
    sbbb -128(%rdi), %sil
    sbbb -2147483648(%r14), %dil
    sbbb 0(%r12), %r8b
    sbbb 127(%rsp), %r12b
    sbbb 2147483647(%r12), %spl
    sbbb 0(%r8,%r15,1), %r13b
    sbbb -1(%rdi,%rsi,2), %bpl
    sbbb 4660(%r15,%rcx,4), %r15b
    sbbb gnu_fwd(%rip), %sil
    sbbb 128, %dil
    sbbb 0(%rdi), %bh
    sbbb 64(%rbx), %ch
    sbbb -129(%rbp), %ah
    sbbb 0(%rsp), %cl
    sbbb 8(%rsp), %dl
    sbbb -2147483648(%rsp), %bl
    sbbb 0(%rdi,%rbp,8), %dh
    sbbb -128(%rsp,%rsi,1), %bh
    sbbb 2147483647(%rbp,%rdi,2), %ch
    sbbb gnu_back(%rip), %ah
    sbbb 4660, %cl
    sbbb $-128, 0(%r11)
    sbbb $127, 127(%r10)
    sbbb $255, 128(%r11)
    sbbb $-128, 0(%r12)
    sbbb $127, -1(%r12)
    sbbb $255, -129(%r12)
    sbbb $-128, 0(%r9,%r9,4)
    sbbb $127, 64(%r8,%rbp,8)
    sbbb $255, -2147483648(%r9,%r12,1)
    sbbb $-128, %dl
    sbbb $127, 0(%rcx)
    sbbb $255, 8(%rsi)
    sbbb $-128, 2147483647(%rdi)
    sbbb $127, 0(%rsp)
    sbbb $255, -128(%rsp)
    sbbb $-128, 4660(%rsp)
    sbbb $127, 0(%rax,%rax,2)
    sbbb $255, 127(%rsi,%rcx,4)
    sbbb $-128, 128(%rdi,%rdx,8)
    sbbb $127, gnu_fwd(%rip)
    sbbb $255, -129
    sbbw %r11w, 0(%r15)
    sbbw %r14w, -1(%r15)
    sbbw %r8w, -2147483648(%rcx)
    sbbw %r12w, 0(%rsp)
    sbbw %r13w, 64(%r12)
    sbbw %r15w, 2147483647(%rsp)
    sbbw %r9w, 0(%rcx,%rax,1)
    sbbw %r10w, 8(%rax,%r15,2)
    sbbw %r11w, 4660(%r9,%rsi,4)
    sbbw %r14w, gnu_back(%rip)
    sbbw %r8w, 128
    sbbw %bx, %si
    sbbw %di, 0(%rdx)
    sbbw %bp, -128(%rcx)
    sbbw %sp, -129(%rdx)
    sbbw %cx, 0(%rsp)
    sbbw %dx, 127(%rsp)
    sbbw %bx, -2147483648(%rsp)
    sbbw %si, 0(%rcx,%rbx,8)
    sbbw %di, -1(%rax,%rbp,1)
    sbbw %bp, 2147483647(%rcx,%rsi,2)
    sbbw %sp, gnu_fwd(%rip)
    sbbw %cx, 4660
    sbbw 0(%rcx), %r12w
    sbbw 64(%r8), %r13w
    sbbw 128(%rbp), %r15w
    sbbw 0(%r12), %r9w
    sbbw 8(%rsp), %r10w
    sbbw -129(%r12), %r11w
    sbbw 0(%r12,%rcx,4), %r14w
    sbbw -128(%rsp,%r9,8), %r8w
    sbbw -2147483648(%r13,%rbp,1), %r12w
    sbbw gnu_back(%rip), %r13w
    sbbw 2147483647, %r15w
    sbbw 0(%rbx), %dx
    sbbw 127(%rbx), %bx
    sbbw 4660(%rbp), %si
    sbbw 0(%rsp), %di
    sbbw -1(%rsp), %bp
    sbbw 128(%rsp), %sp
    sbbw 0(%rdx,%rdi,2), %cx
    sbbw 64(%rdx,%rax,4), %dx
    sbbw -129(%rbx,%rcx,8), %bx
    sbbw gnu_fwd(%rip), %si
    sbbw -2147483648, %di
    sbbw $200, 0(%r14)
    sbbw $-32768, 8(%r13)
    sbbw $32767, 2147483647(%r14)
    sbbw $4660, 0(%r12)
    sbbw $200, -128(%r12)
    sbbw $-32768, 4660(%r12)
    sbbw $32767, 0(%r10,%r12,1)
    sbbw $4660, 127(%r12,%rax,2)
    sbbw $200, 128(%r13,%r15,4)
    sbbw $-32768, %bp
    sbbw $32767, 0(%rsi)
    sbbw $4660, -1(%rsi)
    sbbw $200, -129(%rdi)
    sbbw $-32768, 0(%rsp)
    sbbw $32767, 64(%rsp)
    sbbw $4660, -2147483648(%rsp)
    sbbw $200, 0(%rbx,%rdx,8)
    sbbw $-32768, 8(%rsp,%rbx,1)
    sbbw $32767, 2147483647(%rbp,%rbp,2)
    sbbw $4660, gnu_back(%rip)
    sbbw $200, 4660
    sbbw $0, 0(%r15)
    sbbw $-128, -128(%r15)
    sbbw $127, 128(%r8)
    sbbw $-1, 0(%r12)
    sbbw $0, 127(%r12)
    sbbw $-128, -129(%r12)
    sbbw $127, 0(%r11,%rsi,4)
    sbbw $-1, -1(%r15,%rcx,8)
    sbbw $0, -2147483648(%r8,%r9,1)
    sbbw $-128, %sp
    sbbw $127, 0(%rdi)
    sbbw $-1, 64(%rcx)
    sbbw $0, 2147483647(%rdx)
    sbbw $-128, 0(%rsp)
    sbbw $127, 8(%rsp)
    sbbw $-1, 4660(%rsp)
g5:
    sbbw $0, 0(%rsp,%rsi,2)
    sbbw $-128, -128(%rsi,%rdi,4)
    sbbw $127, 128(%rdi,%rax,8)
    sbbw $-1, gnu_fwd(%rip)
    sbbw $0, -129
    sbbl %r9d, 0(%r8)
    sbbl %r10d, 127(%r13)
    sbbl %r11d, -2147483648(%rdx)
    sbbl %r14d, 0(%rsp)
    sbbl %r8d, -1(%r12)
    sbbl %r12d, 2147483647(%rsp)
    sbbl %r13d, 0(%rdx,%rbp,1)
    sbbl %r15d, 64(%rbp,%r12,2)
    sbbl %r9d, 4660(%r12,%rax,4)
    sbbl %r10d, gnu_back(%rip)
    sbbl %r11d, 128
    sbbl %ecx, %edx
    sbbl %ebx, 0(%rcx)
    sbbl %esi, 8(%rbx)
    sbbl %edi, -129(%rbp)
    sbbl %ebp, 0(%rsp)
    sbbl %esp, -128(%rsp)
    sbbl %ecx, -2147483648(%rsp)
    sbbl %edx, 0(%rsi,%rcx,8)
    sbbl %ebx, 127(%rax,%rdx,1)
    sbbl %esi, 2147483647(%rcx,%rbx,2)
    sbbl %edi, gnu_fwd(%rip)
    sbbl %ebp, 4660
    sbbl 0(%rdx), %r14d
    sbbl -1(%r9), %r8d
    sbbl 128(%rbx), %r12d
    sbbl 0(%r12), %r13d
    sbbl 64(%rsp), %r15d
    sbbl -129(%r12), %r9d
    sbbl 0(%r9,%r15,4), %r10d
    sbbl 8(%rdi,%rsi,8), %r11d
    sbbl -2147483648(%r15,%rcx,1), %r14d
    sbbl gnu_back(%rip), %r8d
    sbbl 2147483647, %r12d
    sbbl 0(%rdx), %esp
    sbbl -128(%rsi), %ecx
    sbbl 4660(%rdi), %edx
    sbbl 0(%rsp), %ebx
    sbbl 127(%rsp), %esi
    sbbl 128(%rsp), %edi
    sbbl 0(%rdi,%rbp,2), %ebp
    sbbl -1(%rdx,%rsi,4), %esp
    sbbl -129(%rbx,%rdi,8), %ecx
    sbbl gnu_fwd(%rip), %edx
    sbbl -2147483648, %ebx
    sbbl $-2147483648, 0(%r8)
    sbbl $2147483647, 64(%r9)
    sbbl $305419896, 2147483647(%r10)
    sbbl $1000, 0(%r12)
    sbbl $-2147483648, 8(%r12)
    sbbl $2147483647, 4660(%r12)
    sbbl $305419896, 0(%r12,%r9,1)
    sbbl $1000, -128(%r9,%rbp,2)
    sbbl $-2147483648, 128(%r12,%r12,4)
    sbbl $2147483647, %esi
    sbbl $305419896, 0(%rbx)
    sbbl $1000, 127(%rcx)
    sbbl $-2147483648, -129(%rdx)
    sbbl $2147483647, 0(%rsp)
    sbbl $305419896, -1(%rsp)
    sbbl $1000, -2147483648(%rsp)
    sbbl $-2147483648, 0(%rax,%rax,8)
    sbbl $2147483647, 64(%rsp,%rcx,1)
    sbbl $305419896, 2147483647(%rbp,%rdx,2)
    sbbl $1000, gnu_back(%rip)
    sbbl $-2147483648, 4660
    sbbl $-128, 0(%r9)
    sbbl $127, 8(%r11)
    sbbl $-1, 128(%r13)
    sbbl $0, 0(%r12)
    sbbl $-128, -128(%r12)
    sbbl $127, -129(%r12)
    sbbl $-1, 0(%r14,%rax,4)
    sbbl $0, 127(%r13,%r15,8)
    sbbl $-128, -2147483648(%r15,%rsi,1)
    sbbl $127, %edi
    sbbl $-1, 0(%rsi)
    sbbl $0, -1(%rbx)
    sbbl $-128, 2147483647(%rbp)
    sbbl $127, 0(%rsp)
    sbbl $-1, 64(%rsp)
    sbbl $0, 4660(%rsp)
    sbbl $-128, 0(%rcx,%rbx,2)
    sbbl $127, 8(%rsi,%rbp,4)
    sbbl $-1, 128(%rdi,%rsi,8)
    sbbl $0, gnu_fwd(%rip)
    sbbl $-128, -129
    sbbq %r13, 0(%r9)
    sbbq %r15, -128(%r10)
    sbbq %r9, -2147483648(%rsi)
    sbbq %r10, 0(%rsp)
    sbbq %r11, 127(%r12)
    sbbq %r14, 2147483647(%rsp)
    sbbq %r8, 0(%rsp,%rcx,1)
    sbbq %r12, -1(%rax,%r9,2)
    sbbq %r13, 4660(%r9,%rbp,4)
    sbbq %r15, gnu_back(%rip)
    sbbq %r9, 128
    sbbq 0(%rbx), %r10
    sbbq 64(%r11), %r11
    sbbq -129(%rdi), %r14
    sbbq 0(%r12), %r8
    sbbq 8(%rsp), %r12
    sbbq -2147483648(%r12), %r13
    sbbq 0(%r14,%r12,8), %r15
    sbbq -128(%rsp,%rax,1), %r9
    sbbq 2147483647(%r13,%r15,2), %r10
    sbbq gnu_fwd(%rip), %r11
    sbbq 4660, %r14
    sbbq $2147483647, 0(%r10)
    sbbq $305419896, 127(%r14)
    sbbq $1000, 128(%r15)
    sbbq $-2147483648, 0(%rsp)
    sbbq $2147483647, -1(%r12)
    sbbq $305419896, -129(%rsp)
    sbbq $1000, 0(%rsi,%rsi,4)
    sbbq $-2147483648, 64(%rbp,%rcx,8)
    sbbq $2147483647, -2147483648(%r12,%r9,1)
    sbbq $305419896, gnu_back(%rip)
    sbbq $1000, 2147483647
    sbbq $127, 0(%rsi)
    sbbq $-1, 8(%rcx)
    sbbq $0, 4660(%r8)
    sbbq $-128, 0(%r12)
    sbbq $127, -128(%rsp)
    sbbq $-1, 128(%r12)
    sbbq $0, 0(%r15,%rbp,2)
    sbbq $-128, 127(%rdi,%r12,4)
    sbbq $127, -129(%r15,%rax,8)
    sbbq $-1, gnu_fwd(%rip)
    sbbq $0, -2147483648
    andb %r8b, 0(%r11)
    andb %r12b, -1(%rbp)
    andb %spl, 2147483647(%r13)
    andb %r13b, 0(%rsp)
    andb %bpl, 64(%r12)
    andb %r15b, 4660(%rsp)
    andb %sil, 0(%rax,%r15,1)
    andb %dil, 8(%rax,%rsi,2)
    andb %r8b, 128(%r9,%rcx,4)
    andb %r12b, gnu_back(%rip)
    andb %spl, -129
    andb %bl, %dh
    andb %bh, 0(%rdi)
    andb %ch, -128(%rsi)
    andb %ah, -2147483648(%rdi)
    andb %cl, 0(%rsp)
    andb %dl, 127(%rsp)
    andb %bl, 2147483647(%rsp)
    andb %dh, 0(%rdx,%rdi,8)
    andb %bh, -1(%rax,%rax,1)
    andb %ch, 4660(%rcx,%rcx,2)
    andb %ah, gnu_fwd(%rip)
    andb %cl, 128
    andb 0(%rdi), %r13b
    andb 64(%rdx), %bpl
    andb -129(%r9), %r15b
    andb 0(%r12), %sil
    andb 8(%rsp), %dil
    andb -2147483648(%r12), %r8b
    andb 0(%r8,%r9,4), %r12b
    andb -128(%rsp,%rbp,8), %spl
    andb 2147483647(%r13,%r12,1), %r13b
    andb gnu_back(%rip), %bpl
    andb 4660, %r15b
    andb 0(%rcx), %dl
    andb 127(%rcx), %bl
    andb 128(%rdx), %dh
    andb 0(%rsp), %bh
    andb -1(%rsp), %ch
    andb -129(%rsp), %ah
    andb 0(%rbx,%rdx,2), %cl
    andb 64(%rdx,%rbx,4), %dl
    andb -2147483648(%rbx,%rbp,8), %bl
    andb gnu_fwd(%rip), %dh
    andb 2147483647, %bh
    andb $-128, 0(%r10)
    andb $127, 8(%r14)
    andb $255, 4660(%r15)
    andb $-128, 0(%r12)
    andb $127, -128(%r12)
    andb $255, 128(%r12)
    andb $-128, 0(%r15,%rax,1)
    andb $127, 127(%r8,%r15,2)
    andb $255, -129(%r9,%rsi,4)
    andb $-128, %ch
    andb $127, 0(%rdx)
    andb $255, -1(%rbx)
    andb $-128, -2147483648(%rbp)
    andb $127, 0(%rsp)
    andb $255, 64(%rsp)
    andb $-128, 2147483647(%rsp)
    andb $127, 0(%rsp,%rsi,8)
    andb $255, 8(%rsp,%rdi,1)
    andb $-128, 4660(%rbp,%rax,2)
g6:
    andb $127, gnu_back(%rip)
    andb $255, 128
    andw %r8w, 0(%r14)
    andw %r12w, -128(%rbx)
    andw %r13w, -129(%r10)
    andw %r15w, 0(%rsp)
    andw %r9w, 127(%r12)
    andw %r10w, -2147483648(%rsp)
    andw %r11w, 0(%rcx,%rcx,4)
    andw %r14w, -1(%rbp,%r9,8)
    andw %r8w, 2147483647(%r12,%rbp,1)
    andw %r12w, gnu_fwd(%rip)
    andw %r13w, 4660
    andw %bp, %sp
    andw %cx, 0(%rbx)
    andw %dx, 64(%rsi)
    andw %bx, 128(%rdi)
    andw %si, 0(%rsp)
    andw %di, 8(%rsp)
    andw %bp, -129(%rsp)
    andw %sp, 0(%rsi,%rcx,2)
    andw %cx, -128(%rsi,%rdx,4)
    andw %dx, -2147483648(%rdi,%rbx,8)
    andw %bx, gnu_back(%rip)
    andw %si, 2147483647
    andw 0(%r15), %r15w
    andw 127(%rsi), %r9w
    andw 4660(%r11), %r10w
    andw 0(%r12), %r11w
    andw -1(%rsp), %r14w
    andw 128(%r12), %r8w
    andw 0(%r12,%r12,1), %r12w
    andw 64(%rdi,%rax,2), %r13w
    andw -129(%r15,%r15,4), %r15w
    andw gnu_fwd(%rip), %r9w
    andw -2147483648, %r10w
    andw 0(%rsi), %di
    andw 8(%rcx), %bp
    andw 2147483647(%rdx), %sp
    andw 0(%rsp), %cx
    andw -128(%rsp), %dx
    andw 4660(%rsp), %bx
    andw 0(%rdi,%rbp,8), %si
    andw 127(%rax,%rsi,1), %di
    andw 128(%rcx,%rdi,2), %bp
    andw gnu_back(%rip), %sp
    andw -129, %cx
    andw $-32768, 0(%r11)
    andw $32767, -1(%r8)
    andw $4660, -2147483648(%r9)
    andw $200, 0(%r12)
    andw $-32768, 64(%r12)
    andw $32767, 2147483647(%r12)
    andw $4660, 0(%r8,%rsi,4)
    andw $200, 8(%r12,%rcx,8)
    andw $-32768, 4660(%r13,%r9,1)
    andw $32767, %dx
    andw $4660, 0(%rdi)
    andw $200, -128(%rbx)
    andw $-32768, 128(%rbp)
    andw $32767, 0(%rsp)
    andw $4660, 127(%rsp)
    andw $200, -129(%rsp)
    andw $-32768, 0(%rax,%rax,2)
    andw $32767, -1(%rdx,%rcx,4)
    andw $4660, -2147483648(%rbx,%rdx,8)
    andw $200, gnu_fwd(%rip)
    andw $-32768, 2147483647
    andw $-128, 0(%r14)
    andw $127, 64(%r10)
    andw $-1, 4660(%r11)
    andw $0, 0(%r12)
    andw $-128, 8(%r12)
    andw $127, 128(%r12)
    andw $-1, 0(%r9,%rbp,1)
    andw $0, -128(%r15,%r12,2)
    andw $-128, -129(%r8,%rax,4)
    andw $127, %bx
    andw $-1, 0(%rcx)
    andw $0, 127(%rsi)
    andw $-128, -2147483648(%rdi)
    andw $127, 0(%rsp)
    andw $-1, -1(%rsp)
    andw $0, 2147483647(%rsp)
    andw $-128, 0(%rcx,%rbx,8)
    andw $127, 64(%rsp,%rbp,1)
    andw $-1, 4660(%rbp,%rsi,2)
    andw $0, gnu_back(%rip)
    andw $-128, 128
    andl %r11d, 0(%rcx)
    andl %r14d, 8(%rdi)
    andl %r8d, -129(%r14)
    andl %r12d, 0(%rsp)
    andl %r13d, -128(%r12)
    andl %r15d, -2147483648(%rsp)
    andl %r9d, 0(%rdx,%r15,4)
    andl %r10d, 127(%rax,%rsi,8)
    andl %r11d, 2147483647(%r9,%rcx,1)
    andl %r14d, gnu_fwd(%rip)
    andl %r8d, 4660
    andl %esi, %edi
    andl %ebp, 0(%rdx)
    andl %esp, -1(%rcx)
    andl %ecx, 128(%rdx)
    andl %edx, 0(%rsp)
    andl %ebx, 64(%rsp)
    andl %esi, -129(%rsp)
    andl %edi, 0(%rdx,%rdi,2)
    andl %ebp, 8(%rsi,%rax,4)
    andl %esp, -2147483648(%rdi,%rcx,8)
    andl %ecx, gnu_back(%rip)
    andl %edx, 2147483647
    andl 0(%r8), %r12d
    andl -128(%r15), %r13d
    andl 4660(%rcx), %r15d
    andl 0(%r12), %r9d
    andl 127(%rsp), %r10d
    andl 128(%r12), %r11d
    andl 0(%r9,%r9,1), %r14d
    andl -1(%rsp,%rbp,2), %r8d
    andl -129(%r13,%r12,4), %r12d
    andl gnu_fwd(%rip), %r13d
    andl -2147483648, %r15d
    andl 0(%rbx), %ebx
    andl 64(%rbx), %esi
    andl 2147483647(%rbp), %edi
    andl 0(%rsp), %ebp
    andl 8(%rsp), %esp
    andl 4660(%rsp), %ecx
    andl 0(%rbx,%rdx,8), %edx
    andl -128(%rax,%rbx,1), %ebx
    andl 128(%rcx,%rbp,2), %esi
    andl gnu_back(%rip), %edi
    andl -129, %ebp
    andl $-2147483648, 0(%r15)
    andl $2147483647, 127(%r13)
    andl $305419896, -2147483648(%r14)
    andl $1000, 0(%r12)
    andl $-2147483648, -1(%r12)
    andl $2147483647, 2147483647(%r12)
    andl $305419896, 0(%r10,%rax,4)
    andl $1000, 64(%r9,%r15,8)
    andl $-2147483648, 4660(%r12,%rsi,1)
    andl $2147483647, %esp
    andl $305419896, 0(%rsi)
    andl $1000, 8(%rsi)
    andl $-2147483648, 128(%rdi)
    andl $2147483647, 0(%rsp)
    andl $305419896, -128(%rsp)
    andl $1000, -129(%rsp)
    andl $-2147483648, 0(%rsp,%rsi,2)
    andl $2147483647, 127(%rdx,%rdi,4)
    andl $305419896, -2147483648(%rbx,%rax,8)
    andl $1000, gnu_fwd(%rip)
    andl $-2147483648, 2147483647
    andl $127, 0(%r8)
    andl $-1, -1(%r15)
    andl $0, 4660(%r8)
    andl $-128, 0(%r12)
    andl $127, 64(%r12)
    andl $-1, 128(%r12)
    andl $0, 0(%r11,%rcx,1)
    andl $-128, 8(%r13,%r9,2)
    andl $127, -129(%r15,%rbp,4)
    andl $-1, %ecx
    andl $0, 0(%rdi)
    andl $-128, -128(%rcx)
    andl $127, -2147483648(%rdx)
    andl $-1, 0(%rsp)
    andl $0, 127(%rsp)
    andl $-128, 2147483647(%rsp)
    andl $127, 0(%rsi,%rcx,8)
    andl $-1, -1(%rsp,%rdx,1)
    andl $0, 4660(%rbp,%rbx,2)
    andl $-128, gnu_back(%rip)
    andl $127, 128
    andq %r9, 0(%rdx)
    andq %r10, 64(%r8)
    andq %r11, -129(%rbp)
    andq %r14, 0(%rsp)
    andq %r8, 8(%r12)
    andq %r12, -2147483648(%rsp)
    andq %r13, 0(%rsp,%r12,4)
    andq %r15, -128(%rbp,%rax,8)
    andq %r9, 2147483647(%r12,%r15,1)
    andq %r10, gnu_fwd(%rip)
    andq %r11, 4660
    andq 0(%r9), %r14
    andq 127(%r13), %r8
    andq 128(%rdx), %r12
    andq 0(%r12), %r13
    andq -1(%rsp), %r15
    andq -129(%r12), %r9
    andq 0(%r14,%rsi,2), %r10
    andq 64(%rdi,%rcx,4), %r11
    andq -2147483648(%r15,%r9,8), %r14
    andq gnu_back(%rip), %r8
    andq 2147483647, %r12
    andq $2147483647, 0(%rbx)
    andq $305419896, 8(%r9)
g7:
    andq $1000, 4660(%rbx)
    andq $-2147483648, 0(%rsp)
    andq $2147483647, -128(%r12)
    andq $305419896, 128(%rsp)
    andq $1000, 0(%rsi,%rbp,1)
    andq $-2147483648, 127(%rax,%r12,2)
    andq $2147483647, -129(%r9,%rax,4)
    andq $305419896, gnu_fwd(%rip)
    andq $1000, -2147483648
    andq $-1, 0(%r10)
    andq $0, -1(%r10)
    andq $-128, 2147483647(%rsi)
    andq $127, 0(%r12)
    andq $-1, 64(%rsp)
    andq $0, 4660(%r12)
    andq $-128, 0(%r15,%r15,8)
    andq $127, 8(%rsp,%rsi,1)
    andq $-1, 128(%r13,%rcx,2)
    andq $0, gnu_back(%rip)
    andq $-128, -129
    subb %sil, 0(%rsi)
    subb %dil, -128(%r11)
    subb %r8b, -2147483648(%rdi)
    subb %r12b, 0(%rsp)
    subb %spl, 127(%r12)
    subb %r13b, 2147483647(%rsp)
    subb %bpl, 0(%rax,%r9,4)
    subb %r15b, -1(%rbp,%rbp,8)
    subb %sil, 4660(%r12,%r12,1)
    subb %dil, gnu_fwd(%rip)
    subb %r8b, 128
    subb %ah, %cl
    subb %dl, 0(%rcx)
    subb %bl, 64(%rbx)
    subb %dh, -129(%rbp)
    subb %bh, 0(%rsp)
    subb %ch, 8(%rsp)
    subb %ah, -2147483648(%rsp)
    subb %cl, 0(%rdi,%rbp,2)
    subb %dl, -128(%rsi,%rsi,4)
    subb %bl, 2147483647(%rdi,%rdi,8)
    subb %dh, gnu_back(%rip)
    subb %bh, 4660
    subb 0(%r11), %r12b
    subb 127(%r14), %spl
    subb 128(%r15), %r13b
    subb 0(%r12), %bpl
    subb -1(%rsp), %r15b
    subb -129(%r12), %sil
    subb 0(%r8,%rax,1), %dil
    subb 64(%rdi,%r15,2), %r8b
    subb -2147483648(%r15,%rsi,4), %r12b
    subb gnu_fwd(%rip), %spl
    subb 2147483647, %r13b
    subb 0(%rdx), %ch
    subb 8(%rsi), %ah
    subb 4660(%rdi), %cl
    subb 0(%rsp), %dl
    subb -128(%rsp), %bl
    subb 128(%rsp), %dh
    subb 0(%rax,%rax,8), %bh
    subb 127(%rax,%rcx,1), %ch
    subb -129(%rcx,%rdx,2), %ah
    subb gnu_back(%rip), %cl
    subb -2147483648, %dl
    subb $-128, 0(%r9)
    subb $127, -1(%r9)
    subb $255, 2147483647(%r10)
    subb $-128, 0(%r12)
    subb $127, 64(%r12)
    subb $255, 4660(%r12)
    subb $-128, 0(%r12,%rcx,4)
    subb $127, 8(%r8,%r9,8)
    subb $255, 128(%r9,%rbp,1)
    subb $-128, %bl
    subb $127, 0(%rbx)
    subb $255, -128(%rcx)
    subb $-128, -129(%rdx)
    subb $127, 0(%rsp)
    subb $255, 127(%rsp)
    subb $-128, -2147483648(%rsp)
    subb $127, 0(%rcx,%rbx,2)
    subb $255, -1(%rdx,%rbp,4)
    subb $-128, 2147483647(%rbx,%rsi,8)
    subb $127, gnu_fwd(%rip)
    subb $255, 4660
    subw %r13w, 0(%rdi)
    subw %r15w, 64(%rcx)
    subw %r9w, 128(%r8)
    subw %r10w, 0(%rsp)
    subw %r11w, 8(%r12)
    subw %r14w, -129(%rsp)
    subw %r8w, 0(%rcx,%r12,1)
    subw %r12w, -128(%rax,%rax,2)
    subw %r13w, -2147483648(%r9,%r15,4)
    subw %r15w, gnu_back(%rip)
    subw %r9w, 2147483647
    subw %dx, %bx
    subw %si, 0(%rsi)
    subw %di, 127(%rbx)
    subw %bp, 4660(%rbp)
    subw %sp, 0(%rsp)
    subw %cx, -1(%rsp)
    subw %dx, 128(%rsp)
    subw %bx, 0(%rdx,%rdi,8)
    subw %si, 64(%rsp,%rax,1)
    subw %di, -129(%rbp,%rcx,2)
    subw %bp, gnu_fwd(%rip)
    subw %sp, -2147483648
    subw 0(%r14), %r10w
    subw 8(%rbp), %r11w
    subw 2147483647(%r13), %r14w
    subw 0(%r12), %r8w
    subw -128(%rsp), %r12w
    subw 4660(%r12), %r13w
    subw 0(%r12,%rsi,4), %r15w
    subw 127(%rsp,%rcx,8), %r9w
    subw 128(%r13,%r9,1), %r10w
    subw gnu_back(%rip), %r11w
    subw -129, %r14w
    subw 0(%rdi), %cx
    subw -1(%rsi), %dx
    subw -2147483648(%rdi), %bx
    subw 0(%rsp), %si
    subw 64(%rsp), %di
    subw 2147483647(%rsp), %bp
    subw 0(%rbx,%rdx,2), %sp
    subw 8(%rsi,%rbx,4), %cx
    subw 4660(%rdi,%rbp,8), %dx
    subw gnu_fwd(%rip), %bx
    subw 128, %si
    subw $32767, 0(%r10)
    subw $4660, -128(%r11)
    subw $200, -129(%r13)
    subw $-32768, 0(%r12)
    subw $32767, 127(%r12)
    subw $4660, -2147483648(%r12)
    subw $200, 0(%r14,%rbp,1)
    subw $-32768, -1(%r12,%r12,2)
    subw $32767, 2147483647(%r13,%rax,4)
    subw $4660, %di
    subw $200, 0(%rcx)
    subw $-32768, 64(%rcx)
    subw $32767, 4660(%rdx)
    subw $4660, 0(%rsp)
    subw $200, 8(%rsp)
    subw $-32768, 128(%rsp)
    subw $32767, 0(%rsp,%rsi,8)
    subw $4660, -128(%rax,%rdi,1)
    subw $200, -129(%rcx,%rax,2)
    subw $-32768, gnu_back(%rip)
    subw $32767, -2147483648
    subw $127, 0(%r11)
    subw $-1, 127(%r14)
    subw $0, 2147483647(%r15)
    subw $-128, 0(%r12)
    subw $127, -1(%r12)
    subw $-1, 4660(%r12)
    subw $0, 0(%r15,%r15,4)
    subw $-128, 64(%r15,%rsi,8)
    subw $127, 128(%r8,%rcx,1)
    subw $-1, %bp
    subw $0, 0(%rdx)
    subw $-128, 8(%rbx)
    subw $127, -129(%rbp)
    subw $-1, 0(%rsp)
    subw $0, -128(%rsp)
    subw $-128, -2147483648(%rsp)
    subw $127, 0(%rsi,%rcx,2)
    subw $-1, 127(%rdx,%rdx,4)
    subw $0, 2147483647(%rbx,%rbx,8)
    subw $-128, gnu_fwd(%rip)
    subw $127, 4660
    subl %r8d, 0(%r15)
    subl %r12d, -1(%rdx)
    subl %r13d, 128(%r9)
    subl %r15d, 0(%rsp)
    subl %r9d, 64(%r12)
    subl %r10d, -129(%rsp)
    subl %r11d, 0(%rdx,%r9,1)
    subl %r14d, 8(%rbp,%rbp,2)
    subl %r8d, -2147483648(%r12,%r12,4)
    subl %r12d, gnu_back(%rip)
    subl %r13d, 2147483647
    subl %esp, %ecx
    subl %edx, 0(%rbx)
    subl %ebx, -128(%rsi)
    subl %esi, 4660(%rdi)
    subl %edi, 0(%rsp)
    subl %ebp, 127(%rsp)
    subl %esp, 128(%rsp)
    subl %ecx, 0(%rdi,%rbp,8)
    subl %edx, -1(%rsp,%rsi,1)
    subl %ebx, -129(%rbp,%rdi,2)
    subl %esi, gnu_fwd(%rip)
    subl %edi, -2147483648
    subl 0(%rcx), %r15d
    subl 64(%rbx), %r9d
    subl 2147483647(%r10), %r10d
    subl 0(%r12), %r11d
g8:
    subl 8(%rsp), %r14d
    subl 4660(%r12), %r8d
    subl 0(%r9,%rax,4), %r12d
    subl -128(%rdi,%r15,8), %r13d
    subl 128(%r15,%rsi,1), %r15d
    subl gnu_back(%rip), %r9d
    subl -129, %r10d
    subl 0(%rsi), %ebp
    subl 127(%rcx), %esp
    subl -2147483648(%rdx), %ecx
    subl 0(%rsp), %edx
    subl -1(%rsp), %ebx
    subl 2147483647(%rsp), %esi
    subl 0(%rax,%rax,2), %edi
    subl 64(%rsi,%rcx,4), %ebp
    subl 4660(%rdi,%rdx,8), %esp
    subl gnu_fwd(%rip), %ecx
    subl 128, %edx
    subl $-2147483648, 0(%r14)
    subl $2147483647, 8(%r8)
    subl $305419896, -129(%r9)
    subl $1000, 0(%r12)
    subl $-2147483648, -128(%r12)
    subl $2147483647, -2147483648(%r12)
    subl $305419896, 0(%r8,%rcx,1)
    subl $1000, 127(%r9,%r9,2)
    subl $-2147483648, 2147483647(%r12,%rbp,4)
    subl $2147483647, %ebx
    subl $305419896, 0(%rdi)
    subl $1000, -1(%rbx)
    subl $-2147483648, 4660(%rbp)
    subl $2147483647, 0(%rsp)
    subl $305419896, 64(%rsp)
    subl $1000, 128(%rsp)
    subl $-2147483648, 0(%rcx,%rbx,8)
    subl $2147483647, 8(%rax,%rbp,1)
    subl $305419896, -129(%rcx,%rsi,2)
    subl $1000, gnu_back(%rip)
    subl $-2147483648, -2147483648
    subl $-1, 0(%r15)
    subl $0, -128(%r10)
    subl $-128, 2147483647(%r11)
    subl $127, 0(%r12)
    subl $-1, 127(%r12)
    subl $0, 4660(%r12)
    subl $-128, 0(%r9,%r12,4)
    subl $127, -1(%r13,%rax,8)
    subl $-1, 128(%r15,%r15,1)
    subl $0, %esi
    subl $-128, 0(%rcx)
    subl $127, 64(%rsi)
    subl $-1, -129(%rdi)
    subl $0, 0(%rsp)
    subl $-128, 8(%rsp)
    subl $127, -2147483648(%rsp)
    subl $-1, 0(%rdx,%rdi,2)
    subl $0, -128(%rdx,%rax,4)
    subl $-128, 2147483647(%rbx,%rcx,8)
    subl $127, gnu_fwd(%rip)
    subl $-1, 4660
    subq %r11, 0(%r8)
    subq %r14, 127(%rsi)
    subq %r8, 128(%r11)
    subq %r12, 0(%rsp)
    subq %r13, -1(%r12)
    subq %r15, -129(%rsp)
    subq %r9, 0(%rsp,%rsi,1)
    subq %r10, 64(%rax,%rcx,2)
    subq %r11, -2147483648(%r9,%r9,4)
    subq %r14, gnu_back(%rip)
    subq %r8, 2147483647
    subq 0(%rdx), %r12
    subq 8(%rdi), %r13
    subq 4660(%r14), %r15
    subq 0(%r12), %r9
    subq -128(%rsp), %r10
    subq 128(%r12), %r11
    subq 0(%r14,%rbp,8), %r14
    subq 127(%rsp,%r12,1), %r8
    subq -129(%r13,%rax,2), %r12
    subq gnu_fwd(%rip), %r13
    subq -2147483648, %r15
    subq $2147483647, 0(%r9)
    subq $305419896, -1(%r15)
    subq $1000, 2147483647(%rcx)
    subq $-2147483648, 0(%rsp)
    subq $2147483647, 64(%r12)
    subq $305419896, 4660(%rsp)
    subq $1000, 0(%rsi,%r15,4)
    subq $-2147483648, 8(%rbp,%rsi,8)
    subq $2147483647, 128(%r12,%rcx,1)
    subq $305419896, gnu_back(%rip)
    subq $1000, -129
    subq $0, 0(%rbx)
    subq $-128, -128(%r8)
    subq $127, -2147483648(%rbp)
    subq $-1, 0(%r12)
    subq $0, 127(%rsp)
    subq $-128, 2147483647(%r12)
    subq $127, 0(%r15,%r9,2)
    subq $-1, -1(%rdi,%rbp,4)
    subq $0, 4660(%r15,%r12,8)
    subq $-128, gnu_fwd(%rip)
    subq $127, 128
    xorb %bpl, 0(%r10)
    xorb %r15b, 64(%r13)
    xorb %sil, -129(%rdx)
    xorb %dil, 0(%rsp)
    xorb %r8b, 8(%r12)
    xorb %r12b, -2147483648(%rsp)
    xorb %spl, 0(%rax,%rax,1)
    xorb %r13b, -128(%rax,%r15,2)
    xorb %bpl, 2147483647(%r9,%rsi,4)
    xorb %r15b, gnu_back(%rip)
    xorb %sil, 4660
    xorb %dh, %bh
    xorb %ch, 0(%rdx)
    xorb %ah, 127(%rcx)
    xorb %cl, 128(%rdx)
    xorb %dl, 0(%rsp)
    xorb %bl, -1(%rsp)
    xorb %dh, -129(%rsp)
    xorb %bh, 0(%rbx,%rdx,8)
    xorb %ch, 64(%rsp,%rbx,1)
    xorb %ah, -2147483648(%rbp,%rbp,2)
    xorb %cl, gnu_fwd(%rip)
    xorb %dl, 2147483647
    xorb 0(%rsi), %dil
    xorb 8(%r9), %r8b
    xorb 4660(%rbx), %r12b
    xorb 0(%r12), %spl
    xorb -128(%rsp), %r13b
    xorb 128(%r12), %bpl
    xorb 0(%r8,%rcx,4), %r15b
    xorb 127(%rsp,%r9,8), %sil
    xorb -129(%r13,%rbp,1), %dil
    xorb gnu_back(%rip), %r8b
    xorb -2147483648, %r12b
    xorb 0(%rbx), %bl
    xorb -1(%rbx), %dh
    xorb 2147483647(%rbp), %bh
    xorb 0(%rsp), %ch
    xorb 64(%rsp), %ah
    xorb 4660(%rsp), %cl
    xorb 0(%rsp,%rsi,2), %dl
    xorb 8(%rsi,%rdi,4), %bl
    xorb 128(%rdi,%rax,8), %dh
    xorb gnu_fwd(%rip), %bh
    xorb -129, %ch
    xorb $-128, 0(%r8)
    xorb $127, -128(%r13)
    xorb $255, -2147483648(%r14)
    xorb $-128, 0(%r12)
    xorb $127, 127(%r12)
    xorb $255, 2147483647(%r12)
    xorb $-128, 0(%r10,%r12,1)
    xorb $127, -1(%r8,%rax,2)
    xorb $255, 4660(%r9,%r15,4)
    xorb $-128, %ah
    xorb $127, 0(%rsi)
    xorb $255, 64(%rsi)
    xorb $-128, 128(%rdi)
    xorb $127, 0(%rsp)
    xorb $255, 8(%rsp)
    xorb $-128, -129(%rsp)
    xorb $127, 0(%rsi,%rcx,8)
    xorb $255, -128(%rax,%rdx,1)
    xorb $-128, -2147483648(%rcx,%rbx,2)
    xorb $127, gnu_back(%rip)
    xorb $255, 2147483647
    xorw %r9w, 0(%r11)
    xorw %r10w, 127(%r10)
    xorw %r11w, 4660(%rsi)
    xorw %r14w, 0(%rsp)
    xorw %r8w, -1(%r12)
    xorw %r12w, 128(%rsp)
    xorw %r13w, 0(%rcx,%rsi,4)
    xorw %r15w, 64(%rbp,%rcx,8)
    xorw %r9w, -129(%r12,%r9,1)
    xorw %r10w, gnu_fwd(%rip)
    xorw %r11w, -2147483648
    xorw %di, %bp
    xorw %sp, 0(%rdi)
    xorw %cx, 8(%rcx)
    xorw %dx, 2147483647(%rdx)
    xorw %bx, 0(%rsp)
    xorw %si, -128(%rsp)
    xorw %di, 4660(%rsp)
    xorw %bp, 0(%rdi,%rbp,2)
    xorw %sp, 127(%rdx,%rsi,4)
    xorw %cx, 128(%rbx,%rdi,8)
    xorw %dx, gnu_back(%rip)
    xorw %bx, -129
    xorw 0(%rdi), %r14w
    xorw -1(%r11), %r8w
    xorw -2147483648(%rdi), %r12w
    xorw 0(%r12), %r13w
    xorw 64(%rsp), %r15w
    xorw 2147483647(%r12), %r9w
    xorw 0(%r12,%rbp,1), %r10w
g9:
    xorw 8(%rdi,%r12,2), %r11w
    xorw 4660(%r15,%rax,4), %r14w
    xorw gnu_fwd(%rip), %r8w
    xorw 128, %r12w
    xorw 0(%rcx), %si
    xorw -128(%rbx), %di
    xorw -129(%rbp), %bp
    xorw 0(%rsp), %sp
    xorw 127(%rsp), %cx
    xorw -2147483648(%rsp), %dx
    xorw 0(%rax,%rax,8), %bx
    xorw -1(%rsp,%rcx,1), %si
    xorw 2147483647(%rbp,%rdx,2), %di
    xorw gnu_back(%rip), %bp
    xorw 4660, %sp
    xorw $4660, 0(%r9)
    xorw $200, 64(%r15)
    xorw $-32768, 128(%r8)
    xorw $32767, 0(%r12)
    xorw $4660, 8(%r12)
    xorw $200, -129(%r12)
    xorw $-32768, 0(%r11,%r15,4)
    xorw $32767, -128(%r12,%rsi,8)
    xorw $4660, -2147483648(%r13,%rcx,1)
    xorw $200, %cx
    xorw $-32768, 0(%rdx)
    xorw $32767, 127(%rsi)
    xorw $4660, 2147483647(%rdi)
    xorw $200, 0(%rsp)
    xorw $-32768, -1(%rsp)
    xorw $32767, 4660(%rsp)
    xorw $4660, 0(%rcx,%rbx,2)
    xorw $200, 64(%rsi,%rbp,4)
    xorw $-32768, 128(%rdi,%rsi,8)
    xorw $32767, gnu_fwd(%rip)
    xorw $4660, -129
    xorw $-1, 0(%r10)
    xorw $0, 8(%r9)
    xorw $-128, -2147483648(%r10)
    xorw $127, 0(%r12)
    xorw $-1, -128(%r12)
    xorw $0, 2147483647(%r12)
    xorw $-128, 0(%r12,%r9,1)
    xorw $127, 127(%r15,%rbp,2)
    xorw $-1, 4660(%r8,%r12,4)
    xorw $0, %dx
    xorw $-128, 0(%rbx)
    xorw $127, -1(%rcx)
    xorw $-1, 128(%rdx)
    xorw $0, 0(%rsp)
    xorw $-128, 64(%rsp)
    xorw $127, -129(%rsp)
    xorw $-1, 0(%rdx,%rdi,8)
    xorw $0, 8(%rax,%rax,1)
    xorw $-128, -2147483648(%rcx,%rcx,2)
    xorw $127, gnu_back(%rip)
    xorw $-1, 2147483647
    xorl %r13d, 0(%r14)
    xorl %r15d, -128(%r14)
    xorl %r9d, 4660(%r15)
    xorl %r10d, 0(%rsp)
    xorl %r11d, 127(%r12)
    xorl %r14d, 128(%rsp)
    xorl %r8d, 0(%rdx,%rax,4)
    xorl %r12d, -1(%rax,%r15,8)
    xorl %r13d, -129(%r9,%rsi,1)
    xorl %r15d, gnu_fwd(%rip)
    xorl %r9d, -2147483648
    xorl %ebx, %esi
    xorl %edi, 0(%rsi)
    xorl %ebp, 64(%rbx)
    xorl %esp, 2147483647(%rbp)
    xorl %ecx, 0(%rsp)
    xorl %edx, 8(%rsp)
    xorl %ebx, 4660(%rsp)
    xorl %esi, 0(%rbx,%rdx,2)
    xorl %edi, -128(%rdx,%rbx,4)
    xorl %ebp, 128(%rbx,%rbp,8)
    xorl %esp, gnu_back(%rip)
    xorl %ecx, -129
    xorl 0(%r15), %r10d
    xorl 127(%rcx), %r11d
    xorl -2147483648(%r8), %r14d
    xorl 0(%r12), %r8d
    xorl -1(%rsp), %r12d
    xorl 2147483647(%r12), %r13d
    xorl 0(%r9,%rcx,1), %r15d
    xorl 64(%rsp,%r9,2), %r9d
    xorl 4660(%r13,%rbp,4), %r10d
    xorl gnu_fwd(%rip), %r11d
    xorl 128, %r14d
    xorl 0(%rdi), %edx
    xorl 8(%rsi), %ebx
    xorl -129(%rdi), %esi
    xorl 0(%rsp), %edi
    xorl -128(%rsp), %ebp
    xorl -2147483648(%rsp), %esp
    xorl 0(%rsp,%rsi,8), %ecx
    xorl 127(%rsp,%rdi,1), %edx
    xorl 2147483647(%rbp,%rax,2), %ebx
    xorl gnu_back(%rip), %esi
    xorl 4660, %edi
    xorl $-2147483648, 0(%r11)
    xorl $2147483647, -1(%r11)
    xorl $305419896, 128(%r13)
    xorl $1000, 0(%r12)
    xorl $-2147483648, 64(%r12)
    xorl $2147483647, -129(%r12)
    xorl $305419896, 0(%r14,%r12,4)
    xorl $1000, 8(%r9,%rax,8)
    xorl $-2147483648, -2147483648(%r12,%r15,1)
    xorl $2147483647, %ebp
    xorl $305419896, 0(%rcx)
    xorl $1000, -128(%rcx)
    xorl $-2147483648, 2147483647(%rdx)
    xorl $2147483647, 0(%rsp)
    xorl $305419896, 127(%rsp)
    xorl $1000, 4660(%rsp)
    xorl $-2147483648, 0(%rsi,%rcx,2)
    xorl $2147483647, -1(%rsi,%rdx,4)
    xorl $305419896, 128(%rdi,%rbx,8)
    xorl $1000, gnu_fwd(%rip)
    xorl $-2147483648, -129
    xorl $0, 0(%r14)
    xorl $-128, 64(%r14)
    xorl $127, -2147483648(%r15)
    xorl $-1, 0(%r12)
    xorl $0, 8(%r12)
    xorl $-128, 2147483647(%r12)
    xorl $127, 0(%r15,%rsi,1)
    xorl $-1, -128(%r13,%rcx,2)
    xorl $0, 4660(%r15,%r9,4)
    xorl $-128, %esp
    xorl $127, 0(%rdx)
    xorl $-1, 127(%rbx)
    xorl $0, 128(%rbp)
    xorl $-128, 0(%rsp)
    xorl $127, -1(%rsp)
    xorl $-1, -129(%rsp)
    xorl $0, 0(%rdi,%rbp,8)
    xorl $-128, 64(%rax,%rsi,1)
    xorl $127, -2147483648(%rcx,%rdi,2)
    xorl $-1, gnu_back(%rip)
    xorl $0, 2147483647
    xorq %r8, 0(%rcx)
    xorq %r12, 8(%rbp)
    xorq %r13, 4660(%r13)
    xorq %r15, 0(%rsp)
    xorq %r9, -128(%r12)
    xorq %r10, 128(%rsp)
    xorq %r11, 0(%rsp,%rbp,4)
    xorq %r14, 127(%rbp,%r12,8)
    xorq %r8, -129(%r12,%rax,1)
    xorq %r12, gnu_fwd(%rip)
    xorq %r13, -2147483648
    xorq 0(%r8), %r15
    xorq -1(%rdx), %r9
    xorq 2147483647(%r9), %r10
    xorq 0(%r12), %r11
    xorq 64(%rsp), %r14
    xorq 4660(%r12), %r8
    xorq 0(%r14,%r15,2), %r12
    xorq 8(%rdi,%rsi,4), %r13
    xorq 128(%r15,%rcx,8), %r15
    xorq gnu_back(%rip), %r9
    xorq -129, %r10
    xorq $2147483647, 0(%rdx)
    xorq $305419896, -128(%rbx)
    xorq $1000, -2147483648(%r10)
    xorq $-2147483648, 0(%rsp)
    xorq $2147483647, 127(%r12)
    xorq $305419896, 2147483647(%rsp)
    xorq $1000, 0(%rsi,%r9,1)
    xorq $-2147483648, -1(%rax,%rbp,2)
    xorq $2147483647, 4660(%r9,%r12,4)
    xorq $305419896, gnu_fwd(%rip)
    xorq $1000, 128
    xorq $-128, 0(%r9)
    xorq $127, 64(%rsi)
    xorq $-1, -129(%r11)
    xorq $0, 0(%r12)
    xorq $-128, 8(%rsp)
    xorq $127, -2147483648(%r12)
    xorq $-1, 0(%r15,%rax,8)
    xorq $0, -128(%rsp,%r15,1)
    xorq $-128, 2147483647(%r13,%rsi,2)
    xorq $127, gnu_back(%rip)
    xorq $-1, 4660
    cmpb %spl, 0(%rbx)
    cmpb %r13b, 127(%rdi)
    cmpb %bpl, 128(%r14)
    cmpb %r15b, 0(%rsp)
    cmpb %sil, -1(%r12)
    cmpb %dil, -129(%rsp)
    cmpb %r8b, 0(%rax,%rcx,4)
    cmpb %r12b, 64(%rbp,%r9,8)
    cmpb %spl, -2147483648(%r12,%rbp,1)
    cmpb %r13b, gnu_fwd(%rip)
    cmpb %bpl, 2147483647
    cmpb %cl, %dl
g10:
    cmpb %bl, 0(%rbx)
    cmpb %dh, 8(%rsi)
    cmpb %bh, 4660(%rdi)
    cmpb %ch, 0(%rsp)
    cmpb %ah, -128(%rsp)
    cmpb %cl, 128(%rsp)
    cmpb %dl, 0(%rax,%rax,2)
    cmpb %bl, 127(%rdx,%rcx,4)
    cmpb %dh, -129(%rbx,%rdx,8)
    cmpb %bh, gnu_back(%rip)
    cmpb %ch, -2147483648
    cmpb 0(%r10), %r15b
    cmpb -1(%r15), %sil
    cmpb 2147483647(%rcx), %dil
    cmpb 0(%r12), %r8b
    cmpb 64(%rsp), %r12b
    cmpb 4660(%r12), %spl
    cmpb 0(%r8,%r12,1), %r13b
    cmpb 8(%rdi,%rax,2), %bpl
    cmpb 128(%r15,%r15,4), %r15b
    cmpb gnu_fwd(%rip), %sil
    cmpb -129, %dil
    cmpb 0(%rsi), %ah
    cmpb -128(%rcx), %cl
    cmpb -2147483648(%rdx), %dl
    cmpb 0(%rsp), %bl
    cmpb 127(%rsp), %dh
    cmpb 2147483647(%rsp), %bh
    cmpb 0(%rcx,%rbx,8), %ch
    cmpb -1(%rsp,%rbp,1), %ah
    cmpb 4660(%rbp,%rsi,2), %cl
    cmpb gnu_back(%rip), %dl
    cmpb 128, %bl
    cmpb $-128, 0(%r15)
    cmpb $127, 64(%r8)
    cmpb $255, -129(%r9)
    cmpb $-128, 0(%r12)
    cmpb $127, 8(%r12)
    cmpb $255, -2147483648(%r12)
    cmpb $-128, 0(%r8,%rsi,4)
    cmpb $127, -128(%r8,%rcx,8)
    cmpb $255, 2147483647(%r9,%r9,1)
    cmpb $-128, %dh
    cmpb $127, 0(%rdi)
    cmpb $255, 127(%rbx)
    cmpb $-128, 4660(%rbp)
    cmpb $127, 0(%rsp)
    cmpb $255, -1(%rsp)
    cmpb $-128, 128(%rsp)
    cmpb $127, 0(%rdx,%rdi,2)
    cmpb $255, 64(%rsi,%rax,4)
    cmpb $-128, -129(%rdi,%rcx,8)
    cmpb $127, gnu_fwd(%rip)
    cmpb $255, -2147483648
    cmpw %r11w, 0(%rsi)
    cmpw %r14w, 8(%r8)
    cmpw %r8w, 2147483647(%rbp)
    cmpw %r12w, 0(%rsp)
    cmpw %r13w, -128(%r12)
    cmpw %r15w, 4660(%rsp)
    cmpw %r9w, 0(%rcx,%rbp,1)
    cmpw %r10w, 127(%rax,%r12,2)
    cmpw %r11w, 128(%r9,%rax,4)
    cmpw %r14w, gnu_back(%rip)
    cmpw %r8w, -129
    cmpw %cx, %dx
    cmpw %bx, 0(%rcx)
    cmpw %si, -1(%rsi)
    cmpw %di, -2147483648(%rdi)
    cmpw %bp, 0(%rsp)
    cmpw %sp, 64(%rsp)
    cmpw %cx, 2147483647(%rsp)
    cmpw %dx, 0(%rbx,%rdx,8)
    cmpw %bx, 8(%rax,%rbx,1)
    cmpw %si, 4660(%rcx,%rbp,2)
    cmpw %di, gnu_fwd(%rip)
    cmpw %bp, 128
    cmpw 0(%r11), %r12w
    cmpw -128(%r13), %r13w
    cmpw -129(%rdx), %r15w
    cmpw 0(%r12), %r9w
    cmpw 127(%rsp), %r10w
    cmpw -2147483648(%r12), %r11w
    cmpw 0(%r12,%r15,4), %r14w
    cmpw -1(%rsp,%rsi,8), %r8w
    cmpw 2147483647(%r13,%rcx,1), %r12w
    cmpw gnu_back(%rip), %r13w
    cmpw 4660, %r15w
    cmpw 0(%rdx), %sp
    cmpw 64(%rcx), %cx
    cmpw 128(%rdx), %dx
    cmpw 0(%rsp), %bx
    cmpw 8(%rsp), %si
    cmpw -129(%rsp), %di
    cmpw 0(%rsp,%rsi,2), %bp
    cmpw -128(%rdx,%rdi,4), %sp
    cmpw -2147483648(%rbx,%rax,8), %cx
    cmpw gnu_fwd(%rip), %dx
    cmpw 2147483647, %bx
    cmpw $200, 0(%r8)
    cmpw $-32768, 127(%r10)
    cmpw $32767, 4660(%r11)
    cmpw $4660, 0(%r12)
    cmpw $200, -1(%r12)
    cmpw $-32768, 128(%r12)
    cmpw $32767, 0(%r9,%r9,1)
    cmpw $4660, 64(%r12,%rbp,2)
    cmpw $200, -129(%r13,%r12,4)
    cmpw $-32768, %si
    cmpw $32767, 0(%rbx)
    cmpw $4660, 8(%rbx)
    cmpw $200, -2147483648(%rbp)
    cmpw $-32768, 0(%rsp)
    cmpw $32767, -128(%rsp)
    cmpw $4660, 2147483647(%rsp)
    cmpw $200, 0(%rsi,%rcx,8)
    cmpw $-32768, 127(%rsp,%rdx,1)
    cmpw $32767, 4660(%rbp,%rbx,2)
    cmpw $4660, gnu_back(%rip)
    cmpw $200, 128
    cmpw $0, 0(%r9)
    cmpw $-128, -1(%r13)
    cmpw $127, -129(%r14)
    cmpw $-1, 0(%r12)
    cmpw $0, 64(%r12)
    cmpw $-128, -2147483648(%r12)
    cmpw $127, 0(%r10,%rax,4)
    cmpw $-1, 8(%r15,%r15,8)
    cmpw $0, 2147483647(%r8,%rsi,1)
    cmpw $-128, %di
    cmpw $127, 0(%rsi)
    cmpw $-1, -128(%rsi)
    cmpw $0, 4660(%rdi)
    cmpw $-128, 0(%rsp)
    cmpw $127, 127(%rsp)
    cmpw $-1, 128(%rsp)
    cmpw $0, 0(%rdi,%rbp,2)
    cmpw $-128, -1(%rsi,%rsi,4)
    cmpw $127, -129(%rdi,%rdi,8)
    cmpw $-1, gnu_fwd(%rip)
    cmpw $0, -2147483648
    cmpl %r9d, 0(%rdi)
    cmpl %r10d, 64(%r9)
    cmpl %r11d, 2147483647(%rbx)
    cmpl %r14d, 0(%rsp)
    cmpl %r8d, 8(%r12)
    cmpl %r12d, 4660(%rsp)
    cmpl %r13d, 0(%rdx,%rcx,1)
    cmpl %r15d, -128(%rbp,%r9,2)
    cmpl %r9d, 128(%r12,%rbp,4)
    cmpl %r10d, gnu_back(%rip)
    cmpl %r11d, -129
    cmpl %ebp, %esp
    cmpl %ecx, 0(%rdi)
    cmpl %edx, 127(%rcx)
    cmpl %ebx, -2147483648(%rdx)
    cmpl %esi, 0(%rsp)
    cmpl %edi, -1(%rsp)
    cmpl %ebp, 2147483647(%rsp)
    cmpl %esp, 0(%rax,%rax,8)
    cmpl %ecx, 64(%rax,%rcx,1)
    cmpl %edx, 4660(%rcx,%rdx,2)
    cmpl %ebx, gnu_fwd(%rip)
    cmpl %esi, 128
    cmpl 0(%r14), %r14d
    cmpl 8(%r10), %r8d
    cmpl -129(%rsi), %r12d
    cmpl 0(%r12), %r13d
    cmpl -128(%rsp), %r15d
    cmpl -2147483648(%r12), %r9d
    cmpl 0(%r9,%r12,4), %r10d
    cmpl 127(%rdi,%rax,8), %r11d
    cmpl 2147483647(%r15,%r15,1), %r14d
    cmpl gnu_back(%rip), %r8d
    cmpl 4660, %r12d
    cmpl 0(%rcx), %edi
    cmpl -1(%rbx), %ebp
    cmpl 128(%rbp), %esp
    cmpl 0(%rsp), %ecx
    cmpl 64(%rsp), %edx
    cmpl -129(%rsp), %ebx
    cmpl 0(%rcx,%rbx,2), %esi
    cmpl 8(%rdx,%rbp,4), %edi
    cmpl -2147483648(%rbx,%rsi,8), %ebp
    cmpl gnu_fwd(%rip), %esp
    cmpl 2147483647, %ecx
    cmpl $-2147483648, 0(%r10)
    cmpl $2147483647, -128(%r15)
    cmpl $305419896, 4660(%r8)
    cmpl $1000, 0(%r12)
    cmpl $-2147483648, 127(%r12)
    cmpl $2147483647, 128(%r12)
    cmpl $305419896, 0(%r11,%rsi,1)
    cmpl $1000, -1(%r9,%rcx,2)
    cmpl $-2147483648, -129(%r12,%r9,4)
    cmpl $2147483647, %edx
    cmpl $305419896, 0(%rdx)
    cmpl $1000, 64(%rsi)
    cmpl $-2147483648, -2147483648(%rdi)
    cmpl $2147483647, 0(%rsp)
g11:
    cmpl $305419896, 8(%rsp)
    cmpl $1000, 2147483647(%rsp)
    cmpl $-2147483648, 0(%rdx,%rdi,8)
    cmpl $2147483647, -128(%rsp,%rax,1)
    cmpl $305419896, 4660(%rbp,%rcx,2)
    cmpl $1000, gnu_back(%rip)
    cmpl $-2147483648, 128
    cmpl $-128, 0(%r11)
    cmpl $127, 127(%r9)
    cmpl $-1, -129(%r10)
    cmpl $0, 0(%r12)
    cmpl $-128, -1(%r12)
    cmpl $127, -2147483648(%r12)
    cmpl $-1, 0(%r12,%rbp,4)
    cmpl $0, 64(%r13,%r12,8)
    cmpl $-128, 2147483647(%r15,%rax,1)
    cmpl $127, %ebx
    cmpl $-1, 0(%rbx)
    cmpl $0, 8(%rcx)
    cmpl $-128, 4660(%rdx)
    cmpl $127, 0(%rsp)
    cmpl $-1, -128(%rsp)
    cmpl $0, 128(%rsp)
    cmpl $-128, 0(%rbx,%rdx,2)
    cmpl $127, 127(%rsi,%rbx,4)
    cmpl $-1, -129(%rdi,%rbp,8)
    cmpl $0, gnu_fwd(%rip)
    cmpl $-128, -2147483648
    cmpq %r13, 0(%r15)
    cmpq %r15, -1(%r11)
    cmpq %r9, 2147483647(%rdi)
    cmpq %r10, 0(%rsp)
    cmpq %r11, 64(%r12)
    cmpq %r14, 4660(%rsp)
    cmpq %r8, 0(%rsp,%r15,1)
    cmpq %r12, 8(%rax,%rsi,2)
    cmpq %r13, 128(%r9,%rcx,4)
    cmpq %r15, gnu_back(%rip)
    cmpq %r9, -129
    cmpq 0(%rcx), %r10
    cmpq -128(%r14), %r11
    cmpq -2147483648(%r15), %r14
    cmpq 0(%r12), %r8
    cmpq 127(%rsp), %r12
    cmpq 2147483647(%r12), %r13
    cmpq 0(%r14,%r9,8), %r15
    cmpq -1(%rsp,%rbp,1), %r9
    cmpq 4660(%r13,%r12,2), %r10
    cmpq gnu_fwd(%rip), %r11
    cmpq 128, %r14
    cmpq $2147483647, 0(%r8)
    cmpq $305419896, 64(%rcx)
    cmpq $1000, -129(%r8)
    cmpq $-2147483648, 0(%rsp)
    cmpq $2147483647, 8(%r12)
    cmpq $305419896, -2147483648(%rsp)
    cmpq $1000, 0(%rsi,%rax,4)
    cmpq $-2147483648, -128(%rbp,%r15,8)
    cmpq $2147483647, 2147483647(%r12,%rsi,1)
    cmpq $305419896, gnu_back(%rip)
    cmpq $1000, 4660
    cmpq $127, 0(%rdx)
    cmpq $-1, 127(%rbp)
    cmpq $0, 128(%r13)
    cmpq $-128, 0(%r12)
    cmpq $127, -1(%rsp)
    cmpq $-1, -129(%r12)
    cmpq $0, 0(%r15,%rcx,2)
    cmpq $-128, 64(%rdi,%r9,4)
    cmpq $127, -2147483648(%r15,%rbp,8)
    cmpq $-1, gnu_fwd(%rip)
    cmpq $0, 2147483647
    addb $-128, %al
    addw $-32768, %ax
    addl $-2147483648, %eax
    addq $2147483647, %rax
    orb $127, %al
    orw $32767, %ax
    orl $305419896, %eax
    orq $1000, %rax
    adcb $255, %al
    adcw $4660, %ax
    adcl $-2147483648, %eax
    adcq $2147483647, %rax
    sbbb $-128, %al
    sbbw $200, %ax
    sbbl $305419896, %eax
    sbbq $1000, %rax
    andb $127, %al
    andw $-32768, %ax
    andl $-2147483648, %eax
    andq $2147483647, %rax
    subb $255, %al
    subw $32767, %ax
    subl $305419896, %eax
    subq $1000, %rax
    xorb $-128, %al
    xorw $4660, %ax
    xorl $-2147483648, %eax
    xorq $2147483647, %rax
    cmpb $127, %al
    cmpw $200, %ax
    cmpl $305419896, %eax
    cmpq $1000, %rax
    testb $255, %al
    testw $-32768, %ax
    testl $-2147483648, %eax
    testq $2147483647, %rax
    xchgw %si, %ax
    xchgl %edi, %eax
    xchgq %rcx, %rax
    movb %r8b, 0(%r9)
    movb %r12b, 8(%rdx)
    movb %spl, 4660(%r9)
    movb %r13b, 0(%rsp)
    movb %bpl, -128(%r12)
    movb %r15b, 128(%rsp)
    movb %sil, 0(%rax,%r12,1)
    movb %dil, 127(%rax,%rax,2)
    movb %r8b, -129(%r9,%r15,4)
    movb %r12b, -2147483648
    movb %bh, %ch
    movb %ah, 0(%rsi)
    movb %cl, -1(%rbx)
    movb %dl, 2147483647(%rbp)
    movb %bl, 0(%rsp)
    movb %dh, 64(%rsp)
    movb %bh, 4660(%rsp)
    movb %ch, 0(%rsp,%rsi,8)
    movb %ah, 8(%rax,%rdi,1)
    movb %cl, 128(%rcx,%rax,2)
    movb %dl, gnu_back(%rip)
    movb %bl, -129
    movb 0(%rbx), %spl
    movb -128(%rbx), %r13b
    movb -2147483648(%r10), %bpl
    movb 0(%r12), %r15b
    movb 127(%rsp), %sil
    movb 2147483647(%r12), %dil
    movb 0(%r8,%rsi,4), %r8b
    movb -1(%rsp,%rcx,8), %r12b
    movb 4660(%r13,%r9,1), %spl
    movb 128, %r13b
    movb 0(%rdi), %dh
    movb 64(%rsi), %bh
    movb -129(%rdi), %ch
    movb 0(%rsp), %ah
    movb 8(%rsp), %cl
    movb -2147483648(%rsp), %dl
    movb 0(%rsi,%rcx,2), %bl
    movb -128(%rdx,%rdx,4), %dh
    movb 2147483647(%rbx,%rbx,8), %bh
    movb gnu_fwd(%rip), %ch
    movb 4660, %ah
    movb $-128, 0(%r14)
    movb $127, 127(%r11)
    movb $255, 128(%r13)
    movb $-128, 0(%r12)
    movb $127, -1(%r12)
    movb $255, -129(%r12)
    movb $-128, 0(%r14,%rbp,1)
    movb $127, 64(%r8,%r12,2)
    movb $255, -2147483648(%r9,%rax,4)
    movb $-128, 0(%rcx)
    movb $127, 8(%rcx)
    movb $255, 2147483647(%rdx)
    movb $-128, 0(%rsp)
    movb $127, -128(%rsp)
    movb $255, 4660(%rsp)
    movb $-128, 0(%rdi,%rbp,8)
    movb $127, 127(%rsp,%rsi,1)
    movb $255, 128(%rbp,%rdi,2)
    movb $-128, gnu_back(%rip)
    movb $127, -129
    testb %bpl, 0(%r10)
    testb %r15b, -1(%rsi)
    testb %sil, -2147483648(%r11)
    testb %dil, 0(%rsp)
    testb %r8b, 64(%r12)
    testb %r12b, 2147483647(%rsp)
    testb %spl, 0(%rcx,%r15,4)
    testb %r13b, 8(%rbp,%rsi,8)
    testb %bpl, 4660(%r12,%rcx,1)
    testb %r15b, gnu_fwd(%rip)
    testb %sil, 128
    testb %cl, %dl
    testb %bl, 0(%rdx)
    testb %dh, -128(%rbx)
    testb %bh, -129(%rbp)
    testb %ch, 0(%rsp)
    testb %ah, 127(%rsp)
    testb %cl, -2147483648(%rsp)
    testb %dl, 0(%rax,%rax,2)
    testb %bl, -1(%rsi,%rcx,4)
    testb %dh, 2147483647(%rdi,%rdx,8)
    testb %bh, gnu_back(%rip)
    testb %ch, 4660
    testb $255, 0(%r15)
    testb $-128, 64(%r14)
    testb $127, 128(%r15)
g12:
    testb $255, 0(%r12)
    testb $-128, 8(%r12)
    testb $127, -129(%r12)
    testb $255, 0(%r15,%r9,1)
    testb $-128, -128(%r12,%rbp,2)
    testb $127, -2147483648(%r13,%r12,4)
    testb $255, %ah
    testb $-128, 0(%rbx)
    testb $127, 127(%rsi)
    testb $255, 2147483647(%rdi)
    testb $-128, 0(%rsp)
    testb $127, -1(%rsp)
    testb $255, 4660(%rsp)
    testb $-128, 0(%rcx,%rbx,8)
    testb $127, 64(%rax,%rbp,1)
    testb $255, 128(%rcx,%rsi,2)
    testb $-128, gnu_fwd(%rip)
    testb $127, -129
    xchgb %dil, 0(%rsi)
    xchgb %r8b, 8(%rdi)
    xchgb %r12b, -2147483648(%r14)
    xchgb %spl, 0(%r12)
    xchgb %r13b, -128(%rsp)
    xchgb %bpl, 2147483647(%r12)
    xchgb %r15b, 0(%r12,%rax,4)
    xchgb %sil, 127(%rdi,%r15,8)
    xchgb %dil, 4660(%r15,%rsi,1)
    xchgb %r8b, gnu_back(%rip)
    xchgb %r12b, 128
    xchgb %cl, %dl
    xchgb %bl, 0(%rsi)
    xchgb %dh, -1(%rcx)
    xchgb %bh, -129(%rdx)
    xchgb %ch, 0(%rsp)
    xchgb %ah, 64(%rsp)
    xchgb %cl, -2147483648(%rsp)
    xchgb %dl, 0(%rdx,%rdi,2)
    xchgb %bl, 8(%rdx,%rax,4)
    xchgb %dh, 2147483647(%rbx,%rcx,8)
    xchgb %bh, gnu_fwd(%rip)
    xchgb %ch, 4660
    movw %r8w, 0(%r11)
    movw %r12w, -128(%r15)
    movw %r13w, 128(%rcx)
    movw %r15w, 0(%rsp)
    movw %r9w, 127(%r12)
    movw %r10w, -129(%rsp)
    movw %r11w, 0(%rdx,%rcx,1)
    movw %r14w, -1(%rax,%r9,2)
    movw %r8w, -2147483648(%r9,%rbp,4)
    movw %r12w, 2147483647
    movw %bp, %sp
    movw %cx, 0(%rdi)
    movw %dx, 64(%rbx)
    movw %bx, 4660(%rbp)
    movw %si, 0(%rsp)
    movw %di, 8(%rsp)
    movw %bp, 128(%rsp)
    movw %sp, 0(%rbx,%rdx,8)
    movw %cx, -128(%rsp,%rbx,1)
    movw %dx, -129(%rbp,%rbp,2)
    movw %bx, gnu_back(%rip)
    movw %si, -2147483648
    movw 0(%rdi), %r13w
    movw 127(%r8), %r15w
    movw 2147483647(%rbp), %r9w
    movw 0(%r12), %r10w
    movw -1(%rsp), %r11w
    movw 4660(%r12), %r14w
    movw 0(%r9,%r12,4), %r8w
    movw 64(%rsp,%rax,8), %r12w
    movw 128(%r13,%r15,1), %r13w
    movw -129, %r15w
    movw 0(%rcx), %di
    movw 8(%rsi), %bp
    movw -2147483648(%rdi), %sp
    movw 0(%rsp), %cx
    movw -128(%rsp), %dx
    movw 2147483647(%rsp), %bx
    movw 0(%rsp,%rsi,2), %si
    movw 127(%rsi,%rdi,4), %di
    movw 4660(%rdi,%rax,8), %bp
    movw gnu_fwd(%rip), %sp
    movw 128, %cx
    movw $32767, 0(%r8)
    movw $4660, -1(%r8)
    movw $200, -129(%r9)
    movw $-32768, 0(%r12)
    movw $32767, 64(%r12)
    movw $4660, -2147483648(%r12)
    movw $200, 0(%r8,%rsi,1)
    movw $-32768, 8(%r15,%rcx,2)
    movw $32767, 2147483647(%r8,%r9,4)
    movw $4660, 0(%rdx)
    movw $200, -128(%rcx)
    movw $-32768, 4660(%rdx)
    movw $32767, 0(%rsp)
    movw $4660, 127(%rsp)
    movw $200, 128(%rsp)
    movw $-32768, 0(%rsi,%rcx,8)
    movw $32767, -1(%rax,%rdx,1)
    movw $4660, -129(%rcx,%rbx,2)
    movw $200, gnu_back(%rip)
    movw $-32768, -2147483648
    testw %r9w, 0(%r14)
    testw %r10w, 64(%r13)
    testw %r11w, 2147483647(%rdx)
    testw %r14w, 0(%rsp)
    testw %r8w, 8(%r12)
    testw %r12w, 4660(%rsp)
    testw %r13w, 0(%rsp,%rbp,4)
    testw %r15w, -128(%rbp,%r12,8)
    testw %r9w, 128(%r12,%rax,1)
    testw %r10w, gnu_fwd(%rip)
    testw %r11w, -129
    testw %dx, %bx
    testw %si, 0(%rbx)
    testw %di, 127(%rbx)
    testw %bp, -2147483648(%rbp)
    testw %sp, 0(%rsp)
    testw %cx, -1(%rsp)
    testw %dx, 2147483647(%rsp)
    testw %bx, 0(%rdi,%rbp,2)
    testw %si, 64(%rdx,%rsi,4)
    testw %di, 4660(%rbx,%rdi,8)
    testw %bp, gnu_back(%rip)
    testw %sp, 128
    testw $32767, 0(%r9)
    testw $4660, 8(%r10)
    testw $200, -129(%r11)
    testw $-32768, 0(%r12)
    testw $32767, -128(%r12)
    testw $4660, -2147483648(%r12)
    testw $200, 0(%r9,%r15,1)
    testw $-32768, 127(%r9,%rsi,2)
    testw $32767, 2147483647(%r12,%rcx,4)
    testw $4660, %cx
    testw $200, 0(%rsi)
    testw $-32768, -1(%rsi)
    testw $32767, 4660(%rdi)
    testw $4660, 0(%rsp)
    testw $200, 64(%rsp)
    testw $-32768, 128(%rsp)
    testw $32767, 0(%rax,%rax,8)
    testw $4660, 8(%rsp,%rcx,1)
    testw $200, -129(%rbp,%rdx,2)
    testw $-32768, gnu_fwd(%rip)
    testw $32767, -2147483648
    xchgw %r14w, 0(%r15)
    xchgw %r8w, -128(%r9)
    xchgw %r12w, 2147483647(%rbx)
    xchgw %r13w, 0(%r12)
    xchgw %r15w, 127(%rsp)
    xchgw %r9w, 4660(%r12)
    xchgw %r10w, 0(%r14,%r9,4)
    xchgw %r11w, -1(%rdi,%rbp,8)
    xchgw %r14w, 128(%r15,%r12,1)
    xchgw %r8w, gnu_back(%rip)
    xchgw %r12w, -129
    xchgw %dx, %bx
    xchgw %si, 0(%rdi)
    xchgw %di, 64(%rcx)
    xchgw %bp, -2147483648(%rdx)
    xchgw %sp, 0(%rsp)
    xchgw %cx, 8(%rsp)
    xchgw %dx, 2147483647(%rsp)
    xchgw %bx, 0(%rcx,%rbx,2)
    xchgw %si, -128(%rsi,%rbp,4)
    xchgw %di, 4660(%rdi,%rsi,8)
    xchgw %bp, gnu_fwd(%rip)
    xchgw %sp, 128
    movl %r13d, 0(%rcx)
    movl %r15d, 127(%r10)
    movl %r9d, -129(%rsi)
    movl %r10d, 0(%rsp)
    movl %r11d, -1(%r12)
    movl %r14d, -2147483648(%rsp)
    movl %r8d, 0(%rsi,%rax,1)
    movl %r12d, 64(%rax,%r15,2)
    movl %r13d, 2147483647(%r9,%rsi,4)
    movl %r15d, 4660
    movl %ecx, %edx
    movl %ebx, 0(%rcx)
    movl %esi, 8(%rbx)
    movl %edi, 128(%rbp)
    movl %ebp, 0(%rsp)
    movl %esp, -128(%rsp)
    movl %ecx, -129(%rsp)
    movl %edx, 0(%rdx,%rdi,8)
    movl %ebx, 127(%rax,%rax,1)
    movl %esi, -2147483648(%rcx,%rcx,2)
    movl %edi, gnu_back(%rip)
    movl %ebp, 2147483647
    movl 0(%r8), %r9d
    movl -1(%r11), %r10d
    movl 4660(%rdi), %r11d
    movl 0(%r12), %r14d
    movl 64(%rsp), %r8d
    movl 128(%r12), %r12d
    movl 0(%r15,%rcx,4), %r13d
g13:
    movl 8(%rsp,%r9,8), %r15d
    movl -129(%r13,%rbp,1), %r9d
    movl -2147483648, %r10d
    movl 0(%rdx), %esp
    movl -128(%rsi), %ecx
    movl 2147483647(%rdi), %edx
    movl 0(%rsp), %ebx
    movl 127(%rsp), %esi
    movl 4660(%rsp), %edi
    movl 0(%rbx,%rdx,2), %ebp
    movl -1(%rdx,%rbx,4), %esp
    movl 128(%rbx,%rbp,8), %ecx
    movl gnu_fwd(%rip), %edx
    movl -129, %ebx
    movl $305419896, 0(%r10)
    movl $1000, 64(%r13)
    movl $-2147483648, -2147483648(%r14)
    movl $2147483647, 0(%r12)
    movl $305419896, 8(%r12)
    movl $1000, 2147483647(%r12)
    movl $-2147483648, 0(%r10,%r12,1)
    movl $2147483647, -128(%r13,%rax,2)
    movl $305419896, 4660(%r15,%r15,4)
    movl $1000, 0(%rbx)
    movl $-2147483648, 127(%rcx)
    movl $2147483647, 128(%rdx)
    movl $305419896, 0(%rsp)
    movl $1000, -1(%rsp)
    movl $-2147483648, -129(%rsp)
    movl $2147483647, 0(%rsp,%rsi,8)
    movl $305419896, 64(%rsp,%rdi,1)
    movl $1000, -2147483648(%rbp,%rax,2)
    movl $-2147483648, gnu_back(%rip)
    movl $2147483647, 2147483647
    testl %r11d, 0(%rdx)
    testl %r14d, 8(%r14)
    testl %r8d, 4660(%r15)
    testl %r12d, 0(%rsp)
    testl %r13d, -128(%r12)
    testl %r15d, 128(%rsp)
    testl %r9d, 0(%rax,%rsi,4)
    testl %r10d, 127(%rbp,%rcx,8)
    testl %r11d, -129(%r12,%r9,1)
    testl %r14d, gnu_fwd(%rip)
    testl %r8d, -2147483648
    testl %esi, %edi
    testl %ebp, 0(%rsi)
    testl %esp, -1(%rbx)
    testl %ecx, 2147483647(%rbp)
    testl %edx, 0(%rsp)
    testl %ebx, 64(%rsp)
    testl %esi, 4660(%rsp)
    testl %edi, 0(%rsi,%rcx,2)
    testl %ebp, 8(%rsi,%rdx,4)
    testl %esp, 128(%rdi,%rbx,8)
    testl %ecx, gnu_back(%rip)
    testl %edx, -129
    testl $305419896, 0(%r11)
    testl $1000, -128(%r15)
    testl $-2147483648, -2147483648(%r8)
    testl $2147483647, 0(%r12)
    testl $305419896, 127(%r12)
    testl $1000, 2147483647(%r12)
    testl $-2147483648, 0(%r11,%rbp,1)
    testl $2147483647, -1(%r8,%r12,2)
    testl $305419896, 4660(%r9,%rax,4)
    testl $1000, %ebx
    testl $-2147483648, 0(%rdi)
    testl $2147483647, 64(%rsi)
    testl $305419896, 128(%rdi)
    testl $1000, 0(%rsp)
    testl $-2147483648, 8(%rsp)
    testl $2147483647, -129(%rsp)
    testl $305419896, 0(%rdi,%rbp,8)
    testl $1000, -128(%rax,%rsi,1)
    testl $-2147483648, -2147483648(%rcx,%rdi,2)
    testl $2147483647, gnu_fwd(%rip)
    testl $305419896, 2147483647
    xchgl %r12d, 0(%r9)
    xchgl %r13d, 127(%rcx)
    xchgl %r15d, 4660(%r8)
    xchgl %r9d, 0(%r12)
    xchgl %r10d, -1(%rsp)
    xchgl %r11d, 128(%r12)
    xchgl %r14d, 0(%r8,%r15,4)
    xchgl %r8d, 64(%rdi,%rsi,8)
    xchgl %r12d, -129(%r15,%rcx,1)
    xchgl %r13d, gnu_back(%rip)
    xchgl %r15d, -2147483648
    xchgl %esi, %edi
    xchgl %ebp, 0(%rcx)
    xchgl %esp, 8(%rcx)
    xchgl %ecx, 2147483647(%rdx)
    xchgl %edx, 0(%rsp)
    xchgl %ebx, -128(%rsp)
    xchgl %esi, 4660(%rsp)
    xchgl %edi, 0(%rax,%rax,2)
    xchgl %ebp, 127(%rdx,%rcx,4)
    xchgl %esp, 128(%rbx,%rdx,8)
    xchgl %ecx, gnu_fwd(%rip)
    xchgl %edx, -129
    movq %r9, 0(%rbx)
    movq %r10, -1(%rbp)
    movq %r11, -2147483648(%r13)
    movq %r14, 0(%rsp)
    movq %r8, 64(%r12)
    movq %r12, 2147483647(%rsp)
    movq %r13, 0(%rcx,%r9,1)
    movq %r15, 8(%rax,%rbp,2)
    movq %r9, 4660(%r9,%r12,4)
    movq %r10, 128
    movq 0(%r10), %r11
    movq -128(%rdx), %r14
    movq -129(%r9), %r8
    movq 0(%r12), %r12
    movq 127(%rsp), %r13
    movq -2147483648(%r12), %r15
    movq 0(%r12,%rax,8), %r9
    movq -1(%rsp,%r15,1), %r10
    movq 2147483647(%r13,%rsi,2), %r11
    movq 4660, %r14
    movq $1000, 0(%rsi)
    movq $-2147483648, 64(%rbx)
    movq $2147483647, 128(%r10)
    movq $305419896, 0(%rsp)
    movq $1000, 8(%r12)
    movq $-2147483648, -129(%rsp)
    movq $2147483647, 0(%rdx,%rcx,4)
    movq $305419896, -128(%rbp,%r9,8)
    movq $1000, -2147483648(%r12,%rbp,1)
    movq $-2147483648, gnu_back(%rip)
    movq $2147483647, 2147483647
    testq %r8, 0(%r11)
    testq %r12, 127(%rsi)
    testq %r13, 4660(%r11)
    testq %r15, 0(%r12)
    testq %r9, -1(%rsp)
    testq %r10, 128(%r12)
    testq %r11, 0(%r9,%r12,2)
    testq %r14, 64(%rdi,%rax,4)
    testq %r8, -129(%r15,%r15,8)
    testq %r12, gnu_fwd(%rip)
    testq %r13, -2147483648
    testq $305419896, 0(%rdi)
    testq $1000, 8(%rdi)
    testq $-2147483648, 2147483647(%r14)
    testq $2147483647, 0(%rsp)
    testq $305419896, -128(%r12)
    testq $1000, 4660(%rsp)
    testq $-2147483648, 0(%rsp,%rsi,1)
    testq $2147483647, 127(%rax,%rcx,2)
    testq $305419896, 128(%r9,%r9,4)
    testq $1000, gnu_back(%rip)
    testq $-2147483648, -129
    xchgq %r15, 0(%r14)
    xchgq %r9, -1(%r15)
    xchgq %r10, -2147483648(%rcx)
    xchgq %r11, 0(%r12)
    xchgq %r14, 64(%rsp)
    xchgq %r8, 2147483647(%r12)
    xchgq %r12, 0(%r14,%rbp,8)
    xchgq %r13, 8(%rsp,%r12,1)
    xchgq %r15, 4660(%r13,%rax,2)
    xchgq %r9, gnu_fwd(%rip)
    xchgq %r10, 128
    movb $255, %ah
    movw $4660, %bx
    movl $2147483647, %esi
    leal 0(%r15), %r11d
    leal -128(%r8), %r14d
    leal -129(%rbp), %r8d
    leal 0(%rsp), %r12d
    leal 127(%r12), %r13d
    leal -2147483648(%rsp), %r15d
    leal 0(%rsi,%r15,4), %r9d
    leal -1(%rbp,%rsi,8), %r10d
    leal 2147483647(%r12,%rcx,1), %r11d
    leal 4660, %r14d
    leal 0(%rdx), %edi
    leal 64(%rbx), %ebp
    leal 128(%rbp), %esp
    leal 0(%rsp), %ecx
    leal 8(%rsp), %edx
    leal -129(%rsp), %ebx
    leal 0(%rcx,%rbx,2), %esi
    leal -128(%rsp,%rbp,4), %edi
    leal -2147483648(%rbp,%rsi,8), %ebp
    leal gnu_back(%rip), %esp
    leal 2147483647, %ecx
    leaq 0(%rcx), %r8
    leaq 127(%r13), %r12
    leaq 4660(%rdx), %r13
    leaq 0(%r12), %r15
    leaq -1(%rsp), %r9
    leaq 128(%r12), %r10
    leaq 0(%r15,%r9,1), %r11
    leaq 64(%rdi,%rbp,2), %r14
    leaq -129(%r15,%r12,4), %r8
    leaq -2147483648, %r12
    movzbw 0(%r8), %r13w
g14:
    movzbw 8(%r9), %r15w
    movzbw 2147483647(%rbx), %r9w
    movzbw 0(%rsp), %r10w
    movzbw -128(%r12), %r11w
    movzbw 4660(%rsp), %r14w
    movzbw 0(%rax,%rax,8), %r8w
    movzbw 127(%rax,%r15,1), %r12w
    movzbw 128(%r9,%rsi,2), %r13w
    movzbw gnu_fwd(%rip), %r15w
    movzbw -129, %r9w
    movzbw %cl, %dx
    movzbw 0(%rbx), %bx
    movzbw -1(%rsi), %si
    movzbw -2147483648(%rdi), %di
    movzbw 0(%rsp), %bp
    movzbw 64(%rsp), %sp
    movzbw 2147483647(%rsp), %cx
    movzbw 0(%rdx,%rdi,4), %dx
    movzbw 8(%rsi,%rax,8), %bx
    movzbw 4660(%rdi,%rcx,1), %si
    movzbw gnu_back(%rip), %di
    movzbw 128, %bp
    movzbl 0(%rdx), %r10d
    movzbl -128(%r10), %r11d
    movzbl -129(%rsi), %r14d
    movzbl 0(%r12), %r8d
    movzbl 127(%rsp), %r12d
    movzbl -2147483648(%r12), %r13d
    movzbl 0(%r8,%rcx,2), %r15d
    movzbl -1(%rsp,%r9,4), %r9d
    movzbl 2147483647(%r13,%rbp,8), %r10d
    movzbl gnu_fwd(%rip), %r11d
    movzbl 4660, %r14d
    movzbl %dl, %esp
    movzbl 0(%rsi), %ecx
    movzbl 64(%rcx), %edx
    movzbl 128(%rdx), %ebx
    movzbl 0(%rsp), %esi
    movzbl 8(%rsp), %edi
    movzbl -129(%rsp), %ebp
    movzbl 0(%rbx,%rdx,1), %esp
    movzbl -128(%rax,%rbx,2), %ecx
    movzbl -2147483648(%rcx,%rbp,4), %edx
    movzbl gnu_back(%rip), %ebx
    movzbl 2147483647, %esi
    movzbq 0(%r9), %r8
    movzbq 127(%r11), %r12
    movzbq 4660(%rdi), %r13
    movzbq 0(%rsp), %r15
    movzbq -1(%r12), %r9
    movzbq 128(%rsp), %r10
    movzbq 0(%rcx,%r12,8), %r11
    movzbq 64(%rbp,%rax,1), %r14
    movzbq -129(%r12,%r15,2), %r8
    movzbq gnu_fwd(%rip), %r12
    movzbq -2147483648, %r13
    movzwl 0(%rbx), %r15d
    movzwl 8(%r14), %r9d
    movzwl 2147483647(%r15), %r10d
    movzwl 0(%r12), %r11d
    movzwl -128(%rsp), %r14d
    movzwl 4660(%r12), %r8d
    movzwl 0(%r12,%rsi,4), %r12d
    movzwl 127(%rdi,%rcx,8), %r13d
    movzwl 128(%r15,%r9,1), %r15d
    movzwl gnu_back(%rip), %r9d
    movzwl -129, %r10d
    movzwl %di, %ebp
    movzwl 0(%rdi), %esp
    movzwl -1(%rbx), %ecx
    movzwl -2147483648(%rbp), %edx
    movzwl 0(%rsp), %ebx
    movzwl 64(%rsp), %esi
    movzwl 2147483647(%rsp), %edi
    movzwl 0(%rsp,%rsi,2), %ebp
    movzwl 8(%rdx,%rdi,4), %esp
    movzwl 4660(%rbx,%rax,8), %ecx
    movzwl gnu_fwd(%rip), %edx
    movzwl 128, %ebx
    movzwq 0(%r10), %r11
    movzwq -128(%rcx), %r14
    movzwq -129(%r8), %r8
    movzwq 0(%rsp), %r12
    movzwq 127(%r12), %r13
    movzwq -2147483648(%rsp), %r15
    movzwq 0(%rdx,%rbp,1), %r9
    movzwq -1(%rax,%r12,2), %r10
    movzwq 2147483647(%r9,%rax,4), %r11
    movzwq gnu_back(%rip), %r14
    movzwq 4660, %r8
    movsbw 0(%rsi), %r12w
    movsbw 64(%rbp), %r13w
    movsbw 128(%r13), %r15w
    movsbw 0(%r12), %r9w
    movsbw 8(%rsp), %r10w
    movsbw -129(%r12), %r11w
    movsbw 0(%r9,%r15,8), %r14w
    movsbw -128(%rsp,%rsi,1), %r8w
    movsbw -2147483648(%r13,%rcx,2), %r12w
    movsbw gnu_fwd(%rip), %r13w
    movsbw 2147483647, %r15w
    movsbw %bl, %si
    movsbw 0(%rcx), %di
    movsbw 127(%rsi), %bp
    movsbw 4660(%rdi), %sp
    movsbw 0(%rsp), %cx
    movsbw -1(%rsp), %dx
    movsbw 128(%rsp), %bx
    movsbw 0(%rsi,%rcx,4), %si
    movsbw 64(%rsp,%rdx,8), %di
    movsbw -129(%rbp,%rbx,1), %bp
    movsbw gnu_back(%rip), %sp
    movsbw -2147483648, %cx
    movsbl 0(%r11), %r9d
    movsbl 8(%rdx), %r10d
    movsbl 2147483647(%r9), %r11d
    movsbl 0(%rsp), %r14d
    movsbl -128(%r12), %r8d
    movsbl 4660(%rsp), %r12d
    movsbl 0(%rsp,%r9,2), %r13d
    movsbl 127(%rbp,%rbp,4), %r15d
    movsbl 128(%r12,%r12,8), %r9d
    movsbl gnu_fwd(%rip), %r10d
    movsbl -129, %r11d
    movsbl %dh, %edx
    movsbl 0(%rdx), %ebx
    movsbl -1(%rcx), %esi
    movsbl -2147483648(%rdx), %edi
    movsbl 0(%rsp), %ebp
    movsbl 64(%rsp), %esp
    movsbl 2147483647(%rsp), %ecx
    movsbl 0(%rdi,%rbp,1), %edx
    movsbl 8(%rsi,%rsi,2), %ebx
    movsbl 4660(%rdi,%rdi,4), %esi
    movsbl gnu_back(%rip), %edi
    movsbl 128, %ebp
    movsbq 0(%rdi), %r14
    movsbq -128(%rbx), %r8
    movsbq -129(%r10), %r12
    movsbq 0(%r12), %r13
    movsbq 127(%rsp), %r15
    movsbq -2147483648(%r12), %r9
    movsbq 0(%r14,%rax,8), %r10
    movsbq -1(%rdi,%r15,1), %r11
    movsbq 2147483647(%r15,%rsi,2), %r14
    movsbq gnu_fwd(%rip), %r8
    movsbq 4660, %r12
    movswl 0(%r14), %r13d
    movswl 64(%rsi), %r15d
    movswl 128(%r11), %r9d
    movswl 0(%rsp), %r10d
    movswl 8(%r12), %r11d
    movswl -129(%rsp), %r14d
    movswl 0(%rsi,%rcx,4), %r8d
    movswl -128(%rax,%r9,8), %r12d
    movswl -2147483648(%r9,%rbp,1), %r13d
    movswl gnu_back(%rip), %r15d
    movswl 2147483647, %r9d
    movswl %sp, %ecx
    movswl 0(%rbx), %edx
    movswl 127(%rbx), %ebx
    movswl 4660(%rbp), %esi
    movswl 0(%rsp), %edi
    movswl -1(%rsp), %ebp
    movswl 128(%rsp), %esp
    movswl 0(%rax,%rax,2), %ecx
    movswl 64(%rax,%rcx,4), %edx
    movswl -129(%rcx,%rdx,8), %ebx
    movswl gnu_fwd(%rip), %esi
    movswl -2147483648, %edi
    movswq 0(%r15), %r10
    movswq 8(%rdi), %r11
    movswq 2147483647(%r14), %r14
    movswq 0(%r12), %r8
    movswq -128(%rsp), %r12
    movswq 4660(%r12), %r13
    movswq 0(%r15,%r12,1), %r15
    movswq 127(%rsp,%rax,2), %r9
    movswq 128(%r13,%r15,4), %r10
    movswq gnu_back(%rip), %r11
    movswq -129, %r14
    movslq 0(%rcx), %r8
    movslq -1(%r15), %r12
    movslq -2147483648(%rcx), %r13
    movslq 0(%rsp), %r15
    movslq 64(%r12), %r9
    movslq 2147483647(%rsp), %r10
    movslq 0(%rax,%rsi,8), %r11
    movslq 8(%rbp,%rcx,1), %r14
    movslq 4660(%r12,%r9,2), %r8
    movslq gnu_fwd(%rip), %r12
    movslq 128, %r13
    incb 0(%r14)
    incb -128(%r9)
    incb -129(%r10)
    incb 0(%r12)
    incb 127(%r12)
    incb -2147483648(%r12)
    incb 0(%r12,%rbp,4)
    incb -1(%r12,%r12,8)
g15:
    incb 2147483647(%r13,%rax,1)
    incb %bh
    incb 0(%rsi)
    incb 64(%rsi)
    incb 4660(%rdi)
    incb 0(%rsp)
    incb 8(%rsp)
    incb 128(%rsp)
    incb 0(%rcx,%rbx,2)
    incb -128(%rdx,%rbp,4)
    incb -129(%rbx,%rsi,8)
    incb gnu_back(%rip)
    incb -2147483648
    incw 0(%r15)
    incw 127(%r11)
    incw 2147483647(%r13)
    incw 0(%r12)
    incw -1(%r12)
    incw 4660(%r12)
    incw 0(%r14,%r15,1)
    incw 64(%r15,%rsi,2)
    incw 128(%r8,%rcx,4)
    incw %bp
    incw 0(%rdi)
    incw 8(%rcx)
    incw -129(%rdx)
    incw 0(%rsp)
    incw -128(%rsp)
    incw -2147483648(%rsp)
    incw 0(%rdx,%rdi,8)
    incw 127(%rsp,%rax,1)
    incw 2147483647(%rbp,%rcx,2)
    incw gnu_fwd(%rip)
    incw 4660
    incl 0(%r8)
    incl -1(%r14)
    incl 128(%r15)
    incl 0(%r12)
    incl 64(%r12)
    incl -129(%r12)
    incl 0(%r15,%r9,4)
    incl 8(%r9,%rbp,8)
    incl -2147483648(%r12,%r12,1)
    incl %esp
    incl 0(%rcx)
    incl -128(%rbx)
    incl 2147483647(%rbp)
    incl 0(%rsp)
    incl 127(%rsp)
    incl 4660(%rsp)
    incl 0(%rbx,%rdx,2)
    incl -1(%rsi,%rbx,4)
    incl 128(%rdi,%rbp,8)
    incl gnu_back(%rip)
    incl -129
    incq 0(%r8)
    incq 64(%r8)
    incq -2147483648(%rbp)
    incq 0(%r12)
    incq 8(%rsp)
    incq 2147483647(%r12)
    incq 0(%r8,%rax,1)
    incq -128(%rdi,%r15,2)
    incq 4660(%r15,%rsi,4)
    incq gnu_fwd(%rip)
    incq 128
    decb 0(%r9)
    decb 127(%r8)
    decb -129(%r9)
    decb 0(%r12)
    decb -1(%r12)
    decb -2147483648(%r12)
    decb 0(%r8,%rcx,8)
    decb 64(%r13,%r9,1)
    decb 2147483647(%r15,%rbp,2)
    decb %ch
    decb 0(%rdx)
    decb 8(%rsi)
    decb 4660(%rdi)
    decb 0(%rsp)
    decb -128(%rsp)
    decb 128(%rsp)
    decb 0(%rsp,%rsi,4)
    decb 127(%rax,%rdi,8)
    decb -129(%rcx,%rax,1)
    decb gnu_back(%rip)
    decb -2147483648
    decw 0(%r10)
    decw -1(%r10)
    decw 2147483647(%r11)
    decw 0(%r12)
    decw 64(%r12)
    decw 4660(%r12)
    decw 0(%r9,%r12,2)
    decw 8(%r8,%rax,4)
    decw 128(%r9,%r15,8)
    decw %cx
    decw 0(%rbx)
    decw -128(%rcx)
    decw -129(%rdx)
    decw 0(%rsp)
    decw 127(%rsp)
    decw -2147483648(%rsp)
    decw 0(%rsi,%rcx,1)
    decw -1(%rdx,%rdx,2)
    decw 2147483647(%rbx,%rbx,4)
    decw gnu_fwd(%rip)
    decw 4660
    decl 0(%r11)
    decl 64(%r13)
    decl 128(%r14)
    decl 0(%r12)
    decl 8(%r12)
    decl -129(%r12)
    decl 0(%r10,%rsi,8)
    decl -128(%r12,%rcx,1)
    decl -2147483648(%r13,%r9,2)
    decl %edx
    decl 0(%rsi)
    decl 127(%rbx)
    decl 2147483647(%rbp)
    decl 0(%rsp)
    decl -1(%rsp)
    decl 4660(%rsp)
    decl 0(%rdi,%rbp,4)
    decl 64(%rsp,%rsi,8)
    decl 128(%rbp,%rdi,1)
    decl gnu_back(%rip)
    decl -129
    decq 0(%rdx)
    decq 8(%r13)
    decq -2147483648(%rdx)
    decq 0(%rsp)
    decq -128(%r12)
    decq 2147483647(%rsp)
    decq 0(%rcx,%rbp,2)
    decq 127(%rax,%r12,4)
    decq 4660(%r9,%rax,8)
    decq gnu_fwd(%rip)
    decq 128
    notb 0(%r14)
    notb -1(%r15)
    notb -129(%r8)
    notb 0(%r12)
    notb 64(%r12)
    notb -2147483648(%r12)
    notb 0(%r11,%r15,1)
    notb 8(%r15,%rsi,2)
    notb 2147483647(%r8,%rcx,4)
    notb %ah
    notb 0(%rdi)
    notb -128(%rsi)
    notb 4660(%rdi)
    notb 0(%rsp)
    notb 127(%rsp)
    notb 128(%rsp)
    notb 0(%rax,%rax,8)
    notb -1(%rsi,%rcx,1)
    notb -129(%rdi,%rdx,2)
    notb gnu_back(%rip)
    notb -2147483648
    notw 0(%r15)
    notw 64(%r9)
    notw 2147483647(%r10)
    notw 0(%r12)
    notw 8(%r12)
    notw 4660(%r12)
    notw 0(%r12,%r9,4)
    notw -128(%r9,%rbp,8)
    notw 128(%r12,%r12,1)
    notw %bx
    notw 0(%rcx)
    notw 127(%rcx)
    notw -129(%rdx)
    notw 0(%rsp)
    notw -1(%rsp)
    notw -2147483648(%rsp)
    notw 0(%rcx,%rbx,2)
    notw 64(%rax,%rbp,4)
    notw 2147483647(%rcx,%rsi,8)
    notw gnu_fwd(%rip)
    notw 4660
    notl 0(%r8)
    notl 8(%r11)
    notl 128(%r13)
    notl 0(%r12)
    notl -128(%r12)
    notl -129(%r12)
    notl 0(%r14,%rax,1)
    notl 127(%r13,%r15,2)
    notl -2147483648(%r15,%rsi,4)
    notl %esi
    notl 0(%rdx)
    notl -1(%rbx)
    notl 2147483647(%rbp)
    notl 0(%rsp)
    notl 64(%rsp)
    notl 4660(%rsp)
    notl 0(%rdx,%rdi,8)
    notl 8(%rdx,%rax,1)
g16:
    notl 128(%rbx,%rcx,2)
    notl gnu_back(%rip)
    notl -129
    notq 0(%r9)
    notq -128(%r9)
    notq -2147483648(%rbx)
    notq 0(%r12)
    notq 127(%rsp)
    notq 2147483647(%r12)
    notq 0(%r12,%rcx,4)
    notq -1(%rsp,%r9,8)
    notq 4660(%r13,%rbp,1)
    notq gnu_fwd(%rip)
    notq 128
    negb 0(%r9)
    negb 64(%r14)
    negb -129(%r15)
    negb 0(%r12)
    negb 8(%r12)
    negb -2147483648(%r12)
    negb 0(%r15,%r12,2)
    negb -128(%r8,%rax,4)
    negb 2147483647(%r9,%r15,8)
    negb %cl
    negb 0(%rbx)
    negb 127(%rsi)
    negb 4660(%rdi)
    negb 0(%rsp)
    negb -1(%rsp)
    negb 128(%rsp)
    negb 0(%rbx,%rdx,1)
    negb 64(%rsp,%rbx,2)
    negb -129(%rbp,%rbp,4)
    negb gnu_back(%rip)
    negb -2147483648
    negw 0(%r10)
    negw 8(%r8)
    negw 2147483647(%r9)
    negw 0(%r12)
    negw -128(%r12)
    negw 4660(%r12)
    negw 0(%r8,%rsi,8)
    negw 127(%r12,%rcx,1)
    negw 128(%r13,%r9,2)
    negw %di
    negw 0(%rsi)
    negw -1(%rcx)
    negw -129(%rdx)
    negw 0(%rsp)
    negw 64(%rsp)
    negw -2147483648(%rsp)
    negw 0(%rsp,%rsi,4)
    negw 8(%rsi,%rdi,8)
    negw 2147483647(%rdi,%rax,1)
    negw gnu_fwd(%rip)
    negw 4660
    negl 0(%r11)
    negl -128(%r10)
    negl 128(%r11)
    negl 0(%r12)
    negl 127(%r12)
    negl -129(%r12)
    negl 0(%r9,%rbp,2)
    negl -1(%r15,%r12,4)
    negl -2147483648(%r8,%rax,8)
    negl %ebp
    negl 0(%rdi)
    negl 64(%rbx)
    negl 2147483647(%rbp)
    negl 0(%rsp)
    negl 8(%rsp)
    negl 4660(%rsp)
    negl 0(%rsi,%rcx,1)
    negl -128(%rax,%rdx,2)
    negl 128(%rcx,%rbx,4)
    negl gnu_back(%rip)
    negl -129
    negq 0(%rbx)
    negq 127(%r10)
    negq -2147483648(%rsi)
    negq 0(%rsp)
    negq -1(%r12)
    negq 2147483647(%rsp)
    negq 0(%rdx,%r15,8)
    negq 64(%rbp,%rsi,1)
    negq 4660(%r12,%rcx,2)
    negq gnu_fwd(%rip)
    negq 128
    mulb 0(%r14)
    mulb 8(%r13)
    mulb -129(%r14)
    mulb 0(%r12)
    mulb -128(%r12)
    mulb -2147483648(%r12)
    mulb 0(%r10,%r9,4)
    mulb 127(%r9,%rbp,8)
    mulb 2147483647(%r12,%r12,1)
    mulb %dl
    mulb 0(%rcx)
    mulb -1(%rsi)
    mulb 4660(%rdi)
    mulb 0(%rsp)
    mulb 64(%rsp)
    mulb 128(%rsp)
    mulb 0(%rdi,%rbp,2)
    mulb 8(%rdx,%rsi,4)
    mulb -129(%rbx,%rdi,8)
    mulb gnu_back(%rip)
    mulb -2147483648
    mulw 0(%r15)
    mulw -128(%r15)
    mulw 2147483647(%r8)
    mulw 0(%r12)
    mulw 127(%r12)
    mulw 4660(%r12)
    mulw 0(%r11,%rax,1)
    mulw -1(%r13,%r15,2)
    mulw 128(%r15,%rsi,4)
    mulw %sp
    mulw 0(%rdx)
    mulw 64(%rcx)
    mulw -129(%rdx)
    mulw 0(%rsp)
    mulw 8(%rsp)
    mulw -2147483648(%rsp)
    mulw 0(%rax,%rax,8)
    mulw -128(%rsp,%rcx,1)
    mulw 2147483647(%rbp,%rdx,2)
    mulw gnu_fwd(%rip)
    mulw 4660
    mull 0(%r8)
    mull 127(%r9)
    mull 128(%r10)
    mull 0(%r12)
    mull -1(%r12)
    mull -129(%r12)
    mull 0(%r12,%rcx,4)
    mull 64(%r8,%r9,8)
    mull -2147483648(%r9,%rbp,1)
    mull %ecx
    mull 0(%rbx)
    mull 8(%rbx)
    mull 2147483647(%rbp)
    mull 0(%rsp)
    mull -128(%rsp)
    mull 4660(%rsp)
    mull 0(%rcx,%rbx,2)
    mull 127(%rsi,%rbp,4)
    mull 128(%rdi,%rsi,8)
    mull gnu_back(%rip)
    mull -129
    mulq 0(%r10)
    mulq -1(%r11)
    mulq -2147483648(%rdi)
    mulq 0(%r12)
    mulq 64(%rsp)
    mulq 2147483647(%r12)
    mulq 0(%r9,%r12,1)
    mulq 8(%rdi,%rax,2)
    mulq 4660(%r15,%r15,4)
    mulq gnu_fwd(%rip)
    mulq 128
    imulb 0(%r9)
    imulb -128(%r11)
    imulb -129(%r13)
    imulb 0(%r12)
    imulb 127(%r12)
    imulb -2147483648(%r12)
    imulb 0(%r14,%rsi,8)
    imulb -1(%r12,%rcx,1)
    imulb 2147483647(%r13,%r9,2)
    imulb %bl
    imulb 0(%rsi)
    imulb 64(%rsi)
    imulb 4660(%rdi)
    imulb 0(%rsp)
    imulb 8(%rsp)
    imulb 128(%rsp)
    imulb 0(%rdx,%rdi,4)
    imulb -128(%rax,%rax,8)
    imulb -129(%rcx,%rcx,1)
    imulb gnu_back(%rip)
    imulb -2147483648
    imulw 0(%r10)
    imulw 127(%r14)
    imulw 2147483647(%r15)
    imulw 0(%r12)
    imulw -1(%r12)
    imulw 4660(%r12)
    imulw 0(%r15,%rbp,2)
    imulw 64(%r15,%r12,4)
    imulw 128(%r8,%rax,8)
    imulw %dx
    imulw 0(%rdi)
    imulw 8(%rcx)
    imulw -129(%rdx)
    imulw 0(%rsp)
    imulw -128(%rsp)
    imulw -2147483648(%rsp)
    imulw 0(%rbx,%rdx,1)
g17:
    imulw 127(%rdx,%rbx,2)
    imulw 2147483647(%rbx,%rbp,4)
    imulw gnu_fwd(%rip)
    imulw 4660
    imull 0(%r11)
    imull -1(%r8)
    imull 128(%r9)
    imull 0(%r12)
    imull 64(%r12)
    imull -129(%r12)
    imull 0(%r8,%r15,8)
    imull 8(%r9,%rsi,1)
    imull -2147483648(%r12,%rcx,2)
    imull %ebx
    imull 0(%rcx)
    imull -128(%rbx)
    imull 2147483647(%rbp)
    imull 0(%rsp)
    imull 127(%rsp)
    imull 4660(%rsp)
    imull 0(%rsp,%rsi,4)
    imull -1(%rsp,%rdi,8)
    imull 128(%rbp,%rax,1)
    imull gnu_back(%rip)
    imull -129
    imulq 0(%rsi)
    imulq 64(%r14)
    imulq -2147483648(%r15)
    imulq 0(%rsp)
    imulq 8(%r12)
    imulq 2147483647(%rsp)
    imulq 0(%rsp,%r9,2)
    imulq -128(%rax,%rbp,4)
    imulq 4660(%r9,%r12,8)
    imulq gnu_fwd(%rip)
    imulq 128
    divb 0(%r14)
    divb 127(%r10)
    divb -129(%r11)
    divb 0(%r12)
    divb -1(%r12)
    divb -2147483648(%r12)
    divb 0(%r9,%rax,1)
    divb 64(%r13,%r15,2)
    divb 2147483647(%r15,%rsi,4)
    divb %dh
    divb 0(%rdx)
    divb 8(%rsi)
    divb 4660(%rdi)
    divb 0(%rsp)
    divb -128(%rsp)
    divb 128(%rsp)
    divb 0(%rsi,%rcx,8)
    divb 127(%rsi,%rdx,1)
    divb -129(%rdi,%rbx,2)
    divb gnu_back(%rip)
    divb -2147483648
    divw 0(%r15)
    divw -1(%r13)
    divw 2147483647(%r14)
    divw 0(%r12)
    divw 64(%r12)
    divw 4660(%r12)
    divw 0(%r10,%rcx,4)
    divw 8(%r8,%r9,8)
    divw 128(%r9,%rbp,1)
    divw %si
    divw 0(%rbx)
    divw -128(%rcx)
    divw -129(%rdx)
    divw 0(%rsp)
    divw 127(%rsp)
    divw -2147483648(%rsp)
    divw 0(%rdi,%rbp,2)
    divw -1(%rax,%rsi,4)
    divw 2147483647(%rcx,%rdi,8)
    divw gnu_fwd(%rip)
    divw 4660
    divl 0(%r8)
    divl 64(%r15)
    divl 128(%r8)
    divl 0(%r12)
    divl 8(%r12)
    divl -129(%r12)
    divl 0(%r11,%r12,1)
    divl -128(%r12,%rax,2)
    divl -2147483648(%r13,%r15,4)
    divl %edi
    divl 0(%rsi)
    divl 127(%rbx)
    divl 2147483647(%rbp)
    divl 0(%rsp)
    divl -1(%rsp)
    divl 4660(%rsp)
    divl 0(%rax,%rax,8)
    divl 64(%rdx,%rcx,1)
    divl 128(%rbx,%rdx,2)
    divl gnu_back(%rip)
    divl -129
    divq 0(%r11)
    divq 8(%rcx)
    divq -2147483648(%r8)
    divq 0(%r12)
    divq -128(%rsp)
    divq 2147483647(%r12)
    divq 0(%r14,%rsi,4)
    divq 127(%rsp,%rcx,8)
    divq 4660(%r13,%r9,1)
    divq gnu_fwd(%rip)
    divq 128
    idivb 0(%r9)
    idivb -1(%r9)
    idivb -129(%r10)
    idivb 0(%r12)
    idivb 64(%r12)
    idivb -2147483648(%r12)
    idivb 0(%r12,%rbp,2)
    idivb 8(%r15,%r12,4)
    idivb 2147483647(%r8,%rax,8)
    idivb %bh
    idivb 0(%rdi)
    idivb -128(%rsi)
    idivb 4660(%rdi)
    idivb 0(%rsp)
    idivb 127(%rsp)
    idivb 128(%rsp)
    idivb 0(%rcx,%rbx,1)
    idivb -1(%rsp,%rbp,2)
    idivb -129(%rbp,%rsi,4)
    idivb gnu_back(%rip)
    idivb -2147483648
    idivw 0(%r10)
    idivw 64(%r11)
    idivw 2147483647(%r13)
    idivw 0(%r12)
    idivw 8(%r12)
    idivw 4660(%r12)
    idivw 0(%r14,%r15,8)
    idivw -128(%r9,%rsi,1)
    idivw 128(%r12,%rcx,2)
    idivw %bp
    idivw 0(%rcx)
    idivw 127(%rcx)
    idivw -129(%rdx)
    idivw 0(%rsp)
    idivw -1(%rsp)
    idivw -2147483648(%rsp)
    idivw 0(%rdx,%rdi,4)
    idivw 64(%rsi,%rax,8)
    idivw 2147483647(%rdi,%rcx,1)
    idivw gnu_fwd(%rip)
    idivw 4660
    idivl 0(%r11)
    idivl 8(%r14)
    idivl 128(%r15)
    idivl 0(%r12)
    idivl -128(%r12)
    idivl -129(%r12)
    idivl 0(%r15,%r9,2)
    idivl 127(%r13,%rbp,4)
    idivl -2147483648(%r15,%r12,8)
    idivl %esp
    idivl 0(%rdx)
    idivl -1(%rbx)
    idivl 2147483647(%rbp)
    idivl 0(%rsp)
    idivl 64(%rsp)
    idivl 4660(%rsp)
    idivl 0(%rbx,%rdx,1)
    idivl 8(%rax,%rbx,2)
    idivl 128(%rcx,%rbp,4)
    idivl gnu_back(%rip)
    idivl -129
    idivq 0(%rdi)
    idivq -128(%rbp)
    idivq -2147483648(%r13)
    idivq 0(%rsp)
    idivq 127(%r12)
    idivq 2147483647(%rsp)
    idivq 0(%rsi,%rax,8)
    idivq -1(%rbp,%r15,1)
    idivq 4660(%r12,%rsi,2)
    idivq gnu_fwd(%rip)
    idivq 128
    imulw 0(%r14), %r15w
    imulw 64(%rdx), %r9w
    imulw -129(%r9), %r10w
    imulw 0(%r12), %r11w
    imulw 8(%rsp), %r14w
    imulw -2147483648(%r12), %r8w
    imulw 0(%r15,%rcx,4), %r12w
    imulw -128(%rdi,%r9,8), %r13w
    imulw 2147483647(%r15,%rbp,1), %r15w
    imulw gnu_back(%rip), %r9w
    imulw 4660, %r10w
    imulw %cx, %dx
    imulw 0(%rbx), %bx
    imulw 127(%rsi), %si
    imulw 128(%rdi), %di
    imulw 0(%rsp), %bp
g18:
    imulw -1(%rsp), %sp
    imulw -129(%rsp), %cx
    imulw 0(%rsp,%rsi,2), %dx
    imulw 64(%rdx,%rdi,4), %bx
    imulw -2147483648(%rbx,%rax,8), %si
    imulw gnu_fwd(%rip), %di
    imulw 2147483647, %bp
    imulw $200, 0(%r15), %r11w
    imulw $-32768, 8(%rbx), %r14w
    imulw $32767, 4660(%r10), %r8w
    imulw $4660, 0(%rsp), %r12w
    imulw $200, -128(%r12), %r13w
    imulw $-32768, 128(%rsp), %r15w
    imulw $32767, 0(%rax,%r12,1), %r9w
    imulw $4660, 127(%rax,%rax,2), %r10w
    imulw $200, -129(%r9,%r15,4), %r11w
    imulw $-32768, gnu_back(%rip), %r14w
    imulw $32767, -2147483648, %r8w
    imulw $4660, %sp, %cx
    imulw $200, 0(%rsi), %dx
    imulw $-32768, -1(%rcx), %bx
    imulw $32767, 2147483647(%rdx), %si
    imulw $4660, 0(%rsp), %di
    imulw $200, 64(%rsp), %bp
    imulw $-32768, 4660(%rsp), %sp
    imulw $32767, 0(%rsi,%rcx,8), %cx
    imulw $4660, 8(%rsp,%rdx,1), %dx
    imulw $200, 128(%rbp,%rbx,2), %bx
    imulw $-32768, gnu_fwd(%rip), %si
    imulw $32767, -129, %di
    imulw $-128, 0(%rcx), %r12w
    imulw $127, -128(%rsi), %r13w
    imulw $-1, -2147483648(%r11), %r15w
    imulw $0, 0(%r12), %r9w
    imulw $-128, 127(%rsp), %r10w
    imulw $127, 2147483647(%r12), %r11w
    imulw $-1, 0(%r8,%rsi,4), %r14w
    imulw $0, -1(%rsp,%rcx,8), %r8w
    imulw $-128, 4660(%r13,%r9,1), %r12w
    imulw $127, gnu_back(%rip), %r13w
    imulw $-1, 128, %r15w
    imulw $0, %bp, %sp
    imulw $-128, 0(%rdi), %cx
    imulw $127, 64(%rbx), %dx
    imulw $-1, -129(%rbp), %bx
    imulw $0, 0(%rsp), %si
    imulw $-128, 8(%rsp), %di
    imulw $127, -2147483648(%rsp), %bp
    imulw $-1, 0(%rdi,%rbp,2), %sp
    imulw $0, -128(%rsi,%rsi,4), %cx
    imulw $-128, 2147483647(%rdi,%rdi,8), %dx
    imulw $127, gnu_fwd(%rip), %bx
    imulw $-1, 4660, %si
    imull 0(%r8), %r9d
    imull 127(%rdi), %r10d
    imull 128(%r14), %r11d
    imull 0(%rsp), %r14d
    imull -1(%r12), %r8d
    imull -129(%rsp), %r12d
    imull 0(%rcx,%rbp,1), %r13d
    imull 64(%rbp,%r12,2), %r15d
    imull -2147483648(%r12,%rax,4), %r9d
    imull gnu_back(%rip), %r10d
    imull 2147483647, %r11d
    imull %edi, %ebp
    imull 0(%rcx), %esp
    imull 8(%rsi), %ecx
    imull 4660(%rdi), %edx
    imull 0(%rsp), %ebx
    imull -128(%rsp), %esi
    imull 128(%rsp), %edi
    imull 0(%rax,%rax,8), %ebp
    imull 127(%rax,%rcx,1), %esp
    imull -129(%rcx,%rdx,2), %ecx
    imull gnu_fwd(%rip), %edx
    imull -2147483648, %ebx
    imull $305419896, 0(%rdx), %r14d
    imull $1000, -1(%r15), %r8d
    imull $-2147483648, 2147483647(%rcx), %r12d
    imull $2147483647, 0(%r12), %r13d
    imull $305419896, 64(%rsp), %r15d
    imull $1000, 4660(%r12), %r9d
    imull $-2147483648, 0(%r12,%r15,4), %r10d
    imull $2147483647, 8(%rdi,%rsi,8), %r11d
    imull $305419896, 128(%r15,%rcx,1), %r14d
    imull $1000, gnu_back(%rip), %r8d
    imull $-2147483648, -129, %r12d
    imull $2147483647, %esi, %edi
    imull $305419896, 0(%rdx), %ebp
    imull $1000, -128(%rcx), %esp
    imull $-2147483648, -2147483648(%rdx), %ecx
    imull $2147483647, 0(%rsp), %edx
    imull $305419896, 127(%rsp), %ebx
    imull $1000, 2147483647(%rsp), %esi
    imull $-2147483648, 0(%rcx,%rbx,2), %edi
    imull $2147483647, -1(%rdx,%rbp,4), %ebp
    imull $305419896, 4660(%rbx,%rsi,8), %esp
    imull $1000, gnu_fwd(%rip), %ecx
    imull $-2147483648, 128, %edx
    imull $0, 0(%r9), %r13d
    imull $-128, 64(%r8), %r15d
    imull $127, -129(%rbp), %r9d
    imull $-1, 0(%rsp), %r10d
    imull $0, 8(%r12), %r11d
    imull $-128, -2147483648(%rsp), %r14d
    imull $127, 0(%rdx,%r9,1), %r8d
    imull $-1, -128(%rax,%rbp,2), %r12d
    imull $0, 2147483647(%r9,%r12,4), %r13d
    imull $-128, gnu_back(%rip), %r15d
    imull $127, 4660, %r9d
    imull $-1, %ebx, %esi
    imull $0, 0(%rbx), %edi
    imull $-128, 127(%rbx), %ebp
    imull $127, 128(%rbp), %esp
    imull $-1, 0(%rsp), %ecx
    imull $0, -1(%rsp), %edx
    imull $-128, -129(%rsp), %ebx
    imull $127, 0(%rdx,%rdi,8), %esi
    imull $-1, 64(%rsp,%rax,1), %edi
    imull $0, -2147483648(%rbp,%rcx,2), %ebp
    imull $-128, gnu_fwd(%rip), %esp
    imull $127, 2147483647, %ecx
    imulq 0(%rbx), %r10
    imulq 8(%r13), %r11
    imulq 4660(%rdx), %r14
    imulq 0(%r12), %r8
    imulq -128(%rsp), %r12
    imulq 128(%r12), %r13
    imulq 0(%r9,%rax,4), %r15
    imulq 127(%rsp,%r15,8), %r9
    imulq -129(%r13,%rsi,1), %r10
    imulq gnu_back(%rip), %r11
    imulq -2147483648, %r14
    imulq $2147483647, 0(%r10), %r8
    imulq $305419896, -1(%r9), %r12
    imulq $1000, 2147483647(%rbx), %r13
    imulq $-2147483648, 0(%rsp), %r15
    imulq $2147483647, 64(%r12), %r9
    imulq $305419896, 4660(%rsp), %r10
    imulq $1000, 0(%rsp,%rcx,2), %r11
    imulq $-2147483648, 8(%rbp,%r9,4), %r14
    imulq $2147483647, 128(%r12,%rbp,8), %r8
    imulq $305419896, gnu_fwd(%rip), %r12
    imulq $1000, -129, %r13
    imulq $-1, 0(%rsi), %r15
    imulq $0, -128(%r10), %r9
    imulq $-128, -2147483648(%rsi), %r10
    imulq $127, 0(%r12), %r11
    imulq $-1, 127(%rsp), %r14
    imulq $0, 2147483647(%r12), %r8
    imulq $-128, 0(%r14,%r12,1), %r12
    imulq $127, -1(%rdi,%rax,2), %r13
    imulq $-1, 4660(%r15,%r15,4), %r15
    imulq $0, gnu_back(%rip), %r9
    imulq $-128, 128, %r10
    rolb 0(%r14)
    rolb 64(%r8)
    rolb -129(%r9)
    rolb 0(%r12)
    rolb 8(%r12)
    rolb -2147483648(%r12)
    rolb 0(%r8,%rsi,8)
    rolb -128(%r8,%rcx,1)
    rolb 2147483647(%r9,%r9,2)
    rolb %ch
    rolb 0(%rsi)
    rolb 127(%rsi)
    rolb 4660(%rdi)
    rolb 0(%rsp)
    rolb -1(%rsp)
    rolb 128(%rsp)
    rolb 0(%rbx,%rdx,4)
    rolb 64(%rsi,%rbx,8)
    rolb -129(%rdi,%rbp,1)
    rolb gnu_fwd(%rip)
    rolb -2147483648
    rolb $0, 0(%r15)
    rolb $255, 8(%r10)
    rolb $63, 2147483647(%r11)
    rolb $7, 0(%r12)
    rolb $0, -128(%r12)
    rolb $255, 4660(%r12)
    rolb $63, 0(%r9,%rbp,2)
    rolb $7, 127(%r12,%r12,4)
    rolb $0, 128(%r13,%rax,8)
    rolb $255, %ah
    rolb $63, 0(%rdi)
    rolb $7, -1(%rcx)
    rolb $0, -129(%rdx)
    rolb $255, 0(%rsp)
    rolb $63, 64(%rsp)
    rolb $7, -2147483648(%rsp)
    rolb $0, 0(%rsp,%rsi,1)
    rolb $255, 8(%rax,%rdi,2)
    rolb $63, 2147483647(%rcx,%rax,4)
    rolb $7, gnu_back(%rip)
    rolb $0, 4660
    rolb %cl, 0(%r8)
    rolb %cl, -128(%r13)
    rolb %cl, 128(%r14)
g19:
    rolb %cl, 0(%r12)
    rolb %cl, 127(%r12)
    rolb %cl, -129(%r12)
    rolb %cl, 0(%r10,%r15,8)
    rolb %cl, -1(%r15,%rsi,1)
    rolb %cl, -2147483648(%r8,%rcx,2)
    rolb %cl, %cl
    rolb %cl, 0(%rcx)
    rolb %cl, 64(%rbx)
    rolb %cl, 2147483647(%rbp)
    rolb %cl, 0(%rsp)
    rolb %cl, 8(%rsp)
    rolb %cl, 4660(%rsp)
    rolb %cl, 0(%rsi,%rcx,4)
    rolb %cl, -128(%rdx,%rdx,8)
    rolb %cl, 128(%rbx,%rbx,1)
    rolb %cl, gnu_fwd(%rip)
    rolb %cl, -129
    rolw 0(%r9)
    rolw 127(%r15)
    rolw -2147483648(%r8)
    rolw 0(%r12)
    rolw -1(%r12)
    rolw 2147483647(%r12)
    rolw 0(%r11,%r9,2)
    rolw 64(%r9,%rbp,4)
    rolw 4660(%r12,%r12,8)
    rolw %dx
    rolw 0(%rdx)
    rolw 8(%rsi)
    rolw 128(%rdi)
    rolw 0(%rsp)
    rolw -128(%rsp)
    rolw -129(%rsp)
    rolw 0(%rdi,%rbp,1)
    rolw 127(%rsp,%rsi,2)
    rolw -2147483648(%rbp,%rdi,4)
    rolw gnu_back(%rip)
    rolw 2147483647
    rolw $255, 0(%r10)
    rolw $63, -1(%r9)
    rolw $7, 4660(%r10)
    rolw $0, 0(%r12)
    rolw $255, 64(%r12)
    rolw $63, 128(%r12)
    rolw $7, 0(%r12,%rax,8)
    rolw $0, 8(%r13,%r15,1)
    rolw $255, -129(%r15,%rsi,2)
    rolw $63, %bx
    rolw $7, 0(%rbx)
    rolw $0, -128(%rcx)
    rolw $255, -2147483648(%rdx)
    rolw $63, 0(%rsp)
    rolw $7, 127(%rsp)
    rolw $0, 2147483647(%rsp)
    rolw $255, 0(%rax,%rax,4)
    rolw $63, -1(%rsi,%rcx,8)
    rolw $7, 4660(%rdi,%rdx,1)
    rolw $0, gnu_fwd(%rip)
    rolw $255, 128
    rolw %cl, 0(%r11)
    rolw %cl, 64(%r11)
    rolw %cl, -129(%r13)
    rolw %cl, 0(%r12)
    rolw %cl, 8(%r12)
    rolw %cl, -2147483648(%r12)
    rolw %cl, 0(%r14,%rcx,2)
    rolw %cl, -128(%r8,%r9,4)
    rolw %cl, 2147483647(%r9,%rbp,8)
    rolw %cl, %si
    rolw %cl, 0(%rsi)
    rolw %cl, 127(%rbx)
    rolw %cl, 4660(%rbp)
    rolw %cl, 0(%rsp)
    rolw %cl, -1(%rsp)
    rolw %cl, 128(%rsp)
    rolw %cl, 0(%rcx,%rbx,1)
    rolw %cl, 64(%rax,%rbp,2)
    rolw %cl, -129(%rcx,%rsi,4)
    rolw %cl, gnu_back(%rip)
    rolw %cl, -2147483648
    roll 0(%r14)
    roll 8(%r14)
    roll 2147483647(%r15)
    roll 0(%r12)
    roll -128(%r12)
    roll 4660(%r12)
    roll 0(%r15,%r12,8)
    roll 127(%r12,%rax,1)
    roll 128(%r13,%r15,2)
    roll %edi
    roll 0(%rdi)
    roll -1(%rsi)
    roll -129(%rdi)
    roll 0(%rsp)
    roll 64(%rsp)
    roll -2147483648(%rsp)
    roll 0(%rdx,%rdi,4)
    roll 8(%rdx,%rax,8)
    roll 2147483647(%rbx,%rcx,1)
    roll gnu_fwd(%rip)
    roll 4660
    roll $63, 0(%r15)
    roll $7, -128(%r8)
    roll $0, 128(%r9)
    roll $255, 0(%r12)
    roll $63, 127(%r12)
    roll $7, -129(%r12)
    roll $0, 0(%r8,%rsi,2)
    roll $255, -1(%r15,%rcx,4)
    roll $63, -2147483648(%r8,%r9,8)
    roll $7, %ebp
    roll $0, 0(%rcx)
    roll $255, 64(%rcx)
    roll $63, 2147483647(%rdx)
    roll $7, 0(%rsp)
    roll $0, 8(%rsp)
    roll $255, 4660(%rsp)
    roll $63, 0(%rbx,%rdx,1)
    roll $7, -128(%rsp,%rbx,2)
    roll $0, 128(%rbp,%rbp,4)
    roll $255, gnu_back(%rip)
    roll $63, -129
    roll %cl, 0(%r8)
    roll %cl, 127(%r10)
    roll %cl, -2147483648(%r11)
    roll %cl, 0(%r12)
    roll %cl, -1(%r12)
    roll %cl, 2147483647(%r12)
    roll %cl, 0(%r9,%rbp,8)
    roll %cl, 64(%r9,%r12,1)
    roll %cl, 4660(%r12,%rax,2)
    roll %cl, %esp
    roll %cl, 0(%rdx)
    roll %cl, 8(%rbx)
    roll %cl, 128(%rbp)
    roll %cl, 0(%rsp)
    roll %cl, -128(%rsp)
    roll %cl, -129(%rsp)
    roll %cl, 0(%rsp,%rsi,4)
    roll %cl, 127(%rsi,%rdi,8)
    roll %cl, -2147483648(%rdi,%rax,1)
    roll %cl, gnu_fwd(%rip)
    roll %cl, 2147483647
    rolq 0(%r11)
    rolq -1(%r11)
    rolq 4660(%rdi)
    rolq 0(%rsp)
    rolq 64(%r12)
    rolq 128(%rsp)
    rolq 0(%rsi,%r15,2)
    rolq 8(%rax,%rsi,4)
    rolq -129(%r9,%rcx,8)
    rolq gnu_back(%rip)
    rolq -2147483648
    rolq $7, 0(%rdi)
    rolq $0, -128(%r14)
    rolq $255, 2147483647(%r15)
    rolq $63, 0(%r12)
    rolq $7, 127(%rsp)
    rolq $0, 4660(%r12)
    rolq $255, 0(%r15,%r9,1)
    rolq $63, -1(%rsp,%rbp,2)
    rolq $7, 128(%r13,%r12,4)
    rolq $0, gnu_fwd(%rip)
    rolq $255, -129
    rolq %cl, 0(%r14)
    rolq %cl, 64(%rcx)
    rolq %cl, -2147483648(%r8)
    rolq %cl, 0(%rsp)
    rolq %cl, 8(%r12)
    rolq %cl, 2147483647(%rsp)
    rolq %cl, 0(%rax,%rax,8)
    rolq %cl, -128(%rbp,%r15,1)
    rolq %cl, 4660(%r12,%rsi,2)
    rolq %cl, gnu_back(%rip)
    rolq %cl, 128
    rorb 0(%r9)
    rorb 127(%r13)
    rorb -129(%r14)
    rorb 0(%r12)
    rorb -1(%r12)
    rorb -2147483648(%r12)
    rorb 0(%r10,%rcx,4)
    rorb 64(%r13,%r9,8)
    rorb 2147483647(%r15,%rbp,1)
    rorb %dl
    rorb 0(%rbx)
    rorb 8(%rsi)
    rorb 4660(%rdi)
    rorb 0(%rsp)
    rorb -128(%rsp)
    rorb 128(%rsp)
    rorb 0(%rsi,%rcx,2)
    rorb 127(%rax,%rdx,4)
    rorb -129(%rcx,%rbx,8)
    rorb gnu_fwd(%rip)
    rorb -2147483648
    rorb $63, 0(%r10)
    rorb $7, -1(%r15)
g20:
    rorb $0, 2147483647(%r8)
    rorb $255, 0(%r12)
    rorb $63, 64(%r12)
    rorb $7, 4660(%r12)
    rorb $0, 0(%r11,%r12,1)
    rorb $255, 8(%r8,%rax,2)
    rorb $63, 128(%r9,%r15,4)
    rorb $7, %bl
    rorb $0, 0(%rsi)
    rorb $255, -128(%rcx)
    rorb $63, -129(%rdx)
    rorb $7, 0(%rsp)
    rorb $0, 127(%rsp)
    rorb $255, -2147483648(%rsp)
    rorb $63, 0(%rdi,%rbp,8)
    rorb $7, -1(%rdx,%rsi,1)
    rorb $0, 2147483647(%rbx,%rdi,2)
    rorb $255, gnu_back(%rip)
    rorb $63, 4660
    rorb %cl, 0(%r11)
    rorb %cl, 64(%r9)
    rorb %cl, 128(%r10)
    rorb %cl, 0(%r12)
    rorb %cl, 8(%r12)
    rorb %cl, -129(%r12)
    rorb %cl, 0(%r12,%rsi,4)
    rorb %cl, -128(%r12,%rcx,8)
    rorb %cl, -2147483648(%r13,%r9,1)
    rorb %cl, %dh
    rorb %cl, 0(%rdi)
    rorb %cl, 127(%rbx)
    rorb %cl, 2147483647(%rbp)
    rorb %cl, 0(%rsp)
    rorb %cl, -1(%rsp)
    rorb %cl, 4660(%rsp)
    rorb %cl, 0(%rax,%rax,2)
    rorb %cl, 64(%rsp,%rcx,4)
    rorb %cl, 128(%rbp,%rdx,8)
    rorb %cl, gnu_fwd(%rip)
    rorb %cl, -129
    rorw 0(%r14)
    rorw 8(%r11)
    rorw -2147483648(%r13)
    rorw 0(%r12)
    rorw -128(%r12)
    rorw 2147483647(%r12)
    rorw 0(%r14,%rbp,1)
    rorw 127(%r15,%r12,2)
    rorw 4660(%r8,%rax,4)
    rorw %cx
    rorw 0(%rcx)
    rorw -1(%rsi)
    rorw 128(%rdi)
    rorw 0(%rsp)
    rorw 64(%rsp)
    rorw -129(%rsp)
    rorw 0(%rcx,%rbx,8)
    rorw 8(%rsi,%rbp,1)
    rorw -2147483648(%rdi,%rsi,2)
    rorw gnu_back(%rip)
    rorw 2147483647
    rorw $7, 0(%r15)
    rorw $0, -128(%r14)
    rorw $255, 4660(%r15)
    rorw $63, 0(%r12)
    rorw $7, 127(%r12)
    rorw $0, 128(%r12)
    rorw $255, 0(%r15,%r15,4)
    rorw $63, -1(%r9,%rsi,8)
    rorw $7, -129(%r12,%rcx,1)
    rorw $0, %dx
    rorw $255, 0(%rdx)
    rorw $63, 64(%rcx)
    rorw $7, -2147483648(%rdx)
    rorw $0, 0(%rsp)
    rorw $255, 8(%rsp)
    rorw $63, 2147483647(%rsp)
    rorw $7, 0(%rdx,%rdi,2)
    rorw $0, -128(%rax,%rax,4)
    rorw $255, 4660(%rcx,%rcx,8)
    rorw $63, gnu_fwd(%rip)
    rorw $7, 128
    rorw %cl, 0(%r8)
    rorw %cl, 127(%r8)
    rorw %cl, -129(%r9)
    rorw %cl, 0(%r12)
    rorw %cl, -1(%r12)
    rorw %cl, -2147483648(%r12)
    rorw %cl, 0(%r8,%r9,1)
    rorw %cl, 64(%r13,%rbp,2)
    rorw %cl, 2147483647(%r15,%r12,4)
    rorw %cl, %bx
    rorw %cl, 0(%rbx)
    rorw %cl, 8(%rbx)
    rorw %cl, 4660(%rbp)
    rorw %cl, 0(%rsp)
    rorw %cl, -128(%rsp)
    rorw %cl, 128(%rsp)
    rorw %cl, 0(%rbx,%rdx,8)
    rorw %cl, 127(%rdx,%rbx,1)
    rorw %cl, -129(%rbx,%rbp,2)
    rorw %cl, gnu_back(%rip)
    rorw %cl, -2147483648
    rorl 0(%r9)
    rorl -1(%r10)
    rorl 2147483647(%r11)
    rorl 0(%r12)
    rorl 64(%r12)
    rorl 4660(%r12)
    rorl 0(%r9,%rax,4)
    rorl 8(%r8,%r15,8)
    rorl 128(%r9,%rsi,1)
    rorl %esi
    rorl 0(%rsi)
    rorl -128(%rsi)
    rorl -129(%rdi)
    rorl 0(%rsp)
    rorl 127(%rsp)
    rorl -2147483648(%rsp)
    rorl 0(%rsp,%rsi,2)
    rorl -1(%rsp,%rdi,4)
    rorl 2147483647(%rbp,%rax,8)
    rorl gnu_fwd(%rip)
    rorl 4660
    rorl $0, 0(%r10)
    rorl $255, 64(%r13)
    rorl $63, 128(%r14)
    rorl $7, 0(%r12)
    rorl $0, 8(%r12)
    rorl $255, -129(%r12)
    rorl $63, 0(%r10,%rcx,1)
    rorl $7, -128(%r12,%r9,2)
    rorl $0, -2147483648(%r13,%rbp,4)
    rorl $255, %edi
    rorl $63, 0(%rdi)
    rorl $7, 127(%rcx)
    rorl $0, 2147483647(%rdx)
    rorl $255, 0(%rsp)
    rorl $63, -1(%rsp)
    rorl $7, 4660(%rsp)
    rorl $0, 0(%rsi,%rcx,8)
    rorl $255, 64(%rsi,%rdx,1)
    rorl $63, 128(%rdi,%rbx,2)
    rorl $7, gnu_back(%rip)
    rorl $0, -129
    rorl %cl, 0(%r11)
    rorl %cl, 8(%r15)
    rorl %cl, -2147483648(%r8)
    rorl %cl, 0(%r12)
    rorl %cl, -128(%r12)
    rorl %cl, 2147483647(%r12)
    rorl %cl, 0(%r11,%r12,4)
    rorl %cl, 127(%r15,%rax,8)
    rorl %cl, 4660(%r8,%r15,1)
    rorl %cl, %ebp
    rorl %cl, 0(%rcx)
    rorl %cl, -1(%rbx)
    rorl %cl, 128(%rbp)
    rorl %cl, 0(%rsp)
    rorl %cl, 64(%rsp)
    rorl %cl, -129(%rsp)
    rorl %cl, 0(%rdi,%rbp,2)
    rorl %cl, 8(%rax,%rsi,4)
    rorl %cl, -2147483648(%rcx,%rdi,8)
    rorl %cl, gnu_fwd(%rip)
    rorl %cl, 2147483647
    rorq 0(%r15)
    rorq -128(%rbp)
    rorq 4660(%r13)
    rorq 0(%r12)
    rorq 127(%rsp)
    rorq 128(%r12)
    rorq 0(%r8,%rsi,1)
    rorq -1(%rdi,%rcx,2)
    rorq -129(%r15,%r9,4)
    rorq gnu_back(%rip)
    rorq -2147483648
    rorq $255, 0(%rcx)
    rorq $63, 64(%rdx)
    rorq $7, 2147483647(%r9)
    rorq $0, 0(%rsp)
    rorq $255, 8(%r12)
    rorq $63, 4660(%rsp)
    rorq $7, 0(%rcx,%rbp,8)
    rorq $0, -128(%rax,%r12,1)
    rorq $255, 128(%r9,%rax,2)
    rorq $63, gnu_fwd(%rip)
    rorq $7, -129
    rorq %cl, 0(%r8)
    rorq %cl, 127(%rbx)
    rorq %cl, -2147483648(%r10)
    rorq %cl, 0(%r12)
    rorq %cl, -1(%rsp)
    rorq %cl, 2147483647(%r12)
    rorq %cl, 0(%r12,%r15,4)
    rorq %cl, 64(%rsp,%rsi,8)
    rorq %cl, 4660(%r13,%rcx,1)
    rorq %cl, gnu_back(%rip)
    rorq %cl, 128
    rclb 0(%r14)
g21:
    rclb 8(%r9)
    rclb -129(%r10)
    rclb 0(%r12)
    rclb -128(%r12)
    rclb -2147483648(%r12)
    rclb 0(%r12,%r9,2)
    rclb 127(%r9,%rbp,4)
    rclb 2147483647(%r12,%r12,8)
    rclb %bh
    rclb 0(%rdx)
    rclb -1(%rsi)
    rclb 4660(%rdi)
    rclb 0(%rsp)
    rclb 64(%rsp)
    rclb 128(%rsp)
    rclb 0(%rax,%rax,1)
    rclb 8(%rdx,%rcx,2)
    rclb -129(%rbx,%rdx,4)
    rclb gnu_fwd(%rip)
    rclb -2147483648
    rclb $0, 0(%r15)
    rclb $255, -128(%r11)
    rclb $63, 2147483647(%r13)
    rclb $7, 0(%r12)
    rclb $0, 127(%r12)
    rclb $255, 4660(%r12)
    rclb $63, 0(%r14,%rax,8)
    rclb $7, -1(%r13,%r15,1)
    rclb $0, 128(%r15,%rsi,2)
    rclb $255, %ch
    rclb $63, 0(%rbx)
    rclb $7, 64(%rcx)
    rclb $0, -129(%rdx)
    rclb $255, 0(%rsp)
    rclb $63, 8(%rsp)
    rclb $7, -2147483648(%rsp)
    rclb $0, 0(%rcx,%rbx,4)
    rclb $255, -128(%rsp,%rbp,8)
    rclb $63, 2147483647(%rbp,%rsi,1)
    rclb $7, gnu_back(%rip)
    rclb $0, 4660
    rclb %cl, 0(%r8)
    rclb %cl, 127(%r14)
    rclb %cl, 128(%r15)
    rclb %cl, 0(%r12)
    rclb %cl, -1(%r12)
    rclb %cl, -129(%r12)
    rclb %cl, 0(%r15,%rcx,2)
    rclb %cl, 64(%r8,%r9,4)
    rclb %cl, -2147483648(%r9,%rbp,8)
    rclb %cl, %ah
    rclb %cl, 0(%rsi)
    rclb %cl, 8(%rbx)
    rclb %cl, 2147483647(%rbp)
    rclb %cl, 0(%rsp)
    rclb %cl, -128(%rsp)
    rclb %cl, 4660(%rsp)
    rclb %cl, 0(%rdx,%rdi,1)
    rclb %cl, 127(%rsi,%rax,2)
    rclb %cl, 128(%rdi,%rcx,4)
    rclb %cl, gnu_fwd(%rip)
    rclb %cl, -129
    rclw 0(%r9)
    rclw -1(%r8)
    rclw -2147483648(%r9)
    rclw 0(%r12)
    rclw 64(%r12)
    rclw 2147483647(%r12)
    rclw 0(%r8,%r12,8)
    rclw 8(%r12,%rax,1)
    rclw 4660(%r13,%r15,2)
    rclw %sp
    rclw 0(%rdi)
    rclw -128(%rsi)
    rclw 128(%rdi)
    rclw 0(%rsp)
    rclw 127(%rsp)
    rclw -129(%rsp)
    rclw 0(%rbx,%rdx,4)
    rclw -1(%rax,%rbx,8)
    rclw -2147483648(%rcx,%rbp,1)
    rclw gnu_back(%rip)
    rclw 2147483647
    rclw $255, 0(%r10)
    rclw $63, 64(%r10)
    rclw $7, 4660(%r11)
    rclw $0, 0(%r12)
    rclw $255, 8(%r12)
    rclw $63, 128(%r12)
    rclw $7, 0(%r9,%rsi,2)
    rclw $0, -128(%r15,%rcx,4)
    rclw $255, -129(%r8,%r9,8)
    rclw $63, %cx
    rclw $7, 0(%rcx)
    rclw $0, 127(%rcx)
    rclw $255, -2147483648(%rdx)
    rclw $63, 0(%rsp)
    rclw $7, -1(%rsp)
    rclw $0, 2147483647(%rsp)
    rclw $255, 0(%rsp,%rsi,1)
    rclw $63, 64(%rdx,%rdi,2)
    rclw $7, 4660(%rbx,%rax,4)
    rclw $0, gnu_fwd(%rip)
    rclw $255, 128
    rclw %cl, 0(%r11)
    rclw %cl, 8(%r13)
    rclw %cl, -129(%r14)
    rclw %cl, 0(%r12)
    rclw %cl, -128(%r12)
    rclw %cl, -2147483648(%r12)
    rclw %cl, 0(%r10,%rbp,8)
    rclw %cl, 127(%r9,%r12,1)
    rclw %cl, 2147483647(%r12,%rax,2)
    rclw %cl, %dx
    rclw %cl, 0(%rdx)
    rclw %cl, -1(%rbx)
    rclw %cl, 4660(%rbp)
    rclw %cl, 0(%rsp)
    rclw %cl, 64(%rsp)
    rclw %cl, 128(%rsp)
    rclw %cl, 0(%rsi,%rcx,4)
    rclw %cl, 8(%rsp,%rdx,8)
    rclw %cl, -129(%rbp,%rbx,1)
    rclw %cl, gnu_back(%rip)
    rclw %cl, -2147483648
    rcll 0(%r14)
    rcll -128(%r15)
    rcll 2147483647(%r8)
    rcll 0(%r12)
    rcll 127(%r12)
    rcll 4660(%r12)
    rcll 0(%r11,%r15,2)
    rcll -1(%r13,%rsi,4)
    rcll 128(%r15,%rcx,8)
    rcll %ebx
    rcll 0(%rbx)
    rcll 64(%rsi)
    rcll -129(%rdi)
    rcll 0(%rsp)
    rcll 8(%rsp)
    rcll -2147483648(%rsp)
    rcll 0(%rdi,%rbp,1)
    rcll -128(%rsi,%rsi,2)
    rcll 2147483647(%rdi,%rdi,4)
    rcll gnu_fwd(%rip)
    rcll 4660
    rcll $63, 0(%r15)
    rcll $7, 127(%r9)
    rcll $0, 128(%r10)
    rcll $255, 0(%r12)
    rcll $63, -1(%r12)
    rcll $7, -129(%r12)
    rcll $0, 0(%r12,%r9,8)
    rcll $255, 64(%r8,%rbp,1)
    rcll $63, -2147483648(%r9,%r12,2)
    rcll $7, %esi
    rcll $0, 0(%rsi)
    rcll $255, 8(%rcx)
    rcll $63, 2147483647(%rdx)
    rcll $7, 0(%rsp)
    rcll $0, -128(%rsp)
    rcll $255, 4660(%rsp)
    rcll $63, 0(%rax,%rax,4)
    rcll $7, 127(%rax,%rcx,8)
    rcll $0, 128(%rcx,%rdx,1)
    rcll $255, gnu_back(%rip)
    rcll $63, -129
    rcll %cl, 0(%r8)
    rcll %cl, -1(%r11)
    rcll %cl, -2147483648(%r13)
    rcll %cl, 0(%r12)
    rcll %cl, 64(%r12)
    rcll %cl, 2147483647(%r12)
    rcll %cl, 0(%r14,%rax,2)
    rcll %cl, 8(%r12,%r15,4)
    rcll %cl, 4660(%r13,%rsi,8)
    rcll %cl, %edi
    rcll %cl, 0(%rdi)
    rcll %cl, -128(%rbx)
    rcll %cl, 128(%rbp)
    rcll %cl, 0(%rsp)
    rcll %cl, 127(%rsp)
    rcll %cl, -129(%rsp)
    rcll %cl, 0(%rcx,%rbx,1)
    rcll %cl, -1(%rdx,%rbp,2)
    rcll %cl, -2147483648(%rbx,%rsi,4)
    rcll %cl, gnu_fwd(%rip)
    rcll %cl, 2147483647
    rclq 0(%rdx)
    rclq 64(%rsi)
    rclq 4660(%r11)
    rclq 0(%rsp)
    rclq 8(%r12)
    rclq 128(%rsp)
    rclq 0(%rdx,%rcx,8)
    rclq -128(%rbp,%r9,1)
    rclq -129(%r12,%rbp,2)
    rclq gnu_back(%rip)
    rclq -2147483648
    rclq $7, 0(%r9)
g22:
    rclq $0, 127(%rdi)
    rclq $255, 2147483647(%r14)
    rclq $63, 0(%r12)
    rclq $7, -1(%rsp)
    rclq $0, 4660(%r12)
    rclq $255, 0(%r9,%r12,4)
    rclq $63, 64(%rdi,%rax,8)
    rclq $7, 128(%r15,%r15,1)
    rclq $0, gnu_fwd(%rip)
    rclq $255, -129
    rclq %cl, 0(%rbx)
    rclq %cl, 8(%r15)
    rclq %cl, -2147483648(%rcx)
    rclq %cl, 0(%rsp)
    rclq %cl, -128(%r12)
    rclq %cl, 2147483647(%rsp)
    rclq %cl, 0(%rsp,%rsi,2)
    rclq %cl, 127(%rax,%rcx,4)
    rclq %cl, 4660(%r9,%r9,8)
    rclq %cl, gnu_back(%rip)
    rclq %cl, 128
    rcrb 0(%r9)
    rcrb -1(%r14)
    rcrb -129(%r15)
    rcrb 0(%r12)
    rcrb 64(%r12)
    rcrb -2147483648(%r12)
    rcrb 0(%r15,%rbp,1)
    rcrb 8(%r15,%r12,2)
    rcrb 2147483647(%r8,%rax,4)
    rcrb %cl
    rcrb 0(%rcx)
    rcrb -128(%rsi)
    rcrb 4660(%rdi)
    rcrb 0(%rsp)
    rcrb 127(%rsp)
    rcrb 128(%rsp)
    rcrb 0(%rdx,%rdi,8)
    rcrb -1(%rsp,%rax,1)
    rcrb -129(%rbp,%rcx,2)
    rcrb gnu_fwd(%rip)
    rcrb -2147483648
    rcrb $63, 0(%r10)
    rcrb $7, 64(%r8)
    rcrb $0, 2147483647(%r9)
    rcrb $255, 0(%r12)
    rcrb $63, 8(%r12)
    rcrb $7, 4660(%r12)
    rcrb $0, 0(%r8,%r15,4)
    rcrb $255, -128(%r9,%rsi,8)
    rcrb $63, 128(%r12,%rcx,1)
    rcrb $7, %dl
    rcrb $0, 0(%rdx)
    rcrb $255, 127(%rcx)
    rcrb $63, -129(%rdx)
    rcrb $7, 0(%rsp)
    rcrb $0, -1(%rsp)
    rcrb $255, -2147483648(%rsp)
    rcrb $63, 0(%rbx,%rdx,2)
    rcrb $7, 64(%rsi,%rbx,4)
    rcrb $0, 2147483647(%rdi,%rbp,8)
    rcrb $255, gnu_back(%rip)
    rcrb $63, 4660
    rcrb %cl, 0(%r11)
    rcrb %cl, 8(%r10)
    rcrb %cl, 128(%r11)
    rcrb %cl, 0(%r12)
    rcrb %cl, -128(%r12)
    rcrb %cl, -129(%r12)
    rcrb %cl, 0(%r9,%r9,1)
    rcrb %cl, 127(%r13,%rbp,2)
    rcrb %cl, -2147483648(%r15,%r12,4)
    rcrb %cl, %bl
    rcrb %cl, 0(%rbx)
    rcrb %cl, -1(%rbx)
    rcrb %cl, 2147483647(%rbp)
    rcrb %cl, 0(%rsp)
    rcrb %cl, 64(%rsp)
    rcrb %cl, 4660(%rsp)
    rcrb %cl, 0(%rsp,%rsi,8)
    rcrb %cl, 8(%rax,%rdi,1)
    rcrb %cl, 128(%rcx,%rax,2)
    rcrb %cl, gnu_fwd(%rip)
    rcrb %cl, -129
    rcrw 0(%r14)
    rcrw -128(%r13)
    rcrw -2147483648(%r14)
    rcrw 0(%r12)
    rcrw 127(%r12)
    rcrw 2147483647(%r12)
    rcrw 0(%r10,%rax,4)
    rcrw -1(%r8,%r15,8)
    rcrw 4660(%r9,%rsi,1)
    rcrw %bp
    rcrw 0(%rsi)
    rcrw 64(%rsi)
    rcrw 128(%rdi)
    rcrw 0(%rsp)
    rcrw 8(%rsp)
    rcrw -129(%rsp)
    rcrw 0(%rsi,%rcx,2)
    rcrw -128(%rdx,%rdx,4)
    rcrw -2147483648(%rbx,%rbx,8)
    rcrw gnu_back(%rip)
    rcrw 2147483647
    rcrw $7, 0(%r15)
    rcrw $0, 127(%r15)
    rcrw $255, 4660(%r8)
    rcrw $63, 0(%r12)
    rcrw $7, -1(%r12)
    rcrw $0, 128(%r12)
    rcrw $255, 0(%r11,%rcx,1)
    rcrw $63, 64(%r12,%r9,2)
    rcrw $7, -129(%r13,%rbp,4)
    rcrw $0, %sp
    rcrw $255, 0(%rdi)
    rcrw $63, 8(%rcx)
    rcrw $7, -2147483648(%rdx)
    rcrw $0, 0(%rsp)
    rcrw $255, -128(%rsp)
    rcrw $63, 2147483647(%rsp)
    rcrw $7, 0(%rdi,%rbp,8)
    rcrw $0, 127(%rsp,%rsi,1)
    rcrw $255, 4660(%rbp,%rdi,2)
    rcrw $63, gnu_fwd(%rip)
    rcrw $7, 128
    rcrw %cl, 0(%r8)
    rcrw %cl, -1(%r9)
    rcrw %cl, -129(%r10)
    rcrw %cl, 0(%r12)
    rcrw %cl, 64(%r12)
    rcrw %cl, -2147483648(%r12)
    rcrw %cl, 0(%r12,%r12,4)
    rcrw %cl, 8(%r15,%rax,8)
    rcrw %cl, 2147483647(%r8,%r15,1)
    rcrw %cl, %cx
    rcrw %cl, 0(%rcx)
    rcrw %cl, -128(%rbx)
    rcrw %cl, 4660(%rbp)
    rcrw %cl, 0(%rsp)
    rcrw %cl, 127(%rsp)
    rcrw %cl, 128(%rsp)
    rcrw %cl, 0(%rax,%rax,2)
    rcrw %cl, -1(%rsi,%rcx,4)
    rcrw %cl, -129(%rdi,%rdx,8)
    rcrw %cl, gnu_back(%rip)
    rcrw %cl, -2147483648
    rcrl 0(%r9)
    rcrl 64(%r11)
    rcrl 2147483647(%r13)
    rcrl 0(%r12)
    rcrl 8(%r12)
    rcrl 4660(%r12)
    rcrl 0(%r14,%rsi,1)
    rcrl -128(%r9,%rcx,2)
    rcrl 128(%r12,%r9,4)
    rcrl %edx
    rcrl 0(%rdx)
    rcrl 127(%rsi)
    rcrl -129(%rdi)
    rcrl 0(%rsp)
    rcrl -1(%rsp)
    rcrl -2147483648(%rsp)
    rcrl 0(%rcx,%rbx,8)
    rcrl 64(%rax,%rbp,1)
    rcrl 2147483647(%rcx,%rsi,2)
    rcrl gnu_fwd(%rip)
    rcrl 4660
    rcrl $0, 0(%r10)
    rcrl $255, 8(%r14)
    rcrl $63, 128(%r15)
    rcrl $7, 0(%r12)
    rcrl $0, -128(%r12)
    rcrl $255, -129(%r12)
    rcrl $63, 0(%r15,%rbp,4)
    rcrl $7, 127(%r13,%r12,8)
    rcrl $0, -2147483648(%r15,%rax,1)
    rcrl $255, %ebx
    rcrl $63, 0(%rbx)
    rcrl $7, -1(%rcx)
    rcrl $0, 2147483647(%rdx)
    rcrl $255, 0(%rsp)
    rcrl $63, 64(%rsp)
    rcrl $7, 4660(%rsp)
    rcrl $0, 0(%rdx,%rdi,2)
    rcrl $255, 8(%rdx,%rax,4)
    rcrl $63, 128(%rbx,%rcx,8)
    rcrl $7, gnu_back(%rip)
    rcrl $0, -129
    rcrl %cl, 0(%r11)
    rcrl %cl, -128(%r8)
    rcrl %cl, -2147483648(%r9)
    rcrl %cl, 0(%r12)
    rcrl %cl, 127(%r12)
    rcrl %cl, 2147483647(%r12)
    rcrl %cl, 0(%r8,%r15,1)
    rcrl %cl, -1(%r8,%rsi,2)
    rcrl %cl, 4660(%r9,%rcx,4)
    rcrl %cl, %esi
    rcrl %cl, 0(%rsi)
g23:
    rcrl %cl, 64(%rbx)
    rcrl %cl, 128(%rbp)
    rcrl %cl, 0(%rsp)
    rcrl %cl, 8(%rsp)
    rcrl %cl, -129(%rsp)
    rcrl %cl, 0(%rbx,%rdx,8)
    rcrl %cl, -128(%rsp,%rbx,1)
    rcrl %cl, -2147483648(%rbp,%rbp,2)
    rcrl %cl, gnu_fwd(%rip)
    rcrl %cl, 2147483647
    rcrq 0(%r10)
    rcrq 127(%r8)
    rcrq 4660(%rbp)
    rcrq 0(%r12)
    rcrq -1(%rsp)
    rcrq 128(%r12)
    rcrq 0(%r14,%r9,4)
    rcrq 64(%rsp,%rbp,8)
    rcrq -129(%r13,%r12,1)
    rcrq gnu_back(%rip)
    rcrq -2147483648
    rcrq $255, 0(%rsi)
    rcrq $63, 8(%r13)
    rcrq $7, 2147483647(%rdx)
    rcrq $0, 0(%rsp)
    rcrq $255, -128(%r12)
    rcrq $63, 4660(%rsp)
    rcrq $7, 0(%rsi,%rax,2)
    rcrq $0, 127(%rbp,%r15,4)
    rcrq $255, 128(%r12,%rsi,8)
    rcrq $63, gnu_fwd(%rip)
    rcrq $7, -129
    rcrq %cl, 0(%r11)
    rcrq %cl, -1(%r9)
    rcrq %cl, -2147483648(%rbx)
    rcrq %cl, 0(%r12)
    rcrq %cl, 64(%rsp)
    rcrq %cl, 2147483647(%r12)
    rcrq %cl, 0(%r15,%rcx,1)
    rcrq %cl, 8(%rdi,%r9,2)
    rcrq %cl, 4660(%r15,%rbp,4)
    rcrq %cl, gnu_back(%rip)
    rcrq %cl, 128
    shlb 0(%r14)
    shlb -128(%r10)
    shlb -129(%r11)
    shlb 0(%r12)
    shlb 127(%r12)
    shlb -2147483648(%r12)
    shlb 0(%r9,%r12,8)
    shlb -1(%r12,%rax,1)
    shlb 2147483647(%r13,%r15,2)
    shlb %dh
    shlb 0(%rdi)
    shlb 64(%rsi)
    shlb 4660(%rdi)
    shlb 0(%rsp)
    shlb 8(%rsp)
    shlb 128(%rsp)
    shlb 0(%rsp,%rsi,4)
    shlb -128(%rsi,%rdi,8)
    shlb -129(%rdi,%rax,1)
    shlb gnu_fwd(%rip)
    shlb -2147483648
    shlb $0, 0(%r15)
    shlb $255, 127(%r13)
    shlb $63, 2147483647(%r14)
    shlb $7, 0(%r12)
    shlb $0, -1(%r12)
    shlb $255, 4660(%r12)
    shlb $63, 0(%r10,%rsi,2)
    shlb $7, 64(%r15,%rcx,4)
    shlb $0, 128(%r8,%r9,8)
    shlb $255, %bh
    shlb $63, 0(%rcx)
    shlb $7, 8(%rcx)
    shlb $0, -129(%rdx)
    shlb $255, 0(%rsp)
    shlb $63, -128(%rsp)
    shlb $7, -2147483648(%rsp)
    shlb $0, 0(%rsi,%rcx,1)
    shlb $255, 127(%rax,%rdx,2)
    shlb $63, 2147483647(%rcx,%rbx,4)
    shlb $7, gnu_back(%rip)
    shlb $0, 4660
    shlb %cl, 0(%r8)
    shlb %cl, -1(%r15)
    shlb %cl, 128(%r8)
    shlb %cl, 0(%r12)
    shlb %cl, 64(%r12)
    shlb %cl, -129(%r12)
    shlb %cl, 0(%r11,%rbp,8)
    shlb %cl, 8(%r9,%r12,1)
    shlb %cl, -2147483648(%r12,%rax,2)
    shlb %cl, %ch
    shlb %cl, 0(%rdx)
    shlb %cl, -128(%rbx)
    shlb %cl, 2147483647(%rbp)
    shlb %cl, 0(%rsp)
    shlb %cl, 127(%rsp)
    shlb %cl, 4660(%rsp)
    shlb %cl, 0(%rdi,%rbp,4)
    shlb %cl, -1(%rdx,%rsi,8)
    shlb %cl, 128(%rbx,%rdi,1)
    shlb %cl, gnu_fwd(%rip)
    shlb %cl, -129
    shlw 0(%r9)
    shlw 64(%r9)
    shlw -2147483648(%r10)
    shlw 0(%r12)
    shlw 8(%r12)
    shlw 2147483647(%r12)
    shlw 0(%r12,%r15,2)
    shlw -128(%r13,%rsi,4)
    shlw 4660(%r15,%rcx,8)
    shlw %di
    shlw 0(%rbx)
    shlw 127(%rsi)
    shlw 128(%rdi)
    shlw 0(%rsp)
    shlw -1(%rsp)
    shlw -129(%rsp)
    shlw 0(%rax,%rax,1)
    shlw 64(%rsp,%rcx,2)
    shlw -2147483648(%rbp,%rdx,4)
    shlw gnu_back(%rip)
    shlw 2147483647
    shlw $255, 0(%r10)
    shlw $63, 8(%r11)
    shlw $7, 4660(%r13)
    shlw $0, 0(%r12)
    shlw $255, -128(%r12)
    shlw $63, 128(%r12)
    shlw $7, 0(%r14,%r9,8)
    shlw $0, 127(%r8,%rbp,1)
    shlw $255, -129(%r9,%r12,2)
    shlw $63, %bp
    shlw $7, 0(%rsi)
    shlw $0, -1(%rcx)
    shlw $255, -2147483648(%rdx)
    shlw $63, 0(%rsp)
    shlw $7, 64(%rsp)
    shlw $0, 2147483647(%rsp)
    shlw $255, 0(%rcx,%rbx,4)
    shlw $63, 8(%rsi,%rbp,8)
    shlw $7, 4660(%rdi,%rsi,1)
    shlw $0, gnu_fwd(%rip)
    shlw $255, 128
    shlw %cl, 0(%r11)
    shlw %cl, -128(%r14)
    shlw %cl, -129(%r15)
    shlw %cl, 0(%r12)
    shlw %cl, 127(%r12)
    shlw %cl, -2147483648(%r12)
    shlw %cl, 0(%r15,%rax,2)
    shlw %cl, -1(%r12,%r15,4)
    shlw %cl, 2147483647(%r13,%rsi,8)
    shlw %cl, %sp
    shlw %cl, 0(%rdi)
    shlw %cl, 64(%rbx)
    shlw %cl, 4660(%rbp)
    shlw %cl, 0(%rsp)
    shlw %cl, 8(%rsp)
    shlw %cl, 128(%rsp)
    shlw %cl, 0(%rdx,%rdi,1)
    shlw %cl, -128(%rax,%rax,2)
    shlw %cl, -129(%rcx,%rcx,4)
    shlw %cl, gnu_back(%rip)
    shlw %cl, -2147483648
    shll 0(%r14)
    shll 127(%r8)
    shll 2147483647(%r9)
    shll 0(%r12)
    shll -1(%r12)
    shll 4660(%r12)
    shll 0(%r8,%rcx,8)
    shll 64(%r15,%r9,1)
    shll 128(%r8,%rbp,2)
    shll %ecx
    shll 0(%rcx)
    shll 8(%rsi)
    shll -129(%rdi)
    shll 0(%rsp)
    shll -128(%rsp)
    shll -2147483648(%rsp)
    shll 0(%rbx,%rdx,4)
    shll 127(%rdx,%rbx,8)
    shll 2147483647(%rbx,%rbp,1)
    shll gnu_fwd(%rip)
    shll 4660
    shll $63, 0(%r15)
    shll $7, -1(%r10)
    shll $0, 128(%r11)
    shll $255, 0(%r12)
    shll $63, 64(%r12)
    shll $7, -129(%r12)
    shll $0, 0(%r9,%r12,2)
    shll $255, 8(%r9,%rax,4)
    shll $63, -2147483648(%r12,%r15,8)
    shll $7, %edx
g24:
    shll $0, 0(%rdx)
    shll $255, -128(%rcx)
    shll $63, 2147483647(%rdx)
    shll $7, 0(%rsp)
    shll $0, 127(%rsp)
    shll $255, 4660(%rsp)
    shll $63, 0(%rsp,%rsi,1)
    shll $7, -1(%rsp,%rdi,2)
    shll $0, 128(%rbp,%rax,4)
    shll $255, gnu_back(%rip)
    shll $63, -129
    shll %cl, 0(%r8)
    shll %cl, 64(%r13)
    shll %cl, -2147483648(%r14)
    shll %cl, 0(%r12)
    shll %cl, 8(%r12)
    shll %cl, 2147483647(%r12)
    shll %cl, 0(%r10,%rsi,8)
    shll %cl, -128(%r13,%rcx,1)
    shll %cl, 4660(%r15,%r9,2)
    shll %cl, %ebx
    shll %cl, 0(%rbx)
    shll %cl, 127(%rbx)
    shll %cl, 128(%rbp)
    shll %cl, 0(%rsp)
    shll %cl, -1(%rsp)
    shll %cl, -129(%rsp)
    shll %cl, 0(%rsi,%rcx,4)
    shll %cl, 64(%rsi,%rdx,8)
    shll %cl, -2147483648(%rdi,%rbx,1)
    shll %cl, gnu_fwd(%rip)
    shll %cl, 2147483647
    shlq 0(%rdi)
    shlq 8(%r10)
    shlq 4660(%rsi)
    shlq 0(%rsp)
    shlq -128(%r12)
    shlq 128(%rsp)
    shlq 0(%rax,%rbp,2)
    shlq 127(%rax,%r12,4)
    shlq -129(%r9,%rax,8)
    shlq gnu_back(%rip)
    shlq -2147483648
    shlq $7, 0(%r14)
    shlq $0, -1(%r11)
    shlq $255, 2147483647(%rdi)
    shlq $63, 0(%r12)
    shlq $7, 64(%rsp)
    shlq $0, 4660(%r12)
    shlq $255, 0(%r8,%r15,1)
    shlq $63, 8(%rsp,%rsi,2)
    shlq $7, 128(%r13,%rcx,4)
    shlq $0, gnu_fwd(%rip)
    shlq $255, -129
    shlq %cl, 0(%r15)
    shlq %cl, -128(%r14)
    shlq %cl, -2147483648(%r15)
    shlq %cl, 0(%rsp)
    shlq %cl, 127(%r12)
    shlq %cl, 2147483647(%rsp)
    shlq %cl, 0(%rcx,%r9,8)
    shlq %cl, -1(%rbp,%rbp,1)
    shlq %cl, 4660(%r12,%r12,2)
    shlq %cl, gnu_back(%rip)
    shlq %cl, 128
    shrb 0(%r9)
    shrb 64(%r15)
    shrb -129(%r8)
    shrb 0(%r12)
    shrb 8(%r12)
    shrb -2147483648(%r12)
    shrb 0(%r11,%rax,4)
    shrb -128(%r8,%r15,8)
    shrb 2147483647(%r9,%rsi,1)
    shrb %ah
    shrb 0(%rsi)
    shrb 127(%rsi)
    shrb 4660(%rdi)
    shrb 0(%rsp)
    shrb -1(%rsp)
    shrb 128(%rsp)
    shrb 0(%rdi,%rbp,2)
    shrb 64(%rax,%rsi,4)
    shrb -129(%rcx,%rdi,8)
    shrb gnu_fwd(%rip)
    shrb -2147483648
    shrb $63, 0(%r10)
    shrb $7, 8(%r9)
    shrb $0, 2147483647(%r10)
    shrb $255, 0(%r12)
    shrb $63, -128(%r12)
    shrb $7, 4660(%r12)
    shrb $0, 0(%r12,%rcx,1)
    shrb $255, 127(%r12,%r9,2)
    shrb $63, 128(%r13,%rbp,4)
    shrb $7, %cl
    shrb $0, 0(%rdi)
    shrb $255, -1(%rcx)
    shrb $63, -129(%rdx)
    shrb $7, 0(%rsp)
    shrb $0, 64(%rsp)
    shrb $255, -2147483648(%rsp)
    shrb $63, 0(%rax,%rax,8)
    shrb $7, 8(%rdx,%rcx,1)
    shrb $0, 2147483647(%rbx,%rdx,2)
    shrb $255, gnu_back(%rip)
    shrb $63, 4660
    shrb %cl, 0(%r11)
    shrb %cl, -128(%r11)
    shrb %cl, 128(%r13)
    shrb %cl, 0(%r12)
    shrb %cl, 127(%r12)
    shrb %cl, -129(%r12)
    shrb %cl, 0(%r14,%r12,4)
    shrb %cl, -1(%r15,%rax,8)
    shrb %cl, -2147483648(%r8,%r15,1)
    shrb %cl, %dl
    shrb %cl, 0(%rcx)
    shrb %cl, 64(%rbx)
    shrb %cl, 2147483647(%rbp)
    shrb %cl, 0(%rsp)
    shrb %cl, 8(%rsp)
    shrb %cl, 4660(%rsp)
    shrb %cl, 0(%rcx,%rbx,2)
    shrb %cl, -128(%rsp,%rbp,4)
    shrb %cl, 128(%rbp,%rsi,8)
    shrb %cl, gnu_fwd(%rip)
    shrb %cl, -129
    shrw 0(%r14)
    shrw 127(%r14)
    shrw -2147483648(%r15)
    shrw 0(%r12)
    shrw -1(%r12)
    shrw 2147483647(%r12)
    shrw 0(%r15,%rsi,1)
    shrw 64(%r9,%rcx,2)
    shrw 4660(%r12,%r9,4)
    shrw %si
    shrw 0(%rdx)
    shrw 8(%rsi)
    shrw 128(%rdi)
    shrw 0(%rsp)
    shrw -128(%rsp)
    shrw -129(%rsp)
    shrw 0(%rdx,%rdi,8)
    shrw 127(%rsi,%rax,1)
    shrw -2147483648(%rdi,%rcx,2)
    shrw gnu_back(%rip)
    shrw 2147483647
    shrw $7, 0(%r15)
    shrw $0, -1(%r8)
    shrw $255, 4660(%r9)
    shrw $63, 0(%r12)
    shrw $7, 64(%r12)
    shrw $0, 128(%r12)
    shrw $255, 0(%r8,%rbp,4)
    shrw $63, 8(%r13,%r12,8)
    shrw $7, -129(%r15,%rax,1)
    shrw $0, %di
    shrw $255, 0(%rbx)
    shrw $63, -128(%rcx)
    shrw $7, -2147483648(%rdx)
    shrw $0, 0(%rsp)
    shrw $255, 127(%rsp)
    shrw $63, 2147483647(%rsp)
    shrw $7, 0(%rbx,%rdx,2)
    shrw $0, -1(%rax,%rbx,4)
    shrw $255, 4660(%rcx,%rbp,8)
    shrw $63, gnu_fwd(%rip)
    shrw $7, 128
    shrw %cl, 0(%r8)
    shrw %cl, 64(%r10)
    shrw %cl, -129(%r11)
    shrw %cl, 0(%r12)
    shrw %cl, 8(%r12)
    shrw %cl, -2147483648(%r12)
    shrw %cl, 0(%r9,%r15,1)
    shrw %cl, -128(%r8,%rsi,2)
    shrw %cl, 2147483647(%r9,%rcx,4)
    shrw %cl, %bp
    shrw %cl, 0(%rsi)
    shrw %cl, 127(%rbx)
    shrw %cl, 4660(%rbp)
    shrw %cl, 0(%rsp)
    shrw %cl, -1(%rsp)
    shrw %cl, 128(%rsp)
    shrw %cl, 0(%rsp,%rsi,8)
    shrw %cl, 64(%rdx,%rdi,1)
    shrw %cl, -129(%rbx,%rax,2)
    shrw %cl, gnu_back(%rip)
    shrw %cl, -2147483648
    shrl 0(%r9)
    shrl 8(%r13)
    shrl 2147483647(%r14)
    shrl 0(%r12)
    shrl -128(%r12)
    shrl 4660(%r12)
    shrl 0(%r10,%r9,4)
    shrl 127(%r12,%rbp,8)
    shrl 128(%r13,%r12,1)
g25:
    shrl %esp
    shrl 0(%rdi)
    shrl -1(%rsi)
    shrl -129(%rdi)
    shrl 0(%rsp)
    shrl 64(%rsp)
    shrl -2147483648(%rsp)
    shrl 0(%rsi,%rcx,2)
    shrl 8(%rsp,%rdx,4)
    shrl 2147483647(%rbp,%rbx,8)
    shrl gnu_fwd(%rip)
    shrl 4660
    shrl $0, 0(%r10)
    shrl $255, -128(%r15)
    shrl $63, 128(%r8)
    shrl $7, 0(%r12)
    shrl $0, 127(%r12)
    shrl $255, -129(%r12)
    shrl $63, 0(%r11,%rax,1)
    shrl $7, -1(%r15,%r15,2)
    shrl $0, -2147483648(%r8,%rsi,4)
    shrl $255, %ecx
    shrl $63, 0(%rcx)
    shrl $7, 64(%rcx)
    shrl $0, 2147483647(%rdx)
    shrl $255, 0(%rsp)
    shrl $63, 8(%rsp)
    shrl $7, 4660(%rsp)
    shrl $0, 0(%rdi,%rbp,8)
    shrl $255, -128(%rsi,%rsi,1)
    shrl $63, 128(%rdi,%rdi,2)
    shrl $7, gnu_back(%rip)
    shrl $0, -129
    shrl %cl, 0(%r11)
    shrl %cl, 127(%r9)
    shrl %cl, -2147483648(%r10)
    shrl %cl, 0(%r12)
    shrl %cl, -1(%r12)
    shrl %cl, 2147483647(%r12)
    shrl %cl, 0(%r12,%rcx,4)
    shrl %cl, 64(%r9,%r9,8)
    shrl %cl, 4660(%r12,%rbp,1)
    shrl %cl, %edx
    shrl %cl, 0(%rdx)
    shrl %cl, 8(%rbx)
    shrl %cl, 128(%rbp)
    shrl %cl, 0(%rsp)
    shrl %cl, -128(%rsp)
    shrl %cl, -129(%rsp)
    shrl %cl, 0(%rax,%rax,2)
    shrl %cl, 127(%rax,%rcx,4)
    shrl %cl, -2147483648(%rcx,%rdx,8)
    shrl %cl, gnu_fwd(%rip)
    shrl %cl, 2147483647
    shrq 0(%rcx)
    shrq -1(%rcx)
    shrq 4660(%r8)
    shrq 0(%r12)
    shrq 64(%rsp)
    shrq 128(%r12)
    shrq 0(%r12,%r12,1)
    shrq 8(%rdi,%rax,2)
    shrq -129(%r15,%r15,4)
    shrq gnu_back(%rip)
    shrq -2147483648
    shrq $255, 0(%r8)
    shrq $63, -128(%rbp)
    shrq $7, 2147483647(%r13)
    shrq $0, 0(%rsp)
    shrq $255, 127(%r12)
    shrq $63, 4660(%rsp)
    shrq $7, 0(%rdx,%rsi,8)
    shrq $0, -1(%rax,%rcx,1)
    shrq $255, 128(%r9,%r9,2)
    shrq $63, gnu_fwd(%rip)
    shrq $7, -129
    shrq %cl, 0(%rdx)
    shrq %cl, 64(%rdx)
    shrq %cl, -2147483648(%r9)
    shrq %cl, 0(%r12)
    shrq %cl, 8(%rsp)
    shrq %cl, 2147483647(%r12)
    shrq %cl, 0(%r9,%rbp,4)
    shrq %cl, -128(%rsp,%r12,8)
    shrq %cl, 4660(%r13,%rax,1)
    shrq %cl, gnu_back(%rip)
    shrq %cl, 128
    sarb 0(%r14)
    sarb 127(%r11)
    sarb -129(%r13)
    sarb 0(%r12)
    sarb -1(%r12)
    sarb -2147483648(%r12)
    sarb 0(%r14,%r15,2)
    sarb 64(%r13,%rsi,4)
    sarb 2147483647(%r15,%rcx,8)
    sarb %bl
    sarb 0(%rbx)
    sarb 8(%rsi)
    sarb 4660(%rdi)
    sarb 0(%rsp)
    sarb -128(%rsp)
    sarb 128(%rsp)
    sarb 0(%rcx,%rbx,1)
    sarb 127(%rdx,%rbp,2)
    sarb -129(%rbx,%rsi,4)
    sarb gnu_fwd(%rip)
    sarb -2147483648
    sarb $0, 0(%r15)
    sarb $255, -1(%r14)
    sarb $63, 2147483647(%r15)
    sarb $7, 0(%r12)
    sarb $0, 64(%r12)
    sarb $255, 4660(%r12)
    sarb $63, 0(%r15,%r9,8)
    sarb $7, 8(%r8,%rbp,1)
    sarb $0, 128(%r9,%r12,2)
    sarb $255, %dh
    sarb $63, 0(%rsi)
    sarb $7, -128(%rcx)
    sarb $0, -129(%rdx)
    sarb $255, 0(%rsp)
    sarb $63, 127(%rsp)
    sarb $7, -2147483648(%rsp)
    sarb $0, 0(%rdx,%rdi,4)
    sarb $255, -1(%rsp,%rax,8)
    sarb $63, 2147483647(%rbp,%rcx,1)
    sarb $7, gnu_back(%rip)
    sarb $0, 4660
    sarb %cl, 0(%r8)
    sarb %cl, 64(%r8)
    sarb %cl, 128(%r9)
    sarb %cl, 0(%r12)
    sarb %cl, 8(%r12)
    sarb %cl, -129(%r12)
    sarb %cl, 0(%r8,%rax,2)
    sarb %cl, -128(%r12,%r15,4)
    sarb %cl, -2147483648(%r13,%rsi,8)
    sarb %cl, %bh
    sarb %cl, 0(%rdi)
    sarb %cl, 127(%rbx)
    sarb %cl, 2147483647(%rbp)
    sarb %cl, 0(%rsp)
    sarb %cl, -1(%rsp)
    sarb %cl, 4660(%rsp)
    sarb %cl, 0(%rbx,%rdx,1)
    sarb %cl, 64(%rsi,%rbx,2)
    sarb %cl, 128(%rdi,%rbp,4)
    sarb %cl, gnu_fwd(%rip)
    sarb %cl, -129
    sarw 0(%r9)
    sarw 8(%r10)
    sarw -2147483648(%r11)
    sarw 0(%r12)
    sarw -128(%r12)
    sarw 2147483647(%r12)
    sarw 0(%r9,%rcx,8)
    sarw 127(%r15,%r9,1)
    sarw 4660(%r8,%rbp,2)
    sarw %bx
    sarw 0(%rcx)
    sarw -1(%rsi)
    sarw 128(%rdi)
    sarw 0(%rsp)
    sarw 64(%rsp)
    sarw -129(%rsp)
    sarw 0(%rsp,%rsi,4)
    sarw 8(%rax,%rdi,8)
    sarw -2147483648(%rcx,%rax,1)
    sarw gnu_back(%rip)
    sarw 2147483647
    sarw $255, 0(%r10)
    sarw $63, -128(%r13)
    sarw $7, 4660(%r14)
    sarw $0, 0(%r12)
    sarw $255, 127(%r12)
    sarw $63, 128(%r12)
    sarw $7, 0(%r10,%r12,2)
    sarw $0, -1(%r9,%rax,4)
    sarw $255, -129(%r12,%r15,8)
    sarw $63, %si
    sarw $7, 0(%rdx)
    sarw $0, 64(%rcx)
    sarw $255, -2147483648(%rdx)
    sarw $63, 0(%rsp)
    sarw $7, 8(%rsp)
    sarw $0, 2147483647(%rsp)
    sarw $255, 0(%rsi,%rcx,1)
    sarw $63, -128(%rdx,%rdx,2)
    sarw $7, 4660(%rbx,%rbx,4)
    sarw $0, gnu_fwd(%rip)
    sarw $255, 128
    sarw %cl, 0(%r11)
    sarw %cl, 127(%r15)
    sarw %cl, -129(%r8)
    sarw %cl, 0(%r12)
    sarw %cl, -1(%r12)
    sarw %cl, -2147483648(%r12)
    sarw %cl, 0(%r11,%rsi,8)
    sarw %cl, 64(%r13,%rcx,1)
g26:
    sarw %cl, 2147483647(%r15,%r9,2)
    sarw %cl, %di
    sarw %cl, 0(%rbx)
    sarw %cl, 8(%rbx)
    sarw %cl, 4660(%rbp)
    sarw %cl, 0(%rsp)
    sarw %cl, -128(%rsp)
    sarw %cl, 128(%rsp)
    sarw %cl, 0(%rdi,%rbp,4)
    sarw %cl, 127(%rsp,%rsi,8)
    sarw %cl, -129(%rbp,%rdi,1)
    sarw %cl, gnu_back(%rip)
    sarw %cl, -2147483648
    sarl 0(%r14)
    sarl -1(%r9)
    sarl 2147483647(%r10)
    sarl 0(%r12)
    sarl 64(%r12)
    sarl 4660(%r12)
    sarl 0(%r12,%rbp,2)
    sarl 8(%r8,%r12,4)
    sarl 128(%r9,%rax,8)
    sarl %ebp
    sarl 0(%rsi)
    sarl -128(%rsi)
    sarl -129(%rdi)
    sarl 0(%rsp)
    sarl 127(%rsp)
    sarl -2147483648(%rsp)
    sarl 0(%rax,%rax,1)
    sarl -1(%rsi,%rcx,2)
    sarl 2147483647(%rdi,%rdx,4)
    sarl gnu_fwd(%rip)
    sarl 4660
    sarl $63, 0(%r15)
    sarl $7, 64(%r11)
    sarl $0, 128(%r13)
    sarl $255, 0(%r12)
    sarl $63, 8(%r12)
    sarl $7, -129(%r12)
    sarl $0, 0(%r14,%r15,8)
    sarl $255, -128(%r12,%rsi,1)
    sarl $63, -2147483648(%r13,%rcx,2)
    sarl $7, %esp
    sarl $0, 0(%rdi)
    sarl $255, 127(%rcx)
    sarl $63, 2147483647(%rdx)
    sarl $7, 0(%rsp)
    sarl $0, -1(%rsp)
    sarl $255, 4660(%rsp)
    sarl $63, 0(%rcx,%rbx,4)
    sarl $7, 64(%rax,%rbp,8)
    sarl $0, 128(%rcx,%rsi,1)
    sarl $255, gnu_back(%rip)
    sarl $63, -129
    sarl %cl, 0(%r8)
    sarl %cl, 8(%r14)
    sarl %cl, -2147483648(%r15)
    sarl %cl, 0(%r12)
    sarl %cl, -128(%r12)
    sarl %cl, 2147483647(%r12)
    sarl %cl, 0(%r15,%r9,2)
    sarl %cl, 127(%r15,%rbp,4)
    sarl %cl, 4660(%r8,%r12,8)
    sarl %cl, %ecx
    sarl %cl, 0(%rcx)
    sarl %cl, -1(%rbx)
    sarl %cl, 128(%rbp)
    sarl %cl, 0(%rsp)
    sarl %cl, 64(%rsp)
    sarl %cl, -129(%rsp)
    sarl %cl, 0(%rdx,%rdi,1)
    sarl %cl, 8(%rdx,%rax,2)
    sarl %cl, -2147483648(%rbx,%rcx,4)
    sarl %cl, gnu_fwd(%rip)
    sarl %cl, 2147483647
    sarq 0(%r9)
    sarq -128(%rbx)
    sarq 4660(%r10)
    sarq 0(%rsp)
    sarq 127(%r12)
    sarq 128(%rsp)
    sarq 0(%rsp,%rax,8)
    sarq -1(%rbp,%r15,1)
    sarq -129(%r12,%rsi,2)
    sarq gnu_back(%rip)
    sarq -2147483648
    sarq $7, 0(%rbx)
    sarq $0, 64(%rsi)
    sarq $255, 2147483647(%r11)
    sarq $63, 0(%r12)
    sarq $7, 8(%rsp)
    sarq $0, 4660(%r12)
    sarq $255, 0(%r14,%rcx,4)
    sarq $63, -128(%rdi,%r9,8)
    sarq $7, 128(%r15,%rbp,1)
    sarq $0, gnu_fwd(%rip)
    sarq $255, -129
    sarq %cl, 0(%r10)
    sarq %cl, 127(%rdi)
    sarq %cl, -2147483648(%r14)
    sarq %cl, 0(%rsp)
    sarq %cl, -1(%r12)
    sarq %cl, 2147483647(%rsp)
    sarq %cl, 0(%rsi,%r12,2)
    sarq %cl, 64(%rax,%rax,4)
    sarq %cl, 4660(%r9,%r15,8)
    sarq %cl, gnu_back(%rip)
    sarq %cl, 128
    bsfw 0(%rsi), %r11w
    bsfw 8(%r15), %r14w
    bsfw -129(%rcx), %r8w
    bsfw 0(%r12), %r12w
    bsfw -128(%rsp), %r13w
    bsfw -2147483648(%r12), %r15w
    bsfw 0(%r15,%rsi,1), %r9w
    bsfw 127(%rsp,%rcx,2), %r10w
    bsfw 2147483647(%r13,%r9,4), %r11w
    bsfw gnu_fwd(%rip), %r14w
    bsfw 4660, %r8w
    bsfw %dx, %bx
    bsfw 0(%rdx), %si
    bsfw -1(%rsi), %di
    bsfw 128(%rdi), %bp
    bsfw 0(%rsp), %sp
    bsfw 64(%rsp), %cx
    bsfw -129(%rsp), %dx
    bsfw 0(%rbx,%rdx,8), %bx
    bsfw 8(%rsp,%rbx,1), %si
    bsfw -2147483648(%rbp,%rbp,2), %di
    bsfw gnu_back(%rip), %bp
    bsfw 2147483647, %sp
    bsfl 0(%r11), %r12d
    bsfl -128(%r8), %r13d
    bsfl 4660(%rbp), %r15d
    bsfl 0(%rsp), %r9d
    bsfl 127(%r12), %r10d
    bsfl 128(%rsp), %r11d
    bsfl 0(%rax,%rbp,4), %r14d
    bsfl -1(%rbp,%r12,8), %r8d
    bsfl -129(%r12,%rax,1), %r12d
    bsfl gnu_fwd(%rip), %r13d
    bsfl -2147483648, %r15d
    bsfl %ecx, %edx
    bsfl 0(%rbx), %ebx
    bsfl 64(%rcx), %esi
    bsfl 2147483647(%rdx), %edi
    bsfl 0(%rsp), %ebp
    bsfl 8(%rsp), %esp
    bsfl 4660(%rsp), %ecx
    bsfl 0(%rsp,%rsi,2), %edx
    bsfl -128(%rsi,%rdi,4), %ebx
    bsfl 128(%rdi,%rax,8), %esi
    bsfl gnu_back(%rip), %edi
    bsfl -129, %ebp
    bsfq 0(%rdi), %r9
    bsfq 127(%r13), %r10
    bsfq -2147483648(%rdx), %r11
    bsfq 0(%r12), %r14
    bsfq -1(%rsp), %r8
    bsfq 2147483647(%r12), %r12
    bsfq 0(%r8,%r15,1), %r13
    bsfq 64(%rdi,%rsi,2), %r15
    bsfq 4660(%r15,%rcx,4), %r9
    bsfq gnu_fwd(%rip), %r10
    bsfq 128, %r11
    bsrw 0(%r14), %r14w
    bsrw 8(%r9), %r8w
    bsrw -129(%rbx), %r12w
    bsrw 0(%rsp), %r13w
    bsrw -128(%r12), %r15w
    bsrw -2147483648(%rsp), %r9w
    bsrw 0(%rcx,%r9,8), %r10w
    bsrw 127(%rax,%rbp,1), %r11w
    bsrw 2147483647(%r9,%r12,2), %r14w
    bsrw gnu_back(%rip), %r8w
    bsrw 4660, %r12w
    bsrw %sp, %cx
    bsrw 0(%rsi), %dx
    bsrw -1(%rbx), %bx
    bsrw 128(%rbp), %si
    bsrw 0(%rsp), %di
    bsrw 64(%rsp), %bp
    bsrw -129(%rsp), %sp
    bsrw 0(%rsi,%rcx,4), %cx
    bsrw 8(%rax,%rdx,8), %dx
    bsrw -2147483648(%rcx,%rbx,1), %bx
    bsrw gnu_fwd(%rip), %si
    bsrw 2147483647, %di
    bsrl 0(%r15), %r13d
    bsrl -128(%r10), %r15d
    bsrl 4660(%rsi), %r9d
    bsrl 0(%r12), %r10d
    bsrl 127(%rsp), %r11d
    bsrl 128(%r12), %r14d
    bsrl 0(%r12,%rax,2), %r8d
    bsrl -1(%rsp,%r15,4), %r12d
    bsrl -129(%r13,%rsi,8), %r13d
    bsrl gnu_back(%rip), %r15d
    bsrl -2147483648, %r9d
g27:
    bsrl %ebp, %esp
    bsrl 0(%rdi), %ecx
    bsrl 64(%rsi), %edx
    bsrl 2147483647(%rdi), %ebx
    bsrl 0(%rsp), %esi
    bsrl 8(%rsp), %edi
    bsrl 4660(%rsp), %ebp
    bsrl 0(%rdi,%rbp,1), %esp
    bsrl -128(%rdx,%rsi,2), %ecx
    bsrl 128(%rbx,%rdi,4), %edx
    bsrl gnu_fwd(%rip), %ebx
    bsrl -129, %esi
    bsrq 0(%rcx), %r10
    bsrq 127(%r11), %r11
    bsrq -2147483648(%rdi), %r14
    bsrq 0(%rsp), %r8
    bsrq -1(%r12), %r12
    bsrq 2147483647(%rsp), %r13
    bsrq 0(%rdx,%rcx,8), %r15
    bsrq 64(%rbp,%r9,1), %r9
    bsrq 4660(%r12,%rbp,2), %r10
    bsrq gnu_back(%rip), %r11
    bsrq 128, %r14
    popcntw 0(%r8), %r8w
    popcntw 8(%r14), %r12w
    popcntw -129(%r15), %r13w
    popcntw 0(%r12), %r15w
    popcntw -128(%rsp), %r9w
    popcntw -2147483648(%r12), %r10w
    popcntw 0(%r9,%r12,4), %r11w
    popcntw 127(%rdi,%rax,8), %r14w
    popcntw 2147483647(%r15,%r15,1), %r8w
    popcntw gnu_fwd(%rip), %r12w
    popcntw 4660, %r13w
    popcntw %di, %bp
    popcntw 0(%rcx), %sp
    popcntw -1(%rcx), %cx
    popcntw 128(%rdx), %dx
    popcntw 0(%rsp), %bx
    popcntw 64(%rsp), %si
    popcntw -129(%rsp), %di
    popcntw 0(%rax,%rax,2), %bp
    popcntw 8(%rsp,%rcx,4), %sp
    popcntw -2147483648(%rbp,%rdx,8), %cx
    popcntw gnu_back(%rip), %dx
    popcntw 2147483647, %bx
    popcntl 0(%rdx), %r15d
    popcntl -128(%rcx), %r9d
    popcntl 4660(%r8), %r10d
    popcntl 0(%rsp), %r11d
    popcntl 127(%r12), %r14d
    popcntl 128(%rsp), %r8d
    popcntl 0(%rsp,%rsi,1), %r12d
    popcntl -1(%rax,%rcx,2), %r13d
    popcntl -129(%r9,%r9,4), %r15d
    popcntl gnu_fwd(%rip), %r9d
    popcntl -2147483648, %r10d
    popcntl %esi, %edi
    popcntl 0(%rdx), %ebp
    popcntl 64(%rbx), %esp
    popcntl 2147483647(%rbp), %ecx
    popcntl 0(%rsp), %edx
    popcntl 8(%rsp), %ebx
    popcntl 4660(%rsp), %esi
    popcntl 0(%rcx,%rbx,8), %edi
    popcntl -128(%rsi,%rbp,1), %ebp
    popcntl 128(%rdi,%rsi,2), %esp
    popcntl gnu_back(%rip), %ecx
    popcntl -129, %edx
    popcntq 0(%r9), %r11
    popcntq 127(%rbp), %r14
    popcntq -2147483648(%r13), %r8
    popcntq 0(%r12), %r12
    popcntq -1(%rsp), %r13
    popcntq 2147483647(%r12), %r15
    popcntq 0(%r14,%rbp,4), %r9
    popcntq 64(%rsp,%r12,8), %r10
    popcntq 4660(%r13,%rax,1), %r11
    popcntq gnu_fwd(%rip), %r14
    popcntq 128, %r8
    lzcntw 0(%rbx), %r12w
    lzcntw 8(%rdx), %r13w
    lzcntw -129(%r9), %r15w
    lzcntw 0(%rsp), %r9w
    lzcntw -128(%r12), %r10w
    lzcntw -2147483648(%rsp), %r11w
    lzcntw 0(%rsi,%r15,2), %r14w
    lzcntw 127(%rbp,%rsi,4), %r8w
    lzcntw 2147483647(%r12,%rcx,8), %r12w
    lzcntw gnu_back(%rip), %r13w
    lzcntw 4660, %r15w
    lzcntw %bx, %si
    lzcntw 0(%rbx), %di
    lzcntw -1(%rsi), %bp
    lzcntw 128(%rdi), %sp
    lzcntw 0(%rsp), %cx
    lzcntw 64(%rsp), %dx
    lzcntw -129(%rsp), %bx
    lzcntw 0(%rdx,%rdi,1), %si
    lzcntw 8(%rax,%rax,2), %di
    lzcntw -2147483648(%rcx,%rcx,4), %bp
    lzcntw gnu_fwd(%rip), %sp
    lzcntw 2147483647, %cx
    lzcntl 0(%r10), %r9d
    lzcntl -128(%rbx), %r10d
    lzcntl 4660(%r10), %r11d
    lzcntl 0(%r12), %r14d
    lzcntl 127(%rsp), %r8d
    lzcntl 128(%r12), %r12d
    lzcntl 0(%r15,%r9,8), %r13d
    lzcntl -1(%rdi,%rbp,1), %r15d
    lzcntl -129(%r15,%r12,2), %r9d
    lzcntl gnu_back(%rip), %r10d
    lzcntl -2147483648, %r11d
    lzcntl %edx, %ebx
    lzcntl 0(%rsi), %esi
    lzcntl 64(%rcx), %edi
    lzcntl 2147483647(%rdx), %ebp
    lzcntl 0(%rsp), %esp
    lzcntl 8(%rsp), %ecx
    lzcntl 4660(%rsp), %edx
    lzcntl 0(%rbx,%rdx,4), %ebx
    lzcntl -128(%rdx,%rbx,8), %esi
    lzcntl 128(%rbx,%rbp,1), %edi
    lzcntl gnu_fwd(%rip), %ebp
    lzcntl -129, %esp
    lzcntq 0(%rsi), %r14
    lzcntq 127(%rsi), %r8
    lzcntq -2147483648(%r11), %r12
    lzcntq 0(%rsp), %r13
    lzcntq -1(%r12), %r15
    lzcntq 2147483647(%rsp), %r9
    lzcntq 0(%rax,%rax,2), %r10
    lzcntq 64(%rax,%r15,4), %r11
    lzcntq 4660(%r9,%rsi,8), %r14
    lzcntq gnu_back(%rip), %r8
    lzcntq 128, %r12
    tzcntw 0(%r11), %r13w
    tzcntw 8(%rdi), %r15w
    tzcntw -129(%r14), %r9w
    tzcntw 0(%r12), %r10w
    tzcntw -128(%rsp), %r11w
    tzcntw -2147483648(%r12), %r14w
    tzcntw 0(%r8,%rcx,1), %r8w
    tzcntw 127(%rsp,%r9,2), %r12w
    tzcntw 2147483647(%r13,%rbp,4), %r13w
    tzcntw gnu_fwd(%rip), %r15w
    tzcntw 4660, %r9w
    tzcntw %cx, %dx
    tzcntw 0(%rdi), %bx
    tzcntw -1(%rbx), %si
    tzcntw 128(%rbp), %di
    tzcntw 0(%rsp), %bp
    tzcntw 64(%rsp), %sp
    tzcntw -129(%rsp), %cx
    tzcntw 0(%rsp,%rsi,8), %dx
    tzcntw 8(%rsp,%rdi,1), %bx
    tzcntw -2147483648(%rbp,%rax,2), %si
    tzcntw gnu_back(%rip), %di
    tzcntw 2147483647, %bp
    tzcntl 0(%rdi), %r10d
    tzcntl -128(%r15), %r11d
    tzcntl 4660(%rcx), %r14d
    tzcntl 0(%rsp), %r8d
    tzcntl 127(%r12), %r12d
    tzcntl 128(%rsp), %r13d
    tzcntl 0(%rcx,%r12,4), %r15d
    tzcntl -1(%rbp,%rax,8), %r9d
    tzcntl -129(%r12,%r15,1), %r10d
    tzcntl gnu_fwd(%rip), %r11d
    tzcntl -2147483648, %r14d
    tzcntl %esp, %ecx
    tzcntl 0(%rcx), %edx
    tzcntl 64(%rsi), %ebx
    tzcntl 2147483647(%rdi), %esi
    tzcntl 0(%rsp), %edi
    tzcntl 8(%rsp), %ebp
    tzcntl 4660(%rsp), %esp
    tzcntl 0(%rsi,%rcx,2), %ecx
    tzcntl -128(%rsi,%rdx,4), %edx
    tzcntl 128(%rdi,%rbx,8), %ebx
    tzcntl gnu_back(%rip), %esi
    tzcntl -129, %edi
    tzcntq 0(%r14), %r8
    tzcntq 127(%r8), %r12
    tzcntq -2147483648(%rbp), %r13
    tzcntq 0(%r12), %r15
    tzcntq -1(%rsp), %r9
    tzcntq 2147483647(%r12), %r10
    tzcntq 0(%r12,%rsi,1), %r11
    tzcntq 64(%rdi,%rcx,2), %r14
    tzcntq 4660(%r15,%r9,4), %r8
    tzcntq gnu_fwd(%rip), %r12
    tzcntq 128, %r13
    btw %r15w, 0(%r15)
    btw %r9w, 8(%r13)
    btw %r10w, -129(%rdx)
    btw %r11w, 0(%rsp)
    btw %r14w, -128(%r12)
    btw %r8w, -2147483648(%rsp)
g28:
    btw %r12w, 0(%rdx,%rbp,8)
    btw %r13w, 127(%rax,%r12,1)
    btw %r15w, 2147483647(%r9,%rax,2)
    btw %r9w, gnu_back(%rip)
    btw %r10w, 4660
    btw %bp, %sp
    btw %cx, 0(%rdx)
    btw %dx, -1(%rcx)
    btw %bx, 128(%rdx)
    btw %si, 0(%rsp)
    btw %di, 64(%rsp)
    btw %bp, -129(%rsp)
    btw %sp, 0(%rdi,%rbp,4)
    btw %cx, 8(%rax,%rsi,8)
    btw %dx, -2147483648(%rcx,%rdi,1)
    btw %bx, gnu_fwd(%rip)
    btw %si, 2147483647
    btw $63, 0(%r9)
    btw $7, -128(%r8)
    btw $0, 4660(%r9)
    btw $255, 0(%r12)
    btw $63, 127(%r12)
    btw $7, 128(%r12)
    btw $0, 0(%r8,%r15,2)
    btw $255, -1(%r9,%rsi,4)
    btw $63, -129(%r12,%rcx,8)
    btw $7, %di
    btw $0, 0(%rbx)
    btw $255, 64(%rbx)
    btw $63, -2147483648(%rbp)
    btw $7, 0(%rsp)
    btw $0, 8(%rsp)
    btw $255, 2147483647(%rsp)
    btw $63, 0(%rax,%rax,1)
    btw $7, -128(%rdx,%rcx,2)
    btw $0, 4660(%rbx,%rdx,4)
    btw $255, gnu_back(%rip)
    btw $63, 128
    btl %r11d, 0(%rcx)
    btl %r14d, 127(%r9)
    btl %r8d, -129(%rbx)
    btl %r12d, 0(%r12)
    btl %r13d, -1(%rsp)
    btl %r15d, -2147483648(%r12)
    btl %r9d, 0(%r9,%r9,8)
    btl %r10d, 64(%rsp,%rbp,1)
    btl %r11d, 2147483647(%r13,%r12,2)
    btl %r14d, gnu_fwd(%rip)
    btl %r8d, 4660
    btl %ebp, %esp
    btl %ecx, 0(%rsi)
    btl %edx, 8(%rsi)
    btl %ebx, 128(%rdi)
    btl %esi, 0(%rsp)
    btl %edi, -128(%rsp)
    btl %ebp, -129(%rsp)
    btl %esp, 0(%rcx,%rbx,4)
    btl %ecx, 127(%rsp,%rbp,8)
    btl %edx, -2147483648(%rbp,%rsi,1)
    btl %ebx, gnu_back(%rip)
    btl %esi, 2147483647
    btl $7, 0(%r10)
    btl $0, -1(%r10)
    btl $255, 4660(%r11)
    btl $63, 0(%r12)
    btl $7, 64(%r12)
    btl $0, 128(%r12)
    btl $255, 0(%r9,%rax,2)
    btl $63, 8(%r13,%r15,4)
    btl $7, -129(%r15,%rsi,8)
    btl $0, %edi
    btl $255, 0(%rdi)
    btl $63, -128(%rcx)
    btl $7, -2147483648(%rdx)
    btl $0, 0(%rsp)
    btl $255, 127(%rsp)
    btl $63, 2147483647(%rsp)
    btl $7, 0(%rdx,%rdi,1)
    btl $0, -1(%rsi,%rax,2)
    btl $255, 4660(%rdi,%rcx,4)
    btl $63, gnu_fwd(%rip)
    btl $7, 128
    btq %r12, 0(%r8)
    btq %r13, 64(%r10)
    btq %r15, -129(%rsi)
    btq %r9, 0(%rsp)
    btq %r10, 8(%r12)
    btq %r11, -2147483648(%rsp)
    btq %r14, 0(%rsp,%rcx,8)
    btq %r8, -128(%rbp,%r9,1)
    btq %r12, 2147483647(%r12,%rbp,2)
    btq %r13, gnu_back(%rip)
    btq %r15, 4660
    btq $0, 0(%rdx)
    btq $255, 127(%r11)
    btq $63, 128(%rdi)
    btq $7, 0(%r12)
    btq $0, -1(%rsp)
    btq $255, -129(%r12)
    btq $63, 0(%r14,%r12,4)
    btq $7, 64(%rdi,%rax,8)
    btq $0, -2147483648(%r15,%r15,1)
    btq $255, gnu_fwd(%rip)
    btq $63, 2147483647
    btsw %r9w, 0(%r9)
    btsw %r10w, 8(%r14)
    btsw %r11w, 4660(%r15)
    btsw %r14w, 0(%rsp)
    btsw %r8w, -128(%r12)
    btsw %r12w, 128(%rsp)
    btsw %r13w, 0(%rsi,%rsi,2)
    btsw %r15w, 127(%rax,%rcx,4)
    btsw %r9w, -129(%r9,%r9,8)
    btsw %r10w, gnu_back(%rip)
    btsw %r11w, -2147483648
    btsw %bp, %sp
    btsw %cx, 0(%rcx)
    btsw %dx, -1(%rbx)
    btsw %bx, 2147483647(%rbp)
    btsw %si, 0(%rsp)
    btsw %di, 64(%rsp)
    btsw %bp, 4660(%rsp)
    btsw %sp, 0(%rbx,%rdx,1)
    btsw %cx, 8(%rax,%rbx,2)
    btsw %dx, 128(%rcx,%rbp,4)
    btsw %bx, gnu_fwd(%rip)
    btsw %si, -129
    btsw $7, 0(%r11)
    btsw $0, -128(%r13)
    btsw $255, -2147483648(%r14)
    btsw $63, 0(%r12)
    btsw $7, 127(%r12)
    btsw $0, 2147483647(%r12)
    btsw $255, 0(%r10,%rbp,8)
    btsw $63, -1(%r8,%r12,1)
    btsw $7, 4660(%r9,%rax,2)
    btsw $0, %di
    btsw $255, 0(%rdx)
    btsw $63, 64(%rsi)
    btsw $7, 128(%rdi)
    btsw $0, 0(%rsp)
    btsw $255, 8(%rsp)
    btsw $63, -129(%rsp)
    btsw $7, 0(%rsp,%rsi,4)
    btsw $0, -128(%rdx,%rdi,8)
    btsw $255, -2147483648(%rbx,%rax,1)
    btsw $63, gnu_back(%rip)
    btsw $7, 2147483647
    btsl %r14d, 0(%rbx)
    btsl %r8d, 127(%rcx)
    btsl %r12d, 4660(%r8)
    btsl %r13d, 0(%r12)
    btsl %r15d, -1(%rsp)
    btsl %r9d, 128(%r12)
    btsl %r10d, 0(%r15,%r15,2)
    btsl %r11d, 64(%rsp,%rsi,4)
    btsl %r14d, -129(%r13,%rcx,8)
    btsl %r8d, gnu_fwd(%rip)
    btsl %r12d, -2147483648
    btsl %ebp, %esp
    btsl %ecx, 0(%rbx)
    btsl %edx, 8(%rcx)
    btsl %ebx, 2147483647(%rdx)
    btsl %esi, 0(%rsp)
    btsl %edi, -128(%rsp)
    btsl %ebp, 4660(%rsp)
    btsl %esp, 0(%rsi,%rcx,1)
    btsl %ecx, 127(%rsp,%rdx,2)
    btsl %edx, 128(%rbp,%rbx,4)
    btsl %ebx, gnu_back(%rip)
    btsl %esi, -129
    btsl $0, 0(%r14)
    btsl $255, -1(%r15)
    btsl $63, -2147483648(%r8)
    btsl $7, 0(%r12)
    btsl $0, 64(%r12)
    btsl $255, 2147483647(%r12)
    btsl $63, 0(%r11,%r9,8)
    btsl $7, 8(%r12,%rbp,1)
    btsl $0, 4660(%r13,%r12,2)
    btsl $255, %edi
    btsl $63, 0(%rsi)
    btsl $7, -128(%rbx)
    btsl $0, 128(%rbp)
    btsl $255, 0(%rsp)
    btsl $63, 127(%rsp)
    btsl $7, -129(%rsp)
    btsl $0, 0(%rdi,%rbp,4)
    btsl $255, -1(%rsi,%rsi,8)
    btsl $63, -2147483648(%rdi,%rdi,1)
    btsl $7, gnu_fwd(%rip)
    btsl $0, 2147483647
    btsq %r13, 0(%r10)
    btsq %r15, 64(%rbp)
    btsq %r9, 4660(%r13)
    btsq %r10, 0(%rsp)
    btsq %r11, 8(%r12)
    btsq %r14, 128(%rsp)
    btsq %r8, 0(%rax,%rax,2)
    btsq %r12, -128(%rbp,%r15,4)
g29:
    btsq %r13, -129(%r12,%rsi,8)
    btsq %r15, gnu_back(%rip)
    btsq %r9, -2147483648
    btsq $255, 0(%rsi)
    btsq $63, 127(%rdx)
    btsq $7, 2147483647(%r9)
    btsq $0, 0(%r12)
    btsq $255, -1(%rsp)
    btsq $63, 4660(%r12)
    btsq $7, 0(%r8,%rcx,1)
    btsq $0, 64(%rdi,%r9,2)
    btsq $255, 128(%r15,%rbp,4)
    btsq $63, gnu_fwd(%rip)
    btsq $7, -129
    btrw %r10w, 0(%r11)
    btrw %r11w, 8(%rbx)
    btrw %r14w, -2147483648(%r10)
    btrw %r8w, 0(%rsp)
    btrw %r12w, -128(%r12)
    btrw %r13w, 2147483647(%rsp)
    btrw %r15w, 0(%rcx,%r12,8)
    btrw %r9w, 127(%rax,%rax,1)
    btrw %r10w, 4660(%r9,%r15,2)
    btrw %r11w, gnu_back(%rip)
    btrw %r14w, 128
    btrw %bp, %sp
    btrw %cx, 0(%rdi)
    btrw %dx, -1(%rsi)
    btrw %bx, -129(%rdi)
    btrw %si, 0(%rsp)
    btrw %di, 64(%rsp)
    btrw %bp, -2147483648(%rsp)
    btrw %sp, 0(%rax,%rax,4)
    btrw %cx, 8(%rax,%rcx,8)
    btrw %dx, 2147483647(%rcx,%rdx,1)
    btrw %bx, gnu_fwd(%rip)
    btrw %si, 4660
    btrw $0, 0(%r15)
    btrw $255, -128(%r9)
    btrw $63, 128(%r10)
    btrw $7, 0(%r12)
    btrw $0, 127(%r12)
    btrw $255, -129(%r12)
    btrw $63, 0(%r12,%rsi,2)
    btrw $7, -1(%r15,%rcx,4)
    btrw $0, -2147483648(%r8,%r9,8)
    btrw $255, %di
    btrw $63, 0(%rcx)
    btrw $7, 64(%rcx)
    btrw $0, 2147483647(%rdx)
    btrw $255, 0(%rsp)
    btrw $63, 8(%rsp)
    btrw $7, 4660(%rsp)
    btrw $0, 0(%rcx,%rbx,1)
    btrw $255, -128(%rdx,%rbp,2)
    btrw $63, 128(%rbx,%rsi,4)
    btrw $7, gnu_back(%rip)
    btrw $0, -129
    btrl %r8d, 0(%rdi)
    btrl %r12d, 127(%rsi)
    btrl %r13d, -2147483648(%r11)
    btrl %r15d, 0(%r12)
    btrl %r9d, -1(%rsp)
    btrl %r10d, 2147483647(%r12)
    btrl %r11d, 0(%r12,%rbp,8)
    btrl %r14d, 64(%rsp,%r12,1)
    btrl %r8d, 4660(%r13,%rax,2)
    btrl %r12d, gnu_fwd(%rip)
    btrl %r13d, 128
    btrl %ebp, %esp
    btrl %ecx, 0(%rdx)
    btrl %edx, 8(%rbx)
    btrl %ebx, -129(%rbp)
    btrl %esi, 0(%rsp)
    btrl %edi, -128(%rsp)
    btrl %ebp, -2147483648(%rsp)
    btrl %esp, 0(%rdx,%rdi,4)
    btrl %ecx, 127(%rsp,%rax,8)
    btrl %edx, 2147483647(%rbp,%rcx,1)
    btrl %ebx, gnu_back(%rip)
    btrl %esi, 4660
    btrl $255, 0(%r8)
    btrl $63, -1(%r11)
    btrl $7, 128(%r13)
    btrl $0, 0(%r12)
    btrl $255, 64(%r12)
    btrl $63, -129(%r12)
    btrl $7, 0(%r14,%r15,2)
    btrl $0, 8(%r9,%rsi,4)
    btrl $255, -2147483648(%r12,%rcx,8)
    btrl $63, %edi
    btrl $7, 0(%rbx)
    btrl $0, -128(%rsi)
    btrl $255, 2147483647(%rdi)
    btrl $63, 0(%rsp)
    btrl $7, 127(%rsp)
    btrl $0, 4660(%rsp)
    btrl $255, 0(%rbx,%rdx,1)
    btrl $63, -1(%rsi,%rbx,2)
    btrl $7, 128(%rdi,%rbp,4)
    btrl $0, gnu_fwd(%rip)
    btrl $255, -129
    btrq %r15, 0(%r14)
    btrq %r9, 64(%rdi)
    btrq %r10, -2147483648(%r14)
    btrq %r11, 0(%rsp)
    btrq %r14, 8(%r12)
    btrq %r8, 2147483647(%rsp)
    btrq %r12, 0(%rdx,%r9,8)
    btrq %r13, -128(%rbp,%rbp,1)
    btrq %r15, 4660(%r12,%r12,2)
    btrq %r9, gnu_back(%rip)
    btrq %r10, 128
    btrq $63, 0(%r15)
    btrq $7, 127(%r15)
    btrq $0, -129(%rcx)
    btrq $255, 0(%r12)
    btrq $63, -1(%rsp)
    btrq $7, -2147483648(%r12)
    btrq $0, 0(%r9,%rax,4)
    btrq $255, 64(%rdi,%r15,8)
    btrq $63, 2147483647(%r15,%rsi,1)
    btrq $7, gnu_fwd(%rip)
    btrq $0, 4660
    btcw %r11w, 0(%rcx)
    btcw %r14w, 8(%r8)
    btcw %r8w, 128(%rbp)
    btcw %r12w, 0(%rsp)
    btcw %r13w, -128(%r12)
    btcw %r15w, -129(%rsp)
    btcw %r9w, 0(%rsp,%rcx,2)
    btcw %r10w, 127(%rax,%r9,4)
    btcw %r11w, -2147483648(%r9,%rbp,8)
    btcw %r14w, gnu_back(%rip)
    btcw %r8w, 2147483647
    btcw %bp, %sp
    btcw %cx, 0(%rsi)
    btcw %dx, -1(%rcx)
    btcw %bx, 4660(%rdx)
    btcw %si, 0(%rsp)
    btcw %di, 64(%rsp)
    btcw %bp, 128(%rsp)
    btcw %sp, 0(%rsp,%rsi,1)
    btcw %cx, 8(%rax,%rdi,2)
    btcw %dx, -129(%rcx,%rax,4)
    btcw %bx, gnu_fwd(%rip)
    btcw %si, -2147483648
    btcw $255, 0(%r9)
    btcw $63, -128(%r14)
    btcw $7, 2147483647(%r15)
    btcw $0, 0(%r12)
    btcw $255, 127(%r12)
    btcw $63, 4660(%r12)
    btcw $7, 0(%r15,%r12,8)
    btcw $0, -1(%r13,%rax,1)
    btcw $255, 128(%r15,%r15,2)
    btcw $63, %di
    btcw $7, 0(%rdi)
    btcw $0, 64(%rbx)
    btcw $255, -129(%rbp)
    btcw $63, 0(%rsp)
    btcw $7, 8(%rsp)
    btcw $0, -2147483648(%rsp)
    btcw $255, 0(%rsi,%rcx,4)
    btcw $63, -128(%rdx,%rdx,8)
    btcw $7, 2147483647(%rbx,%rbx,1)
    btcw $0, gnu_back(%rip)
    btcw $255, 4660
    btcl %r12d, 0(%r8)
    btcl %r13d, 127(%r13)
    btcl %r15d, 128(%rdx)
    btcl %r9d, 0(%r12)
    btcl %r10d, -1(%rsp)
    btcl %r11d, -129(%r12)
    btcl %r14d, 0(%r14,%rsi,2)
    btcl %r8d, 64(%rsp,%rcx,4)
    btcl %r12d, -2147483648(%r13,%r9,8)
    btcl %r13d, gnu_fwd(%rip)
    btcl %r15d, 2147483647
    btcl %ebp, %esp
    btcl %ecx, 0(%rcx)
    btcl %edx, 8(%rsi)
    btcl %ebx, 4660(%rdi)
    btcl %esi, 0(%rsp)
    btcl %edi, -128(%rsp)
    btcl %ebp, 128(%rsp)
    btcl %esp, 0(%rdi,%rbp,1)
    btcl %ecx, 127(%rsp,%rsi,2)
    btcl %edx, -129(%rbp,%rdi,4)
    btcl %ebx, gnu_back(%rip)
    btcl %esi, -2147483648
    btcl $63, 0(%r10)
    btcl $7, -1(%r8)
    btcl $0, 2147483647(%r9)
    btcl $255, 0(%r12)
    btcl $63, 64(%r12)
    btcl $7, 4660(%r12)
    btcl $0, 0(%r8,%rbp,8)
    btcl $255, 8(%r8,%r12,1)
    btcl $63, 128(%r9,%rax,2)
g30:
    btcl $7, %edi
    btcl $0, 0(%rdx)
    btcl $255, -128(%rcx)
    btcl $63, -129(%rdx)
    btcl $7, 0(%rsp)
    btcl $0, 127(%rsp)
    btcl $255, -2147483648(%rsp)
    btcl $63, 0(%rax,%rax,4)
    btcl $7, -1(%rsi,%rcx,8)
    btcl $0, 2147483647(%rdi,%rdx,1)
    btcl $255, gnu_fwd(%rip)
    btcl $63, 4660
    btcq %r9, 0(%rdx)
    btcq %r10, 64(%r9)
    btcq %r11, 128(%rbx)
    btcq %r14, 0(%rsp)
    btcq %r8, 8(%r12)
    btcq %r12, -129(%rsp)
    btcq %r13, 0(%rsi,%r15,2)
    btcq %r15, -128(%rbp,%rsi,4)
    btcq %r9, -2147483648(%r12,%rcx,8)
    btcq %r10, gnu_back(%rip)
    btcq %r11, 2147483647
    btcq $7, 0(%r9)
    btcq $0, 127(%r10)
    btcq $255, 4660(%rsi)
    btcq $63, 0(%r12)
    btcq $7, -1(%rsp)
    btcq $0, 128(%r12)
    btcq $255, 0(%r15,%r9,1)
    btcq $63, 64(%rdi,%rbp,2)
    btcq $7, -129(%r15,%r12,4)
    btcq $0, gnu_fwd(%rip)
    btcq $255, -2147483648
    bswapl %ebp
    seto 0(%r11)
    seto 8(%r10)
    seto 2147483647(%r11)
    seto 0(%r12)
    seto -128(%r12)
    seto 4660(%r12)
    seto 0(%r9,%rax,8)
    seto 127(%r12,%r15,1)
    seto 128(%r13,%rsi,2)
    seto %ch
    seto 0(%rbx)
    seto -1(%rbx)
    seto -129(%rbp)
    seto 0(%rsp)
    seto 64(%rsp)
    seto -2147483648(%rsp)
    seto 0(%rcx,%rbx,4)
    seto 8(%rax,%rbp,8)
    seto 2147483647(%rcx,%rsi,1)
    seto gnu_back(%rip)
    seto 4660
    cmovow 0(%rbx), %r14w
    cmovow -128(%r11), %r8w
    cmovow 128(%rdi), %r12w
    cmovow 0(%rsp), %r13w
    cmovow 127(%r12), %r15w
    cmovow -129(%rsp), %r9w
    cmovow 0(%rax,%rcx,2), %r10w
    cmovow -1(%rax,%r9,4), %r11w
    cmovow -2147483648(%r9,%rbp,8), %r14w
    cmovow gnu_fwd(%rip), %r8w
    cmovow 2147483647, %r12w
    cmovow %sp, %cx
    cmovow 0(%rsi), %dx
    cmovow 64(%rsi), %bx
    cmovow 4660(%rdi), %si
    cmovow 0(%rsp), %di
    cmovow 8(%rsp), %bp
    cmovow 128(%rsp), %sp
    cmovow 0(%rdx,%rdi,1), %cx
    cmovow -128(%rdx,%rax,2), %dx
    cmovow -129(%rbx,%rcx,4), %bx
    cmovow gnu_back(%rip), %si
    cmovow -2147483648, %di
    cmovol 0(%r10), %r13d
    cmovol 127(%r14), %r15d
    cmovol 2147483647(%r15), %r9d
    cmovol 0(%r12), %r10d
    cmovol -1(%rsp), %r11d
    cmovol 4660(%r12), %r14d
    cmovol 0(%r8,%r12,8), %r8d
    cmovol 64(%rsp,%rax,1), %r12d
    cmovol 128(%r13,%r15,2), %r13d
    cmovol gnu_fwd(%rip), %r15d
    cmovol -129, %r9d
    cmovol %ebp, %esp
    cmovol 0(%rdi), %ecx
    cmovol 8(%rcx), %edx
    cmovol -2147483648(%rdx), %ebx
    cmovol 0(%rsp), %esi
    cmovol -128(%rsp), %edi
    cmovol 2147483647(%rsp), %ebp
    cmovol 0(%rbx,%rdx,4), %esp
    cmovol 127(%rsp,%rbx,8), %ecx
    cmovol 4660(%rbp,%rbp,1), %edx
    cmovol gnu_back(%rip), %ebx
    cmovol 128, %esi
    cmovoq 0(%rsi), %r10
    cmovoq -1(%rcx), %r11
    cmovoq -129(%r8), %r14
    cmovoq 0(%rsp), %r8
    cmovoq 64(%r12), %r12
    cmovoq -2147483648(%rsp), %r13
    cmovoq 0(%rcx,%rsi,2), %r15
    cmovoq 8(%rbp,%rcx,4), %r9
    cmovoq 2147483647(%r12,%r9,8), %r10
    cmovoq gnu_fwd(%rip), %r11
    cmovoq 4660, %r14
    setno 0(%r14)
    setno -128(%r13)
    setno 128(%r14)
    setno 0(%r12)
    setno 127(%r12)
    setno -129(%r12)
    setno 0(%r10,%rbp,1)
    setno -1(%r15,%r12,2)
    setno -2147483648(%r8,%rax,4)
    setno %ah
    setno 0(%rcx)
    setno 64(%rbx)
    setno 2147483647(%rbp)
    setno 0(%rsp)
    setno 8(%rsp)
    setno 4660(%rsp)
    setno 0(%rsp,%rsi,8)
    setno -128(%rsi,%rdi,1)
    setno 128(%rdi,%rax,2)
    setno gnu_back(%rip)
    setno -129
    cmovnow 0(%r11), %r8w
    cmovnow 127(%rbp), %r12w
    cmovnow -2147483648(%r13), %r13w
    cmovnow 0(%r12), %r15w
    cmovnow -1(%rsp), %r9w
    cmovnow 2147483647(%r12), %r10w
    cmovnow 0(%r12,%r15,4), %r11w
    cmovnow 64(%rdi,%rsi,8), %r14w
    cmovnow 4660(%r15,%rcx,1), %r8w
    cmovnow gnu_fwd(%rip), %r12w
    cmovnow 128, %r13w
    cmovnow %di, %bp
    cmovnow 0(%rdx), %sp
    cmovnow 8(%rsi), %cx
    cmovnow -129(%rdi), %dx
    cmovnow 0(%rsp), %bx
    cmovnow -128(%rsp), %si
    cmovnow -2147483648(%rsp), %di
    cmovnow 0(%rsi,%rcx,2), %bp
    cmovnow 127(%rax,%rdx,4), %sp
    cmovnow 2147483647(%rcx,%rbx,8), %cx
    cmovnow gnu_back(%rip), %dx
    cmovnow 4660, %bx
    cmovnol 0(%rdi), %r15d
    cmovnol -1(%rdx), %r9d
    cmovnol 128(%r9), %r10d
    cmovnol 0(%rsp), %r11d
    cmovnol 64(%r12), %r14d
    cmovnol -129(%rsp), %r8d
    cmovnol 0(%rdx,%r9,1), %r12d
    cmovnol 8(%rax,%rbp,2), %r13d
    cmovnol -2147483648(%r9,%r12,4), %r15d
    cmovnol gnu_fwd(%rip), %r9d
    cmovnol 2147483647, %r10d
    cmovnol %esi, %edi
    cmovnol 0(%rbx), %ebp
    cmovnol -128(%rcx), %esp
    cmovnol 4660(%rdx), %ecx
    cmovnol 0(%rsp), %edx
    cmovnol 127(%rsp), %ebx
    cmovnol 128(%rsp), %esi
    cmovnol 0(%rdi,%rbp,8), %edi
    cmovnol -1(%rdx,%rsi,1), %ebp
    cmovnol -129(%rbx,%rdi,2), %esp
    cmovnol gnu_back(%rip), %ecx
    cmovnol -2147483648, %edx
    cmovnoq 0(%r14), %r11
    cmovnoq 64(%rbx), %r14
    cmovnoq 2147483647(%r10), %r8
    cmovnoq 0(%r12), %r12
    cmovnoq 8(%rsp), %r13
    cmovnoq 4660(%r12), %r15
    cmovnoq 0(%r9,%rax,4), %r9
    cmovnoq -128(%rsp,%r15,8), %r10
    cmovnoq 128(%r13,%rsi,1), %r11
    cmovnoq gnu_fwd(%rip), %r14
    cmovnoq -129, %r8
    setb 0(%r15)
    setb 127(%r15)
    setb -2147483648(%r8)
    setb 0(%r12)
    setb -1(%r12)
    setb 2147483647(%r12)
    setb 0(%r11,%rcx,2)
    setb 64(%r9,%r9,4)
    setb 4660(%r12,%rbp,8)
g31:
    setb %cl
    setb 0(%rsi)
    setb 8(%rbx)
    setb 128(%rbp)
    setb 0(%rsp)
    setb -128(%rsp)
    setb -129(%rsp)
    setb 0(%rax,%rax,1)
    setb 127(%rsp,%rcx,2)
    setb -2147483648(%rbp,%rdx,4)
    setb gnu_back(%rip)
    setb 2147483647
    cmovbw 0(%r15), %r12w
    cmovbw -1(%rsi), %r13w
    cmovbw 4660(%r11), %r15w
    cmovbw 0(%rsp), %r9w
    cmovbw 64(%r12), %r10w
    cmovbw 128(%rsp), %r11w
    cmovbw 0(%rsp,%r12,8), %r14w
    cmovbw 8(%rbp,%rax,1), %r8w
    cmovbw -129(%r12,%r15,2), %r12w
    cmovbw gnu_fwd(%rip), %r13w
    cmovbw -2147483648, %r15w
    cmovbw %bx, %si
    cmovbw 0(%rdi), %di
    cmovbw -128(%rsi), %bp
    cmovbw 2147483647(%rdi), %sp
    cmovbw 0(%rsp), %cx
    cmovbw 127(%rsp), %dx
    cmovbw 4660(%rsp), %bx
    cmovbw 0(%rcx,%rbx,4), %si
    cmovbw -1(%rsi,%rbp,8), %di
    cmovbw 128(%rdi,%rsi,1), %bp
    cmovbw gnu_back(%rip), %sp
    cmovbw -129, %cx
    cmovbl 0(%rcx), %r9d
    cmovbl 64(%rdi), %r10d
    cmovbl -2147483648(%r14), %r11d
    cmovbl 0(%r12), %r14d
    cmovbl 8(%rsp), %r8d
    cmovbl 2147483647(%r12), %r12d
    cmovbl 0(%r14,%rsi,2), %r13d
    cmovbl -128(%rdi,%rcx,4), %r15d
    cmovbl 4660(%r15,%r9,8), %r9d
    cmovbl gnu_fwd(%rip), %r10d
    cmovbl 128, %r11d
    cmovbl %edx, %ebx
    cmovbl 0(%rcx), %esi
    cmovbl 127(%rcx), %edi
    cmovbl -129(%rdx), %ebp
    cmovbl 0(%rsp), %esp
    cmovbl -1(%rsp), %ecx
    cmovbl -2147483648(%rsp), %edx
    cmovbl 0(%rdx,%rdi,1), %ebx
    cmovbl 64(%rax,%rax,2), %esi
    cmovbl 2147483647(%rcx,%rcx,4), %edi
    cmovbl gnu_back(%rip), %ebp
    cmovbl 4660, %esp
    cmovbq 0(%r8), %r14
    cmovbq 8(%r15), %r8
    cmovbq 128(%rcx), %r12
    cmovbq 0(%rsp), %r13
    cmovbq -128(%r12), %r15
    cmovbq -129(%rsp), %r9
    cmovbq 0(%rsi,%rbp,8), %r10
    cmovbq 127(%rax,%r12,1), %r11
    cmovbq -2147483648(%r9,%rax,2), %r14
    cmovbq gnu_fwd(%rip), %r8
    cmovbq 2147483647, %r12
    setae 0(%r8)
    setae -1(%r9)
    setae 4660(%r10)
    setae 0(%r12)
    setae 64(%r12)
    setae 128(%r12)
    setae 0(%r12,%r15,4)
    setae 8(%r13,%rsi,8)
    setae -129(%r15,%rcx,1)
    setae %dl
    setae 0(%rdx)
    setae -128(%rbx)
    setae -2147483648(%rbp)
    setae 0(%rsp)
    setae 127(%rsp)
    setae 2147483647(%rsp)
    setae 0(%rbx,%rdx,2)
    setae -1(%rdx,%rbx,4)
    setae 4660(%rbx,%rbp,8)
    setae gnu_back(%rip)
    setae 128
    cmovaew 0(%rdx), %r13w
    cmovaew 64(%r8), %r15w
    cmovaew -129(%rbp), %r9w
    cmovaew 0(%r12), %r10w
    cmovaew 8(%rsp), %r11w
    cmovaew -2147483648(%r12), %r14w
    cmovaew 0(%r15,%r9,1), %r8w
    cmovaew -128(%rsp,%rbp,2), %r12w
    cmovaew 2147483647(%r13,%r12,4), %r13w
    cmovaew gnu_fwd(%rip), %r15w
    cmovaew 4660, %r9w
    cmovaew %cx, %dx
    cmovaew 0(%rbx), %bx
    cmovaew 127(%rsi), %si
    cmovaew 128(%rdi), %di
    cmovaew 0(%rsp), %bp
    cmovaew -1(%rsp), %sp
    cmovaew -129(%rsp), %cx
    cmovaew 0(%rsp,%rsi,8), %dx
    cmovaew 64(%rsp,%rdi,1), %bx
    cmovaew -2147483648(%rbp,%rax,2), %si
    cmovaew gnu_back(%rip), %di
    cmovaew 2147483647, %bp
    cmovael 0(%r9), %r10d
    cmovael 8(%r13), %r11d
    cmovael 4660(%rdx), %r14d
    cmovael 0(%rsp), %r8d
    cmovael -128(%r12), %r12d
    cmovael 128(%rsp), %r13d
    cmovael 0(%rax,%rax,4), %r15d
    cmovael 127(%rbp,%r15,8), %r9d
    cmovael -129(%r12,%rsi,1), %r10d
    cmovael gnu_fwd(%rip), %r11d
    cmovael -2147483648, %r14d
    cmovael %esp, %ecx
    cmovael 0(%rsi), %edx
    cmovael -1(%rcx), %ebx
    cmovael 2147483647(%rdx), %esi
    cmovael 0(%rsp), %edi
    cmovael 64(%rsp), %ebp
    cmovael 4660(%rsp), %esp
    cmovael 0(%rsi,%rcx,2), %ecx
    cmovael 8(%rsi,%rdx,4), %edx
    cmovael 128(%rdi,%rbx,8), %ebx
    cmovael gnu_back(%rip), %esi
    cmovael -129, %edi
    cmovaeq 0(%rbx), %r8
    cmovaeq -128(%r9), %r12
    cmovaeq -2147483648(%rbx), %r13
    cmovaeq 0(%r12), %r15
    cmovaeq 127(%rsp), %r9
    cmovaeq 2147483647(%r12), %r10
    cmovaeq 0(%r8,%rcx,1), %r11
    cmovaeq -1(%rdi,%r9,2), %r14
    cmovaeq 4660(%r15,%rbp,4), %r8
    cmovaeq gnu_fwd(%rip), %r12
    cmovaeq 128, %r13
    sete 0(%r9)
    sete 64(%r11)
    sete -129(%r13)
    sete 0(%r12)
    sete 8(%r12)
    sete -2147483648(%r12)
    sete 0(%r14,%r12,8)
    sete -128(%r8,%rax,1)
    sete 2147483647(%r9,%r15,2)
    sete %bl
    sete 0(%rdi)
    sete 127(%rbx)
    sete 4660(%rbp)
    sete 0(%rsp)
    sete -1(%rsp)
    sete 128(%rsp)
    sete 0(%rdi,%rbp,4)
    sete 64(%rax,%rsi,8)
    sete -129(%rcx,%rdi,1)
    sete gnu_back(%rip)
    sete -2147483648
    cmovew 0(%r10), %r15w
    cmovew 8(%r10), %r9w
    cmovew 2147483647(%rsi), %r10w
    cmovew 0(%rsp), %r11w
    cmovew -128(%r12), %r14w
    cmovew 4660(%rsp), %r8w
    cmovew 0(%rcx,%rsi,2), %r12w
    cmovew 127(%rax,%rcx,4), %r13w
    cmovew 128(%r9,%r9,8), %r15w
    cmovew gnu_fwd(%rip), %r9w
    cmovew -129, %r10w
    cmovew %bp, %sp
    cmovew 0(%rcx), %cx
    cmovew -1(%rsi), %dx
    cmovew -2147483648(%rdi), %bx
    cmovew 0(%rsp), %si
    cmovew 64(%rsp), %di
    cmovew 2147483647(%rsp), %bp
    cmovew 0(%rax,%rax,1), %sp
    cmovew 8(%rdx,%rcx,2), %cx
    cmovew 4660(%rbx,%rdx,4), %dx
    cmovew gnu_back(%rip), %bx
    cmovew 128, %si
    cmovel 0(%rsi), %r11d
    cmovel -128(%r11), %r14d
    cmovel -129(%rdi), %r8d
    cmovel 0(%r12), %r12d
    cmovel 127(%rsp), %r13d
    cmovel -2147483648(%r12), %r15d
    cmovel 0(%r12,%rbp,8), %r9d
    cmovel -1(%rsp,%r12,1), %r10d
    cmovel 2147483647(%r13,%rax,2), %r11d
g32:
    cmovel gnu_fwd(%rip), %r14d
    cmovel 4660, %r8d
    cmovel %edi, %ebp
    cmovel 0(%rdx), %esp
    cmovel 64(%rcx), %ecx
    cmovel 128(%rdx), %edx
    cmovel 0(%rsp), %ebx
    cmovel 8(%rsp), %esi
    cmovel -129(%rsp), %edi
    cmovel 0(%rcx,%rbx,4), %ebp
    cmovel -128(%rsp,%rbp,8), %esp
    cmovel -2147483648(%rbp,%rsi,1), %ecx
    cmovel gnu_back(%rip), %edx
    cmovel 2147483647, %ebx
    cmoveq 0(%r11), %r12
    cmoveq 127(%r14), %r13
    cmoveq 4660(%r15), %r15
    cmoveq 0(%rsp), %r9
    cmoveq -1(%r12), %r10
    cmoveq 128(%rsp), %r11
    cmoveq 0(%rdx,%r15,2), %r14
    cmoveq 64(%rbp,%rsi,4), %r8
    cmoveq -129(%r12,%rcx,8), %r12
    cmoveq gnu_fwd(%rip), %r13
    cmoveq -2147483648, %r15
    setne 0(%r10)
    setne 8(%r14)
    setne 2147483647(%r15)
    setne 0(%r12)
    setne -128(%r12)
    setne 4660(%r12)
    setne 0(%r15,%r9,1)
    setne 127(%r12,%rbp,2)
    setne 128(%r13,%r12,4)
    setne %dh
    setne 0(%rbx)
    setne -1(%rbx)
    setne -129(%rbp)
    setne 0(%rsp)
    setne 64(%rsp)
    setne -2147483648(%rsp)
    setne 0(%rdx,%rdi,8)
    setne 8(%rsi,%rax,1)
    setne 2147483647(%rdi,%rcx,2)
    setne gnu_back(%rip)
    setne 4660
    cmovnew 0(%rdi), %r9w
    cmovnew -128(%rcx), %r10w
    cmovnew 128(%r8), %r11w
    cmovnew 0(%r12), %r14w
    cmovnew 127(%rsp), %r8w
    cmovnew -129(%r12), %r12w
    cmovnew 0(%r9,%rax,4), %r13w
    cmovnew -1(%rdi,%r15,8), %r15w
    cmovnew -2147483648(%r15,%rsi,1), %r9w
    cmovnew gnu_fwd(%rip), %r10w
    cmovnew 2147483647, %r11w
    cmovnew %si, %di
    cmovnew 0(%rsi), %bp
    cmovnew 64(%rsi), %sp
    cmovnew 4660(%rdi), %cx
    cmovnew 0(%rsp), %dx
    cmovnew 8(%rsp), %bx
    cmovnew 128(%rsp), %si
    cmovnew 0(%rbx,%rdx,2), %di
    cmovnew -128(%rax,%rbx,4), %bp
    cmovnew -129(%rcx,%rbp,8), %sp
    cmovnew gnu_back(%rip), %cx
    cmovnew -2147483648, %dx
    cmovnel 0(%r14), %r14d
    cmovnel 127(%rbp), %r8d
    cmovnel 2147483647(%r13), %r12d
    cmovnel 0(%rsp), %r13d
    cmovnel -1(%r12), %r15d
    cmovnel 4660(%rsp), %r9d
    cmovnel 0(%rsp,%rcx,1), %r10d
    cmovnel 64(%rax,%r9,2), %r11d
    cmovnel 128(%r9,%rbp,4), %r14d
    cmovnel gnu_fwd(%rip), %r8d
    cmovnel -129, %r12d
    cmovnel %ebx, %esi
    cmovnel 0(%rdi), %edi
    cmovnel 8(%rcx), %ebp
    cmovnel -2147483648(%rdx), %esp
    cmovnel 0(%rsp), %ecx
    cmovnel -128(%rsp), %edx
    cmovnel 2147483647(%rsp), %ebx
    cmovnel 0(%rsp,%rsi,8), %esi
    cmovnel 127(%rdx,%rdi,1), %edi
    cmovnel 4660(%rbx,%rax,2), %ebp
    cmovnel gnu_back(%rip), %esp
    cmovnel 128, %ecx
    cmovneq 0(%r15), %r13
    cmovneq -1(%rdx), %r15
    cmovneq -129(%r9), %r9
    cmovneq 0(%r12), %r10
    cmovneq 64(%rsp), %r11
    cmovneq -2147483648(%r12), %r14
    cmovneq 0(%r14,%r12,4), %r8
    cmovneq 8(%rsp,%rax,8), %r12
    cmovneq 2147483647(%r13,%r15,1), %r13
    cmovneq gnu_fwd(%rip), %r15
    cmovneq 4660, %r9
    setbe 0(%r11)
    setbe -128(%r8)
    setbe 128(%r9)
    setbe 0(%r12)
    setbe 127(%r12)
    setbe -129(%r12)
    setbe 0(%r8,%rsi,2)
    setbe -1(%r15,%rcx,4)
    setbe -2147483648(%r8,%r9,8)
    setbe %bh
    setbe 0(%rcx)
    setbe 64(%rbx)
    setbe 2147483647(%rbp)
    setbe 0(%rsp)
    setbe 8(%rsp)
    setbe 4660(%rsp)
    setbe 0(%rsi,%rcx,1)
    setbe -128(%rsp,%rdx,2)
    setbe 128(%rbp,%rbx,4)
    setbe gnu_back(%rip)
    setbe -129
    cmovbew 0(%rcx), %r10w
    cmovbew 127(%rbx), %r11w
    cmovbew -2147483648(%r10), %r14w
    cmovbew 0(%rsp), %r8w
    cmovbew -1(%r12), %r12w
    cmovbew 2147483647(%rsp), %r13w
    cmovbew 0(%rsi,%rbp,8), %r15w
    cmovbew 64(%rbp,%r12,1), %r9w
    cmovbew 4660(%r12,%rax,2), %r10w
    cmovbew gnu_fwd(%rip), %r11w
    cmovbew 128, %r14w
    cmovbew %dx, %bx
    cmovbew 0(%rdx), %si
    cmovbew 8(%rsi), %di
    cmovbew -129(%rdi), %bp
    cmovbew 0(%rsp), %sp
    cmovbew -128(%rsp), %cx
    cmovbew -2147483648(%rsp), %dx
    cmovbew 0(%rdi,%rbp,4), %bx
    cmovbew 127(%rsi,%rsi,8), %si
    cmovbew 2147483647(%rdi,%rdi,1), %di
    cmovbew gnu_back(%rip), %bp
    cmovbew 4660, %sp
    cmovbel 0(%r8), %r8d
    cmovbel -1(%rsi), %r12d
    cmovbel 128(%r11), %r13d
    cmovbel 0(%r12), %r15d
    cmovbel 64(%rsp), %r9d
    cmovbel -129(%r12), %r10d
    cmovbel 0(%r15,%r15,2), %r11d
    cmovbel 8(%rdi,%rsi,4), %r14d
    cmovbel -2147483648(%r15,%rcx,8), %r8d
    cmovbel gnu_fwd(%rip), %r12d
    cmovbel 2147483647, %r13d
    cmovbel %ecx, %edx
    cmovbel 0(%rbx), %ebx
    cmovbel -128(%rcx), %esi
    cmovbel 4660(%rdx), %edi
    cmovbel 0(%rsp), %ebp
    cmovbel 127(%rsp), %esp
    cmovbel 128(%rsp), %ecx
    cmovbel 0(%rax,%rax,1), %edx
    cmovbel -1(%rax,%rcx,2), %ebx
    cmovbel -129(%rcx,%rdx,4), %esi
    cmovbel gnu_back(%rip), %edi
    cmovbel -2147483648, %ebp
    cmovbeq 0(%rdx), %r15
    cmovbeq 64(%rdi), %r9
    cmovbeq 2147483647(%r14), %r10
    cmovbeq 0(%rsp), %r11
    cmovbeq 8(%r12), %r14
    cmovbeq 4660(%rsp), %r8
    cmovbeq 0(%rax,%r9,8), %r12
    cmovbeq -128(%rax,%rbp,1), %r13
    cmovbeq 128(%r9,%r12,2), %r15
    cmovbeq gnu_fwd(%rip), %r9
    cmovbeq -129, %r10
    seta 0(%r14)
    seta 127(%r10)
    seta -2147483648(%r11)
    seta 0(%r12)
    seta -1(%r12)
    seta 2147483647(%r12)
    seta 0(%r9,%rax,4)
    seta 64(%r9,%r15,8)
    seta 4660(%r12,%rsi,1)
    seta %ch
    seta 0(%rsi)
    seta 8(%rbx)
    seta 128(%rbp)
    seta 0(%rsp)
    seta -128(%rsp)
    seta -129(%rsp)
    seta 0(%rcx,%rbx,2)
    seta 127(%rdx,%rbp,4)
    seta -2147483648(%rbx,%rsi,8)
g33:
    seta gnu_back(%rip)
    seta 2147483647
    cmovaw 0(%r9), %r11w
    cmovaw -1(%r15), %r14w
    cmovaw 4660(%rcx), %r8w
    cmovaw 0(%r12), %r12w
    cmovaw 64(%rsp), %r13w
    cmovaw 128(%r12), %r15w
    cmovaw 0(%r8,%rcx,1), %r9w
    cmovaw 8(%rsp,%r9,2), %r10w
    cmovaw -129(%r13,%rbp,4), %r11w
    cmovaw gnu_fwd(%rip), %r14w
    cmovaw -2147483648, %r8w
    cmovaw %sp, %cx
    cmovaw 0(%rdi), %dx
    cmovaw -128(%rsi), %bx
    cmovaw 2147483647(%rdi), %si
    cmovaw 0(%rsp), %di
    cmovaw 127(%rsp), %bp
    cmovaw 4660(%rsp), %sp
    cmovaw 0(%rdx,%rdi,8), %cx
    cmovaw -1(%rsp,%rax,1), %dx
    cmovaw 128(%rbp,%rcx,2), %bx
    cmovaw gnu_back(%rip), %si
    cmovaw -129, %di
    cmoval 0(%rbx), %r12d
    cmoval 64(%r8), %r13d
    cmoval -2147483648(%rbp), %r15d
    cmoval 0(%rsp), %r9d
    cmoval 8(%r12), %r10d
    cmoval 2147483647(%rsp), %r11d
    cmoval 0(%rcx,%r12,4), %r14d
    cmoval -128(%rbp,%rax,8), %r8d
    cmoval 4660(%r12,%r15,1), %r12d
    cmoval gnu_fwd(%rip), %r13d
    cmoval 128, %r15d
    cmoval %ebp, %esp
    cmoval 0(%rcx), %ecx
    cmoval 127(%rcx), %edx
    cmoval -129(%rdx), %ebx
    cmoval 0(%rsp), %esi
    cmoval -1(%rsp), %edi
    cmoval -2147483648(%rsp), %ebp
    cmoval 0(%rbx,%rdx,2), %esp
    cmoval 64(%rsi,%rbx,4), %ecx
    cmoval 2147483647(%rdi,%rbp,8), %edx
    cmoval gnu_back(%rip), %ebx
    cmoval 4660, %esi
    cmovaq 0(%r10), %r9
    cmovaq 8(%r13), %r10
    cmovaq 128(%rdx), %r11
    cmovaq 0(%r12), %r14
    cmovaq -128(%rsp), %r8
    cmovaq -129(%r12), %r12
    cmovaq 0(%r12,%rsi,1), %r13
    cmovaq 127(%rdi,%rcx,2), %r15
    cmovaq -2147483648(%r15,%r9,4), %r9
    cmovaq gnu_fwd(%rip), %r10
    cmovaq 2147483647, %r11
    sets 0(%r15)
    sets -1(%r13)
    sets 4660(%r14)
    sets 0(%r12)
    sets 64(%r12)
    sets 128(%r12)
    sets 0(%r10,%rbp,8)
    sets 8(%r13,%r12,1)
    sets -129(%r15,%rax,2)
    sets %ah
    sets 0(%rdx)
    sets -128(%rbx)
    sets -2147483648(%rbp)
    sets 0(%rsp)
    sets 127(%rsp)
    sets 2147483647(%rsp)
    sets 0(%rsp,%rsi,4)
    sets -1(%rax,%rdi,8)
    sets 4660(%rcx,%rax,1)
    sets gnu_back(%rip)
    sets 128
    cmovsw 0(%rsi), %r14w
    cmovsw 64(%r9), %r8w
    cmovsw -129(%rbx), %r12w
    cmovsw 0(%rsp), %r13w
    cmovsw 8(%r12), %r15w
    cmovsw -2147483648(%rsp), %r9w
    cmovsw 0(%rdx,%r15,2), %r10w
    cmovsw -128(%rax,%rsi,4), %r11w
    cmovsw 2147483647(%r9,%rcx,8), %r14w
    cmovsw gnu_fwd(%rip), %r8w
    cmovsw 4660, %r12w
    cmovsw %di, %bp
    cmovsw 0(%rbx), %sp
    cmovsw 127(%rsi), %cx
    cmovsw 128(%rdi), %dx
    cmovsw 0(%rsp), %bx
    cmovsw -1(%rsp), %si
    cmovsw -129(%rsp), %di
    cmovsw 0(%rsi,%rcx,1), %bp
    cmovsw 64(%rdx,%rdx,2), %sp
    cmovsw -2147483648(%rbx,%rbx,4), %cx
    cmovsw gnu_back(%rip), %dx
    cmovsw 2147483647, %bx
    cmovsl 0(%r11), %r13d
    cmovsl 8(%r10), %r15d
    cmovsl 4660(%rsi), %r9d
    cmovsl 0(%r12), %r10d
    cmovsl -128(%rsp), %r11d
    cmovsl 128(%r12), %r14d
    cmovsl 0(%r9,%r9,8), %r8d
    cmovsl 127(%rsp,%rbp,1), %r12d
    cmovsl -129(%r13,%r12,2), %r13d
    cmovsl gnu_fwd(%rip), %r15d
    cmovsl -2147483648, %r9d
    cmovsl %esi, %edi
    cmovsl 0(%rsi), %ebp
    cmovsl -1(%rcx), %esp
    cmovsl 2147483647(%rdx), %ecx
    cmovsl 0(%rsp), %edx
    cmovsl 64(%rsp), %ebx
    cmovsl 4660(%rsp), %esi
    cmovsl 0(%rdi,%rbp,4), %edi
    cmovsl 8(%rsp,%rsi,8), %ebp
    cmovsl 128(%rbp,%rdi,1), %esp
    cmovsl gnu_back(%rip), %ecx
    cmovsl -129, %edx
    cmovsq 0(%rdi), %r10
    cmovsq -128(%r11), %r11
    cmovsq -2147483648(%rdi), %r14
    cmovsq 0(%rsp), %r8
    cmovsq 127(%r12), %r12
    cmovsq 2147483647(%rsp), %r13
    cmovsq 0(%rsp,%rax,2), %r15
    cmovsq -1(%rbp,%r15,4), %r9
    cmovsq 4660(%r12,%rsi,8), %r10
    cmovsq gnu_fwd(%rip), %r11
    cmovsq 128, %r14
    setns 0(%r8)
    setns 64(%r15)
    setns -129(%r8)
    setns 0(%r12)
    setns 8(%r12)
    setns -2147483648(%r12)
    setns 0(%r11,%rcx,1)
    setns -128(%r8,%r9,2)
    setns 2147483647(%r9,%rbp,4)
    setns %cl
    setns 0(%rdi)
    setns 127(%rbx)
    setns 4660(%rbp)
    setns 0(%rsp)
    setns -1(%rsp)
    setns 128(%rsp)
    setns 0(%rax,%rax,8)
    setns 64(%rsi,%rcx,1)
    setns -129(%rdi,%rdx,2)
    setns gnu_back(%rip)
    setns -2147483648
    cmovnsw 0(%r14), %r8w
    cmovnsw 8(%r14), %r12w
    cmovnsw 2147483647(%r15), %r13w
    cmovnsw 0(%r12), %r15w
    cmovnsw -128(%rsp), %r9w
    cmovnsw 4660(%r12), %r10w
    cmovnsw 0(%r14,%r12,4), %r11w
    cmovnsw 127(%rdi,%rax,8), %r14w
    cmovnsw 128(%r15,%r15,1), %r8w
    cmovnsw gnu_fwd(%rip), %r12w
    cmovnsw -129, %r13w
    cmovnsw %bx, %si
    cmovnsw 0(%rcx), %di
    cmovnsw -1(%rsi), %bp
    cmovnsw -2147483648(%rdi), %sp
    cmovnsw 0(%rsp), %cx
    cmovnsw 64(%rsp), %dx
    cmovnsw 2147483647(%rsp), %bx
    cmovnsw 0(%rcx,%rbx,2), %si
    cmovnsw 8(%rax,%rbp,4), %di
    cmovnsw 4660(%rcx,%rsi,8), %bp
    cmovnsw gnu_back(%rip), %sp
    cmovnsw 128, %cx
    cmovnsl 0(%r15), %r15d
    cmovnsl -128(%rcx), %r9d
    cmovnsl -129(%r8), %r10d
    cmovnsl 0(%rsp), %r11d
    cmovnsl 127(%r12), %r14d
    cmovnsl -2147483648(%rsp), %r8d
    cmovnsl 0(%rsi,%rsi,1), %r12d
    cmovnsl -1(%rax,%rcx,2), %r13d
    cmovnsl 2147483647(%r9,%r9,4), %r15d
    cmovnsl gnu_fwd(%rip), %r9d
    cmovnsl 4660, %r10d
    cmovnsl %edx, %ebx
    cmovnsl 0(%rdx), %esi
    cmovnsl 64(%rcx), %edi
    cmovnsl 128(%rdx), %ebp
    cmovnsl 0(%rsp), %esp
    cmovnsl 8(%rsp), %ecx
    cmovnsl -129(%rsp), %edx
    cmovnsl 0(%rdx,%rdi,8), %ebx
g34:
    cmovnsl -128(%rdx,%rax,1), %esi
    cmovnsl -2147483648(%rbx,%rcx,2), %edi
    cmovnsl gnu_back(%rip), %ebp
    cmovnsl 2147483647, %esp
    cmovnsq 0(%rcx), %r11
    cmovnsq 127(%rbp), %r14
    cmovnsq 4660(%r13), %r8
    cmovnsq 0(%r12), %r12
    cmovnsq -1(%rsp), %r13
    cmovnsq 128(%r12), %r15
    cmovnsq 0(%r15,%rbp,4), %r9
    cmovnsq 64(%rsp,%r12,8), %r10
    cmovnsq -129(%r13,%rax,1), %r11
    cmovnsq gnu_fwd(%rip), %r14
    cmovnsq -2147483648, %r8
    setp 0(%r9)
    setp 8(%r9)
    setp 2147483647(%r10)
    setp 0(%r12)
    setp -128(%r12)
    setp 4660(%r12)
    setp 0(%r12,%r15,2)
    setp 127(%r12,%rsi,4)
    setp 128(%r13,%rcx,8)
    setp %dl
    setp 0(%rbx)
    setp -1(%rbx)
    setp -129(%rbp)
    setp 0(%rsp)
    setp 64(%rsp)
    setp -2147483648(%rsp)
    setp 0(%rbx,%rdx,1)
    setp 8(%rsp,%rbx,2)
    setp 2147483647(%rbp,%rbp,4)
    setp gnu_back(%rip)
    setp 4660
    cmovpw 0(%r8), %r12w
    cmovpw -128(%rdx), %r13w
    cmovpw 128(%r9), %r15w
    cmovpw 0(%rsp), %r9w
    cmovpw 127(%r12), %r10w
    cmovpw -129(%rsp), %r11w
    cmovpw 0(%rax,%r9,8), %r14w
    cmovpw -1(%rbp,%rbp,1), %r8w
    cmovpw -2147483648(%r12,%r12,2), %r12w
    cmovpw gnu_fwd(%rip), %r13w
    cmovpw 2147483647, %r15w
    cmovpw %cx, %dx
    cmovpw 0(%rsi), %bx
    cmovpw 64(%rsi), %si
    cmovpw 4660(%rdi), %di
    cmovpw 0(%rsp), %bp
    cmovpw 8(%rsp), %sp
    cmovpw 128(%rsp), %cx
    cmovpw 0(%rsp,%rsi,4), %dx
    cmovpw -128(%rsi,%rdi,8), %bx
    cmovpw -129(%rdi,%rax,1), %si
    cmovpw gnu_back(%rip), %di
    cmovpw -2147483648, %bp
    cmovpl 0(%rdx), %r9d
    cmovpl 127(%rbx), %r10d
    cmovpl 2147483647(%r10), %r11d
    cmovpl 0(%r12), %r14d
    cmovpl -1(%rsp), %r8d
    cmovpl 4660(%r12), %r12d
    cmovpl 0(%r8,%rax,2), %r13d
    cmovpl 64(%rdi,%r15,4), %r15d
    cmovpl 128(%r15,%rsi,8), %r9d
    cmovpl gnu_fwd(%rip), %r10d
    cmovpl -129, %r11d
    cmovpl %esp, %ecx
    cmovpl 0(%rdi), %edx
    cmovpl 8(%rcx), %ebx
    cmovpl -2147483648(%rdx), %esi
    cmovpl 0(%rsp), %edi
    cmovpl -128(%rsp), %ebp
    cmovpl 2147483647(%rsp), %esp
    cmovpl 0(%rsi,%rcx,1), %ecx
    cmovpl 127(%rax,%rdx,2), %edx
    cmovpl 4660(%rcx,%rbx,4), %ebx
    cmovpl gnu_back(%rip), %esi
    cmovpl 128, %edi
    cmovpq 0(%r9), %r14
    cmovpq -1(%rsi), %r8
    cmovpq -129(%r11), %r12
    cmovpq 0(%rsp), %r13
    cmovpq 64(%r12), %r15
    cmovpq -2147483648(%rsp), %r9
    cmovpq 0(%rcx,%rcx,8), %r10
    cmovpq 8(%rax,%r9,1), %r11
    cmovpq 2147483647(%r9,%rbp,2), %r14
    cmovpq gnu_fwd(%rip), %r8
    cmovpq 4660, %r12
    setnp 0(%r10)
    setnp -128(%r11)
    setnp 128(%r13)
    setnp 0(%r12)
    setnp 127(%r12)
    setnp -129(%r12)
    setnp 0(%r14,%r12,4)
    setnp -1(%r15,%rax,8)
    setnp -2147483648(%r8,%r15,1)
    setnp %bl
    setnp 0(%rcx)
    setnp 64(%rbx)
    setnp 2147483647(%rbp)
    setnp 0(%rsp)
    setnp 8(%rsp)
    setnp 4660(%rsp)
    setnp 0(%rdi,%rbp,2)
    setnp -128(%rdx,%rsi,4)
    setnp 128(%rbx,%rdi,8)
    setnp gnu_back(%rip)
    setnp -129
    cmovnpw 0(%rbx), %r13w
    cmovnpw 127(%rdi), %r15w
    cmovnpw -2147483648(%r14), %r9w
    cmovnpw 0(%r12), %r10w
    cmovnpw -1(%rsp), %r11w
    cmovnpw 2147483647(%r12), %r14w
    cmovnpw 0(%r12,%rsi,1), %r8w
    cmovnpw 64(%rsp,%rcx,2), %r12w
    cmovnpw 4660(%r13,%r9,4), %r13w
    cmovnpw gnu_fwd(%rip), %r15w
    cmovnpw 128, %r9w
    cmovnpw %bp, %sp
    cmovnpw 0(%rdx), %cx
    cmovnpw 8(%rsi), %dx
    cmovnpw -129(%rdi), %bx
    cmovnpw 0(%rsp), %si
    cmovnpw -128(%rsp), %di
    cmovnpw -2147483648(%rsp), %bp
    cmovnpw 0(%rax,%rax,8), %sp
    cmovnpw 127(%rsp,%rcx,1), %cx
    cmovnpw 2147483647(%rbp,%rdx,2), %dx
    cmovnpw gnu_back(%rip), %bx
    cmovnpw 4660, %si
    cmovnpl 0(%r10), %r10d
    cmovnpl -1(%r15), %r11d
    cmovnpl 128(%rcx), %r14d
    cmovnpl 0(%rsp), %r8d
    cmovnpl 64(%r12), %r12d
    cmovnpl -129(%rsp), %r13d
    cmovnpl 0(%rdx,%rbp,4), %r15d
    cmovnpl 8(%rbp,%r12,8), %r9d
    cmovnpl -2147483648(%r12,%rax,1), %r10d
    cmovnpl gnu_fwd(%rip), %r11d
    cmovnpl 2147483647, %r14d
    cmovnpl %edi, %ebp
    cmovnpl 0(%rbx), %esp
    cmovnpl -128(%rcx), %ecx
    cmovnpl 4660(%rdx), %edx
    cmovnpl 0(%rsp), %ebx
    cmovnpl 127(%rsp), %esi
    cmovnpl 128(%rsp), %edi
    cmovnpl 0(%rcx,%rbx,2), %ebp
    cmovnpl -1(%rsi,%rbp,4), %esp
    cmovnpl -129(%rdi,%rsi,8), %ecx
    cmovnpl gnu_back(%rip), %edx
    cmovnpl -2147483648, %ebx
    cmovnpq 0(%rsi), %r8
    cmovnpq 64(%r8), %r12
    cmovnpq 2147483647(%rbp), %r13
    cmovnpq 0(%r12), %r15
    cmovnpq 8(%rsp), %r9
    cmovnpq 4660(%r12), %r10
    cmovnpq 0(%r9,%r15,1), %r11
    cmovnpq -128(%rdi,%rsi,2), %r14
    cmovnpq 128(%r15,%rcx,4), %r8
    cmovnpq gnu_fwd(%rip), %r12
    cmovnpq -129, %r13
    setl 0(%r11)
    setl 127(%r14)
    setl -2147483648(%r15)
    setl 0(%r12)
    setl -1(%r12)
    setl 2147483647(%r12)
    setl 0(%r15,%r9,8)
    setl 64(%r9,%rbp,1)
    setl 4660(%r12,%r12,2)
    setl %dh
    setl 0(%rsi)
    setl 8(%rbx)
    setl 128(%rbp)
    setl 0(%rsp)
    setl -128(%rsp)
    setl -129(%rsp)
    setl 0(%rdx,%rdi,4)
    setl 127(%rax,%rax,8)
    setl -2147483648(%rcx,%rcx,1)
    setl gnu_back(%rip)
    setl 2147483647
    cmovlw 0(%r11), %r15w
    cmovlw -1(%r13), %r9w
    cmovlw 4660(%rdx), %r10w
    cmovlw 0(%rsp), %r11w
    cmovlw 64(%r12), %r14w
    cmovlw 128(%rsp), %r8w
    cmovlw 0(%rsp,%rax,2), %r12w
    cmovlw 8(%rax,%r15,4), %r13w
g35:
    cmovlw -129(%r9,%rsi,8), %r15w
    cmovlw gnu_fwd(%rip), %r9w
    cmovlw -2147483648, %r10w
    cmovlw %si, %di
    cmovlw 0(%rdi), %bp
    cmovlw -128(%rsi), %sp
    cmovlw 2147483647(%rdi), %cx
    cmovlw 0(%rsp), %dx
    cmovlw 127(%rsp), %bx
    cmovlw 4660(%rsp), %si
    cmovlw 0(%rbx,%rdx,1), %di
    cmovlw -1(%rdx,%rbx,2), %bp
    cmovlw 128(%rbx,%rbp,4), %sp
    cmovlw gnu_back(%rip), %cx
    cmovlw -129, %dx
    cmovll 0(%rdi), %r11d
    cmovll 64(%r9), %r14d
    cmovll -2147483648(%rbx), %r8d
    cmovll 0(%r12), %r12d
    cmovll 8(%rsp), %r13d
    cmovll 2147483647(%r12), %r15d
    cmovll 0(%r14,%rcx,8), %r9d
    cmovll -128(%rsp,%r9,1), %r10d
    cmovll 4660(%r13,%rbp,2), %r11d
    cmovll gnu_fwd(%rip), %r14d
    cmovll 128, %r8d
    cmovll %ebx, %esi
    cmovll 0(%rcx), %edi
    cmovll 127(%rcx), %ebp
    cmovll -129(%rdx), %esp
    cmovll 0(%rsp), %ecx
    cmovll -1(%rsp), %edx
    cmovll -2147483648(%rsp), %ebx
    cmovll 0(%rsp,%rsi,4), %esi
    cmovll 64(%rsp,%rdi,8), %edi
    cmovll 2147483647(%rbp,%rax,1), %ebp
    cmovll gnu_back(%rip), %esp
    cmovll 4660, %ecx
    cmovlq 0(%r14), %r12
    cmovlq 8(%r10), %r13
    cmovlq 128(%rsi), %r15
    cmovlq 0(%rsp), %r9
    cmovlq -128(%r12), %r10
    cmovlq -129(%rsp), %r11
    cmovlq 0(%rsi,%r12,2), %r14
    cmovlq 127(%rbp,%rax,4), %r8
    cmovlq -2147483648(%r12,%r15,8), %r12
    cmovlq gnu_fwd(%rip), %r13
    cmovlq 2147483647, %r15
    setge 0(%r14)
    setge -1(%r8)
    setge 4660(%r9)
    setge 0(%r12)
    setge 64(%r12)
    setge 128(%r12)
    setge 0(%r8,%rsi,1)
    setge 8(%r13,%rcx,2)
    setge -129(%r15,%r9,4)
    setge %bh
    setge 0(%rdx)
    setge -128(%rbx)
    setge -2147483648(%rbp)
    setge 0(%rsp)
    setge 127(%rsp)
    setge 2147483647(%rsp)
    setge 0(%rsi,%rcx,8)
    setge -1(%rsi,%rdx,1)
    setge 4660(%rdi,%rbx,2)
    setge gnu_back(%rip)
    setge 128
    cmovgew 0(%r15), %r9w
    cmovgew 64(%r11), %r10w
    cmovgew -129(%rdi), %r11w
    cmovgew 0(%r12), %r14w
    cmovgew 8(%rsp), %r8w
    cmovgew -2147483648(%r12), %r12w
    cmovgew 0(%r15,%rbp,4), %r13w
    cmovgew -128(%rdi,%r12,8), %r15w
    cmovgew 2147483647(%r15,%rax,1), %r9w
    cmovgew gnu_fwd(%rip), %r10w
    cmovgew 4660, %r11w
    cmovgew %dx, %bx
    cmovgew 0(%rbx), %si
    cmovgew 127(%rsi), %di
    cmovgew 128(%rdi), %bp
    cmovgew 0(%rsp), %sp
    cmovgew -1(%rsp), %cx
    cmovgew -129(%rsp), %dx
    cmovgew 0(%rdi,%rbp,2), %bx
    cmovgew 64(%rax,%rsi,4), %si
    cmovgew -2147483648(%rcx,%rdi,8), %di
    cmovgew gnu_back(%rip), %bp
    cmovgew 2147483647, %sp
    cmovgel 0(%rcx), %r14d
    cmovgel 8(%r14), %r8d
    cmovgel 4660(%r15), %r12d
    cmovgel 0(%rsp), %r13d
    cmovgel -128(%r12), %r15d
    cmovgel 128(%rsp), %r9d
    cmovgel 0(%rax,%r15,1), %r10d
    cmovgel 127(%rax,%rsi,2), %r11d
    cmovgel -129(%r9,%rcx,4), %r14d
    cmovgel gnu_fwd(%rip), %r8d
    cmovgel -2147483648, %r12d
    cmovgel %ecx, %edx
    cmovgel 0(%rsi), %ebx
    cmovgel -1(%rcx), %esi
    cmovgel 2147483647(%rdx), %edi
    cmovgel 0(%rsp), %ebp
    cmovgel 64(%rsp), %esp
    cmovgel 4660(%rsp), %ecx
    cmovgel 0(%rax,%rax,8), %edx
    cmovgel 8(%rdx,%rcx,1), %ebx
    cmovgel 128(%rbx,%rdx,2), %esi
    cmovgel gnu_back(%rip), %edi
    cmovgel -129, %ebp
    cmovgeq 0(%r8), %r13
    cmovgeq -128(%rcx), %r15
    cmovgeq -2147483648(%r8), %r9
    cmovgeq 0(%r12), %r10
    cmovgeq 127(%rsp), %r11
    cmovgeq 2147483647(%r12), %r14
    cmovgeq 0(%r8,%r9,4), %r8
    cmovgeq -1(%rsp,%rbp,8), %r12
    cmovgeq 4660(%r13,%r12,1), %r13
    cmovgeq gnu_fwd(%rip), %r15
    cmovgeq 128, %r9
    setle 0(%r15)
    setle 64(%r10)
    setle -129(%r11)
    setle 0(%r12)
    setle 8(%r12)
    setle -2147483648(%r12)
    setle 0(%r9,%rax,2)
    setle -128(%r8,%r15,4)
    setle 2147483647(%r9,%rsi,8)
    setle %ch
    setle 0(%rdi)
    setle 127(%rbx)
    setle 4660(%rbp)
    setle 0(%rsp)
    setle -1(%rsp)
    setle 128(%rsp)
    setle 0(%rcx,%rbx,1)
    setle 64(%rsp,%rbp,2)
    setle -129(%rbp,%rsi,4)
    setle gnu_back(%rip)
    setle -2147483648
    cmovlew 0(%rdx), %r10w
    cmovlew 8(%rbp), %r11w
    cmovlew 2147483647(%r13), %r14w
    cmovlew 0(%rsp), %r8w
    cmovlew -128(%r12), %r12w
    cmovlew 4660(%rsp), %r13w
    cmovlew 0(%rcx,%rcx,8), %r15w
    cmovlew 127(%rbp,%r9,1), %r9w
    cmovlew 128(%r12,%rbp,2), %r10w
    cmovlew gnu_fwd(%rip), %r11w
    cmovlew -129, %r14w
    cmovlew %sp, %cx
    cmovlew 0(%rcx), %dx
    cmovlew -1(%rsi), %bx
    cmovlew -2147483648(%rdi), %si
    cmovlew 0(%rsp), %di
    cmovlew 64(%rsp), %bp
    cmovlew 2147483647(%rsp), %sp
    cmovlew 0(%rdx,%rdi,4), %cx
    cmovlew 8(%rsi,%rax,8), %dx
    cmovlew 4660(%rdi,%rcx,1), %bx
    cmovlew gnu_back(%rip), %si
    cmovlew 128, %di
    cmovlel 0(%r9), %r8d
    cmovlel -128(%rdx), %r12d
    cmovlel -129(%r9), %r13d
    cmovlel 0(%r12), %r15d
    cmovlel 127(%rsp), %r9d
    cmovlel -2147483648(%r12), %r10d
    cmovlel 0(%r12,%r12,2), %r11d
    cmovlel -1(%rdi,%rax,4), %r14d
    cmovlel 2147483647(%r15,%r15,8), %r8d
    cmovlel gnu_fwd(%rip), %r12d
    cmovlel 4660, %r13d
    cmovlel %ebp, %esp
    cmovlel 0(%rdx), %ecx
    cmovlel 64(%rcx), %edx
    cmovlel 128(%rdx), %ebx
    cmovlel 0(%rsp), %esi
    cmovlel 8(%rsp), %edi
    cmovlel -129(%rsp), %ebp
    cmovlel 0(%rbx,%rdx,1), %esp
    cmovlel -128(%rax,%rbx,2), %ecx
    cmovlel -2147483648(%rcx,%rbp,4), %edx
    cmovlel gnu_back(%rip), %ebx
    cmovlel 2147483647, %esi
    cmovleq 0(%rbx), %r15
    cmovleq 127(%rbx), %r9
    cmovleq 4660(%r10), %r10
    cmovleq 0(%rsp), %r11
    cmovleq -1(%r12), %r14
    cmovleq 128(%rsp), %r8
g36:
    cmovleq 0(%rdx,%rsi,8), %r12
    cmovleq 64(%rax,%rcx,1), %r13
    cmovleq -129(%r9,%r9,2), %r15
    cmovleq gnu_fwd(%rip), %r9
    cmovleq -2147483648, %r10
    setg 0(%r8)
    setg 8(%r13)
    setg 2147483647(%r14)
    setg 0(%r12)
    setg -128(%r12)
    setg 4660(%r12)
    setg 0(%r10,%rbp,4)
    setg 127(%r12,%r12,8)
    setg 128(%r13,%rax,1)
    setg %ah
    setg 0(%rbx)
    setg -1(%rbx)
    setg -129(%rbp)
    setg 0(%rsp)
    setg 64(%rsp)
    setg -2147483648(%rsp)
    setg 0(%rsp,%rsi,2)
    setg 8(%rdx,%rdi,4)
    setg 2147483647(%rbx,%rax,8)
    setg gnu_back(%rip)
    setg 4660
    cmovgw 0(%r10), %r11w
    cmovgw -128(%rsi), %r14w
    cmovgw 128(%r11), %r8w
    cmovgw 0(%r12), %r12w
    cmovgw 127(%rsp), %r13w
    cmovgw -129(%r12), %r15w
    cmovgw 0(%r9,%r15,1), %r9w
    cmovgw -1(%rsp,%rsi,2), %r10w
    cmovgw -2147483648(%r13,%rcx,4), %r11w
    cmovgw gnu_fwd(%rip), %r14w
    cmovgw 2147483647, %r8w
    cmovgw %di, %bp
    cmovgw 0(%rsi), %sp
    cmovgw 64(%rsi), %cx
    cmovgw 4660(%rdi), %dx
    cmovgw 0(%rsp), %bx
    cmovgw 8(%rsp), %si
    cmovgw 128(%rsp), %di
    cmovgw 0(%rsi,%rcx,8), %bp
    cmovgw -128(%rsp,%rdx,1), %sp
    cmovgw -129(%rbp,%rbx,2), %cx
    cmovgw gnu_back(%rip), %dx
    cmovgw -2147483648, %bx
    cmovgl 0(%rsi), %r12d
    cmovgl 127(%rdi), %r13d
    cmovgl 2147483647(%r14), %r15d
    cmovgl 0(%rsp), %r9d
    cmovgl -1(%r12), %r10d
    cmovgl 4660(%rsp), %r11d
    cmovgl 0(%rsp,%r9,4), %r14d
    cmovgl 64(%rbp,%rbp,8), %r8d
    cmovgl 128(%r12,%r12,1), %r12d
    cmovgl gnu_fwd(%rip), %r13d
    cmovgl -129, %r15d
    cmovgl %esi, %edi
    cmovgl 0(%rdi), %ebp
    cmovgl 8(%rcx), %esp
    cmovgl -2147483648(%rdx), %ecx
    cmovgl 0(%rsp), %edx
    cmovgl -128(%rsp), %ebx
    cmovgl 2147483647(%rsp), %esi
    cmovgl 0(%rdi,%rbp,2), %edi
    cmovgl 127(%rsi,%rsi,4), %ebp
    cmovgl 4660(%rdi,%rdi,8), %esp
    cmovgl gnu_back(%rip), %ecx
    cmovgl 128, %edx
    cmovgq 0(%r11), %r9
    cmovgq -1(%r15), %r10
    cmovgq -129(%rcx), %r11
    cmovgq 0(%r12), %r14
    cmovgq 64(%rsp), %r8
    cmovgq -2147483648(%r12), %r12
    cmovgq 0(%r14,%rax,1), %r13
    cmovgq 8(%rdi,%r15,2), %r15
    cmovgq 2147483647(%r15,%rsi,4), %r9
    cmovgq gnu_fwd(%rip), %r10
    cmovgq 4660, %r11
    call *%rbx
    call *0(%rcx)
    call *0(%r9)
    call *-128(%rbx)
    call *127(%r15)
    call *128(%rbp)
    call *-129(%r8)
    call *0(%rsp)
    call *0(%r12)
    call *-1(%rsp)
    call *64(%r12)
    call *-2147483648(%rsp)
    call *2147483647(%r12)
    call *0(%rax,%rax,8)
    call *0(%r11,%rcx,1)
    call *8(%rax,%rcx,2)
    call *-128(%r15,%r9,4)
    call *4660(%rcx,%rdx,8)
    call *128(%r8,%rbp,1)
    call *-129
    jmp *%rsi
    jmp *0(%rdx)
    jmp *0(%r10)
    jmp *127(%rsi)
    jmp *-1(%r9)
    jmp *-2147483648(%rdi)
    jmp *2147483647(%r10)
    jmp *0(%rsp)
    jmp *0(%r12)
    jmp *64(%rsp)
    jmp *8(%r12)
    jmp *4660(%rsp)
    jmp *128(%r12)
    jmp *0(%rcx,%rbx,2)
    jmp *0(%r12,%r12,4)
    jmp *-128(%rdx,%rbp,8)
    jmp *127(%r9,%rax,1)
    jmp *-129(%rbx,%rsi,2)
    jmp *-2147483648(%r12,%r15,4)
    jmp *2147483647
    pushq %rdi
    popq %rbp
    nopw 0(%r11)
    nopw -1(%r11)
    nopw 4660(%r13)
    nopw 0(%r12)
    nopw 64(%r12)
    nopw 128(%r12)
    nopw 0(%r14,%rsi,8)
    nopw 8(%r13,%rcx,1)
    nopw -129(%r15,%r9,2)
    nopw %sp
    nopw 0(%rbx)
    nopw -128(%rcx)
    nopw -2147483648(%rdx)
    nopw 0(%rsp)
    nopw 127(%rsp)
    nopw 2147483647(%rsp)
    nopw 0(%rdx,%rdi,4)
    nopw -1(%rsp,%rax,8)
    nopw 4660(%rbp,%rcx,1)
    nopw gnu_back(%rip)
    nopw 128
    nopl 0(%r14)
    nopl 64(%r14)
    nopl -129(%r15)
    nopl 0(%r12)
    nopl 8(%r12)
    nopl -2147483648(%r12)
    nopl 0(%r15,%rbp,2)
    nopl -128(%r8,%r12,4)
    nopl 2147483647(%r9,%rax,8)
    nopl %ecx
    nopl 0(%rsi)
    nopl 127(%rbx)
    nopl 4660(%rbp)
    nopl 0(%rsp)
    nopl -1(%rsp)
    nopl 128(%rsp)
    nopl 0(%rbx,%rdx,1)
    nopl 64(%rsi,%rbx,2)
    nopl -129(%rdi,%rbp,4)
    nopl gnu_fwd(%rip)
    nopl -2147483648
    pcmpeqb %xmm14, %xmm9
    pcmpeqb 0(%rdi), %xmm8
    pcmpeqb 8(%r8), %xmm12
    pcmpeqb 2147483647(%rbp), %xmm13
    pcmpeqb 0(%rsp), %xmm15
    pcmpeqb -128(%r12), %xmm9
    pcmpeqb 4660(%rsp), %xmm10
    pcmpeqb 0(%rsi,%r15,8), %xmm11
    pcmpeqb 127(%rax,%rsi,1), %xmm14
    pcmpeqb 128(%r9,%rcx,2), %xmm8
    pcmpeqb gnu_back(%rip), %xmm12
    pcmpeqb -129, %xmm13
    pcmpeqb %xmm2, %xmm3
    pcmpeqb 0(%rdi), %xmm6
    pcmpeqb -1(%rsi), %xmm7
    pcmpeqb -2147483648(%rdi), %xmm5
    pcmpeqb 0(%rsp), %xmm4
    pcmpeqb 64(%rsp), %xmm1
    pcmpeqb 2147483647(%rsp), %xmm2
    pcmpeqb 0(%rsp,%rsi,4), %xmm3
    pcmpeqb 8(%rax,%rdi,8), %xmm6
    pcmpeqb 4660(%rcx,%rax,1), %xmm7
    pcmpeqb gnu_fwd(%rip), %xmm5
    pcmpeqb 128, %xmm4
    pcmpeqd %xmm15, %xmm2
    pcmpeqd 0(%r14), %xmm9
    pcmpeqd -128(%r13), %xmm10
    pcmpeqd -129(%rdx), %xmm11
    pcmpeqd 0(%r12), %xmm14
    pcmpeqd 127(%rsp), %xmm8
    pcmpeqd -2147483648(%r12), %xmm12
    pcmpeqd 0(%r15,%r9,2), %xmm13
    pcmpeqd -1(%rsp,%rbp,4), %xmm15
g37:
    pcmpeqd 2147483647(%r13,%r12,8), %xmm9
    pcmpeqd gnu_back(%rip), %xmm10
    pcmpeqd 4660, %xmm11
    pcmpeqd %xmm1, %xmm2
    pcmpeqd 0(%rcx), %xmm3
    pcmpeqd 64(%rcx), %xmm6
    pcmpeqd 128(%rdx), %xmm7
    pcmpeqd 0(%rsp), %xmm5
    pcmpeqd 8(%rsp), %xmm4
    pcmpeqd -129(%rsp), %xmm1
    pcmpeqd 0(%rsi,%rcx,1), %xmm2
    pcmpeqd -128(%rdx,%rdx,2), %xmm3
    pcmpeqd -2147483648(%rbx,%rbx,4), %xmm6
    pcmpeqd gnu_fwd(%rip), %xmm7
    pcmpeqd 2147483647, %xmm5
    pcmpgtb %xmm14, %xmm12
    pcmpgtb 0(%r15), %xmm8
    pcmpgtb 127(%r9), %xmm12
    pcmpgtb 4660(%rbx), %xmm13
    pcmpgtb 0(%rsp), %xmm15
    pcmpgtb -1(%r12), %xmm9
    pcmpgtb 128(%rsp), %xmm10
    pcmpgtb 0(%rax,%rax,8), %xmm11
    pcmpgtb 64(%rbp,%r15,1), %xmm14
    pcmpgtb -129(%r12,%rsi,2), %xmm8
    pcmpgtb gnu_back(%rip), %xmm12
    pcmpgtb -2147483648, %xmm13
    pcmpgtb %xmm4, %xmm1
    pcmpgtb 0(%rdx), %xmm2
    pcmpgtb 8(%rbx), %xmm3
    pcmpgtb 2147483647(%rbp), %xmm6
    pcmpgtb 0(%rsp), %xmm7
    pcmpgtb -128(%rsp), %xmm5
    pcmpgtb 4660(%rsp), %xmm4
    pcmpgtb 0(%rdi,%rbp,4), %xmm1
    pcmpgtb 127(%rsp,%rsi,8), %xmm2
    pcmpgtb 128(%rbp,%rdi,1), %xmm3
    pcmpgtb gnu_fwd(%rip), %xmm6
    pcmpgtb -129, %xmm7
    pminub %xmm15, %xmm3
    pminub 0(%rcx), %xmm9
    pminub -1(%r10), %xmm10
    pminub -2147483648(%rsi), %xmm11
    pminub 0(%r12), %xmm14
    pminub 64(%rsp), %xmm8
    pminub 2147483647(%r12), %xmm12
    pminub 0(%r8,%rcx,2), %xmm13
    pminub 8(%rdi,%r9,4), %xmm15
    pminub 4660(%r15,%rbp,8), %xmm9
    pminub gnu_back(%rip), %xmm10
    pminub 128, %xmm11
    pminub %xmm5, %xmm4
    pminub 0(%rbx), %xmm1
    pminub -128(%rsi), %xmm2
    pminub -129(%rdi), %xmm3
    pminub 0(%rsp), %xmm6
    pminub 127(%rsp), %xmm7
    pminub -2147483648(%rsp), %xmm5
    pminub 0(%rax,%rax,1), %xmm4
    pminub -1(%rsi,%rcx,2), %xmm1
    pminub 2147483647(%rdi,%rdx,4), %xmm2
    pminub gnu_fwd(%rip), %xmm3
    pminub 4660, %xmm6
    pmaxub %xmm14, %xmm13
    pmaxub 0(%r8), %xmm8
    pmaxub 64(%r11), %xmm12
    pmaxub 128(%rdi), %xmm13
    pmaxub 0(%rsp), %xmm15
    pmaxub 8(%r12), %xmm9
    pmaxub -129(%rsp), %xmm10
    pmaxub 0(%rcx,%r12,8), %xmm11
    pmaxub -128(%rax,%rax,1), %xmm14
    pmaxub -2147483648(%r9,%r15,2), %xmm8
    pmaxub gnu_back(%rip), %xmm12
    pmaxub 2147483647, %xmm13
    pmaxub %xmm7, %xmm5
    pmaxub 0(%rsi), %xmm4
    pmaxub 127(%rcx), %xmm1
    pmaxub 4660(%rdx), %xmm2
    pmaxub 0(%rsp), %xmm3
    pmaxub -1(%rsp), %xmm6
    pmaxub 128(%rsp), %xmm7
    pmaxub 0(%rcx,%rbx,4), %xmm5
    pmaxub 64(%rax,%rbp,8), %xmm4
    pmaxub -129(%rcx,%rsi,1), %xmm1
    pmaxub gnu_fwd(%rip), %xmm2
    pmaxub -2147483648, %xmm3
    pminud %xmm15, %xmm6
    pminud 0(%rdx), %xmm9
    pminud 8(%r14), %xmm10
    pminud 2147483647(%r15), %xmm11
    pminud 0(%r12), %xmm14
    pminud -128(%rsp), %xmm8
    pminud 4660(%r12), %xmm12
    pminud 0(%r12,%rsi,2), %xmm13
    pminud 127(%rsp,%rcx,4), %xmm15
    pminud 128(%r13,%r9,8), %xmm9
    pminud gnu_back(%rip), %xmm10
    pminud -129, %xmm11
    pminud %xmm6, %xmm7
    pminud 0(%rdi), %xmm5
    pminud -1(%rbx), %xmm4
    pminud -2147483648(%rbp), %xmm1
    pminud 0(%rsp), %xmm2
    pminud 64(%rsp), %xmm3
    pminud 2147483647(%rsp), %xmm6
    pminud 0(%rdx,%rdi,1), %xmm7
    pminud 8(%rdx,%rax,2), %xmm5
    pminud 4660(%rbx,%rcx,4), %xmm4
    pminud gnu_fwd(%rip), %xmm1
    pminud 128, %xmm2
    paddb %xmm14, %xmm14
    paddb 0(%r9), %xmm8
    paddb -128(%rcx), %xmm12
    paddb -129(%r8), %xmm13
    paddb 0(%rsp), %xmm15
    paddb 127(%r12), %xmm9
    paddb -2147483648(%rsp), %xmm10
    paddb 0(%rdx,%rbp,8), %xmm11
    paddb -1(%rbp,%r12,1), %xmm14
    paddb 2147483647(%r12,%rax,2), %xmm8
    paddb gnu_back(%rip), %xmm12
    paddb 4660, %xmm13
    paddb %xmm3, %xmm6
    paddb 0(%rcx), %xmm7
    paddb 64(%rsi), %xmm5
    paddb 128(%rdi), %xmm4
    paddb 0(%rsp), %xmm1
    paddb 8(%rsp), %xmm2
    paddb -129(%rsp), %xmm3
    paddb 0(%rbx,%rdx,4), %xmm6
    paddb -128(%rsp,%rbx,8), %xmm7
    paddb -2147483648(%rbp,%rbp,1), %xmm5
    paddb gnu_fwd(%rip), %xmm4
    paddb 2147483647, %xmm1
    psubb %xmm15, %xmm7
    psubb 0(%rbx), %xmm9
    psubb 127(%rbp), %xmm10
    psubb 4660(%r13), %xmm11
    psubb 0(%r12), %xmm14
    psubb -1(%rsp), %xmm8
    psubb 128(%r12), %xmm12
    psubb 0(%r9,%r15,2), %xmm13
    psubb 64(%rdi,%rsi,4), %xmm15
    psubb -129(%r15,%rcx,8), %xmm9
    psubb gnu_back(%rip), %xmm10
    psubb -2147483648, %xmm11
    psubb %xmm2, %xmm3
    psubb 0(%rdx), %xmm6
    psubb 8(%rcx), %xmm7
    psubb 2147483647(%rdx), %xmm5
    psubb 0(%rsp), %xmm4
    psubb -128(%rsp), %xmm1
    psubb 4660(%rsp), %xmm2
    psubb 0(%rsp,%rsi,1), %xmm3
    psubb 127(%rsi,%rdi,2), %xmm6
    psubb 128(%rdi,%rax,4), %xmm7
    psubb gnu_fwd(%rip), %xmm5
    psubb -129, %xmm4
    pand %xmm14, %xmm15
    pand 0(%r10), %xmm8
    pand -1(%rdx), %xmm12
    pand -2147483648(%r9), %xmm13
    pand 0(%rsp), %xmm15
    pand 64(%r12), %xmm9
    pand 2147483647(%rsp), %xmm10
    pand 0(%rsp,%r9,8), %xmm11
    pand 8(%rax,%rbp,1), %xmm14
    pand 4660(%r9,%r12,2), %xmm8
    pand gnu_back(%rip), %xmm12
    pand 128, %xmm13
    pand %xmm1, %xmm2
    pand 0(%rbx), %xmm3
    pand -128(%rbx), %xmm6
    pand -129(%rbp), %xmm7
    pand 0(%rsp), %xmm5
    pand 127(%rsp), %xmm4
    pand -2147483648(%rsp), %xmm1
    pand 0(%rsi,%rcx,4), %xmm2
    pand -1(%rax,%rdx,8), %xmm3
    pand 2147483647(%rcx,%rbx,1), %xmm6
    pand gnu_fwd(%rip), %xmm7
    pand 4660, %xmm5
    pandn %xmm15, %xmm5
    pandn 0(%rsi), %xmm9
    pandn 64(%rbx), %xmm10
    pandn 128(%r10), %xmm11
    pandn 0(%r12), %xmm14
    pandn 8(%rsp), %xmm8
    pandn -129(%r12), %xmm12
    pandn 0(%r14,%rax,2), %xmm13
    pandn -128(%rsp,%r15,4), %xmm15
    pandn -2147483648(%r13,%rsi,8), %xmm9
    pandn gnu_back(%rip), %xmm10
    pandn 2147483647, %xmm11
    pandn %xmm4, %xmm1
    pandn 0(%rsi), %xmm2
    pandn 127(%rsi), %xmm3
    pandn 4660(%rdi), %xmm6
    pandn 0(%rsp), %xmm7
g38:
    pandn -1(%rsp), %xmm5
    pandn 128(%rsp), %xmm4
    pandn 0(%rdi,%rbp,1), %xmm1
    pandn 64(%rdx,%rsi,2), %xmm2
    pandn -129(%rbx,%rdi,4), %xmm3
    pandn gnu_fwd(%rip), %xmm6
    pandn -2147483648, %xmm7
    por %xmm14, %xmm8
    por 0(%r11), %xmm8
    por 8(%rsi), %xmm12
    por 2147483647(%r11), %xmm13
    por 0(%rsp), %xmm15
    por -128(%r12), %xmm9
    por 4660(%rsp), %xmm10
    por 0(%rsi,%rcx,8), %xmm11
    por 127(%rbp,%r9,1), %xmm14
    por 128(%r12,%rbp,2), %xmm8
    por gnu_back(%rip), %xmm12
    por -129, %xmm13
    por %xmm5, %xmm4
    por 0(%rdi), %xmm1
    por -1(%rcx), %xmm2
    por -2147483648(%rdx), %xmm3
    por 0(%rsp), %xmm6
    por 64(%rsp), %xmm7
    por 2147483647(%rsp), %xmm5
    por 0(%rax,%rax,4), %xmm4
    por 8(%rsp,%rcx,8), %xmm1
    por 4660(%rbp,%rdx,1), %xmm2
    por gnu_fwd(%rip), %xmm3
    por 128, %xmm6
    pxor %xmm15, %xmm1
    pxor 0(%rdi), %xmm9
    pxor -128(%rdi), %xmm10
    pxor -129(%r14), %xmm11
    pxor 0(%r12), %xmm14
    pxor 127(%rsp), %xmm8
    pxor -2147483648(%r12), %xmm12
    pxor 0(%r15,%r12,2), %xmm13
    pxor -1(%rdi,%rax,4), %xmm15
    pxor 2147483647(%r15,%r15,8), %xmm9
    pxor gnu_back(%rip), %xmm10
    pxor 4660, %xmm11
    pxor %xmm7, %xmm5
    pxor 0(%rcx), %xmm4
    pxor 64(%rbx), %xmm1
    pxor 128(%rbp), %xmm2
    pxor 0(%rsp), %xmm3
    pxor 8(%rsp), %xmm6
    pxor -129(%rsp), %xmm7
    pxor 0(%rcx,%rbx,1), %xmm5
    pxor -128(%rsi,%rbp,2), %xmm4
    pxor -2147483648(%rdi,%rsi,4), %xmm1
    pxor gnu_fwd(%rip), %xmm2
    pxor 2147483647, %xmm3
    punpcklbw %xmm14, %xmm9
    punpcklbw 0(%r14), %xmm8
    punpcklbw 127(%r15), %xmm12
    punpcklbw 4660(%rcx), %xmm13
    punpcklbw 0(%rsp), %xmm15
    punpcklbw -1(%r12), %xmm9
    punpcklbw 128(%rsp), %xmm10
    punpcklbw 0(%rax,%rsi,8), %xmm11
    punpcklbw 64(%rax,%rcx,1), %xmm14
    punpcklbw -129(%r9,%r9,2), %xmm8
    punpcklbw gnu_back(%rip), %xmm12
    punpcklbw -2147483648, %xmm13
    punpcklbw %xmm6, %xmm7
    punpcklbw 0(%rdx), %xmm5
    punpcklbw 8(%rsi), %xmm4
    punpcklbw 2147483647(%rdi), %xmm1
    punpcklbw 0(%rsp), %xmm2
    punpcklbw -128(%rsp), %xmm3
    punpcklbw 4660(%rsp), %xmm6
    punpcklbw 0(%rdx,%rdi,4), %xmm7
    punpcklbw 127(%rax,%rax,8), %xmm5
    punpcklbw 128(%rcx,%rcx,1), %xmm4
    punpcklbw gnu_fwd(%rip), %xmm1
    punpcklbw -129, %xmm2
    punpcklwd %xmm15, %xmm2
    punpcklwd 0(%r15), %xmm9
    punpcklwd -1(%r8), %xmm10
    punpcklwd -2147483648(%rbp), %xmm11
    punpcklwd 0(%r12), %xmm14
    punpcklwd 64(%rsp), %xmm8
    punpcklwd 2147483647(%r12), %xmm12
    punpcklwd 0(%r8,%rbp,2), %xmm13
    punpcklwd 8(%rsp,%r12,4), %xmm15
    punpcklwd 4660(%r13,%rax,8), %xmm9
    punpcklwd gnu_back(%rip), %xmm10
    punpcklwd 128, %xmm11
    punpcklwd %xmm3, %xmm6
    punpcklwd 0(%rbx), %xmm7
    punpcklwd -128(%rcx), %xmm5
    punpcklwd -129(%rdx), %xmm4
    punpcklwd 0(%rsp), %xmm1
    punpcklwd 127(%rsp), %xmm2
    punpcklwd -2147483648(%rsp), %xmm3
    punpcklwd 0(%rbx,%rdx,1), %xmm6
    punpcklwd -1(%rdx,%rbx,2), %xmm7
    punpcklwd 2147483647(%rbx,%rbp,4), %xmm5
    punpcklwd gnu_fwd(%rip), %xmm4
    punpcklwd 4660, %xmm1
    punpckldq %xmm14, %xmm12
    punpckldq 0(%rcx), %xmm8
    punpckldq 64(%r13), %xmm12
    punpckldq 128(%rdx), %xmm13
    punpckldq 0(%rsp), %xmm15
    punpckldq 8(%r12), %xmm9
    punpckldq -129(%rsp), %xmm10
    punpckldq 0(%rcx,%r15,8), %xmm11
    punpckldq -128(%rbp,%rsi,1), %xmm14
    punpckldq -2147483648(%r12,%rcx,2), %xmm8
    punpckldq gnu_back(%rip), %xmm12
    punpckldq 2147483647, %xmm13
    punpckldq %xmm2, %xmm3
    punpckldq 0(%rsi), %xmm6
    punpckldq 127(%rbx), %xmm7
    punpckldq 4660(%rbp), %xmm5
    punpckldq 0(%rsp), %xmm4
    punpckldq -1(%rsp), %xmm1
    punpckldq 128(%rsp), %xmm2
    punpckldq 0(%rsp,%rsi,4), %xmm3
    punpckldq 64(%rsp,%rdi,8), %xmm6
    punpckldq -129(%rbp,%rax,1), %xmm7
    punpckldq gnu_fwd(%rip), %xmm5
    punpckldq -2147483648, %xmm4
    movdqa %xmm15, %xmm3
    movdqa 0(%r8), %xmm9
    movdqa 8(%r9), %xmm10
    movdqa 2147483647(%rbx), %xmm11
    movdqa 0(%r12), %xmm14
    movdqa -128(%rsp), %xmm8
    movdqa 4660(%r12), %xmm12
    movdqa 0(%r12,%r9,2), %xmm13
    movdqa 127(%rdi,%rbp,4), %xmm15
    movdqa 128(%r15,%r12,8), %xmm9
    movdqa gnu_back(%rip), %xmm10
    movdqa -129, %xmm11
    movdqa %xmm1, %xmm2
    movdqa 0(%rdi), %xmm3
    movdqa -1(%rsi), %xmm6
    movdqa -2147483648(%rdi), %xmm7
    movdqa 0(%rsp), %xmm5
    movdqa 64(%rsp), %xmm4
    movdqa 2147483647(%rsp), %xmm1
    movdqa 0(%rsi,%rcx,1), %xmm2
    movdqa 8(%rsi,%rdx,2), %xmm3
    movdqa 4660(%rdi,%rbx,4), %xmm6
    movdqa gnu_fwd(%rip), %xmm7
    movdqa 128, %xmm5
    movdqu %xmm14, %xmm13
    movdqu 0(%rdx), %xmm8
    movdqu -128(%r10), %xmm12
    movdqu -129(%rsi), %xmm13
    movdqu 0(%rsp), %xmm15
    movdqu 127(%r12), %xmm9
    movdqu -2147483648(%rsp), %xmm10
    movdqu 0(%rdx,%rax,8), %xmm11
    movdqu -1(%rax,%r15,1), %xmm14
    movdqu 2147483647(%r9,%rsi,2), %xmm8
    movdqu gnu_back(%rip), %xmm12
    movdqu 4660, %xmm13
    movdqu %xmm4, %xmm1
    movdqu 0(%rcx), %xmm2
    movdqu 64(%rcx), %xmm3
    movdqu 128(%rdx), %xmm6
    movdqu 0(%rsp), %xmm7
    movdqu 8(%rsp), %xmm5
    movdqu -129(%rsp), %xmm4
    movdqu 0(%rdi,%rbp,4), %xmm1
    movdqu -128(%rax,%rsi,8), %xmm2
    movdqu -2147483648(%rcx,%rdi,1), %xmm3
    movdqu gnu_fwd(%rip), %xmm6
    movdqu 2147483647, %xmm7
    movaps 0(%r9), %xmm15
    movaps 127(%r11), %xmm9
    movaps 4660(%rdi), %xmm10
    movaps 0(%r12), %xmm11
    movaps -1(%rsp), %xmm14
    movaps 128(%r12), %xmm8
    movaps 0(%r9,%rcx,2), %xmm12
    movaps 64(%rsp,%r9,4), %xmm13
    movaps -129(%r13,%rbp,8), %xmm15
    movaps gnu_back(%rip), %xmm9
    movaps -2147483648, %xmm10
    movaps %xmm5, %xmm4
    movaps 0(%rdx), %xmm1
    movaps 8(%rbx), %xmm2
    movaps 2147483647(%rbp), %xmm3
    movaps 0(%rsp), %xmm6
    movaps -128(%rsp), %xmm7
    movaps 4660(%rsp), %xmm5
    movaps 0(%rax,%rax,1), %xmm4
    movaps 127(%rdx,%rcx,2), %xmm1
    movaps 128(%rbx,%rdx,4), %xmm2
    movaps gnu_fwd(%rip), %xmm3
    movaps -129, %xmm6
    movups %xmm11, %xmm6
    movups 0(%rbx), %xmm14
g39:
    movups -1(%r14), %xmm8
    movups -2147483648(%r15), %xmm12
    movups 0(%rsp), %xmm13
    movups 64(%r12), %xmm15
    movups 2147483647(%rsp), %xmm9
    movups 0(%rsp,%r12,8), %xmm10
    movups 8(%rbp,%rax,1), %xmm11
    movups 4660(%r12,%r15,2), %xmm14
    movups gnu_back(%rip), %xmm8
    movups 128, %xmm12
    movups %xmm7, %xmm5
    movups 0(%rbx), %xmm4
    movups -128(%rsi), %xmm1
    movups -129(%rdi), %xmm2
    movups 0(%rsp), %xmm3
    movups 127(%rsp), %xmm6
    movups -2147483648(%rsp), %xmm7
    movups 0(%rcx,%rbx,4), %xmm5
    movups -1(%rsp,%rbp,8), %xmm4
    movups 2147483647(%rbp,%rsi,1), %xmm1
    movups gnu_fwd(%rip), %xmm2
    movups 4660, %xmm3
    movdqa %xmm13, 0(%r10)
    movdqa %xmm15, 64(%rcx)
    movdqa %xmm9, 128(%r8)
    movdqa %xmm10, 0(%r12)
    movdqa %xmm11, 8(%rsp)
    movdqa %xmm14, -129(%r12)
    movdqa %xmm8, 0(%r14,%rsi,2)
    movdqa %xmm12, -128(%rdi,%rcx,4)
    movdqa %xmm13, -2147483648(%r15,%r9,8)
    movdqa %xmm15, gnu_back(%rip)
    movdqa %xmm9, 2147483647
    movdqa %xmm6, 0(%rsi)
    movdqa %xmm7, 127(%rcx)
    movdqa %xmm5, 4660(%rdx)
    movdqa %xmm4, 0(%rsp)
    movdqa %xmm1, -1(%rsp)
    movdqa %xmm2, 128(%rsp)
    movdqa %xmm3, 0(%rdx,%rdi,1)
    movdqa %xmm6, 64(%rsi,%rax,2)
    movdqa %xmm7, -129(%rdi,%rcx,4)
    movdqa %xmm5, gnu_fwd(%rip)
    movdqa %xmm4, -2147483648
    movdqu %xmm10, 0(%rsi)
    movdqu %xmm11, 8(%rbp)
    movdqu %xmm14, 2147483647(%r13)
    movdqu %xmm8, 0(%rsp)
    movdqu %xmm12, -128(%r12)
    movdqu %xmm13, 4660(%rsp)
    movdqu %xmm15, 0(%rsi,%rbp,8)
    movdqu %xmm9, 127(%rax,%r12,1)
    movdqu %xmm10, 128(%r9,%rax,2)
    movdqu %xmm11, gnu_back(%rip)
    movdqu %xmm14, -129
    movdqu %xmm1, 0(%rdi)
    movdqu %xmm2, -1(%rbx)
    movdqu %xmm3, -2147483648(%rbp)
    movdqu %xmm6, 0(%rsp)
    movdqu %xmm7, 64(%rsp)
    movdqu %xmm5, 2147483647(%rsp)
    movdqu %xmm4, 0(%rbx,%rdx,4)
    movdqu %xmm1, 8(%rax,%rbx,8)
    movdqu %xmm2, 4660(%rcx,%rbp,1)
    movdqu %xmm3, gnu_fwd(%rip)
    movdqu %xmm6, 128
    movaps %xmm8, 0(%r11)
    movaps %xmm12, -128(%rdx)
    movaps %xmm13, -129(%r9)
    movaps %xmm15, 0(%r12)
    movaps %xmm9, 127(%rsp)
    movaps %xmm10, -2147483648(%r12)
    movaps %xmm11, 0(%r15,%r15,2)
    movaps %xmm14, -1(%rsp,%rsi,4)
    movaps %xmm8, 2147483647(%r13,%rcx,8)
    movaps %xmm12, gnu_back(%rip)
    movaps %xmm13, 4660
    movaps %xmm7, 0(%rcx)
    movaps %xmm5, 64(%rsi)
    movaps %xmm4, 128(%rdi)
    movaps %xmm1, 0(%rsp)
    movaps %xmm2, 8(%rsp)
    movaps %xmm3, -129(%rsp)
    movaps %xmm6, 0(%rsp,%rsi,1)
    movaps %xmm7, -128(%rdx,%rdi,2)
    movaps %xmm5, -2147483648(%rbx,%rax,4)
    movaps %xmm4, gnu_fwd(%rip)
    movaps %xmm1, 2147483647
    movups %xmm15, 0(%rdi)
    movups %xmm9, 127(%rbx)
    movups %xmm10, 4660(%r10)
    movups %xmm11, 0(%rsp)
    movups %xmm14, -1(%r12)
    movups %xmm8, 128(%rsp)
    movups %xmm12, 0(%rax,%r9,8)
    movups %xmm13, 64(%rbp,%rbp,1)
    movups %xmm15, -129(%r12,%r12,2)
    movups %xmm9, gnu_back(%rip)
    movups %xmm10, -2147483648
    movups %xmm2, 0(%rdx)
    movups %xmm3, 8(%rcx)
    movups %xmm6, 2147483647(%rdx)
    movups %xmm7, 0(%rsp)
    movups %xmm5, -128(%rsp)
    movups %xmm4, 4660(%rsp)
    movups %xmm1, 0(%rsi,%rcx,4)
    movups %xmm2, 127(%rsp,%rdx,8)
    movups %xmm3, 128(%rbp,%rbx,1)
    movups %xmm6, gnu_fwd(%rip)
    movups %xmm7, -129
    movntdq %xmm11, 0(%r14)
    movntdq %xmm14, -1(%rsi)
    movntdq %xmm8, -2147483648(%r11)
    movntdq %xmm12, 0(%r12)
    movntdq %xmm13, 64(%rsp)
    movntdq %xmm15, 2147483647(%r12)
    movntdq %xmm9, 0(%r8,%rax,2)
    movntdq %xmm10, 8(%rdi,%r15,4)
    movntdq %xmm11, 4660(%r15,%rsi,8)
    movntdq %xmm14, gnu_back(%rip)
    movntdq %xmm8, 128
    movntdq %xmm5, 0(%rbx)
    movntdq %xmm4, -128(%rbx)
    movntdq %xmm1, -129(%rbp)
    movntdq %xmm2, 0(%rsp)
    movntdq %xmm3, 127(%rsp)
    movntdq %xmm6, -2147483648(%rsp)
    movntdq %xmm7, 0(%rdi,%rbp,1)
    movntdq %xmm5, -1(%rsi,%rsi,2)
    movntdq %xmm4, 2147483647(%rdi,%rdi,4)
    movntdq %xmm1, gnu_fwd(%rip)
    movntdq %xmm2, 4660
    movntps %xmm12, 0(%r15)
    movntps %xmm13, 64(%rdi)
    movntps %xmm15, 128(%r14)
    movntps %xmm9, 0(%rsp)
    movntps %xmm10, 8(%r12)
    movntps %xmm11, -129(%rsp)
    movntps %xmm14, 0(%rcx,%rcx,8)
    movntps %xmm8, -128(%rax,%r9,1)
    movntps %xmm12, -2147483648(%r9,%rbp,2)
    movntps %xmm13, gnu_back(%rip)
    movntps %xmm15, 2147483647
    movntps %xmm3, 0(%rsi)
    movntps %xmm6, 127(%rsi)
    movntps %xmm7, 4660(%rdi)
    movntps %xmm5, 0(%rsp)
    movntps %xmm4, -1(%rsp)
    movntps %xmm1, 128(%rsp)
    movntps %xmm2, 0(%rax,%rax,4)
    movntps %xmm3, 64(%rax,%rcx,8)
    movntps %xmm6, -129(%rcx,%rdx,1)
    movntps %xmm7, gnu_fwd(%rip)
    movntps %xmm5, -2147483648
    movhpd 0(%rcx), %xmm9
    movhpd 8(%r15), %xmm10
    movhpd 2147483647(%rcx), %xmm11
    movhpd 0(%r12), %xmm14
    movhpd -128(%rsp), %xmm8
    movhpd 4660(%r12), %xmm12
    movhpd 0(%r12,%r12,2), %xmm13
    movhpd 127(%rsp,%rax,4), %xmm15
    movhpd 128(%r13,%r15,8), %xmm9
    movhpd gnu_back(%rip), %xmm10
    movhpd -129, %xmm11
    movhpd 0(%rdi), %xmm4
    movhpd -1(%rcx), %xmm1
    movhpd -2147483648(%rdx), %xmm2
    movhpd 0(%rsp), %xmm3
    movhpd 64(%rsp), %xmm6
    movhpd 2147483647(%rsp), %xmm7
    movhpd 0(%rcx,%rbx,1), %xmm5
    movhpd 8(%rdx,%rbp,2), %xmm4
    movhpd 4660(%rbx,%rsi,4), %xmm1
    movhpd gnu_fwd(%rip), %xmm2
    movhpd 128, %xmm3
    movlpd 0(%r8), %xmm14
    movlpd -128(%r8), %xmm8
    movlpd -129(%rbp), %xmm12
    movlpd 0(%rsp), %xmm13
    movlpd 127(%r12), %xmm15
    movlpd -2147483648(%rsp), %xmm9
    movlpd 0(%rdx,%rsi,8), %xmm10
    movlpd -1(%rbp,%rcx,1), %xmm11
    movlpd 2147483647(%r12,%r9,2), %xmm14
    movlpd gnu_back(%rip), %xmm8
    movlpd 4660, %xmm12
    movlpd 0(%rcx), %xmm6
    movlpd 64(%rbx), %xmm7
    movlpd 128(%rbp), %xmm5
    movlpd 0(%rsp), %xmm4
    movlpd 8(%rsp), %xmm1
    movlpd -129(%rsp), %xmm2
    movlpd 0(%rdx,%rdi,4), %xmm3
    movlpd -128(%rsp,%rax,8), %xmm6
    movlpd -2147483648(%rbp,%rcx,1), %xmm7
    movlpd gnu_fwd(%rip), %xmm5
    movlpd 2147483647, %xmm4
    pshufd $63, %xmm13, %xmm14
    pshufd $7, 0(%rdx), %xmm15
g40:
    pshufd $0, 127(%r13), %xmm9
    pshufd $255, 4660(%rdx), %xmm10
    pshufd $63, 0(%r12), %xmm11
    pshufd $7, -1(%rsp), %xmm14
    pshufd $0, 128(%r12), %xmm8
    pshufd $255, 0(%r9,%rbp,2), %xmm12
    pshufd $63, 64(%rdi,%r12,4), %xmm13
    pshufd $7, -129(%r15,%rax,8), %xmm15
    pshufd $0, gnu_back(%rip), %xmm9
    pshufd $255, -2147483648, %xmm10
    pshufd $63, %xmm1, %xmm2
    pshufd $7, 0(%rdx), %xmm3
    pshufd $0, 8(%rsi), %xmm6
    pshufd $255, 2147483647(%rdi), %xmm7
    pshufd $63, 0(%rsp), %xmm5
    pshufd $7, -128(%rsp), %xmm4
    pshufd $0, 4660(%rsp), %xmm1
    pshufd $255, 0(%rbx,%rdx,1), %xmm2
    pshufd $63, 127(%rsi,%rbx,2), %xmm3
    pshufd $7, 128(%rdi,%rbp,4), %xmm6
    pshufd $0, gnu_fwd(%rip), %xmm7
    pshufd $255, -129, %xmm5
    palignr $63, %xmm11, %xmm7
    palignr $7, 0(%r9), %xmm14
    palignr $0, -1(%r9), %xmm8
    palignr $255, -2147483648(%rbx), %xmm12
    palignr $63, 0(%rsp), %xmm13
    palignr $7, 64(%r12), %xmm15
    palignr $0, 2147483647(%rsp), %xmm9
    palignr $255, 0(%rsp,%r15,8), %xmm10
    palignr $63, 8(%rax,%rsi,1), %xmm11
    palignr $7, 4660(%r9,%rcx,2), %xmm14
    palignr $0, gnu_back(%rip), %xmm8
    palignr $255, 128, %xmm12
    palignr $63, %xmm4, %xmm1
    palignr $7, 0(%rbx), %xmm2
    palignr $0, -128(%rcx), %xmm3
    palignr $255, -129(%rdx), %xmm6
    palignr $63, 0(%rsp), %xmm7
    palignr $7, 127(%rsp), %xmm5
    palignr $0, -2147483648(%rsp), %xmm4
    palignr $255, 0(%rsp,%rsi,4), %xmm1
    palignr $63, -1(%rax,%rdi,8), %xmm2
    palignr $7, 2147483647(%rcx,%rax,1), %xmm3
    palignr $0, gnu_fwd(%rip), %xmm6
    palignr $255, 4660, %xmm7
    pcmpistri $63, %xmm13, %xmm15
    pcmpistri $7, 0(%rbx), %xmm15
    pcmpistri $0, 64(%r10), %xmm9
    pcmpistri $255, 128(%rsi), %xmm10
    pcmpistri $63, 0(%r12), %xmm11
    pcmpistri $7, 8(%rsp), %xmm14
    pcmpistri $0, -129(%r12), %xmm8
    pcmpistri $255, 0(%r14,%r9,2), %xmm12
    pcmpistri $63, -128(%rsp,%rbp,4), %xmm13
    pcmpistri $7, -2147483648(%r13,%r12,8), %xmm15
    pcmpistri $0, gnu_back(%rip), %xmm9
    pcmpistri $255, 2147483647, %xmm10
    pcmpistri $63, %xmm5, %xmm4
    pcmpistri $7, 0(%rsi), %xmm1
    pcmpistri $0, 127(%rbx), %xmm2
    pcmpistri $255, 4660(%rbp), %xmm3
    pcmpistri $63, 0(%rsp), %xmm6
    pcmpistri $7, -1(%rsp), %xmm7
    pcmpistri $0, 128(%rsp), %xmm5
    pcmpistri $255, 0(%rsi,%rcx,1), %xmm4
    pcmpistri $63, 64(%rdx,%rdx,2), %xmm1
    pcmpistri $7, -129(%rbx,%rbx,4), %xmm2
    pcmpistri $0, gnu_fwd(%rip), %xmm3
    pcmpistri $255, -2147483648, %xmm6
    roundsd $63, %xmm11, %xmm5
    roundsd $7, 0(%r10), %xmm14
    roundsd $0, 8(%r11), %xmm8
    roundsd $255, 2147483647(%rdi), %xmm12
    roundsd $63, 0(%rsp), %xmm13
    roundsd $7, -128(%r12), %xmm15
    roundsd $0, 4660(%rsp), %xmm9
    roundsd $255, 0(%rsi,%rax,8), %xmm10
    roundsd $63, 127(%rbp,%r15,1), %xmm11
    roundsd $7, 128(%r12,%rsi,2), %xmm14
    roundsd $0, gnu_back(%rip), %xmm8
    roundsd $255, -129, %xmm12
    roundsd $63, %xmm7, %xmm5
    roundsd $7, 0(%rdi), %xmm4
    roundsd $0, -1(%rsi), %xmm1
    roundsd $255, -2147483648(%rdi), %xmm2
    roundsd $63, 0(%rsp), %xmm3
    roundsd $7, 64(%rsp), %xmm6
    roundsd $0, 2147483647(%rsp), %xmm7
    roundsd $255, 0(%rdi,%rbp,4), %xmm5
    roundsd $63, 8(%rsp,%rsi,8), %xmm4
    roundsd $7, 4660(%rbp,%rdi,1), %xmm1
    roundsd $0, gnu_fwd(%rip), %xmm2
    roundsd $255, 128, %xmm3
    roundss $63, %xmm13, %xmm8
    roundss $7, 0(%rsi), %xmm15
    roundss $0, -128(%r14), %xmm9
    roundss $255, -129(%r15), %xmm10
    roundss $63, 0(%r12), %xmm11
    roundss $7, 127(%rsp), %xmm14
    roundss $0, -2147483648(%r12), %xmm8
    roundss $255, 0(%r15,%rcx,2), %xmm12
    roundss $63, -1(%rdi,%r9,4), %xmm13
    roundss $7, 2147483647(%r15,%rbp,8), %xmm15
    roundss $0, gnu_back(%rip), %xmm9
    roundss $255, 4660, %xmm10
    roundss $63, %xmm6, %xmm7
    roundss $7, 0(%rcx), %xmm5
    roundss $0, 64(%rcx), %xmm4
    roundss $255, 128(%rdx), %xmm1
    roundss $63, 0(%rsp), %xmm2
    roundss $7, 8(%rsp), %xmm3
    roundss $0, -129(%rsp), %xmm6
    roundss $255, 0(%rax,%rax,1), %xmm7
    roundss $63, -128(%rsi,%rcx,2), %xmm5
    roundss $7, -2147483648(%rdi,%rdx,4), %xmm4
    roundss $0, gnu_fwd(%rip), %xmm1
    roundss $255, 2147483647, %xmm2
    pslldq $63, %xmm11
    pslldq $7, %xmm3
    psrldq $0, %xmm14
    psrldq $255, %xmm6
    pmovmskb %xmm8, %ecx
    pmovmskb %xmm7, %ebp
    movd %esp, %xmm1
    movd %xmm2, %ebx
    cvtsd2si %xmm12, %r9
    cvtss2si %xmm13, %rdx
    movq 0(%r11), %xmm15
    movq 127(%rcx), %xmm9
    movq 4660(%r8), %xmm10
    movq 0(%rsp), %xmm11
    movq -1(%r12), %xmm14
    movq 128(%rsp), %xmm8
    movq 0(%rax,%r12,8), %xmm12
    movq 64(%rax,%rax,1), %xmm13
    movq -129(%r9,%r15,2), %xmm15
    movq gnu_back(%rip), %xmm9
    movq -2147483648, %xmm10
    movq 0(%rdx), %xmm6
    movq 8(%rbx), %xmm7
    movq 2147483647(%rbp), %xmm5
    movq 0(%rsp), %xmm4
    movq -128(%rsp), %xmm1
    movq 4660(%rsp), %xmm2
    movq 0(%rcx,%rbx,4), %xmm3
    movq 127(%rax,%rbp,8), %xmm6
    movq 128(%rcx,%rsi,1), %xmm7
    movq gnu_fwd(%rip), %xmm5
    movq -129, %xmm4
    movq %xmm11, 0(%rdi)
    movq %xmm14, -1(%rbp)
    movq %xmm8, -2147483648(%r13)
    movq %xmm12, 0(%r12)
    movq %xmm13, 64(%rsp)
    movq %xmm15, 2147483647(%r12)
    movq %xmm9, 0(%r8,%rsi,2)
    movq %xmm10, 8(%rsp,%rcx,4)
    movq %xmm11, 4660(%r13,%r9,8)
    movq %xmm14, gnu_back(%rip)
    movq %xmm8, 128
    movq %xmm1, 0(%rbx)
    movq %xmm2, -128(%rsi)
    movq %xmm3, -129(%rdi)
    movq %xmm6, 0(%rsp)
    movq %xmm7, 127(%rsp)
    movq %xmm5, -2147483648(%rsp)
    movq %xmm4, 0(%rdx,%rdi,1)
    movq %xmm1, -1(%rdx,%rax,2)
    movq %xmm2, 2147483647(%rbx,%rcx,4)
    movq %xmm3, gnu_fwd(%rip)
    movq %xmm6, 4660
gnu_fwd:
