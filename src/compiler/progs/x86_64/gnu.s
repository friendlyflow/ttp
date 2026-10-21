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
    movb %spl, 2147483647(,%rsi,8)
    movb %bh, %ch
    movb %ah, 0(%rsi)
    movb %cl, -1(%rbx)
    movb %dl, 4660(%rbp)
    movb %bl, 0(%rsp)
    movb %dh, 64(%rsp)
    movb %bh, 128(%rsp)
    movb %ch, 0(%rsp,%rsi,1)
    movb %ah, 8(%rax,%rdi,2)
    movb %cl, -129(%rcx,%rax,4)
    movb %dl, gnu_back(%rip)
    movb %bl, -2147483648
    movb %dh, 2147483647(,%rcx,8)
    movb 0(%rbx), %r13b
    movb -128(%rbx), %bpl
    movb 4660(%r10), %r15b
    movb 0(%r12), %sil
    movb 127(%rsp), %dil
    movb 128(%r12), %r8b
    movb 0(%r8,%rcx,1), %r12b
    movb -1(%rsp,%r9,2), %spl
    movb -129(%r13,%rbp,4), %r13b
    movb -2147483648, %bpl
    movb 2147483647(,%r12,8), %r15b
    movb 0(%rdi), %bh
    movb 64(%rsi), %ch
    movb 4660(%rdi), %ah
    movb 0(%rsp), %cl
    movb 8(%rsp), %dl
    movb 128(%rsp), %bl
    movb 0(%rsi,%rdx,1), %dh
    movb -128(%rdx,%rbx,2), %bh
    movb -129(%rbx,%rbp,4), %ch
    movb gnu_fwd(%rip), %ah
    movb -2147483648, %cl
    movb 2147483647(,%rsi,8), %dl
    movb $-128, 0(%r14)
    movb $127, 127(%r11)
    movb $255, 4660(%r13)
    movb $-128, 0(%r12)
    movb $127, -1(%r12)
    movb $255, 128(%r12)
    movb $-128, 0(%r14,%rax,1)
    movb $127, 64(%r8,%r15,2)
    movb $255, -129(%r9,%rsi,4)
    movb $-128, 0(%rcx)
    movb $127, 8(%rcx)
    movb $255, -2147483648(%rdx)
    movb $-128, 0(%rsp)
    movb $127, -128(%rsp)
    movb $255, 2147483647(%rsp)
    movb $-128, 0(%rdi,%rdi,8)
    movb $127, 127(%rsp,%rax,1)
    movb $255, 4660(%rbp,%rcx,2)
    movb $-128, gnu_back(%rip)
    movb $127, 128
    testb %sil, 0(%r10)
    testb %dil, -1(%rsi)
    testb %r8b, -129(%r11)
    testb %r12b, 0(%rsp)
    testb %spl, 64(%r12)
    testb %r13b, -2147483648(%rsp)
    testb %bpl, 0(%rcx,%rcx,4)
    testb %r15b, 8(%rbp,%r9,8)
    testb %sil, 2147483647(%r12,%rbp,1)
    testb %dil, gnu_fwd(%rip)
    testb %r8b, 4660
    testb %bl, %dh
    testb %bh, 0(%rdx)
    testb %ch, -128(%rbx)
    testb %ah, 128(%rbp)
    testb %cl, 0(%rsp)
    testb %dl, 127(%rsp)
    testb %bl, -129(%rsp)
    testb %dh, 0(%rax,%rdx,2)
    testb %bh, -1(%rsi,%rbx,4)
    testb %ch, -2147483648(%rdi,%rbp,8)
    testb %ah, gnu_back(%rip)
g12:
    testb %cl, 2147483647
    testb $255, 0(%r15)
    testb $-128, 64(%r14)
    testb $127, 4660(%r15)
    testb $255, 0(%r12)
    testb $-128, 8(%r12)
    testb $127, 128(%r12)
    testb $255, 0(%r15,%r12,1)
    testb $-128, -128(%r12,%rax,2)
    testb $127, -129(%r13,%r15,4)
    testb $255, %dl
    testb $-128, 0(%rbx)
    testb $127, 127(%rsi)
    testb $255, -2147483648(%rdi)
    testb $-128, 0(%rsp)
    testb $127, -1(%rsp)
    testb $255, 2147483647(%rsp)
    testb $-128, 0(%rcx,%rsi,8)
    testb $127, 64(%rax,%rdi,1)
    testb $255, 4660(%rcx,%rax,2)
    testb $-128, gnu_fwd(%rip)
    testb $127, 128
    xchgb %r12b, 0(%rsi)
    xchgb %spl, 8(%rdi)
    xchgb %r13b, -129(%r14)
    xchgb %bpl, 0(%r12)
    xchgb %r15b, -128(%rsp)
    xchgb %sil, -2147483648(%r12)
    xchgb %dil, 0(%r12,%rsi,4)
    xchgb %r8b, 127(%rdi,%rcx,8)
    xchgb %r12b, 2147483647(%r15,%r9,1)
    xchgb %spl, gnu_back(%rip)
    xchgb %r13b, 4660
    xchgb %bl, %dh
    xchgb %bh, 0(%rsi)
    xchgb %ch, -1(%rcx)
    xchgb %ah, 128(%rdx)
    xchgb %cl, 0(%rsp)
    xchgb %dl, 64(%rsp)
    xchgb %bl, -129(%rsp)
    xchgb %dh, 0(%rdx,%rcx,2)
    xchgb %bh, 8(%rdx,%rdx,4)
    xchgb %ch, -2147483648(%rbx,%rbx,8)
    xchgb %ah, gnu_fwd(%rip)
    xchgb %cl, 2147483647
    movw %r8w, 0(%r11)
    movw %r12w, -128(%r15)
    movw %r13w, 4660(%rcx)
    movw %r15w, 0(%rsp)
    movw %r9w, 127(%r12)
    movw %r10w, 128(%rsp)
    movw %r11w, 0(%rdx,%rbp,1)
    movw %r14w, -1(%rax,%r12,2)
    movw %r8w, -129(%r9,%rax,4)
    movw %r12w, -2147483648
    movw %r13w, 2147483647(,%r15,8)
    movw %bp, %sp
    movw %cx, 0(%rdi)
    movw %dx, 64(%rbx)
    movw %bx, 4660(%rbp)
    movw %si, 0(%rsp)
    movw %di, 8(%rsp)
    movw %bp, 128(%rsp)
    movw %sp, 0(%rbx,%rbp,1)
    movw %cx, -128(%rsp,%rsi,2)
    movw %dx, -129(%rbp,%rdi,4)
    movw %bx, gnu_back(%rip)
    movw %si, -2147483648
    movw %di, 2147483647(,%rax,8)
    movw 0(%rdi), %r15w
    movw 127(%r8), %r9w
    movw 4660(%rbp), %r10w
    movw 0(%r12), %r11w
    movw -1(%rsp), %r14w
    movw 128(%r12), %r8w
    movw 0(%r9,%rsi,1), %r12w
    movw 64(%rsp,%rcx,2), %r13w
    movw -129(%r13,%r9,4), %r15w
    movw -2147483648, %r9w
    movw 2147483647(,%rbp,8), %r10w
    movw 0(%rcx), %bp
    movw 8(%rsi), %sp
    movw 4660(%rdi), %cx
    movw 0(%rsp), %dx
    movw -128(%rsp), %bx
    movw 128(%rsp), %si
    movw 0(%rsp,%rcx,1), %di
    movw 127(%rsi,%rdx,2), %bp
    movw -129(%rdi,%rbx,4), %sp
    movw gnu_fwd(%rip), %cx
    movw -2147483648, %dx
    movw 2147483647(,%rbp,8), %bx
    movw $32767, 0(%r8)
    movw $4660, -1(%r8)
    movw $200, 4660(%r9)
    movw $-32768, 0(%r12)
    movw $32767, 64(%r12)
    movw $4660, 128(%r12)
    movw $200, 0(%r8,%r12,1)
    movw $-32768, 8(%r15,%rax,2)
    movw $32767, -129(%r8,%r15,4)
    movw $4660, 0(%rdx)
    movw $200, -128(%rcx)
    movw $-32768, -2147483648(%rdx)
    movw $32767, 0(%rsp)
    movw $4660, 127(%rsp)
    movw $200, 2147483647(%rsp)
    movw $-32768, 0(%rsi,%rsi,8)
    movw $32767, -1(%rax,%rdi,1)
    movw $4660, 4660(%rcx,%rax,2)
    movw $200, gnu_back(%rip)
    movw $-32768, 128
    testw %r11w, 0(%r14)
    testw %r14w, 64(%r13)
    testw %r8w, -129(%rdx)
    testw %r12w, 0(%rsp)
    testw %r13w, 8(%r12)
    testw %r15w, -2147483648(%rsp)
    testw %r9w, 0(%rsp,%rsi,4)
    testw %r10w, -128(%rbp,%rcx,8)
    testw %r11w, 2147483647(%r12,%r9,1)
    testw %r14w, gnu_fwd(%rip)
    testw %r8w, 4660
    testw %si, %di
    testw %bp, 0(%rbx)
    testw %sp, 127(%rbx)
    testw %cx, 128(%rbp)
    testw %dx, 0(%rsp)
    testw %bx, -1(%rsp)
    testw %si, -129(%rsp)
    testw %di, 0(%rdi,%rcx,2)
    testw %bp, 64(%rdx,%rdx,4)
    testw %sp, -2147483648(%rbx,%rbx,8)
    testw %cx, gnu_back(%rip)
    testw %dx, 2147483647
    testw $32767, 0(%r9)
    testw $4660, 8(%r10)
    testw $200, 4660(%r11)
    testw $-32768, 0(%r12)
    testw $32767, -128(%r12)
    testw $4660, 128(%r12)
    testw $200, 0(%r9,%rbp,1)
    testw $-32768, 127(%r9,%r12,2)
    testw $32767, -129(%r12,%rax,4)
    testw $4660, %bx
    testw $200, 0(%rsi)
    testw $-32768, -1(%rsi)
    testw $32767, -2147483648(%rdi)
    testw $4660, 0(%rsp)
    testw $200, 64(%rsp)
    testw $-32768, 2147483647(%rsp)
    testw $32767, 0(%rax,%rbp,8)
    testw $4660, 8(%rsp,%rsi,1)
    testw $200, 4660(%rbp,%rdi,2)
    testw $-32768, gnu_fwd(%rip)
    testw $32767, 128
    xchgw %r12w, 0(%r15)
    xchgw %r13w, -128(%r9)
    xchgw %r15w, -129(%rbx)
    xchgw %r9w, 0(%r12)
    xchgw %r10w, 127(%rsp)
    xchgw %r11w, -2147483648(%r12)
    xchgw %r14w, 0(%r14,%r15,4)
    xchgw %r8w, -1(%rdi,%rsi,8)
    xchgw %r12w, 2147483647(%r15,%rcx,1)
    xchgw %r13w, gnu_back(%rip)
    xchgw %r15w, 4660
    xchgw %si, %di
    xchgw %bp, 0(%rdi)
    xchgw %sp, 64(%rcx)
    xchgw %cx, 128(%rdx)
    xchgw %dx, 0(%rsp)
    xchgw %bx, 8(%rsp)
    xchgw %si, -129(%rsp)
    xchgw %di, 0(%rcx,%rax,2)
    xchgw %bp, -128(%rsi,%rcx,4)
    xchgw %sp, -2147483648(%rdi,%rdx,8)
    xchgw %cx, gnu_fwd(%rip)
    xchgw %dx, 2147483647
    movl %r9d, 0(%rcx)
    movl %r10d, 127(%r10)
    movl %r11d, 4660(%rsi)
    movl %r14d, 0(%rsp)
    movl %r8d, -1(%r12)
    movl %r12d, 128(%rsp)
    movl %r13d, 0(%rsi,%r9,1)
    movl %r15d, 64(%rax,%rbp,2)
    movl %r9d, -129(%r9,%r12,4)
    movl %r10d, -2147483648
    movl %r11d, 2147483647(,%rax,8)
    movl %ebx, %esi
    movl %edi, 0(%rcx)
    movl %ebp, 8(%rbx)
    movl %esp, 4660(%rbp)
    movl %ecx, 0(%rsp)
    movl %edx, -128(%rsp)
    movl %ebx, 128(%rsp)
    movl %esi, 0(%rdx,%rbx,1)
    movl %edi, 127(%rax,%rbp,2)
    movl %ebp, -129(%rcx,%rsi,4)
g13:
    movl %esp, gnu_back(%rip)
    movl %ecx, -2147483648
    movl %edx, 2147483647(,%rdi,8)
    movl 0(%r8), %r14d
    movl -1(%r11), %r8d
    movl 4660(%rdi), %r12d
    movl 0(%r12), %r13d
    movl 64(%rsp), %r15d
    movl 128(%r12), %r9d
    movl 0(%r15,%r15,1), %r10d
    movl 8(%rsp,%rsi,2), %r11d
    movl -129(%r13,%rcx,4), %r14d
    movl -2147483648, %r8d
    movl 2147483647(,%r9,8), %r12d
    movl 0(%rdx), %ebx
    movl -128(%rsi), %esi
    movl 4660(%rdi), %edi
    movl 0(%rsp), %ebp
    movl 127(%rsp), %esp
    movl 128(%rsp), %ecx
    movl 0(%rbx,%rax,1), %edx
    movl -1(%rdx,%rcx,2), %ebx
    movl -129(%rbx,%rdx,4), %esi
    movl gnu_fwd(%rip), %edi
    movl -2147483648, %ebp
    movl 2147483647(,%rbx,8), %esp
    movl $305419896, 0(%r10)
    movl $1000, 64(%r13)
    movl $-2147483648, 4660(%r14)
    movl $2147483647, 0(%r12)
    movl $305419896, 8(%r12)
    movl $1000, 128(%r12)
    movl $-2147483648, 0(%r10,%rbp,1)
    movl $2147483647, -128(%r13,%r12,2)
    movl $305419896, -129(%r15,%rax,4)
    movl $1000, 0(%rbx)
    movl $-2147483648, 127(%rcx)
    movl $2147483647, -2147483648(%rdx)
    movl $305419896, 0(%rsp)
    movl $1000, -1(%rsp)
    movl $-2147483648, 2147483647(%rsp)
    movl $2147483647, 0(%rsp,%rbp,8)
    movl $305419896, 64(%rsp,%rsi,1)
    movl $1000, 4660(%rbp,%rdi,2)
    movl $-2147483648, gnu_back(%rip)
    movl $2147483647, 128
    testl %r13d, 0(%rdx)
    testl %r15d, 8(%r14)
    testl %r9d, -129(%r15)
    testl %r10d, 0(%rsp)
    testl %r11d, -128(%r12)
    testl %r14d, -2147483648(%rsp)
    testl %r8d, 0(%rax,%r15,4)
    testl %r12d, 127(%rbp,%rsi,8)
    testl %r13d, 2147483647(%r12,%rcx,1)
    testl %r15d, gnu_fwd(%rip)
    testl %r9d, 4660
    testl %ecx, %edx
    testl %ebx, 0(%rsi)
    testl %esi, -1(%rbx)
    testl %edi, 128(%rbp)
    testl %ebp, 0(%rsp)
    testl %esp, 64(%rsp)
    testl %ecx, -129(%rsp)
    testl %edx, 0(%rsi,%rax,2)
    testl %ebx, 8(%rsi,%rcx,4)
    testl %esi, -2147483648(%rdi,%rdx,8)
    testl %edi, gnu_back(%rip)
    testl %ebp, 2147483647
    testl $305419896, 0(%r11)
    testl $1000, -128(%r15)
    testl $-2147483648, 4660(%r8)
    testl $2147483647, 0(%r12)
    testl $305419896, 127(%r12)
    testl $1000, 128(%r12)
    testl $-2147483648, 0(%r11,%r9,1)
    testl $2147483647, -1(%r8,%rbp,2)
    testl $305419896, -129(%r9,%r12,4)
    testl $1000, %esp
    testl $-2147483648, 0(%rdi)
    testl $2147483647, 64(%rsi)
    testl $305419896, -2147483648(%rdi)
    testl $1000, 0(%rsp)
    testl $-2147483648, 8(%rsp)
    testl $2147483647, 2147483647(%rsp)
    testl $305419896, 0(%rdi,%rbx,8)
    testl $1000, -128(%rax,%rbp,1)
    testl $-2147483648, 4660(%rcx,%rsi,2)
    testl $2147483647, gnu_fwd(%rip)
    testl $305419896, 128
    xchgl %r10d, 0(%r9)
    xchgl %r11d, 127(%rcx)
    xchgl %r14d, -129(%r8)
    xchgl %r8d, 0(%r12)
    xchgl %r12d, -1(%rsp)
    xchgl %r13d, -2147483648(%r12)
    xchgl %r15d, 0(%r8,%rax,4)
    xchgl %r9d, 64(%rdi,%r15,8)
    xchgl %r10d, 2147483647(%r15,%rsi,1)
    xchgl %r11d, gnu_back(%rip)
    xchgl %r14d, 4660
    xchgl %ecx, %edx
    xchgl %ebx, 0(%rcx)
    xchgl %esi, 8(%rcx)
    xchgl %edi, 128(%rdx)
    xchgl %ebp, 0(%rsp)
    xchgl %esp, -128(%rsp)
    xchgl %ecx, -129(%rsp)
    xchgl %edx, 0(%rax,%rdi,2)
    xchgl %ebx, 127(%rdx,%rax,4)
    xchgl %esi, -2147483648(%rbx,%rcx,8)
    xchgl %edi, gnu_fwd(%rip)
    xchgl %ebp, 2147483647
    movq %r8, 0(%rbx)
    movq %r12, -1(%rbp)
    movq %r13, 4660(%r13)
    movq %r15, 0(%rsp)
    movq %r9, 64(%r12)
    movq %r10, 128(%rsp)
    movq %r11, 0(%rcx,%rcx,1)
    movq %r14, 8(%rax,%r9,2)
    movq %r8, -129(%r9,%rbp,4)
    movq %r12, -2147483648
    movq %r13, 2147483647(,%r12,8)
    movq 0(%r10), %r15
    movq -128(%rdx), %r9
    movq 4660(%r9), %r10
    movq 0(%r12), %r11
    movq 127(%rsp), %r14
    movq 128(%r12), %r8
    movq 0(%r12,%rax,1), %r12
    movq -1(%rsp,%r15,2), %r13
    movq -129(%r13,%rsi,4), %r15
    movq -2147483648, %r9
    movq 2147483647(,%rcx,8), %r10
    movq $1000, 0(%rsi)
    movq $-2147483648, 64(%rbx)
    movq $2147483647, 4660(%r10)
    movq $305419896, 0(%rsp)
    movq $1000, 8(%r12)
    movq $-2147483648, 128(%rsp)
    movq $2147483647, 0(%rdx,%r9,1)
    movq $305419896, -128(%rbp,%rbp,2)
    movq $1000, -129(%r12,%r12,4)
    movq $-2147483648, gnu_back(%rip)
    movq $2147483647, -2147483648
    testq %r11, 0(%r11)
    testq %r14, 127(%rsi)
    testq %r8, 2147483647(%r11)
    testq %r12, 0(%r12)
    testq %r13, -1(%rsp)
    testq %r15, 4660(%r12)
    testq %r9, 0(%r9,%rax,8)
    testq %r10, 64(%rdi,%r15,1)
    testq %r11, 128(%r15,%rsi,2)
    testq %r14, gnu_fwd(%rip)
    testq %r8, -129
    testq $305419896, 0(%rdi)
    testq $1000, 8(%rdi)
    testq $-2147483648, -2147483648(%r14)
    testq $2147483647, 0(%rsp)
    testq $305419896, -128(%r12)
    testq $1000, 2147483647(%rsp)
    testq $-2147483648, 0(%rsp,%rcx,4)
    testq $2147483647, 127(%rax,%r9,8)
    testq $305419896, 4660(%r9,%rbp,1)
    testq $1000, gnu_back(%rip)
    testq $-2147483648, 128
    xchgq %r12, 0(%r14)
    xchgq %r13, -1(%r15)
    xchgq %r15, -129(%rcx)
    xchgq %r9, 0(%r12)
    xchgq %r10, 64(%rsp)
    xchgq %r11, -2147483648(%r12)
    xchgq %r14, 0(%r14,%r12,2)
    xchgq %r8, 8(%rsp,%rax,4)
    xchgq %r12, 2147483647(%r13,%r15,8)
    xchgq %r13, gnu_fwd(%rip)
    xchgq %r15, 4660
    movb $255, %dl
    movw $4660, %sp
    movl $2147483647, %ecx
    leal 0(%r15), %r9d
    leal -128(%r8), %r10d
    leal 128(%rbp), %r11d
    leal 0(%rsp), %r14d
    leal 127(%r12), %r8d
    leal -129(%rsp), %r12d
    leal 0(%rsi,%rsi,1), %r13d
    leal -1(%rbp,%rcx,2), %r15d
    leal -2147483648(%r12,%r9,4), %r9d
    leal 2147483647, %r10d
    leal 4660(,%rbp,8), %r11d
    leal 0(%rdx), %edx
    leal 64(%rbx), %ebx
    leal 128(%rbp), %esi
    leal 0(%rsp), %edi
    leal 8(%rsp), %ebp
    leal -129(%rsp), %esp
    leal 0(%rcx,%rdx,1), %ecx
g14:
    leal -128(%rsp,%rbx,2), %edx
    leal -2147483648(%rbp,%rbp,4), %ebx
    leal gnu_back(%rip), %esi
    leal 2147483647, %edi
    leal 4660(,%rsi,8), %ebp
    leaq 0(%rcx), %r14
    leaq 127(%r13), %r8
    leaq 128(%rdx), %r12
    leaq 0(%r12), %r13
    leaq -1(%rsp), %r15
    leaq -129(%r12), %r9
    leaq 0(%r15,%r12,1), %r10
    leaq 64(%rdi,%rax,2), %r11
    leaq -2147483648(%r15,%r15,4), %r14
    leaq 2147483647, %r8
    leaq 4660(,%rsi,8), %r12
    movzbw 0(%r8), %r13w
    movzbw 8(%r9), %r15w
    movzbw 128(%rbx), %r9w
    movzbw 0(%rsp), %r10w
    movzbw -128(%r12), %r11w
    movzbw -129(%rsp), %r14w
    movzbw 0(%rax,%rcx,1), %r8w
    movzbw 127(%rax,%r9,2), %r12w
    movzbw -2147483648(%r9,%rbp,4), %r13w
    movzbw gnu_fwd(%rip), %r15w
    movzbw 2147483647, %r9w
    movzbw %bl, %sp
    movzbw 0(%rbx), %cx
    movzbw -1(%rsi), %dx
    movzbw 4660(%rdi), %bx
    movzbw 0(%rsp), %si
    movzbw 64(%rsp), %di
    movzbw 128(%rsp), %bp
    movzbw 0(%rdx,%rdi,8), %sp
    movzbw 8(%rsi,%rax,1), %cx
    movzbw -129(%rdi,%rcx,2), %dx
    movzbw gnu_back(%rip), %bx
    movzbw -2147483648, %si
    movzbl 0(%rdx), %r10d
    movzbl -128(%r10), %r11d
    movzbl 2147483647(%rsi), %r14d
    movzbl 0(%r12), %r8d
    movzbl 127(%rsp), %r12d
    movzbl 4660(%r12), %r13d
    movzbl 0(%r8,%r12,4), %r15d
    movzbl -1(%rsp,%rax,8), %r9d
    movzbl 128(%r13,%r15,1), %r10d
    movzbl gnu_fwd(%rip), %r11d
    movzbl -129, %r14d
    movzbl %dh, %edi
    movzbl 0(%rsi), %ebp
    movzbl 64(%rcx), %esp
    movzbl -2147483648(%rdx), %ecx
    movzbl 0(%rsp), %edx
    movzbl 8(%rsp), %ebx
    movzbl 2147483647(%rsp), %esi
    movzbl 0(%rbx,%rdx,2), %edi
    movzbl -128(%rax,%rbx,4), %ebp
    movzbl 4660(%rcx,%rbp,8), %esp
    movzbl gnu_back(%rip), %ecx
    movzbl 128, %edx
    movzbq 0(%r9), %r8
    movzbq 127(%r11), %r12
    movzbq -129(%rdi), %r13
    movzbq 0(%rsp), %r15
    movzbq -1(%r12), %r9
    movzbq -2147483648(%rsp), %r10
    movzbq 0(%rcx,%rsi,1), %r11
    movzbq 64(%rbp,%rcx,2), %r14
    movzbq 2147483647(%r12,%r9,4), %r8
    movzbq gnu_fwd(%rip), %r12
    movzbq 4660, %r13
    movzwl 0(%rbx), %r15d
    movzwl 8(%r14), %r9d
    movzwl 128(%r15), %r10d
    movzwl 0(%r12), %r11d
    movzwl -128(%rsp), %r14d
    movzwl -129(%r12), %r8d
    movzwl 0(%r12,%rbp,8), %r12d
    movzwl 127(%rdi,%r12,1), %r13d
    movzwl -2147483648(%r15,%rax,2), %r15d
    movzwl gnu_back(%rip), %r9d
    movzwl 2147483647, %r10d
    movzwl %bx, %esi
    movzwl 0(%rdi), %edi
    movzwl -1(%rbx), %ebp
    movzwl 4660(%rbp), %esp
    movzwl 0(%rsp), %ecx
    movzwl 64(%rsp), %edx
    movzwl 128(%rsp), %ebx
    movzwl 0(%rsp,%rsi,4), %esi
    movzwl 8(%rdx,%rdi,8), %edi
    movzwl -129(%rbx,%rax,1), %ebp
    movzwl gnu_fwd(%rip), %esp
    movzwl -2147483648, %ecx
    movzwq 0(%r10), %r11
    movzwq -128(%rcx), %r14
    movzwq 2147483647(%r8), %r8
    movzwq 0(%rsp), %r12
    movzwq 127(%r12), %r13
    movzwq 4660(%rsp), %r15
    movzwq 0(%rdx,%r15,2), %r9
    movzwq -1(%rax,%rsi,4), %r10
    movzwq 128(%r9,%rcx,8), %r11
    movzwq gnu_back(%rip), %r14
    movzwq -129, %r8
    movsbw 0(%rsi), %r12w
    movsbw 64(%rbp), %r13w
    movsbw -2147483648(%r13), %r15w
    movsbw 0(%r12), %r9w
    movsbw 8(%rsp), %r10w
    movsbw 2147483647(%r12), %r11w
    movsbw 0(%r9,%r9,1), %r14w
    movsbw -128(%rsp,%rbp,2), %r8w
    movsbw 4660(%r13,%r12,4), %r12w
    movsbw gnu_fwd(%rip), %r13w
    movsbw 128, %r15w
    movsbw %bh, %dx
    movsbw 0(%rcx), %bx
    movsbw 127(%rsi), %si
    movsbw -129(%rdi), %di
    movsbw 0(%rsp), %bp
    movsbw -1(%rsp), %sp
    movsbw -2147483648(%rsp), %cx
    movsbw 0(%rsi,%rcx,8), %dx
    movsbw 64(%rsp,%rdx,1), %bx
    movsbw 2147483647(%rbp,%rbx,2), %si
    movsbw gnu_back(%rip), %di
    movsbw 4660, %bp
    movsbl 0(%r11), %r9d
    movsbl 8(%rdx), %r10d
    movsbl 128(%r9), %r11d
    movsbl 0(%rsp), %r14d
    movsbl -128(%r12), %r8d
    movsbl -129(%rsp), %r12d
    movsbl 0(%rsp,%rax,4), %r13d
    movsbl 127(%rbp,%r15,8), %r15d
    movsbl -2147483648(%r12,%rsi,1), %r9d
    movsbl gnu_fwd(%rip), %r10d
    movsbl 2147483647, %r11d
    movsbl %ch, %esp
    movsbl 0(%rdx), %ecx
    movsbl -1(%rcx), %edx
    movsbl 4660(%rdx), %ebx
    movsbl 0(%rsp), %esi
    movsbl 64(%rsp), %edi
    movsbl 128(%rsp), %ebp
    movsbl 0(%rdi,%rbp,2), %esp
    movsbl 8(%rsi,%rsi,4), %ecx
    movsbl -129(%rdi,%rdi,8), %edx
    movsbl gnu_back(%rip), %ebx
    movsbl -2147483648, %esi
    movsbq 0(%rdi), %r14
    movsbq -128(%rbx), %r8
    movsbq 2147483647(%r10), %r12
    movsbq 0(%r12), %r13
    movsbq 127(%rsp), %r15
    movsbq 4660(%r12), %r9
    movsbq 0(%r14,%rcx,1), %r10
    movsbq -1(%rdi,%r9,2), %r11
    movsbq 128(%r15,%rbp,4), %r14
    movsbq gnu_fwd(%rip), %r8
    movsbq -129, %r12
    movswl 0(%r14), %r13d
    movswl 64(%rsi), %r15d
    movswl -2147483648(%r11), %r9d
    movswl 0(%rsp), %r10d
    movswl 8(%r12), %r11d
    movswl 2147483647(%rsp), %r14d
    movswl 0(%rsi,%r12,8), %r8d
    movswl -128(%rax,%rax,1), %r12d
    movswl 4660(%r9,%r15,2), %r13d
    movswl gnu_back(%rip), %r15d
    movswl 128, %r9d
    movswl %di, %ebp
    movswl 0(%rbx), %esp
    movswl 127(%rbx), %ecx
    movswl -129(%rbp), %edx
    movswl 0(%rsp), %ebx
    movswl -1(%rsp), %esi
    movswl -2147483648(%rsp), %edi
    movswl 0(%rax,%rax,4), %ebp
    movswl 64(%rax,%rcx,8), %esp
    movswl 2147483647(%rcx,%rdx,1), %ecx
    movswl gnu_fwd(%rip), %edx
    movswl 4660, %ebx
    movswq 0(%r15), %r10
    movswq 8(%rdi), %r11
    movswq 128(%r14), %r14
    movswq 0(%r12), %r8
    movswq -128(%rsp), %r12
    movswq -129(%r12), %r13
    movswq 0(%r15,%rsi,2), %r15
    movswq 127(%rsp,%rcx,4), %r9
    movswq -2147483648(%r13,%r9,8), %r10
    movswq gnu_back(%rip), %r11
    movswq 2147483647, %r14
    movslq 0(%rcx), %r8
    movslq -1(%r15), %r12
g15:
    movslq 4660(%rcx), %r13
    movslq 0(%rsp), %r15
    movslq 64(%r12), %r9
    movslq 128(%rsp), %r10
    movslq 0(%rax,%rbp,1), %r11
    movslq 8(%rbp,%r12,2), %r14
    movslq -129(%r12,%rax,4), %r8
    movslq gnu_fwd(%rip), %r12
    movslq -2147483648, %r13
    incb 0(%r14)
    incb -128(%r9)
    incb 2147483647(%r10)
    incb 0(%r12)
    incb 127(%r12)
    incb 4660(%r12)
    incb 0(%r12,%r15,8)
    incb -1(%r12,%rsi,1)
    incb 128(%r13,%rcx,2)
    incb %ah
    incb 0(%rsi)
    incb 64(%rsi)
    incb -129(%rdi)
    incb 0(%rsp)
    incb 8(%rsp)
    incb -2147483648(%rsp)
    incb 0(%rcx,%rbx,4)
    incb -128(%rdx,%rbp,8)
    incb 2147483647(%rbx,%rsi,1)
    incb gnu_back(%rip)
    incb 4660
    incw 0(%r15)
    incw 127(%r11)
    incw 128(%r13)
    incw 0(%r12)
    incw -1(%r12)
    incw -129(%r12)
    incw 0(%r14,%r9,2)
    incw 64(%r15,%rbp,4)
    incw -2147483648(%r8,%r12,8)
    incw %si
    incw 0(%rdi)
    incw 8(%rcx)
    incw 2147483647(%rdx)
    incw 0(%rsp)
    incw -128(%rsp)
    incw 4660(%rsp)
    incw 0(%rdx,%rdi,1)
    incw 127(%rsp,%rax,2)
    incw 128(%rbp,%rcx,4)
    incw gnu_fwd(%rip)
    incw -129
    incl 0(%r8)
    incl -1(%r14)
    incl -2147483648(%r15)
    incl 0(%r12)
    incl 64(%r12)
    incl 2147483647(%r12)
    incl 0(%r15,%rax,8)
    incl 8(%r9,%r15,1)
    incl 4660(%r12,%rsi,2)
    incl %edi
    incl 0(%rcx)
    incl -128(%rbx)
    incl 128(%rbp)
    incl 0(%rsp)
    incl 127(%rsp)
    incl -129(%rsp)
    incl 0(%rbx,%rdx,4)
    incl -1(%rsi,%rbx,8)
    incl -2147483648(%rdi,%rbp,1)
    incl gnu_back(%rip)
    incl 2147483647
    incq 0(%r8)
    incq 64(%r8)
    incq 4660(%rbp)
    incq 0(%r12)
    incq 8(%rsp)
    incq 128(%r12)
    incq 0(%r8,%rcx,2)
    incq -128(%rdi,%r9,4)
    incq -129(%r15,%rbp,8)
    incq gnu_fwd(%rip)
    incq -2147483648
    decb 0(%r9)
    decb 127(%r8)
    decb 2147483647(%r9)
    decb 0(%r12)
    decb -1(%r12)
    decb 4660(%r12)
    decb 0(%r8,%r12,1)
    decb 64(%r13,%rax,2)
    decb 128(%r15,%r15,4)
    decb %cl
    decb 0(%rdx)
    decb 8(%rsi)
    decb -129(%rdi)
    decb 0(%rsp)
    decb -128(%rsp)
    decb -2147483648(%rsp)
    decb 0(%rsp,%rsi,8)
    decb 127(%rax,%rdi,1)
    decb 2147483647(%rcx,%rax,2)
    decb gnu_back(%rip)
    decb 4660
    decw 0(%r10)
    decw -1(%r10)
    decw 128(%r11)
    decw 0(%r12)
    decw 64(%r12)
    decw -129(%r12)
    decw 0(%r9,%rsi,4)
    decw 8(%r8,%rcx,8)
    decw -2147483648(%r9,%r9,1)
    decw %bp
    decw 0(%rbx)
    decw -128(%rcx)
    decw 2147483647(%rdx)
    decw 0(%rsp)
    decw 127(%rsp)
    decw 4660(%rsp)
    decw 0(%rsi,%rcx,2)
    decw -1(%rdx,%rdx,4)
    decw 128(%rbx,%rbx,8)
    decw gnu_fwd(%rip)
    decw -129
    decl 0(%r11)
    decl 64(%r13)
    decl -2147483648(%r14)
    decl 0(%r12)
    decl 8(%r12)
    decl 2147483647(%r12)
    decl 0(%r10,%rbp,1)
    decl -128(%r12,%r12,2)
    decl 4660(%r13,%rax,4)
    decl %esp
    decl 0(%rsi)
    decl 127(%rbx)
    decl 128(%rbp)
    decl 0(%rsp)
    decl -1(%rsp)
    decl -129(%rsp)
    decl 0(%rdi,%rbp,8)
    decl 64(%rsp,%rsi,1)
    decl -2147483648(%rbp,%rdi,2)
    decl gnu_back(%rip)
    decl 2147483647
    decq 0(%rdx)
    decq 8(%r13)
    decq 4660(%rdx)
    decq 0(%rsp)
    decq -128(%r12)
    decq 128(%rsp)
    decq 0(%rcx,%r15,4)
    decq 127(%rax,%rsi,8)
    decq -129(%r9,%rcx,1)
    decq gnu_fwd(%rip)
    decq -2147483648
    notb 0(%r14)
    notb -1(%r15)
    notb 2147483647(%r8)
    notb 0(%r12)
    notb 64(%r12)
    notb 4660(%r12)
    notb 0(%r11,%r9,2)
    notb 8(%r15,%rbp,4)
    notb 128(%r8,%r12,8)
    notb %dl
    notb 0(%rdi)
    notb -128(%rsi)
    notb -129(%rdi)
    notb 0(%rsp)
    notb 127(%rsp)
    notb -2147483648(%rsp)
    notb 0(%rax,%rax,1)
    notb -1(%rsi,%rcx,2)
    notb 2147483647(%rdi,%rdx,4)
    notb gnu_back(%rip)
    notb 4660
    notw 0(%r15)
    notw 64(%r9)
    notw 128(%r10)
    notw 0(%r12)
    notw 8(%r12)
    notw -129(%r12)
    notw 0(%r12,%rax,8)
    notw -128(%r9,%r15,1)
    notw -2147483648(%r12,%rsi,2)
    notw %cx
    notw 0(%rcx)
    notw 127(%rcx)
    notw 2147483647(%rdx)
    notw 0(%rsp)
    notw -1(%rsp)
    notw 4660(%rsp)
    notw 0(%rcx,%rbx,4)
    notw 64(%rax,%rbp,8)
    notw 128(%rcx,%rsi,1)
    notw gnu_fwd(%rip)
    notw -129
    notl 0(%r8)
g16:
    notl 8(%r11)
    notl -2147483648(%r13)
    notl 0(%r12)
    notl -128(%r12)
    notl 2147483647(%r12)
    notl 0(%r14,%rcx,2)
    notl 127(%r13,%r9,4)
    notl 4660(%r15,%rbp,8)
    notl %edx
    notl 0(%rdx)
    notl -1(%rbx)
    notl 128(%rbp)
    notl 0(%rsp)
    notl 64(%rsp)
    notl -129(%rsp)
    notl 0(%rdx,%rdi,1)
    notl 8(%rdx,%rax,2)
    notl -2147483648(%rbx,%rcx,4)
    notl gnu_back(%rip)
    notl 2147483647
    notq 0(%r9)
    notq -128(%r9)
    notq 4660(%rbx)
    notq 0(%r12)
    notq 127(%rsp)
    notq 128(%r12)
    notq 0(%r12,%r12,8)
    notq -1(%rsp,%rax,1)
    notq -129(%r13,%r15,2)
    notq gnu_fwd(%rip)
    notq -2147483648
    negb 0(%r9)
    negb 64(%r14)
    negb 2147483647(%r15)
    negb 0(%r12)
    negb 8(%r12)
    negb 4660(%r12)
    negb 0(%r15,%rsi,4)
    negb -128(%r8,%rcx,8)
    negb 128(%r9,%r9,1)
    negb %bl
    negb 0(%rbx)
    negb 127(%rsi)
    negb -129(%rdi)
    negb 0(%rsp)
    negb -1(%rsp)
    negb -2147483648(%rsp)
    negb 0(%rbx,%rdx,2)
    negb 64(%rsp,%rbx,4)
    negb 2147483647(%rbp,%rbp,8)
    negb gnu_back(%rip)
    negb 4660
    negw 0(%r10)
    negw 8(%r8)
    negw 128(%r9)
    negw 0(%r12)
    negw -128(%r12)
    negw -129(%r12)
    negw 0(%r8,%rbp,1)
    negw 127(%r12,%r12,2)
    negw -2147483648(%r13,%rax,4)
    negw %bx
    negw 0(%rsi)
    negw -1(%rcx)
    negw 2147483647(%rdx)
    negw 0(%rsp)
    negw 64(%rsp)
    negw 4660(%rsp)
    negw 0(%rsp,%rsi,8)
    negw 8(%rsi,%rdi,1)
    negw 128(%rdi,%rax,2)
    negw gnu_fwd(%rip)
    negw -129
    negl 0(%r11)
    negl -128(%r10)
    negl -2147483648(%r11)
    negl 0(%r12)
    negl 127(%r12)
    negl 2147483647(%r12)
    negl 0(%r9,%r15,4)
    negl -1(%r15,%rsi,8)
    negl 4660(%r8,%rcx,1)
    negl %esi
    negl 0(%rdi)
    negl 64(%rbx)
    negl 128(%rbp)
    negl 0(%rsp)
    negl 8(%rsp)
    negl -129(%rsp)
    negl 0(%rsi,%rcx,2)
    negl -128(%rax,%rdx,4)
    negl -2147483648(%rcx,%rbx,8)
    negl gnu_back(%rip)
    negl 2147483647
    negq 0(%rbx)
    negq 127(%r10)
    negq 4660(%rsi)
    negq 0(%rsp)
    negq -1(%r12)
    negq 128(%rsp)
    negq 0(%rdx,%r9,1)
    negq 64(%rbp,%rbp,2)
    negq -129(%r12,%r12,4)
    negq gnu_fwd(%rip)
    negq -2147483648
    mulb 0(%r14)
    mulb 8(%r13)
    mulb 2147483647(%r14)
    mulb 0(%r12)
    mulb -128(%r12)
    mulb 4660(%r12)
    mulb 0(%r10,%rax,8)
    mulb 127(%r9,%r15,1)
    mulb 128(%r12,%rsi,2)
    mulb %dh
    mulb 0(%rcx)
    mulb -1(%rsi)
    mulb -129(%rdi)
    mulb 0(%rsp)
    mulb 64(%rsp)
    mulb -2147483648(%rsp)
    mulb 0(%rdi,%rbp,4)
    mulb 8(%rdx,%rsi,8)
    mulb 2147483647(%rbx,%rdi,1)
    mulb gnu_back(%rip)
    mulb 4660
    mulw 0(%r15)
    mulw -128(%r15)
    mulw 128(%r8)
    mulw 0(%r12)
    mulw 127(%r12)
    mulw -129(%r12)
    mulw 0(%r11,%rcx,2)
    mulw -1(%r13,%r9,4)
    mulw -2147483648(%r15,%rbp,8)
    mulw %di
    mulw 0(%rdx)
    mulw 64(%rcx)
    mulw 2147483647(%rdx)
    mulw 0(%rsp)
    mulw 8(%rsp)
    mulw 4660(%rsp)
    mulw 0(%rax,%rax,1)
    mulw -128(%rsp,%rcx,2)
    mulw 128(%rbp,%rdx,4)
    mulw gnu_fwd(%rip)
    mulw -129
    mull 0(%r8)
    mull 127(%r9)
    mull -2147483648(%r10)
    mull 0(%r12)
    mull -1(%r12)
    mull 2147483647(%r12)
    mull 0(%r12,%r12,8)
    mull 64(%r8,%rax,1)
    mull 4660(%r9,%r15,2)
    mull %ebp
    mull 0(%rbx)
    mull 8(%rbx)
    mull 128(%rbp)
    mull 0(%rsp)
    mull -128(%rsp)
    mull -129(%rsp)
    mull 0(%rcx,%rbx,4)
    mull 127(%rsi,%rbp,8)
    mull -2147483648(%rdi,%rsi,1)
    mull gnu_back(%rip)
    mull 2147483647
    mulq 0(%r10)
    mulq -1(%r11)
    mulq 4660(%rdi)
    mulq 0(%r12)
    mulq 64(%rsp)
    mulq 128(%r12)
    mulq 0(%r9,%rsi,2)
    mulq 8(%rdi,%rcx,4)
    mulq -129(%r15,%r9,8)
    mulq gnu_fwd(%rip)
    mulq -2147483648
    imulb 0(%r9)
    imulb -128(%r11)
    imulb 2147483647(%r13)
    imulb 0(%r12)
    imulb 127(%r12)
    imulb 4660(%r12)
    imulb 0(%r14,%rbp,1)
    imulb -1(%r12,%r12,2)
    imulb 128(%r13,%rax,4)
    imulb %bh
    imulb 0(%rsi)
    imulb 64(%rsi)
    imulb -129(%rdi)
    imulb 0(%rsp)
    imulb 8(%rsp)
    imulb -2147483648(%rsp)
    imulb 0(%rdx,%rdi,8)
    imulb -128(%rax,%rax,1)
    imulb 2147483647(%rcx,%rcx,2)
    imulb gnu_back(%rip)
    imulb 4660
g17:
    imulw 0(%r10)
    imulw 127(%r14)
    imulw 128(%r15)
    imulw 0(%r12)
    imulw -1(%r12)
    imulw -129(%r12)
    imulw 0(%r15,%r15,4)
    imulw 64(%r15,%rsi,8)
    imulw -2147483648(%r8,%rcx,1)
    imulw %sp
    imulw 0(%rdi)
    imulw 8(%rcx)
    imulw 2147483647(%rdx)
    imulw 0(%rsp)
    imulw -128(%rsp)
    imulw 4660(%rsp)
    imulw 0(%rbx,%rdx,2)
    imulw 127(%rdx,%rbx,4)
    imulw 128(%rbx,%rbp,8)
    imulw gnu_fwd(%rip)
    imulw -129
    imull 0(%r11)
    imull -1(%r8)
    imull -2147483648(%r9)
    imull 0(%r12)
    imull 64(%r12)
    imull 2147483647(%r12)
    imull 0(%r8,%r9,1)
    imull 8(%r9,%rbp,2)
    imull 4660(%r12,%r12,4)
    imull %ecx
    imull 0(%rcx)
    imull -128(%rbx)
    imull 128(%rbp)
    imull 0(%rsp)
    imull 127(%rsp)
    imull -129(%rsp)
    imull 0(%rsp,%rsi,8)
    imull -1(%rsp,%rdi,1)
    imull -2147483648(%rbp,%rax,2)
    imull gnu_back(%rip)
    imull 2147483647
    imulq 0(%rsi)
    imulq 64(%r14)
    imulq 4660(%r15)
    imulq 0(%rsp)
    imulq 8(%r12)
    imulq 128(%rsp)
    imulq 0(%rsp,%rax,4)
    imulq -128(%rax,%r15,8)
    imulq -129(%r9,%rsi,1)
    imulq gnu_fwd(%rip)
    imulq -2147483648
    divb 0(%r14)
    divb 127(%r10)
    divb 2147483647(%r11)
    divb 0(%r12)
    divb -1(%r12)
    divb 4660(%r12)
    divb 0(%r9,%rcx,2)
    divb 64(%r13,%r9,4)
    divb 128(%r15,%rbp,8)
    divb %ch
    divb 0(%rdx)
    divb 8(%rsi)
    divb -129(%rdi)
    divb 0(%rsp)
    divb -128(%rsp)
    divb -2147483648(%rsp)
    divb 0(%rsi,%rcx,1)
    divb 127(%rsi,%rdx,2)
    divb 2147483647(%rdi,%rbx,4)
    divb gnu_back(%rip)
    divb 4660
    divw 0(%r15)
    divw -1(%r13)
    divw 128(%r14)
    divw 0(%r12)
    divw 64(%r12)
    divw -129(%r12)
    divw 0(%r10,%r12,8)
    divw 8(%r8,%rax,1)
    divw -2147483648(%r9,%r15,2)
    divw %dx
    divw 0(%rbx)
    divw -128(%rcx)
    divw 2147483647(%rdx)
    divw 0(%rsp)
    divw 127(%rsp)
    divw 4660(%rsp)
    divw 0(%rdi,%rbp,4)
    divw -1(%rax,%rsi,8)
    divw 128(%rcx,%rdi,1)
    divw gnu_fwd(%rip)
    divw -129
    divl 0(%r8)
    divl 64(%r15)
    divl -2147483648(%r8)
    divl 0(%r12)
    divl 8(%r12)
    divl 2147483647(%r12)
    divl 0(%r11,%rsi,2)
    divl -128(%r12,%rcx,4)
    divl 4660(%r13,%r9,8)
    divl %ebx
    divl 0(%rsi)
    divl 127(%rbx)
    divl 128(%rbp)
    divl 0(%rsp)
    divl -1(%rsp)
    divl -129(%rsp)
    divl 0(%rax,%rax,1)
    divl 64(%rdx,%rcx,2)
    divl -2147483648(%rbx,%rdx,4)
    divl gnu_back(%rip)
    divl 2147483647
    divq 0(%r11)
    divq 8(%rcx)
    divq 4660(%r8)
    divq 0(%r12)
    divq -128(%rsp)
    divq 128(%r12)
    divq 0(%r14,%rbp,8)
    divq 127(%rsp,%r12,1)
    divq -129(%r13,%rax,2)
    divq gnu_fwd(%rip)
    divq -2147483648
    idivb 0(%r9)
    idivb -1(%r9)
    idivb 2147483647(%r10)
    idivb 0(%r12)
    idivb 64(%r12)
    idivb 4660(%r12)
    idivb 0(%r12,%r15,4)
    idivb 8(%r15,%rsi,8)
    idivb 128(%r8,%rcx,1)
    idivb %ah
    idivb 0(%rdi)
    idivb -128(%rsi)
    idivb -129(%rdi)
    idivb 0(%rsp)
    idivb 127(%rsp)
    idivb -2147483648(%rsp)
    idivb 0(%rcx,%rbx,2)
    idivb -1(%rsp,%rbp,4)
    idivb 2147483647(%rbp,%rsi,8)
    idivb gnu_back(%rip)
    idivb 4660
    idivw 0(%r10)
    idivw 64(%r11)
    idivw 128(%r13)
    idivw 0(%r12)
    idivw 8(%r12)
    idivw -129(%r12)
    idivw 0(%r14,%r9,1)
    idivw -128(%r9,%rbp,2)
    idivw -2147483648(%r12,%r12,4)
    idivw %si
    idivw 0(%rcx)
    idivw 127(%rcx)
    idivw 2147483647(%rdx)
    idivw 0(%rsp)
    idivw -1(%rsp)
    idivw 4660(%rsp)
    idivw 0(%rdx,%rdi,8)
    idivw 64(%rsi,%rax,1)
    idivw 128(%rdi,%rcx,2)
    idivw gnu_fwd(%rip)
    idivw -129
    idivl 0(%r11)
    idivl 8(%r14)
    idivl -2147483648(%r15)
    idivl 0(%r12)
    idivl -128(%r12)
    idivl 2147483647(%r12)
    idivl 0(%r15,%rax,4)
    idivl 127(%r13,%r15,8)
    idivl 4660(%r15,%rsi,1)
    idivl %edi
    idivl 0(%rdx)
    idivl -1(%rbx)
    idivl 128(%rbp)
    idivl 0(%rsp)
    idivl 64(%rsp)
    idivl -129(%rsp)
    idivl 0(%rbx,%rdx,2)
    idivl 8(%rax,%rbx,4)
    idivl -2147483648(%rcx,%rbp,8)
    idivl gnu_back(%rip)
    idivl 2147483647
    idivq 0(%rdi)
    idivq -128(%rbp)
    idivq 4660(%r13)
    idivq 0(%rsp)
    idivq 127(%r12)
    idivq 128(%rsp)
    idivq 0(%rsi,%rcx,1)
    idivq -1(%rbp,%r9,2)
    idivq -129(%r12,%rbp,4)
    idivq gnu_fwd(%rip)
g18:
    idivq -2147483648
    imulw 0(%r14), %r15w
    imulw 64(%rdx), %r9w
    imulw 2147483647(%r9), %r10w
    imulw 0(%r12), %r11w
    imulw 8(%rsp), %r14w
    imulw 4660(%r12), %r8w
    imulw 0(%r15,%r12,8), %r12w
    imulw -128(%rdi,%rax,1), %r13w
    imulw 128(%r15,%r15,2), %r15w
    imulw gnu_back(%rip), %r9w
    imulw -129, %r10w
    imulw %bp, %sp
    imulw 0(%rbx), %cx
    imulw 127(%rsi), %dx
    imulw -2147483648(%rdi), %bx
    imulw 0(%rsp), %si
    imulw -1(%rsp), %di
    imulw 2147483647(%rsp), %bp
    imulw 0(%rsp,%rsi,4), %sp
    imulw 64(%rdx,%rdi,8), %cx
    imulw 4660(%rbx,%rax,1), %dx
    imulw gnu_fwd(%rip), %bx
    imulw 128, %si
    imulw $200, 0(%r15), %r11w
    imulw $-32768, 8(%rbx), %r14w
    imulw $32767, -129(%r10), %r8w
    imulw $4660, 0(%rsp), %r12w
    imulw $200, -128(%r12), %r13w
    imulw $-32768, -2147483648(%rsp), %r15w
    imulw $32767, 0(%rax,%rsi,2), %r9w
    imulw $4660, 127(%rax,%rcx,4), %r10w
    imulw $200, 2147483647(%r9,%r9,8), %r11w
    imulw $-32768, gnu_back(%rip), %r14w
    imulw $32767, 4660, %r8w
    imulw $4660, %di, %bp
    imulw $200, 0(%rsi), %sp
    imulw $-32768, -1(%rcx), %cx
    imulw $32767, 128(%rdx), %dx
    imulw $4660, 0(%rsp), %bx
    imulw $200, 64(%rsp), %si
    imulw $-32768, -129(%rsp), %di
    imulw $32767, 0(%rsi,%rcx,1), %bp
    imulw $4660, 8(%rsp,%rdx,2), %sp
    imulw $200, -2147483648(%rbp,%rbx,4), %cx
    imulw $-32768, gnu_fwd(%rip), %dx
    imulw $32767, 2147483647, %bx
    imulw $-128, 0(%rcx), %r12w
    imulw $127, -128(%rsi), %r13w
    imulw $-1, 4660(%r11), %r15w
    imulw $0, 0(%r12), %r9w
    imulw $-128, 127(%rsp), %r10w
    imulw $127, 128(%r12), %r11w
    imulw $-1, 0(%r8,%rbp,8), %r14w
    imulw $0, -1(%rsp,%r12,1), %r8w
    imulw $-128, -129(%r13,%rax,2), %r12w
    imulw $127, gnu_back(%rip), %r13w
    imulw $-1, -2147483648, %r15w
    imulw $0, %si, %di
    imulw $-128, 0(%rdi), %bp
    imulw $127, 64(%rbx), %sp
    imulw $-1, 2147483647(%rbp), %cx
    imulw $0, 0(%rsp), %dx
    imulw $-128, 8(%rsp), %bx
    imulw $127, 4660(%rsp), %si
    imulw $-1, 0(%rdi,%rbp,4), %di
    imulw $0, -128(%rsi,%rsi,8), %bp
    imulw $-128, 128(%rdi,%rdi,1), %sp
    imulw $127, gnu_fwd(%rip), %cx
    imulw $-1, -129, %dx
    imull 0(%r8), %r9d
    imull 127(%rdi), %r10d
    imull -2147483648(%r14), %r11d
    imull 0(%rsp), %r14d
    imull -1(%r12), %r8d
    imull 2147483647(%rsp), %r12d
    imull 0(%rcx,%r15,2), %r13d
    imull 64(%rbp,%rsi,4), %r15d
    imull 4660(%r12,%rcx,8), %r9d
    imull gnu_back(%rip), %r10d
    imull 128, %r11d
    imull %ebx, %esi
    imull 0(%rcx), %edi
    imull 8(%rsi), %ebp
    imull -129(%rdi), %esp
    imull 0(%rsp), %ecx
    imull -128(%rsp), %edx
    imull -2147483648(%rsp), %ebx
    imull 0(%rax,%rax,1), %esi
    imull 127(%rax,%rcx,2), %edi
    imull 2147483647(%rcx,%rdx,4), %ebp
    imull gnu_fwd(%rip), %esp
    imull 4660, %ecx
    imull $305419896, 0(%rdx), %r14d
    imull $1000, -1(%r15), %r8d
    imull $-2147483648, 128(%rcx), %r12d
    imull $2147483647, 0(%r12), %r13d
    imull $305419896, 64(%rsp), %r15d
    imull $1000, -129(%r12), %r9d
    imull $-2147483648, 0(%r12,%r9,8), %r10d
    imull $2147483647, 8(%rdi,%rbp,1), %r11d
    imull $305419896, -2147483648(%r15,%r12,2), %r14d
    imull $1000, gnu_back(%rip), %r8d
    imull $-2147483648, 2147483647, %r12d
    imull $2147483647, %edx, %ebx
    imull $305419896, 0(%rdx), %esi
    imull $1000, -128(%rcx), %edi
    imull $-2147483648, 4660(%rdx), %ebp
    imull $2147483647, 0(%rsp), %esp
    imull $305419896, 127(%rsp), %ecx
    imull $1000, 128(%rsp), %edx
    imull $-2147483648, 0(%rcx,%rbx,4), %ebx
    imull $2147483647, -1(%rdx,%rbp,8), %esi
    imull $305419896, -129(%rbx,%rsi,1), %edi
    imull $1000, gnu_fwd(%rip), %ebp
    imull $-2147483648, -2147483648, %esp
    imull $0, 0(%r9), %r13d
    imull $-128, 64(%r8), %r15d
    imull $127, 2147483647(%rbp), %r9d
    imull $-1, 0(%rsp), %r10d
    imull $0, 8(%r12), %r11d
    imull $-128, 4660(%rsp), %r14d
    imull $127, 0(%rdx,%rax,2), %r8d
    imull $-1, -128(%rax,%r15,4), %r12d
    imull $0, 128(%r9,%rsi,8), %r13d
    imull $-128, gnu_back(%rip), %r15d
    imull $127, -129, %r9d
    imull $-1, %ecx, %edx
    imull $0, 0(%rbx), %ebx
    imull $-128, 127(%rbx), %esi
    imull $127, -2147483648(%rbp), %edi
    imull $-1, 0(%rsp), %ebp
    imull $0, -1(%rsp), %esp
    imull $-128, 2147483647(%rsp), %ecx
    imull $127, 0(%rdx,%rdi,1), %edx
    imull $-1, 64(%rsp,%rax,2), %ebx
    imull $0, 4660(%rbp,%rcx,4), %esi
    imull $-128, gnu_fwd(%rip), %edi
    imull $127, 128, %ebp
    imulq 0(%rbx), %r10
    imulq 8(%r13), %r11
    imulq -129(%rdx), %r14
    imulq 0(%r12), %r8
    imulq -128(%rsp), %r12
    imulq -2147483648(%r12), %r13
    imulq 0(%r9,%rcx,8), %r15
    imulq 127(%rsp,%r9,1), %r9
    imulq 2147483647(%r13,%rbp,2), %r10
    imulq gnu_back(%rip), %r11
    imulq 4660, %r14
    imulq $2147483647, 0(%r10), %r8
    imulq $305419896, -1(%r9), %r12
    imulq $1000, 128(%rbx), %r13
    imulq $-2147483648, 0(%rsp), %r15
    imulq $2147483647, 64(%r12), %r9
    imulq $305419896, -129(%rsp), %r10
    imulq $1000, 0(%rsp,%r12,4), %r11
    imulq $-2147483648, 8(%rbp,%rax,8), %r14
    imulq $2147483647, -2147483648(%r12,%r15,1), %r8
    imulq $305419896, gnu_fwd(%rip), %r12
    imulq $1000, 2147483647, %r13
    imulq $-1, 0(%rsi), %r15
    imulq $0, -128(%r10), %r9
    imulq $-128, 4660(%rsi), %r10
    imulq $127, 0(%r12), %r11
    imulq $-1, 127(%rsp), %r14
    imulq $0, 128(%r12), %r8
    imulq $-128, 0(%r14,%rsi,2), %r12
    imulq $127, -1(%rdi,%rcx,4), %r13
    imulq $-1, -129(%r15,%r9,8), %r15
    imulq $0, gnu_back(%rip), %r9
    imulq $-128, -2147483648, %r10
    rolb 0(%r14)
    rolb 64(%r8)
    rolb 2147483647(%r9)
    rolb 0(%r12)
    rolb 8(%r12)
    rolb 4660(%r12)
    rolb 0(%r8,%rbp,1)
    rolb -128(%r8,%r12,2)
    rolb 128(%r9,%rax,4)
    rolb %cl
    rolb 0(%rsi)
    rolb 127(%rsi)
    rolb -129(%rdi)
    rolb 0(%rsp)
    rolb -1(%rsp)
    rolb -2147483648(%rsp)
    rolb 0(%rbx,%rdx,8)
    rolb 64(%rsi,%rbx,1)
    rolb 2147483647(%rdi,%rbp,2)
    rolb gnu_fwd(%rip)
    rolb 4660
    rolb $0, 0(%r15)
    rolb $255, 8(%r10)
    rolb $63, 128(%r11)
    rolb $7, 0(%r12)
    rolb $0, -128(%r12)
    rolb $255, -129(%r12)
    rolb $63, 0(%r9,%r15,4)
g19:
    rolb $7, 127(%r12,%rsi,8)
    rolb $0, -2147483648(%r13,%rcx,1)
    rolb $255, %dl
    rolb $63, 0(%rdi)
    rolb $7, -1(%rcx)
    rolb $0, 2147483647(%rdx)
    rolb $255, 0(%rsp)
    rolb $63, 64(%rsp)
    rolb $7, 4660(%rsp)
    rolb $0, 0(%rsp,%rsi,2)
    rolb $255, 8(%rax,%rdi,4)
    rolb $63, 128(%rcx,%rax,8)
    rolb $7, gnu_back(%rip)
    rolb $0, -129
    rolb %cl, 0(%r8)
    rolb %cl, -128(%r13)
    rolb %cl, -2147483648(%r14)
    rolb %cl, 0(%r12)
    rolb %cl, 127(%r12)
    rolb %cl, 2147483647(%r12)
    rolb %cl, 0(%r10,%r9,1)
    rolb %cl, -1(%r15,%rbp,2)
    rolb %cl, 4660(%r8,%r12,4)
    rolb %cl, %bl
    rolb %cl, 0(%rcx)
    rolb %cl, 64(%rbx)
    rolb %cl, 128(%rbp)
    rolb %cl, 0(%rsp)
    rolb %cl, 8(%rsp)
    rolb %cl, -129(%rsp)
    rolb %cl, 0(%rsi,%rcx,8)
    rolb %cl, -128(%rdx,%rdx,1)
    rolb %cl, -2147483648(%rbx,%rbx,2)
    rolb %cl, gnu_fwd(%rip)
    rolb %cl, 2147483647
    rolw 0(%r9)
    rolw 127(%r15)
    rolw 4660(%r8)
    rolw 0(%r12)
    rolw -1(%r12)
    rolw 128(%r12)
    rolw 0(%r11,%rax,4)
    rolw 64(%r9,%r15,8)
    rolw -129(%r12,%rsi,1)
    rolw %sp
    rolw 0(%rdx)
    rolw 8(%rsi)
    rolw -2147483648(%rdi)
    rolw 0(%rsp)
    rolw -128(%rsp)
    rolw 2147483647(%rsp)
    rolw 0(%rdi,%rbp,2)
    rolw 127(%rsp,%rsi,4)
    rolw 4660(%rbp,%rdi,8)
    rolw gnu_back(%rip)
    rolw 128
    rolw $255, 0(%r10)
    rolw $63, -1(%r9)
    rolw $7, -129(%r10)
    rolw $0, 0(%r12)
    rolw $255, 64(%r12)
    rolw $63, -2147483648(%r12)
    rolw $7, 0(%r12,%rcx,1)
    rolw $0, 8(%r13,%r9,2)
    rolw $255, 2147483647(%r15,%rbp,4)
    rolw $63, %cx
    rolw $7, 0(%rbx)
    rolw $0, -128(%rcx)
    rolw $255, 4660(%rdx)
    rolw $63, 0(%rsp)
    rolw $7, 127(%rsp)
    rolw $0, 128(%rsp)
    rolw $255, 0(%rax,%rax,8)
    rolw $63, -1(%rsi,%rcx,1)
    rolw $7, -129(%rdi,%rdx,2)
    rolw $0, gnu_fwd(%rip)
    rolw $255, -2147483648
    rolw %cl, 0(%r11)
    rolw %cl, 64(%r11)
    rolw %cl, 2147483647(%r13)
    rolw %cl, 0(%r12)
    rolw %cl, 8(%r12)
    rolw %cl, 4660(%r12)
    rolw %cl, 0(%r14,%r12,4)
    rolw %cl, -128(%r8,%rax,8)
    rolw %cl, 128(%r9,%r15,1)
    rolw %cl, %dx
    rolw %cl, 0(%rsi)
    rolw %cl, 127(%rbx)
    rolw %cl, -129(%rbp)
    rolw %cl, 0(%rsp)
    rolw %cl, -1(%rsp)
    rolw %cl, -2147483648(%rsp)
    rolw %cl, 0(%rcx,%rbx,2)
    rolw %cl, 64(%rax,%rbp,4)
    rolw %cl, 2147483647(%rcx,%rsi,8)
    rolw %cl, gnu_back(%rip)
    rolw %cl, 4660
    roll 0(%r14)
    roll 8(%r14)
    roll 128(%r15)
    roll 0(%r12)
    roll -128(%r12)
    roll -129(%r12)
    roll 0(%r15,%rsi,1)
    roll 127(%r12,%rcx,2)
    roll -2147483648(%r13,%r9,4)
    roll %ebx
    roll 0(%rdi)
    roll -1(%rsi)
    roll 2147483647(%rdi)
    roll 0(%rsp)
    roll 64(%rsp)
    roll 4660(%rsp)
    roll 0(%rdx,%rdi,8)
    roll 8(%rdx,%rax,1)
    roll 128(%rbx,%rcx,2)
    roll gnu_fwd(%rip)
    roll -129
    roll $63, 0(%r15)
    roll $7, -128(%r8)
    roll $0, -2147483648(%r9)
    roll $255, 0(%r12)
    roll $63, 127(%r12)
    roll $7, 2147483647(%r12)
    roll $0, 0(%r8,%rbp,4)
    roll $255, -1(%r15,%r12,8)
    roll $63, 4660(%r8,%rax,1)
    roll $7, %esi
    roll $0, 0(%rcx)
    roll $255, 64(%rcx)
    roll $63, 128(%rdx)
    roll $7, 0(%rsp)
    roll $0, 8(%rsp)
    roll $255, -129(%rsp)
    roll $63, 0(%rbx,%rdx,2)
    roll $7, -128(%rsp,%rbx,4)
    roll $0, -2147483648(%rbp,%rbp,8)
    roll $255, gnu_back(%rip)
    roll $63, 2147483647
    roll %cl, 0(%r8)
    roll %cl, 127(%r10)
    roll %cl, 4660(%r11)
    roll %cl, 0(%r12)
    roll %cl, -1(%r12)
    roll %cl, 128(%r12)
    roll %cl, 0(%r9,%r15,1)
    roll %cl, 64(%r9,%rsi,2)
    roll %cl, -129(%r12,%rcx,4)
    roll %cl, %edi
    roll %cl, 0(%rdx)
    roll %cl, 8(%rbx)
    roll %cl, -2147483648(%rbp)
    roll %cl, 0(%rsp)
    roll %cl, -128(%rsp)
    roll %cl, 2147483647(%rsp)
    roll %cl, 0(%rsp,%rsi,8)
    roll %cl, 127(%rsi,%rdi,1)
    roll %cl, 4660(%rdi,%rax,2)
    roll %cl, gnu_fwd(%rip)
    roll %cl, 128
    rolq 0(%r11)
    rolq -1(%r11)
    rolq -129(%rdi)
    rolq 0(%rsp)
    rolq 64(%r12)
    rolq -2147483648(%rsp)
    rolq 0(%rsi,%r9,4)
    rolq 8(%rax,%rbp,8)
    rolq 2147483647(%r9,%r12,1)
    rolq gnu_back(%rip)
    rolq 4660
    rolq $7, 0(%rdi)
    rolq $0, -128(%r14)
    rolq $255, 128(%r15)
    rolq $63, 0(%r12)
    rolq $7, 127(%rsp)
    rolq $0, -129(%r12)
    rolq $255, 0(%r15,%rax,2)
    rolq $63, -1(%rsp,%r15,4)
    rolq $7, -2147483648(%r13,%rsi,8)
    rolq $0, gnu_fwd(%rip)
    rolq $255, 2147483647
    rolq %cl, 0(%r14)
    rolq %cl, 64(%rcx)
    rolq %cl, 4660(%r8)
    rolq %cl, 0(%rsp)
    rolq %cl, 8(%r12)
    rolq %cl, 128(%rsp)
    rolq %cl, 0(%rax,%rcx,1)
    rolq %cl, -128(%rbp,%r9,2)
    rolq %cl, -129(%r12,%rbp,4)
    rolq %cl, gnu_back(%rip)
    rolq %cl, -2147483648
    rorb 0(%r9)
    rorb 127(%r13)
    rorb 2147483647(%r14)
    rorb 0(%r12)
    rorb -1(%r12)
    rorb 4660(%r12)
g20:
    rorb 0(%r10,%r12,8)
    rorb 64(%r13,%rax,1)
    rorb 128(%r15,%r15,2)
    rorb %dh
    rorb 0(%rbx)
    rorb 8(%rsi)
    rorb -129(%rdi)
    rorb 0(%rsp)
    rorb -128(%rsp)
    rorb -2147483648(%rsp)
    rorb 0(%rsi,%rcx,4)
    rorb 127(%rax,%rdx,8)
    rorb 2147483647(%rcx,%rbx,1)
    rorb gnu_fwd(%rip)
    rorb 4660
    rorb $63, 0(%r10)
    rorb $7, -1(%r15)
    rorb $0, 128(%r8)
    rorb $255, 0(%r12)
    rorb $63, 64(%r12)
    rorb $7, -129(%r12)
    rorb $0, 0(%r11,%rsi,2)
    rorb $255, 8(%r8,%rcx,4)
    rorb $63, -2147483648(%r9,%r9,8)
    rorb $7, %bh
    rorb $0, 0(%rsi)
    rorb $255, -128(%rcx)
    rorb $63, 2147483647(%rdx)
    rorb $7, 0(%rsp)
    rorb $0, 127(%rsp)
    rorb $255, 4660(%rsp)
    rorb $63, 0(%rdi,%rbp,1)
    rorb $7, -1(%rdx,%rsi,2)
    rorb $0, 128(%rbx,%rdi,4)
    rorb $255, gnu_back(%rip)
    rorb $63, -129
    rorb %cl, 0(%r11)
    rorb %cl, 64(%r9)
    rorb %cl, -2147483648(%r10)
    rorb %cl, 0(%r12)
    rorb %cl, 8(%r12)
    rorb %cl, 2147483647(%r12)
    rorb %cl, 0(%r12,%rbp,8)
    rorb %cl, -128(%r12,%r12,1)
    rorb %cl, 4660(%r13,%rax,2)
    rorb %cl, %ch
    rorb %cl, 0(%rdi)
    rorb %cl, 127(%rbx)
    rorb %cl, 128(%rbp)
    rorb %cl, 0(%rsp)
    rorb %cl, -1(%rsp)
    rorb %cl, -129(%rsp)
    rorb %cl, 0(%rax,%rax,4)
    rorb %cl, 64(%rsp,%rcx,8)
    rorb %cl, -2147483648(%rbp,%rdx,1)
    rorb %cl, gnu_fwd(%rip)
    rorb %cl, 2147483647
    rorw 0(%r14)
    rorw 8(%r11)
    rorw 4660(%r13)
    rorw 0(%r12)
    rorw -128(%r12)
    rorw 128(%r12)
    rorw 0(%r14,%r15,2)
    rorw 127(%r15,%rsi,4)
    rorw -129(%r8,%rcx,8)
    rorw %bp
    rorw 0(%rcx)
    rorw -1(%rsi)
    rorw -2147483648(%rdi)
    rorw 0(%rsp)
    rorw 64(%rsp)
    rorw 2147483647(%rsp)
    rorw 0(%rcx,%rbx,1)
    rorw 8(%rsi,%rbp,2)
    rorw 4660(%rdi,%rsi,4)
    rorw gnu_back(%rip)
    rorw 128
    rorw $7, 0(%r15)
    rorw $0, -128(%r14)
    rorw $255, -129(%r15)
    rorw $63, 0(%r12)
    rorw $7, 127(%r12)
    rorw $0, -2147483648(%r12)
    rorw $255, 0(%r15,%r9,8)
    rorw $63, -1(%r9,%rbp,1)
    rorw $7, 2147483647(%r12,%r12,2)
    rorw $0, %sp
    rorw $255, 0(%rdx)
    rorw $63, 64(%rcx)
    rorw $7, 4660(%rdx)
    rorw $0, 0(%rsp)
    rorw $255, 8(%rsp)
    rorw $63, 128(%rsp)
    rorw $7, 0(%rdx,%rdi,4)
    rorw $0, -128(%rax,%rax,8)
    rorw $255, -129(%rcx,%rcx,1)
    rorw $63, gnu_fwd(%rip)
    rorw $7, -2147483648
    rorw %cl, 0(%r8)
    rorw %cl, 127(%r8)
    rorw %cl, 2147483647(%r9)
    rorw %cl, 0(%r12)
    rorw %cl, -1(%r12)
    rorw %cl, 4660(%r12)
    rorw %cl, 0(%r8,%rax,2)
    rorw %cl, 64(%r13,%r15,4)
    rorw %cl, 128(%r15,%rsi,8)
    rorw %cl, %cx
    rorw %cl, 0(%rbx)
    rorw %cl, 8(%rbx)
    rorw %cl, -129(%rbp)
    rorw %cl, 0(%rsp)
    rorw %cl, -128(%rsp)
    rorw %cl, -2147483648(%rsp)
    rorw %cl, 0(%rbx,%rdx,1)
    rorw %cl, 127(%rdx,%rbx,2)
    rorw %cl, 2147483647(%rbx,%rbp,4)
    rorw %cl, gnu_back(%rip)
    rorw %cl, 4660
    rorl 0(%r9)
    rorl -1(%r10)
    rorl 128(%r11)
    rorl 0(%r12)
    rorl 64(%r12)
    rorl -129(%r12)
    rorl 0(%r9,%rcx,8)
    rorl 8(%r8,%r9,1)
    rorl -2147483648(%r9,%rbp,2)
    rorl %edx
    rorl 0(%rsi)
    rorl -128(%rsi)
    rorl 2147483647(%rdi)
    rorl 0(%rsp)
    rorl 127(%rsp)
    rorl 4660(%rsp)
    rorl 0(%rsp,%rsi,4)
    rorl -1(%rsp,%rdi,8)
    rorl 128(%rbp,%rax,1)
    rorl gnu_fwd(%rip)
    rorl -129
    rorl $0, 0(%r10)
    rorl $255, 64(%r13)
    rorl $63, -2147483648(%r14)
    rorl $7, 0(%r12)
    rorl $0, 8(%r12)
    rorl $255, 2147483647(%r12)
    rorl $63, 0(%r10,%r12,2)
    rorl $7, -128(%r12,%rax,4)
    rorl $0, 4660(%r13,%r15,8)
    rorl $255, %ebx
    rorl $63, 0(%rdi)
    rorl $7, 127(%rcx)
    rorl $0, 128(%rdx)
    rorl $255, 0(%rsp)
    rorl $63, -1(%rsp)
    rorl $7, -129(%rsp)
    rorl $0, 0(%rsi,%rcx,1)
    rorl $255, 64(%rsi,%rdx,2)
    rorl $63, -2147483648(%rdi,%rbx,4)
    rorl $7, gnu_back(%rip)
    rorl $0, 2147483647
    rorl %cl, 0(%r11)
    rorl %cl, 8(%r15)
    rorl %cl, 4660(%r8)
    rorl %cl, 0(%r12)
    rorl %cl, -128(%r12)
    rorl %cl, 128(%r12)
    rorl %cl, 0(%r11,%rsi,8)
    rorl %cl, 127(%r15,%rcx,1)
    rorl %cl, -129(%r8,%r9,2)
    rorl %cl, %esi
    rorl %cl, 0(%rcx)
    rorl %cl, -1(%rbx)
    rorl %cl, -2147483648(%rbp)
    rorl %cl, 0(%rsp)
    rorl %cl, 64(%rsp)
    rorl %cl, 2147483647(%rsp)
    rorl %cl, 0(%rdi,%rbp,4)
    rorl %cl, 8(%rax,%rsi,8)
    rorl %cl, 4660(%rcx,%rdi,1)
    rorl %cl, gnu_fwd(%rip)
    rorl %cl, 128
    rorq 0(%r15)
    rorq -128(%rbp)
    rorq -129(%r13)
    rorq 0(%r12)
    rorq 127(%rsp)
    rorq -2147483648(%r12)
    rorq 0(%r8,%rbp,2)
    rorq -1(%rdi,%r12,4)
    rorq 2147483647(%r15,%rax,8)
    rorq gnu_back(%rip)
    rorq 4660
    rorq $255, 0(%rcx)
    rorq $63, 64(%rdx)
    rorq $7, 128(%r9)
    rorq $0, 0(%rsp)
    rorq $255, 8(%r12)
    rorq $63, -129(%rsp)
g21:
    rorq $7, 0(%rcx,%r15,1)
    rorq $0, -128(%rax,%rsi,2)
    rorq $255, -2147483648(%r9,%rcx,4)
    rorq $63, gnu_fwd(%rip)
    rorq $7, 2147483647
    rorq %cl, 0(%r8)
    rorq %cl, 127(%rbx)
    rorq %cl, 4660(%r10)
    rorq %cl, 0(%r12)
    rorq %cl, -1(%rsp)
    rorq %cl, 128(%r12)
    rorq %cl, 0(%r12,%r9,8)
    rorq %cl, 64(%rsp,%rbp,1)
    rorq %cl, -129(%r13,%r12,2)
    rorq %cl, gnu_back(%rip)
    rorq %cl, -2147483648
    rclb 0(%r14)
    rclb 8(%r9)
    rclb 2147483647(%r10)
    rclb 0(%r12)
    rclb -128(%r12)
    rclb 4660(%r12)
    rclb 0(%r12,%rax,4)
    rclb 127(%r9,%r15,8)
    rclb 128(%r12,%rsi,1)
    rclb %ah
    rclb 0(%rdx)
    rclb -1(%rsi)
    rclb -129(%rdi)
    rclb 0(%rsp)
    rclb 64(%rsp)
    rclb -2147483648(%rsp)
    rclb 0(%rax,%rax,2)
    rclb 8(%rdx,%rcx,4)
    rclb 2147483647(%rbx,%rdx,8)
    rclb gnu_fwd(%rip)
    rclb 4660
    rclb $0, 0(%r15)
    rclb $255, -128(%r11)
    rclb $63, 128(%r13)
    rclb $7, 0(%r12)
    rclb $0, 127(%r12)
    rclb $255, -129(%r12)
    rclb $63, 0(%r14,%rcx,1)
    rclb $7, -1(%r13,%r9,2)
    rclb $0, -2147483648(%r15,%rbp,4)
    rclb $255, %cl
    rclb $63, 0(%rbx)
    rclb $7, 64(%rcx)
    rclb $0, 2147483647(%rdx)
    rclb $255, 0(%rsp)
    rclb $63, 8(%rsp)
    rclb $7, 4660(%rsp)
    rclb $0, 0(%rcx,%rbx,8)
    rclb $255, -128(%rsp,%rbp,1)
    rclb $63, 128(%rbp,%rsi,2)
    rclb $7, gnu_back(%rip)
    rclb $0, -129
    rclb %cl, 0(%r8)
    rclb %cl, 127(%r14)
    rclb %cl, -2147483648(%r15)
    rclb %cl, 0(%r12)
    rclb %cl, -1(%r12)
    rclb %cl, 2147483647(%r12)
    rclb %cl, 0(%r15,%r12,4)
    rclb %cl, 64(%r8,%rax,8)
    rclb %cl, 4660(%r9,%r15,1)
    rclb %cl, %dl
    rclb %cl, 0(%rsi)
    rclb %cl, 8(%rbx)
    rclb %cl, 128(%rbp)
    rclb %cl, 0(%rsp)
    rclb %cl, -128(%rsp)
    rclb %cl, -129(%rsp)
    rclb %cl, 0(%rdx,%rdi,2)
    rclb %cl, 127(%rsi,%rax,4)
    rclb %cl, -2147483648(%rdi,%rcx,8)
    rclb %cl, gnu_fwd(%rip)
    rclb %cl, 2147483647
    rclw 0(%r9)
    rclw -1(%r8)
    rclw 4660(%r9)
    rclw 0(%r12)
    rclw 64(%r12)
    rclw 128(%r12)
    rclw 0(%r8,%rsi,1)
    rclw 8(%r12,%rcx,2)
    rclw -129(%r13,%r9,4)
    rclw %di
    rclw 0(%rdi)
    rclw -128(%rsi)
    rclw -2147483648(%rdi)
    rclw 0(%rsp)
    rclw 127(%rsp)
    rclw 2147483647(%rsp)
    rclw 0(%rbx,%rdx,8)
    rclw -1(%rax,%rbx,1)
    rclw 4660(%rcx,%rbp,2)
    rclw gnu_back(%rip)
    rclw 128
    rclw $255, 0(%r10)
    rclw $63, 64(%r10)
    rclw $7, -129(%r11)
    rclw $0, 0(%r12)
    rclw $255, 8(%r12)
    rclw $63, -2147483648(%r12)
    rclw $7, 0(%r9,%rbp,4)
    rclw $0, -128(%r15,%r12,8)
    rclw $255, 2147483647(%r8,%rax,1)
    rclw $63, %bp
    rclw $7, 0(%rcx)
    rclw $0, 127(%rcx)
    rclw $255, 4660(%rdx)
    rclw $63, 0(%rsp)
    rclw $7, -1(%rsp)
    rclw $0, 128(%rsp)
    rclw $255, 0(%rsp,%rsi,2)
    rclw $63, 64(%rdx,%rdi,4)
    rclw $7, -129(%rbx,%rax,8)
    rclw $0, gnu_fwd(%rip)
    rclw $255, -2147483648
    rclw %cl, 0(%r11)
    rclw %cl, 8(%r13)
    rclw %cl, 2147483647(%r14)
    rclw %cl, 0(%r12)
    rclw %cl, -128(%r12)
    rclw %cl, 4660(%r12)
    rclw %cl, 0(%r10,%r15,1)
    rclw %cl, 127(%r9,%rsi,2)
    rclw %cl, 128(%r12,%rcx,4)
    rclw %cl, %sp
    rclw %cl, 0(%rdx)
    rclw %cl, -1(%rbx)
    rclw %cl, -129(%rbp)
    rclw %cl, 0(%rsp)
    rclw %cl, 64(%rsp)
    rclw %cl, -2147483648(%rsp)
    rclw %cl, 0(%rsi,%rcx,8)
    rclw %cl, 8(%rsp,%rdx,1)
    rclw %cl, 2147483647(%rbp,%rbx,2)
    rclw %cl, gnu_back(%rip)
    rclw %cl, 4660
    rcll 0(%r14)
    rcll -128(%r15)
    rcll 128(%r8)
    rcll 0(%r12)
    rcll 127(%r12)
    rcll -129(%r12)
    rcll 0(%r11,%r9,4)
    rcll -1(%r13,%rbp,8)
    rcll -2147483648(%r15,%r12,1)
    rcll %ecx
    rcll 0(%rbx)
    rcll 64(%rsi)
    rcll 2147483647(%rdi)
    rcll 0(%rsp)
    rcll 8(%rsp)
    rcll 4660(%rsp)
    rcll 0(%rdi,%rbp,2)
    rcll -128(%rsi,%rsi,4)
    rcll 128(%rdi,%rdi,8)
    rcll gnu_fwd(%rip)
    rcll -129
    rcll $63, 0(%r15)
    rcll $7, 127(%r9)
    rcll $0, -2147483648(%r10)
    rcll $255, 0(%r12)
    rcll $63, -1(%r12)
    rcll $7, 2147483647(%r12)
    rcll $0, 0(%r12,%rax,1)
    rcll $255, 64(%r8,%r15,2)
    rcll $63, 4660(%r9,%rsi,4)
    rcll $7, %edx
    rcll $0, 0(%rsi)
    rcll $255, 8(%rcx)
    rcll $63, 128(%rdx)
    rcll $7, 0(%rsp)
    rcll $0, -128(%rsp)
    rcll $255, -129(%rsp)
    rcll $63, 0(%rax,%rax,8)
    rcll $7, 127(%rax,%rcx,1)
    rcll $0, -2147483648(%rcx,%rdx,2)
    rcll $255, gnu_back(%rip)
    rcll $63, 2147483647
    rcll %cl, 0(%r8)
    rcll %cl, -1(%r11)
    rcll %cl, 4660(%r13)
    rcll %cl, 0(%r12)
    rcll %cl, 64(%r12)
    rcll %cl, 128(%r12)
    rcll %cl, 0(%r14,%rcx,4)
    rcll %cl, 8(%r12,%r9,8)
    rcll %cl, -129(%r13,%rbp,1)
    rcll %cl, %ebx
    rcll %cl, 0(%rdi)
    rcll %cl, -128(%rbx)
    rcll %cl, -2147483648(%rbp)
    rcll %cl, 0(%rsp)
    rcll %cl, 127(%rsp)
    rcll %cl, 2147483647(%rsp)
g22:
    rcll %cl, 0(%rcx,%rbx,2)
    rcll %cl, -1(%rdx,%rbp,4)
    rcll %cl, 4660(%rbx,%rsi,8)
    rcll %cl, gnu_fwd(%rip)
    rcll %cl, 128
    rclq 0(%rdx)
    rclq 64(%rsi)
    rclq -129(%r11)
    rclq 0(%rsp)
    rclq 8(%r12)
    rclq -2147483648(%rsp)
    rclq 0(%rdx,%r12,1)
    rclq -128(%rbp,%rax,2)
    rclq 2147483647(%r12,%r15,4)
    rclq gnu_back(%rip)
    rclq 4660
    rclq $7, 0(%r9)
    rclq $0, 127(%rdi)
    rclq $255, 128(%r14)
    rclq $63, 0(%r12)
    rclq $7, -1(%rsp)
    rclq $0, -129(%r12)
    rclq $255, 0(%r9,%rsi,8)
    rclq $63, 64(%rdi,%rcx,1)
    rclq $7, -2147483648(%r15,%r9,2)
    rclq $0, gnu_fwd(%rip)
    rclq $255, 2147483647
    rclq %cl, 0(%rbx)
    rclq %cl, 8(%r15)
    rclq %cl, 4660(%rcx)
    rclq %cl, 0(%rsp)
    rclq %cl, -128(%r12)
    rclq %cl, 128(%rsp)
    rclq %cl, 0(%rsp,%rbp,4)
    rclq %cl, 127(%rax,%r12,8)
    rclq %cl, -129(%r9,%rax,1)
    rclq %cl, gnu_back(%rip)
    rclq %cl, -2147483648
    rcrb 0(%r9)
    rcrb -1(%r14)
    rcrb 2147483647(%r15)
    rcrb 0(%r12)
    rcrb 64(%r12)
    rcrb 4660(%r12)
    rcrb 0(%r15,%r15,2)
    rcrb 8(%r15,%rsi,4)
    rcrb 128(%r8,%rcx,8)
    rcrb %bl
    rcrb 0(%rcx)
    rcrb -128(%rsi)
    rcrb -129(%rdi)
    rcrb 0(%rsp)
    rcrb 127(%rsp)
    rcrb -2147483648(%rsp)
    rcrb 0(%rdx,%rdi,1)
    rcrb -1(%rsp,%rax,2)
    rcrb 2147483647(%rbp,%rcx,4)
    rcrb gnu_fwd(%rip)
    rcrb 4660
    rcrb $63, 0(%r10)
    rcrb $7, 64(%r8)
    rcrb $0, 128(%r9)
    rcrb $255, 0(%r12)
    rcrb $63, 8(%r12)
    rcrb $7, -129(%r12)
    rcrb $0, 0(%r8,%r9,8)
    rcrb $255, -128(%r9,%rbp,1)
    rcrb $63, -2147483648(%r12,%r12,2)
    rcrb $7, %dh
    rcrb $0, 0(%rdx)
    rcrb $255, 127(%rcx)
    rcrb $63, 2147483647(%rdx)
    rcrb $7, 0(%rsp)
    rcrb $0, -1(%rsp)
    rcrb $255, 4660(%rsp)
    rcrb $63, 0(%rbx,%rdx,4)
    rcrb $7, 64(%rsi,%rbx,8)
    rcrb $0, 128(%rdi,%rbp,1)
    rcrb $255, gnu_back(%rip)
    rcrb $63, -129
    rcrb %cl, 0(%r11)
    rcrb %cl, 8(%r10)
    rcrb %cl, -2147483648(%r11)
    rcrb %cl, 0(%r12)
    rcrb %cl, -128(%r12)
    rcrb %cl, 2147483647(%r12)
    rcrb %cl, 0(%r9,%rax,2)
    rcrb %cl, 127(%r13,%r15,4)
    rcrb %cl, 4660(%r15,%rsi,8)
    rcrb %cl, %bh
    rcrb %cl, 0(%rbx)
    rcrb %cl, -1(%rbx)
    rcrb %cl, 128(%rbp)
    rcrb %cl, 0(%rsp)
    rcrb %cl, 64(%rsp)
    rcrb %cl, -129(%rsp)
    rcrb %cl, 0(%rsp,%rsi,1)
    rcrb %cl, 8(%rax,%rdi,2)
    rcrb %cl, -2147483648(%rcx,%rax,4)
    rcrb %cl, gnu_fwd(%rip)
    rcrb %cl, 2147483647
    rcrw 0(%r14)
    rcrw -128(%r13)
    rcrw 4660(%r14)
    rcrw 0(%r12)
    rcrw 127(%r12)
    rcrw 128(%r12)
    rcrw 0(%r10,%rcx,8)
    rcrw -1(%r8,%r9,1)
    rcrw -129(%r9,%rbp,2)
    rcrw %si
    rcrw 0(%rsi)
    rcrw 64(%rsi)
    rcrw -2147483648(%rdi)
    rcrw 0(%rsp)
    rcrw 8(%rsp)
    rcrw 2147483647(%rsp)
    rcrw 0(%rsi,%rcx,4)
    rcrw -128(%rdx,%rdx,8)
    rcrw 4660(%rbx,%rbx,1)
    rcrw gnu_back(%rip)
    rcrw 128
    rcrw $7, 0(%r15)
    rcrw $0, 127(%r15)
    rcrw $255, -129(%r8)
    rcrw $63, 0(%r12)
    rcrw $7, -1(%r12)
    rcrw $0, -2147483648(%r12)
    rcrw $255, 0(%r11,%r12,2)
    rcrw $63, 64(%r12,%rax,4)
    rcrw $7, 2147483647(%r13,%r15,8)
    rcrw $0, %di
    rcrw $255, 0(%rdi)
    rcrw $63, 8(%rcx)
    rcrw $7, 4660(%rdx)
    rcrw $0, 0(%rsp)
    rcrw $255, -128(%rsp)
    rcrw $63, 128(%rsp)
    rcrw $7, 0(%rdi,%rbp,1)
    rcrw $0, 127(%rsp,%rsi,2)
    rcrw $255, -129(%rbp,%rdi,4)
    rcrw $63, gnu_fwd(%rip)
    rcrw $7, -2147483648
    rcrw %cl, 0(%r8)
    rcrw %cl, -1(%r9)
    rcrw %cl, 2147483647(%r10)
    rcrw %cl, 0(%r12)
    rcrw %cl, 64(%r12)
    rcrw %cl, 4660(%r12)
    rcrw %cl, 0(%r12,%rsi,8)
    rcrw %cl, 8(%r15,%rcx,1)
    rcrw %cl, 128(%r8,%r9,2)
    rcrw %cl, %bp
    rcrw %cl, 0(%rcx)
    rcrw %cl, -128(%rbx)
    rcrw %cl, -129(%rbp)
    rcrw %cl, 0(%rsp)
    rcrw %cl, 127(%rsp)
    rcrw %cl, -2147483648(%rsp)
    rcrw %cl, 0(%rax,%rax,4)
    rcrw %cl, -1(%rsi,%rcx,8)
    rcrw %cl, 2147483647(%rdi,%rdx,1)
    rcrw %cl, gnu_back(%rip)
    rcrw %cl, 4660
    rcrl 0(%r9)
    rcrl 64(%r11)
    rcrl 128(%r13)
    rcrl 0(%r12)
    rcrl 8(%r12)
    rcrl -129(%r12)
    rcrl 0(%r14,%rbp,2)
    rcrl -128(%r9,%r12,4)
    rcrl -2147483648(%r12,%rax,8)
    rcrl %esp
    rcrl 0(%rdx)
    rcrl 127(%rsi)
    rcrl 2147483647(%rdi)
    rcrl 0(%rsp)
    rcrl -1(%rsp)
    rcrl 4660(%rsp)
    rcrl 0(%rcx,%rbx,1)
    rcrl 64(%rax,%rbp,2)
    rcrl 128(%rcx,%rsi,4)
    rcrl gnu_fwd(%rip)
    rcrl -129
    rcrl $0, 0(%r10)
    rcrl $255, 8(%r14)
    rcrl $63, -2147483648(%r15)
    rcrl $7, 0(%r12)
    rcrl $0, -128(%r12)
    rcrl $255, 2147483647(%r12)
    rcrl $63, 0(%r15,%r15,8)
    rcrl $7, 127(%r13,%rsi,1)
    rcrl $0, 4660(%r15,%rcx,2)
    rcrl $255, %ecx
    rcrl $63, 0(%rbx)
    rcrl $7, -1(%rcx)
    rcrl $0, 128(%rdx)
    rcrl $255, 0(%rsp)
    rcrl $63, 64(%rsp)
g23:
    rcrl $7, -129(%rsp)
    rcrl $0, 0(%rdx,%rdi,4)
    rcrl $255, 8(%rdx,%rax,8)
    rcrl $63, -2147483648(%rbx,%rcx,1)
    rcrl $7, gnu_back(%rip)
    rcrl $0, 2147483647
    rcrl %cl, 0(%r11)
    rcrl %cl, -128(%r8)
    rcrl %cl, 4660(%r9)
    rcrl %cl, 0(%r12)
    rcrl %cl, 127(%r12)
    rcrl %cl, 128(%r12)
    rcrl %cl, 0(%r8,%r9,2)
    rcrl %cl, -1(%r8,%rbp,4)
    rcrl %cl, -129(%r9,%r12,8)
    rcrl %cl, %edx
    rcrl %cl, 0(%rsi)
    rcrl %cl, 64(%rbx)
    rcrl %cl, -2147483648(%rbp)
    rcrl %cl, 0(%rsp)
    rcrl %cl, 8(%rsp)
    rcrl %cl, 2147483647(%rsp)
    rcrl %cl, 0(%rbx,%rdx,1)
    rcrl %cl, -128(%rsp,%rbx,2)
    rcrl %cl, 4660(%rbp,%rbp,4)
    rcrl %cl, gnu_fwd(%rip)
    rcrl %cl, 128
    rcrq 0(%r10)
    rcrq 127(%r8)
    rcrq -129(%rbp)
    rcrq 0(%r12)
    rcrq -1(%rsp)
    rcrq -2147483648(%r12)
    rcrq 0(%r14,%rax,8)
    rcrq 64(%rsp,%r15,1)
    rcrq 2147483647(%r13,%rsi,2)
    rcrq gnu_back(%rip)
    rcrq 4660
    rcrq $255, 0(%rsi)
    rcrq $63, 8(%r13)
    rcrq $7, 128(%rdx)
    rcrq $0, 0(%rsp)
    rcrq $255, -128(%r12)
    rcrq $63, -129(%rsp)
    rcrq $7, 0(%rsi,%rcx,4)
    rcrq $0, 127(%rbp,%r9,8)
    rcrq $255, -2147483648(%r12,%rbp,1)
    rcrq $63, gnu_fwd(%rip)
    rcrq $7, 2147483647
    rcrq %cl, 0(%r11)
    rcrq %cl, -1(%r9)
    rcrq %cl, 4660(%rbx)
    rcrq %cl, 0(%r12)
    rcrq %cl, 64(%rsp)
    rcrq %cl, 128(%r12)
    rcrq %cl, 0(%r15,%r12,2)
    rcrq %cl, 8(%rdi,%rax,4)
    rcrq %cl, -129(%r15,%r15,8)
    rcrq %cl, gnu_back(%rip)
    rcrq %cl, -2147483648
    shlb 0(%r14)
    shlb -128(%r10)
    shlb 2147483647(%r11)
    shlb 0(%r12)
    shlb 127(%r12)
    shlb 4660(%r12)
    shlb 0(%r9,%rsi,1)
    shlb -1(%r12,%rcx,2)
    shlb 128(%r13,%r9,4)
    shlb %ch
    shlb 0(%rdi)
    shlb 64(%rsi)
    shlb -129(%rdi)
    shlb 0(%rsp)
    shlb 8(%rsp)
    shlb -2147483648(%rsp)
    shlb 0(%rsp,%rsi,8)
    shlb -128(%rsi,%rdi,1)
    shlb 2147483647(%rdi,%rax,2)
    shlb gnu_fwd(%rip)
    shlb 4660
    shlb $0, 0(%r15)
    shlb $255, 127(%r13)
    shlb $63, 128(%r14)
    shlb $7, 0(%r12)
    shlb $0, -1(%r12)
    shlb $255, -129(%r12)
    shlb $63, 0(%r10,%rbp,4)
    shlb $7, 64(%r15,%r12,8)
    shlb $0, -2147483648(%r8,%rax,1)
    shlb $255, %ah
    shlb $63, 0(%rcx)
    shlb $7, 8(%rcx)
    shlb $0, 2147483647(%rdx)
    shlb $255, 0(%rsp)
    shlb $63, -128(%rsp)
    shlb $7, 4660(%rsp)
    shlb $0, 0(%rsi,%rcx,2)
    shlb $255, 127(%rax,%rdx,4)
    shlb $63, 128(%rcx,%rbx,8)
    shlb $7, gnu_back(%rip)
    shlb $0, -129
    shlb %cl, 0(%r8)
    shlb %cl, -1(%r15)
    shlb %cl, -2147483648(%r8)
    shlb %cl, 0(%r12)
    shlb %cl, 64(%r12)
    shlb %cl, 2147483647(%r12)
    shlb %cl, 0(%r11,%r15,1)
    shlb %cl, 8(%r9,%rsi,2)
    shlb %cl, 4660(%r12,%rcx,4)
    shlb %cl, %cl
    shlb %cl, 0(%rdx)
    shlb %cl, -128(%rbx)
    shlb %cl, 128(%rbp)
    shlb %cl, 0(%rsp)
    shlb %cl, 127(%rsp)
    shlb %cl, -129(%rsp)
    shlb %cl, 0(%rdi,%rbp,8)
    shlb %cl, -1(%rdx,%rsi,1)
    shlb %cl, -2147483648(%rbx,%rdi,2)
    shlb %cl, gnu_fwd(%rip)
    shlb %cl, 2147483647
    shlw 0(%r9)
    shlw 64(%r9)
    shlw 4660(%r10)
    shlw 0(%r12)
    shlw 8(%r12)
    shlw 128(%r12)
    shlw 0(%r12,%r9,4)
    shlw -128(%r13,%rbp,8)
    shlw -129(%r15,%r12,1)
    shlw %bx
    shlw 0(%rbx)
    shlw 127(%rsi)
    shlw -2147483648(%rdi)
    shlw 0(%rsp)
    shlw -1(%rsp)
    shlw 2147483647(%rsp)
    shlw 0(%rax,%rax,2)
    shlw 64(%rsp,%rcx,4)
    shlw 4660(%rbp,%rdx,8)
    shlw gnu_back(%rip)
    shlw 128
    shlw $255, 0(%r10)
    shlw $63, 8(%r11)
    shlw $7, -129(%r13)
    shlw $0, 0(%r12)
    shlw $255, -128(%r12)
    shlw $63, -2147483648(%r12)
    shlw $7, 0(%r14,%rax,1)
    shlw $0, 127(%r8,%r15,2)
    shlw $255, 2147483647(%r9,%rsi,4)
    shlw $63, %si
    shlw $7, 0(%rsi)
    shlw $0, -1(%rcx)
    shlw $255, 4660(%rdx)
    shlw $63, 0(%rsp)
    shlw $7, 64(%rsp)
    shlw $0, 128(%rsp)
    shlw $255, 0(%rcx,%rbx,8)
    shlw $63, 8(%rsi,%rbp,1)
    shlw $7, -129(%rdi,%rsi,2)
    shlw $0, gnu_fwd(%rip)
    shlw $255, -2147483648
    shlw %cl, 0(%r11)
    shlw %cl, -128(%r14)
    shlw %cl, 2147483647(%r15)
    shlw %cl, 0(%r12)
    shlw %cl, 127(%r12)
    shlw %cl, 4660(%r12)
    shlw %cl, 0(%r15,%rcx,4)
    shlw %cl, -1(%r12,%r9,8)
    shlw %cl, 128(%r13,%rbp,1)
    shlw %cl, %di
    shlw %cl, 0(%rdi)
    shlw %cl, 64(%rbx)
    shlw %cl, -129(%rbp)
    shlw %cl, 0(%rsp)
    shlw %cl, 8(%rsp)
    shlw %cl, -2147483648(%rsp)
    shlw %cl, 0(%rdx,%rdi,2)
    shlw %cl, -128(%rax,%rax,4)
    shlw %cl, 2147483647(%rcx,%rcx,8)
    shlw %cl, gnu_back(%rip)
    shlw %cl, 4660
    shll 0(%r14)
    shll 127(%r8)
    shll 128(%r9)
    shll 0(%r12)
    shll -1(%r12)
    shll -129(%r12)
    shll 0(%r8,%r12,1)
    shll 64(%r15,%rax,2)
    shll -2147483648(%r8,%r15,4)
    shll %ebp
    shll 0(%rcx)
    shll 8(%rsi)
    shll 2147483647(%rdi)
    shll 0(%rsp)
g24:
    shll -128(%rsp)
    shll 4660(%rsp)
    shll 0(%rbx,%rdx,8)
    shll 127(%rdx,%rbx,1)
    shll 128(%rbx,%rbp,2)
    shll gnu_fwd(%rip)
    shll -129
    shll $63, 0(%r15)
    shll $7, -1(%r10)
    shll $0, -2147483648(%r11)
    shll $255, 0(%r12)
    shll $63, 64(%r12)
    shll $7, 2147483647(%r12)
    shll $0, 0(%r9,%rsi,4)
    shll $255, 8(%r9,%rcx,8)
    shll $63, 4660(%r12,%r9,1)
    shll $7, %esp
    shll $0, 0(%rdx)
    shll $255, -128(%rcx)
    shll $63, 128(%rdx)
    shll $7, 0(%rsp)
    shll $0, 127(%rsp)
    shll $255, -129(%rsp)
    shll $63, 0(%rsp,%rsi,2)
    shll $7, -1(%rsp,%rdi,4)
    shll $0, -2147483648(%rbp,%rax,8)
    shll $255, gnu_back(%rip)
    shll $63, 2147483647
    shll %cl, 0(%r8)
    shll %cl, 64(%r13)
    shll %cl, 4660(%r14)
    shll %cl, 0(%r12)
    shll %cl, 8(%r12)
    shll %cl, 128(%r12)
    shll %cl, 0(%r10,%rbp,1)
    shll %cl, -128(%r13,%r12,2)
    shll %cl, -129(%r15,%rax,4)
    shll %cl, %ecx
    shll %cl, 0(%rbx)
    shll %cl, 127(%rbx)
    shll %cl, -2147483648(%rbp)
    shll %cl, 0(%rsp)
    shll %cl, -1(%rsp)
    shll %cl, 2147483647(%rsp)
    shll %cl, 0(%rsi,%rcx,8)
    shll %cl, 64(%rsi,%rdx,1)
    shll %cl, 4660(%rdi,%rbx,2)
    shll %cl, gnu_fwd(%rip)
    shll %cl, 128
    shlq 0(%rdi)
    shlq 8(%r10)
    shlq -129(%rsi)
    shlq 0(%rsp)
    shlq -128(%r12)
    shlq -2147483648(%rsp)
    shlq 0(%rax,%r15,4)
    shlq 127(%rax,%rsi,8)
    shlq 2147483647(%r9,%rcx,1)
    shlq gnu_back(%rip)
    shlq 4660
    shlq $7, 0(%r14)
    shlq $0, -1(%r11)
    shlq $255, 128(%rdi)
    shlq $63, 0(%r12)
    shlq $7, 64(%rsp)
    shlq $0, -129(%r12)
    shlq $255, 0(%r8,%r9,2)
    shlq $63, 8(%rsp,%rbp,4)
    shlq $7, -2147483648(%r13,%r12,8)
    shlq $0, gnu_fwd(%rip)
    shlq $255, 2147483647
    shlq %cl, 0(%r15)
    shlq %cl, -128(%r14)
    shlq %cl, 4660(%r15)
    shlq %cl, 0(%rsp)
    shlq %cl, 127(%r12)
    shlq %cl, 128(%rsp)
    shlq %cl, 0(%rcx,%rax,1)
    shlq %cl, -1(%rbp,%r15,2)
    shlq %cl, -129(%r12,%rsi,4)
    shlq %cl, gnu_back(%rip)
    shlq %cl, -2147483648
    shrb 0(%r9)
    shrb 64(%r15)
    shrb 2147483647(%r8)
    shrb 0(%r12)
    shrb 8(%r12)
    shrb 4660(%r12)
    shrb 0(%r11,%rcx,8)
    shrb -128(%r8,%r9,1)
    shrb 128(%r9,%rbp,2)
    shrb %dl
    shrb 0(%rsi)
    shrb 127(%rsi)
    shrb -129(%rdi)
    shrb 0(%rsp)
    shrb -1(%rsp)
    shrb -2147483648(%rsp)
    shrb 0(%rdi,%rbp,4)
    shrb 64(%rax,%rsi,8)
    shrb 2147483647(%rcx,%rdi,1)
    shrb gnu_fwd(%rip)
    shrb 4660
    shrb $63, 0(%r10)
    shrb $7, 8(%r9)
    shrb $0, 128(%r10)
    shrb $255, 0(%r12)
    shrb $63, -128(%r12)
    shrb $7, -129(%r12)
    shrb $0, 0(%r12,%r12,2)
    shrb $255, 127(%r12,%rax,4)
    shrb $63, -2147483648(%r13,%r15,8)
    shrb $7, %bl
    shrb $0, 0(%rdi)
    shrb $255, -1(%rcx)
    shrb $63, 2147483647(%rdx)
    shrb $7, 0(%rsp)
    shrb $0, 64(%rsp)
    shrb $255, 4660(%rsp)
    shrb $63, 0(%rax,%rax,1)
    shrb $7, 8(%rdx,%rcx,2)
    shrb $0, 128(%rbx,%rdx,4)
    shrb $255, gnu_back(%rip)
    shrb $63, -129
    shrb %cl, 0(%r11)
    shrb %cl, -128(%r11)
    shrb %cl, -2147483648(%r13)
    shrb %cl, 0(%r12)
    shrb %cl, 127(%r12)
    shrb %cl, 2147483647(%r12)
    shrb %cl, 0(%r14,%rsi,8)
    shrb %cl, -1(%r15,%rcx,1)
    shrb %cl, 4660(%r8,%r9,2)
    shrb %cl, %dh
    shrb %cl, 0(%rcx)
    shrb %cl, 64(%rbx)
    shrb %cl, 128(%rbp)
    shrb %cl, 0(%rsp)
    shrb %cl, 8(%rsp)
    shrb %cl, -129(%rsp)
    shrb %cl, 0(%rcx,%rbx,4)
    shrb %cl, -128(%rsp,%rbp,8)
    shrb %cl, -2147483648(%rbp,%rsi,1)
    shrb %cl, gnu_fwd(%rip)
    shrb %cl, 2147483647
    shrw 0(%r14)
    shrw 127(%r14)
    shrw 4660(%r15)
    shrw 0(%r12)
    shrw -1(%r12)
    shrw 128(%r12)
    shrw 0(%r15,%rbp,2)
    shrw 64(%r9,%r12,4)
    shrw -129(%r12,%rax,8)
    shrw %dx
    shrw 0(%rdx)
    shrw 8(%rsi)
    shrw -2147483648(%rdi)
    shrw 0(%rsp)
    shrw -128(%rsp)
    shrw 2147483647(%rsp)
    shrw 0(%rdx,%rdi,1)
    shrw 127(%rsi,%rax,2)
    shrw 4660(%rdi,%rcx,4)
    shrw gnu_back(%rip)
    shrw 128
    shrw $7, 0(%r15)
    shrw $0, -1(%r8)
    shrw $255, -129(%r9)
    shrw $63, 0(%r12)
    shrw $7, 64(%r12)
    shrw $0, -2147483648(%r12)
    shrw $255, 0(%r8,%r15,8)
    shrw $63, 8(%r13,%rsi,1)
    shrw $7, 2147483647(%r15,%rcx,2)
    shrw $0, %bx
    shrw $255, 0(%rbx)
    shrw $63, -128(%rcx)
    shrw $7, 4660(%rdx)
    shrw $0, 0(%rsp)
    shrw $255, 127(%rsp)
    shrw $63, 128(%rsp)
    shrw $7, 0(%rbx,%rdx,4)
    shrw $0, -1(%rax,%rbx,8)
    shrw $255, -129(%rcx,%rbp,1)
    shrw $63, gnu_fwd(%rip)
    shrw $7, -2147483648
    shrw %cl, 0(%r8)
    shrw %cl, 64(%r10)
    shrw %cl, 2147483647(%r11)
    shrw %cl, 0(%r12)
    shrw %cl, 8(%r12)
    shrw %cl, 4660(%r12)
    shrw %cl, 0(%r9,%r9,2)
    shrw %cl, -128(%r8,%rbp,4)
    shrw %cl, 128(%r9,%r12,8)
    shrw %cl, %si
    shrw %cl, 0(%rsi)
    shrw %cl, 127(%rbx)
    shrw %cl, -129(%rbp)
g25:
    shrw %cl, 0(%rsp)
    shrw %cl, -1(%rsp)
    shrw %cl, -2147483648(%rsp)
    shrw %cl, 0(%rsp,%rsi,1)
    shrw %cl, 64(%rdx,%rdi,2)
    shrw %cl, 2147483647(%rbx,%rax,4)
    shrw %cl, gnu_back(%rip)
    shrw %cl, 4660
    shrl 0(%r9)
    shrl 8(%r13)
    shrl 128(%r14)
    shrl 0(%r12)
    shrl -128(%r12)
    shrl -129(%r12)
    shrl 0(%r10,%rax,8)
    shrl 127(%r12,%r15,1)
    shrl -2147483648(%r13,%rsi,2)
    shrl %edi
    shrl 0(%rdi)
    shrl -1(%rsi)
    shrl 2147483647(%rdi)
    shrl 0(%rsp)
    shrl 64(%rsp)
    shrl 4660(%rsp)
    shrl 0(%rsi,%rcx,4)
    shrl 8(%rsp,%rdx,8)
    shrl 128(%rbp,%rbx,1)
    shrl gnu_fwd(%rip)
    shrl -129
    shrl $0, 0(%r10)
    shrl $255, -128(%r15)
    shrl $63, -2147483648(%r8)
    shrl $7, 0(%r12)
    shrl $0, 127(%r12)
    shrl $255, 2147483647(%r12)
    shrl $63, 0(%r11,%rcx,2)
    shrl $7, -1(%r15,%r9,4)
    shrl $0, 4660(%r8,%rbp,8)
    shrl $255, %ebp
    shrl $63, 0(%rcx)
    shrl $7, 64(%rcx)
    shrl $0, 128(%rdx)
    shrl $255, 0(%rsp)
    shrl $63, 8(%rsp)
    shrl $7, -129(%rsp)
    shrl $0, 0(%rdi,%rbp,1)
    shrl $255, -128(%rsi,%rsi,2)
    shrl $63, -2147483648(%rdi,%rdi,4)
    shrl $7, gnu_back(%rip)
    shrl $0, 2147483647
    shrl %cl, 0(%r11)
    shrl %cl, 127(%r9)
    shrl %cl, 4660(%r10)
    shrl %cl, 0(%r12)
    shrl %cl, -1(%r12)
    shrl %cl, 128(%r12)
    shrl %cl, 0(%r12,%r12,8)
    shrl %cl, 64(%r9,%rax,1)
    shrl %cl, -129(%r12,%r15,2)
    shrl %cl, %esp
    shrl %cl, 0(%rdx)
    shrl %cl, 8(%rbx)
    shrl %cl, -2147483648(%rbp)
    shrl %cl, 0(%rsp)
    shrl %cl, -128(%rsp)
    shrl %cl, 2147483647(%rsp)
    shrl %cl, 0(%rax,%rax,4)
    shrl %cl, 127(%rax,%rcx,8)
    shrl %cl, 4660(%rcx,%rdx,1)
    shrl %cl, gnu_fwd(%rip)
    shrl %cl, 128
    shrq 0(%rcx)
    shrq -1(%rcx)
    shrq -129(%r8)
    shrq 0(%r12)
    shrq 64(%rsp)
    shrq -2147483648(%r12)
    shrq 0(%r12,%rsi,2)
    shrq 8(%rdi,%rcx,4)
    shrq 2147483647(%r15,%r9,8)
    shrq gnu_back(%rip)
    shrq 4660
    shrq $255, 0(%r8)
    shrq $63, -128(%rbp)
    shrq $7, 128(%r13)
    shrq $0, 0(%rsp)
    shrq $255, 127(%r12)
    shrq $63, -129(%rsp)
    shrq $7, 0(%rdx,%rbp,1)
    shrq $0, -1(%rax,%r12,2)
    shrq $255, -2147483648(%r9,%rax,4)
    shrq $63, gnu_fwd(%rip)
    shrq $7, 2147483647
    shrq %cl, 0(%rdx)
    shrq %cl, 64(%rdx)
    shrq %cl, 4660(%r9)
    shrq %cl, 0(%r12)
    shrq %cl, 8(%rsp)
    shrq %cl, 128(%r12)
    shrq %cl, 0(%r9,%r15,8)
    shrq %cl, -128(%rsp,%rsi,1)
    shrq %cl, -129(%r13,%rcx,2)
    shrq %cl, gnu_back(%rip)
    shrq %cl, -2147483648
    sarb 0(%r14)
    sarb 127(%r11)
    sarb 2147483647(%r13)
    sarb 0(%r12)
    sarb -1(%r12)
    sarb 4660(%r12)
    sarb 0(%r14,%r9,4)
    sarb 64(%r13,%rbp,8)
    sarb 128(%r15,%r12,1)
    sarb %bh
    sarb 0(%rbx)
    sarb 8(%rsi)
    sarb -129(%rdi)
    sarb 0(%rsp)
    sarb -128(%rsp)
    sarb -2147483648(%rsp)
    sarb 0(%rcx,%rbx,2)
    sarb 127(%rdx,%rbp,4)
    sarb 2147483647(%rbx,%rsi,8)
    sarb gnu_fwd(%rip)
    sarb 4660
    sarb $0, 0(%r15)
    sarb $255, -1(%r14)
    sarb $63, 128(%r15)
    sarb $7, 0(%r12)
    sarb $0, 64(%r12)
    sarb $255, -129(%r12)
    sarb $63, 0(%r15,%rax,1)
    sarb $7, 8(%r8,%r15,2)
    sarb $0, -2147483648(%r9,%rsi,4)
    sarb $255, %ch
    sarb $63, 0(%rsi)
    sarb $7, -128(%rcx)
    sarb $0, 2147483647(%rdx)
    sarb $255, 0(%rsp)
    sarb $63, 127(%rsp)
    sarb $7, 4660(%rsp)
    sarb $0, 0(%rdx,%rdi,8)
    sarb $255, -1(%rsp,%rax,1)
    sarb $63, 128(%rbp,%rcx,2)
    sarb $7, gnu_back(%rip)
    sarb $0, -129
    sarb %cl, 0(%r8)
    sarb %cl, 64(%r8)
    sarb %cl, -2147483648(%r9)
    sarb %cl, 0(%r12)
    sarb %cl, 8(%r12)
    sarb %cl, 2147483647(%r12)
    sarb %cl, 0(%r8,%rcx,4)
    sarb %cl, -128(%r12,%r9,8)
    sarb %cl, 4660(%r13,%rbp,1)
    sarb %cl, %ah
    sarb %cl, 0(%rdi)
    sarb %cl, 127(%rbx)
    sarb %cl, 128(%rbp)
    sarb %cl, 0(%rsp)
    sarb %cl, -1(%rsp)
    sarb %cl, -129(%rsp)
    sarb %cl, 0(%rbx,%rdx,2)
    sarb %cl, 64(%rsi,%rbx,4)
    sarb %cl, -2147483648(%rdi,%rbp,8)
    sarb %cl, gnu_fwd(%rip)
    sarb %cl, 2147483647
    sarw 0(%r9)
    sarw 8(%r10)
    sarw 4660(%r11)
    sarw 0(%r12)
    sarw -128(%r12)
    sarw 128(%r12)
    sarw 0(%r9,%r12,1)
    sarw 127(%r15,%rax,2)
    sarw -129(%r8,%r15,4)
    sarw %cx
    sarw 0(%rcx)
    sarw -1(%rsi)
    sarw -2147483648(%rdi)
    sarw 0(%rsp)
    sarw 64(%rsp)
    sarw 2147483647(%rsp)
    sarw 0(%rsp,%rsi,8)
    sarw 8(%rax,%rdi,1)
    sarw 4660(%rcx,%rax,2)
    sarw gnu_back(%rip)
    sarw 128
    sarw $255, 0(%r10)
    sarw $63, -128(%r13)
    sarw $7, -129(%r14)
    sarw $0, 0(%r12)
    sarw $255, 127(%r12)
    sarw $63, -2147483648(%r12)
    sarw $7, 0(%r10,%rsi,4)
    sarw $0, -1(%r9,%rcx,8)
    sarw $255, 2147483647(%r12,%r9,1)
    sarw $63, %dx
    sarw $7, 0(%rdx)
    sarw $0, 64(%rcx)
g26:
    sarw $255, 4660(%rdx)
    sarw $63, 0(%rsp)
    sarw $7, 8(%rsp)
    sarw $0, 128(%rsp)
    sarw $255, 0(%rsi,%rcx,2)
    sarw $63, -128(%rdx,%rdx,4)
    sarw $7, -129(%rbx,%rbx,8)
    sarw $0, gnu_fwd(%rip)
    sarw $255, -2147483648
    sarw %cl, 0(%r11)
    sarw %cl, 127(%r15)
    sarw %cl, 2147483647(%r8)
    sarw %cl, 0(%r12)
    sarw %cl, -1(%r12)
    sarw %cl, 4660(%r12)
    sarw %cl, 0(%r11,%rbp,1)
    sarw %cl, 64(%r13,%r12,2)
    sarw %cl, 128(%r15,%rax,4)
    sarw %cl, %bx
    sarw %cl, 0(%rbx)
    sarw %cl, 8(%rbx)
    sarw %cl, -129(%rbp)
    sarw %cl, 0(%rsp)
    sarw %cl, -128(%rsp)
    sarw %cl, -2147483648(%rsp)
    sarw %cl, 0(%rdi,%rbp,8)
    sarw %cl, 127(%rsp,%rsi,1)
    sarw %cl, 2147483647(%rbp,%rdi,2)
    sarw %cl, gnu_back(%rip)
    sarw %cl, 4660
    sarl 0(%r14)
    sarl -1(%r9)
    sarl 128(%r10)
    sarl 0(%r12)
    sarl 64(%r12)
    sarl -129(%r12)
    sarl 0(%r12,%r15,4)
    sarl 8(%r8,%rsi,8)
    sarl -2147483648(%r9,%rcx,1)
    sarl %esi
    sarl 0(%rsi)
    sarl -128(%rsi)
    sarl 2147483647(%rdi)
    sarl 0(%rsp)
    sarl 127(%rsp)
    sarl 4660(%rsp)
    sarl 0(%rax,%rax,2)
    sarl -1(%rsi,%rcx,4)
    sarl 128(%rdi,%rdx,8)
    sarl gnu_fwd(%rip)
    sarl -129
    sarl $63, 0(%r15)
    sarl $7, 64(%r11)
    sarl $0, -2147483648(%r13)
    sarl $255, 0(%r12)
    sarl $63, 8(%r12)
    sarl $7, 2147483647(%r12)
    sarl $0, 0(%r14,%r9,1)
    sarl $255, -128(%r12,%rbp,2)
    sarl $63, 4660(%r13,%r12,4)
    sarl $7, %edi
    sarl $0, 0(%rdi)
    sarl $255, 127(%rcx)
    sarl $63, 128(%rdx)
    sarl $7, 0(%rsp)
    sarl $0, -1(%rsp)
    sarl $255, -129(%rsp)
    sarl $63, 0(%rcx,%rbx,8)
    sarl $7, 64(%rax,%rbp,1)
    sarl $0, -2147483648(%rcx,%rsi,2)
    sarl $255, gnu_back(%rip)
    sarl $63, 2147483647
    sarl %cl, 0(%r8)
    sarl %cl, 8(%r14)
    sarl %cl, 4660(%r15)
    sarl %cl, 0(%r12)
    sarl %cl, -128(%r12)
    sarl %cl, 128(%r12)
    sarl %cl, 0(%r15,%rax,4)
    sarl %cl, 127(%r15,%r15,8)
    sarl %cl, -129(%r8,%rsi,1)
    sarl %cl, %ebp
    sarl %cl, 0(%rcx)
    sarl %cl, -1(%rbx)
    sarl %cl, -2147483648(%rbp)
    sarl %cl, 0(%rsp)
    sarl %cl, 64(%rsp)
    sarl %cl, 2147483647(%rsp)
    sarl %cl, 0(%rdx,%rdi,2)
    sarl %cl, 8(%rdx,%rax,4)
    sarl %cl, 4660(%rbx,%rcx,8)
    sarl %cl, gnu_fwd(%rip)
    sarl %cl, 128
    sarq 0(%r9)
    sarq -128(%rbx)
    sarq -129(%r10)
    sarq 0(%rsp)
    sarq 127(%r12)
    sarq -2147483648(%rsp)
    sarq 0(%rsp,%rcx,1)
    sarq -1(%rbp,%r9,2)
    sarq 2147483647(%r12,%rbp,4)
    sarq gnu_back(%rip)
    sarq 4660
    sarq $7, 0(%rbx)
    sarq $0, 64(%rsi)
    sarq $255, 128(%r11)
    sarq $63, 0(%r12)
    sarq $7, 8(%rsp)
    sarq $0, -129(%r12)
    sarq $255, 0(%r14,%r12,8)
    sarq $63, -128(%rdi,%rax,1)
    sarq $7, -2147483648(%r15,%r15,2)
    sarq $0, gnu_fwd(%rip)
    sarq $255, 2147483647
    sarq %cl, 0(%r10)
    sarq %cl, 127(%rdi)
    sarq %cl, 4660(%r14)
    sarq %cl, 0(%rsp)
    sarq %cl, -1(%r12)
    sarq %cl, 128(%rsp)
    sarq %cl, 0(%rsi,%rsi,4)
    sarq %cl, 64(%rax,%rcx,8)
    sarq %cl, -129(%r9,%r9,1)
    sarq %cl, gnu_back(%rip)
    sarq %cl, -2147483648
    bsfw 0(%rsi), %r11w
    bsfw 8(%r15), %r14w
    bsfw 2147483647(%rcx), %r8w
    bsfw 0(%r12), %r12w
    bsfw -128(%rsp), %r13w
    bsfw 4660(%r12), %r15w
    bsfw 0(%r15,%rbp,2), %r9w
    bsfw 127(%rsp,%r12,4), %r10w
    bsfw 128(%r13,%rax,8), %r11w
    bsfw gnu_fwd(%rip), %r14w
    bsfw -129, %r8w
    bsfw %sp, %cx
    bsfw 0(%rdx), %dx
    bsfw -1(%rsi), %bx
    bsfw -2147483648(%rdi), %si
    bsfw 0(%rsp), %di
    bsfw 64(%rsp), %bp
    bsfw 2147483647(%rsp), %sp
    bsfw 0(%rbx,%rdx,1), %cx
    bsfw 8(%rsp,%rbx,2), %dx
    bsfw 4660(%rbp,%rbp,4), %bx
    bsfw gnu_back(%rip), %si
    bsfw 128, %di
    bsfl 0(%r11), %r12d
    bsfl -128(%r8), %r13d
    bsfl -129(%rbp), %r15d
    bsfl 0(%rsp), %r9d
    bsfl 127(%r12), %r10d
    bsfl -2147483648(%rsp), %r11d
    bsfl 0(%rax,%r15,8), %r14d
    bsfl -1(%rbp,%rsi,1), %r8d
    bsfl 2147483647(%r12,%rcx,2), %r12d
    bsfl gnu_fwd(%rip), %r13d
    bsfl 4660, %r15d
    bsfl %ebp, %esp
    bsfl 0(%rbx), %ecx
    bsfl 64(%rcx), %edx
    bsfl 128(%rdx), %ebx
    bsfl 0(%rsp), %esi
    bsfl 8(%rsp), %edi
    bsfl -129(%rsp), %ebp
    bsfl 0(%rsp,%rsi,4), %esp
    bsfl -128(%rsi,%rdi,8), %ecx
    bsfl -2147483648(%rdi,%rax,1), %edx
    bsfl gnu_back(%rip), %ebx
    bsfl 2147483647, %esi
    bsfq 0(%rdi), %r9
    bsfq 127(%r13), %r10
    bsfq 4660(%rdx), %r11
    bsfq 0(%r12), %r14
    bsfq -1(%rsp), %r8
    bsfq 128(%r12), %r12
    bsfq 0(%r8,%r9,2), %r13
    bsfq 64(%rdi,%rbp,4), %r15
    bsfq -129(%r15,%r12,8), %r9
    bsfq gnu_fwd(%rip), %r10
    bsfq -2147483648, %r11
    bsrw 0(%r14), %r14w
    bsrw 8(%r9), %r8w
    bsrw 2147483647(%rbx), %r12w
    bsrw 0(%rsp), %r13w
    bsrw -128(%r12), %r15w
    bsrw 4660(%rsp), %r9w
    bsrw 0(%rcx,%rax,1), %r10w
    bsrw 127(%rax,%r15,2), %r11w
    bsrw 128(%r9,%rsi,4), %r14w
    bsrw gnu_back(%rip), %r8w
    bsrw -129, %r12w
    bsrw %di, %bp
    bsrw 0(%rsi), %sp
    bsrw -1(%rbx), %cx
    bsrw -2147483648(%rbp), %dx
    bsrw 0(%rsp), %bx
    bsrw 64(%rsp), %si
g27:
    bsrw 2147483647(%rsp), %di
    bsrw 0(%rsi,%rcx,8), %bp
    bsrw 8(%rax,%rdx,1), %sp
    bsrw 4660(%rcx,%rbx,2), %cx
    bsrw gnu_fwd(%rip), %dx
    bsrw 128, %bx
    bsrl 0(%r15), %r13d
    bsrl -128(%r10), %r15d
    bsrl -129(%rsi), %r9d
    bsrl 0(%r12), %r10d
    bsrl 127(%rsp), %r11d
    bsrl -2147483648(%r12), %r14d
    bsrl 0(%r12,%rcx,4), %r8d
    bsrl -1(%rsp,%r9,8), %r12d
    bsrl 2147483647(%r13,%rbp,1), %r13d
    bsrl gnu_back(%rip), %r15d
    bsrl 4660, %r9d
    bsrl %esi, %edi
    bsrl 0(%rdi), %ebp
    bsrl 64(%rsi), %esp
    bsrl 128(%rdi), %ecx
    bsrl 0(%rsp), %edx
    bsrl 8(%rsp), %ebx
    bsrl -129(%rsp), %esi
    bsrl 0(%rdi,%rbp,2), %edi
    bsrl -128(%rdx,%rsi,4), %ebp
    bsrl -2147483648(%rbx,%rdi,8), %esp
    bsrl gnu_fwd(%rip), %ecx
    bsrl 2147483647, %edx
    bsrq 0(%rcx), %r10
    bsrq 127(%r11), %r11
    bsrq 4660(%rdi), %r14
    bsrq 0(%rsp), %r8
    bsrq -1(%r12), %r12
    bsrq 128(%rsp), %r13
    bsrq 0(%rdx,%r12,1), %r15
    bsrq 64(%rbp,%rax,2), %r9
    bsrq -129(%r12,%r15,4), %r10
    bsrq gnu_back(%rip), %r11
    bsrq -2147483648, %r14
    popcntw 0(%r8), %r8w
    popcntw 8(%r14), %r12w
    popcntw 2147483647(%r15), %r13w
    popcntw 0(%r12), %r15w
    popcntw -128(%rsp), %r9w
    popcntw 4660(%r12), %r10w
    popcntw 0(%r9,%rsi,8), %r11w
    popcntw 127(%rdi,%rcx,1), %r14w
    popcntw 128(%r15,%r9,2), %r8w
    popcntw gnu_fwd(%rip), %r12w
    popcntw -129, %r13w
    popcntw %bx, %si
    popcntw 0(%rcx), %di
    popcntw -1(%rcx), %bp
    popcntw -2147483648(%rdx), %sp
    popcntw 0(%rsp), %cx
    popcntw 64(%rsp), %dx
    popcntw 2147483647(%rsp), %bx
    popcntw 0(%rax,%rax,4), %si
    popcntw 8(%rsp,%rcx,8), %di
    popcntw 4660(%rbp,%rdx,1), %bp
    popcntw gnu_back(%rip), %sp
    popcntw 128, %cx
    popcntl 0(%rdx), %r15d
    popcntl -128(%rcx), %r9d
    popcntl -129(%r8), %r10d
    popcntl 0(%rsp), %r11d
    popcntl 127(%r12), %r14d
    popcntl -2147483648(%rsp), %r8d
    popcntl 0(%rsp,%rbp,2), %r12d
    popcntl -1(%rax,%r12,4), %r13d
    popcntl 2147483647(%r9,%rax,8), %r15d
    popcntl gnu_fwd(%rip), %r9d
    popcntl 4660, %r10d
    popcntl %edx, %ebx
    popcntl 0(%rdx), %esi
    popcntl 64(%rbx), %edi
    popcntl 128(%rbp), %ebp
    popcntl 0(%rsp), %esp
    popcntl 8(%rsp), %ecx
    popcntl -129(%rsp), %edx
    popcntl 0(%rcx,%rbx,1), %ebx
    popcntl -128(%rsi,%rbp,2), %esi
    popcntl -2147483648(%rdi,%rsi,4), %edi
    popcntl gnu_back(%rip), %ebp
    popcntl 2147483647, %esp
    popcntq 0(%r9), %r11
    popcntq 127(%rbp), %r14
    popcntq 4660(%r13), %r8
    popcntq 0(%r12), %r12
    popcntq -1(%rsp), %r13
    popcntq 128(%r12), %r15
    popcntq 0(%r14,%r15,8), %r9
    popcntq 64(%rsp,%rsi,1), %r10
    popcntq -129(%r13,%rcx,2), %r11
    popcntq gnu_fwd(%rip), %r14
    popcntq -2147483648, %r8
    lzcntw 0(%rbx), %r12w
    lzcntw 8(%rdx), %r13w
    lzcntw 2147483647(%r9), %r15w
    lzcntw 0(%rsp), %r9w
    lzcntw -128(%r12), %r10w
    lzcntw 4660(%rsp), %r11w
    lzcntw 0(%rsi,%r9,4), %r14w
    lzcntw 127(%rbp,%rbp,8), %r8w
    lzcntw 128(%r12,%r12,1), %r12w
    lzcntw gnu_back(%rip), %r13w
    lzcntw -129, %r15w
    lzcntw %cx, %dx
    lzcntw 0(%rbx), %bx
    lzcntw -1(%rsi), %si
    lzcntw -2147483648(%rdi), %di
    lzcntw 0(%rsp), %bp
    lzcntw 64(%rsp), %sp
    lzcntw 2147483647(%rsp), %cx
    lzcntw 0(%rdx,%rdi,2), %dx
    lzcntw 8(%rax,%rax,4), %bx
    lzcntw 4660(%rcx,%rcx,8), %si
    lzcntw gnu_fwd(%rip), %di
    lzcntw 128, %bp
    lzcntl 0(%r10), %r9d
    lzcntl -128(%rbx), %r10d
    lzcntl -129(%r10), %r11d
    lzcntl 0(%r12), %r14d
    lzcntl 127(%rsp), %r8d
    lzcntl -2147483648(%r12), %r12d
    lzcntl 0(%r15,%rax,1), %r13d
    lzcntl -1(%rdi,%r15,2), %r15d
    lzcntl 2147483647(%r15,%rsi,4), %r9d
    lzcntl gnu_back(%rip), %r10d
    lzcntl 4660, %r11d
    lzcntl %esp, %ecx
    lzcntl 0(%rsi), %edx
    lzcntl 64(%rcx), %ebx
    lzcntl 128(%rdx), %esi
    lzcntl 0(%rsp), %edi
    lzcntl 8(%rsp), %ebp
    lzcntl -129(%rsp), %esp
    lzcntl 0(%rbx,%rdx,8), %ecx
    lzcntl -128(%rdx,%rbx,1), %edx
    lzcntl -2147483648(%rbx,%rbp,2), %ebx
    lzcntl gnu_fwd(%rip), %esi
    lzcntl 2147483647, %edi
    lzcntq 0(%rsi), %r14
    lzcntq 127(%rsi), %r8
    lzcntq 4660(%r11), %r12
    lzcntq 0(%rsp), %r13
    lzcntq -1(%r12), %r15
    lzcntq 128(%rsp), %r9
    lzcntq 0(%rax,%rcx,4), %r10
    lzcntq 64(%rax,%r9,8), %r11
    lzcntq -129(%r9,%rbp,1), %r14
    lzcntq gnu_back(%rip), %r8
    lzcntq -2147483648, %r12
    tzcntw 0(%r11), %r13w
    tzcntw 8(%rdi), %r15w
    tzcntw 2147483647(%r14), %r9w
    tzcntw 0(%r12), %r10w
    tzcntw -128(%rsp), %r11w
    tzcntw 4660(%r12), %r14w
    tzcntw 0(%r8,%r12,2), %r8w
    tzcntw 127(%rsp,%rax,4), %r12w
    tzcntw 128(%r13,%r15,8), %r13w
    tzcntw gnu_fwd(%rip), %r15w
    tzcntw -129, %r9w
    tzcntw %bp, %sp
    tzcntw 0(%rdi), %cx
    tzcntw -1(%rbx), %dx
    tzcntw -2147483648(%rbp), %bx
    tzcntw 0(%rsp), %si
    tzcntw 64(%rsp), %di
    tzcntw 2147483647(%rsp), %bp
    tzcntw 0(%rsp,%rsi,1), %sp
    tzcntw 8(%rsp,%rdi,2), %cx
    tzcntw 4660(%rbp,%rax,4), %dx
    tzcntw gnu_back(%rip), %bx
    tzcntw 128, %si
    tzcntl 0(%rdi), %r10d
    tzcntl -128(%r15), %r11d
    tzcntl -129(%rcx), %r14d
    tzcntl 0(%rsp), %r8d
    tzcntl 127(%r12), %r12d
    tzcntl -2147483648(%rsp), %r13d
    tzcntl 0(%rcx,%rsi,8), %r15d
    tzcntl -1(%rbp,%rcx,1), %r9d
    tzcntl 2147483647(%r12,%r9,2), %r10d
    tzcntl gnu_fwd(%rip), %r11d
    tzcntl 4660, %r14d
    tzcntl %edi, %ebp
    tzcntl 0(%rcx), %esp
    tzcntl 64(%rsi), %ecx
    tzcntl 128(%rdi), %edx
    tzcntl 0(%rsp), %ebx
    tzcntl 8(%rsp), %esi
    tzcntl -129(%rsp), %edi
    tzcntl 0(%rsi,%rcx,4), %ebp
    tzcntl -128(%rsi,%rdx,8), %esp
    tzcntl -2147483648(%rdi,%rbx,1), %ecx
    tzcntl gnu_back(%rip), %edx
    tzcntl 2147483647, %ebx
g28:
    tzcntq 0(%r14), %r8
    tzcntq 127(%r8), %r12
    tzcntq 4660(%rbp), %r13
    tzcntq 0(%r12), %r15
    tzcntq -1(%rsp), %r9
    tzcntq 128(%r12), %r10
    tzcntq 0(%r12,%rbp,2), %r11
    tzcntq 64(%rdi,%r12,4), %r14
    tzcntq -129(%r15,%rax,8), %r8
    tzcntq gnu_fwd(%rip), %r12
    tzcntq -2147483648, %r13
    btw %r15w, 0(%r15)
    btw %r9w, 8(%r13)
    btw %r10w, 2147483647(%rdx)
    btw %r11w, 0(%rsp)
    btw %r14w, -128(%r12)
    btw %r8w, 4660(%rsp)
    btw %r12w, 0(%rdx,%r15,1)
    btw %r13w, 127(%rax,%rsi,2)
    btw %r15w, 128(%r9,%rcx,4)
    btw %r9w, gnu_back(%rip)
    btw %r10w, -129
    btw %si, %di
    btw %bp, 0(%rdx)
    btw %sp, -1(%rcx)
    btw %cx, -2147483648(%rdx)
    btw %dx, 0(%rsp)
    btw %bx, 64(%rsp)
    btw %si, 2147483647(%rsp)
    btw %di, 0(%rdi,%rbp,8)
    btw %bp, 8(%rax,%rsi,1)
    btw %sp, 4660(%rcx,%rdi,2)
    btw %cx, gnu_fwd(%rip)
    btw %dx, 128
    btw $63, 0(%r9)
    btw $7, -128(%r8)
    btw $0, -129(%r9)
    btw $255, 0(%r12)
    btw $63, 127(%r12)
    btw $7, -2147483648(%r12)
    btw $0, 0(%r8,%r9,4)
    btw $255, -1(%r9,%rbp,8)
    btw $63, 2147483647(%r12,%r12,1)
    btw $7, %bx
    btw $0, 0(%rbx)
    btw $255, 64(%rbx)
    btw $63, 4660(%rbp)
    btw $7, 0(%rsp)
    btw $0, 8(%rsp)
    btw $255, 128(%rsp)
    btw $63, 0(%rax,%rax,2)
    btw $7, -128(%rdx,%rcx,4)
    btw $0, -129(%rbx,%rdx,8)
    btw $255, gnu_back(%rip)
    btw $63, -2147483648
    btl %r11d, 0(%rcx)
    btl %r14d, 127(%r9)
    btl %r8d, 2147483647(%rbx)
    btl %r12d, 0(%r12)
    btl %r13d, -1(%rsp)
    btl %r15d, 4660(%r12)
    btl %r9d, 0(%r9,%rax,1)
    btl %r10d, 64(%rsp,%r15,2)
    btl %r11d, 128(%r13,%rsi,4)
    btl %r14d, gnu_fwd(%rip)
    btl %r8d, -129
    btl %esi, %edi
    btl %ebp, 0(%rsi)
    btl %esp, 8(%rsi)
    btl %ecx, -2147483648(%rdi)
    btl %edx, 0(%rsp)
    btl %ebx, -128(%rsp)
    btl %esi, 2147483647(%rsp)
    btl %edi, 0(%rcx,%rbx,8)
    btl %ebp, 127(%rsp,%rbp,1)
    btl %esp, 4660(%rbp,%rsi,2)
    btl %ecx, gnu_back(%rip)
    btl %edx, 128
    btl $7, 0(%r10)
    btl $0, -1(%r10)
    btl $255, -129(%r11)
    btl $63, 0(%r12)
    btl $7, 64(%r12)
    btl $0, -2147483648(%r12)
    btl $255, 0(%r9,%rcx,4)
    btl $63, 8(%r13,%r9,8)
    btl $7, 2147483647(%r15,%rbp,1)
    btl $0, %ebx
    btl $255, 0(%rdi)
    btl $63, -128(%rcx)
    btl $7, 4660(%rdx)
    btl $0, 0(%rsp)
    btl $255, 127(%rsp)
    btl $63, 128(%rsp)
    btl $7, 0(%rdx,%rdi,2)
    btl $0, -1(%rsi,%rax,4)
    btl $255, -129(%rdi,%rcx,8)
    btl $63, gnu_fwd(%rip)
    btl $7, -2147483648
    btq %r12, 0(%r8)
    btq %r13, 64(%r10)
    btq %r15, 2147483647(%rsi)
    btq %r9, 0(%rsp)
    btq %r10, 8(%r12)
    btq %r11, 4660(%rsp)
    btq %r14, 0(%rsp,%r12,1)
    btq %r8, -128(%rbp,%rax,2)
    btq %r12, 128(%r12,%r15,4)
    btq %r13, gnu_back(%rip)
    btq %r15, -129
    btq $0, 0(%rdx)
    btq $255, 127(%r11)
    btq $63, -2147483648(%rdi)
    btq $7, 0(%r12)
    btq $0, -1(%rsp)
    btq $255, 2147483647(%r12)
    btq $63, 0(%r14,%rsi,8)
    btq $7, 64(%rdi,%rcx,1)
    btq $0, 4660(%r15,%r9,2)
    btq $255, gnu_fwd(%rip)
    btq $63, 128
    btsw %r9w, 0(%r9)
    btsw %r10w, 8(%r14)
    btsw %r11w, -129(%r15)
    btsw %r14w, 0(%rsp)
    btsw %r8w, -128(%r12)
    btsw %r12w, -2147483648(%rsp)
    btsw %r13w, 0(%rsi,%rbp,4)
    btsw %r15w, 127(%rax,%r12,8)
    btsw %r9w, 2147483647(%r9,%rax,1)
    btsw %r10w, gnu_back(%rip)
    btsw %r11w, 4660
    btsw %si, %di
    btsw %bp, 0(%rcx)
    btsw %sp, -1(%rbx)
    btsw %cx, 128(%rbp)
    btsw %dx, 0(%rsp)
    btsw %bx, 64(%rsp)
    btsw %si, -129(%rsp)
    btsw %di, 0(%rbx,%rdx,2)
    btsw %bp, 8(%rax,%rbx,4)
    btsw %sp, -2147483648(%rcx,%rbp,8)
    btsw %cx, gnu_fwd(%rip)
    btsw %dx, 2147483647
    btsw $7, 0(%r11)
    btsw $0, -128(%r13)
    btsw $255, 4660(%r14)
    btsw $63, 0(%r12)
    btsw $7, 127(%r12)
    btsw $0, 128(%r12)
    btsw $255, 0(%r10,%r15,1)
    btsw $63, -1(%r8,%rsi,2)
    btsw $7, -129(%r9,%rcx,4)
    btsw $0, %bx
    btsw $255, 0(%rdx)
    btsw $63, 64(%rsi)
    btsw $7, -2147483648(%rdi)
    btsw $0, 0(%rsp)
    btsw $255, 8(%rsp)
    btsw $63, 2147483647(%rsp)
    btsw $7, 0(%rsp,%rsi,8)
    btsw $0, -128(%rdx,%rdi,1)
    btsw $255, 4660(%rbx,%rax,2)
    btsw $63, gnu_back(%rip)
    btsw $7, 128
    btsl %r14d, 0(%rbx)
    btsl %r8d, 127(%rcx)
    btsl %r12d, -129(%r8)
    btsl %r13d, 0(%r12)
    btsl %r15d, -1(%rsp)
    btsl %r9d, -2147483648(%r12)
    btsl %r10d, 0(%r15,%r9,4)
    btsl %r11d, 64(%rsp,%rbp,8)
    btsl %r14d, 2147483647(%r13,%r12,1)
    btsl %r8d, gnu_fwd(%rip)
    btsl %r12d, 4660
    btsl %esi, %edi
    btsl %ebp, 0(%rbx)
    btsl %esp, 8(%rcx)
    btsl %ecx, 128(%rdx)
    btsl %edx, 0(%rsp)
    btsl %ebx, -128(%rsp)
    btsl %esi, -129(%rsp)
    btsl %edi, 0(%rsi,%rcx,2)
    btsl %ebp, 127(%rsp,%rdx,4)
    btsl %esp, -2147483648(%rbp,%rbx,8)
    btsl %ecx, gnu_back(%rip)
    btsl %edx, 2147483647
    btsl $0, 0(%r14)
    btsl $255, -1(%r15)
    btsl $63, 4660(%r8)
    btsl $7, 0(%r12)
    btsl $0, 64(%r12)
    btsl $255, 128(%r12)
    btsl $63, 0(%r11,%rax,1)
    btsl $7, 8(%r12,%r15,2)
    btsl $0, -129(%r13,%rsi,4)
    btsl $255, %ebx
    btsl $63, 0(%rsi)
    btsl $7, -128(%rbx)
g29:
    btsl $0, -2147483648(%rbp)
    btsl $255, 0(%rsp)
    btsl $63, 127(%rsp)
    btsl $7, 2147483647(%rsp)
    btsl $0, 0(%rdi,%rbp,8)
    btsl $255, -1(%rsi,%rsi,1)
    btsl $63, 4660(%rdi,%rdi,2)
    btsl $7, gnu_fwd(%rip)
    btsl $0, 128
    btsq %r13, 0(%r10)
    btsq %r15, 64(%rbp)
    btsq %r9, -129(%r13)
    btsq %r10, 0(%rsp)
    btsq %r11, 8(%r12)
    btsq %r14, -2147483648(%rsp)
    btsq %r8, 0(%rax,%rcx,4)
    btsq %r12, -128(%rbp,%r9,8)
    btsq %r13, 2147483647(%r12,%rbp,1)
    btsq %r15, gnu_back(%rip)
    btsq %r9, 4660
    btsq $255, 0(%rsi)
    btsq $63, 127(%rdx)
    btsq $7, 128(%r9)
    btsq $0, 0(%r12)
    btsq $255, -1(%rsp)
    btsq $63, -129(%r12)
    btsq $7, 0(%r8,%r12,2)
    btsq $0, 64(%rdi,%rax,4)
    btsq $255, -2147483648(%r15,%r15,8)
    btsq $63, gnu_fwd(%rip)
    btsq $7, 2147483647
    btrw %r10w, 0(%r11)
    btrw %r11w, 8(%rbx)
    btrw %r14w, 4660(%r10)
    btrw %r8w, 0(%rsp)
    btrw %r12w, -128(%r12)
    btrw %r13w, 128(%rsp)
    btrw %r15w, 0(%rcx,%rsi,1)
    btrw %r9w, 127(%rax,%rcx,2)
    btrw %r10w, -129(%r9,%r9,4)
    btrw %r11w, gnu_back(%rip)
    btrw %r14w, -2147483648
    btrw %si, %di
    btrw %bp, 0(%rdi)
    btrw %sp, -1(%rsi)
    btrw %cx, 2147483647(%rdi)
    btrw %dx, 0(%rsp)
    btrw %bx, 64(%rsp)
    btrw %si, 4660(%rsp)
    btrw %di, 0(%rax,%rax,8)
    btrw %bp, 8(%rax,%rcx,1)
    btrw %sp, 128(%rcx,%rdx,2)
    btrw %cx, gnu_fwd(%rip)
    btrw %dx, -129
    btrw $0, 0(%r15)
    btrw $255, -128(%r9)
    btrw $63, -2147483648(%r10)
    btrw $7, 0(%r12)
    btrw $0, 127(%r12)
    btrw $255, 2147483647(%r12)
    btrw $63, 0(%r12,%rbp,4)
    btrw $7, -1(%r15,%r12,8)
    btrw $0, 4660(%r8,%rax,1)
    btrw $255, %bx
    btrw $63, 0(%rcx)
    btrw $7, 64(%rcx)
    btrw $0, 128(%rdx)
    btrw $255, 0(%rsp)
    btrw $63, 8(%rsp)
    btrw $7, -129(%rsp)
    btrw $0, 0(%rcx,%rbx,2)
    btrw $255, -128(%rdx,%rbp,4)
    btrw $63, -2147483648(%rbx,%rsi,8)
    btrw $7, gnu_back(%rip)
    btrw $0, 2147483647
    btrl %r8d, 0(%rdi)
    btrl %r12d, 127(%rsi)
    btrl %r13d, 4660(%r11)
    btrl %r15d, 0(%r12)
    btrl %r9d, -1(%rsp)
    btrl %r10d, 128(%r12)
    btrl %r11d, 0(%r12,%r15,1)
    btrl %r14d, 64(%rsp,%rsi,2)
    btrl %r8d, -129(%r13,%rcx,4)
    btrl %r12d, gnu_fwd(%rip)
    btrl %r13d, -2147483648
    btrl %esi, %edi
    btrl %ebp, 0(%rdx)
    btrl %esp, 8(%rbx)
    btrl %ecx, 2147483647(%rbp)
    btrl %edx, 0(%rsp)
    btrl %ebx, -128(%rsp)
    btrl %esi, 4660(%rsp)
    btrl %edi, 0(%rdx,%rdi,8)
    btrl %ebp, 127(%rsp,%rax,1)
    btrl %esp, 128(%rbp,%rcx,2)
    btrl %ecx, gnu_back(%rip)
    btrl %edx, -129
    btrl $255, 0(%r8)
    btrl $63, -1(%r11)
    btrl $7, -2147483648(%r13)
    btrl $0, 0(%r12)
    btrl $255, 64(%r12)
    btrl $63, 2147483647(%r12)
    btrl $7, 0(%r14,%r9,4)
    btrl $0, 8(%r9,%rbp,8)
    btrl $255, 4660(%r12,%r12,1)
    btrl $63, %ebx
    btrl $7, 0(%rbx)
    btrl $0, -128(%rsi)
    btrl $255, 128(%rdi)
    btrl $63, 0(%rsp)
    btrl $7, 127(%rsp)
    btrl $0, -129(%rsp)
    btrl $255, 0(%rbx,%rdx,2)
    btrl $63, -1(%rsi,%rbx,4)
    btrl $7, -2147483648(%rdi,%rbp,8)
    btrl $0, gnu_fwd(%rip)
    btrl $255, 2147483647
    btrq %r15, 0(%r14)
    btrq %r9, 64(%rdi)
    btrq %r10, 4660(%r14)
    btrq %r11, 0(%rsp)
    btrq %r14, 8(%r12)
    btrq %r8, 128(%rsp)
    btrq %r12, 0(%rdx,%rax,1)
    btrq %r13, -128(%rbp,%r15,2)
    btrq %r15, -129(%r12,%rsi,4)
    btrq %r9, gnu_back(%rip)
    btrq %r10, -2147483648
    btrq $63, 0(%r15)
    btrq $7, 127(%r15)
    btrq $0, 2147483647(%rcx)
    btrq $255, 0(%r12)
    btrq $63, -1(%rsp)
    btrq $7, 4660(%r12)
    btrq $0, 0(%r9,%rcx,8)
    btrq $255, 64(%rdi,%r9,1)
    btrq $63, 128(%r15,%rbp,2)
    btrq $7, gnu_fwd(%rip)
    btrq $0, -129
    btcw %r11w, 0(%rcx)
    btcw %r14w, 8(%r8)
    btcw %r8w, -2147483648(%rbp)
    btcw %r12w, 0(%rsp)
    btcw %r13w, -128(%r12)
    btcw %r15w, 2147483647(%rsp)
    btcw %r9w, 0(%rsp,%r12,4)
    btcw %r10w, 127(%rax,%rax,8)
    btcw %r11w, 4660(%r9,%r15,1)
    btcw %r14w, gnu_back(%rip)
    btcw %r8w, 128
    btcw %si, %di
    btcw %bp, 0(%rsi)
    btcw %sp, -1(%rcx)
    btcw %cx, -129(%rdx)
    btcw %dx, 0(%rsp)
    btcw %bx, 64(%rsp)
    btcw %si, -2147483648(%rsp)
    btcw %di, 0(%rsp,%rsi,2)
    btcw %bp, 8(%rax,%rdi,4)
    btcw %sp, 2147483647(%rcx,%rax,8)
    btcw %cx, gnu_fwd(%rip)
    btcw %dx, 4660
    btcw $255, 0(%r9)
    btcw $63, -128(%r14)
    btcw $7, 128(%r15)
    btcw $0, 0(%r12)
    btcw $255, 127(%r12)
    btcw $63, -129(%r12)
    btcw $7, 0(%r15,%rsi,1)
    btcw $0, -1(%r13,%rcx,2)
    btcw $255, -2147483648(%r15,%r9,4)
    btcw $63, %bx
    btcw $7, 0(%rdi)
    btcw $0, 64(%rbx)
    btcw $255, 2147483647(%rbp)
    btcw $63, 0(%rsp)
    btcw $7, 8(%rsp)
    btcw $0, 4660(%rsp)
    btcw $255, 0(%rsi,%rcx,8)
    btcw $63, -128(%rdx,%rdx,1)
    btcw $7, 128(%rbx,%rbx,2)
    btcw $0, gnu_back(%rip)
    btcw $255, -129
    btcl %r12d, 0(%r8)
    btcl %r13d, 127(%r13)
    btcl %r15d, -2147483648(%rdx)
    btcl %r9d, 0(%r12)
    btcl %r10d, -1(%rsp)
    btcl %r11d, 2147483647(%r12)
    btcl %r14d, 0(%r14,%rbp,4)
    btcl %r8d, 64(%rsp,%r12,8)
    btcl %r12d, 4660(%r13,%rax,1)
    btcl %r13d, gnu_fwd(%rip)
    btcl %r15d, 128
    btcl %esi, %edi
    btcl %ebp, 0(%rcx)
    btcl %esp, 8(%rsi)
    btcl %ecx, -129(%rdi)
g30:
    btcl %edx, 0(%rsp)
    btcl %ebx, -128(%rsp)
    btcl %esi, -2147483648(%rsp)
    btcl %edi, 0(%rdi,%rbp,2)
    btcl %ebp, 127(%rsp,%rsi,4)
    btcl %esp, 2147483647(%rbp,%rdi,8)
    btcl %ecx, gnu_back(%rip)
    btcl %edx, 4660
    btcl $63, 0(%r10)
    btcl $7, -1(%r8)
    btcl $0, 128(%r9)
    btcl $255, 0(%r12)
    btcl $63, 64(%r12)
    btcl $7, -129(%r12)
    btcl $0, 0(%r8,%r15,1)
    btcl $255, 8(%r8,%rsi,2)
    btcl $63, -2147483648(%r9,%rcx,4)
    btcl $7, %ebx
    btcl $0, 0(%rdx)
    btcl $255, -128(%rcx)
    btcl $63, 2147483647(%rdx)
    btcl $7, 0(%rsp)
    btcl $0, 127(%rsp)
    btcl $255, 4660(%rsp)
    btcl $63, 0(%rax,%rax,8)
    btcl $7, -1(%rsi,%rcx,1)
    btcl $0, 128(%rdi,%rdx,2)
    btcl $255, gnu_fwd(%rip)
    btcl $63, -129
    btcq %r9, 0(%rdx)
    btcq %r10, 64(%r9)
    btcq %r11, -2147483648(%rbx)
    btcq %r14, 0(%rsp)
    btcq %r8, 8(%r12)
    btcq %r12, 2147483647(%rsp)
    btcq %r13, 0(%rsi,%r9,4)
    btcq %r15, -128(%rbp,%rbp,8)
    btcq %r9, 4660(%r12,%r12,1)
    btcq %r10, gnu_back(%rip)
    btcq %r11, 128
    btcq $7, 0(%r9)
    btcq $0, 127(%r10)
    btcq $255, -129(%rsi)
    btcq $63, 0(%r12)
    btcq $7, -1(%rsp)
    btcq $0, -2147483648(%r12)
    btcq $255, 0(%r15,%rax,2)
    btcq $63, 64(%rdi,%r15,4)
    btcq $7, 2147483647(%r15,%rsi,8)
    btcq $0, gnu_fwd(%rip)
    btcq $255, 4660
    bswapl %esi
    seto 0(%r11)
    seto 8(%r10)
    seto 128(%r11)
    seto 0(%r12)
    seto -128(%r12)
    seto -129(%r12)
    seto 0(%r9,%rcx,1)
    seto 127(%r12,%r9,2)
    seto -2147483648(%r13,%rbp,4)
    seto %cl
    seto 0(%rbx)
    seto -1(%rbx)
    seto 2147483647(%rbp)
    seto 0(%rsp)
    seto 64(%rsp)
    seto 4660(%rsp)
    seto 0(%rcx,%rbx,8)
    seto 8(%rax,%rbp,1)
    seto 128(%rcx,%rsi,2)
    seto gnu_back(%rip)
    seto -129
    cmovow 0(%rbx), %r14w
    cmovow -128(%r11), %r8w
    cmovow -2147483648(%rdi), %r12w
    cmovow 0(%rsp), %r13w
    cmovow 127(%r12), %r15w
    cmovow 2147483647(%rsp), %r9w
    cmovow 0(%rax,%r12,4), %r10w
    cmovow -1(%rax,%rax,8), %r11w
    cmovow 4660(%r9,%r15,1), %r14w
    cmovow gnu_fwd(%rip), %r8w
    cmovow 128, %r12w
    cmovow %di, %bp
    cmovow 0(%rsi), %sp
    cmovow 64(%rsi), %cx
    cmovow -129(%rdi), %dx
    cmovow 0(%rsp), %bx
    cmovow 8(%rsp), %si
    cmovow -2147483648(%rsp), %di
    cmovow 0(%rdx,%rdi,2), %bp
    cmovow -128(%rdx,%rax,4), %sp
    cmovow 2147483647(%rbx,%rcx,8), %cx
    cmovow gnu_back(%rip), %dx
    cmovow 4660, %bx
    cmovol 0(%r10), %r13d
    cmovol 127(%r14), %r15d
    cmovol 128(%r15), %r9d
    cmovol 0(%r12), %r10d
    cmovol -1(%rsp), %r11d
    cmovol -129(%r12), %r14d
    cmovol 0(%r8,%rsi,1), %r8d
    cmovol 64(%rsp,%rcx,2), %r12d
    cmovol -2147483648(%r13,%r9,4), %r13d
    cmovol gnu_fwd(%rip), %r15d
    cmovol 2147483647, %r9d
    cmovol %esi, %edi
    cmovol 0(%rdi), %ebp
    cmovol 8(%rcx), %esp
    cmovol 4660(%rdx), %ecx
    cmovol 0(%rsp), %edx
    cmovol -128(%rsp), %ebx
    cmovol 128(%rsp), %esi
    cmovol 0(%rbx,%rdx,8), %edi
    cmovol 127(%rsp,%rbx,1), %ebp
    cmovol -129(%rbp,%rbp,2), %esp
    cmovol gnu_back(%rip), %ecx
    cmovol -2147483648, %edx
    cmovoq 0(%rsi), %r10
    cmovoq -1(%rcx), %r11
    cmovoq 2147483647(%r8), %r14
    cmovoq 0(%rsp), %r8
    cmovoq 64(%r12), %r12
    cmovoq 4660(%rsp), %r13
    cmovoq 0(%rcx,%rbp,4), %r15
    cmovoq 8(%rbp,%r12,8), %r9
    cmovoq 128(%r12,%rax,1), %r10
    cmovoq gnu_fwd(%rip), %r11
    cmovoq -129, %r14
    setno 0(%r14)
    setno -128(%r13)
    setno -2147483648(%r14)
    setno 0(%r12)
    setno 127(%r12)
    setno 2147483647(%r12)
    setno 0(%r10,%r15,2)
    setno -1(%r15,%rsi,4)
    setno 4660(%r8,%rcx,8)
    setno %dl
    setno 0(%rcx)
    setno 64(%rbx)
    setno 128(%rbp)
    setno 0(%rsp)
    setno 8(%rsp)
    setno -129(%rsp)
    setno 0(%rsp,%rsi,1)
    setno -128(%rsi,%rdi,2)
    setno -2147483648(%rdi,%rax,4)
    setno gnu_back(%rip)
    setno 2147483647
    cmovnow 0(%r11), %r8w
    cmovnow 127(%rbp), %r12w
    cmovnow 4660(%r13), %r13w
    cmovnow 0(%r12), %r15w
    cmovnow -1(%rsp), %r9w
    cmovnow 128(%r12), %r10w
    cmovnow 0(%r12,%r9,8), %r11w
    cmovnow 64(%rdi,%rbp,1), %r14w
    cmovnow -129(%r15,%r12,2), %r8w
    cmovnow gnu_fwd(%rip), %r12w
    cmovnow -2147483648, %r13w
    cmovnow %bx, %si
    cmovnow 0(%rdx), %di
    cmovnow 8(%rsi), %bp
    cmovnow 2147483647(%rdi), %sp
    cmovnow 0(%rsp), %cx
    cmovnow -128(%rsp), %dx
    cmovnow 4660(%rsp), %bx
    cmovnow 0(%rsi,%rcx,4), %si
    cmovnow 127(%rax,%rdx,8), %di
    cmovnow 128(%rcx,%rbx,1), %bp
    cmovnow gnu_back(%rip), %sp
    cmovnow -129, %cx
    cmovnol 0(%rdi), %r15d
    cmovnol -1(%rdx), %r9d
    cmovnol -2147483648(%r9), %r10d
    cmovnol 0(%rsp), %r11d
    cmovnol 64(%r12), %r14d
    cmovnol 2147483647(%rsp), %r8d
    cmovnol 0(%rdx,%rax,2), %r12d
    cmovnol 8(%rax,%r15,4), %r13d
    cmovnol 4660(%r9,%rsi,8), %r15d
    cmovnol gnu_fwd(%rip), %r9d
    cmovnol 128, %r10d
    cmovnol %edx, %ebx
    cmovnol 0(%rbx), %esi
    cmovnol -128(%rcx), %edi
    cmovnol -129(%rdx), %ebp
    cmovnol 0(%rsp), %esp
    cmovnol 127(%rsp), %ecx
    cmovnol -2147483648(%rsp), %edx
    cmovnol 0(%rdi,%rbp,1), %ebx
    cmovnol -1(%rdx,%rsi,2), %esi
    cmovnol 2147483647(%rbx,%rdi,4), %edi
    cmovnol gnu_back(%rip), %ebp
    cmovnol 4660, %esp
    cmovnoq 0(%r14), %r11
    cmovnoq 64(%rbx), %r14
    cmovnoq 128(%r10), %r8
g31:
    cmovnoq 0(%r12), %r12
    cmovnoq 8(%rsp), %r13
    cmovnoq -129(%r12), %r15
    cmovnoq 0(%r9,%rcx,8), %r9
    cmovnoq -128(%rsp,%r9,1), %r10
    cmovnoq -2147483648(%r13,%rbp,2), %r11
    cmovnoq gnu_fwd(%rip), %r14
    cmovnoq 2147483647, %r8
    setb 0(%r15)
    setb 127(%r15)
    setb 4660(%r8)
    setb 0(%r12)
    setb -1(%r12)
    setb 128(%r12)
    setb 0(%r11,%r12,4)
    setb 64(%r9,%rax,8)
    setb -129(%r12,%r15,1)
    setb %bl
    setb 0(%rsi)
    setb 8(%rbx)
    setb -2147483648(%rbp)
    setb 0(%rsp)
    setb -128(%rsp)
    setb 2147483647(%rsp)
    setb 0(%rax,%rax,2)
    setb 127(%rsp,%rcx,4)
    setb 4660(%rbp,%rdx,8)
    setb gnu_back(%rip)
    setb 128
    cmovbw 0(%r15), %r12w
    cmovbw -1(%rsi), %r13w
    cmovbw -129(%r11), %r15w
    cmovbw 0(%rsp), %r9w
    cmovbw 64(%r12), %r10w
    cmovbw -2147483648(%rsp), %r11w
    cmovbw 0(%rsp,%rsi,1), %r14w
    cmovbw 8(%rbp,%rcx,2), %r8w
    cmovbw 2147483647(%r12,%r9,4), %r12w
    cmovbw gnu_fwd(%rip), %r13w
    cmovbw 4660, %r15w
    cmovbw %cx, %dx
    cmovbw 0(%rdi), %bx
    cmovbw -128(%rsi), %si
    cmovbw 128(%rdi), %di
    cmovbw 0(%rsp), %bp
    cmovbw 127(%rsp), %sp
    cmovbw -129(%rsp), %cx
    cmovbw 0(%rcx,%rbx,8), %dx
    cmovbw -1(%rsi,%rbp,1), %bx
    cmovbw -2147483648(%rdi,%rsi,2), %si
    cmovbw gnu_back(%rip), %di
    cmovbw 2147483647, %bp
    cmovbl 0(%rcx), %r9d
    cmovbl 64(%rdi), %r10d
    cmovbl 4660(%r14), %r11d
    cmovbl 0(%r12), %r14d
    cmovbl 8(%rsp), %r8d
    cmovbl 128(%r12), %r12d
    cmovbl 0(%r14,%rbp,4), %r13d
    cmovbl -128(%rdi,%r12,8), %r15d
    cmovbl -129(%r15,%rax,1), %r9d
    cmovbl gnu_fwd(%rip), %r10d
    cmovbl -2147483648, %r11d
    cmovbl %esp, %ecx
    cmovbl 0(%rcx), %edx
    cmovbl 127(%rcx), %ebx
    cmovbl 2147483647(%rdx), %esi
    cmovbl 0(%rsp), %edi
    cmovbl -1(%rsp), %ebp
    cmovbl 4660(%rsp), %esp
    cmovbl 0(%rdx,%rdi,2), %ecx
    cmovbl 64(%rax,%rax,4), %edx
    cmovbl 128(%rcx,%rcx,8), %ebx
    cmovbl gnu_back(%rip), %esi
    cmovbl -129, %edi
    cmovbq 0(%r8), %r14
    cmovbq 8(%r15), %r8
    cmovbq -2147483648(%rcx), %r12
    cmovbq 0(%rsp), %r13
    cmovbq -128(%r12), %r15
    cmovbq 2147483647(%rsp), %r9
    cmovbq 0(%rsi,%r15,1), %r10
    cmovbq 127(%rax,%rsi,2), %r11
    cmovbq 4660(%r9,%rcx,4), %r14
    cmovbq gnu_fwd(%rip), %r8
    cmovbq 128, %r12
    setae 0(%r8)
    setae -1(%r9)
    setae -129(%r10)
    setae 0(%r12)
    setae 64(%r12)
    setae -2147483648(%r12)
    setae 0(%r12,%r9,8)
    setae 8(%r13,%rbp,1)
    setae 2147483647(%r15,%r12,2)
    setae %dh
    setae 0(%rdx)
    setae -128(%rbx)
    setae 4660(%rbp)
    setae 0(%rsp)
    setae 127(%rsp)
    setae 128(%rsp)
    setae 0(%rbx,%rdx,4)
    setae -1(%rdx,%rbx,8)
    setae -129(%rbx,%rbp,1)
    setae gnu_back(%rip)
    setae -2147483648
    cmovaew 0(%rdx), %r13w
    cmovaew 64(%r8), %r15w
    cmovaew 2147483647(%rbp), %r9w
    cmovaew 0(%r12), %r10w
    cmovaew 8(%rsp), %r11w
    cmovaew 4660(%r12), %r14w
    cmovaew 0(%r15,%rax,2), %r8w
    cmovaew -128(%rsp,%r15,4), %r12w
    cmovaew 128(%r13,%rsi,8), %r13w
    cmovaew gnu_fwd(%rip), %r15w
    cmovaew -129, %r9w
    cmovaew %bp, %sp
    cmovaew 0(%rbx), %cx
    cmovaew 127(%rsi), %dx
    cmovaew -2147483648(%rdi), %bx
    cmovaew 0(%rsp), %si
    cmovaew -1(%rsp), %di
    cmovaew 2147483647(%rsp), %bp
    cmovaew 0(%rsp,%rsi,1), %sp
    cmovaew 64(%rsp,%rdi,2), %cx
    cmovaew 4660(%rbp,%rax,4), %dx
    cmovaew gnu_back(%rip), %bx
    cmovaew 128, %si
    cmovael 0(%r9), %r10d
    cmovael 8(%r13), %r11d
    cmovael -129(%rdx), %r14d
    cmovael 0(%rsp), %r8d
    cmovael -128(%r12), %r12d
    cmovael -2147483648(%rsp), %r13d
    cmovael 0(%rax,%rcx,8), %r15d
    cmovael 127(%rbp,%r9,1), %r9d
    cmovael 2147483647(%r12,%rbp,2), %r10d
    cmovael gnu_fwd(%rip), %r11d
    cmovael 4660, %r14d
    cmovael %edi, %ebp
    cmovael 0(%rsi), %esp
    cmovael -1(%rcx), %ecx
    cmovael 128(%rdx), %edx
    cmovael 0(%rsp), %ebx
    cmovael 64(%rsp), %esi
    cmovael -129(%rsp), %edi
    cmovael 0(%rsi,%rcx,4), %ebp
    cmovael 8(%rsi,%rdx,8), %esp
    cmovael -2147483648(%rdi,%rbx,1), %ecx
    cmovael gnu_back(%rip), %edx
    cmovael 2147483647, %ebx
    cmovaeq 0(%rbx), %r8
    cmovaeq -128(%r9), %r12
    cmovaeq 4660(%rbx), %r13
    cmovaeq 0(%r12), %r15
    cmovaeq 127(%rsp), %r9
    cmovaeq 128(%r12), %r10
    cmovaeq 0(%r8,%r12,2), %r11
    cmovaeq -1(%rdi,%rax,4), %r14
    cmovaeq -129(%r15,%r15,8), %r8
    cmovaeq gnu_fwd(%rip), %r12
    cmovaeq -2147483648, %r13
    sete 0(%r9)
    sete 64(%r11)
    sete 2147483647(%r13)
    sete 0(%r12)
    sete 8(%r12)
    sete 4660(%r12)
    sete 0(%r14,%rsi,1)
    sete -128(%r8,%rcx,2)
    sete 128(%r9,%r9,4)
    sete %bh
    sete 0(%rdi)
    sete 127(%rbx)
    sete -129(%rbp)
    sete 0(%rsp)
    sete -1(%rsp)
    sete -2147483648(%rsp)
    sete 0(%rdi,%rbp,8)
    sete 64(%rax,%rsi,1)
    sete 2147483647(%rcx,%rdi,2)
    sete gnu_back(%rip)
    sete 4660
    cmovew 0(%r10), %r15w
    cmovew 8(%r10), %r9w
    cmovew 128(%rsi), %r10w
    cmovew 0(%rsp), %r11w
    cmovew -128(%r12), %r14w
    cmovew -129(%rsp), %r8w
    cmovew 0(%rcx,%rbp,4), %r12w
    cmovew 127(%rax,%r12,8), %r13w
    cmovew -2147483648(%r9,%rax,1), %r15w
    cmovew gnu_fwd(%rip), %r9w
    cmovew 2147483647, %r10w
    cmovew %si, %di
    cmovew 0(%rcx), %bp
    cmovew -1(%rsi), %sp
    cmovew 4660(%rdi), %cx
g32:
    cmovew 0(%rsp), %dx
    cmovew 64(%rsp), %bx
    cmovew 128(%rsp), %si
    cmovew 0(%rax,%rax,2), %di
    cmovew 8(%rdx,%rcx,4), %bp
    cmovew -129(%rbx,%rdx,8), %sp
    cmovew gnu_back(%rip), %cx
    cmovew -2147483648, %dx
    cmovel 0(%rsi), %r11d
    cmovel -128(%r11), %r14d
    cmovel 2147483647(%rdi), %r8d
    cmovel 0(%r12), %r12d
    cmovel 127(%rsp), %r13d
    cmovel 4660(%r12), %r15d
    cmovel 0(%r12,%r15,1), %r9d
    cmovel -1(%rsp,%rsi,2), %r10d
    cmovel 128(%r13,%rcx,4), %r11d
    cmovel gnu_fwd(%rip), %r14d
    cmovel -129, %r8d
    cmovel %ebx, %esi
    cmovel 0(%rdx), %edi
    cmovel 64(%rcx), %ebp
    cmovel -2147483648(%rdx), %esp
    cmovel 0(%rsp), %ecx
    cmovel 8(%rsp), %edx
    cmovel 2147483647(%rsp), %ebx
    cmovel 0(%rcx,%rbx,8), %esi
    cmovel -128(%rsp,%rbp,1), %edi
    cmovel 4660(%rbp,%rsi,2), %ebp
    cmovel gnu_back(%rip), %esp
    cmovel 128, %ecx
    cmoveq 0(%r11), %r12
    cmoveq 127(%r14), %r13
    cmoveq -129(%r15), %r15
    cmoveq 0(%rsp), %r9
    cmoveq -1(%r12), %r10
    cmoveq -2147483648(%rsp), %r11
    cmoveq 0(%rdx,%r9,4), %r14
    cmoveq 64(%rbp,%rbp,8), %r8
    cmoveq 2147483647(%r12,%r12,1), %r12
    cmoveq gnu_fwd(%rip), %r13
    cmoveq 4660, %r15
    setne 0(%r10)
    setne 8(%r14)
    setne 128(%r15)
    setne 0(%r12)
    setne -128(%r12)
    setne -129(%r12)
    setne 0(%r15,%rax,2)
    setne 127(%r12,%r15,4)
    setne -2147483648(%r13,%rsi,8)
    setne %ch
    setne 0(%rbx)
    setne -1(%rbx)
    setne 2147483647(%rbp)
    setne 0(%rsp)
    setne 64(%rsp)
    setne 4660(%rsp)
    setne 0(%rdx,%rdi,1)
    setne 8(%rsi,%rax,2)
    setne 128(%rdi,%rcx,4)
    setne gnu_back(%rip)
    setne -129
    cmovnew 0(%rdi), %r9w
    cmovnew -128(%rcx), %r10w
    cmovnew -2147483648(%r8), %r11w
    cmovnew 0(%r12), %r14w
    cmovnew 127(%rsp), %r8w
    cmovnew 2147483647(%r12), %r12w
    cmovnew 0(%r9,%rcx,8), %r13w
    cmovnew -1(%rdi,%r9,1), %r15w
    cmovnew 4660(%r15,%rbp,2), %r9w
    cmovnew gnu_fwd(%rip), %r10w
    cmovnew 128, %r11w
    cmovnew %dx, %bx
    cmovnew 0(%rsi), %si
    cmovnew 64(%rsi), %di
    cmovnew -129(%rdi), %bp
    cmovnew 0(%rsp), %sp
    cmovnew 8(%rsp), %cx
    cmovnew -2147483648(%rsp), %dx
    cmovnew 0(%rbx,%rdx,4), %bx
    cmovnew -128(%rax,%rbx,8), %si
    cmovnew 2147483647(%rcx,%rbp,1), %di
    cmovnew gnu_back(%rip), %bp
    cmovnew 4660, %sp
    cmovnel 0(%r14), %r14d
    cmovnel 127(%rbp), %r8d
    cmovnel 128(%r13), %r12d
    cmovnel 0(%rsp), %r13d
    cmovnel -1(%r12), %r15d
    cmovnel -129(%rsp), %r9d
    cmovnel 0(%rsp,%r12,2), %r10d
    cmovnel 64(%rax,%rax,4), %r11d
    cmovnel -2147483648(%r9,%r15,8), %r14d
    cmovnel gnu_fwd(%rip), %r8d
    cmovnel 2147483647, %r12d
    cmovnel %ecx, %edx
    cmovnel 0(%rdi), %ebx
    cmovnel 8(%rcx), %esi
    cmovnel 4660(%rdx), %edi
    cmovnel 0(%rsp), %ebp
    cmovnel -128(%rsp), %esp
    cmovnel 128(%rsp), %ecx
    cmovnel 0(%rsp,%rsi,1), %edx
    cmovnel 127(%rdx,%rdi,2), %ebx
    cmovnel -129(%rbx,%rax,4), %esi
    cmovnel gnu_back(%rip), %edi
    cmovnel -2147483648, %ebp
    cmovneq 0(%r15), %r13
    cmovneq -1(%rdx), %r15
    cmovneq 2147483647(%r9), %r9
    cmovneq 0(%r12), %r10
    cmovneq 64(%rsp), %r11
    cmovneq 4660(%r12), %r14
    cmovneq 0(%r14,%rsi,8), %r8
    cmovneq 8(%rsp,%rcx,1), %r12
    cmovneq 128(%r13,%r9,2), %r13
    cmovneq gnu_fwd(%rip), %r15
    cmovneq -129, %r9
    setbe 0(%r11)
    setbe -128(%r8)
    setbe -2147483648(%r9)
    setbe 0(%r12)
    setbe 127(%r12)
    setbe 2147483647(%r12)
    setbe 0(%r8,%rbp,4)
    setbe -1(%r15,%r12,8)
    setbe 4660(%r8,%rax,1)
    setbe %ah
    setbe 0(%rcx)
    setbe 64(%rbx)
    setbe 128(%rbp)
    setbe 0(%rsp)
    setbe 8(%rsp)
    setbe -129(%rsp)
    setbe 0(%rsi,%rcx,2)
    setbe -128(%rsp,%rdx,4)
    setbe -2147483648(%rbp,%rbx,8)
    setbe gnu_back(%rip)
    setbe 2147483647
    cmovbew 0(%rcx), %r10w
    cmovbew 127(%rbx), %r11w
    cmovbew 4660(%r10), %r14w
    cmovbew 0(%rsp), %r8w
    cmovbew -1(%r12), %r12w
    cmovbew 128(%rsp), %r13w
    cmovbew 0(%rsi,%r15,1), %r15w
    cmovbew 64(%rbp,%rsi,2), %r9w
    cmovbew -129(%r12,%rcx,4), %r10w
    cmovbew gnu_fwd(%rip), %r11w
    cmovbew -2147483648, %r14w
    cmovbew %sp, %cx
    cmovbew 0(%rdx), %dx
    cmovbew 8(%rsi), %bx
    cmovbew 2147483647(%rdi), %si
    cmovbew 0(%rsp), %di
    cmovbew -128(%rsp), %bp
    cmovbew 4660(%rsp), %sp
    cmovbew 0(%rdi,%rbp,8), %cx
    cmovbew 127(%rsi,%rsi,1), %dx
    cmovbew 128(%rdi,%rdi,2), %bx
    cmovbew gnu_back(%rip), %si
    cmovbew -129, %di
    cmovbel 0(%r8), %r8d
    cmovbel -1(%rsi), %r12d
    cmovbel -2147483648(%r11), %r13d
    cmovbel 0(%r12), %r15d
    cmovbel 64(%rsp), %r9d
    cmovbel 2147483647(%r12), %r10d
    cmovbel 0(%r15,%r9,4), %r11d
    cmovbel 8(%rdi,%rbp,8), %r14d
    cmovbel 4660(%r15,%r12,1), %r8d
    cmovbel gnu_fwd(%rip), %r12d
    cmovbel 128, %r13d
    cmovbel %ebp, %esp
    cmovbel 0(%rbx), %ecx
    cmovbel -128(%rcx), %edx
    cmovbel -129(%rdx), %ebx
    cmovbel 0(%rsp), %esi
    cmovbel 127(%rsp), %edi
    cmovbel -2147483648(%rsp), %ebp
    cmovbel 0(%rax,%rax,2), %esp
    cmovbel -1(%rax,%rcx,4), %ecx
    cmovbel 2147483647(%rcx,%rdx,8), %edx
    cmovbel gnu_back(%rip), %ebx
    cmovbel 4660, %esi
    cmovbeq 0(%rdx), %r15
    cmovbeq 64(%rdi), %r9
    cmovbeq 128(%r14), %r10
    cmovbeq 0(%rsp), %r11
    cmovbeq 8(%r12), %r14
    cmovbeq -129(%rsp), %r8
    cmovbeq 0(%rax,%rax,1), %r12
    cmovbeq -128(%rax,%r15,2), %r13
    cmovbeq -2147483648(%r9,%rsi,4), %r15
    cmovbeq gnu_fwd(%rip), %r9
    cmovbeq 2147483647, %r10
    seta 0(%r14)
    seta 127(%r10)
g33:
    seta 4660(%r11)
    seta 0(%r12)
    seta -1(%r12)
    seta 128(%r12)
    seta 0(%r9,%rcx,8)
    seta 64(%r9,%r9,1)
    seta -129(%r12,%rbp,2)
    seta %cl
    seta 0(%rsi)
    seta 8(%rbx)
    seta -2147483648(%rbp)
    seta 0(%rsp)
    seta -128(%rsp)
    seta 2147483647(%rsp)
    seta 0(%rcx,%rbx,4)
    seta 127(%rdx,%rbp,8)
    seta 4660(%rbx,%rsi,1)
    seta gnu_back(%rip)
    seta 128
    cmovaw 0(%r9), %r11w
    cmovaw -1(%r15), %r14w
    cmovaw -129(%rcx), %r8w
    cmovaw 0(%r12), %r12w
    cmovaw 64(%rsp), %r13w
    cmovaw -2147483648(%r12), %r15w
    cmovaw 0(%r8,%r12,2), %r9w
    cmovaw 8(%rsp,%rax,4), %r10w
    cmovaw 2147483647(%r13,%r15,8), %r11w
    cmovaw gnu_fwd(%rip), %r14w
    cmovaw 4660, %r8w
    cmovaw %di, %bp
    cmovaw 0(%rdi), %sp
    cmovaw -128(%rsi), %cx
    cmovaw 128(%rdi), %dx
    cmovaw 0(%rsp), %bx
    cmovaw 127(%rsp), %si
    cmovaw -129(%rsp), %di
    cmovaw 0(%rdx,%rdi,1), %bp
    cmovaw -1(%rsp,%rax,2), %sp
    cmovaw -2147483648(%rbp,%rcx,4), %cx
    cmovaw gnu_back(%rip), %dx
    cmovaw 2147483647, %bx
    cmoval 0(%rbx), %r12d
    cmoval 64(%r8), %r13d
    cmoval 4660(%rbp), %r15d
    cmoval 0(%rsp), %r9d
    cmoval 8(%r12), %r10d
    cmoval 128(%rsp), %r11d
    cmoval 0(%rcx,%rsi,8), %r14d
    cmoval -128(%rbp,%rcx,1), %r8d
    cmoval -129(%r12,%r9,2), %r12d
    cmoval gnu_fwd(%rip), %r13d
    cmoval -2147483648, %r15d
    cmoval %esi, %edi
    cmoval 0(%rcx), %ebp
    cmoval 127(%rcx), %esp
    cmoval 2147483647(%rdx), %ecx
    cmoval 0(%rsp), %edx
    cmoval -1(%rsp), %ebx
    cmoval 4660(%rsp), %esi
    cmoval 0(%rbx,%rdx,4), %edi
    cmoval 64(%rsi,%rbx,8), %ebp
    cmoval 128(%rdi,%rbp,1), %esp
    cmoval gnu_back(%rip), %ecx
    cmoval -129, %edx
    cmovaq 0(%r10), %r9
    cmovaq 8(%r13), %r10
    cmovaq -2147483648(%rdx), %r11
    cmovaq 0(%r12), %r14
    cmovaq -128(%rsp), %r8
    cmovaq 2147483647(%r12), %r12
    cmovaq 0(%r12,%rbp,2), %r13
    cmovaq 127(%rdi,%r12,4), %r15
    cmovaq 4660(%r15,%rax,8), %r9
    cmovaq gnu_fwd(%rip), %r10
    cmovaq 128, %r11
    sets 0(%r15)
    sets -1(%r13)
    sets -129(%r14)
    sets 0(%r12)
    sets 64(%r12)
    sets -2147483648(%r12)
    sets 0(%r10,%r15,1)
    sets 8(%r13,%rsi,2)
    sets 2147483647(%r15,%rcx,4)
    sets %dl
    sets 0(%rdx)
    sets -128(%rbx)
    sets 4660(%rbp)
    sets 0(%rsp)
    sets 127(%rsp)
    sets 128(%rsp)
    sets 0(%rsp,%rsi,8)
    sets -1(%rax,%rdi,1)
    sets -129(%rcx,%rax,2)
    sets gnu_back(%rip)
    sets -2147483648
    cmovsw 0(%rsi), %r14w
    cmovsw 64(%r9), %r8w
    cmovsw 2147483647(%rbx), %r12w
    cmovsw 0(%rsp), %r13w
    cmovsw 8(%r12), %r15w
    cmovsw 4660(%rsp), %r9w
    cmovsw 0(%rdx,%r9,4), %r10w
    cmovsw -128(%rax,%rbp,8), %r11w
    cmovsw 128(%r9,%r12,1), %r14w
    cmovsw gnu_fwd(%rip), %r8w
    cmovsw -129, %r12w
    cmovsw %bx, %si
    cmovsw 0(%rbx), %di
    cmovsw 127(%rsi), %bp
    cmovsw -2147483648(%rdi), %sp
    cmovsw 0(%rsp), %cx
    cmovsw -1(%rsp), %dx
    cmovsw 2147483647(%rsp), %bx
    cmovsw 0(%rsi,%rcx,2), %si
    cmovsw 64(%rdx,%rdx,4), %di
    cmovsw 4660(%rbx,%rbx,8), %bp
    cmovsw gnu_back(%rip), %sp
    cmovsw 128, %cx
    cmovsl 0(%r11), %r13d
    cmovsl 8(%r10), %r15d
    cmovsl -129(%rsi), %r9d
    cmovsl 0(%r12), %r10d
    cmovsl -128(%rsp), %r11d
    cmovsl -2147483648(%r12), %r14d
    cmovsl 0(%r9,%rax,1), %r8d
    cmovsl 127(%rsp,%r15,2), %r12d
    cmovsl 2147483647(%r13,%rsi,4), %r13d
    cmovsl gnu_fwd(%rip), %r15d
    cmovsl 4660, %r9d
    cmovsl %edx, %ebx
    cmovsl 0(%rsi), %esi
    cmovsl -1(%rcx), %edi
    cmovsl 128(%rdx), %ebp
    cmovsl 0(%rsp), %esp
    cmovsl 64(%rsp), %ecx
    cmovsl -129(%rsp), %edx
    cmovsl 0(%rdi,%rbp,8), %ebx
    cmovsl 8(%rsp,%rsi,1), %esi
    cmovsl -2147483648(%rbp,%rdi,2), %edi
    cmovsl gnu_back(%rip), %ebp
    cmovsl 2147483647, %esp
    cmovsq 0(%rdi), %r10
    cmovsq -128(%r11), %r11
    cmovsq 4660(%rdi), %r14
    cmovsq 0(%rsp), %r8
    cmovsq 127(%r12), %r12
    cmovsq 128(%rsp), %r13
    cmovsq 0(%rsp,%rcx,4), %r15
    cmovsq -1(%rbp,%r9,8), %r9
    cmovsq -129(%r12,%rbp,1), %r10
    cmovsq gnu_fwd(%rip), %r11
    cmovsq -2147483648, %r14
    setns 0(%r8)
    setns 64(%r15)
    setns 2147483647(%r8)
    setns 0(%r12)
    setns 8(%r12)
    setns 4660(%r12)
    setns 0(%r11,%r12,2)
    setns -128(%r8,%rax,4)
    setns 128(%r9,%r15,8)
    setns %bl
    setns 0(%rdi)
    setns 127(%rbx)
    setns -129(%rbp)
    setns 0(%rsp)
    setns -1(%rsp)
    setns -2147483648(%rsp)
    setns 0(%rax,%rax,1)
    setns 64(%rsi,%rcx,2)
    setns 2147483647(%rdi,%rdx,4)
    setns gnu_back(%rip)
    setns 4660
    cmovnsw 0(%r14), %r8w
    cmovnsw 8(%r14), %r12w
    cmovnsw 128(%r15), %r13w
    cmovnsw 0(%r12), %r15w
    cmovnsw -128(%rsp), %r9w
    cmovnsw -129(%r12), %r10w
    cmovnsw 0(%r14,%rsi,8), %r11w
    cmovnsw 127(%rdi,%rcx,1), %r14w
    cmovnsw -2147483648(%r15,%r9,2), %r8w
    cmovnsw gnu_fwd(%rip), %r12w
    cmovnsw 2147483647, %r13w
    cmovnsw %cx, %dx
    cmovnsw 0(%rcx), %bx
    cmovnsw -1(%rsi), %si
    cmovnsw 4660(%rdi), %di
    cmovnsw 0(%rsp), %bp
    cmovnsw 64(%rsp), %sp
    cmovnsw 128(%rsp), %cx
    cmovnsw 0(%rcx,%rbx,4), %dx
    cmovnsw 8(%rax,%rbp,8), %bx
    cmovnsw -129(%rcx,%rsi,1), %si
    cmovnsw gnu_back(%rip), %di
    cmovnsw -2147483648, %bp
    cmovnsl 0(%r15), %r15d
    cmovnsl -128(%rcx), %r9d
g34:
    cmovnsl 2147483647(%r8), %r10d
    cmovnsl 0(%rsp), %r11d
    cmovnsl 127(%r12), %r14d
    cmovnsl 4660(%rsp), %r8d
    cmovnsl 0(%rsi,%rbp,2), %r12d
    cmovnsl -1(%rax,%r12,4), %r13d
    cmovnsl 128(%r9,%rax,8), %r15d
    cmovnsl gnu_fwd(%rip), %r9d
    cmovnsl -129, %r10d
    cmovnsl %esp, %ecx
    cmovnsl 0(%rdx), %edx
    cmovnsl 64(%rcx), %ebx
    cmovnsl -2147483648(%rdx), %esi
    cmovnsl 0(%rsp), %edi
    cmovnsl 8(%rsp), %ebp
    cmovnsl 2147483647(%rsp), %esp
    cmovnsl 0(%rdx,%rdi,1), %ecx
    cmovnsl -128(%rdx,%rax,2), %edx
    cmovnsl 4660(%rbx,%rcx,4), %ebx
    cmovnsl gnu_back(%rip), %esi
    cmovnsl 128, %edi
    cmovnsq 0(%rcx), %r11
    cmovnsq 127(%rbp), %r14
    cmovnsq -129(%r13), %r8
    cmovnsq 0(%r12), %r12
    cmovnsq -1(%rsp), %r13
    cmovnsq -2147483648(%r12), %r15
    cmovnsq 0(%r15,%r15,8), %r9
    cmovnsq 64(%rsp,%rsi,1), %r10
    cmovnsq 2147483647(%r13,%rcx,2), %r11
    cmovnsq gnu_fwd(%rip), %r14
    cmovnsq 4660, %r8
    setp 0(%r9)
    setp 8(%r9)
    setp 128(%r10)
    setp 0(%r12)
    setp -128(%r12)
    setp -129(%r12)
    setp 0(%r12,%r9,4)
    setp 127(%r12,%rbp,8)
    setp -2147483648(%r13,%r12,1)
    setp %dh
    setp 0(%rbx)
    setp -1(%rbx)
    setp 2147483647(%rbp)
    setp 0(%rsp)
    setp 64(%rsp)
    setp 4660(%rsp)
    setp 0(%rbx,%rdx,2)
    setp 8(%rsp,%rbx,4)
    setp 128(%rbp,%rbp,8)
    setp gnu_back(%rip)
    setp -129
    cmovpw 0(%r8), %r12w
    cmovpw -128(%rdx), %r13w
    cmovpw -2147483648(%r9), %r15w
    cmovpw 0(%rsp), %r9w
    cmovpw 127(%r12), %r10w
    cmovpw 2147483647(%rsp), %r11w
    cmovpw 0(%rax,%rax,1), %r14w
    cmovpw -1(%rbp,%r15,2), %r8w
    cmovpw 4660(%r12,%rsi,4), %r12w
    cmovpw gnu_fwd(%rip), %r13w
    cmovpw 128, %r15w
    cmovpw %bp, %sp
    cmovpw 0(%rsi), %cx
    cmovpw 64(%rsi), %dx
    cmovpw -129(%rdi), %bx
    cmovpw 0(%rsp), %si
    cmovpw 8(%rsp), %di
    cmovpw -2147483648(%rsp), %bp
    cmovpw 0(%rsp,%rsi,8), %sp
    cmovpw -128(%rsi,%rdi,1), %cx
    cmovpw 2147483647(%rdi,%rax,2), %dx
    cmovpw gnu_back(%rip), %bx
    cmovpw 4660, %si
    cmovpl 0(%rdx), %r9d
    cmovpl 127(%rbx), %r10d
    cmovpl 128(%r10), %r11d
    cmovpl 0(%r12), %r14d
    cmovpl -1(%rsp), %r8d
    cmovpl -129(%r12), %r12d
    cmovpl 0(%r8,%rcx,4), %r13d
    cmovpl 64(%rdi,%r9,8), %r15d
    cmovpl -2147483648(%r15,%rbp,1), %r9d
    cmovpl gnu_fwd(%rip), %r10d
    cmovpl 2147483647, %r11d
    cmovpl %edi, %ebp
    cmovpl 0(%rdi), %esp
    cmovpl 8(%rcx), %ecx
    cmovpl 4660(%rdx), %edx
    cmovpl 0(%rsp), %ebx
    cmovpl -128(%rsp), %esi
    cmovpl 128(%rsp), %edi
    cmovpl 0(%rsi,%rcx,2), %ebp
    cmovpl 127(%rax,%rdx,4), %esp
    cmovpl -129(%rcx,%rbx,8), %ecx
    cmovpl gnu_back(%rip), %edx
    cmovpl -2147483648, %ebx
    cmovpq 0(%r9), %r14
    cmovpq -1(%rsi), %r8
    cmovpq 2147483647(%r11), %r12
    cmovpq 0(%rsp), %r13
    cmovpq 64(%r12), %r15
    cmovpq 4660(%rsp), %r9
    cmovpq 0(%rcx,%r12,1), %r10
    cmovpq 8(%rax,%rax,2), %r11
    cmovpq 128(%r9,%r15,4), %r14
    cmovpq gnu_fwd(%rip), %r8
    cmovpq -129, %r12
    setnp 0(%r10)
    setnp -128(%r11)
    setnp -2147483648(%r13)
    setnp 0(%r12)
    setnp 127(%r12)
    setnp 2147483647(%r12)
    setnp 0(%r14,%rsi,8)
    setnp -1(%r15,%rcx,1)
    setnp 4660(%r8,%r9,2)
    setnp %bh
    setnp 0(%rcx)
    setnp 64(%rbx)
    setnp 128(%rbp)
    setnp 0(%rsp)
    setnp 8(%rsp)
    setnp -129(%rsp)
    setnp 0(%rdi,%rbp,4)
    setnp -128(%rdx,%rsi,8)
    setnp -2147483648(%rbx,%rdi,1)
    setnp gnu_back(%rip)
    setnp 2147483647
    cmovnpw 0(%rbx), %r13w
    cmovnpw 127(%rdi), %r15w
    cmovnpw 4660(%r14), %r9w
    cmovnpw 0(%r12), %r10w
    cmovnpw -1(%rsp), %r11w
    cmovnpw 128(%r12), %r14w
    cmovnpw 0(%r12,%rbp,2), %r8w
    cmovnpw 64(%rsp,%r12,4), %r12w
    cmovnpw -129(%r13,%rax,8), %r13w
    cmovnpw gnu_fwd(%rip), %r15w
    cmovnpw -2147483648, %r9w
    cmovnpw %si, %di
    cmovnpw 0(%rdx), %bp
    cmovnpw 8(%rsi), %sp
    cmovnpw 2147483647(%rdi), %cx
    cmovnpw 0(%rsp), %dx
    cmovnpw -128(%rsp), %bx
    cmovnpw 4660(%rsp), %si
    cmovnpw 0(%rax,%rax,1), %di
    cmovnpw 127(%rsp,%rcx,2), %bp
    cmovnpw 128(%rbp,%rdx,4), %sp
    cmovnpw gnu_back(%rip), %cx
    cmovnpw -129, %dx
    cmovnpl 0(%r10), %r10d
    cmovnpl -1(%r15), %r11d
    cmovnpl -2147483648(%rcx), %r14d
    cmovnpl 0(%rsp), %r8d
    cmovnpl 64(%r12), %r12d
    cmovnpl 2147483647(%rsp), %r13d
    cmovnpl 0(%rdx,%r15,8), %r15d
    cmovnpl 8(%rbp,%rsi,1), %r9d
    cmovnpl 4660(%r12,%rcx,2), %r10d
    cmovnpl gnu_fwd(%rip), %r11d
    cmovnpl 128, %r14d
    cmovnpl %ebx, %esi
    cmovnpl 0(%rbx), %edi
    cmovnpl -128(%rcx), %ebp
    cmovnpl -129(%rdx), %esp
    cmovnpl 0(%rsp), %ecx
    cmovnpl 127(%rsp), %edx
    cmovnpl -2147483648(%rsp), %ebx
    cmovnpl 0(%rcx,%rbx,4), %esi
    cmovnpl -1(%rsi,%rbp,8), %edi
    cmovnpl 2147483647(%rdi,%rsi,1), %ebp
    cmovnpl gnu_back(%rip), %esp
    cmovnpl 4660, %ecx
    cmovnpq 0(%rsi), %r8
    cmovnpq 64(%r8), %r12
    cmovnpq 128(%rbp), %r13
    cmovnpq 0(%r12), %r15
    cmovnpq 8(%rsp), %r9
    cmovnpq -129(%r12), %r10
    cmovnpq 0(%r9,%r9,2), %r11
    cmovnpq -128(%rdi,%rbp,4), %r14
    cmovnpq -2147483648(%r15,%r12,8), %r8
    cmovnpq gnu_fwd(%rip), %r12
    cmovnpq 2147483647, %r13
    setl 0(%r11)
    setl 127(%r14)
    setl 4660(%r15)
    setl 0(%r12)
    setl -1(%r12)
    setl 128(%r12)
    setl 0(%r15,%rax,1)
    setl 64(%r9,%r15,2)
    setl -129(%r12,%rsi,4)
    setl %ch
    setl 0(%rsi)
    setl 8(%rbx)
g35:
    setl -2147483648(%rbp)
    setl 0(%rsp)
    setl -128(%rsp)
    setl 2147483647(%rsp)
    setl 0(%rdx,%rdi,8)
    setl 127(%rax,%rax,1)
    setl 4660(%rcx,%rcx,2)
    setl gnu_back(%rip)
    setl 128
    cmovlw 0(%r11), %r15w
    cmovlw -1(%r13), %r9w
    cmovlw -129(%rdx), %r10w
    cmovlw 0(%rsp), %r11w
    cmovlw 64(%r12), %r14w
    cmovlw -2147483648(%rsp), %r8w
    cmovlw 0(%rsp,%rcx,4), %r12w
    cmovlw 8(%rax,%r9,8), %r13w
    cmovlw 2147483647(%r9,%rbp,1), %r15w
    cmovlw gnu_fwd(%rip), %r9w
    cmovlw 4660, %r10w
    cmovlw %dx, %bx
    cmovlw 0(%rdi), %si
    cmovlw -128(%rsi), %di
    cmovlw 128(%rdi), %bp
    cmovlw 0(%rsp), %sp
    cmovlw 127(%rsp), %cx
    cmovlw -129(%rsp), %dx
    cmovlw 0(%rbx,%rdx,2), %bx
    cmovlw -1(%rdx,%rbx,4), %si
    cmovlw -2147483648(%rbx,%rbp,8), %di
    cmovlw gnu_back(%rip), %bp
    cmovlw 2147483647, %sp
    cmovll 0(%rdi), %r11d
    cmovll 64(%r9), %r14d
    cmovll 4660(%rbx), %r8d
    cmovll 0(%r12), %r12d
    cmovll 8(%rsp), %r13d
    cmovll 128(%r12), %r15d
    cmovll 0(%r14,%r12,1), %r9d
    cmovll -128(%rsp,%rax,2), %r10d
    cmovll -129(%r13,%r15,4), %r11d
    cmovll gnu_fwd(%rip), %r14d
    cmovll -2147483648, %r8d
    cmovll %ecx, %edx
    cmovll 0(%rcx), %ebx
    cmovll 127(%rcx), %esi
    cmovll 2147483647(%rdx), %edi
    cmovll 0(%rsp), %ebp
    cmovll -1(%rsp), %esp
    cmovll 4660(%rsp), %ecx
    cmovll 0(%rsp,%rsi,8), %edx
    cmovll 64(%rsp,%rdi,1), %ebx
    cmovll 128(%rbp,%rax,2), %esi
    cmovll gnu_back(%rip), %edi
    cmovll -129, %ebp
    cmovlq 0(%r14), %r12
    cmovlq 8(%r10), %r13
    cmovlq -2147483648(%rsi), %r15
    cmovlq 0(%rsp), %r9
    cmovlq -128(%r12), %r10
    cmovlq 2147483647(%rsp), %r11
    cmovlq 0(%rsi,%rsi,4), %r14
    cmovlq 127(%rbp,%rcx,8), %r8
    cmovlq 4660(%r12,%r9,1), %r12
    cmovlq gnu_fwd(%rip), %r13
    cmovlq 128, %r15
    setge 0(%r14)
    setge -1(%r8)
    setge -129(%r9)
    setge 0(%r12)
    setge 64(%r12)
    setge -2147483648(%r12)
    setge 0(%r8,%rbp,2)
    setge 8(%r13,%r12,4)
    setge 2147483647(%r15,%rax,8)
    setge %ah
    setge 0(%rdx)
    setge -128(%rbx)
    setge 4660(%rbp)
    setge 0(%rsp)
    setge 127(%rsp)
    setge 128(%rsp)
    setge 0(%rsi,%rcx,1)
    setge -1(%rsi,%rdx,2)
    setge -129(%rdi,%rbx,4)
    setge gnu_back(%rip)
    setge -2147483648
    cmovgew 0(%r15), %r9w
    cmovgew 64(%r11), %r10w
    cmovgew 2147483647(%rdi), %r11w
    cmovgew 0(%r12), %r14w
    cmovgew 8(%rsp), %r8w
    cmovgew 4660(%r12), %r12w
    cmovgew 0(%r15,%r15,8), %r13w
    cmovgew -128(%rdi,%rsi,1), %r15w
    cmovgew 128(%r15,%rcx,2), %r9w
    cmovgew gnu_fwd(%rip), %r10w
    cmovgew -129, %r11w
    cmovgew %sp, %cx
    cmovgew 0(%rbx), %dx
    cmovgew 127(%rsi), %bx
    cmovgew -2147483648(%rdi), %si
    cmovgew 0(%rsp), %di
    cmovgew -1(%rsp), %bp
    cmovgew 2147483647(%rsp), %sp
    cmovgew 0(%rdi,%rbp,4), %cx
    cmovgew 64(%rax,%rsi,8), %dx
    cmovgew 4660(%rcx,%rdi,1), %bx
    cmovgew gnu_back(%rip), %si
    cmovgew 128, %di
    cmovgel 0(%rcx), %r14d
    cmovgel 8(%r14), %r8d
    cmovgel -129(%r15), %r12d
    cmovgel 0(%rsp), %r13d
    cmovgel -128(%r12), %r15d
    cmovgel -2147483648(%rsp), %r9d
    cmovgel 0(%rax,%r9,2), %r10d
    cmovgel 127(%rax,%rbp,4), %r11d
    cmovgel 2147483647(%r9,%r12,8), %r14d
    cmovgel gnu_fwd(%rip), %r8d
    cmovgel 4660, %r12d
    cmovgel %ebp, %esp
    cmovgel 0(%rsi), %ecx
    cmovgel -1(%rcx), %edx
    cmovgel 128(%rdx), %ebx
    cmovgel 0(%rsp), %esi
    cmovgel 64(%rsp), %edi
    cmovgel -129(%rsp), %ebp
    cmovgel 0(%rax,%rax,1), %esp
    cmovgel 8(%rdx,%rcx,2), %ecx
    cmovgel -2147483648(%rbx,%rdx,4), %edx
    cmovgel gnu_back(%rip), %ebx
    cmovgel 2147483647, %esi
    cmovgeq 0(%r8), %r13
    cmovgeq -128(%rcx), %r15
    cmovgeq 4660(%r8), %r9
    cmovgeq 0(%r12), %r10
    cmovgeq 127(%rsp), %r11
    cmovgeq 128(%r12), %r14
    cmovgeq 0(%r8,%rax,8), %r8
    cmovgeq -1(%rsp,%r15,1), %r12
    cmovgeq -129(%r13,%rsi,2), %r13
    cmovgeq gnu_fwd(%rip), %r15
    cmovgeq -2147483648, %r9
    setle 0(%r15)
    setle 64(%r10)
    setle 2147483647(%r11)
    setle 0(%r12)
    setle 8(%r12)
    setle 4660(%r12)
    setle 0(%r9,%rcx,4)
    setle -128(%r8,%r9,8)
    setle 128(%r9,%rbp,1)
    setle %cl
    setle 0(%rdi)
    setle 127(%rbx)
    setle -129(%rbp)
    setle 0(%rsp)
    setle -1(%rsp)
    setle -2147483648(%rsp)
    setle 0(%rcx,%rbx,2)
    setle 64(%rsp,%rbp,4)
    setle 2147483647(%rbp,%rsi,8)
    setle gnu_back(%rip)
    setle 4660
    cmovlew 0(%rdx), %r10w
    cmovlew 8(%rbp), %r11w
    cmovlew 128(%r13), %r14w
    cmovlew 0(%rsp), %r8w
    cmovlew -128(%r12), %r12w
    cmovlew -129(%rsp), %r13w
    cmovlew 0(%rcx,%r12,1), %r15w
    cmovlew 127(%rbp,%rax,2), %r9w
    cmovlew -2147483648(%r12,%r15,4), %r10w
    cmovlew gnu_fwd(%rip), %r11w
    cmovlew 2147483647, %r14w
    cmovlew %di, %bp
    cmovlew 0(%rcx), %sp
    cmovlew -1(%rsi), %cx
    cmovlew 4660(%rdi), %dx
    cmovlew 0(%rsp), %bx
    cmovlew 64(%rsp), %si
    cmovlew 128(%rsp), %di
    cmovlew 0(%rdx,%rdi,8), %bp
    cmovlew 8(%rsi,%rax,1), %sp
    cmovlew -129(%rdi,%rcx,2), %cx
    cmovlew gnu_back(%rip), %dx
    cmovlew -2147483648, %bx
    cmovlel 0(%r9), %r8d
    cmovlel -128(%rdx), %r12d
    cmovlel 2147483647(%r9), %r13d
    cmovlel 0(%r12), %r15d
    cmovlel 127(%rsp), %r9d
    cmovlel 4660(%r12), %r10d
    cmovlel 0(%r12,%rsi,4), %r11d
    cmovlel -1(%rdi,%rcx,8), %r14d
    cmovlel 128(%r15,%r9,1), %r8d
    cmovlel gnu_fwd(%rip), %r12d
    cmovlel -129, %r13d
    cmovlel %esi, %edi
g36:
    cmovlel 0(%rdx), %ebp
    cmovlel 64(%rcx), %esp
    cmovlel -2147483648(%rdx), %ecx
    cmovlel 0(%rsp), %edx
    cmovlel 8(%rsp), %ebx
    cmovlel 2147483647(%rsp), %esi
    cmovlel 0(%rbx,%rdx,2), %edi
    cmovlel -128(%rax,%rbx,4), %ebp
    cmovlel 4660(%rcx,%rbp,8), %esp
    cmovlel gnu_back(%rip), %ecx
    cmovlel 128, %edx
    cmovleq 0(%rbx), %r15
    cmovleq 127(%rbx), %r9
    cmovleq -129(%r10), %r10
    cmovleq 0(%rsp), %r11
    cmovleq -1(%r12), %r14
    cmovleq -2147483648(%rsp), %r8
    cmovleq 0(%rdx,%rbp,1), %r12
    cmovleq 64(%rax,%r12,2), %r13
    cmovleq 2147483647(%r9,%rax,4), %r15
    cmovleq gnu_fwd(%rip), %r9
    cmovleq 4660, %r10
    setg 0(%r8)
    setg 8(%r13)
    setg 128(%r14)
    setg 0(%r12)
    setg -128(%r12)
    setg -129(%r12)
    setg 0(%r10,%r15,8)
    setg 127(%r12,%rsi,1)
    setg -2147483648(%r13,%rcx,2)
    setg %dl
    setg 0(%rbx)
    setg -1(%rbx)
    setg 2147483647(%rbp)
    setg 0(%rsp)
    setg 64(%rsp)
    setg 4660(%rsp)
    setg 0(%rsp,%rsi,4)
    setg 8(%rdx,%rdi,8)
    setg 128(%rbx,%rax,1)
    setg gnu_back(%rip)
    setg -129
    cmovgw 0(%r10), %r11w
    cmovgw -128(%rsi), %r14w
    cmovgw -2147483648(%r11), %r8w
    cmovgw 0(%r12), %r12w
    cmovgw 127(%rsp), %r13w
    cmovgw 2147483647(%r12), %r15w
    cmovgw 0(%r9,%r9,2), %r9w
    cmovgw -1(%rsp,%rbp,4), %r10w
    cmovgw 4660(%r13,%r12,8), %r11w
    cmovgw gnu_fwd(%rip), %r14w
    cmovgw 128, %r8w
    cmovgw %bx, %si
    cmovgw 0(%rsi), %di
    cmovgw 64(%rsi), %bp
    cmovgw -129(%rdi), %sp
    cmovgw 0(%rsp), %cx
    cmovgw 8(%rsp), %dx
    cmovgw -2147483648(%rsp), %bx
    cmovgw 0(%rsi,%rcx,1), %si
    cmovgw -128(%rsp,%rdx,2), %di
    cmovgw 2147483647(%rbp,%rbx,4), %bp
    cmovgw gnu_back(%rip), %sp
    cmovgw 4660, %cx
    cmovgl 0(%rsi), %r12d
    cmovgl 127(%rdi), %r13d
    cmovgl 128(%r14), %r15d
    cmovgl 0(%rsp), %r9d
    cmovgl -1(%r12), %r10d
    cmovgl -129(%rsp), %r11d
    cmovgl 0(%rsp,%rax,8), %r14d
    cmovgl 64(%rbp,%r15,1), %r8d
    cmovgl -2147483648(%r12,%rsi,2), %r12d
    cmovgl gnu_fwd(%rip), %r13d
    cmovgl 2147483647, %r15d
    cmovgl %edx, %ebx
    cmovgl 0(%rdi), %esi
    cmovgl 8(%rcx), %edi
    cmovgl 4660(%rdx), %ebp
    cmovgl 0(%rsp), %esp
    cmovgl -128(%rsp), %ecx
    cmovgl 128(%rsp), %edx
    cmovgl 0(%rdi,%rbp,4), %ebx
    cmovgl 127(%rsi,%rsi,8), %esi
    cmovgl -129(%rdi,%rdi,1), %edi
    cmovgl gnu_back(%rip), %ebp
    cmovgl -2147483648, %esp
    cmovgq 0(%r11), %r9
    cmovgq -1(%r15), %r10
    cmovgq 2147483647(%rcx), %r11
    cmovgq 0(%r12), %r14
    cmovgq 64(%rsp), %r8
    cmovgq 4660(%r12), %r12
    cmovgq 0(%r14,%rcx,2), %r13
    cmovgq 8(%rdi,%r9,4), %r15
    cmovgq 128(%r15,%rbp,8), %r9
    cmovgq gnu_fwd(%rip), %r10
    cmovgq -129, %r11
    call *%rcx
    call *0(%rcx)
    call *0(%r9)
    call *-128(%rbx)
    call *127(%r15)
    call *-2147483648(%rbp)
    call *2147483647(%r8)
    call *0(%rsp)
    call *0(%r12)
    call *-1(%rsp)
    call *64(%r12)
    call *4660(%rsp)
    call *128(%r12)
    call *0(%rax,%rax,1)
    call *0(%r11,%r12,2)
    call *8(%rax,%rcx,4)
    call *-128(%r15,%rax,8)
    call *-129(%rcx,%rdx,1)
    call *-2147483648(%r8,%r15,2)
    call *2147483647
    jmp *%rdx
    jmp *0(%rdx)
    jmp *0(%r10)
    jmp *127(%rsi)
    jmp *-1(%r9)
    jmp *4660(%rdi)
    jmp *128(%r10)
    jmp *0(%rsp)
    jmp *0(%r12)
    jmp *64(%rsp)
    jmp *8(%r12)
    jmp *-129(%rsp)
    jmp *-2147483648(%r12)
    jmp *0(%rcx,%rbx,4)
    jmp *0(%r12,%rsi,8)
    jmp *-128(%rdx,%rbp,1)
    jmp *127(%r9,%rcx,2)
    jmp *2147483647(%rbx,%rsi,4)
    jmp *4660(%r12,%r9,8)
    jmp *128
    pushq %rbx
    popq %rsi
    nopw 0(%r11)
    nopw -1(%r11)
    nopw -129(%r13)
    nopw 0(%r12)
    nopw 64(%r12)
    nopw -2147483648(%r12)
    nopw 0(%r14,%rbp,1)
    nopw 8(%r13,%r12,2)
    nopw 2147483647(%r15,%rax,4)
    nopw %di
    nopw 0(%rbx)
    nopw -128(%rcx)
    nopw 4660(%rdx)
    nopw 0(%rsp)
    nopw 127(%rsp)
    nopw 128(%rsp)
    nopw 0(%rdx,%rdi,8)
    nopw -1(%rsp,%rax,1)
    nopw -129(%rbp,%rcx,2)
    nopw gnu_back(%rip)
    nopw -2147483648
    nopl 0(%r14)
    nopl 64(%r14)
    nopl 2147483647(%r15)
    nopl 0(%r12)
    nopl 8(%r12)
    nopl 4660(%r12)
    nopl 0(%r15,%r15,4)
    nopl -128(%r8,%rsi,8)
    nopl 128(%r9,%rcx,1)
    nopl %ebp
    nopl 0(%rsi)
    nopl 127(%rbx)
    nopl -129(%rbp)
    nopl 0(%rsp)
    nopl -1(%rsp)
    nopl -2147483648(%rsp)
    nopl 0(%rbx,%rdx,2)
    nopl 64(%rsi,%rbx,4)
    nopl 2147483647(%rdi,%rbp,8)
    nopl gnu_fwd(%rip)
    nopl 4660
    pcmpeqb %xmm14, %xmm9
    pcmpeqb 0(%rdi), %xmm8
    pcmpeqb 8(%r8), %xmm12
    pcmpeqb 128(%rbp), %xmm13
    pcmpeqb 0(%rsp), %xmm15
    pcmpeqb -128(%r12), %xmm9
    pcmpeqb -129(%rsp), %xmm10
    pcmpeqb 0(%rsi,%r9,1), %xmm11
    pcmpeqb 127(%rax,%rbp,2), %xmm14
    pcmpeqb -2147483648(%r9,%r12,4), %xmm8
    pcmpeqb gnu_back(%rip), %xmm12
    pcmpeqb 2147483647, %xmm13
    pcmpeqb %xmm4, %xmm1
    pcmpeqb 0(%rdi), %xmm2
    pcmpeqb -1(%rsi), %xmm3
    pcmpeqb 4660(%rdi), %xmm6
g37:
    pcmpeqb 0(%rsp), %xmm7
    pcmpeqb 64(%rsp), %xmm5
    pcmpeqb 128(%rsp), %xmm4
    pcmpeqb 0(%rsp,%rsi,8), %xmm1
    pcmpeqb 8(%rax,%rdi,1), %xmm2
    pcmpeqb -129(%rcx,%rax,2), %xmm3
    pcmpeqb gnu_fwd(%rip), %xmm6
    pcmpeqb -2147483648, %xmm7
    pcmpeqd %xmm15, %xmm2
    pcmpeqd 0(%r14), %xmm9
    pcmpeqd -128(%r13), %xmm10
    pcmpeqd 2147483647(%rdx), %xmm11
    pcmpeqd 0(%r12), %xmm14
    pcmpeqd 127(%rsp), %xmm8
    pcmpeqd 4660(%r12), %xmm12
    pcmpeqd 0(%r15,%rax,4), %xmm13
    pcmpeqd -1(%rsp,%r15,8), %xmm15
    pcmpeqd 128(%r13,%rsi,1), %xmm9
    pcmpeqd gnu_back(%rip), %xmm10
    pcmpeqd -129, %xmm11
    pcmpeqd %xmm5, %xmm4
    pcmpeqd 0(%rcx), %xmm1
    pcmpeqd 64(%rcx), %xmm2
    pcmpeqd -2147483648(%rdx), %xmm3
    pcmpeqd 0(%rsp), %xmm6
    pcmpeqd 8(%rsp), %xmm7
    pcmpeqd 2147483647(%rsp), %xmm5
    pcmpeqd 0(%rsi,%rcx,2), %xmm4
    pcmpeqd -128(%rdx,%rdx,4), %xmm1
    pcmpeqd 4660(%rbx,%rbx,8), %xmm2
    pcmpeqd gnu_fwd(%rip), %xmm3
    pcmpeqd 128, %xmm6
    pcmpgtb %xmm14, %xmm12
    pcmpgtb 0(%r15), %xmm8
    pcmpgtb 127(%r9), %xmm12
    pcmpgtb -129(%rbx), %xmm13
    pcmpgtb 0(%rsp), %xmm15
    pcmpgtb -1(%r12), %xmm9
    pcmpgtb -2147483648(%rsp), %xmm10
    pcmpgtb 0(%rax,%rcx,1), %xmm11
    pcmpgtb 64(%rbp,%r9,2), %xmm14
    pcmpgtb 2147483647(%r12,%rbp,4), %xmm8
    pcmpgtb gnu_back(%rip), %xmm12
    pcmpgtb 4660, %xmm13
    pcmpgtb %xmm7, %xmm5
    pcmpgtb 0(%rdx), %xmm4
    pcmpgtb 8(%rbx), %xmm1
    pcmpgtb 128(%rbp), %xmm2
    pcmpgtb 0(%rsp), %xmm3
    pcmpgtb -128(%rsp), %xmm6
    pcmpgtb -129(%rsp), %xmm7
    pcmpgtb 0(%rdi,%rbp,8), %xmm5
    pcmpgtb 127(%rsp,%rsi,1), %xmm4
    pcmpgtb -2147483648(%rbp,%rdi,2), %xmm1
    pcmpgtb gnu_fwd(%rip), %xmm2
    pcmpgtb 2147483647, %xmm3
    pminub %xmm15, %xmm3
    pminub 0(%rcx), %xmm9
    pminub -1(%r10), %xmm10
    pminub 4660(%rsi), %xmm11
    pminub 0(%r12), %xmm14
    pminub 64(%rsp), %xmm8
    pminub 128(%r12), %xmm12
    pminub 0(%r8,%r12,4), %xmm13
    pminub 8(%rdi,%rax,8), %xmm15
    pminub -129(%r15,%r15,1), %xmm9
    pminub gnu_back(%rip), %xmm10
    pminub -2147483648, %xmm11
    pminub %xmm6, %xmm7
    pminub 0(%rbx), %xmm5
    pminub -128(%rsi), %xmm4
    pminub 2147483647(%rdi), %xmm1
    pminub 0(%rsp), %xmm2
    pminub 127(%rsp), %xmm3
    pminub 4660(%rsp), %xmm6
    pminub 0(%rax,%rax,2), %xmm7
    pminub -1(%rsi,%rcx,4), %xmm5
    pminub 128(%rdi,%rdx,8), %xmm4
    pminub gnu_fwd(%rip), %xmm1
    pminub -129, %xmm2
    pmaxub %xmm14, %xmm13
    pmaxub 0(%r8), %xmm8
    pmaxub 64(%r11), %xmm12
    pmaxub -2147483648(%rdi), %xmm13
    pmaxub 0(%rsp), %xmm15
    pmaxub 8(%r12), %xmm9
    pmaxub 2147483647(%rsp), %xmm10
    pmaxub 0(%rcx,%rsi,1), %xmm11
    pmaxub -128(%rax,%rcx,2), %xmm14
    pmaxub 4660(%r9,%r9,4), %xmm8
    pmaxub gnu_back(%rip), %xmm12
    pmaxub 128, %xmm13
    pmaxub %xmm3, %xmm6
    pmaxub 0(%rsi), %xmm7
    pmaxub 127(%rcx), %xmm5
    pmaxub -129(%rdx), %xmm4
    pmaxub 0(%rsp), %xmm1
    pmaxub -1(%rsp), %xmm2
    pmaxub -2147483648(%rsp), %xmm3
    pmaxub 0(%rcx,%rbx,8), %xmm6
    pmaxub 64(%rax,%rbp,1), %xmm7
    pmaxub 2147483647(%rcx,%rsi,2), %xmm5
    pmaxub gnu_fwd(%rip), %xmm4
    pmaxub 4660, %xmm1
    pminud %xmm15, %xmm6
    pminud 0(%rdx), %xmm9
    pminud 8(%r14), %xmm10
    pminud 128(%r15), %xmm11
    pminud 0(%r12), %xmm14
    pminud -128(%rsp), %xmm8
    pminud -129(%r12), %xmm12
    pminud 0(%r12,%rbp,4), %xmm13
    pminud 127(%rsp,%r12,8), %xmm15
    pminud -2147483648(%r13,%rax,1), %xmm9
    pminud gnu_back(%rip), %xmm10
    pminud 2147483647, %xmm11
    pminud %xmm2, %xmm3
    pminud 0(%rdi), %xmm6
    pminud -1(%rbx), %xmm7
    pminud 4660(%rbp), %xmm5
    pminud 0(%rsp), %xmm4
    pminud 64(%rsp), %xmm1
    pminud 128(%rsp), %xmm2
    pminud 0(%rdx,%rdi,2), %xmm3
    pminud 8(%rdx,%rax,4), %xmm6
    pminud -129(%rbx,%rcx,8), %xmm7
    pminud gnu_fwd(%rip), %xmm5
    pminud -2147483648, %xmm4
    paddb %xmm14, %xmm14
    paddb 0(%r9), %xmm8
    paddb -128(%rcx), %xmm12
    paddb 2147483647(%r8), %xmm13
    paddb 0(%rsp), %xmm15
    paddb 127(%r12), %xmm9
    paddb 4660(%rsp), %xmm10
    paddb 0(%rdx,%r15,1), %xmm11
    paddb -1(%rbp,%rsi,2), %xmm14
    paddb 128(%r12,%rcx,4), %xmm8
    paddb gnu_back(%rip), %xmm12
    paddb -129, %xmm13
    paddb %xmm1, %xmm2
    paddb 0(%rcx), %xmm3
    paddb 64(%rsi), %xmm6
    paddb -2147483648(%rdi), %xmm7
    paddb 0(%rsp), %xmm5
    paddb 8(%rsp), %xmm4
    paddb 2147483647(%rsp), %xmm1
    paddb 0(%rbx,%rdx,8), %xmm2
    paddb -128(%rsp,%rbx,1), %xmm3
    paddb 4660(%rbp,%rbp,2), %xmm6
    paddb gnu_fwd(%rip), %xmm7
    paddb 128, %xmm5
    psubb %xmm15, %xmm7
    psubb 0(%rbx), %xmm9
    psubb 127(%rbp), %xmm10
    psubb -129(%r13), %xmm11
    psubb 0(%r12), %xmm14
    psubb -1(%rsp), %xmm8
    psubb -2147483648(%r12), %xmm12
    psubb 0(%r9,%r9,4), %xmm13
    psubb 64(%rdi,%rbp,8), %xmm15
    psubb 2147483647(%r15,%r12,1), %xmm9
    psubb gnu_back(%rip), %xmm10
    psubb 4660, %xmm11
    psubb %xmm4, %xmm1
    psubb 0(%rdx), %xmm2
    psubb 8(%rcx), %xmm3
    psubb 128(%rdx), %xmm6
    psubb 0(%rsp), %xmm7
    psubb -128(%rsp), %xmm5
    psubb -129(%rsp), %xmm4
    psubb 0(%rsp,%rsi,2), %xmm1
    psubb 127(%rsi,%rdi,4), %xmm2
    psubb -2147483648(%rdi,%rax,8), %xmm3
    psubb gnu_fwd(%rip), %xmm6
    psubb 2147483647, %xmm7
    pand %xmm14, %xmm15
    pand 0(%r10), %xmm8
    pand -1(%rdx), %xmm12
    pand 4660(%r9), %xmm13
    pand 0(%rsp), %xmm15
    pand 64(%r12), %xmm9
    pand 128(%rsp), %xmm10
    pand 0(%rsp,%rax,1), %xmm11
    pand 8(%rax,%r15,2), %xmm14
    pand -129(%r9,%rsi,4), %xmm8
    pand gnu_back(%rip), %xmm12
    pand -2147483648, %xmm13
    pand %xmm5, %xmm4
    pand 0(%rbx), %xmm1
    pand -128(%rbx), %xmm2
    pand 2147483647(%rbp), %xmm3
    pand 0(%rsp), %xmm6
    pand 127(%rsp), %xmm7
    pand 4660(%rsp), %xmm5
    pand 0(%rsi,%rcx,8), %xmm4
    pand -1(%rax,%rdx,1), %xmm1
    pand 128(%rcx,%rbx,2), %xmm2
    pand gnu_fwd(%rip), %xmm3
    pand -129, %xmm6
g38:
    pandn %xmm15, %xmm5
    pandn 0(%rsi), %xmm9
    pandn 64(%rbx), %xmm10
    pandn -2147483648(%r10), %xmm11
    pandn 0(%r12), %xmm14
    pandn 8(%rsp), %xmm8
    pandn 2147483647(%r12), %xmm12
    pandn 0(%r14,%rcx,4), %xmm13
    pandn -128(%rsp,%r9,8), %xmm15
    pandn 4660(%r13,%rbp,1), %xmm9
    pandn gnu_back(%rip), %xmm10
    pandn 128, %xmm11
    pandn %xmm7, %xmm5
    pandn 0(%rsi), %xmm4
    pandn 127(%rsi), %xmm1
    pandn -129(%rdi), %xmm2
    pandn 0(%rsp), %xmm3
    pandn -1(%rsp), %xmm6
    pandn -2147483648(%rsp), %xmm7
    pandn 0(%rdi,%rbp,2), %xmm5
    pandn 64(%rdx,%rsi,4), %xmm4
    pandn 2147483647(%rbx,%rdi,8), %xmm1
    pandn gnu_fwd(%rip), %xmm2
    pandn 4660, %xmm3
    por %xmm14, %xmm8
    por 0(%r11), %xmm8
    por 8(%rsi), %xmm12
    por 128(%r11), %xmm13
    por 0(%rsp), %xmm15
    por -128(%r12), %xmm9
    por -129(%rsp), %xmm10
    por 0(%rsi,%r12,1), %xmm11
    por 127(%rbp,%rax,2), %xmm14
    por -2147483648(%r12,%r15,4), %xmm8
    por gnu_back(%rip), %xmm12
    por 2147483647, %xmm13
    por %xmm6, %xmm7
    por 0(%rdi), %xmm5
    por -1(%rcx), %xmm4
    por 4660(%rdx), %xmm1
    por 0(%rsp), %xmm2
    por 64(%rsp), %xmm3
    por 128(%rsp), %xmm6
    por 0(%rax,%rax,8), %xmm7
    por 8(%rsp,%rcx,1), %xmm5
    por -129(%rbp,%rdx,2), %xmm4
    por gnu_fwd(%rip), %xmm1
    por -2147483648, %xmm2
    pxor %xmm15, %xmm1
    pxor 0(%rdi), %xmm9
    pxor -128(%rdi), %xmm10
    pxor 2147483647(%r14), %xmm11
    pxor 0(%r12), %xmm14
    pxor 127(%rsp), %xmm8
    pxor 4660(%r12), %xmm12
    pxor 0(%r15,%rsi,4), %xmm13
    pxor -1(%rdi,%rcx,8), %xmm15
    pxor 128(%r15,%r9,1), %xmm9
    pxor gnu_back(%rip), %xmm10
    pxor -129, %xmm11
    pxor %xmm3, %xmm6
    pxor 0(%rcx), %xmm7
    pxor 64(%rbx), %xmm5
    pxor -2147483648(%rbp), %xmm4
    pxor 0(%rsp), %xmm1
    pxor 8(%rsp), %xmm2
    pxor 2147483647(%rsp), %xmm3
    pxor 0(%rcx,%rbx,2), %xmm6
    pxor -128(%rsi,%rbp,4), %xmm7
    pxor 4660(%rdi,%rsi,8), %xmm5
    pxor gnu_fwd(%rip), %xmm4
    pxor 128, %xmm1
    punpcklbw %xmm14, %xmm9
    punpcklbw 0(%r14), %xmm8
    punpcklbw 127(%r15), %xmm12
    punpcklbw -129(%rcx), %xmm13
    punpcklbw 0(%rsp), %xmm15
    punpcklbw -1(%r12), %xmm9
    punpcklbw -2147483648(%rsp), %xmm10
    punpcklbw 0(%rax,%rbp,1), %xmm11
    punpcklbw 64(%rax,%r12,2), %xmm14
    punpcklbw 2147483647(%r9,%rax,4), %xmm8
    punpcklbw gnu_back(%rip), %xmm12
    punpcklbw 4660, %xmm13
    punpcklbw %xmm2, %xmm3
    punpcklbw 0(%rdx), %xmm6
    punpcklbw 8(%rsi), %xmm7
    punpcklbw 128(%rdi), %xmm5
    punpcklbw 0(%rsp), %xmm4
    punpcklbw -128(%rsp), %xmm1
    punpcklbw -129(%rsp), %xmm2
    punpcklbw 0(%rdx,%rdi,8), %xmm3
    punpcklbw 127(%rax,%rax,1), %xmm6
    punpcklbw -2147483648(%rcx,%rcx,2), %xmm7
    punpcklbw gnu_fwd(%rip), %xmm5
    punpcklbw 2147483647, %xmm4
    punpcklwd %xmm15, %xmm2
    punpcklwd 0(%r15), %xmm9
    punpcklwd -1(%r8), %xmm10
    punpcklwd 4660(%rbp), %xmm11
    punpcklwd 0(%r12), %xmm14
    punpcklwd 64(%rsp), %xmm8
    punpcklwd 128(%r12), %xmm12
    punpcklwd 0(%r8,%r15,4), %xmm13
    punpcklwd 8(%rsp,%rsi,8), %xmm15
    punpcklwd -129(%r13,%rcx,1), %xmm9
    punpcklwd gnu_back(%rip), %xmm10
    punpcklwd -2147483648, %xmm11
    punpcklwd %xmm1, %xmm2
    punpcklwd 0(%rbx), %xmm3
    punpcklwd -128(%rcx), %xmm6
    punpcklwd 2147483647(%rdx), %xmm7
    punpcklwd 0(%rsp), %xmm5
    punpcklwd 127(%rsp), %xmm4
    punpcklwd 4660(%rsp), %xmm1
    punpcklwd 0(%rbx,%rdx,2), %xmm2
    punpcklwd -1(%rdx,%rbx,4), %xmm3
    punpcklwd 128(%rbx,%rbp,8), %xmm6
    punpcklwd gnu_fwd(%rip), %xmm7
    punpcklwd -129, %xmm5
    punpckldq %xmm14, %xmm12
    punpckldq 0(%rcx), %xmm8
    punpckldq 64(%r13), %xmm12
    punpckldq -2147483648(%rdx), %xmm13
    punpckldq 0(%rsp), %xmm15
    punpckldq 8(%r12), %xmm9
    punpckldq 2147483647(%rsp), %xmm10
    punpckldq 0(%rcx,%r9,1), %xmm11
    punpckldq -128(%rbp,%rbp,2), %xmm14
    punpckldq 4660(%r12,%r12,4), %xmm8
    punpckldq gnu_back(%rip), %xmm12
    punpckldq 128, %xmm13
    punpckldq %xmm4, %xmm1
    punpckldq 0(%rsi), %xmm2
    punpckldq 127(%rbx), %xmm3
    punpckldq -129(%rbp), %xmm6
    punpckldq 0(%rsp), %xmm7
    punpckldq -1(%rsp), %xmm5
    punpckldq -2147483648(%rsp), %xmm4
    punpckldq 0(%rsp,%rsi,8), %xmm1
    punpckldq 64(%rsp,%rdi,1), %xmm2
    punpckldq 2147483647(%rbp,%rax,2), %xmm3
    punpckldq gnu_fwd(%rip), %xmm6
    punpckldq 4660, %xmm7
    movdqa %xmm15, %xmm3
    movdqa 0(%r8), %xmm9
    movdqa 8(%r9), %xmm10
    movdqa 128(%rbx), %xmm11
    movdqa 0(%r12), %xmm14
    movdqa -128(%rsp), %xmm8
    movdqa -129(%r12), %xmm12
    movdqa 0(%r12,%rax,4), %xmm13
    movdqa 127(%rdi,%r15,8), %xmm15
    movdqa -2147483648(%r15,%rsi,1), %xmm9
    movdqa gnu_back(%rip), %xmm10
    movdqa 2147483647, %xmm11
    movdqa %xmm5, %xmm4
    movdqa 0(%rdi), %xmm1
    movdqa -1(%rsi), %xmm2
    movdqa 4660(%rdi), %xmm3
    movdqa 0(%rsp), %xmm6
    movdqa 64(%rsp), %xmm7
    movdqa 128(%rsp), %xmm5
    movdqa 0(%rsi,%rcx,2), %xmm4
    movdqa 8(%rsi,%rdx,4), %xmm1
    movdqa -129(%rdi,%rbx,8), %xmm2
    movdqa gnu_fwd(%rip), %xmm3
    movdqa -2147483648, %xmm6
    movdqu 0(%rdx), %xmm14
    movdqu -128(%r10), %xmm8
    movdqu 2147483647(%rsi), %xmm12
    movdqu 0(%rsp), %xmm13
    movdqu 127(%r12), %xmm15
    movdqu 4660(%rsp), %xmm9
    movdqu 0(%rdx,%rcx,1), %xmm10
    movdqu -1(%rax,%r9,2), %xmm11
    movdqu 128(%r9,%rbp,4), %xmm14
    movdqu gnu_back(%rip), %xmm8
    movdqu -129, %xmm12
    movdqu %xmm7, %xmm5
    movdqu 0(%rcx), %xmm4
    movdqu 64(%rcx), %xmm1
    movdqu -2147483648(%rdx), %xmm2
    movdqu 0(%rsp), %xmm3
    movdqu 8(%rsp), %xmm6
    movdqu 2147483647(%rsp), %xmm7
    movdqu 0(%rdi,%rbp,8), %xmm5
    movdqu -128(%rax,%rsi,1), %xmm4
    movdqu 4660(%rcx,%rdi,2), %xmm1
    movdqu gnu_fwd(%rip), %xmm2
    movdqu 128, %xmm3
    movaps 0(%r9), %xmm13
    movaps 127(%r11), %xmm15
    movaps -129(%rdi), %xmm9
    movaps 0(%r12), %xmm10
    movaps -1(%rsp), %xmm11
    movaps -2147483648(%r12), %xmm14
    movaps 0(%r9,%r12,4), %xmm8
    movaps 64(%rsp,%rax,8), %xmm12
    movaps 2147483647(%r13,%r15,1), %xmm13
g39:
    movaps gnu_back(%rip), %xmm15
    movaps 4660, %xmm9
    movaps %xmm6, %xmm7
    movaps 0(%rdx), %xmm5
    movaps 8(%rbx), %xmm4
    movaps 128(%rbp), %xmm1
    movaps 0(%rsp), %xmm2
    movaps -128(%rsp), %xmm3
    movaps -129(%rsp), %xmm6
    movaps 0(%rax,%rax,2), %xmm7
    movaps 127(%rdx,%rcx,4), %xmm5
    movaps -2147483648(%rbx,%rdx,8), %xmm4
    movaps gnu_fwd(%rip), %xmm1
    movaps 2147483647, %xmm2
    movups %xmm10, %xmm13
    movups 0(%rbx), %xmm11
    movups -1(%r14), %xmm14
    movups 4660(%r15), %xmm8
    movups 0(%rsp), %xmm12
    movups 64(%r12), %xmm13
    movups 128(%rsp), %xmm15
    movups 0(%rsp,%rsi,1), %xmm9
    movups 8(%rbp,%rcx,2), %xmm10
    movups -129(%r12,%r9,4), %xmm11
    movups gnu_back(%rip), %xmm14
    movups -2147483648, %xmm8
    movups %xmm3, %xmm6
    movups 0(%rbx), %xmm7
    movups -128(%rsi), %xmm5
    movups 2147483647(%rdi), %xmm4
    movups 0(%rsp), %xmm1
    movups 127(%rsp), %xmm2
    movups 4660(%rsp), %xmm3
    movups 0(%rcx,%rbx,8), %xmm6
    movups -1(%rsp,%rbp,1), %xmm7
    movups 128(%rbp,%rsi,2), %xmm5
    movups gnu_fwd(%rip), %xmm4
    movups -129, %xmm1
    movdqa %xmm12, 0(%r10)
    movdqa %xmm13, 64(%rcx)
    movdqa %xmm15, -2147483648(%r8)
    movdqa %xmm9, 0(%r12)
    movdqa %xmm10, 8(%rsp)
    movdqa %xmm11, 2147483647(%r12)
    movdqa %xmm14, 0(%r14,%rbp,4)
    movdqa %xmm8, -128(%rdi,%r12,8)
    movdqa %xmm12, 4660(%r15,%rax,1)
    movdqa %xmm13, gnu_back(%rip)
    movdqa %xmm15, 128
    movdqa %xmm2, 0(%rsi)
    movdqa %xmm3, 127(%rcx)
    movdqa %xmm6, -129(%rdx)
    movdqa %xmm7, 0(%rsp)
    movdqa %xmm5, -1(%rsp)
    movdqa %xmm4, -2147483648(%rsp)
    movdqa %xmm1, 0(%rdx,%rdi,2)
    movdqa %xmm2, 64(%rsi,%rax,4)
    movdqa %xmm3, 2147483647(%rdi,%rcx,8)
    movdqa %xmm6, gnu_fwd(%rip)
    movdqa %xmm7, 4660
    movdqu %xmm9, 0(%rsi)
    movdqu %xmm10, 8(%rbp)
    movdqu %xmm11, 128(%r13)
    movdqu %xmm14, 0(%rsp)
    movdqu %xmm8, -128(%r12)
    movdqu %xmm12, -129(%rsp)
    movdqu %xmm13, 0(%rsi,%r15,1)
    movdqu %xmm15, 127(%rax,%rsi,2)
    movdqu %xmm9, -2147483648(%r9,%rcx,4)
    movdqu %xmm10, gnu_back(%rip)
    movdqu %xmm11, 2147483647
    movdqu %xmm5, 0(%rdi)
    movdqu %xmm4, -1(%rbx)
    movdqu %xmm1, 4660(%rbp)
    movdqu %xmm2, 0(%rsp)
    movdqu %xmm3, 64(%rsp)
    movdqu %xmm6, 128(%rsp)
    movdqu %xmm7, 0(%rbx,%rdx,8)
    movdqu %xmm5, 8(%rax,%rbx,1)
    movdqu %xmm4, -129(%rcx,%rbp,2)
    movdqu %xmm1, gnu_fwd(%rip)
    movdqu %xmm2, -2147483648
    movaps %xmm14, 0(%r11)
    movaps %xmm8, -128(%rdx)
    movaps %xmm12, 2147483647(%r9)
    movaps %xmm13, 0(%r12)
    movaps %xmm15, 127(%rsp)
    movaps %xmm9, 4660(%r12)
    movaps %xmm10, 0(%r15,%r9,4)
    movaps %xmm11, -1(%rsp,%rbp,8)
    movaps %xmm14, 128(%r13,%r12,1)
    movaps %xmm8, gnu_back(%rip)
    movaps %xmm12, -129
    movaps %xmm3, 0(%rcx)
    movaps %xmm6, 64(%rsi)
    movaps %xmm7, -2147483648(%rdi)
    movaps %xmm5, 0(%rsp)
    movaps %xmm4, 8(%rsp)
    movaps %xmm1, 2147483647(%rsp)
    movaps %xmm2, 0(%rsp,%rsi,2)
    movaps %xmm3, -128(%rdx,%rdi,4)
    movaps %xmm6, 4660(%rbx,%rax,8)
    movaps %xmm7, gnu_fwd(%rip)
    movaps %xmm5, 128
    movups %xmm13, 0(%rdi)
    movups %xmm15, 127(%rbx)
    movups %xmm9, -129(%r10)
    movups %xmm10, 0(%rsp)
    movups %xmm11, -1(%r12)
    movups %xmm14, -2147483648(%rsp)
    movups %xmm8, 0(%rax,%rax,1)
    movups %xmm12, 64(%rbp,%r15,2)
    movups %xmm13, 2147483647(%r12,%rsi,4)
    movups %xmm15, gnu_back(%rip)
    movups %xmm9, 4660
    movups %xmm4, 0(%rdx)
    movups %xmm1, 8(%rcx)
    movups %xmm2, 128(%rdx)
    movups %xmm3, 0(%rsp)
    movups %xmm6, -128(%rsp)
    movups %xmm7, -129(%rsp)
    movups %xmm5, 0(%rsi,%rcx,8)
    movups %xmm4, 127(%rsp,%rdx,1)
    movups %xmm1, -2147483648(%rbp,%rbx,2)
    movups %xmm2, gnu_fwd(%rip)
    movups %xmm3, 2147483647
    movntdq %xmm10, 0(%r14)
    movntdq %xmm11, -1(%rsi)
    movntdq %xmm14, 4660(%r11)
    movntdq %xmm8, 0(%r12)
    movntdq %xmm12, 64(%rsp)
    movntdq %xmm13, 128(%r12)
    movntdq %xmm15, 0(%r8,%rcx,4)
    movntdq %xmm9, 8(%rdi,%r9,8)
    movntdq %xmm10, -129(%r15,%rbp,1)
    movntdq %xmm11, gnu_back(%rip)
    movntdq %xmm14, -2147483648
    movntdq %xmm6, 0(%rbx)
    movntdq %xmm7, -128(%rbx)
    movntdq %xmm5, 2147483647(%rbp)
    movntdq %xmm4, 0(%rsp)
    movntdq %xmm1, 127(%rsp)
    movntdq %xmm2, 4660(%rsp)
    movntdq %xmm3, 0(%rdi,%rbp,2)
    movntdq %xmm6, -1(%rsi,%rsi,4)
    movntdq %xmm7, 128(%rdi,%rdi,8)
    movntdq %xmm5, gnu_fwd(%rip)
    movntdq %xmm4, -129
    movntps %xmm8, 0(%r15)
    movntps %xmm12, 64(%rdi)
    movntps %xmm13, -2147483648(%r14)
    movntps %xmm15, 0(%rsp)
    movntps %xmm9, 8(%r12)
    movntps %xmm10, 2147483647(%rsp)
    movntps %xmm11, 0(%rcx,%r12,1)
    movntps %xmm14, -128(%rax,%rax,2)
    movntps %xmm8, 4660(%r9,%r15,4)
    movntps %xmm12, gnu_back(%rip)
    movntps %xmm13, 128
    movntps %xmm1, 0(%rsi)
    movntps %xmm2, 127(%rsi)
    movntps %xmm3, -129(%rdi)
    movntps %xmm6, 0(%rsp)
    movntps %xmm7, -1(%rsp)
    movntps %xmm5, -2147483648(%rsp)
    movntps %xmm4, 0(%rax,%rax,8)
    movntps %xmm1, 64(%rax,%rcx,1)
    movntps %xmm2, 2147483647(%rcx,%rdx,2)
    movntps %xmm3, gnu_fwd(%rip)
    movntps %xmm6, 4660
    movhpd 0(%rcx), %xmm15
    movhpd 8(%r15), %xmm9
    movhpd 128(%rcx), %xmm10
    movhpd 0(%r12), %xmm11
    movhpd -128(%rsp), %xmm14
    movhpd -129(%r12), %xmm8
    movhpd 0(%r12,%rsi,4), %xmm12
    movhpd 127(%rsp,%rcx,8), %xmm13
    movhpd -2147483648(%r13,%r9,1), %xmm15
    movhpd gnu_back(%rip), %xmm9
    movhpd 2147483647, %xmm10
    movhpd 0(%rdi), %xmm7
    movhpd -1(%rcx), %xmm5
    movhpd 4660(%rdx), %xmm4
    movhpd 0(%rsp), %xmm1
    movhpd 64(%rsp), %xmm2
    movhpd 128(%rsp), %xmm3
    movhpd 0(%rcx,%rbx,2), %xmm6
    movhpd 8(%rdx,%rbp,4), %xmm7
    movhpd -129(%rbx,%rsi,8), %xmm5
    movhpd gnu_fwd(%rip), %xmm4
    movhpd -2147483648, %xmm1
    movlpd 0(%r8), %xmm11
    movlpd -128(%r8), %xmm14
    movlpd 2147483647(%rbp), %xmm8
    movlpd 0(%rsp), %xmm12
    movlpd 127(%r12), %xmm13
    movlpd 4660(%rsp), %xmm15
    movlpd 0(%rdx,%rbp,1), %xmm9
    movlpd -1(%rbp,%r12,2), %xmm10
g40:
    movlpd 128(%r12,%rax,4), %xmm11
    movlpd gnu_back(%rip), %xmm14
    movlpd -129, %xmm8
    movlpd 0(%rcx), %xmm2
    movlpd 64(%rbx), %xmm3
    movlpd -2147483648(%rbp), %xmm6
    movlpd 0(%rsp), %xmm7
    movlpd 8(%rsp), %xmm5
    movlpd 2147483647(%rsp), %xmm4
    movlpd 0(%rdx,%rdi,8), %xmm1
    movlpd -128(%rsp,%rax,1), %xmm2
    movlpd 4660(%rbp,%rcx,2), %xmm3
    movlpd gnu_fwd(%rip), %xmm6
    movlpd 128, %xmm7
    pshufd $63, %xmm12, %xmm6
    pshufd $7, 0(%rdx), %xmm13
    pshufd $0, 127(%r13), %xmm15
    pshufd $255, -129(%rdx), %xmm9
    pshufd $63, 0(%r12), %xmm10
    pshufd $7, -1(%rsp), %xmm11
    pshufd $0, -2147483648(%r12), %xmm14
    pshufd $255, 0(%r9,%r15,4), %xmm8
    pshufd $63, 64(%rdi,%rsi,8), %xmm12
    pshufd $7, 2147483647(%r15,%rcx,1), %xmm13
    pshufd $0, gnu_back(%rip), %xmm15
    pshufd $255, 4660, %xmm9
    pshufd $63, %xmm5, %xmm4
    pshufd $7, 0(%rdx), %xmm1
    pshufd $0, 8(%rsi), %xmm2
    pshufd $255, 128(%rdi), %xmm3
    pshufd $63, 0(%rsp), %xmm6
    pshufd $7, -128(%rsp), %xmm7
    pshufd $0, -129(%rsp), %xmm5
    pshufd $255, 0(%rbx,%rdx,2), %xmm4
    pshufd $63, 127(%rsi,%rbx,4), %xmm1
    pshufd $7, -2147483648(%rdi,%rbp,8), %xmm2
    pshufd $0, gnu_fwd(%rip), %xmm3
    pshufd $255, 2147483647, %xmm6
    palignr $63, %xmm10, %xmm14
    palignr $7, 0(%r9), %xmm11
    palignr $0, -1(%r9), %xmm14
    palignr $255, 4660(%rbx), %xmm8
    palignr $63, 0(%rsp), %xmm12
    palignr $7, 64(%r12), %xmm13
    palignr $0, 128(%rsp), %xmm15
    palignr $255, 0(%rsp,%r9,1), %xmm9
    palignr $63, 8(%rax,%rbp,2), %xmm10
    palignr $7, -129(%r9,%r12,4), %xmm11
    palignr $0, gnu_back(%rip), %xmm14
    palignr $255, -2147483648, %xmm8
    palignr $63, %xmm7, %xmm5
    palignr $7, 0(%rbx), %xmm4
    palignr $0, -128(%rcx), %xmm1
    palignr $255, 2147483647(%rdx), %xmm2
    palignr $63, 0(%rsp), %xmm3
    palignr $7, 127(%rsp), %xmm6
    palignr $0, 4660(%rsp), %xmm7
    palignr $255, 0(%rsp,%rsi,8), %xmm5
    palignr $63, -1(%rax,%rdi,1), %xmm4
    palignr $7, 128(%rcx,%rax,2), %xmm1
    palignr $0, gnu_fwd(%rip), %xmm2
    palignr $255, -129, %xmm3
    pcmpistri $63, %xmm12, %xmm7
    pcmpistri $7, 0(%rbx), %xmm13
    pcmpistri $0, 64(%r10), %xmm15
    pcmpistri $255, -2147483648(%rsi), %xmm9
    pcmpistri $63, 0(%r12), %xmm10
    pcmpistri $7, 8(%rsp), %xmm11
    pcmpistri $0, 2147483647(%r12), %xmm14
    pcmpistri $255, 0(%r14,%rax,4), %xmm8
    pcmpistri $63, -128(%rsp,%r15,8), %xmm12
    pcmpistri $7, 4660(%r13,%rsi,1), %xmm13
    pcmpistri $0, gnu_back(%rip), %xmm15
    pcmpistri $255, 128, %xmm9
    pcmpistri $63, %xmm6, %xmm7
    pcmpistri $7, 0(%rsi), %xmm5
    pcmpistri $0, 127(%rbx), %xmm4
    pcmpistri $255, -129(%rbp), %xmm1
    pcmpistri $63, 0(%rsp), %xmm2
    pcmpistri $7, -1(%rsp), %xmm3
    pcmpistri $0, -2147483648(%rsp), %xmm6
    pcmpistri $255, 0(%rsi,%rcx,2), %xmm7
    pcmpistri $63, 64(%rdx,%rdx,4), %xmm5
    pcmpistri $7, 2147483647(%rbx,%rbx,8), %xmm4
    pcmpistri $0, gnu_fwd(%rip), %xmm1
    pcmpistri $255, 4660, %xmm2
    roundsd $63, %xmm10, %xmm15
    roundsd $7, 0(%r10), %xmm11
    roundsd $0, 8(%r11), %xmm14
    roundsd $255, 128(%rdi), %xmm8
    roundsd $63, 0(%rsp), %xmm12
    roundsd $7, -128(%r12), %xmm13
    roundsd $0, -129(%rsp), %xmm15
    roundsd $255, 0(%rsi,%rcx,1), %xmm9
    roundsd $63, 127(%rbp,%r9,2), %xmm10
    roundsd $7, -2147483648(%r12,%rbp,4), %xmm11
    roundsd $0, gnu_back(%rip), %xmm14
    roundsd $255, 2147483647, %xmm8
    roundsd $63, %xmm3, %xmm6
    roundsd $7, 0(%rdi), %xmm7
    roundsd $0, -1(%rsi), %xmm5
    roundsd $255, 4660(%rdi), %xmm4
    roundsd $63, 0(%rsp), %xmm1
    roundsd $7, 64(%rsp), %xmm2
    roundsd $0, 128(%rsp), %xmm3
    roundsd $255, 0(%rdi,%rbp,8), %xmm6
    roundsd $63, 8(%rsp,%rsi,1), %xmm7
    roundsd $7, -129(%rbp,%rdi,2), %xmm5
    roundsd $0, gnu_fwd(%rip), %xmm4
    roundsd $255, -2147483648, %xmm1
    roundss $63, %xmm12, %xmm5
    roundss $7, 0(%rsi), %xmm13
    roundss $0, -128(%r14), %xmm15
    roundss $255, 2147483647(%r15), %xmm9
    roundss $63, 0(%r12), %xmm10
    roundss $7, 127(%rsp), %xmm11
    roundss $0, 4660(%r12), %xmm14
    roundss $255, 0(%r15,%r12,4), %xmm8
    roundss $63, -1(%rdi,%rax,8), %xmm12
    roundss $7, 128(%r15,%r15,1), %xmm13
    roundss $0, gnu_back(%rip), %xmm15
    roundss $255, -129, %xmm9
    roundss $63, %xmm2, %xmm3
    roundss $7, 0(%rcx), %xmm6
    roundss $0, 64(%rcx), %xmm7
    roundss $255, -2147483648(%rdx), %xmm5
    roundss $63, 0(%rsp), %xmm4
    roundss $7, 8(%rsp), %xmm1
    roundss $0, 2147483647(%rsp), %xmm2
    roundss $255, 0(%rax,%rax,2), %xmm3
    roundss $63, -128(%rsi,%rcx,4), %xmm6
    roundss $7, 4660(%rdi,%rdx,8), %xmm7
    roundss $0, gnu_fwd(%rip), %xmm5
    roundss $255, 128, %xmm4
    pslldq $63, %xmm10
    pslldq $7, %xmm1
    psrldq $0, %xmm11
    psrldq $255, %xmm2
    pmovmskb %xmm14, %r8d
    pmovmskb %xmm3, %esi
    movd %edi, %xmm5
    movd %xmm4, %ecx
    cvtsd2si %xmm8, %rcx
    cvtss2si %xmm12, %r9
    movq 0(%r11), %xmm13
    movq 127(%rcx), %xmm15
    movq -129(%r8), %xmm9
    movq 0(%rsp), %xmm10
    movq -1(%r12), %xmm11
    movq -2147483648(%rsp), %xmm14
    movq 0(%rax,%rsi,1), %xmm8
    movq 64(%rax,%rcx,2), %xmm12
    movq 2147483647(%r9,%r9,4), %xmm13
    movq gnu_back(%rip), %xmm15
    movq 4660, %xmm9
    movq 0(%rdx), %xmm2
    movq 8(%rbx), %xmm3
    movq 128(%rbp), %xmm6
    movq 0(%rsp), %xmm7
    movq -128(%rsp), %xmm5
    movq -129(%rsp), %xmm4
    movq 0(%rcx,%rbx,8), %xmm1
    movq 127(%rax,%rbp,1), %xmm2
    movq -2147483648(%rcx,%rsi,2), %xmm3
    movq gnu_fwd(%rip), %xmm6
    movq 2147483647, %xmm7
    movq %xmm10, 0(%rdi)
    movq %xmm11, -1(%rbp)
    movq %xmm14, 4660(%r13)
    movq %xmm8, 0(%r12)
    movq %xmm12, 64(%rsp)
    movq %xmm13, 128(%r12)
    movq %xmm15, 0(%r8,%rbp,4)
    movq %xmm9, 8(%rsp,%r12,8)
    movq %xmm10, -129(%r13,%rax,1)
    movq %xmm11, gnu_back(%rip)
    movq %xmm14, -2147483648
    movq %xmm5, 0(%rbx)
    movq %xmm4, -128(%rsi)
    movq %xmm1, 2147483647(%rdi)
    movq %xmm2, 0(%rsp)
    movq %xmm3, 127(%rsp)
    movq %xmm6, 4660(%rsp)
    movq %xmm7, 0(%rdx,%rdi,2)
    movq %xmm5, -1(%rdx,%rax,4)
    movq %xmm4, 128(%rbx,%rcx,8)
    movq %xmm1, gnu_fwd(%rip)
    movq %xmm2, -129
    addsd 0(%r14), %xmm8
    addsd 64(%rdx), %xmm12
    addsd -2147483648(%r9), %xmm13
    addsd 0(%rsp), %xmm15
    addsd 8(%r12), %xmm9
    addsd 2147483647(%rsp), %xmm10
    addsd 0(%rcx,%r15,1), %xmm11
    addsd -128(%rbp,%rsi,2), %xmm14
    addsd 4660(%r12,%rcx,4), %xmm8
    addsd gnu_back(%rip), %xmm12
    addsd 128, %xmm13
    addsd %xmm3, %xmm6
g41:
    addsd 0(%rsi), %xmm7
    addsd 127(%rcx), %xmm5
    addsd -129(%rdx), %xmm4
    addsd 0(%rsp), %xmm1
    addsd -1(%rsp), %xmm2
    addsd -2147483648(%rsp), %xmm3
    addsd 0(%rbx,%rdx,8), %xmm6
    addsd 64(%rsp,%rbx,1), %xmm7
    addsd 2147483647(%rbp,%rbp,2), %xmm5
    addsd gnu_fwd(%rip), %xmm4
    addsd 4660, %xmm1
    addss 0(%r15), %xmm15
    addss 8(%rbx), %xmm9
    addss 128(%r10), %xmm10
    addss 0(%r12), %xmm11
    addss -128(%rsp), %xmm14
    addss -129(%r12), %xmm8
    addss 0(%r12,%r9,4), %xmm12
    addss 127(%rdi,%rbp,8), %xmm13
    addss -2147483648(%r15,%r12,1), %xmm15
    addss gnu_back(%rip), %xmm9
    addss 2147483647, %xmm10
    addss %xmm2, %xmm3
    addss 0(%rdi), %xmm6
    addss -1(%rbx), %xmm7
    addss 4660(%rbp), %xmm5
    addss 0(%rsp), %xmm4
    addss 64(%rsp), %xmm1
    addss 128(%rsp), %xmm2
    addss 0(%rsp,%rsi,2), %xmm3
    addss 8(%rsi,%rdi,4), %xmm6
    addss -129(%rdi,%rax,8), %xmm7
    addss gnu_fwd(%rip), %xmm5
    addss -2147483648, %xmm4
    addpd %xmm11, %xmm2
    addpd 0(%rcx), %xmm14
    addpd -128(%rsi), %xmm8
    addpd 2147483647(%r11), %xmm12
    addpd 0(%rsp), %xmm13
    addpd 127(%r12), %xmm15
    addpd 4660(%rsp), %xmm9
    addpd 0(%rdx,%rax,1), %xmm10
    addpd -1(%rax,%r15,2), %xmm11
    addpd 128(%r9,%rsi,4), %xmm14
    addpd gnu_back(%rip), %xmm8
    addpd -129, %xmm12
    addpd %xmm1, %xmm2
    addpd 0(%rcx), %xmm3
    addpd 64(%rsi), %xmm6
    addpd -2147483648(%rdi), %xmm7
    addpd 0(%rsp), %xmm5
    addpd 8(%rsp), %xmm4
    addpd 2147483647(%rsp), %xmm1
    addpd 0(%rsi,%rcx,8), %xmm2
    addpd -128(%rax,%rdx,1), %xmm3
    addpd 4660(%rcx,%rbx,2), %xmm6
    addpd gnu_fwd(%rip), %xmm7
    addpd 128, %xmm5
    addps %xmm13, %xmm12
    addps 0(%r8), %xmm15
    addps 127(%rdi), %xmm9
    addps -129(%r14), %xmm10
    addps 0(%r12), %xmm11
    addps -1(%rsp), %xmm14
    addps -2147483648(%r12), %xmm8
    addps 0(%r9,%rcx,4), %xmm12
    addps 64(%rsp,%r9,8), %xmm13
    addps 2147483647(%r13,%rbp,1), %xmm15
    addps gnu_back(%rip), %xmm9
    addps 4660, %xmm10
    addps %xmm4, %xmm1
    addps 0(%rdx), %xmm2
    addps 8(%rcx), %xmm3
    addps 128(%rdx), %xmm6
    addps 0(%rsp), %xmm7
    addps -128(%rsp), %xmm5
    addps -129(%rsp), %xmm4
    addps 0(%rdi,%rbp,2), %xmm1
    addps 127(%rdx,%rsi,4), %xmm2
    addps -2147483648(%rbx,%rdi,8), %xmm3
    addps gnu_fwd(%rip), %xmm6
    addps 2147483647, %xmm7
    subsd 0(%rdx), %xmm11
    subsd -1(%r15), %xmm14
    subsd 4660(%rcx), %xmm8
    subsd 0(%rsp), %xmm12
    subsd 64(%r12), %xmm13
    subsd 128(%rsp), %xmm15
    subsd 0(%rsp,%r12,1), %xmm9
    subsd 8(%rbp,%rax,2), %xmm10
    subsd -129(%r12,%r15,4), %xmm11
    subsd gnu_back(%rip), %xmm14
    subsd -2147483648, %xmm8
    subsd %xmm5, %xmm4
    subsd 0(%rbx), %xmm1
    subsd -128(%rbx), %xmm2
    subsd 2147483647(%rbp), %xmm3
    subsd 0(%rsp), %xmm6
    subsd 127(%rsp), %xmm7
    subsd 4660(%rsp), %xmm5
    subsd 0(%rax,%rax,8), %xmm4
    subsd -1(%rsp,%rcx,1), %xmm1
    subsd 128(%rbp,%rdx,2), %xmm2
    subsd gnu_fwd(%rip), %xmm3
    subsd -129, %xmm6
    subss 0(%r9), %xmm12
    subss 64(%r8), %xmm13
    subss -2147483648(%rbp), %xmm15
    subss 0(%r12), %xmm9
    subss 8(%rsp), %xmm10
    subss 2147483647(%r12), %xmm11
    subss 0(%r14,%rsi,4), %xmm14
    subss -128(%rdi,%rcx,8), %xmm8
    subss 4660(%r15,%r9,1), %xmm12
    subss gnu_back(%rip), %xmm13
    subss 128, %xmm15
    subss %xmm7, %xmm5
    subss 0(%rsi), %xmm4
    subss 127(%rsi), %xmm1
    subss -129(%rdi), %xmm2
    subss 0(%rsp), %xmm3
    subss -1(%rsp), %xmm6
    subss -2147483648(%rsp), %xmm7
    subss 0(%rcx,%rbx,2), %xmm5
    subss 64(%rsi,%rbp,4), %xmm4
    subss 2147483647(%rdi,%rsi,8), %xmm1
    subss gnu_fwd(%rip), %xmm2
    subss 4660, %xmm3
    subpd %xmm9, %xmm3
    subpd 0(%rbx), %xmm10
    subpd 8(%r13), %xmm11
    subpd 128(%rdx), %xmm14
    subpd 0(%rsp), %xmm8
    subpd -128(%r12), %xmm12
    subpd -129(%rsp), %xmm13
    subpd 0(%rsi,%rbp,1), %xmm15
    subpd 127(%rax,%r12,2), %xmm9
    subpd -2147483648(%r9,%rax,4), %xmm10
    subpd gnu_back(%rip), %xmm11
    subpd 2147483647, %xmm14
    subpd %xmm6, %xmm7
    subpd 0(%rdi), %xmm5
    subpd -1(%rcx), %xmm4
    subpd 4660(%rdx), %xmm1
    subpd 0(%rsp), %xmm2
    subpd 64(%rsp), %xmm3
    subpd 128(%rsp), %xmm6
    subpd 0(%rdx,%rdi,8), %xmm7
    subpd 8(%rax,%rax,1), %xmm5
    subpd -129(%rcx,%rcx,2), %xmm4
    subpd gnu_fwd(%rip), %xmm1
    subpd -2147483648, %xmm2
    subps %xmm8, %xmm13
    subps 0(%r10), %xmm12
    subps -128(%r9), %xmm13
    subps 2147483647(%rbx), %xmm15
    subps 0(%r12), %xmm9
    subps 127(%rsp), %xmm10
    subps 4660(%r12), %xmm11
    subps 0(%r15,%r15,4), %xmm14
    subps -1(%rsp,%rsi,8), %xmm8
    subps 128(%r13,%rcx,1), %xmm12
    subps gnu_back(%rip), %xmm13
    subps -129, %xmm15
    subps %xmm3, %xmm6
    subps 0(%rcx), %xmm7
    subps 64(%rbx), %xmm5
    subps -2147483648(%rbp), %xmm4
    subps 0(%rsp), %xmm1
    subps 8(%rsp), %xmm2
    subps 2147483647(%rsp), %xmm3
    subps 0(%rbx,%rdx,2), %xmm6
    subps -128(%rdx,%rbx,4), %xmm7
    subps 4660(%rbx,%rbp,8), %xmm5
    subps gnu_fwd(%rip), %xmm4
    subps 128, %xmm1
    mulsd 0(%rsi), %xmm9
    mulsd 127(%r10), %xmm10
    mulsd -129(%rsi), %xmm11
    mulsd 0(%rsp), %xmm14
    mulsd -1(%r12), %xmm8
    mulsd -2147483648(%rsp), %xmm12
    mulsd 0(%rax,%r9,1), %xmm13
    mulsd 64(%rbp,%rbp,2), %xmm15
    mulsd 2147483647(%r12,%r12,4), %xmm9
    mulsd gnu_back(%rip), %xmm10
    mulsd 4660, %xmm11
    mulsd %xmm2, %xmm3
    mulsd 0(%rdx), %xmm6
    mulsd 8(%rsi), %xmm7
    mulsd 128(%rdi), %xmm5
    mulsd 0(%rsp), %xmm4
    mulsd -128(%rsp), %xmm1
    mulsd -129(%rsp), %xmm2
    mulsd 0(%rsp,%rsi,8), %xmm3
    mulsd 127(%rsp,%rdi,1), %xmm6
    mulsd -2147483648(%rbp,%rax,2), %xmm7
    mulsd gnu_fwd(%rip), %xmm5
    mulsd 2147483647, %xmm4
    mulss 0(%r11), %xmm14
g42:
    mulss -1(%r11), %xmm8
    mulss 4660(%rdi), %xmm12
    mulss 0(%r12), %xmm13
    mulss 64(%rsp), %xmm15
    mulss 128(%r12), %xmm9
    mulss 0(%r8,%rax,4), %xmm10
    mulss 8(%rdi,%r15,8), %xmm11
    mulss -129(%r15,%rsi,1), %xmm14
    mulss gnu_back(%rip), %xmm8
    mulss -2147483648, %xmm12
    mulss %xmm1, %xmm2
    mulss 0(%rbx), %xmm3
    mulss -128(%rcx), %xmm6
    mulss 2147483647(%rdx), %xmm7
    mulss 0(%rsp), %xmm5
    mulss 127(%rsp), %xmm4
    mulss 4660(%rsp), %xmm1
    mulss 0(%rsi,%rcx,2), %xmm2
    mulss -1(%rsi,%rdx,4), %xmm3
    mulss 128(%rdi,%rbx,8), %xmm6
    mulss gnu_fwd(%rip), %xmm7
    mulss -129, %xmm5
    mulpd %xmm13, %xmm6
    mulpd 0(%rdi), %xmm15
    mulpd 64(%r14), %xmm9
    mulpd -2147483648(%r15), %xmm10
    mulpd 0(%rsp), %xmm11
    mulpd 8(%r12), %xmm14
    mulpd 2147483647(%rsp), %xmm8
    mulpd 0(%rcx,%rcx,1), %xmm12
    mulpd -128(%rax,%r9,2), %xmm13
    mulpd 4660(%r9,%rbp,4), %xmm15
    mulpd gnu_back(%rip), %xmm9
    mulpd 128, %xmm10
    mulpd %xmm4, %xmm1
    mulpd 0(%rsi), %xmm2
    mulpd 127(%rbx), %xmm3
    mulpd -129(%rbp), %xmm6
    mulpd 0(%rsp), %xmm7
    mulpd -1(%rsp), %xmm5
    mulpd -2147483648(%rsp), %xmm4
    mulpd 0(%rdi,%rbp,8), %xmm1
    mulpd 64(%rax,%rsi,1), %xmm2
    mulpd 2147483647(%rcx,%rdi,2), %xmm3
    mulpd gnu_fwd(%rip), %xmm6
    mulpd 4660, %xmm7
    mulps %xmm11, %xmm14
    mulps 0(%r14), %xmm14
    mulps 8(%rcx), %xmm8
    mulps 128(%r8), %xmm12
    mulps 0(%r12), %xmm13
    mulps -128(%rsp), %xmm15
    mulps -129(%r12), %xmm9
    mulps 0(%r12,%r12,4), %xmm10
    mulps 127(%rsp,%rax,8), %xmm11
    mulps -2147483648(%r13,%r15,1), %xmm14
    mulps gnu_back(%rip), %xmm8
    mulps 2147483647, %xmm12
    mulps %xmm5, %xmm4
    mulps 0(%rdi), %xmm1
    mulps -1(%rsi), %xmm2
    mulps 4660(%rdi), %xmm3
    mulps 0(%rsp), %xmm6
    mulps 64(%rsp), %xmm7
    mulps 128(%rsp), %xmm5
    mulps 0(%rax,%rax,2), %xmm4
    mulps 8(%rdx,%rcx,4), %xmm1
    mulps -129(%rbx,%rdx,8), %xmm2
    mulps gnu_fwd(%rip), %xmm3
    mulps -2147483648, %xmm6
    divsd 0(%r15), %xmm13
    divsd -128(%rbp), %xmm15
    divsd 2147483647(%r13), %xmm9
    divsd 0(%rsp), %xmm10
    divsd 127(%r12), %xmm11
    divsd 4660(%rsp), %xmm14
    divsd 0(%rdx,%rsi,1), %xmm8
    divsd -1(%rbp,%rcx,2), %xmm12
    divsd 128(%r12,%r9,4), %xmm13
    divsd gnu_back(%rip), %xmm15
    divsd -129, %xmm9
    divsd %xmm7, %xmm5
    divsd 0(%rcx), %xmm4
    divsd 64(%rcx), %xmm1
    divsd -2147483648(%rdx), %xmm2
    divsd 0(%rsp), %xmm3
    divsd 8(%rsp), %xmm6
    divsd 2147483647(%rsp), %xmm7
    divsd 0(%rcx,%rbx,8), %xmm5
    divsd -128(%rsp,%rbp,1), %xmm4
    divsd 4660(%rbp,%rsi,2), %xmm1
    divsd gnu_fwd(%rip), %xmm2
    divsd 128, %xmm3
    divss 0(%rcx), %xmm10
    divss 127(%rdx), %xmm11
    divss -129(%r9), %xmm14
    divss 0(%r12), %xmm8
    divss -1(%rsp), %xmm12
    divss -2147483648(%r12), %xmm13
    divss 0(%r9,%rbp,4), %xmm15
    divss 64(%rdi,%r12,8), %xmm9
    divss 2147483647(%r15,%rax,1), %xmm10
    divss gnu_back(%rip), %xmm11
    divss 4660, %xmm14
    divss %xmm6, %xmm7
    divss 0(%rdx), %xmm5
    divss 8(%rbx), %xmm4
    divss 128(%rbp), %xmm1
    divss 0(%rsp), %xmm2
    divss -128(%rsp), %xmm3
    divss -129(%rsp), %xmm6
    divss 0(%rdx,%rdi,2), %xmm7
    divss 127(%rsi,%rax,4), %xmm5
    divss -2147483648(%rdi,%rcx,8), %xmm4
    divss gnu_fwd(%rip), %xmm1
    divss 2147483647, %xmm2
    divpd %xmm8, %xmm7
    divpd 0(%r8), %xmm12
    divpd -1(%rbx), %xmm13
    divpd 4660(%r10), %xmm15
    divpd 0(%rsp), %xmm9
    divpd 64(%r12), %xmm10
    divpd 128(%rsp), %xmm11
    divpd 0(%rsp,%r15,1), %xmm14
    divpd 8(%rax,%rsi,2), %xmm8
    divpd -129(%r9,%rcx,4), %xmm12
    divpd gnu_back(%rip), %xmm13
    divpd -2147483648, %xmm15
    divpd %xmm3, %xmm6
    divpd 0(%rbx), %xmm7
    divpd -128(%rsi), %xmm5
    divpd 2147483647(%rdi), %xmm4
    divpd 0(%rsp), %xmm1
    divpd 127(%rsp), %xmm2
    divpd 4660(%rsp), %xmm3
    divpd 0(%rbx,%rdx,8), %xmm6
    divpd -1(%rax,%rbx,1), %xmm7
    divpd 128(%rcx,%rbp,2), %xmm5
    divpd gnu_fwd(%rip), %xmm4
    divpd -129, %xmm1
    divps %xmm9, %xmm15
    divps 0(%rdx), %xmm10
    divps 64(%rsi), %xmm11
    divps -2147483648(%r11), %xmm14
    divps 0(%r12), %xmm8
    divps 8(%rsp), %xmm12
    divps 2147483647(%r12), %xmm13
    divps 0(%r14,%r9,4), %xmm15
    divps -128(%rsp,%rbp,8), %xmm9
    divps 4660(%r13,%r12,1), %xmm10
    divps gnu_back(%rip), %xmm11
    divps 128, %xmm14
    divps %xmm2, %xmm3
    divps 0(%rsi), %xmm6
    divps 127(%rcx), %xmm7
    divps -129(%rdx), %xmm5
    divps 0(%rsp), %xmm4
    divps -1(%rsp), %xmm1
    divps -2147483648(%rsp), %xmm2
    divps 0(%rsp,%rsi,2), %xmm3
    divps 64(%rdx,%rdi,4), %xmm6
    divps 2147483647(%rbx,%rax,8), %xmm7
    divps gnu_fwd(%rip), %xmm5
    divps 4660, %xmm4
    sqrtsd 0(%r9), %xmm8
    sqrtsd 8(%rdi), %xmm12
    sqrtsd 128(%r14), %xmm13
    sqrtsd 0(%rsp), %xmm15
    sqrtsd -128(%r12), %xmm9
    sqrtsd -129(%rsp), %xmm10
    sqrtsd 0(%rsi,%rax,1), %xmm11
    sqrtsd 127(%rbp,%r15,2), %xmm14
    sqrtsd -2147483648(%r12,%rsi,4), %xmm8
    sqrtsd gnu_back(%rip), %xmm12
    sqrtsd 2147483647, %xmm13
    sqrtsd %xmm1, %xmm2
    sqrtsd 0(%rdi), %xmm3
    sqrtsd -1(%rbx), %xmm6
    sqrtsd 4660(%rbp), %xmm7
    sqrtsd 0(%rsp), %xmm5
    sqrtsd 64(%rsp), %xmm4
    sqrtsd 128(%rsp), %xmm1
    sqrtsd 0(%rsi,%rcx,8), %xmm2
    sqrtsd 8(%rsp,%rdx,1), %xmm3
    sqrtsd -129(%rbp,%rbx,2), %xmm6
    sqrtsd gnu_fwd(%rip), %xmm7
    sqrtsd -2147483648, %xmm5
    sqrtss 0(%rbx), %xmm15
    sqrtss -128(%r15), %xmm9
    sqrtss 2147483647(%rcx), %xmm10
    sqrtss 0(%r12), %xmm11
    sqrtss 127(%rsp), %xmm14
    sqrtss 4660(%r12), %xmm8
    sqrtss 0(%r15,%rcx,4), %xmm12
    sqrtss -1(%rdi,%r9,8), %xmm13
    sqrtss 128(%r15,%rbp,1), %xmm15
    sqrtss gnu_back(%rip), %xmm9
    sqrtss -129, %xmm10
    sqrtss %xmm4, %xmm1
    sqrtss 0(%rcx), %xmm2
g43:
    sqrtss 64(%rsi), %xmm3
    sqrtss -2147483648(%rdi), %xmm6
    sqrtss 0(%rsp), %xmm7
    sqrtss 8(%rsp), %xmm5
    sqrtss 2147483647(%rsp), %xmm4
    sqrtss 0(%rdi,%rbp,2), %xmm1
    sqrtss -128(%rsi,%rsi,4), %xmm2
    sqrtss 4660(%rdi,%rdi,8), %xmm3
    sqrtss gnu_fwd(%rip), %xmm6
    sqrtss 128, %xmm7
    sqrtpd %xmm11, %xmm5
    sqrtpd 0(%r10), %xmm14
    sqrtpd 127(%r8), %xmm8
    sqrtpd -129(%rbp), %xmm12
    sqrtpd 0(%rsp), %xmm13
    sqrtpd -1(%r12), %xmm15
    sqrtpd -2147483648(%rsp), %xmm9
    sqrtpd 0(%rax,%r12,1), %xmm10
    sqrtpd 64(%rax,%rax,2), %xmm11
    sqrtpd 2147483647(%r9,%r15,4), %xmm14
    sqrtpd gnu_back(%rip), %xmm8
    sqrtpd 4660, %xmm12
    sqrtpd %xmm5, %xmm4
    sqrtpd 0(%rdx), %xmm1
    sqrtpd 8(%rcx), %xmm2
    sqrtpd 128(%rdx), %xmm3
    sqrtpd 0(%rsp), %xmm6
    sqrtpd -128(%rsp), %xmm7
    sqrtpd -129(%rsp), %xmm5
    sqrtpd 0(%rax,%rax,8), %xmm4
    sqrtpd 127(%rax,%rcx,1), %xmm1
    sqrtpd -2147483648(%rcx,%rdx,2), %xmm2
    sqrtpd gnu_fwd(%rip), %xmm3
    sqrtpd 2147483647, %xmm6
    sqrtps %xmm13, %xmm8
    sqrtps 0(%rsi), %xmm15
    sqrtps -1(%r13), %xmm9
    sqrtps 4660(%rdx), %xmm10
    sqrtps 0(%r12), %xmm11
    sqrtps 64(%rsp), %xmm14
    sqrtps 128(%r12), %xmm8
    sqrtps 0(%r8,%rsi,4), %xmm12
    sqrtps 8(%rsp,%rcx,8), %xmm13
    sqrtps -129(%r13,%r9,1), %xmm15
    sqrtps gnu_back(%rip), %xmm9
    sqrtps -2147483648, %xmm10
    sqrtps %xmm7, %xmm5
    sqrtps 0(%rbx), %xmm4
    sqrtps -128(%rbx), %xmm1
    sqrtps 2147483647(%rbp), %xmm2
    sqrtps 0(%rsp), %xmm3
    sqrtps 127(%rsp), %xmm6
    sqrtps 4660(%rsp), %xmm7
    sqrtps 0(%rcx,%rbx,2), %xmm5
    sqrtps -1(%rdx,%rbp,4), %xmm4
    sqrtps 128(%rbx,%rsi,8), %xmm1
    sqrtps gnu_fwd(%rip), %xmm2
    sqrtps -129, %xmm3
    minsd 0(%r11), %xmm11
    minsd 64(%r9), %xmm14
    minsd -2147483648(%rbx), %xmm8
    minsd 0(%rsp), %xmm12
    minsd 8(%r12), %xmm13
    minsd 2147483647(%rsp), %xmm15
    minsd 0(%rcx,%rbp,1), %xmm9
    minsd -128(%rbp,%r12,2), %xmm10
    minsd 4660(%r12,%rax,4), %xmm11
    minsd gnu_back(%rip), %xmm14
    minsd 128, %xmm8
    minsd %xmm6, %xmm7
    minsd 0(%rsi), %xmm5
    minsd 127(%rsi), %xmm4
    minsd -129(%rdi), %xmm1
    minsd 0(%rsp), %xmm2
    minsd -1(%rsp), %xmm3
    minsd -2147483648(%rsp), %xmm6
    minsd 0(%rdx,%rdi,8), %xmm7
    minsd 64(%rsp,%rax,1), %xmm5
    minsd 2147483647(%rbp,%rcx,2), %xmm4
    minsd gnu_fwd(%rip), %xmm1
    minsd 4660, %xmm2
    minss 0(%rdi), %xmm12
    minss 8(%r10), %xmm13
    minss 128(%rsi), %xmm15
    minss 0(%r12), %xmm9
    minss -128(%rsp), %xmm10
    minss -129(%r12), %xmm11
    minss 0(%r12,%r15,4), %xmm14
    minss 127(%rdi,%rsi,8), %xmm8
    minss -2147483648(%r15,%rcx,1), %xmm12
    minss gnu_back(%rip), %xmm13
    minss 2147483647, %xmm15
    minss %xmm3, %xmm6
    minss 0(%rdi), %xmm7
    minss -1(%rcx), %xmm5
    minss 4660(%rdx), %xmm4
    minss 0(%rsp), %xmm1
    minss 64(%rsp), %xmm2
    minss 128(%rsp), %xmm3
    minss 0(%rbx,%rdx,2), %xmm6
    minss 8(%rsi,%rbx,4), %xmm7
    minss -129(%rdi,%rbp,8), %xmm5
    minss gnu_fwd(%rip), %xmm4
    minss -2147483648, %xmm1
    minpd %xmm9, %xmm1
    minpd 0(%r14), %xmm10
    minpd -128(%r11), %xmm11
    minpd 2147483647(%rdi), %xmm14
    minpd 0(%rsp), %xmm8
    minpd 127(%r12), %xmm12
    minpd 4660(%rsp), %xmm13
    minpd 0(%rdx,%r9,1), %xmm15
    minpd -1(%rax,%rbp,2), %xmm9
    minpd 128(%r9,%r12,4), %xmm10
    minpd gnu_back(%rip), %xmm11
    minpd -129, %xmm14
    minpd %xmm2, %xmm3
    minpd 0(%rcx), %xmm6
    minpd 64(%rbx), %xmm7
    minpd -2147483648(%rbp), %xmm5
    minpd 0(%rsp), %xmm4
    minpd 8(%rsp), %xmm1
    minpd 2147483647(%rsp), %xmm2
    minpd 0(%rsp,%rsi,8), %xmm3
    minpd -128(%rax,%rdi,1), %xmm6
    minpd 4660(%rcx,%rax,2), %xmm7
    minpd gnu_fwd(%rip), %xmm5
    minpd 128, %xmm4
    minps %xmm8, %xmm9
    minps 0(%r15), %xmm12
    minps 127(%r14), %xmm13
    minps -129(%r15), %xmm15
    minps 0(%r12), %xmm9
    minps -1(%rsp), %xmm10
    minps -2147483648(%r12), %xmm11
    minps 0(%r9,%rax,4), %xmm14
    minps 64(%rsp,%r15,8), %xmm8
    minps 2147483647(%r13,%rsi,1), %xmm12
    minps gnu_back(%rip), %xmm13
    minps 4660, %xmm15
    minps %xmm1, %xmm2
    minps 0(%rdx), %xmm3
    minps 8(%rsi), %xmm6
    minps 128(%rdi), %xmm7
    minps 0(%rsp), %xmm5
    minps -128(%rsp), %xmm4
    minps -129(%rsp), %xmm1
    minps 0(%rsi,%rcx,2), %xmm2
    minps 127(%rdx,%rdx,4), %xmm3
    minps -2147483648(%rbx,%rbx,8), %xmm6
    minps gnu_fwd(%rip), %xmm7
    minps 2147483647, %xmm5
    maxsd 0(%rcx), %xmm9
    maxsd -1(%rcx), %xmm10
    maxsd 4660(%r8), %xmm11
    maxsd 0(%rsp), %xmm14
    maxsd 64(%r12), %xmm8
    maxsd 128(%rsp), %xmm12
    maxsd 0(%rsp,%rcx,1), %xmm13
    maxsd 8(%rbp,%r9,2), %xmm15
    maxsd -129(%r12,%rbp,4), %xmm9
    maxsd gnu_back(%rip), %xmm10
    maxsd -2147483648, %xmm11
    maxsd %xmm4, %xmm1
    maxsd 0(%rbx), %xmm2
    maxsd -128(%rcx), %xmm3
    maxsd 2147483647(%rdx), %xmm6
    maxsd 0(%rsp), %xmm7
    maxsd 127(%rsp), %xmm5
    maxsd 4660(%rsp), %xmm4
    maxsd 0(%rdi,%rbp,8), %xmm1
    maxsd -1(%rsp,%rsi,1), %xmm2
    maxsd 128(%rbp,%rdi,2), %xmm3
    maxsd gnu_fwd(%rip), %xmm6
    maxsd -129, %xmm7
    maxss 0(%r8), %xmm14
    maxss 64(%rbp), %xmm8
    maxss -2147483648(%r13), %xmm12
    maxss 0(%r12), %xmm13
    maxss 8(%rsp), %xmm15
    maxss 2147483647(%r12), %xmm9
    maxss 0(%r14,%r12,4), %xmm10
    maxss -128(%rdi,%rax,8), %xmm11
    maxss 4660(%r15,%r15,1), %xmm14
    maxss gnu_back(%rip), %xmm8
    maxss 128, %xmm12
    maxss %xmm5, %xmm4
    maxss 0(%rsi), %xmm1
    maxss 127(%rbx), %xmm2
    maxss -129(%rbp), %xmm3
    maxss 0(%rsp), %xmm6
    maxss -1(%rsp), %xmm7
    maxss -2147483648(%rsp), %xmm5
    maxss 0(%rax,%rax,2), %xmm4
    maxss 64(%rsi,%rcx,4), %xmm1
    maxss 2147483647(%rdi,%rdx,8), %xmm2
    maxss gnu_fwd(%rip), %xmm3
    maxss 4660, %xmm6
    maxpd %xmm13, %xmm2
    maxpd 0(%rdx), %xmm15
g44:
    maxpd 8(%rdx), %xmm9
    maxpd 128(%r9), %xmm10
    maxpd 0(%rsp), %xmm11
    maxpd -128(%r12), %xmm14
    maxpd -129(%rsp), %xmm8
    maxpd 0(%rsi,%rsi,1), %xmm12
    maxpd 127(%rax,%rcx,2), %xmm13
    maxpd -2147483648(%r9,%r9,4), %xmm15
    maxpd gnu_back(%rip), %xmm9
    maxpd 2147483647, %xmm10
    maxpd %xmm7, %xmm5
    maxpd 0(%rdi), %xmm4
    maxpd -1(%rsi), %xmm1
    maxpd 4660(%rdi), %xmm2
    maxpd 0(%rsp), %xmm3
    maxpd 64(%rsp), %xmm6
    maxpd 128(%rsp), %xmm7
    maxpd 0(%rcx,%rbx,8), %xmm5
    maxpd 8(%rax,%rbp,1), %xmm4
    maxpd -129(%rcx,%rsi,2), %xmm1
    maxpd gnu_fwd(%rip), %xmm2
    maxpd -2147483648, %xmm3
    maxps %xmm11, %xmm12
    maxps 0(%r9), %xmm14
    maxps -128(%rbx), %xmm8
    maxps 2147483647(%r10), %xmm12
    maxps 0(%r12), %xmm13
    maxps 127(%rsp), %xmm15
    maxps 4660(%r12), %xmm9
    maxps 0(%r15,%rbp,4), %xmm10
    maxps -1(%rsp,%r12,8), %xmm11
    maxps 128(%r13,%rax,1), %xmm14
    maxps gnu_back(%rip), %xmm8
    maxps -129, %xmm12
    maxps %xmm6, %xmm7
    maxps 0(%rcx), %xmm5
    maxps 64(%rcx), %xmm4
    maxps -2147483648(%rdx), %xmm1
    maxps 0(%rsp), %xmm2
    maxps 8(%rsp), %xmm3
    maxps 2147483647(%rsp), %xmm6
    maxps 0(%rdx,%rdi,2), %xmm7
    maxps -128(%rdx,%rax,4), %xmm5
    maxps 4660(%rbx,%rcx,8), %xmm4
    maxps gnu_fwd(%rip), %xmm1
    maxps 128, %xmm2
    andpd 0(%rbx), %xmm13
    andpd 127(%rsi), %xmm15
    andpd -129(%r11), %xmm9
    andpd 0(%rsp), %xmm10
    andpd -1(%r12), %xmm11
    andpd -2147483648(%rsp), %xmm14
    andpd 0(%rax,%r15,1), %xmm8
    andpd 64(%rbp,%rsi,2), %xmm12
    andpd 2147483647(%r12,%rcx,4), %xmm13
    andpd gnu_back(%rip), %xmm15
    andpd 4660, %xmm9
    andpd %xmm3, %xmm6
    andpd 0(%rdx), %xmm7
    andpd 8(%rbx), %xmm5
    andpd 128(%rbp), %xmm4
    andpd 0(%rsp), %xmm1
    andpd -128(%rsp), %xmm2
    andpd -129(%rsp), %xmm3
    andpd 0(%rbx,%rdx,8), %xmm6
    andpd 127(%rsp,%rbx,1), %xmm7
    andpd -2147483648(%rbp,%rbp,2), %xmm5
    andpd gnu_fwd(%rip), %xmm4
    andpd 2147483647, %xmm1
    andps 0(%r10), %xmm10
    andps -1(%rdi), %xmm11
    andps 4660(%r14), %xmm14
    andps 0(%r12), %xmm8
    andps 64(%rsp), %xmm12
    andps 128(%r12), %xmm13
    andps 0(%r8,%r9,4), %xmm15
    andps 8(%rdi,%rbp,8), %xmm9
    andps -129(%r15,%r12,1), %xmm10
    andps gnu_back(%rip), %xmm11
    andps -2147483648, %xmm14
    andps %xmm2, %xmm3
    andps 0(%rbx), %xmm6
    andps -128(%rsi), %xmm7
    andps 2147483647(%rdi), %xmm5
    andps 0(%rsp), %xmm4
    andps 127(%rsp), %xmm1
    andps 4660(%rsp), %xmm2
    andps 0(%rsp,%rsi,2), %xmm3
    andps -1(%rsi,%rdi,4), %xmm6
    andps 128(%rdi,%rax,8), %xmm7
    andps gnu_fwd(%rip), %xmm5
    andps -129, %xmm4
    andnpd 0(%rsi), %xmm8
    andnpd 64(%r15), %xmm12
    andnpd -2147483648(%rcx), %xmm13
    andnpd 0(%rsp), %xmm15
    andnpd 8(%r12), %xmm9
    andnpd 2147483647(%rsp), %xmm10
    andnpd 0(%rcx,%rax,1), %xmm11
    andnpd -128(%rax,%r15,2), %xmm14
    andnpd 4660(%r9,%rsi,4), %xmm8
    andnpd gnu_back(%rip), %xmm12
    andnpd 128, %xmm13
    andnpd %xmm1, %xmm2
    andnpd 0(%rsi), %xmm3
    andnpd 127(%rcx), %xmm6
    andnpd -129(%rdx), %xmm7
    andnpd 0(%rsp), %xmm5
    andnpd -1(%rsp), %xmm4
    andnpd -2147483648(%rsp), %xmm1
    andnpd 0(%rsi,%rcx,8), %xmm2
    andnpd 64(%rax,%rdx,1), %xmm3
    andnpd 2147483647(%rcx,%rbx,2), %xmm6
    andnpd gnu_fwd(%rip), %xmm7
    andnpd 4660, %xmm5
    andnps 0(%r11), %xmm15
    andnps 8(%r8), %xmm9
    andnps 128(%rbp), %xmm10
    andnps 0(%r12), %xmm11
    andnps -128(%rsp), %xmm14
    andnps -129(%r12), %xmm8
    andnps 0(%r12,%rcx,4), %xmm12
    andnps 127(%rsp,%r9,8), %xmm13
    andnps -2147483648(%r13,%rbp,1), %xmm15
    andnps gnu_back(%rip), %xmm9
    andnps 2147483647, %xmm10
    andnps %xmm4, %xmm1
    andnps 0(%rdi), %xmm2
    andnps -1(%rbx), %xmm3
    andnps 4660(%rbp), %xmm6
    andnps 0(%rsp), %xmm7
    andnps 64(%rsp), %xmm5
    andnps 128(%rsp), %xmm4
    andnps 0(%rdi,%rbp,2), %xmm1
    andnps 8(%rdx,%rsi,4), %xmm2
    andnps -129(%rbx,%rdi,8), %xmm3
    andnps gnu_fwd(%rip), %xmm6
    andnps -2147483648, %xmm7
    orpd 0(%rdi), %xmm11
    orpd -128(%r13), %xmm14
    orpd 2147483647(%rdx), %xmm8
    orpd 0(%rsp), %xmm12
    orpd 127(%r12), %xmm13
    orpd 4660(%rsp), %xmm15
    orpd 0(%rdx,%r12,1), %xmm9
    orpd -1(%rbp,%rax,2), %xmm10
    orpd 128(%r12,%r15,4), %xmm11
    orpd gnu_back(%rip), %xmm14
    orpd -129, %xmm8
    orpd %xmm5, %xmm4
    orpd 0(%rcx), %xmm1
    orpd 64(%rsi), %xmm2
    orpd -2147483648(%rdi), %xmm3
    orpd 0(%rsp), %xmm6
    orpd 8(%rsp), %xmm7
    orpd 2147483647(%rsp), %xmm5
    orpd 0(%rax,%rax,8), %xmm4
    orpd -128(%rsp,%rcx,1), %xmm1
    orpd 4660(%rbp,%rdx,2), %xmm2
    orpd gnu_fwd(%rip), %xmm3
    orpd 128, %xmm6
    orps 0(%r14), %xmm12
    orps 127(%r9), %xmm13
    orps -129(%rbx), %xmm15
    orps 0(%r12), %xmm9
    orps -1(%rsp), %xmm10
    orps -2147483648(%r12), %xmm11
    orps 0(%r9,%rsi,4), %xmm14
    orps 64(%rdi,%rcx,8), %xmm8
    orps 2147483647(%r15,%r9,1), %xmm12
    orps gnu_back(%rip), %xmm13
    orps 4660, %xmm15
    orps %xmm7, %xmm5
    orps 0(%rdx), %xmm4
    orps 8(%rcx), %xmm1
    orps 128(%rdx), %xmm2
    orps 0(%rsp), %xmm3
    orps -128(%rsp), %xmm6
    orps -129(%rsp), %xmm7
    orps 0(%rcx,%rbx,2), %xmm5
    orps 127(%rsi,%rbp,4), %xmm4
    orps -2147483648(%rdi,%rsi,8), %xmm1
    orps gnu_fwd(%rip), %xmm2
    orps 2147483647, %xmm3
    xorpd 0(%r15), %xmm9
    xorpd -1(%r10), %xmm10
    xorpd 4660(%rsi), %xmm11
    xorpd 0(%rsp), %xmm14
    xorpd 64(%r12), %xmm8
    xorpd 128(%rsp), %xmm12
    xorpd 0(%rsp,%rbp,1), %xmm13
    xorpd 8(%rax,%r12,2), %xmm15
    xorpd -129(%r9,%rax,4), %xmm9
    xorpd gnu_back(%rip), %xmm10
    xorpd -2147483648, %xmm11
    xorpd %xmm6, %xmm7
    xorpd 0(%rbx), %xmm5
    xorpd -128(%rbx), %xmm4
    xorpd 2147483647(%rbp), %xmm1
    xorpd 0(%rsp), %xmm2
g45:
    xorpd 127(%rsp), %xmm3
    xorpd 4660(%rsp), %xmm6
    xorpd 0(%rdx,%rdi,8), %xmm7
    xorpd -1(%rax,%rax,1), %xmm5
    xorpd 128(%rcx,%rcx,2), %xmm4
    xorpd gnu_fwd(%rip), %xmm1
    xorpd -129, %xmm2
    xorps 0(%rcx), %xmm14
    xorps 64(%r11), %xmm8
    xorps -2147483648(%rdi), %xmm12
    xorps 0(%r12), %xmm13
    xorps 8(%rsp), %xmm15
    xorps 2147483647(%r12), %xmm9
    xorps 0(%r14,%r15,4), %xmm10
    xorps -128(%rsp,%rsi,8), %xmm11
    xorps 4660(%r13,%rcx,1), %xmm14
    xorps gnu_back(%rip), %xmm8
    xorps 128, %xmm12
    xorps %xmm3, %xmm6
    xorps 0(%rsi), %xmm7
    xorps 127(%rsi), %xmm5
    xorps -129(%rdi), %xmm4
    xorps 0(%rsp), %xmm1
    xorps -1(%rsp), %xmm2
    xorps -2147483648(%rsp), %xmm3
    xorps 0(%rbx,%rdx,2), %xmm6
    xorps 64(%rdx,%rbx,4), %xmm7
    xorps 2147483647(%rbx,%rbp,8), %xmm5
    xorps gnu_fwd(%rip), %xmm4
    xorps 4660, %xmm1
    movsd 0(%r8), %xmm13
    movsd 8(%r14), %xmm15
    movsd 128(%r15), %xmm9
    movsd 0(%rsp), %xmm10
    movsd -128(%r12), %xmm11
    movsd -129(%rsp), %xmm14
    movsd 0(%rsi,%r9,1), %xmm8
    movsd 127(%rbp,%rbp,2), %xmm12
    movsd -2147483648(%r12,%r12,4), %xmm13
    movsd gnu_back(%rip), %xmm15
    movsd 2147483647, %xmm9
    movsd %xmm2, %xmm3
    movsd 0(%rdi), %xmm6
    movsd -1(%rcx), %xmm7
    movsd 4660(%rdx), %xmm5
    movsd 0(%rsp), %xmm4
    movsd 64(%rsp), %xmm1
    movsd 128(%rsp), %xmm2
    movsd 0(%rsp,%rsi,8), %xmm3
    movsd 8(%rsp,%rdi,1), %xmm6
    movsd -129(%rbp,%rax,2), %xmm7
    movsd gnu_fwd(%rip), %xmm5
    movsd -2147483648, %xmm4
    movss 0(%rdx), %xmm10
    movss -128(%rcx), %xmm11
    movss 2147483647(%r8), %xmm14
    movss 0(%r12), %xmm8
    movss 127(%rsp), %xmm12
    movss 4660(%r12), %xmm13
    movss 0(%r15,%rax,4), %xmm15
    movss -1(%rdi,%r15,8), %xmm9
    movss 128(%r15,%rsi,1), %xmm10
    movss gnu_back(%rip), %xmm11
    movss -129, %xmm14
    movss %xmm1, %xmm2
    movss 0(%rcx), %xmm3
    movss 64(%rbx), %xmm6
    movss -2147483648(%rbp), %xmm7
    movss 0(%rsp), %xmm5
    movss 8(%rsp), %xmm4
    movss 2147483647(%rsp), %xmm1
    movss 0(%rsi,%rcx,2), %xmm2
    movss -128(%rsi,%rdx,4), %xmm3
    movss 4660(%rdi,%rbx,8), %xmm6
    movss gnu_fwd(%rip), %xmm7
    movss 128, %xmm5
    movapd 0(%r9), %xmm8
    movapd 127(%rbp), %xmm12
    movapd -129(%r13), %xmm13
    movapd 0(%rsp), %xmm15
    movapd -1(%r12), %xmm9
    movapd -2147483648(%rsp), %xmm10
    movapd 0(%rax,%rcx,1), %xmm11
    movapd 64(%rax,%r9,2), %xmm14
    movapd 2147483647(%r9,%rbp,4), %xmm8
    movapd gnu_back(%rip), %xmm12
    movapd 4660, %xmm13
    movapd %xmm4, %xmm1
    movapd 0(%rdx), %xmm2
    movapd 8(%rsi), %xmm3
    movapd 128(%rdi), %xmm6
    movapd 0(%rsp), %xmm7
    movapd -128(%rsp), %xmm5
    movapd -129(%rsp), %xmm4
    movapd 0(%rdi,%rbp,8), %xmm1
    movapd 127(%rax,%rsi,1), %xmm2
    movapd -2147483648(%rcx,%rdi,2), %xmm3
    movapd gnu_fwd(%rip), %xmm6
    movapd 2147483647, %xmm7
    movupd %xmm15, %xmm3
    movupd 0(%rbx), %xmm9
    movupd -1(%rdx), %xmm10
    movupd 4660(%r9), %xmm11
    movupd 0(%r12), %xmm14
    movupd 64(%rsp), %xmm8
    movupd 128(%r12), %xmm12
    movupd 0(%r8,%r12,4), %xmm13
    movupd 8(%rsp,%rax,8), %xmm15
    movupd -129(%r13,%r15,1), %xmm9
    movupd gnu_back(%rip), %xmm10
    movupd -2147483648, %xmm11
    movupd %xmm5, %xmm4
    movupd 0(%rbx), %xmm1
    movupd -128(%rcx), %xmm2
    movupd 2147483647(%rdx), %xmm3
    movupd 0(%rsp), %xmm6
    movupd 127(%rsp), %xmm7
    movupd 4660(%rsp), %xmm5
    movupd 0(%rax,%rax,2), %xmm4
    movupd -1(%rdx,%rcx,4), %xmm1
    movupd 128(%rbx,%rdx,8), %xmm2
    movupd gnu_fwd(%rip), %xmm3
    movupd -129, %xmm6
    cvtss2sd 0(%r10), %xmm14
    cvtss2sd 64(%rbx), %xmm8
    cvtss2sd -2147483648(%r10), %xmm12
    cvtss2sd 0(%rsp), %xmm13
    cvtss2sd 8(%r12), %xmm15
    cvtss2sd 2147483647(%rsp), %xmm9
    cvtss2sd 0(%rcx,%rsi,1), %xmm10
    cvtss2sd -128(%rbp,%rcx,2), %xmm11
    cvtss2sd 4660(%r12,%r9,4), %xmm14
    cvtss2sd gnu_back(%rip), %xmm8
    cvtss2sd 128, %xmm12
    cvtss2sd %xmm7, %xmm5
    cvtss2sd 0(%rsi), %xmm4
    cvtss2sd 127(%rbx), %xmm1
    cvtss2sd -129(%rbp), %xmm2
    cvtss2sd 0(%rsp), %xmm3
    cvtss2sd -1(%rsp), %xmm6
    cvtss2sd -2147483648(%rsp), %xmm7
    cvtss2sd 0(%rcx,%rbx,8), %xmm5
    cvtss2sd 64(%rsp,%rbp,1), %xmm4
    cvtss2sd 2147483647(%rbp,%rsi,2), %xmm1
    cvtss2sd gnu_fwd(%rip), %xmm2
    cvtss2sd 4660, %xmm3
    cvtsd2ss 0(%rsi), %xmm13
    cvtsd2ss 8(%rsi), %xmm15
    cvtsd2ss 128(%r11), %xmm9
    cvtsd2ss 0(%r12), %xmm10
    cvtsd2ss -128(%rsp), %xmm11
    cvtsd2ss -129(%r12), %xmm14
    cvtsd2ss 0(%r12,%rbp,4), %xmm8
    cvtsd2ss 127(%rdi,%r12,8), %xmm12
    cvtsd2ss -2147483648(%r15,%rax,1), %xmm13
    cvtsd2ss gnu_back(%rip), %xmm15
    cvtsd2ss 2147483647, %xmm9
    cvtsd2ss %xmm6, %xmm7
    cvtsd2ss 0(%rdi), %xmm5
    cvtsd2ss -1(%rsi), %xmm4
    cvtsd2ss 4660(%rdi), %xmm1
    cvtsd2ss 0(%rsp), %xmm2
    cvtsd2ss 64(%rsp), %xmm3
    cvtsd2ss 128(%rsp), %xmm6
    cvtsd2ss 0(%rdx,%rdi,2), %xmm7
    cvtsd2ss 8(%rsi,%rax,4), %xmm5
    cvtsd2ss -129(%rdi,%rcx,8), %xmm4
    cvtsd2ss gnu_fwd(%rip), %xmm1
    cvtsd2ss -2147483648, %xmm2
    cvtps2pd %xmm10, %xmm13
    cvtps2pd 0(%r11), %xmm11
    cvtps2pd -128(%rdi), %xmm14
    cvtps2pd 2147483647(%r14), %xmm8
    cvtps2pd 0(%rsp), %xmm12
    cvtps2pd 127(%r12), %xmm13
    cvtps2pd 4660(%rsp), %xmm15
    cvtps2pd 0(%rdx,%r15,1), %xmm9
    cvtps2pd -1(%rax,%rsi,2), %xmm10
    cvtps2pd 128(%r9,%rcx,4), %xmm11
    cvtps2pd gnu_back(%rip), %xmm14
    cvtps2pd -129, %xmm8
    cvtps2pd %xmm3, %xmm6
    cvtps2pd 0(%rcx), %xmm7
    cvtps2pd 64(%rcx), %xmm5
    cvtps2pd -2147483648(%rdx), %xmm4
    cvtps2pd 0(%rsp), %xmm1
    cvtps2pd 8(%rsp), %xmm2
    cvtps2pd 2147483647(%rsp), %xmm3
    cvtps2pd 0(%rbx,%rdx,8), %xmm6
    cvtps2pd -128(%rax,%rbx,1), %xmm7
    cvtps2pd 4660(%rcx,%rbp,2), %xmm5
    cvtps2pd gnu_fwd(%rip), %xmm4
    cvtps2pd 128, %xmm1
    cvtpd2ps %xmm12, %xmm6
    cvtpd2ps 0(%rdi), %xmm13
    cvtpd2ps 127(%r15), %xmm15
    cvtpd2ps -129(%rcx), %xmm9
    cvtpd2ps 0(%r12), %xmm10
    cvtpd2ps -1(%rsp), %xmm11
    cvtpd2ps -2147483648(%r12), %xmm14
g46:
    cvtpd2ps 0(%r9,%r9,4), %xmm8
    cvtpd2ps 64(%rsp,%rbp,8), %xmm12
    cvtpd2ps 2147483647(%r13,%r12,1), %xmm13
    cvtpd2ps gnu_back(%rip), %xmm15
    cvtpd2ps 4660, %xmm9
    cvtpd2ps %xmm2, %xmm3
    cvtpd2ps 0(%rdx), %xmm6
    cvtpd2ps 8(%rbx), %xmm7
    cvtpd2ps 128(%rbp), %xmm5
    cvtpd2ps 0(%rsp), %xmm4
    cvtpd2ps -128(%rsp), %xmm1
    cvtpd2ps -129(%rsp), %xmm2
    cvtpd2ps 0(%rsp,%rsi,2), %xmm3
    cvtpd2ps 127(%rdx,%rdi,4), %xmm6
    cvtpd2ps -2147483648(%rbx,%rax,8), %xmm7
    cvtpd2ps gnu_fwd(%rip), %xmm5
    cvtpd2ps 2147483647, %xmm4
    ucomisd 0(%r14), %xmm10
    ucomisd -1(%r8), %xmm11
    ucomisd 4660(%rbp), %xmm14
    ucomisd 0(%rsp), %xmm8
    ucomisd 64(%r12), %xmm12
    ucomisd 128(%rsp), %xmm13
    ucomisd 0(%rsp,%rax,1), %xmm15
    ucomisd 8(%rbp,%r15,2), %xmm9
    ucomisd -129(%r12,%rsi,4), %xmm10
    ucomisd gnu_back(%rip), %xmm11
    ucomisd -2147483648, %xmm14
    ucomisd %xmm1, %xmm2
    ucomisd 0(%rbx), %xmm3
    ucomisd -128(%rsi), %xmm6
    ucomisd 2147483647(%rdi), %xmm7
    ucomisd 0(%rsp), %xmm5
    ucomisd 127(%rsp), %xmm4
    ucomisd 4660(%rsp), %xmm1
    ucomisd 0(%rsi,%rcx,8), %xmm2
    ucomisd -1(%rsp,%rdx,1), %xmm3
    ucomisd 128(%rbp,%rbx,2), %xmm6
    ucomisd gnu_fwd(%rip), %xmm7
    ucomisd -129, %xmm5
    ucomiss 0(%r15), %xmm8
    ucomiss 64(%r13), %xmm12
    ucomiss -2147483648(%rdx), %xmm13
    ucomiss 0(%r12), %xmm15
    ucomiss 8(%rsp), %xmm9
    ucomiss 2147483647(%r12), %xmm10
    ucomiss 0(%r14,%rcx,4), %xmm11
    ucomiss -128(%rdi,%r9,8), %xmm14
    ucomiss 4660(%r15,%rbp,1), %xmm8
    ucomiss gnu_back(%rip), %xmm12
    ucomiss 128, %xmm13
    ucomiss %xmm4, %xmm1
    ucomiss 0(%rsi), %xmm2
    ucomiss 127(%rcx), %xmm3
    ucomiss -129(%rdx), %xmm6
    ucomiss 0(%rsp), %xmm7
    ucomiss -1(%rsp), %xmm5
    ucomiss -2147483648(%rsp), %xmm4
    ucomiss 0(%rdi,%rbp,2), %xmm1
    ucomiss 64(%rsi,%rsi,4), %xmm2
    ucomiss 2147483647(%rdi,%rdi,8), %xmm3
    ucomiss gnu_fwd(%rip), %xmm6
    ucomiss 4660, %xmm7
    comisd 0(%rcx), %xmm15
    comisd 8(%r9), %xmm9
    comisd 128(%rbx), %xmm10
    comisd 0(%rsp), %xmm11
    comisd -128(%r12), %xmm14
    comisd -129(%rsp), %xmm8
    comisd 0(%rsi,%r12,1), %xmm12
    comisd 127(%rax,%rax,2), %xmm13
    comisd -2147483648(%r9,%r15,4), %xmm15
    comisd gnu_back(%rip), %xmm9
    comisd 2147483647, %xmm10
    comisd %xmm5, %xmm4
    comisd 0(%rdi), %xmm1
    comisd -1(%rbx), %xmm2
    comisd 4660(%rbp), %xmm3
    comisd 0(%rsp), %xmm6
    comisd 64(%rsp), %xmm7
    comisd 128(%rsp), %xmm5
    comisd 0(%rax,%rax,8), %xmm4
    comisd 8(%rax,%rcx,1), %xmm1
    comisd -129(%rcx,%rdx,2), %xmm2
    comisd gnu_fwd(%rip), %xmm3
    comisd -2147483648, %xmm6
    comiss 0(%r8), %xmm11
    comiss -128(%r10), %xmm14
    comiss 2147483647(%rsi), %xmm8
    comiss 0(%r12), %xmm12
    comiss 127(%rsp), %xmm13
    comiss 4660(%r12), %xmm15
    comiss 0(%r15,%rsi,4), %xmm9
    comiss -1(%rsp,%rcx,8), %xmm10
    comiss 128(%r13,%r9,1), %xmm11
    comiss gnu_back(%rip), %xmm14
    comiss -129, %xmm8
    comiss %xmm7, %xmm5
    comiss 0(%rcx), %xmm4
    comiss 64(%rsi), %xmm1
    comiss -2147483648(%rdi), %xmm2
    comiss 0(%rsp), %xmm3
    comiss 8(%rsp), %xmm6
    comiss 2147483647(%rsp), %xmm7
    comiss 0(%rcx,%rbx,2), %xmm5
    comiss -128(%rdx,%rbp,4), %xmm4
    comiss 4660(%rbx,%rsi,8), %xmm1
    comiss gnu_fwd(%rip), %xmm2
    comiss 128, %xmm3
    unpcklpd %xmm12, %xmm14
    unpcklpd 0(%rdx), %xmm13
    unpcklpd 127(%r11), %xmm15
    unpcklpd -129(%rdi), %xmm9
    unpcklpd 0(%rsp), %xmm10
    unpcklpd -1(%r12), %xmm11
    unpcklpd -2147483648(%rsp), %xmm14
    unpcklpd 0(%rax,%rbp,1), %xmm8
    unpcklpd 64(%rbp,%r12,2), %xmm12
    unpcklpd 2147483647(%r12,%rax,4), %xmm13
    unpcklpd gnu_back(%rip), %xmm15
    unpcklpd 4660, %xmm9
    unpcklpd %xmm6, %xmm7
    unpcklpd 0(%rdx), %xmm5
    unpcklpd 8(%rcx), %xmm4
    unpcklpd 128(%rdx), %xmm1
    unpcklpd 0(%rsp), %xmm2
    unpcklpd -128(%rsp), %xmm3
    unpcklpd -129(%rsp), %xmm6
    unpcklpd 0(%rdx,%rdi,8), %xmm7
    unpcklpd 127(%rsp,%rax,1), %xmm5
    unpcklpd -2147483648(%rbp,%rcx,2), %xmm4
    unpcklpd gnu_fwd(%rip), %xmm1
    unpcklpd 2147483647, %xmm2
    unpcklps %xmm10, %xmm7
    unpcklps 0(%r9), %xmm11
    unpcklps -1(%r14), %xmm14
    unpcklps 4660(%r15), %xmm8
    unpcklps 0(%r12), %xmm12
    unpcklps 64(%rsp), %xmm13
    unpcklps 128(%r12), %xmm15
    unpcklps 0(%r8,%r15,4), %xmm9
    unpcklps 8(%rdi,%rsi,8), %xmm10
    unpcklps -129(%r15,%rcx,1), %xmm11
    unpcklps gnu_back(%rip), %xmm14
    unpcklps -2147483648, %xmm8
    unpcklps %xmm3, %xmm6
    unpcklps 0(%rbx), %xmm7
    unpcklps -128(%rbx), %xmm5
    unpcklps 2147483647(%rbp), %xmm4
    unpcklps 0(%rsp), %xmm1
    unpcklps 127(%rsp), %xmm2
    unpcklps 4660(%rsp), %xmm3
    unpcklps 0(%rbx,%rdx,2), %xmm6
    unpcklps -1(%rsi,%rbx,4), %xmm7
    unpcklps 128(%rdi,%rbp,8), %xmm5
    unpcklps gnu_fwd(%rip), %xmm4
    unpcklps -129, %xmm1
    unpckhpd %xmm12, %xmm15
    unpckhpd 0(%rbx), %xmm13
    unpckhpd 64(%rcx), %xmm15
    unpckhpd -2147483648(%r8), %xmm9
    unpckhpd 0(%rsp), %xmm10
    unpckhpd 8(%r12), %xmm11
    unpckhpd 2147483647(%rsp), %xmm14
    unpckhpd 0(%rcx,%r9,1), %xmm8
    unpckhpd -128(%rax,%rbp,2), %xmm12
    unpckhpd 4660(%r9,%r12,4), %xmm13
    unpckhpd gnu_back(%rip), %xmm15
    unpckhpd 128, %xmm9
    unpckhpd %xmm2, %xmm3
    unpckhpd 0(%rsi), %xmm6
    unpckhpd 127(%rsi), %xmm7
    unpckhpd -129(%rdi), %xmm5
    unpckhpd 0(%rsp), %xmm4
    unpckhpd -1(%rsp), %xmm1
    unpckhpd -2147483648(%rsp), %xmm2
    unpckhpd 0(%rsp,%rsi,8), %xmm3
    unpckhpd 64(%rax,%rdi,1), %xmm6
    unpckhpd 2147483647(%rcx,%rax,2), %xmm7
    unpckhpd gnu_fwd(%rip), %xmm5
    unpckhpd 4660, %xmm4
    unpckhps %xmm10, %xmm5
    unpckhps 0(%r10), %xmm11
    unpckhps 8(%rbp), %xmm14
    unpckhps 128(%r13), %xmm8
    unpckhps 0(%r12), %xmm12
    unpckhps -128(%rsp), %xmm13
    unpckhps -129(%r12), %xmm15
    unpckhps 0(%r12,%rax,4), %xmm9
    unpckhps 127(%rsp,%r15,8), %xmm10
    unpckhps -2147483648(%r13,%rsi,1), %xmm11
    unpckhps gnu_back(%rip), %xmm14
    unpckhps 2147483647, %xmm8
    unpckhps %xmm1, %xmm2
    unpckhps 0(%rdi), %xmm3
    unpckhps -1(%rcx), %xmm6
    unpckhps 4660(%rdx), %xmm7
    unpckhps 0(%rsp), %xmm5
    unpckhps 64(%rsp), %xmm4
    unpckhps 128(%rsp), %xmm1
g47:
    unpckhps 0(%rsi,%rcx,2), %xmm2
    unpckhps 8(%rdx,%rdx,4), %xmm3
    unpckhps -129(%rbx,%rbx,8), %xmm6
    unpckhps gnu_fwd(%rip), %xmm7
    unpckhps -2147483648, %xmm5
    punpcklqdq %xmm12, %xmm8
    punpcklqdq 0(%rsi), %xmm13
    punpcklqdq -128(%rdx), %xmm15
    punpcklqdq 2147483647(%r9), %xmm9
    punpcklqdq 0(%rsp), %xmm10
    punpcklqdq 127(%r12), %xmm11
    punpcklqdq 4660(%rsp), %xmm14
    punpcklqdq 0(%rdx,%rcx,1), %xmm8
    punpcklqdq -1(%rbp,%r9,2), %xmm12
    punpcklqdq 128(%r12,%rbp,4), %xmm13
    punpcklqdq gnu_back(%rip), %xmm15
    punpcklqdq -129, %xmm9
    punpcklqdq %xmm4, %xmm1
    punpcklqdq 0(%rcx), %xmm2
    punpcklqdq 64(%rbx), %xmm3
    punpcklqdq -2147483648(%rbp), %xmm6
    punpcklqdq 0(%rsp), %xmm7
    punpcklqdq 8(%rsp), %xmm5
    punpcklqdq 2147483647(%rsp), %xmm4
    punpcklqdq 0(%rdi,%rbp,8), %xmm1
    punpcklqdq -128(%rsp,%rsi,1), %xmm2
    punpcklqdq 4660(%rbp,%rdi,2), %xmm3
    punpcklqdq gnu_fwd(%rip), %xmm6
    punpcklqdq 128, %xmm7
    punpckhqdq %xmm10, %xmm1
    punpckhqdq 0(%r11), %xmm11
    punpckhqdq 127(%rbx), %xmm14
    punpckhqdq -129(%r10), %xmm8
    punpckhqdq 0(%r12), %xmm12
    punpckhqdq -1(%rsp), %xmm13
    punpckhqdq -2147483648(%r12), %xmm15
    punpckhqdq 0(%r9,%r12,4), %xmm9
    punpckhqdq 64(%rdi,%rax,8), %xmm10
    punpckhqdq 2147483647(%r15,%r15,1), %xmm11
    punpckhqdq gnu_back(%rip), %xmm14
    punpckhqdq 4660, %xmm8
    punpckhqdq %xmm5, %xmm4
    punpckhqdq 0(%rdx), %xmm1
    punpckhqdq 8(%rsi), %xmm2
    punpckhqdq 128(%rdi), %xmm3
    punpckhqdq 0(%rsp), %xmm6
    punpckhqdq -128(%rsp), %xmm7
    punpckhqdq -129(%rsp), %xmm5
    punpckhqdq 0(%rax,%rax,2), %xmm4
    punpckhqdq 127(%rsi,%rcx,4), %xmm1
    punpckhqdq -2147483648(%rdi,%rdx,8), %xmm2
    punpckhqdq gnu_fwd(%rip), %xmm3
    punpckhqdq 2147483647, %xmm6
    paddd %xmm12, %xmm9
    paddd 0(%rdi), %xmm13
    paddd -1(%rsi), %xmm15
    paddd 4660(%r11), %xmm9
    paddd 0(%rsp), %xmm10
    paddd 64(%r12), %xmm11
    paddd 128(%rsp), %xmm14
    paddd 0(%rsp,%rsi,1), %xmm8
    paddd 8(%rax,%rcx,2), %xmm12
    paddd -129(%r9,%r9,4), %xmm13
    paddd gnu_back(%rip), %xmm15
    paddd -2147483648, %xmm9
    paddd %xmm7, %xmm5
    paddd 0(%rbx), %xmm4
    paddd -128(%rcx), %xmm1
    paddd 2147483647(%rdx), %xmm2
    paddd 0(%rsp), %xmm3
    paddd 127(%rsp), %xmm6
    paddd 4660(%rsp), %xmm7
    paddd 0(%rcx,%rbx,8), %xmm5
    paddd -1(%rax,%rbp,1), %xmm4
    paddd 128(%rcx,%rsi,2), %xmm1
    paddd gnu_fwd(%rip), %xmm2
    paddd -129, %xmm3
    paddq %xmm10, %xmm2
    paddq 0(%r14), %xmm11
    paddq 64(%rdi), %xmm14
    paddq -2147483648(%r14), %xmm8
    paddq 0(%r12), %xmm12
    paddq 8(%rsp), %xmm13
    paddq 2147483647(%r12), %xmm15
    paddq 0(%r14,%rbp,4), %xmm9
    paddq -128(%rsp,%r12,8), %xmm10
    paddq 4660(%r13,%rax,1), %xmm11
    paddq gnu_back(%rip), %xmm14
    paddq 128, %xmm8
    paddq %xmm6, %xmm7
    paddq 0(%rsi), %xmm5
    paddq 127(%rbx), %xmm4
    paddq -129(%rbp), %xmm1
    paddq 0(%rsp), %xmm2
    paddq -1(%rsp), %xmm3
    paddq -2147483648(%rsp), %xmm6
    paddq 0(%rdx,%rdi,2), %xmm7
    paddq 64(%rdx,%rax,4), %xmm5
    paddq 2147483647(%rbx,%rcx,8), %xmm4
    paddq gnu_fwd(%rip), %xmm1
    paddq 4660, %xmm2
    psubd %xmm12, %xmm12
    psubd 0(%r15), %xmm13
    psubd 8(%r15), %xmm15
    psubd 128(%rcx), %xmm9
    psubd 0(%rsp), %xmm10
    psubd -128(%r12), %xmm11
    psubd -129(%rsp), %xmm14
    psubd 0(%rsi,%r15,1), %xmm8
    psubd 127(%rbp,%rsi,2), %xmm12
    psubd -2147483648(%r12,%rcx,4), %xmm13
    psubd gnu_back(%rip), %xmm15
    psubd 2147483647, %xmm9
    psubd %xmm3, %xmm6
    psubd 0(%rdi), %xmm7
    psubd -1(%rsi), %xmm5
    psubd 4660(%rdi), %xmm4
    psubd 0(%rsp), %xmm1
    psubd 64(%rsp), %xmm2
    psubd 128(%rsp), %xmm3
    psubd 0(%rbx,%rdx,8), %xmm6
    psubd 8(%rsp,%rbx,1), %xmm7
    psubd -129(%rbp,%rbp,2), %xmm5
    psubd gnu_fwd(%rip), %xmm4
    psubd -2147483648, %xmm1
    psubq %xmm10, %xmm3
    psubq 0(%rcx), %xmm11
    psubq -128(%r8), %xmm14
    psubq 2147483647(%rbp), %xmm8
    psubq 0(%r12), %xmm12
    psubq 127(%rsp), %xmm13
    psubq 4660(%r12), %xmm15
    psubq 0(%r15,%r9,4), %xmm9
    psubq -1(%rdi,%rbp,8), %xmm10
    psubq 128(%r15,%r12,1), %xmm11
    psubq gnu_back(%rip), %xmm14
    psubq -129, %xmm8
    psubq %xmm2, %xmm3
    psubq 0(%rcx), %xmm6
    psubq 64(%rcx), %xmm7
    psubq -2147483648(%rdx), %xmm5
    psubq 0(%rsp), %xmm4
    psubq 8(%rsp), %xmm1
    psubq 2147483647(%rsp), %xmm2
    psubq 0(%rsp,%rsi,2), %xmm3
    psubq -128(%rsi,%rdi,4), %xmm6
    psubq 4660(%rdi,%rax,8), %xmm7
    psubq gnu_fwd(%rip), %xmm5
    psubq 128, %xmm4
    movsd %xmm12, 0(%r8)
    movsd %xmm13, 127(%r13)
    movsd %xmm15, -129(%rdx)
    movsd %xmm9, 0(%rsp)
    movsd %xmm10, -1(%r12)
    movsd %xmm11, -2147483648(%rsp)
    movsd %xmm14, 0(%rax,%rax,1)
    movsd %xmm8, 64(%rax,%r15,2)
    movsd %xmm12, 2147483647(%r9,%rsi,4)
    movsd %xmm13, gnu_back(%rip)
    movsd %xmm15, 4660
    movsd %xmm1, 0(%rdx)
    movsd %xmm2, 8(%rbx)
    movsd %xmm3, 128(%rbp)
    movsd %xmm6, 0(%rsp)
    movsd %xmm7, -128(%rsp)
    movsd %xmm5, -129(%rsp)
    movsd %xmm4, 0(%rsi,%rcx,8)
    movsd %xmm1, 127(%rax,%rdx,1)
    movsd %xmm2, -2147483648(%rcx,%rbx,2)
    movsd %xmm3, gnu_fwd(%rip)
    movsd %xmm6, 2147483647
    movss %xmm9, 0(%rdx)
    movss %xmm10, -1(%r9)
    movss %xmm11, 4660(%rbx)
    movss %xmm14, 0(%r12)
    movss %xmm8, 64(%rsp)
    movss %xmm12, 128(%r12)
    movss %xmm13, 0(%r8,%rcx,4)
    movss %xmm15, 8(%rsp,%r9,8)
    movss %xmm9, -129(%r13,%rbp,1)
    movss %xmm10, gnu_back(%rip)
    movss %xmm11, -2147483648
    movss %xmm7, 0(%rbx)
    movss %xmm5, -128(%rsi)
    movss %xmm4, 2147483647(%rdi)
    movss %xmm1, 0(%rsp)
    movss %xmm2, 127(%rsp)
    movss %xmm3, 4660(%rsp)
    movss %xmm6, 0(%rdi,%rbp,2)
    movss %xmm7, -1(%rdx,%rsi,4)
    movss %xmm5, 128(%rbx,%rdi,8)
    movss %xmm4, gnu_fwd(%rip)
    movss %xmm1, -129
    movapd %xmm14, 0(%r9)
    movapd %xmm8, 64(%r10)
    movapd %xmm12, -2147483648(%rsi)
    movapd %xmm13, 0(%rsp)
    movapd %xmm15, 8(%r12)
    movapd %xmm9, 2147483647(%rsp)
    movapd %xmm10, 0(%rcx,%r12,1)
g48:
    movapd %xmm11, -128(%rbp,%rax,2)
    movapd %xmm14, 4660(%r12,%r15,4)
    movapd %xmm8, gnu_back(%rip)
    movapd %xmm12, 128
    movapd %xmm2, 0(%rsi)
    movapd %xmm3, 127(%rcx)
    movapd %xmm6, -129(%rdx)
    movapd %xmm7, 0(%rsp)
    movapd %xmm5, -1(%rsp)
    movapd %xmm4, -2147483648(%rsp)
    movapd %xmm1, 0(%rax,%rax,8)
    movapd %xmm2, 64(%rsp,%rcx,1)
    movapd %xmm3, 2147483647(%rbp,%rdx,2)
    movapd %xmm6, gnu_fwd(%rip)
    movapd %xmm7, 4660
    movupd %xmm13, 0(%rbx)
    movupd %xmm15, 8(%r11)
    movupd %xmm9, 128(%rdi)
    movupd %xmm10, 0(%r12)
    movupd %xmm11, -128(%rsp)
    movupd %xmm14, -129(%r12)
    movupd %xmm8, 0(%r12,%rsi,4)
    movupd %xmm12, 127(%rdi,%rcx,8)
    movupd %xmm13, -2147483648(%r15,%r9,1)
    movupd %xmm15, gnu_back(%rip)
    movupd %xmm9, 2147483647
    movupd %xmm5, 0(%rdi)
    movupd %xmm4, -1(%rbx)
    movupd %xmm1, 4660(%rbp)
    movupd %xmm2, 0(%rsp)
    movupd %xmm3, 64(%rsp)
    movupd %xmm6, 128(%rsp)
    movupd %xmm7, 0(%rcx,%rbx,2)
    movupd %xmm5, 8(%rsi,%rbp,4)
    movupd %xmm4, -129(%rdi,%rsi,8)
    movupd %xmm1, gnu_fwd(%rip)
    movupd %xmm2, -2147483648
    movhlps %xmm10, %xmm13
    movhlps %xmm3, %xmm6
    movlhps %xmm11, %xmm6
    movlhps %xmm7, %xmm5
    shufps $63, %xmm14, %xmm14
    shufps $7, 0(%r10), %xmm8
    shufps $0, -128(%r14), %xmm12
    shufps $255, 2147483647(%r15), %xmm13
    shufps $63, 0(%rsp), %xmm15
    shufps $7, 127(%r12), %xmm9
    shufps $0, 4660(%rsp), %xmm10
    shufps $255, 0(%rdx,%rbp,1), %xmm11
    shufps $63, -1(%rax,%r12,2), %xmm14
    shufps $7, 128(%r9,%rax,4), %xmm8
    shufps $0, gnu_back(%rip), %xmm12
    shufps $255, -129, %xmm13
    shufps $63, %xmm4, %xmm1
    shufps $7, 0(%rcx), %xmm2
    shufps $0, 64(%rsi), %xmm3
    shufps $255, -2147483648(%rdi), %xmm6
    shufps $63, 0(%rsp), %xmm7
    shufps $7, 8(%rsp), %xmm5
    shufps $0, 2147483647(%rsp), %xmm4
    shufps $255, 0(%rdx,%rdi,8), %xmm1
    shufps $63, -128(%rax,%rax,1), %xmm2
    shufps $7, 4660(%rcx,%rcx,2), %xmm3
    shufps $0, gnu_fwd(%rip), %xmm6
    shufps $255, 128, %xmm7
    shufpd $63, %xmm15, %xmm7
    shufpd $7, 0(%rsi), %xmm9
    shufpd $0, 127(%rcx), %xmm10
    shufpd $255, -129(%r8), %xmm11
    shufpd $63, 0(%r12), %xmm14
    shufpd $7, -1(%rsp), %xmm8
    shufpd $0, -2147483648(%r12), %xmm12
    shufpd $255, 0(%r9,%r15,4), %xmm13
    shufpd $63, 64(%rsp,%rsi,8), %xmm15
    shufpd $7, 2147483647(%r13,%rcx,1), %xmm9
    shufpd $0, gnu_back(%rip), %xmm10
    shufpd $255, 4660, %xmm11
    shufpd $63, %xmm5, %xmm4
    shufpd $7, 0(%rdx), %xmm1
    shufpd $0, 8(%rcx), %xmm2
    shufpd $255, 128(%rdx), %xmm3
    shufpd $63, 0(%rsp), %xmm6
    shufpd $7, -128(%rsp), %xmm7
    shufpd $0, -129(%rsp), %xmm5
    shufpd $255, 0(%rbx,%rdx,2), %xmm4
    shufpd $63, 127(%rdx,%rbx,4), %xmm1
    shufpd $7, -2147483648(%rbx,%rbp,8), %xmm2
    shufpd $0, gnu_fwd(%rip), %xmm3
    shufpd $255, 2147483647, %xmm6
    cmpsd $63, %xmm14, %xmm15
    cmpsd $7, 0(%r11), %xmm8
    cmpsd $0, -1(%rbp), %xmm12
    cmpsd $255, 4660(%r13), %xmm13
    cmpsd $63, 0(%rsp), %xmm15
    cmpsd $7, 64(%r12), %xmm9
    cmpsd $0, 128(%rsp), %xmm10
    cmpsd $255, 0(%rsp,%r9,1), %xmm11
    cmpsd $63, 8(%rbp,%rbp,2), %xmm14
    cmpsd $7, -129(%r12,%r12,4), %xmm8
    cmpsd $0, gnu_back(%rip), %xmm12
    cmpsd $255, -2147483648, %xmm13
    cmpsd $63, %xmm7, %xmm5
    cmpsd $7, 0(%rbx), %xmm4
    cmpsd $0, -128(%rbx), %xmm1
    cmpsd $255, 2147483647(%rbp), %xmm2
    cmpsd $63, 0(%rsp), %xmm3
    cmpsd $7, 127(%rsp), %xmm6
    cmpsd $0, 4660(%rsp), %xmm7
    cmpsd $255, 0(%rsp,%rsi,8), %xmm5
    cmpsd $63, -1(%rsp,%rdi,1), %xmm4
    cmpsd $7, 128(%rbp,%rax,2), %xmm1
    cmpsd $0, gnu_fwd(%rip), %xmm2
    cmpsd $255, -129, %xmm3
    cmpss $63, %xmm15, %xmm5
    cmpss $7, 0(%rdi), %xmm9
    cmpss $0, 64(%rdx), %xmm10
    cmpss $255, -2147483648(%r9), %xmm11
    cmpss $63, 0(%r12), %xmm14
    cmpss $7, 8(%rsp), %xmm8
    cmpss $0, 2147483647(%r12), %xmm12
    cmpss $255, 0(%r14,%rax,4), %xmm13
    cmpss $63, -128(%rdi,%r15,8), %xmm15
    cmpss $7, 4660(%r15,%rsi,1), %xmm9
    cmpss $0, gnu_back(%rip), %xmm10
    cmpss $255, 128, %xmm11
    cmpss $63, %xmm6, %xmm7
    cmpss $7, 0(%rsi), %xmm5
    cmpss $0, 127(%rsi), %xmm4
    cmpss $255, -129(%rdi), %xmm1
    cmpss $63, 0(%rsp), %xmm2
    cmpss $7, -1(%rsp), %xmm3
    cmpss $0, -2147483648(%rsp), %xmm6
    cmpss $255, 0(%rsi,%rcx,2), %xmm7
    cmpss $63, 64(%rsi,%rdx,4), %xmm5
    cmpss $7, 2147483647(%rdi,%rbx,8), %xmm4
    cmpss $0, gnu_fwd(%rip), %xmm1
    cmpss $255, 4660, %xmm2
    cmppd $63, %xmm14, %xmm8
    cmppd $7, 0(%r14), %xmm8
    cmppd $0, 8(%rbx), %xmm12
    cmppd $255, 128(%r10), %xmm13
    cmppd $63, 0(%rsp), %xmm15
    cmppd $7, -128(%r12), %xmm9
    cmppd $0, -129(%rsp), %xmm10
    cmppd $255, 0(%rsi,%rcx,1), %xmm11
    cmppd $63, 127(%rax,%r9,2), %xmm14
    cmppd $7, -2147483648(%r9,%rbp,4), %xmm8
    cmppd $0, gnu_back(%rip), %xmm12
    cmppd $255, 2147483647, %xmm13
    cmppd $63, %xmm3, %xmm6
    cmppd $7, 0(%rdi), %xmm7
    cmppd $0, -1(%rcx), %xmm5
    cmppd $255, 4660(%rdx), %xmm4
    cmppd $63, 0(%rsp), %xmm1
    cmppd $7, 64(%rsp), %xmm2
    cmppd $0, 128(%rsp), %xmm3
    cmppd $255, 0(%rdi,%rbp,8), %xmm6
    cmppd $63, 8(%rax,%rsi,1), %xmm7
    cmppd $7, -129(%rcx,%rdi,2), %xmm5
    cmppd $0, gnu_fwd(%rip), %xmm4
    cmppd $255, -2147483648, %xmm1
    cmpps $63, %xmm15, %xmm1
    cmpps $7, 0(%r15), %xmm9
    cmpps $0, -128(%rsi), %xmm10
    cmpps $255, 2147483647(%r11), %xmm11
    cmpps $63, 0(%r12), %xmm14
    cmpps $7, 127(%rsp), %xmm8
    cmpps $0, 4660(%r12), %xmm12
    cmpps $255, 0(%r15,%r12,4), %xmm13
    cmpps $63, -1(%rsp,%rax,8), %xmm15
    cmpps $7, 128(%r13,%r15,1), %xmm9
    cmpps $0, gnu_back(%rip), %xmm10
    cmpps $255, -129, %xmm11
    cmpps $63, %xmm2, %xmm3
    cmpps $7, 0(%rcx), %xmm6
    cmpps $0, 64(%rbx), %xmm7
    cmpps $255, -2147483648(%rbp), %xmm5
    cmpps $63, 0(%rsp), %xmm4
    cmpps $7, 8(%rsp), %xmm1
    cmpps $0, 2147483647(%rsp), %xmm2
    cmpps $255, 0(%rax,%rax,2), %xmm3
    cmpps $63, -128(%rdx,%rcx,4), %xmm6
    cmpps $7, 4660(%rbx,%rdx,8), %xmm7
    cmpps $0, gnu_fwd(%rip), %xmm5
    cmpps $255, 128, %xmm4
    cvtsi2sdl 0(%rcx), %xmm14
    cvtsi2sdl 127(%rdi), %xmm8
    cvtsi2sdl -129(%r14), %xmm12
    cvtsi2sdl 0(%rsp), %xmm13
    cvtsi2sdl -1(%r12), %xmm15
    cvtsi2sdl -2147483648(%rsp), %xmm9
    cvtsi2sdl 0(%rax,%rsi,1), %xmm10
    cvtsi2sdl 64(%rbp,%rcx,2), %xmm11
    cvtsi2sdl 2147483647(%r12,%r9,4), %xmm14
    cvtsi2sdl gnu_back(%rip), %xmm8
    cvtsi2sdl 4660, %xmm12
    cvtsi2sdl %ecx, %xmm2
    cvtsi2sdl 0(%rdx), %xmm3
    cvtsi2sdl 8(%rsi), %xmm6
    cvtsi2sdl 128(%rdi), %xmm7
g49:
    cvtsi2sdl 0(%rsp), %xmm5
    cvtsi2sdl -128(%rsp), %xmm4
    cvtsi2sdl -129(%rsp), %xmm1
    cvtsi2sdl 0(%rcx,%rbx,8), %xmm2
    cvtsi2sdl 127(%rsp,%rbp,1), %xmm3
    cvtsi2sdl -2147483648(%rbp,%rsi,2), %xmm6
    cvtsi2sdl gnu_fwd(%rip), %xmm7
    cvtsi2sdl 2147483647, %xmm5
    cvtsi2sdq 0(%r8), %xmm13
    cvtsi2sdq -1(%r15), %xmm15
    cvtsi2sdq 4660(%rcx), %xmm9
    cvtsi2sdq 0(%r12), %xmm10
    cvtsi2sdq 64(%rsp), %xmm11
    cvtsi2sdq 128(%r12), %xmm14
    cvtsi2sdq 0(%r8,%rbp,4), %xmm8
    cvtsi2sdq 8(%rdi,%r12,8), %xmm12
    cvtsi2sdq -129(%r15,%rax,1), %xmm13
    cvtsi2sdq gnu_back(%rip), %xmm15
    cvtsi2sdq -2147483648, %xmm9
    cvttsd2si 0(%rdx), %r10d
    cvttsd2si -128(%r8), %r11d
    cvttsd2si 2147483647(%rbp), %r14d
    cvttsd2si 0(%rsp), %r8d
    cvttsd2si 127(%r12), %r12d
    cvttsd2si 4660(%rsp), %r13d
    cvttsd2si 0(%rcx,%r15,2), %r15d
    cvttsd2si -1(%rax,%rsi,4), %r9d
    cvttsd2si 128(%r9,%rcx,8), %r10d
    cvttsd2si gnu_fwd(%rip), %r11d
    cvttsd2si -129, %r14d
    cvttsd2si %xmm4, %ecx
    cvttsd2si 0(%rbx), %edx
    cvttsd2si 64(%rcx), %ebx
    cvttsd2si -2147483648(%rdx), %esi
    cvttsd2si 0(%rsp), %edi
    cvttsd2si 8(%rsp), %ebp
    cvttsd2si 2147483647(%rsp), %esp
    cvttsd2si 0(%rdx,%rdi,1), %ecx
    cvttsd2si -128(%rsi,%rax,2), %edx
    cvttsd2si 4660(%rdi,%rcx,4), %ebx
    cvttsd2si gnu_back(%rip), %esi
    cvttsd2si 128, %edi
    cvttsd2si 0(%r9), %r8
    cvttsd2si 127(%r13), %r12
    cvttsd2si -129(%rdx), %r13
    cvttsd2si 0(%r12), %r15
    cvttsd2si -1(%rsp), %r9
    cvttsd2si -2147483648(%r12), %r10
    cvttsd2si 0(%r12,%r9,8), %r11
    cvttsd2si 64(%rsp,%rbp,1), %r14
    cvttsd2si 2147483647(%r13,%r12,2), %r8
    cvttsd2si gnu_fwd(%rip), %r12
    cvttsd2si 4660, %r13
    cvtsi2ssl 0(%rbx), %xmm15
    cvtsi2ssl 8(%r9), %xmm9
    cvtsi2ssl 128(%rbx), %xmm10
    cvtsi2ssl 0(%rsp), %xmm11
    cvtsi2ssl -128(%r12), %xmm14
    cvtsi2ssl -129(%rsp), %xmm8
    cvtsi2ssl 0(%rdx,%rax,4), %xmm12
    cvtsi2ssl 127(%rbp,%r15,8), %xmm13
    cvtsi2ssl -2147483648(%r12,%rsi,1), %xmm15
    cvtsi2ssl gnu_back(%rip), %xmm9
    cvtsi2ssl 2147483647, %xmm10
    cvtsi2ssl %ebp, %xmm4
    cvtsi2ssl 0(%rsi), %xmm1
    cvtsi2ssl -1(%rbx), %xmm2
    cvtsi2ssl 4660(%rbp), %xmm3
    cvtsi2ssl 0(%rsp), %xmm6
    cvtsi2ssl 64(%rsp), %xmm7
    cvtsi2ssl 128(%rsp), %xmm5
    cvtsi2ssl 0(%rbx,%rdx,2), %xmm4
    cvtsi2ssl 8(%rax,%rbx,4), %xmm1
    cvtsi2ssl -129(%rcx,%rbp,8), %xmm2
    cvtsi2ssl gnu_fwd(%rip), %xmm3
    cvtsi2ssl -2147483648, %xmm6
    cvtsi2ssq 0(%r10), %xmm11
    cvtsi2ssq -128(%r10), %xmm14
    cvtsi2ssq 2147483647(%rsi), %xmm8
    cvtsi2ssq 0(%r12), %xmm12
    cvtsi2ssq 127(%rsp), %xmm13
    cvtsi2ssq 4660(%r12), %xmm15
    cvtsi2ssq 0(%r9,%rcx,1), %xmm9
    cvtsi2ssq -1(%rdi,%r9,2), %xmm10
    cvtsi2ssq 128(%r15,%rbp,4), %xmm11
    cvtsi2ssq gnu_back(%rip), %xmm14
    cvtsi2ssq -129, %xmm8
    cvttss2si 0(%rsi), %r12d
    cvttss2si 64(%r11), %r13d
    cvttss2si -2147483648(%rdi), %r15d
    cvttss2si 0(%rsp), %r9d
    cvttss2si 8(%r12), %r10d
    cvttss2si 2147483647(%rsp), %r11d
    cvttss2si 0(%rsp,%r12,8), %r14d
    cvttss2si -128(%rax,%rax,1), %r8d
    cvttss2si 4660(%r9,%r15,2), %r12d
    cvttss2si gnu_fwd(%rip), %r13d
    cvttss2si 128, %r15d
    cvttss2si %xmm7, %ebp
    cvttss2si 0(%rdi), %esp
    cvttss2si 127(%rsi), %ecx
    cvttss2si -129(%rdi), %edx
    cvttss2si 0(%rsp), %ebx
    cvttss2si -1(%rsp), %esi
    cvttss2si -2147483648(%rsp), %edi
    cvttss2si 0(%rsp,%rsi,4), %ebp
    cvttss2si 64(%rdx,%rdi,8), %esp
    cvttss2si 2147483647(%rbx,%rax,1), %ecx
    cvttss2si gnu_back(%rip), %edx
    cvttss2si 4660, %ebx
    cvttss2si 0(%r11), %r9
    cvttss2si 8(%r14), %r10
    cvttss2si 128(%r15), %r11
    cvttss2si 0(%r12), %r14
    cvttss2si -128(%rsp), %r8
    cvttss2si -129(%r12), %r12
    cvttss2si 0(%r14,%rsi,2), %r13
    cvttss2si 127(%rsp,%rcx,4), %r15
    cvttss2si -2147483648(%r13,%r9,8), %r9
    cvttss2si gnu_fwd(%rip), %r10
    cvttss2si 2147483647, %r11
    vpaddb %xmm6, %xmm9, %xmm2
    vpaddb 0(%rcx), %xmm12, %xmm3
    vpaddb -1(%rcx), %xmm13, %xmm6
    vpaddb 4660(%rdx), %xmm14, %xmm7
    vpaddb 0(%rsp), %xmm15, %xmm5
    vpaddb 64(%rsp), %xmm8, %xmm1
    vpaddb 128(%rsp), %xmm9, %xmm2
    vpaddb 0(%rsi,%rcx,1), %xmm12, %xmm3
    vpaddb 8(%rsp,%rdx,2), %xmm13, %xmm6
    vpaddb -129(%rbp,%rbx,4), %xmm14, %xmm7
    vpaddb gnu_back(%rip), %xmm15, %xmm5
    {vex3} vpaddb %xmm8, %xmm1, %xmm9
    {vex3} vpaddb 0(%rdi), %xmm2, %xmm12
    {vex3} vpaddb -128(%rcx), %xmm3, %xmm13
    {vex3} vpaddb -2147483648(%r8), %xmm6, %xmm14
    {vex3} vpaddb 0(%rsp), %xmm7, %xmm15
    {vex3} vpaddb 127(%r12), %xmm5, %xmm8
    {vex3} vpaddb 2147483647(%rsp), %xmm1, %xmm9
    {vex3} vpaddb 0(%rsi,%rbp,8), %xmm2, %xmm12
    {vex3} vpaddb -1(%rbp,%r12,1), %xmm3, %xmm13
    {vex3} vpaddb 4660(%r12,%rax,2), %xmm6, %xmm14
    {vex3} vpaddb gnu_fwd(%rip), %xmm7, %xmm15
    vpaddb %ymm7, %ymm5, %ymm8
    vpaddb 0(%rdx), %ymm1, %ymm9
    vpaddb 64(%rbx), %ymm2, %ymm12
    vpaddb 128(%rbp), %ymm3, %ymm13
    vpaddb 0(%rsp), %ymm6, %ymm14
    vpaddb 8(%rsp), %ymm7, %ymm15
    vpaddb -129(%rsp), %ymm5, %ymm8
    vpaddb 0(%rdi,%rbp,4), %ymm1, %ymm9
    vpaddb -128(%rsi,%rsi,8), %ymm2, %ymm12
    vpaddb -2147483648(%rdi,%rdi,1), %ymm3, %ymm13
    vpaddb gnu_back(%rip), %ymm6, %ymm14
    {vex3} vpaddb %ymm7, %ymm15, %ymm5
    {vex3} vpaddb 0(%r14), %ymm8, %ymm1
    {vex3} vpaddb 127(%rbp), %ymm9, %ymm2
    {vex3} vpaddb 2147483647(%r13), %ymm12, %ymm3
    {vex3} vpaddb 0(%r12), %ymm13, %ymm6
    {vex3} vpaddb -1(%rsp), %ymm14, %ymm7
    {vex3} vpaddb 4660(%r12), %ymm15, %ymm5
    {vex3} vpaddb 0(%r15,%r15,2), %ymm8, %ymm1
    {vex3} vpaddb 64(%rdi,%rsi,4), %ymm9, %ymm2
    {vex3} vpaddb 128(%r15,%rcx,8), %ymm12, %ymm3
    {vex3} vpaddb gnu_fwd(%rip), %ymm13, %ymm6
    vpsubb %xmm5, %xmm14, %xmm7
    vpsubb 0(%rbx), %xmm15, %xmm5
    vpsubb 8(%rsi), %xmm8, %xmm1
    vpsubb -129(%rdi), %xmm9, %xmm2
    vpsubb 0(%rsp), %xmm12, %xmm3
    vpsubb -128(%rsp), %xmm13, %xmm6
    vpsubb -2147483648(%rsp), %xmm14, %xmm7
    vpsubb 0(%rax,%rax,1), %xmm15, %xmm5
    vpsubb 127(%rax,%rcx,2), %xmm8, %xmm1
    vpsubb 2147483647(%rcx,%rdx,4), %xmm9, %xmm2
    vpsubb gnu_back(%rip), %xmm12, %xmm3
    {vex3} vpsubb %xmm13, %xmm6, %xmm14
    {vex3} vpsubb 0(%r15), %xmm7, %xmm15
    {vex3} vpsubb -1(%rdx), %xmm5, %xmm8
    {vex3} vpsubb 4660(%r9), %xmm1, %xmm9
    {vex3} vpsubb 0(%rsp), %xmm2, %xmm12
    {vex3} vpsubb 64(%r12), %xmm3, %xmm13
    {vex3} vpsubb 128(%rsp), %xmm6, %xmm14
    {vex3} vpsubb 0(%rax,%r9,8), %xmm7, %xmm15
    {vex3} vpsubb 8(%rax,%rbp,1), %xmm5, %xmm8
    {vex3} vpsubb -129(%r9,%r12,2), %xmm1, %xmm9
    {vex3} vpsubb gnu_fwd(%rip), %xmm2, %xmm12
    vpsubb %ymm4, %ymm3, %ymm13
    vpsubb 0(%rsi), %ymm6, %ymm14
    vpsubb -128(%rcx), %ymm7, %ymm15
    vpsubb -2147483648(%rdx), %ymm5, %ymm8
    vpsubb 0(%rsp), %ymm1, %ymm9
    vpsubb 127(%rsp), %ymm2, %ymm12
    vpsubb 2147483647(%rsp), %ymm3, %ymm13
    vpsubb 0(%rcx,%rbx,4), %ymm6, %ymm14
    vpsubb -1(%rdx,%rbp,8), %ymm7, %ymm15
    vpsubb 4660(%rbx,%rsi,1), %ymm5, %ymm8
    vpsubb gnu_back(%rip), %ymm1, %ymm9
    {vex3} vpsubb %ymm2, %ymm12, %ymm3
    {vex3} vpsubb 0(%rcx), %ymm13, %ymm6
g50:
    {vex3} vpsubb 64(%rbx), %ymm14, %ymm7
    {vex3} vpsubb 128(%r10), %ymm15, %ymm5
    {vex3} vpsubb 0(%r12), %ymm8, %ymm1
    {vex3} vpsubb 8(%rsp), %ymm9, %ymm2
    {vex3} vpsubb -129(%r12), %ymm12, %ymm3
    {vex3} vpsubb 0(%r8,%rax,2), %ymm13, %ymm6
    {vex3} vpsubb -128(%rsp,%r15,4), %ymm14, %ymm7
    {vex3} vpsubb -2147483648(%r13,%rsi,8), %ymm15, %ymm5
    {vex3} vpsubb gnu_fwd(%rip), %ymm8, %ymm1
    vpand %xmm1, %xmm9, %xmm2
    vpand 0(%rdi), %xmm12, %xmm3
    vpand 127(%rbx), %xmm13, %xmm6
    vpand 2147483647(%rbp), %xmm14, %xmm7
    vpand 0(%rsp), %xmm15, %xmm5
    vpand -1(%rsp), %xmm8, %xmm1
    vpand 4660(%rsp), %xmm9, %xmm2
    vpand 0(%rdx,%rdi,1), %xmm12, %xmm3
    vpand 64(%rsp,%rax,2), %xmm13, %xmm6
    vpand 128(%rbp,%rcx,4), %xmm14, %xmm7
    vpand gnu_back(%rip), %xmm15, %xmm5
    {vex3} vpand %xmm8, %xmm1, %xmm9
    {vex3} vpand 0(%r8), %xmm2, %xmm12
    {vex3} vpand 8(%rsi), %xmm3, %xmm13
    {vex3} vpand -129(%r11), %xmm6, %xmm14
    {vex3} vpand 0(%rsp), %xmm7, %xmm15
    {vex3} vpand -128(%r12), %xmm5, %xmm8
    {vex3} vpand -2147483648(%rsp), %xmm1, %xmm9
    {vex3} vpand 0(%rcx,%rcx,8), %xmm2, %xmm12
    {vex3} vpand 127(%rbp,%r9,1), %xmm3, %xmm13
    {vex3} vpand 2147483647(%r12,%rbp,2), %xmm6, %xmm14
    {vex3} vpand gnu_fwd(%rip), %xmm7, %xmm15
    vpand %ymm2, %ymm5, %ymm8
    vpand 0(%rcx), %ymm1, %ymm9
    vpand -1(%rsi), %ymm2, %ymm12
    vpand 4660(%rdi), %ymm3, %ymm13
    vpand 0(%rsp), %ymm6, %ymm14
    vpand 64(%rsp), %ymm7, %ymm15
    vpand 128(%rsp), %ymm5, %ymm8
    vpand 0(%rbx,%rdx,4), %ymm1, %ymm9
    vpand 8(%rsi,%rbx,8), %ymm2, %ymm12
    vpand -129(%rdi,%rbp,1), %ymm3, %ymm13
    vpand gnu_back(%rip), %ymm6, %ymm14
    {vex3} vpand %ymm7, %ymm15, %ymm5
    {vex3} vpand 0(%rdx), %ymm8, %ymm1
    {vex3} vpand -128(%rdi), %ymm9, %ymm2
    {vex3} vpand -2147483648(%r14), %ymm12, %ymm3
    {vex3} vpand 0(%r12), %ymm13, %ymm6
    {vex3} vpand 127(%rsp), %ymm14, %ymm7
    {vex3} vpand 2147483647(%r12), %ymm15, %ymm5
    {vex3} vpand 0(%r12,%r12,2), %ymm8, %ymm1
    {vex3} vpand -1(%rdi,%rax,4), %ymm9, %ymm2
    {vex3} vpand 4660(%r15,%r15,8), %ymm12, %ymm3
    {vex3} vpand gnu_fwd(%rip), %ymm13, %ymm6
    vpandn %xmm3, %xmm14, %xmm7
    vpandn 0(%rdx), %xmm15, %xmm5
    vpandn 64(%rcx), %xmm8, %xmm1
    vpandn 128(%rdx), %xmm9, %xmm2
    vpandn 0(%rsp), %xmm12, %xmm3
    vpandn 8(%rsp), %xmm13, %xmm6
    vpandn -129(%rsp), %xmm14, %xmm7
    vpandn 0(%rsp,%rsi,1), %xmm15, %xmm5
    vpandn -128(%rax,%rdi,2), %xmm8, %xmm1
    vpandn -2147483648(%rcx,%rax,4), %xmm9, %xmm2
    vpandn gnu_back(%rip), %xmm12, %xmm3
    {vex3} vpandn %xmm13, %xmm6, %xmm14
    {vex3} vpandn 0(%r9), %xmm7, %xmm15
    {vex3} vpandn 127(%r15), %xmm5, %xmm8
    {vex3} vpandn 2147483647(%rcx), %xmm1, %xmm9
    {vex3} vpandn 0(%rsp), %xmm2, %xmm12
    {vex3} vpandn -1(%r12), %xmm3, %xmm13
    {vex3} vpandn 4660(%rsp), %xmm6, %xmm14
    {vex3} vpandn 0(%rdx,%rsi,8), %xmm7, %xmm15
    {vex3} vpandn 64(%rax,%rcx,1), %xmm5, %xmm8
    {vex3} vpandn 128(%r9,%r9,2), %xmm1, %xmm9
    {vex3} vpandn gnu_fwd(%rip), %xmm2, %xmm12
    vpandn %ymm6, %ymm3, %ymm13
    vpandn 0(%rbx), %ymm6, %ymm14
    vpandn 8(%rbx), %ymm7, %ymm15
    vpandn -129(%rbp), %ymm5, %ymm8
    vpandn 0(%rsp), %ymm1, %ymm9
    vpandn -128(%rsp), %ymm2, %ymm12
    vpandn -2147483648(%rsp), %ymm3, %ymm13
    vpandn 0(%rsi,%rcx,4), %ymm6, %ymm14
    vpandn 127(%rdx,%rdx,8), %ymm7, %ymm15
    vpandn 2147483647(%rbx,%rbx,1), %ymm5, %ymm8
    vpandn gnu_back(%rip), %ymm1, %ymm9
    {vex3} vpandn %ymm2, %ymm12, %ymm3
    {vex3} vpandn 0(%rbx), %ymm13, %ymm6
    {vex3} vpandn -1(%r8), %ymm14, %ymm7
    {vex3} vpandn 4660(%rbp), %ymm15, %ymm5
    {vex3} vpandn 0(%r12), %ymm8, %ymm1
    {vex3} vpandn 64(%rsp), %ymm9, %ymm2
    {vex3} vpandn 128(%r12), %ymm12, %ymm3
    {vex3} vpandn 0(%r9,%rbp,2), %ymm13, %ymm6
    {vex3} vpandn 8(%rsp,%r12,4), %ymm14, %ymm7
    {vex3} vpandn -129(%r13,%rax,8), %ymm15, %ymm5
    {vex3} vpandn gnu_fwd(%rip), %ymm8, %ymm1
    vpor %xmm7, %xmm9, %xmm2
    vpor 0(%rsi), %xmm12, %xmm3
    vpor -128(%rsi), %xmm13, %xmm6
    vpor -2147483648(%rdi), %xmm14, %xmm7
    vpor 0(%rsp), %xmm15, %xmm5
    vpor 127(%rsp), %xmm8, %xmm1
    vpor 2147483647(%rsp), %xmm9, %xmm2
    vpor 0(%rdi,%rbp,1), %xmm12, %xmm3
    vpor -1(%rsp,%rsi,2), %xmm13, %xmm6
    vpor 4660(%rbp,%rdi,4), %xmm14, %xmm7
    vpor gnu_back(%rip), %xmm15, %xmm5
    {vex3} vpor %xmm8, %xmm1, %xmm9
    {vex3} vpor 0(%r10), %xmm2, %xmm12
    {vex3} vpor 64(%r13), %xmm3, %xmm13
    {vex3} vpor 128(%rdx), %xmm6, %xmm14
    {vex3} vpor 0(%rsp), %xmm7, %xmm15
    {vex3} vpor 8(%r12), %xmm5, %xmm8
    {vex3} vpor -129(%rsp), %xmm1, %xmm9
    {vex3} vpor 0(%rsp,%r15,8), %xmm2, %xmm12
    {vex3} vpor -128(%rbp,%rsi,1), %xmm3, %xmm13
    {vex3} vpor -2147483648(%r12,%rcx,2), %xmm6, %xmm14
    {vex3} vpor gnu_fwd(%rip), %xmm7, %xmm15
    vpor %ymm5, %ymm5, %ymm8
    vpor 0(%rdi), %ymm1, %ymm9
    vpor 127(%rcx), %ymm2, %ymm12
    vpor 2147483647(%rdx), %ymm3, %ymm13
    vpor 0(%rsp), %ymm6, %ymm14
    vpor -1(%rsp), %ymm7, %ymm15
    vpor 4660(%rsp), %ymm5, %ymm8
    vpor 0(%rax,%rax,4), %ymm1, %ymm9
    vpor 64(%rsi,%rcx,8), %ymm2, %ymm12
    vpor 128(%rdi,%rdx,1), %ymm3, %ymm13
    vpor gnu_back(%rip), %ymm6, %ymm14
    {vex3} vpor %ymm7, %ymm15, %ymm5
    {vex3} vpor 0(%rsi), %ymm8, %ymm1
    {vex3} vpor 8(%r9), %ymm9, %ymm2
    {vex3} vpor -129(%rbx), %ymm12, %ymm3
    {vex3} vpor 0(%r12), %ymm13, %ymm6
    {vex3} vpor -128(%rsp), %ymm14, %ymm7
    {vex3} vpor -2147483648(%r12), %ymm15, %ymm5
    {vex3} vpor 0(%r14,%r9,2), %ymm8, %ymm1
    {vex3} vpor 127(%rdi,%rbp,4), %ymm9, %ymm2
    {vex3} vpor 2147483647(%r15,%r12,8), %ymm12, %ymm3
    {vex3} vpor gnu_fwd(%rip), %ymm13, %ymm6
    vpxor %xmm4, %xmm14, %xmm7
    vpxor 0(%rcx), %xmm15, %xmm5
    vpxor -1(%rbx), %xmm8, %xmm1
    vpxor 4660(%rbp), %xmm9, %xmm2
    vpxor 0(%rsp), %xmm12, %xmm3
    vpxor 64(%rsp), %xmm13, %xmm6
    vpxor 128(%rsp), %xmm14, %xmm7
    vpxor 0(%rcx,%rbx,1), %xmm15, %xmm5
    vpxor 8(%rax,%rbp,2), %xmm8, %xmm1
    vpxor -129(%rcx,%rsi,4), %xmm9, %xmm2
    vpxor gnu_back(%rip), %xmm12, %xmm3
    {vex3} vpxor %xmm13, %xmm6, %xmm14
    {vex3} vpxor 0(%r11), %xmm7, %xmm15
    {vex3} vpxor -128(%r10), %xmm5, %xmm8
    {vex3} vpxor -2147483648(%rsi), %xmm1, %xmm9
    {vex3} vpxor 0(%rsp), %xmm2, %xmm12
    {vex3} vpxor 127(%r12), %xmm3, %xmm13
    {vex3} vpxor 2147483647(%rsp), %xmm6, %xmm14
    {vex3} vpxor 0(%rsi,%rax,8), %xmm7, %xmm15
    {vex3} vpxor -1(%rax,%r15,1), %xmm5, %xmm8
    {vex3} vpxor 4660(%r9,%rsi,2), %xmm1, %xmm9
    {vex3} vpxor gnu_fwd(%rip), %xmm2, %xmm12
    vpxor %ymm1, %ymm3, %ymm13
    vpxor 0(%rdx), %ymm6, %ymm14
    vpxor 64(%rsi), %ymm7, %ymm15
    vpxor 128(%rdi), %ymm5, %ymm8
    vpxor 0(%rsp), %ymm1, %ymm9
    vpxor 8(%rsp), %ymm2, %ymm12
    vpxor -129(%rsp), %ymm3, %ymm13
    vpxor 0(%rdx,%rdi,4), %ymm6, %ymm14
    vpxor -128(%rdx,%rax,8), %ymm7, %ymm15
    vpxor -2147483648(%rbx,%rcx,1), %ymm5, %ymm8
    vpxor gnu_back(%rip), %ymm1, %ymm9
    {vex3} vpxor %ymm2, %ymm12, %ymm3
    {vex3} vpxor 0(%rdi), %ymm13, %ymm6
    {vex3} vpxor 127(%r11), %ymm14, %ymm7
    {vex3} vpxor 2147483647(%rdi), %ymm15, %ymm5
    {vex3} vpxor 0(%r12), %ymm8, %ymm1
    {vex3} vpxor -1(%rsp), %ymm9, %ymm2
    {vex3} vpxor 4660(%r12), %ymm12, %ymm3
    {vex3} vpxor 0(%r15,%rcx,2), %ymm13, %ymm6
    {vex3} vpxor 64(%rsp,%r9,4), %ymm14, %ymm7
    {vex3} vpxor 128(%r13,%rbp,8), %ymm15, %ymm5
    {vex3} vpxor gnu_fwd(%rip), %ymm8, %ymm1
    vpcmpeqb %xmm2, %xmm9, %xmm2
    vpcmpeqb 0(%rbx), %xmm12, %xmm3
    vpcmpeqb 8(%rcx), %xmm13, %xmm6
    vpcmpeqb -129(%rdx), %xmm14, %xmm7
    vpcmpeqb 0(%rsp), %xmm15, %xmm5
    vpcmpeqb -128(%rsp), %xmm8, %xmm1
    vpcmpeqb -2147483648(%rsp), %xmm9, %xmm2
    vpcmpeqb 0(%rbx,%rdx,1), %xmm12, %xmm3
    vpcmpeqb 127(%rsp,%rbx,2), %xmm13, %xmm6
    vpcmpeqb 2147483647(%rbp,%rbp,4), %xmm14, %xmm7
    vpcmpeqb gnu_back(%rip), %xmm15, %xmm5
    {vex3} vpcmpeqb %xmm8, %xmm1, %xmm9
    {vex3} vpcmpeqb 0(%r14), %xmm2, %xmm12
    {vex3} vpcmpeqb -1(%r14), %xmm3, %xmm13
    {vex3} vpcmpeqb 4660(%r15), %xmm6, %xmm14
g51:
    {vex3} vpcmpeqb 0(%rsp), %xmm7, %xmm15
    {vex3} vpcmpeqb 64(%r12), %xmm5, %xmm8
    {vex3} vpcmpeqb 128(%rsp), %xmm1, %xmm9
    {vex3} vpcmpeqb 0(%rax,%r12,8), %xmm2, %xmm12
    {vex3} vpcmpeqb 8(%rbp,%rax,1), %xmm3, %xmm13
    {vex3} vpcmpeqb -129(%r12,%r15,2), %xmm6, %xmm14
    {vex3} vpcmpeqb gnu_fwd(%rip), %xmm7, %xmm15
    vpcmpeqb %ymm3, %ymm5, %ymm8
    vpcmpeqb 0(%rsi), %ymm1, %ymm9
    vpcmpeqb -128(%rbx), %ymm2, %ymm12
    vpcmpeqb -2147483648(%rbp), %ymm3, %ymm13
    vpcmpeqb 0(%rsp), %ymm6, %ymm14
    vpcmpeqb 127(%rsp), %ymm7, %ymm15
    vpcmpeqb 2147483647(%rsp), %ymm5, %ymm8
    vpcmpeqb 0(%rsp,%rsi,4), %ymm1, %ymm9
    vpcmpeqb -1(%rsi,%rdi,8), %ymm2, %ymm12
    vpcmpeqb 4660(%rdi,%rax,1), %ymm3, %ymm13
    vpcmpeqb gnu_back(%rip), %ymm6, %ymm14
    {vex3} vpcmpeqb %ymm7, %ymm15, %ymm5
    {vex3} vpcmpeqb 0(%r15), %ymm8, %ymm1
    {vex3} vpcmpeqb 64(%rcx), %ymm9, %ymm2
    {vex3} vpcmpeqb 128(%r8), %ymm12, %ymm3
    {vex3} vpcmpeqb 0(%r12), %ymm13, %ymm6
    {vex3} vpcmpeqb 8(%rsp), %ymm14, %ymm7
    {vex3} vpcmpeqb -129(%r12), %ymm15, %ymm5
    {vex3} vpcmpeqb 0(%r8,%rsi,2), %ymm8, %ymm1
    {vex3} vpcmpeqb -128(%rdi,%rcx,4), %ymm9, %ymm2
    {vex3} vpcmpeqb -2147483648(%r15,%r9,8), %ymm12, %ymm3
    {vex3} vpcmpeqb gnu_fwd(%rip), %ymm13, %ymm6
    vpcmpeqd %xmm6, %xmm14, %xmm7
    vpcmpeqd 0(%rdi), %xmm15, %xmm5
    vpcmpeqd 127(%rsi), %xmm8, %xmm1
    vpcmpeqd 2147483647(%rdi), %xmm9, %xmm2
    vpcmpeqd 0(%rsp), %xmm12, %xmm3
    vpcmpeqd -1(%rsp), %xmm13, %xmm6
    vpcmpeqd 4660(%rsp), %xmm14, %xmm7
    vpcmpeqd 0(%rsi,%rcx,1), %xmm15, %xmm5
    vpcmpeqd 64(%rax,%rdx,2), %xmm8, %xmm1
    vpcmpeqd 128(%rcx,%rbx,4), %xmm9, %xmm2
    vpcmpeqd gnu_back(%rip), %xmm12, %xmm3
    {vex3} vpcmpeqd %xmm13, %xmm6, %xmm14
    {vex3} vpcmpeqd 0(%rcx), %xmm7, %xmm15
    {vex3} vpcmpeqd 8(%rbp), %xmm5, %xmm8
    {vex3} vpcmpeqd -129(%r13), %xmm1, %xmm9
    {vex3} vpcmpeqd 0(%rsp), %xmm2, %xmm12
    {vex3} vpcmpeqd -128(%r12), %xmm3, %xmm13
    {vex3} vpcmpeqd -2147483648(%rsp), %xmm6, %xmm14
    {vex3} vpcmpeqd 0(%rcx,%rbp,8), %xmm7, %xmm15
    {vex3} vpcmpeqd 127(%rax,%r12,1), %xmm5, %xmm8
    {vex3} vpcmpeqd 2147483647(%r9,%rax,2), %xmm1, %xmm9
    {vex3} vpcmpeqd gnu_fwd(%rip), %xmm2, %xmm12
    vpcmpeqd %ymm7, %ymm3, %ymm13
    vpcmpeqd 0(%rcx), %ymm6, %ymm14
    vpcmpeqd -1(%rcx), %ymm7, %ymm15
    vpcmpeqd 4660(%rdx), %ymm5, %ymm8
    vpcmpeqd 0(%rsp), %ymm1, %ymm9
    vpcmpeqd 64(%rsp), %ymm2, %ymm12
    vpcmpeqd 128(%rsp), %ymm3, %ymm13
    vpcmpeqd 0(%rdi,%rbp,4), %ymm6, %ymm14
    vpcmpeqd 8(%rdx,%rsi,8), %ymm7, %ymm15
    vpcmpeqd -129(%rbx,%rdi,1), %ymm5, %ymm8
    vpcmpeqd gnu_back(%rip), %ymm1, %ymm9
    {vex3} vpcmpeqd %ymm2, %ymm12, %ymm3
    {vex3} vpcmpeqd 0(%r8), %ymm13, %ymm6
    {vex3} vpcmpeqd -128(%rdx), %ymm14, %ymm7
    {vex3} vpcmpeqd -2147483648(%r9), %ymm15, %ymm5
    {vex3} vpcmpeqd 0(%r12), %ymm8, %ymm1
    {vex3} vpcmpeqd 127(%rsp), %ymm9, %ymm2
    {vex3} vpcmpeqd 2147483647(%r12), %ymm12, %ymm3
    {vex3} vpcmpeqd 0(%r12,%r15,2), %ymm13, %ymm6
    {vex3} vpcmpeqd -1(%rsp,%rsi,4), %ymm14, %ymm7
    {vex3} vpcmpeqd 4660(%r13,%rcx,8), %ymm15, %ymm5
    {vex3} vpcmpeqd gnu_fwd(%rip), %ymm8, %ymm1
    vpcmpgtb %xmm5, %xmm9, %xmm2
    vpcmpgtb 0(%rdx), %xmm12, %xmm3
    vpcmpgtb 64(%rbx), %xmm13, %xmm6
    vpcmpgtb 128(%rbp), %xmm14, %xmm7
    vpcmpgtb 0(%rsp), %xmm15, %xmm5
    vpcmpgtb 8(%rsp), %xmm8, %xmm1
    vpcmpgtb -129(%rsp), %xmm9, %xmm2
    vpcmpgtb 0(%rax,%rax,1), %xmm12, %xmm3
    vpcmpgtb -128(%rsp,%rcx,2), %xmm13, %xmm6
    vpcmpgtb -2147483648(%rbp,%rdx,4), %xmm14, %xmm7
    vpcmpgtb gnu_back(%rip), %xmm15, %xmm5
    {vex3} vpcmpgtb %xmm8, %xmm1, %xmm9
    {vex3} vpcmpgtb 0(%rdx), %xmm2, %xmm12
    {vex3} vpcmpgtb 127(%rbx), %xmm3, %xmm13
    {vex3} vpcmpgtb 2147483647(%r10), %xmm6, %xmm14
    {vex3} vpcmpgtb 0(%rsp), %xmm7, %xmm15
    {vex3} vpcmpgtb -1(%r12), %xmm5, %xmm8
    {vex3} vpcmpgtb 4660(%rsp), %xmm1, %xmm9
    {vex3} vpcmpgtb 0(%rdx,%r9,8), %xmm2, %xmm12
    {vex3} vpcmpgtb 64(%rbp,%rbp,1), %xmm3, %xmm13
    {vex3} vpcmpgtb 128(%r12,%r12,2), %xmm6, %xmm14
    {vex3} vpcmpgtb gnu_fwd(%rip), %xmm7, %xmm15
    vpcmpgtb %ymm4, %ymm5, %ymm8
    vpcmpgtb 0(%rbx), %ymm1, %ymm9
    vpcmpgtb 8(%rsi), %ymm2, %ymm12
    vpcmpgtb -129(%rdi), %ymm3, %ymm13
    vpcmpgtb 0(%rsp), %ymm6, %ymm14
    vpcmpgtb -128(%rsp), %ymm7, %ymm15
    vpcmpgtb -2147483648(%rsp), %ymm5, %ymm8
    vpcmpgtb 0(%rcx,%rbx,4), %ymm1, %ymm9
    vpcmpgtb 127(%rsi,%rbp,8), %ymm2, %ymm12
    vpcmpgtb 2147483647(%rdi,%rsi,1), %ymm3, %ymm13
    vpcmpgtb gnu_back(%rip), %ymm6, %ymm14
    {vex3} vpcmpgtb %ymm7, %ymm15, %ymm5
    {vex3} vpcmpgtb 0(%r9), %ymm8, %ymm1
    {vex3} vpcmpgtb -1(%rsi), %ymm9, %ymm2
    {vex3} vpcmpgtb 4660(%r11), %ymm12, %ymm3
    {vex3} vpcmpgtb 0(%r12), %ymm13, %ymm6
    {vex3} vpcmpgtb 64(%rsp), %ymm14, %ymm7
    {vex3} vpcmpgtb 128(%r12), %ymm15, %ymm5
    {vex3} vpcmpgtb 0(%r9,%rax,2), %ymm8, %ymm1
    {vex3} vpcmpgtb 8(%rdi,%r15,4), %ymm9, %ymm2
    {vex3} vpcmpgtb -129(%r15,%rsi,8), %ymm12, %ymm3
    {vex3} vpcmpgtb gnu_fwd(%rip), %ymm13, %ymm6
    vpminub %xmm1, %xmm14, %xmm7
    vpminub 0(%rsi), %xmm15, %xmm5
    vpminub -128(%rcx), %xmm8, %xmm1
    vpminub -2147483648(%rdx), %xmm9, %xmm2
    vpminub 0(%rsp), %xmm12, %xmm3
    vpminub 127(%rsp), %xmm13, %xmm6
    vpminub 2147483647(%rsp), %xmm14, %xmm7
    vpminub 0(%rdx,%rdi,1), %xmm15, %xmm5
    vpminub -1(%rax,%rax,2), %xmm8, %xmm1
    vpminub 4660(%rcx,%rcx,4), %xmm9, %xmm2
    vpminub gnu_back(%rip), %xmm12, %xmm3
    {vex3} vpminub %xmm13, %xmm6, %xmm14
    {vex3} vpminub 0(%rbx), %xmm7, %xmm15
    {vex3} vpminub 64(%rdi), %xmm5, %xmm8
    {vex3} vpminub 128(%r14), %xmm1, %xmm9
    {vex3} vpminub 0(%rsp), %xmm2, %xmm12
    {vex3} vpminub 8(%r12), %xmm3, %xmm13
    {vex3} vpminub -129(%rsp), %xmm6, %xmm14
    {vex3} vpminub 0(%rsp,%rcx,8), %xmm7, %xmm15
    {vex3} vpminub -128(%rax,%r9,1), %xmm5, %xmm8
    {vex3} vpminub -2147483648(%r9,%rbp,2), %xmm1, %xmm9
    {vex3} vpminub gnu_fwd(%rip), %xmm2, %xmm12
    vpminub %ymm2, %ymm3, %ymm13
    vpminub 0(%rdi), %ymm6, %ymm14
    vpminub 127(%rbx), %ymm7, %ymm15
    vpminub 2147483647(%rbp), %ymm5, %ymm8
    vpminub 0(%rsp), %ymm1, %ymm9
    vpminub -1(%rsp), %ymm2, %ymm12
    vpminub 4660(%rsp), %ymm3, %ymm13
    vpminub 0(%rbx,%rdx,4), %ymm6, %ymm14
    vpminub 64(%rdx,%rbx,8), %ymm7, %ymm15
    vpminub 128(%rbx,%rbp,1), %ymm5, %ymm8
    vpminub gnu_back(%rip), %ymm1, %ymm9
    {vex3} vpminub %ymm2, %ymm12, %ymm3
    {vex3} vpminub 0(%r10), %ymm13, %ymm6
    {vex3} vpminub 8(%r15), %ymm14, %ymm7
    {vex3} vpminub -129(%rcx), %ymm15, %ymm5
    {vex3} vpminub 0(%r12), %ymm8, %ymm1
    {vex3} vpminub -128(%rsp), %ymm9, %ymm2
    {vex3} vpminub -2147483648(%r12), %ymm12, %ymm3
    {vex3} vpminub 0(%r14,%r12,2), %ymm13, %ymm6
    {vex3} vpminub 127(%rsp,%rax,4), %ymm14, %ymm7
    {vex3} vpminub 2147483647(%r13,%r15,8), %ymm15, %ymm5
    {vex3} vpminub gnu_fwd(%rip), %ymm8, %ymm1
    vpmaxub %xmm3, %xmm9, %xmm2
    vpmaxub 0(%rcx), %xmm12, %xmm3
    vpmaxub -1(%rsi), %xmm13, %xmm6
    vpmaxub 4660(%rdi), %xmm14, %xmm7
    vpmaxub 0(%rsp), %xmm15, %xmm5
    vpmaxub 64(%rsp), %xmm8, %xmm1
    vpmaxub 128(%rsp), %xmm9, %xmm2
    vpmaxub 0(%rsp,%rsi,1), %xmm12, %xmm3
    vpmaxub 8(%rsp,%rdi,2), %xmm13, %xmm6
    vpmaxub -129(%rbp,%rax,4), %xmm14, %xmm7
    vpmaxub gnu_back(%rip), %xmm15, %xmm5
    {vex3} vpmaxub %xmm8, %xmm1, %xmm9
    {vex3} vpmaxub 0(%rsi), %xmm2, %xmm12
    {vex3} vpmaxub -128(%r8), %xmm3, %xmm13
    {vex3} vpmaxub -2147483648(%rbp), %xmm6, %xmm14
    {vex3} vpmaxub 0(%rsp), %xmm7, %xmm15
    {vex3} vpmaxub 127(%r12), %xmm5, %xmm8
    {vex3} vpmaxub 2147483647(%rsp), %xmm1, %xmm9
    {vex3} vpmaxub 0(%rsi,%rsi,8), %xmm2, %xmm12
    {vex3} vpmaxub -1(%rbp,%rcx,1), %xmm3, %xmm13
    {vex3} vpmaxub 4660(%r12,%r9,2), %xmm6, %xmm14
    {vex3} vpmaxub gnu_fwd(%rip), %xmm7, %xmm15
    vpmaxub %ymm6, %ymm5, %ymm8
    vpmaxub 0(%rdx), %ymm1, %ymm9
    vpmaxub 64(%rcx), %ymm2, %ymm12
    vpmaxub 128(%rdx), %ymm3, %ymm13
    vpmaxub 0(%rsp), %ymm6, %ymm14
    vpmaxub 8(%rsp), %ymm7, %ymm15
    vpmaxub -129(%rsp), %ymm5, %ymm8
    vpmaxub 0(%rsi,%rcx,4), %ymm1, %ymm9
    vpmaxub -128(%rsi,%rdx,8), %ymm2, %ymm12
    vpmaxub -2147483648(%rdi,%rbx,1), %ymm3, %ymm13
    vpmaxub gnu_back(%rip), %ymm6, %ymm14
    {vex3} vpmaxub %ymm7, %ymm15, %ymm5
    {vex3} vpmaxub 0(%r11), %ymm8, %ymm1
    {vex3} vpmaxub 127(%r13), %ymm9, %ymm2
    {vex3} vpmaxub 2147483647(%rdx), %ymm12, %ymm3
    {vex3} vpmaxub 0(%r12), %ymm13, %ymm6
    {vex3} vpmaxub -1(%rsp), %ymm14, %ymm7
g52:
    {vex3} vpmaxub 4660(%r12), %ymm15, %ymm5
    {vex3} vpmaxub 0(%r15,%rbp,2), %ymm8, %ymm1
    {vex3} vpmaxub 64(%rdi,%r12,4), %ymm9, %ymm2
    {vex3} vpmaxub 128(%r15,%rax,8), %ymm12, %ymm3
    {vex3} vpmaxub gnu_fwd(%rip), %ymm13, %ymm6
    {vex3} vpminud %xmm14, %xmm7, %xmm15
    {vex3} vpminud 0(%rdi), %xmm5, %xmm8
    {vex3} vpminud 8(%r9), %xmm1, %xmm9
    {vex3} vpminud -129(%rbx), %xmm2, %xmm12
    {vex3} vpminud 0(%rsp), %xmm3, %xmm13
    {vex3} vpminud -128(%r12), %xmm6, %xmm14
    {vex3} vpminud -2147483648(%rsp), %xmm7, %xmm15
    {vex3} vpminud 0(%rax,%r15,1), %xmm5, %xmm8
    {vex3} vpminud 127(%rax,%rsi,2), %xmm1, %xmm9
    {vex3} vpminud 2147483647(%r9,%rcx,4), %xmm2, %xmm12
    {vex3} vpminud gnu_back(%rip), %xmm3, %xmm13
    {vex3} vpminud %ymm6, %ymm14, %ymm7
    {vex3} vpminud 0(%r14), %ymm15, %ymm5
    {vex3} vpminud -1(%r10), %ymm8, %ymm1
    {vex3} vpminud 4660(%rsi), %ymm9, %ymm2
    {vex3} vpminud 0(%r12), %ymm12, %ymm3
    {vex3} vpminud 64(%rsp), %ymm13, %ymm6
    {vex3} vpminud 128(%r12), %ymm14, %ymm7
    {vex3} vpminud 0(%r8,%r9,8), %ymm15, %ymm5
    {vex3} vpminud 8(%rsp,%rbp,1), %ymm8, %ymm1
    {vex3} vpminud -129(%r13,%r12,2), %ymm9, %ymm2
    {vex3} vpminud gnu_fwd(%rip), %ymm12, %ymm3
    {vex3} vpshufb %xmm13, %xmm6, %xmm14
    {vex3} vpshufb 0(%r15), %xmm7, %xmm15
    {vex3} vpshufb -128(%r11), %xmm5, %xmm8
    {vex3} vpshufb -2147483648(%rdi), %xmm1, %xmm9
    {vex3} vpshufb 0(%rsp), %xmm2, %xmm12
    {vex3} vpshufb 127(%r12), %xmm3, %xmm13
    {vex3} vpshufb 2147483647(%rsp), %xmm6, %xmm14
    {vex3} vpshufb 0(%rcx,%rax,4), %xmm7, %xmm15
    {vex3} vpshufb -1(%rbp,%r15,8), %xmm5, %xmm8
    {vex3} vpshufb 4660(%r12,%rsi,1), %xmm1, %xmm9
    {vex3} vpshufb gnu_back(%rip), %xmm2, %xmm12
    {vex3} vpshufb %ymm3, %ymm13, %ymm6
    {vex3} vpshufb 0(%rcx), %ymm14, %ymm7
    {vex3} vpshufb 64(%r14), %ymm15, %ymm5
    {vex3} vpshufb 128(%r15), %ymm8, %ymm1
    {vex3} vpshufb 0(%r12), %ymm9, %ymm2
    {vex3} vpshufb 8(%rsp), %ymm12, %ymm3
    {vex3} vpshufb -129(%r12), %ymm13, %ymm6
    {vex3} vpshufb 0(%r12,%rcx,2), %ymm14, %ymm7
    {vex3} vpshufb -128(%rdi,%r9,4), %ymm15, %ymm5
    {vex3} vpshufb -2147483648(%r15,%rbp,8), %ymm8, %ymm1
    {vex3} vpshufb gnu_fwd(%rip), %ymm9, %ymm2
    vmovdqa %xmm7, %xmm12
    vmovdqa 0(%rbx), %xmm3
    vmovdqa 127(%rbx), %xmm13
    vmovdqa 2147483647(%rbp), %xmm6
    vmovdqa 0(%rsp), %xmm14
    vmovdqa -1(%rsp), %xmm7
    vmovdqa 4660(%rsp), %xmm15
    vmovdqa 0(%rdi,%rbp,1), %xmm5
    vmovdqa 64(%rax,%rsi,2), %xmm8
    vmovdqa 128(%rcx,%rdi,4), %xmm1
    vmovdqa gnu_back(%rip), %xmm9
    {vex3} vmovdqa %xmm2, %xmm12
    {vex3} vmovdqa 0(%r8), %xmm3
    {vex3} vmovdqa 8(%rcx), %xmm13
    {vex3} vmovdqa -129(%r8), %xmm6
    {vex3} vmovdqa 0(%rsp), %xmm14
    {vex3} vmovdqa -128(%r12), %xmm7
    {vex3} vmovdqa -2147483648(%rsp), %xmm15
    {vex3} vmovdqa 0(%rdx,%r12,8), %xmm5
    {vex3} vmovdqa 127(%rax,%rax,1), %xmm8
    {vex3} vmovdqa 2147483647(%r9,%r15,2), %xmm1
    {vex3} vmovdqa gnu_fwd(%rip), %xmm9
    vmovdqa %ymm5, %ymm2
    vmovdqa 0(%rsi), %ymm12
    vmovdqa -1(%rsi), %ymm3
    vmovdqa 4660(%rdi), %ymm13
    vmovdqa 0(%rsp), %ymm6
    vmovdqa 64(%rsp), %ymm14
    vmovdqa 128(%rsp), %ymm7
    vmovdqa 0(%rax,%rax,4), %ymm15
    vmovdqa 8(%rdx,%rcx,8), %ymm5
    vmovdqa -129(%rbx,%rdx,1), %ymm8
    vmovdqa gnu_back(%rip), %ymm1
    {vex3} vmovdqa %ymm9, %ymm2
    {vex3} vmovdqa 0(%rdx), %ymm12
    {vex3} vmovdqa -128(%rbp), %ymm3
    {vex3} vmovdqa -2147483648(%r13), %ymm13
    {vex3} vmovdqa 0(%r12), %ymm6
    {vex3} vmovdqa 127(%rsp), %ymm14
    {vex3} vmovdqa 2147483647(%r12), %ymm7
    {vex3} vmovdqa 0(%r9,%rsi,2), %ymm15
    {vex3} vmovdqa -1(%rsp,%rcx,4), %ymm5
    {vex3} vmovdqa 4660(%r13,%r9,8), %ymm8
    {vex3} vmovdqa gnu_fwd(%rip), %ymm1
    {store} vmovdqa %xmm9, %xmm4
    {vex3} {store} vmovdqa %xmm2, %xmm12
    {store} vmovdqa %ymm3, %ymm1
    {vex3} {store} vmovdqa %ymm13, %ymm6
    vmovdqa %xmm14, 0(%rdi)
    vmovdqa %xmm7, 64(%rcx)
    vmovdqa %xmm15, 128(%rdx)
    vmovdqa %xmm5, 0(%rsp)
    vmovdqa %xmm8, 8(%rsp)
    vmovdqa %xmm1, -129(%rsp)
    vmovdqa %xmm9, 0(%rcx,%rbx,1)
    vmovdqa %xmm2, -128(%rsp,%rbp,2)
    vmovdqa %xmm12, -2147483648(%rbp,%rsi,4)
    vmovdqa %xmm3, gnu_back(%rip)
    {vex3} vmovdqa %xmm13, 0(%r9)
    {vex3} vmovdqa %xmm6, 127(%rdx)
    {vex3} vmovdqa %xmm14, 2147483647(%r9)
    {vex3} vmovdqa %xmm7, 0(%rsp)
    {vex3} vmovdqa %xmm15, -1(%r12)
    {vex3} vmovdqa %xmm5, 4660(%rsp)
    {vex3} vmovdqa %xmm8, 0(%rsp,%rbp,8)
    {vex3} vmovdqa %xmm1, 64(%rbp,%r12,1)
    {vex3} vmovdqa %xmm9, 128(%r12,%rax,2)
    {vex3} vmovdqa %xmm2, gnu_fwd(%rip)
    vmovdqa %ymm12, 0(%rcx)
    vmovdqa %ymm3, 8(%rbx)
    vmovdqa %ymm13, -129(%rbp)
    vmovdqa %ymm6, 0(%rsp)
    vmovdqa %ymm14, -128(%rsp)
    vmovdqa %ymm7, -2147483648(%rsp)
    vmovdqa %ymm15, 0(%rdx,%rdi,4)
    vmovdqa %ymm5, 127(%rsi,%rax,8)
    vmovdqa %ymm8, 2147483647(%rdi,%rcx,1)
    vmovdqa %ymm1, gnu_back(%rip)
    {vex3} vmovdqa %ymm9, 0(%rbx)
    {vex3} vmovdqa %ymm2, -1(%rbx)
    {vex3} vmovdqa %ymm12, 4660(%r10)
    {vex3} vmovdqa %ymm3, 0(%r12)
    {vex3} vmovdqa %ymm13, 64(%rsp)
    {vex3} vmovdqa %ymm6, 128(%r12)
    {vex3} vmovdqa %ymm14, 0(%r14,%r15,2)
    {vex3} vmovdqa %ymm7, 8(%rdi,%rsi,4)
    {vex3} vmovdqa %ymm15, -129(%r15,%rcx,8)
    {vex3} vmovdqa %ymm5, gnu_fwd(%rip)
    vmovdqu %xmm2, %xmm8
    vmovdqu 0(%rdx), %xmm1
    vmovdqu -128(%rsi), %xmm9
    vmovdqu -2147483648(%rdi), %xmm2
    vmovdqu 0(%rsp), %xmm12
    vmovdqu 127(%rsp), %xmm3
    vmovdqu 2147483647(%rsp), %xmm13
    vmovdqu 0(%rbx,%rdx,1), %xmm6
    vmovdqu -1(%rax,%rbx,2), %xmm14
    vmovdqu 4660(%rcx,%rbp,4), %xmm7
    vmovdqu gnu_back(%rip), %xmm15
    {vex3} vmovdqu %xmm5, %xmm8
    {vex3} vmovdqu 0(%r10), %xmm1
    {vex3} vmovdqu 64(%rsi), %xmm9
    {vex3} vmovdqu 128(%r11), %xmm2
    {vex3} vmovdqu 0(%rsp), %xmm12
    {vex3} vmovdqu 8(%r12), %xmm3
    {vex3} vmovdqu -129(%rsp), %xmm13
    {vex3} vmovdqu 0(%rsi,%r9,8), %xmm6
    {vex3} vmovdqu -128(%rax,%rbp,1), %xmm14
    {vex3} vmovdqu -2147483648(%r9,%r12,2), %xmm7
    {vex3} vmovdqu gnu_fwd(%rip), %xmm15
    vmovdqu %ymm3, %ymm5
    vmovdqu 0(%rbx), %ymm8
    vmovdqu 127(%rcx), %ymm1
    vmovdqu 2147483647(%rdx), %ymm9
    vmovdqu 0(%rsp), %ymm2
    vmovdqu -1(%rsp), %ymm12
    vmovdqu 4660(%rsp), %ymm3
    vmovdqu 0(%rsp,%rsi,4), %ymm13
    vmovdqu 64(%rdx,%rdi,8), %ymm6
    vmovdqu 128(%rbx,%rax,1), %ymm14
    vmovdqu gnu_back(%rip), %ymm7
    {vex3} vmovdqu %ymm15, %ymm5
    {vex3} vmovdqu 0(%rsi), %ymm8
    {vex3} vmovdqu 8(%rdi), %ymm1
    {vex3} vmovdqu -129(%r14), %ymm9
    {vex3} vmovdqu 0(%r12), %ymm2
    {vex3} vmovdqu -128(%rsp), %ymm12
    {vex3} vmovdqu -2147483648(%r12), %ymm3
    {vex3} vmovdqu 0(%r15,%rax,2), %ymm13
    {vex3} vmovdqu 127(%rsp,%r15,4), %ymm6
    {vex3} vmovdqu 2147483647(%r13,%rsi,8), %ymm14
    {vex3} vmovdqu gnu_fwd(%rip), %ymm7
    {store} vmovdqu %xmm15, %xmm6
    {vex3} {store} vmovdqu %xmm5, %xmm8
    {store} vmovdqu %ymm1, %ymm7
    {vex3} {store} vmovdqu %ymm9, %ymm2
    vmovdqu %xmm12, 0(%rsi)
    vmovdqu %xmm3, -1(%rbx)
    vmovdqu %xmm13, 4660(%rbp)
    vmovdqu %xmm6, 0(%rsp)
    vmovdqu %xmm14, 64(%rsp)
    vmovdqu %xmm7, 128(%rsp)
    vmovdqu %xmm15, 0(%rsi,%rcx,1)
    vmovdqu %xmm5, 8(%rsp,%rdx,2)
    vmovdqu %xmm8, -129(%rbp,%rbx,4)
    vmovdqu %xmm1, gnu_back(%rip)
    {vex3} vmovdqu %xmm9, 0(%r11)
    {vex3} vmovdqu %xmm2, -128(%r15)
    {vex3} vmovdqu %xmm12, -2147483648(%rcx)
    {vex3} vmovdqu %xmm3, 0(%rsp)
    {vex3} vmovdqu %xmm13, 127(%r12)
g53:
    {vex3} vmovdqu %xmm6, 2147483647(%rsp)
    {vex3} vmovdqu %xmm14, 0(%rax,%rcx,8)
    {vex3} vmovdqu %xmm7, -1(%rbp,%r9,1)
    {vex3} vmovdqu %xmm15, 4660(%r12,%rbp,2)
    {vex3} vmovdqu %xmm5, gnu_fwd(%rip)
    vmovdqu %ymm8, 0(%rdi)
    vmovdqu %ymm1, 64(%rsi)
    vmovdqu %ymm9, 128(%rdi)
    vmovdqu %ymm2, 0(%rsp)
    vmovdqu %ymm12, 8(%rsp)
    vmovdqu %ymm3, -129(%rsp)
    vmovdqu %ymm13, 0(%rdi,%rbp,4)
    vmovdqu %ymm6, -128(%rsi,%rsi,8)
    vmovdqu %ymm14, -2147483648(%rdi,%rdi,1)
    vmovdqu %ymm7, gnu_back(%rip)
    {vex3} vmovdqu %ymm15, 0(%rdi)
    {vex3} vmovdqu %ymm5, 127(%r8)
    {vex3} vmovdqu %ymm8, 2147483647(%rbp)
    {vex3} vmovdqu %ymm1, 0(%r12)
    {vex3} vmovdqu %ymm9, -1(%rsp)
    {vex3} vmovdqu %ymm2, 4660(%r12)
    {vex3} vmovdqu %ymm12, 0(%r8,%r12,2)
    {vex3} vmovdqu %ymm3, 64(%rdi,%rax,4)
    {vex3} vmovdqu %ymm13, 128(%r15,%r15,8)
    {vex3} vmovdqu %ymm6, gnu_fwd(%rip)
    vmovaps %xmm5, %xmm14
    vmovaps 0(%rcx), %xmm7
    vmovaps 8(%rcx), %xmm15
    vmovaps -129(%rdx), %xmm5
    vmovaps 0(%rsp), %xmm8
    vmovaps -128(%rsp), %xmm1
    vmovaps -2147483648(%rsp), %xmm9
    vmovaps 0(%rax,%rax,1), %xmm2
    vmovaps 127(%rax,%rcx,2), %xmm12
    vmovaps 2147483647(%rcx,%rdx,4), %xmm3
    vmovaps gnu_back(%rip), %xmm13
    {vex3} vmovaps %xmm6, %xmm14
    {vex3} vmovaps 0(%r14), %xmm7
    {vex3} vmovaps -1(%r13), %xmm15
    {vex3} vmovaps 4660(%rdx), %xmm5
    {vex3} vmovaps 0(%rsp), %xmm8
    {vex3} vmovaps 64(%r12), %xmm1
    {vex3} vmovaps 128(%rsp), %xmm9
    {vex3} vmovaps 0(%rcx,%rsi,8), %xmm2
    {vex3} vmovaps 8(%rax,%rcx,1), %xmm12
    {vex3} vmovaps -129(%r9,%r9,2), %xmm3
    {vex3} vmovaps gnu_fwd(%rip), %xmm13
    vmovaps %ymm4, %ymm6
    vmovaps 0(%rdx), %ymm14
    vmovaps -128(%rbx), %ymm7
    vmovaps -2147483648(%rbp), %ymm15
    vmovaps 0(%rsp), %ymm5
    vmovaps 127(%rsp), %ymm8
    vmovaps 2147483647(%rsp), %ymm1
    vmovaps 0(%rcx,%rbx,4), %ymm9
    vmovaps -1(%rdx,%rbp,8), %ymm2
    vmovaps 4660(%rbx,%rsi,1), %ymm12
    vmovaps gnu_back(%rip), %ymm3
    {vex3} vmovaps %ymm13, %ymm6
    {vex3} vmovaps 0(%r15), %ymm14
    {vex3} vmovaps 64(%r9), %ymm7
    {vex3} vmovaps 128(%rbx), %ymm15
    {vex3} vmovaps 0(%r12), %ymm5
    {vex3} vmovaps 8(%rsp), %ymm8
    {vex3} vmovaps -129(%r12), %ymm1
    {vex3} vmovaps 0(%r12,%rbp,2), %ymm9
    {vex3} vmovaps -128(%rsp,%r12,4), %ymm2
    {vex3} vmovaps -2147483648(%r13,%rax,8), %ymm12
    {vex3} vmovaps gnu_fwd(%rip), %ymm3
    {store} vmovaps %xmm13, %xmm1
    {vex3} {store} vmovaps %xmm6, %xmm14
    {store} vmovaps %ymm7, %ymm2
    {vex3} {store} vmovaps %ymm15, %ymm5
    vmovaps %xmm8, 0(%rbx)
    vmovaps %xmm1, 127(%rsi)
    vmovaps %xmm9, 2147483647(%rdi)
    vmovaps %xmm2, 0(%rsp)
    vmovaps %xmm12, -1(%rsp)
    vmovaps %xmm3, 4660(%rsp)
    vmovaps %xmm13, 0(%rdx,%rdi,1)
    vmovaps %xmm6, 64(%rsp,%rax,2)
    vmovaps %xmm14, 128(%rbp,%rcx,4)
    vmovaps %xmm7, gnu_back(%rip)
    {vex3} vmovaps %xmm15, 0(%rcx)
    {vex3} vmovaps %xmm5, 8(%r10)
    {vex3} vmovaps %xmm8, -129(%rsi)
    {vex3} vmovaps %xmm1, 0(%rsp)
    {vex3} vmovaps %xmm9, -128(%r12)
    {vex3} vmovaps %xmm2, -2147483648(%rsp)
    {vex3} vmovaps %xmm12, 0(%rdx,%r15,8)
    {vex3} vmovaps %xmm3, 127(%rbp,%rsi,1)
    {vex3} vmovaps %xmm13, 2147483647(%r12,%rcx,2)
    {vex3} vmovaps %xmm6, gnu_fwd(%rip)
    vmovaps %ymm14, 0(%rsi)
    vmovaps %ymm7, -1(%rcx)
    vmovaps %ymm15, 4660(%rdx)
    vmovaps %ymm5, 0(%rsp)
    vmovaps %ymm8, 64(%rsp)
    vmovaps %ymm1, 128(%rsp)
    vmovaps %ymm9, 0(%rbx,%rdx,4)
    vmovaps %ymm2, 8(%rsi,%rbx,8)
    vmovaps %ymm12, -129(%rdi,%rbp,1)
    vmovaps %ymm3, gnu_back(%rip)
    {vex3} vmovaps %ymm13, 0(%r8)
    {vex3} vmovaps %ymm6, -128(%r11)
    {vex3} vmovaps %ymm14, -2147483648(%rdi)
    {vex3} vmovaps %ymm7, 0(%r12)
    {vex3} vmovaps %ymm15, 127(%rsp)
    {vex3} vmovaps %ymm5, 2147483647(%r12)
    {vex3} vmovaps %ymm8, 0(%r9,%r9,2)
    {vex3} vmovaps %ymm1, -1(%rdi,%rbp,4)
    {vex3} vmovaps %ymm9, 4660(%r15,%r12,8)
    {vex3} vmovaps %ymm2, gnu_fwd(%rip)
    vmovups %xmm3, %xmm12
    vmovups 0(%rdi), %xmm3
    vmovups 64(%rbx), %xmm13
    vmovups 128(%rbp), %xmm6
    vmovups 0(%rsp), %xmm14
    vmovups 8(%rsp), %xmm7
    vmovups -129(%rsp), %xmm15
    vmovups 0(%rsp,%rsi,1), %xmm5
    vmovups -128(%rax,%rdi,2), %xmm8
    vmovups -2147483648(%rcx,%rax,4), %xmm1
    vmovups gnu_back(%rip), %xmm9
    {vex3} vmovups %xmm2, %xmm12
    {vex3} vmovups 0(%rdx), %xmm3
    {vex3} vmovups 127(%r14), %xmm13
    {vex3} vmovups 2147483647(%r15), %xmm6
    {vex3} vmovups 0(%rsp), %xmm14
    {vex3} vmovups -1(%r12), %xmm7
    {vex3} vmovups 4660(%rsp), %xmm15
    {vex3} vmovups 0(%rsp,%rax,8), %xmm5
    {vex3} vmovups 64(%rax,%r15,1), %xmm8
    {vex3} vmovups 128(%r9,%rsi,2), %xmm1
    {vex3} vmovups gnu_fwd(%rip), %xmm9
    vmovups %ymm6, %ymm2
    vmovups 0(%rcx), %ymm12
    vmovups 8(%rsi), %ymm3
    vmovups -129(%rdi), %ymm13
    vmovups 0(%rsp), %ymm6
    vmovups -128(%rsp), %ymm14
    vmovups -2147483648(%rsp), %ymm7
    vmovups 0(%rsi,%rcx,4), %ymm15
    vmovups 127(%rdx,%rdx,8), %ymm5
    vmovups 2147483647(%rbx,%rbx,1), %ymm8
    vmovups gnu_back(%rip), %ymm1
    {vex3} vmovups %ymm9, %ymm2
    {vex3} vmovups 0(%r9), %ymm12
    {vex3} vmovups -1(%rcx), %ymm3
    {vex3} vmovups 4660(%r8), %ymm13
    {vex3} vmovups 0(%r12), %ymm6
    {vex3} vmovups 64(%rsp), %ymm14
    {vex3} vmovups 128(%r12), %ymm7
    {vex3} vmovups 0(%r14,%rcx,2), %ymm15
    {vex3} vmovups 8(%rsp,%r9,4), %ymm5
    {vex3} vmovups -129(%r13,%rbp,8), %ymm8
    {vex3} vmovups gnu_fwd(%rip), %ymm1
    {store} vmovups %xmm9, %xmm7
    {vex3} {store} vmovups %xmm2, %xmm12
    {store} vmovups %ymm3, %ymm5
    {vex3} {store} vmovups %ymm13, %ymm6
    vmovups %xmm14, 0(%rdx)
    vmovups %xmm7, -128(%rcx)
    vmovups %xmm15, -2147483648(%rdx)
    vmovups %xmm5, 0(%rsp)
    vmovups %xmm8, 127(%rsp)
    vmovups %xmm1, 2147483647(%rsp)
    vmovups %xmm9, 0(%rdi,%rbp,1)
    vmovups %xmm2, -1(%rsp,%rsi,2)
    vmovups %xmm12, 4660(%rbp,%rdi,4)
    vmovups %xmm3, gnu_back(%rip)
    {vex3} vmovups %xmm13, 0(%rbx)
    {vex3} vmovups %xmm6, 64(%rbp)
    {vex3} vmovups %xmm14, 128(%r13)
    {vex3} vmovups %xmm7, 0(%rsp)
    {vex3} vmovups %xmm15, 8(%r12)
    {vex3} vmovups %xmm5, -129(%rsp)
    {vex3} vmovups %xmm8, 0(%rsi,%r12,8)
    {vex3} vmovups %xmm1, -128(%rbp,%rax,1)
    {vex3} vmovups %xmm9, -2147483648(%r12,%r15,2)
    {vex3} vmovups %xmm2, gnu_fwd(%rip)
    vmovups %ymm12, 0(%rbx)
    vmovups %ymm3, 127(%rbx)
    vmovups %ymm13, 2147483647(%rbp)
    vmovups %ymm6, 0(%rsp)
    vmovups %ymm14, -1(%rsp)
    vmovups %ymm7, 4660(%rsp)
    vmovups %ymm15, 0(%rax,%rax,4)
    vmovups %ymm5, 64(%rsi,%rcx,8)
    vmovups %ymm8, 128(%rdi,%rdx,1)
    vmovups %ymm1, gnu_back(%rip)
    {vex3} vmovups %ymm9, 0(%r10)
    {vex3} vmovups %ymm2, 8(%rdx)
    {vex3} vmovups %ymm12, -129(%r9)
    {vex3} vmovups %ymm3, 0(%r12)
    {vex3} vmovups %ymm13, -128(%rsp)
    {vex3} vmovups %ymm6, -2147483648(%r12)
    {vex3} vmovups %ymm14, 0(%r15,%rsi,2)
    {vex3} vmovups %ymm7, 127(%rdi,%rcx,4)
    {vex3} vmovups %ymm15, 2147483647(%r15,%r9,8)
g54:
    {vex3} vmovups %ymm5, gnu_fwd(%rip)
    vmovntdq %xmm8, 0(%rsi)
    vmovntdq %xmm1, -1(%rsi)
    vmovntdq %xmm9, 4660(%rdi)
    vmovntdq %xmm2, 0(%rsp)
    vmovntdq %xmm12, 64(%rsp)
    vmovntdq %xmm3, 128(%rsp)
    vmovntdq %xmm13, 0(%rcx,%rbx,1)
    vmovntdq %xmm6, 8(%rax,%rbp,2)
    vmovntdq %xmm14, -129(%rcx,%rsi,4)
    vmovntdq %xmm7, gnu_back(%rip)
    {vex3} vmovntdq %xmm15, 0(%rsi)
    {vex3} vmovntdq %xmm5, -128(%rbx)
    {vex3} vmovntdq %xmm8, -2147483648(%r10)
    {vex3} vmovntdq %xmm1, 0(%rsp)
    {vex3} vmovntdq %xmm9, 127(%r12)
    {vex3} vmovntdq %xmm2, 2147483647(%rsp)
    {vex3} vmovntdq %xmm12, 0(%rax,%rbp,8)
    {vex3} vmovntdq %xmm3, -1(%rax,%r12,1)
    {vex3} vmovntdq %xmm13, 4660(%r9,%rax,2)
    {vex3} vmovntdq %xmm6, gnu_fwd(%rip)
    vmovntdq %ymm14, 0(%rdi)
    vmovntdq %ymm7, 64(%rcx)
    vmovntdq %ymm15, 128(%rdx)
    vmovntdq %ymm5, 0(%rsp)
    vmovntdq %ymm8, 8(%rsp)
    vmovntdq %ymm1, -129(%rsp)
    vmovntdq %ymm9, 0(%rdx,%rdi,4)
    vmovntdq %ymm2, -128(%rdx,%rax,8)
    vmovntdq %ymm12, -2147483648(%rbx,%rcx,1)
    vmovntdq %ymm3, gnu_back(%rip)
    {vex3} vmovntdq %ymm13, 0(%r11)
    {vex3} vmovntdq %ymm6, 127(%rsi)
    {vex3} vmovntdq %ymm14, 2147483647(%r11)
    {vex3} vmovntdq %ymm7, 0(%r12)
    {vex3} vmovntdq %ymm15, -1(%rsp)
    {vex3} vmovntdq %ymm5, 4660(%r12)
    {vex3} vmovntdq %ymm8, 0(%r8,%r15,2)
    {vex3} vmovntdq %ymm1, 64(%rsp,%rsi,4)
    {vex3} vmovntdq %ymm9, 128(%r13,%rcx,8)
    {vex3} vmovntdq %ymm2, gnu_fwd(%rip)
    {vex3} vpbroadcastb %xmm12, %xmm3
    {vex3} vpbroadcastb 0(%rdi), %xmm13
    {vex3} vpbroadcastb 8(%rdi), %xmm6
    {vex3} vpbroadcastb -129(%r14), %xmm14
    {vex3} vpbroadcastb 0(%rsp), %xmm7
    {vex3} vpbroadcastb -128(%r12), %xmm15
    {vex3} vpbroadcastb -2147483648(%rsp), %xmm5
    {vex3} vpbroadcastb 0(%rcx,%r9,1), %xmm8
    {vex3} vpbroadcastb 127(%rbp,%rbp,2), %xmm1
    {vex3} vpbroadcastb 2147483647(%r12,%r12,4), %xmm9
    {vex3} vpbroadcastb gnu_back(%rip), %xmm2
    {vex3} vpbroadcastb %xmm12, %ymm3
    {vex3} vpbroadcastb 0(%r14), %ymm13
    {vex3} vpbroadcastb -1(%r15), %ymm6
    {vex3} vpbroadcastb 4660(%rcx), %ymm14
    {vex3} vpbroadcastb 0(%r12), %ymm7
    {vex3} vpbroadcastb 64(%rsp), %ymm15
    {vex3} vpbroadcastb 128(%r12), %ymm5
    {vex3} vpbroadcastb 0(%r12,%rax,8), %ymm8
    {vex3} vpbroadcastb 8(%rdi,%r15,1), %ymm1
    {vex3} vpbroadcastb -129(%r15,%rsi,2), %ymm9
    {vex3} vpbroadcastb gnu_fwd(%rip), %ymm2
    {vex3} vpbroadcastd %xmm12, %xmm3
    {vex3} vpbroadcastd 0(%r15), %xmm13
    {vex3} vpbroadcastd -128(%r8), %xmm6
    {vex3} vpbroadcastd -2147483648(%rbp), %xmm14
    {vex3} vpbroadcastd 0(%rsp), %xmm7
    {vex3} vpbroadcastd 127(%r12), %xmm15
    {vex3} vpbroadcastd 2147483647(%rsp), %xmm5
    {vex3} vpbroadcastd 0(%rdx,%rcx,4), %xmm8
    {vex3} vpbroadcastd -1(%rax,%r9,8), %xmm1
    {vex3} vpbroadcastd 4660(%r9,%rbp,1), %xmm9
    {vex3} vpbroadcastd gnu_back(%rip), %xmm2
    {vex3} vpbroadcastd %xmm12, %ymm3
    {vex3} vpbroadcastd 0(%rcx), %ymm13
    {vex3} vpbroadcastd 64(%r13), %ymm6
    {vex3} vpbroadcastd 128(%rdx), %ymm14
    {vex3} vpbroadcastd 0(%r12), %ymm7
    {vex3} vpbroadcastd 8(%rsp), %ymm15
    {vex3} vpbroadcastd -129(%r12), %ymm5
    {vex3} vpbroadcastd 0(%r9,%r12,2), %ymm8
    {vex3} vpbroadcastd -128(%rsp,%rax,4), %ymm1
    {vex3} vpbroadcastd -2147483648(%r13,%r15,8), %ymm9
    {vex3} vpbroadcastd gnu_fwd(%rip), %ymm2
    {vex3} vbroadcastss %xmm12, %xmm3
    {vex3} vbroadcastss 0(%r8), %xmm13
    {vex3} vbroadcastss 127(%r9), %xmm6
    {vex3} vbroadcastss 2147483647(%rbx), %xmm14
    {vex3} vbroadcastss 0(%rsp), %xmm7
    {vex3} vbroadcastss -1(%r12), %xmm15
    {vex3} vbroadcastss 4660(%rsp), %xmm5
    {vex3} vbroadcastss 0(%rsp,%rsi,1), %xmm8
    {vex3} vbroadcastss 64(%rbp,%rcx,2), %xmm1
    {vex3} vbroadcastss 128(%r12,%r9,4), %xmm9
    {vex3} vbroadcastss gnu_back(%rip), %xmm2
    {vex3} vbroadcastss %xmm12, %ymm3
    {vex3} vbroadcastss 0(%rdx), %ymm13
    {vex3} vbroadcastss 8(%r10), %ymm6
    {vex3} vbroadcastss -129(%rsi), %ymm14
    {vex3} vbroadcastss 0(%r12), %ymm7
    {vex3} vbroadcastss -128(%rsp), %ymm15
    {vex3} vbroadcastss -2147483648(%r12), %ymm5
    {vex3} vbroadcastss 0(%r14,%rbp,8), %ymm8
    {vex3} vbroadcastss 127(%rdi,%r12,1), %ymm1
    {vex3} vbroadcastss 2147483647(%r15,%rax,2), %ymm9
    {vex3} vbroadcastss gnu_fwd(%rip), %ymm2
    vpmovmskb %xmm4, %r12d
    {vex3} vpmovmskb %xmm3, %r13d
    vpmovmskb %ymm1, %esi
    {vex3} vpmovmskb %ymm14, %edi
    vmovd %edx, %xmm15
    vmovd 0(%rcx), %xmm5
    vmovd -1(%rbx), %xmm8
    vmovd 4660(%rbp), %xmm1
    vmovd 0(%rsp), %xmm9
    vmovd 64(%rsp), %xmm2
    vmovd 128(%rsp), %xmm12
    vmovd 0(%rbx,%rdx,4), %xmm3
    vmovd 8(%rsp,%rbx,8), %xmm13
    vmovd -129(%rbp,%rbp,1), %xmm6
    vmovd gnu_back(%rip), %xmm14
    {vex3} vmovd %edi, %xmm15
    {vex3} vmovd 0(%r9), %xmm5
    {vex3} vmovd -128(%r11), %xmm8
    {vex3} vmovd -2147483648(%rdi), %xmm1
    {vex3} vmovd 0(%rsp), %xmm9
    {vex3} vmovd 127(%r12), %xmm2
    {vex3} vmovd 2147483647(%rsp), %xmm12
    {vex3} vmovd 0(%rsi,%r15,2), %xmm3
    {vex3} vmovd -1(%rax,%rsi,4), %xmm13
    {vex3} vmovd 4660(%r9,%rcx,8), %xmm6
    {vex3} vmovd gnu_fwd(%rip), %xmm14
    vmovd %xmm7, %ebx
    vmovd %xmm15, 0(%rdx)
    vmovd %xmm5, 64(%rsi)
    vmovd %xmm8, 128(%rdi)
    vmovd %xmm1, 0(%rsp)
    vmovd %xmm9, 8(%rsp)
    vmovd %xmm2, -129(%rsp)
    vmovd %xmm12, 0(%rsp,%rsi,1)
    vmovd %xmm3, -128(%rsi,%rdi,2)
    vmovd %xmm13, -2147483648(%rdi,%rax,4)
    vmovd %xmm6, gnu_back(%rip)
    {vex3} vmovd %xmm14, %edi
    {vex3} vmovd %xmm15, 0(%rbx)
    {vex3} vmovd %xmm5, 127(%r14)
    {vex3} vmovd %xmm8, 2147483647(%r15)
    {vex3} vmovd %xmm1, 0(%r12)
    {vex3} vmovd %xmm9, -1(%rsp)
    {vex3} vmovd %xmm2, 4660(%r12)
    {vex3} vmovd %xmm12, 0(%r15,%r9,8)
    {vex3} vmovd %xmm3, 64(%rsp,%rbp,1)
    {vex3} vmovd %xmm13, 128(%r13,%r12,2)
    {vex3} vmovd %xmm6, gnu_fwd(%rip)
    {vex3} vmovq %r14, %xmm7
    {vex3} vmovq %xmm15, %rbp
    vmovq 0(%rbx), %xmm8
    vmovq 8(%rcx), %xmm1
    vmovq -129(%rdx), %xmm9
    vmovq 0(%rsp), %xmm2
    vmovq -128(%rsp), %xmm12
    vmovq -2147483648(%rsp), %xmm3
    vmovq 0(%rsi,%rcx,4), %xmm13
    vmovq 127(%rax,%rdx,8), %xmm6
    vmovq 2147483647(%rcx,%rbx,1), %xmm14
    vmovq gnu_back(%rip), %xmm7
    {vex3} vmovq 0(%r10), %xmm15
    {vex3} vmovq -1(%rcx), %xmm5
    {vex3} vmovq 4660(%r8), %xmm8
    {vex3} vmovq 0(%rsp), %xmm1
    {vex3} vmovq 64(%r12), %xmm9
    {vex3} vmovq 128(%rsp), %xmm2
    {vex3} vmovq 0(%rax,%rax,2), %xmm12
    {vex3} vmovq 8(%rbp,%r15,4), %xmm3
    {vex3} vmovq -129(%r12,%rsi,8), %xmm13
    {vex3} vmovq gnu_fwd(%rip), %xmm6
    vmovq %xmm14, 0(%rsi)
    vmovq %xmm7, -128(%rbx)
    vmovq %xmm15, -2147483648(%rbp)
    vmovq %xmm5, 0(%rsp)
    vmovq %xmm8, 127(%rsp)
    vmovq %xmm1, 2147483647(%rsp)
    vmovq %xmm9, 0(%rdi,%rbp,1)
    vmovq %xmm2, -1(%rdx,%rsi,2)
    vmovq %xmm12, 4660(%rbx,%rdi,4)
    vmovq %xmm3, gnu_back(%rip)
    {vex3} vmovq %xmm13, 0(%rsi)
    {vex3} vmovq %xmm6, 64(%rbp)
    {vex3} vmovq %xmm14, 128(%r13)
    {vex3} vmovq %xmm7, 0(%r12)
    {vex3} vmovq %xmm15, 8(%rsp)
    {vex3} vmovq %xmm5, -129(%r12)
    {vex3} vmovq %xmm8, 0(%r8,%rcx,8)
    {vex3} vmovq %xmm1, -128(%rdi,%r9,1)
    {vex3} vmovq %xmm9, -2147483648(%r15,%rbp,2)
    {vex3} vmovq %xmm2, gnu_fwd(%rip)
    vzeroupper
    vzeroall
    kmovd %esi, %k1
g55:
    {vex3} kmovd %r12d, %k2
    kmovd %k1, %ebx
    {vex3} kmovd %k3, %r13d
    {vex3} kmovq %rsi, %k4
    {vex3} kmovq %k5, %r14
    kortestb %k2, %k6
    {vex3} kortestb %k7, %k1
    kortestw %k3, %k2
    {vex3} kortestw %k3, %k4
    {vex3} kortestd %k5, %k6
    {vex3} kortestq %k7, %k1
    {vex3} kord %k2, %k3, %k4
    {vex3} korq %k5, %k6, %k7
    korw %k4, %k1, %k2
    {vex3} korw %k3, %k4, %k5
    {vex3} andn %edi, %r15d, %ebp
    {vex3} andn 0(%r11), %r8d, %ecx
    {vex3} andn 127(%rdx), %r9d, %edx
    {vex3} andn 2147483647(%r9), %r12d, %ebx
    {vex3} andn 0(%rsp), %r13d, %esi
    {vex3} andn -1(%r12), %r14d, %edi
    {vex3} andn 4660(%rsp), %r15d, %ebp
    {vex3} andn 0(%rcx,%r12,4), %r8d, %ecx
    {vex3} andn 64(%rax,%rax,8), %r9d, %edx
    {vex3} andn 128(%r9,%r15,1), %r12d, %ebx
    {vex3} andn gnu_back(%rip), %r13d, %esi
    {vex3} bzhi %r14d, %edi, %r15d
    {vex3} bzhi %ebp, 0(%rdi), %r8d
    {vex3} bzhi %ecx, 8(%rbx), %r9d
    {vex3} bzhi %edx, -129(%r10), %r12d
    {vex3} bzhi %ebx, 0(%r12), %r13d
    {vex3} bzhi %esi, -128(%rsp), %r14d
    {vex3} bzhi %edi, -2147483648(%r12), %r15d
    {vex3} bzhi %ebp, 0(%r12,%rsi,2), %r8d
    {vex3} bzhi %ecx, 127(%rsp,%rcx,4), %r9d
    {vex3} bzhi %edx, 2147483647(%r13,%r9,8), %r12d
    {vex3} bzhi %ebx, gnu_fwd(%rip), %r13d
    {vex3} blsmsk %esi, %r14d
    {vex3} blsmsk 0(%r14), %edi
    {vex3} blsmsk -1(%rsi), %r15d
    {vex3} blsmsk 4660(%r11), %ebp
    {vex3} blsmsk 0(%rsp), %r8d
    {vex3} blsmsk 64(%r12), %ecx
    {vex3} blsmsk 128(%rsp), %r9d
    {vex3} blsmsk 0(%rdx,%rbp,1), %edx
    {vex3} blsmsk 8(%rbp,%r12,2), %r12d
    {vex3} blsmsk -129(%r12,%rax,4), %ebx
    {vex3} blsmsk gnu_back(%rip), %r13d
    {vex3} shlx %esi, %r14d, %edi
    {vex3} shlx %r15d, 0(%r15), %ebp
    {vex3} shlx %r8d, -128(%rdi), %ecx
    {vex3} shlx %r9d, -2147483648(%r14), %edx
    {vex3} shlx %r12d, 0(%r12), %ebx
    {vex3} shlx %r13d, 127(%rsp), %esi
    {vex3} shlx %r14d, 2147483647(%r12), %edi
    {vex3} shlx %r15d, 0(%r9,%r15,8), %ebp
    {vex3} shlx %r8d, -1(%rdi,%rsi,1), %ecx
    {vex3} shlx %r9d, 4660(%r15,%rcx,2), %edx
    {vex3} shlx %r12d, gnu_fwd(%rip), %ebx
    {vex3} shrx %r13d, %esi, %r14d
    {vex3} shrx %edi, 0(%rcx), %r15d
    {vex3} shrx %ebp, 64(%r15), %r8d
    {vex3} shrx %ecx, 128(%rcx), %r9d
    {vex3} shrx %edx, 0(%rsp), %r12d
    {vex3} shrx %ebx, 8(%r12), %r13d
    {vex3} shrx %esi, -129(%rsp), %r14d
    {vex3} shrx %edi, 0(%rsp,%r9,4), %r15d
    {vex3} shrx %ebp, -128(%rax,%rbp,8), %r8d
    {vex3} shrx %ecx, -2147483648(%r9,%r12,1), %r9d
    {vex3} shrx %edx, gnu_back(%rip), %r12d
    {vex3} sarx %ebx, %r13d, %esi
    {vex3} sarx %r14d, 0(%r8), %edi
    {vex3} sarx %r15d, 127(%r8), %ebp
    {vex3} sarx %r8d, 2147483647(%rbp), %ecx
    {vex3} sarx %r9d, 0(%r12), %edx
    {vex3} sarx %r12d, -1(%rsp), %ebx
    {vex3} sarx %r13d, 4660(%r12), %esi
    {vex3} sarx %r14d, 0(%r14,%rax,2), %edi
    {vex3} sarx %r15d, 64(%rsp,%r15,4), %ebp
    {vex3} sarx %r8d, 128(%r13,%rsi,8), %ecx
    {vex3} sarx %r9d, gnu_fwd(%rip), %edx
    {vex3} andn %r12, %rbx, %r13
    {vex3} andn 0(%rdx), %rsi, %r14
    {vex3} andn 8(%r13), %rdi, %r15
    {vex3} andn -129(%rdx), %rbp, %r8
    {vex3} andn 0(%rsp), %rcx, %r9
    {vex3} andn -128(%r12), %rdx, %r12
    {vex3} andn -2147483648(%rsp), %rbx, %r13
    {vex3} andn 0(%rsi,%rcx,1), %rsi, %r14
    {vex3} andn 127(%rbp,%r9,2), %rdi, %r15
    {vex3} andn 2147483647(%r12,%rbp,4), %rbp, %r8
    {vex3} andn gnu_back(%rip), %rcx, %r9
    {vex3} bzhi %rdx, %r12, %rbx
    {vex3} bzhi %r13, 0(%r9), %rsi
    {vex3} bzhi %r14, -1(%r9), %rdi
    {vex3} bzhi %r15, 4660(%rbx), %rbp
    {vex3} bzhi %r8, 0(%r12), %rcx
    {vex3} bzhi %r9, 64(%rsp), %rdx
    {vex3} bzhi %r12, 128(%r12), %rbx
    {vex3} bzhi %r13, 0(%r15,%r12,8), %rsi
    {vex3} bzhi %r14, 8(%rdi,%rax,1), %rdi
    {vex3} bzhi %r15, -129(%r15,%r15,2), %rbp
    {vex3} bzhi %r8, gnu_fwd(%rip), %rcx
    {vex3} blsmsk %r9, %rdx
    {vex3} blsmsk 0(%rbx), %r12
    {vex3} blsmsk -128(%r10), %rbx
    {vex3} blsmsk -2147483648(%rsi), %r13
    {vex3} blsmsk 0(%rsp), %rsi
    {vex3} blsmsk 127(%r12), %r14
    {vex3} blsmsk 2147483647(%rsp), %rdi
    {vex3} blsmsk 0(%rax,%rsi,4), %r15
    {vex3} blsmsk -1(%rax,%rcx,8), %rbp
    {vex3} blsmsk 4660(%r9,%r9,1), %r8
    {vex3} blsmsk gnu_back(%rip), %rcx
    {vex3} shlx %r9, %rdx, %r12
    {vex3} shlx %rbx, 0(%r10), %r13
    {vex3} shlx %rsi, 64(%r11), %r14
    {vex3} shlx %rdi, 128(%rdi), %r15
    {vex3} shlx %rbp, 0(%r12), %r8
    {vex3} shlx %rcx, 8(%rsp), %r9
    {vex3} shlx %rdx, -129(%r12), %r12
    {vex3} shlx %rbx, 0(%r8,%rbp,2), %r13
    {vex3} shlx %rsi, -128(%rsp,%r12,4), %r14
    {vex3} shlx %rdi, -2147483648(%r13,%rax,8), %r15
    {vex3} shlx %rbp, gnu_fwd(%rip), %r8
    {vex3} shrx %rcx, %r9, %rdx
    {vex3} shrx %r12, 0(%rsi), %rbx
    {vex3} shrx %r13, 127(%r14), %rsi
    {vex3} shrx %r14, 2147483647(%r15), %rdi
    {vex3} shrx %r15, 0(%rsp), %rbp
    {vex3} shrx %r8, -1(%r12), %rcx
    {vex3} shrx %r9, 4660(%rsp), %rdx
    {vex3} shrx %r12, 0(%rcx,%r15,1), %rbx
    {vex3} shrx %r13, 64(%rbp,%rsi,2), %rsi
    {vex3} shrx %r14, 128(%r12,%rcx,4), %rdi
    {vex3} shrx %r15, gnu_back(%rip), %rbp
    {vex3} sarx %r8, %rcx, %r9
    {vex3} sarx %rdx, 0(%r11), %r12
    {vex3} sarx %rbx, 8(%rcx), %r13
    {vex3} sarx %rsi, -129(%r8), %r14
    {vex3} sarx %rdi, 0(%r12), %r15
    {vex3} sarx %rbp, -128(%rsp), %r8
    {vex3} sarx %rcx, -2147483648(%r12), %r9
    {vex3} sarx %rdx, 0(%r12,%r9,8), %r12
    {vex3} sarx %rbx, 127(%rdi,%rbp,1), %r13
    {vex3} sarx %rsi, 2147483647(%r15,%r12,2), %r14
    {vex3} sarx %rdi, gnu_fwd(%rip), %r15
    {evex} vmovdqu64 %xmm16, %xmm3
    {evex} vmovdqu64 0(%rdi), %xmm25
    {evex} vmovdqu64 -2048(%rbp), %xmm9
    {evex} vmovdqu64 -2147483648(%r13), %xmm31
    {evex} vmovdqu64 0(%rsp), %xmm20
    {evex} vmovdqu64 2032(%r12), %xmm12
    {evex} vmovdqu64 2147483647(%rsp), %xmm17
    {evex} vmovdqu64 0(%rdx,%rax,4), %xmm16
    {evex} vmovdqu64 -16(%rax,%r15,8), %xmm3
    {evex} vmovdqu64 4660(%r9,%rsi,1), %xmm25
    {evex} vmovdqu64 gnu_back(%rip), %xmm9
    {evex} vmovdqu64 %xmm31, %xmm20{%k6}
    {evex} vmovdqu64 0(%r14), %xmm12{%k7}
    {evex} vmovdqu64 32(%rdx), %xmm17{%k1}
    {evex} vmovdqu64 -129(%r9), %xmm16{%k2}
    {evex} vmovdqu64 0(%r12), %xmm3{%k3}
    {evex} vmovdqu64 -2048(%rsp), %xmm25{%k4}
    {evex} vmovdqu64 1001(%r12), %xmm9{%k5}
    {evex} vmovdqu64 0(%r9,%rcx,2), %xmm31{%k6}
    {evex} vmovdqu64 2032(%rsp,%r9,4), %xmm20{%k7}
    {evex} vmovdqu64 -2147483648(%r13,%rbp,8), %xmm12{%k1}
    {evex} vmovdqu64 gnu_fwd(%rip), %xmm17{%k2}
    {evex} vmovdqu64 %xmm16, %xmm3{%k3}{z}
    {evex} vmovdqu64 0(%r15), %xmm25{%k4}{z}
    {evex} vmovdqu64 -16(%rbx), %xmm9{%k5}{z}
    {evex} vmovdqu64 2147483647(%r10), %xmm31{%k6}{z}
    {evex} vmovdqu64 0(%rsp), %xmm20{%k7}{z}
    {evex} vmovdqu64 32(%r12), %xmm12{%k1}{z}
    {evex} vmovdqu64 4660(%rsp), %xmm17{%k2}{z}
    {evex} vmovdqu64 0(%rsp,%r12,1), %xmm16{%k3}{z}
    {evex} vmovdqu64 -2048(%rbp,%rax,2), %xmm3{%k4}{z}
    {evex} vmovdqu64 -129(%r12,%r15,4), %xmm25{%k5}{z}
    {evex} vmovdqu64 gnu_back(%rip), %xmm9{%k6}{z}
    {evex} vmovdqu64 %ymm31, %ymm20
    {evex} vmovdqu64 0(%rcx), %ymm12
    {evex} vmovdqu64 -4096(%rsi), %ymm17
    {evex} vmovdqu64 1001(%r11), %ymm16
    {evex} vmovdqu64 0(%r12), %ymm3
    {evex} vmovdqu64 4064(%rsp), %ymm25
    {evex} vmovdqu64 -2147483648(%r12), %ymm9
    {evex} vmovdqu64 0(%r14,%rsi,8), %ymm31
    {evex} vmovdqu64 -32(%rdi,%rcx,1), %ymm20
    {evex} vmovdqu64 2147483647(%r15,%r9,2), %ymm12
    {evex} vmovdqu64 gnu_fwd(%rip), %ymm17
    {evex} vmovdqu64 %ymm16, %ymm3{%k7}
    {evex} vmovdqu64 0(%r8), %ymm25{%k1}
    {evex} vmovdqu64 64(%rdi), %ymm9{%k2}
    {evex} vmovdqu64 4660(%r14), %ymm31{%k3}
    {evex} vmovdqu64 0(%rsp), %ymm20{%k4}
    {evex} vmovdqu64 -4096(%r12), %ymm12{%k5}
    {evex} vmovdqu64 -129(%rsp), %ymm17{%k6}
    {evex} vmovdqu64 0(%rsi,%rbp,4), %ymm16{%k7}
    {evex} vmovdqu64 4064(%rax,%r12,8), %ymm3{%k1}
g56:
    {evex} vmovdqu64 1001(%r9,%rax,1), %ymm25{%k2}
    {evex} vmovdqu64 gnu_back(%rip), %ymm9{%k3}
    {evex} vmovdqu64 %ymm31, %ymm20{%k4}{z}
    {evex} vmovdqu64 0(%rdx), %ymm12{%k5}{z}
    {evex} vmovdqu64 -32(%r15), %ymm17{%k6}{z}
    {evex} vmovdqu64 -2147483648(%rcx), %ymm16{%k7}{z}
    {evex} vmovdqu64 0(%r12), %ymm3{%k1}{z}
    {evex} vmovdqu64 64(%rsp), %ymm25{%k2}{z}
    {evex} vmovdqu64 2147483647(%r12), %ymm9{%k3}{z}
    {evex} vmovdqu64 0(%r15,%r15,2), %ymm31{%k4}{z}
    {evex} vmovdqu64 -4096(%rsp,%rsi,4), %ymm20{%k5}{z}
    {evex} vmovdqu64 4660(%r13,%rcx,8), %ymm12{%k6}{z}
    {evex} vmovdqu64 gnu_fwd(%rip), %ymm17{%k7}{z}
    {evex} vmovdqu64 %zmm16, %zmm3
    {evex} vmovdqu64 0(%r9), %zmm25
    {evex} vmovdqu64 -8192(%r8), %zmm9
    {evex} vmovdqu64 -129(%rbp), %zmm31
    {evex} vmovdqu64 0(%rsp), %zmm20
    {evex} vmovdqu64 8128(%r12), %zmm12
    {evex} vmovdqu64 1001(%rsp), %zmm17
    {evex} vmovdqu64 0(%rax,%r9,1), %zmm16
    {evex} vmovdqu64 -64(%rbp,%rbp,2), %zmm3
    {evex} vmovdqu64 -2147483648(%r12,%r12,4), %zmm25
    {evex} vmovdqu64 gnu_back(%rip), %zmm9
    {evex} vmovdqu64 %zmm31, %zmm20{%k1}
    {evex} vmovdqu64 0(%rbx), %zmm12{%k2}
    {evex} vmovdqu64 128(%r13), %zmm17{%k3}
    {evex} vmovdqu64 2147483647(%rdx), %zmm16{%k4}
    {evex} vmovdqu64 0(%r12), %zmm3{%k5}
    {evex} vmovdqu64 -8192(%rsp), %zmm25{%k6}
    {evex} vmovdqu64 4660(%r12), %zmm9{%k7}
    {evex} vmovdqu64 0(%r8,%rax,8), %zmm31{%k1}
    {evex} vmovdqu64 8128(%rdi,%r15,1), %zmm20{%k2}
    {evex} vmovdqu64 -129(%r15,%rsi,2), %zmm12{%k3}
    {evex} vmovdqu64 gnu_fwd(%rip), %zmm17{%k4}
    {evex} vmovdqu64 %zmm16, %zmm3{%k5}{z}
    {evex} vmovdqu64 0(%r10), %zmm25{%k6}{z}
    {evex} vmovdqu64 -64(%r9), %zmm9{%k7}{z}
    {evex} vmovdqu64 1001(%rbx), %zmm31{%k1}{z}
    {evex} vmovdqu64 0(%rsp), %zmm20{%k2}{z}
    {evex} vmovdqu64 128(%r12), %zmm12{%k3}{z}
    {evex} vmovdqu64 -2147483648(%rsp), %zmm17{%k4}{z}
    {evex} vmovdqu64 0(%rcx,%rcx,4), %zmm16{%k5}{z}
    {evex} vmovdqu64 -8192(%rax,%r9,8), %zmm3{%k6}{z}
    {evex} vmovdqu64 2147483647(%r9,%rbp,1), %zmm25{%k7}{z}
    {evex} vmovdqu64 gnu_back(%rip), %zmm9{%k1}{z}
    {evex} {store} vmovdqu64 %xmm31, %xmm20
    {evex} {store} vmovdqu64 %xmm12, %xmm17{%k2}
    {evex} {store} vmovdqu64 %xmm16, %xmm3{%k3}{z}
    {evex} {store} vmovdqu64 %ymm25, %ymm9
    {evex} {store} vmovdqu64 %ymm31, %ymm20{%k4}
    {evex} {store} vmovdqu64 %ymm12, %ymm17{%k5}{z}
    {evex} {store} vmovdqu64 %zmm16, %zmm3
    {evex} {store} vmovdqu64 %zmm25, %zmm9{%k6}
    {evex} {store} vmovdqu64 %zmm31, %zmm20{%k7}{z}
    {evex} vmovdqu64 %xmm12, 0(%rsi)
    {evex} vmovdqu64 %xmm17, 2032(%r10)
    {evex} vmovdqu64 %xmm16, 4660(%rsi)
    {evex} vmovdqu64 %xmm3, 0(%r12)
    {evex} vmovdqu64 %xmm25, -16(%rsp)
    {evex} vmovdqu64 %xmm9, -129(%r12)
    {evex} vmovdqu64 %xmm31, 0(%r12,%r12,2)
    {evex} vmovdqu64 %xmm20, 32(%rsp,%rax,4)
    {evex} vmovdqu64 %xmm12, 1001(%r13,%r15,8)
    {evex} vmovdqu64 %xmm17, gnu_fwd(%rip)
    {evex} vmovdqu64 %xmm16, 0(%r11){%k1}
    {evex} vmovdqu64 %xmm3, -2048(%r11){%k2}
    {evex} vmovdqu64 %xmm25, -2147483648(%rdi){%k3}
    {evex} vmovdqu64 %xmm9, 0(%rsp){%k4}
    {evex} vmovdqu64 %xmm31, 2032(%r12){%k5}
    {evex} vmovdqu64 %xmm20, 2147483647(%rsp){%k6}
    {evex} vmovdqu64 %xmm12, 0(%rdx,%rsi,1){%k7}
    {evex} vmovdqu64 %xmm17, -16(%rbp,%rcx,2){%k1}
    {evex} vmovdqu64 %xmm16, 4660(%r12,%r9,4){%k2}
    {evex} vmovdqu64 %xmm3, gnu_back(%rip){%k3}
    {evex} vmovdqu64 %ymm25, 0(%rdi)
    {evex} vmovdqu64 %ymm9, 4064(%r14)
    {evex} vmovdqu64 %ymm31, -129(%r15)
    {evex} vmovdqu64 %ymm20, 0(%r12)
    {evex} vmovdqu64 %ymm12, -32(%rsp)
    {evex} vmovdqu64 %ymm17, 1001(%r12)
    {evex} vmovdqu64 %ymm16, 0(%r9,%rbp,8)
    {evex} vmovdqu64 %ymm3, 64(%rdi,%r12,1)
    {evex} vmovdqu64 %ymm25, -2147483648(%r15,%rax,2)
    {evex} vmovdqu64 %ymm9, gnu_fwd(%rip)
    {evex} vmovdqu64 %ymm31, 0(%r14){%k4}
    {evex} vmovdqu64 %ymm20, -4096(%rcx){%k5}
    {evex} vmovdqu64 %ymm12, 2147483647(%r8){%k6}
    {evex} vmovdqu64 %ymm17, 0(%rsp){%k7}
    {evex} vmovdqu64 %ymm16, 4064(%r12){%k1}
    {evex} vmovdqu64 %ymm3, 4660(%rsp){%k2}
    {evex} vmovdqu64 %ymm25, 0(%rsp,%r15,4){%k3}
    {evex} vmovdqu64 %ymm9, -32(%rax,%rsi,8){%k4}
    {evex} vmovdqu64 %ymm31, -129(%r9,%rcx,1){%k5}
    {evex} vmovdqu64 %ymm20, gnu_back(%rip){%k6}
    {evex} vmovdqu64 %zmm12, 0(%r15)
    {evex} vmovdqu64 %zmm17, 8128(%rbp)
    {evex} vmovdqu64 %zmm16, 1001(%r13)
    {evex} vmovdqu64 %zmm3, 0(%r12)
    {evex} vmovdqu64 %zmm25, -64(%rsp)
    {evex} vmovdqu64 %zmm9, -2147483648(%r12)
    {evex} vmovdqu64 %zmm31, 0(%r14,%r9,2)
    {evex} vmovdqu64 %zmm20, 128(%rsp,%rbp,4)
    {evex} vmovdqu64 %zmm12, 2147483647(%r13,%r12,8)
    {evex} vmovdqu64 %zmm17, gnu_fwd(%rip)
    {evex} vmovdqu64 %zmm16, 0(%rcx){%k7}
    {evex} vmovdqu64 %zmm3, -8192(%rdx){%k1}
    {evex} vmovdqu64 %zmm25, 4660(%r9){%k2}
    {evex} vmovdqu64 %zmm9, 0(%rsp){%k3}
    {evex} vmovdqu64 %zmm31, 8128(%r12){%k4}
    {evex} vmovdqu64 %zmm20, -129(%rsp){%k5}
    {evex} vmovdqu64 %zmm12, 0(%rsi,%rax,1){%k6}
    {evex} vmovdqu64 %zmm17, -64(%rbp,%r15,2){%k7}
    {evex} vmovdqu64 %zmm16, 1001(%r12,%rsi,4){%k1}
    {evex} vmovdqu64 %zmm3, gnu_back(%rip){%k2}
    {evex} vmovdqu32 %xmm25, %xmm9
    {evex} vmovdqu32 0(%r8), %xmm31
    {evex} vmovdqu32 32(%rbx), %xmm20
    {evex} vmovdqu32 -2147483648(%r10), %xmm12
    {evex} vmovdqu32 0(%r12), %xmm17
    {evex} vmovdqu32 -2048(%rsp), %xmm16
    {evex} vmovdqu32 2147483647(%r12), %xmm3
    {evex} vmovdqu32 0(%r15,%rcx,8), %xmm25
    {evex} vmovdqu32 2032(%rdi,%r9,1), %xmm9
    {evex} vmovdqu32 4660(%r15,%rbp,2), %xmm31
    {evex} vmovdqu32 gnu_fwd(%rip), %xmm20
    {evex} vmovdqu32 %xmm12, %xmm17{%k3}
    {evex} vmovdqu32 0(%rdx), %xmm16{%k4}
    {evex} vmovdqu32 -16(%rsi), %xmm3{%k5}
    {evex} vmovdqu32 -129(%r11), %xmm25{%k6}
    {evex} vmovdqu32 0(%rsp), %xmm9{%k7}
    {evex} vmovdqu32 32(%r12), %xmm31{%k1}
    {evex} vmovdqu32 1001(%rsp), %xmm20{%k2}
    {evex} vmovdqu32 0(%rax,%r12,4), %xmm12{%k3}
    {evex} vmovdqu32 -2048(%rax,%rax,8), %xmm17{%k4}
    {evex} vmovdqu32 -2147483648(%r9,%r15,1), %xmm16{%k5}
    {evex} vmovdqu32 gnu_back(%rip), %xmm3{%k6}
    {evex} vmovdqu32 %xmm25, %xmm9{%k7}{z}
    {evex} vmovdqu32 0(%r9), %xmm31{%k1}{z}
    {evex} vmovdqu32 2032(%rdi), %xmm20{%k2}{z}
    {evex} vmovdqu32 2147483647(%r14), %xmm12{%k3}{z}
    {evex} vmovdqu32 0(%r12), %xmm17{%k4}{z}
    {evex} vmovdqu32 -16(%rsp), %xmm16{%k5}{z}
    {evex} vmovdqu32 4660(%r12), %xmm3{%k6}{z}
    {evex} vmovdqu32 0(%r8,%rsi,2), %xmm25{%k7}{z}
    {evex} vmovdqu32 32(%rsp,%rcx,4), %xmm9{%k1}{z}
    {evex} vmovdqu32 -129(%r13,%r9,8), %xmm31{%k2}{z}
    {evex} vmovdqu32 gnu_fwd(%rip), %xmm20{%k3}{z}
    {evex} vmovdqu32 %ymm12, %ymm17
    {evex} vmovdqu32 0(%rbx), %ymm16
    {evex} vmovdqu32 64(%r15), %ymm3
    {evex} vmovdqu32 1001(%rcx), %ymm25
    {evex} vmovdqu32 0(%rsp), %ymm9
    {evex} vmovdqu32 -4096(%r12), %ymm31
    {evex} vmovdqu32 -2147483648(%rsp), %ymm20
    {evex} vmovdqu32 0(%rcx,%rbp,1), %ymm12
    {evex} vmovdqu32 4064(%rbp,%r12,2), %ymm17
    {evex} vmovdqu32 2147483647(%r12,%rax,4), %ymm16
    {evex} vmovdqu32 gnu_back(%rip), %ymm3
    {evex} vmovdqu32 %ymm25, %ymm9{%k4}
    {evex} vmovdqu32 0(%r10), %ymm31{%k5}
    {evex} vmovdqu32 -32(%r8), %ymm20{%k6}
    {evex} vmovdqu32 4660(%rbp), %ymm12{%k7}
    {evex} vmovdqu32 0(%r12), %ymm17{%k1}
    {evex} vmovdqu32 64(%rsp), %ymm16{%k2}
    {evex} vmovdqu32 -129(%r12), %ymm3{%k3}
    {evex} vmovdqu32 0(%r12,%r15,8), %ymm25{%k4}
    {evex} vmovdqu32 -4096(%rdi,%rsi,1), %ymm9{%k5}
    {evex} vmovdqu32 1001(%r15,%rcx,2), %ymm31{%k6}
    {evex} vmovdqu32 gnu_fwd(%rip), %ymm20{%k7}
    {evex} vmovdqu32 %ymm12, %ymm17{%k1}{z}
    {evex} vmovdqu32 0(%rsi), %ymm16{%k2}{z}
    {evex} vmovdqu32 4064(%r13), %ymm3{%k3}{z}
    {evex} vmovdqu32 -2147483648(%rdx), %ymm25{%k4}{z}
    {evex} vmovdqu32 0(%rsp), %ymm9{%k5}{z}
    {evex} vmovdqu32 -32(%r12), %ymm31{%k6}{z}
    {evex} vmovdqu32 2147483647(%rsp), %ymm20{%k7}{z}
    {evex} vmovdqu32 0(%rdx,%r9,4), %ymm12{%k1}{z}
    {evex} vmovdqu32 64(%rax,%rbp,8), %ymm17{%k2}{z}
    {evex} vmovdqu32 4660(%r9,%r12,1), %ymm16{%k3}{z}
    {evex} vmovdqu32 gnu_back(%rip), %ymm3{%k4}{z}
    {evex} vmovdqu32 %zmm25, %zmm9
    {evex} vmovdqu32 0(%r11), %zmm31
    {evex} vmovdqu32 128(%r9), %zmm20
    {evex} vmovdqu32 -129(%rbx), %zmm12
    {evex} vmovdqu32 0(%r12), %zmm17
    {evex} vmovdqu32 -8192(%rsp), %zmm16
    {evex} vmovdqu32 1001(%r12), %zmm3
    {evex} vmovdqu32 0(%r9,%rax,2), %zmm25
    {evex} vmovdqu32 8128(%rsp,%r15,4), %zmm9
    {evex} vmovdqu32 -2147483648(%r13,%rsi,8), %zmm31
    {evex} vmovdqu32 gnu_fwd(%rip), %zmm20
    {evex} vmovdqu32 %zmm12, %zmm17{%k5}
    {evex} vmovdqu32 0(%rdi), %zmm16{%k6}
    {evex} vmovdqu32 -64(%r10), %zmm3{%k7}
    {evex} vmovdqu32 2147483647(%rsi), %zmm25{%k1}
    {evex} vmovdqu32 0(%rsp), %zmm9{%k2}
    {evex} vmovdqu32 128(%r12), %zmm31{%k3}
    {evex} vmovdqu32 4660(%rsp), %zmm20{%k4}
    {evex} vmovdqu32 0(%rsp,%rcx,1), %zmm12{%k5}
g57:
    {evex} vmovdqu32 -8192(%rbp,%r9,2), %zmm17{%k6}
    {evex} vmovdqu32 -129(%r12,%rbp,4), %zmm16{%k7}
    {evex} vmovdqu32 gnu_back(%rip), %zmm3{%k1}
    {evex} vmovdqu32 %zmm25, %zmm9{%k2}{z}
    {evex} vmovdqu32 0(%r14), %zmm31{%k3}{z}
    {evex} vmovdqu32 8128(%r11), %zmm20{%k4}{z}
    {evex} vmovdqu32 1001(%rdi), %zmm12{%k5}{z}
    {evex} vmovdqu32 0(%r12), %zmm17{%k6}{z}
    {evex} vmovdqu32 -64(%rsp), %zmm16{%k7}{z}
    {evex} vmovdqu32 -2147483648(%r12), %zmm3{%k1}{z}
    {evex} vmovdqu32 0(%r14,%r12,8), %zmm25{%k2}{z}
    {evex} vmovdqu32 128(%rdi,%rax,1), %zmm9{%k3}{z}
    {evex} vmovdqu32 2147483647(%r15,%r15,2), %zmm31{%k4}{z}
    {evex} vmovdqu32 gnu_fwd(%rip), %zmm20{%k5}{z}
    {evex} {store} vmovdqu32 %xmm12, %xmm17
    {evex} {store} vmovdqu32 %xmm16, %xmm3{%k6}
    {evex} {store} vmovdqu32 %xmm25, %xmm9{%k7}{z}
    {evex} {store} vmovdqu32 %ymm31, %ymm20
    {evex} {store} vmovdqu32 %ymm12, %ymm17{%k1}
    {evex} {store} vmovdqu32 %ymm16, %ymm3{%k2}{z}
    {evex} {store} vmovdqu32 %zmm25, %zmm9
    {evex} {store} vmovdqu32 %zmm31, %zmm20{%k3}
    {evex} {store} vmovdqu32 %zmm12, %zmm17{%k4}{z}
    {evex} vmovdqu32 %xmm16, 0(%r15)
    {evex} vmovdqu32 %xmm3, -2048(%r14)
    {evex} vmovdqu32 %xmm25, 4660(%r15)
    {evex} vmovdqu32 %xmm9, 0(%rsp)
    {evex} vmovdqu32 %xmm31, 2032(%r12)
    {evex} vmovdqu32 %xmm20, -129(%rsp)
    {evex} vmovdqu32 %xmm12, 0(%rsi,%rsi,4)
    {evex} vmovdqu32 %xmm17, -16(%rax,%rcx,8)
    {evex} vmovdqu32 %xmm16, 1001(%r9,%r9,1)
    {evex} vmovdqu32 %xmm3, gnu_back(%rip)
    {evex} vmovdqu32 %xmm25, 0(%rcx){%k5}
    {evex} vmovdqu32 %xmm9, 32(%rcx){%k6}
    {evex} vmovdqu32 %xmm31, -2147483648(%r8){%k7}
    {evex} vmovdqu32 %xmm20, 0(%r12){%k1}
    {evex} vmovdqu32 %xmm12, -2048(%rsp){%k2}
    {evex} vmovdqu32 %xmm17, 2147483647(%r12){%k3}
    {evex} vmovdqu32 %xmm16, 0(%r15,%rbp,2){%k4}
    {evex} vmovdqu32 %xmm3, 2032(%rsp,%r12,4){%k5}
    {evex} vmovdqu32 %xmm25, 4660(%r13,%rax,8){%k6}
    {evex} vmovdqu32 %xmm9, gnu_fwd(%rip){%k7}
    {evex} vmovdqu32 %ymm31, 0(%r8)
    {evex} vmovdqu32 %ymm20, -4096(%rbp)
    {evex} vmovdqu32 %ymm12, -129(%r13)
    {evex} vmovdqu32 %ymm17, 0(%rsp)
    {evex} vmovdqu32 %ymm16, 4064(%r12)
    {evex} vmovdqu32 %ymm3, 1001(%rsp)
    {evex} vmovdqu32 %ymm25, 0(%rax,%r15,1)
    {evex} vmovdqu32 %ymm9, -32(%rbp,%rsi,2)
    {evex} vmovdqu32 %ymm31, -2147483648(%r12,%rcx,4)
    {evex} vmovdqu32 %ymm20, gnu_back(%rip)
    {evex} vmovdqu32 %ymm12, 0(%rdx){%k1}
    {evex} vmovdqu32 %ymm17, 64(%rdx){%k2}
    {evex} vmovdqu32 %ymm16, 2147483647(%r9){%k3}
    {evex} vmovdqu32 %ymm3, 0(%r12){%k4}
    {evex} vmovdqu32 %ymm25, -4096(%rsp){%k5}
    {evex} vmovdqu32 %ymm9, 4660(%r12){%k6}
    {evex} vmovdqu32 %ymm31, 0(%r8,%r9,8){%k7}
    {evex} vmovdqu32 %ymm20, 4064(%rdi,%rbp,1){%k1}
    {evex} vmovdqu32 %ymm12, -129(%r15,%r12,2){%k2}
    {evex} vmovdqu32 %ymm17, gnu_fwd(%rip){%k3}
    {evex} vmovdqu32 %zmm16, 0(%r9)
    {evex} vmovdqu32 %zmm3, -8192(%rbx)
    {evex} vmovdqu32 %zmm25, 1001(%r10)
    {evex} vmovdqu32 %zmm9, 0(%rsp)
    {evex} vmovdqu32 %zmm31, 8128(%r12)
    {evex} vmovdqu32 %zmm20, -2147483648(%rsp)
    {evex} vmovdqu32 %zmm12, 0(%rcx,%rax,4)
    {evex} vmovdqu32 %zmm17, -64(%rax,%r15,8)
    {evex} vmovdqu32 %zmm16, 2147483647(%r9,%rsi,1)
    {evex} vmovdqu32 %zmm3, gnu_back(%rip)
    {evex} vmovdqu32 %zmm25, 0(%rbx){%k4}
    {evex} vmovdqu32 %zmm9, 128(%rsi){%k5}
    {evex} vmovdqu32 %zmm31, 4660(%r11){%k6}
    {evex} vmovdqu32 %zmm20, 0(%r12){%k7}
    {evex} vmovdqu32 %zmm12, -8192(%rsp){%k1}
    {evex} vmovdqu32 %zmm17, -129(%r12){%k2}
    {evex} vmovdqu32 %zmm16, 0(%r12,%rcx,2){%k3}
    {evex} vmovdqu32 %zmm3, 8128(%rsp,%r9,4){%k4}
    {evex} vmovdqu32 %zmm25, 1001(%r13,%rbp,8){%k5}
    {evex} vmovdqu32 %zmm9, gnu_fwd(%rip){%k6}
    {evex} vmovdqu8 %xmm31, %xmm20
    {evex} vmovdqu8 0(%r10), %xmm12
    {evex} vmovdqu8 -16(%rdi), %xmm17
    {evex} vmovdqu8 -2147483648(%r14), %xmm16
    {evex} vmovdqu8 0(%rsp), %xmm3
    {evex} vmovdqu8 32(%r12), %xmm25
    {evex} vmovdqu8 2147483647(%rsp), %xmm9
    {evex} vmovdqu8 0(%rdx,%r12,1), %xmm31
    {evex} vmovdqu8 -2048(%rbp,%rax,2), %xmm20
    {evex} vmovdqu8 4660(%r12,%r15,4), %xmm12
    {evex} vmovdqu8 gnu_back(%rip), %xmm17
    {evex} vmovdqu8 %xmm16, %xmm3{%k7}
    {evex} vmovdqu8 0(%rsi), %xmm25{%k1}
    {evex} vmovdqu8 2032(%r15), %xmm9{%k2}
    {evex} vmovdqu8 -129(%rcx), %xmm31{%k3}
    {evex} vmovdqu8 0(%r12), %xmm20{%k4}
    {evex} vmovdqu8 -16(%rsp), %xmm12{%k5}
    {evex} vmovdqu8 1001(%r12), %xmm17{%k6}
    {evex} vmovdqu8 0(%r9,%rsi,8), %xmm16{%k7}
    {evex} vmovdqu8 32(%rdi,%rcx,1), %xmm3{%k1}
    {evex} vmovdqu8 -2147483648(%r15,%r9,2), %xmm25{%k2}
    {evex} vmovdqu8 gnu_fwd(%rip), %xmm9{%k3}
    {evex} vmovdqu8 %xmm31, %xmm20{%k4}{z}
    {evex} vmovdqu8 0(%r11), %xmm12{%k5}{z}
    {evex} vmovdqu8 -2048(%r8), %xmm17{%k6}{z}
    {evex} vmovdqu8 2147483647(%rbp), %xmm16{%k7}{z}
    {evex} vmovdqu8 0(%rsp), %xmm3{%k1}{z}
    {evex} vmovdqu8 2032(%r12), %xmm25{%k2}{z}
    {evex} vmovdqu8 4660(%rsp), %xmm9{%k3}{z}
    {evex} vmovdqu8 0(%rsp,%rbp,4), %xmm31{%k4}{z}
    {evex} vmovdqu8 -16(%rax,%r12,8), %xmm20{%k5}{z}
    {evex} vmovdqu8 -129(%r9,%rax,1), %xmm12{%k6}{z}
    {evex} vmovdqu8 gnu_back(%rip), %xmm17{%k7}{z}
    {evex} vmovdqu8 %ymm16, %ymm3
    {evex} vmovdqu8 0(%rdi), %ymm25
    {evex} vmovdqu8 -32(%r13), %ymm9
    {evex} vmovdqu8 1001(%rdx), %ymm31
    {evex} vmovdqu8 0(%r12), %ymm20
    {evex} vmovdqu8 64(%rsp), %ymm12
    {evex} vmovdqu8 -2147483648(%r12), %ymm17
    {evex} vmovdqu8 0(%r14,%r15,2), %ymm16
    {evex} vmovdqu8 -4096(%rsp,%rsi,4), %ymm3
    {evex} vmovdqu8 2147483647(%r13,%rcx,8), %ymm25
    {evex} vmovdqu8 gnu_fwd(%rip), %ymm9
    {evex} vmovdqu8 %ymm31, %ymm20{%k1}
    {evex} vmovdqu8 0(%r14), %ymm12{%k2}
    {evex} vmovdqu8 4064(%r9), %ymm17{%k3}
    {evex} vmovdqu8 4660(%rbx), %ymm16{%k4}
    {evex} vmovdqu8 0(%rsp), %ymm3{%k5}
    {evex} vmovdqu8 -32(%r12), %ymm25{%k6}
    {evex} vmovdqu8 -129(%rsp), %ymm9{%k7}
    {evex} vmovdqu8 0(%rsi,%r9,1), %ymm31{%k1}
    {evex} vmovdqu8 64(%rbp,%rbp,2), %ymm20{%k2}
    {evex} vmovdqu8 1001(%r12,%r12,4), %ymm12{%k3}
    {evex} vmovdqu8 gnu_back(%rip), %ymm17{%k4}
    {evex} vmovdqu8 %ymm16, %ymm3{%k5}{z}
    {evex} vmovdqu8 0(%r15), %ymm25{%k6}{z}
    {evex} vmovdqu8 -4096(%r10), %ymm9{%k7}{z}
    {evex} vmovdqu8 -2147483648(%rsi), %ymm31{%k1}{z}
    {evex} vmovdqu8 0(%r12), %ymm20{%k2}{z}
    {evex} vmovdqu8 4064(%rsp), %ymm12{%k3}{z}
    {evex} vmovdqu8 2147483647(%r12), %ymm17{%k4}{z}
    {evex} vmovdqu8 0(%r15,%rax,8), %ymm16{%k5}{z}
    {evex} vmovdqu8 -32(%rdi,%r15,1), %ymm3{%k6}{z}
    {evex} vmovdqu8 4660(%r15,%rsi,2), %ymm25{%k7}{z}
    {evex} vmovdqu8 gnu_fwd(%rip), %ymm9{%k1}{z}
    {evex} vmovdqu8 %zmm31, %zmm20
    {evex} vmovdqu8 0(%rcx), %zmm12
    {evex} vmovdqu8 -64(%r11), %zmm17
    {evex} vmovdqu8 -129(%rdi), %zmm16
    {evex} vmovdqu8 0(%rsp), %zmm3
    {evex} vmovdqu8 128(%r12), %zmm25
    {evex} vmovdqu8 1001(%rsp), %zmm9
    {evex} vmovdqu8 0(%rax,%rcx,4), %zmm31
    {evex} vmovdqu8 -8192(%rax,%r9,8), %zmm20
    {evex} vmovdqu8 -2147483648(%r9,%rbp,1), %zmm12
    {evex} vmovdqu8 gnu_back(%rip), %zmm17
    {evex} vmovdqu8 %zmm16, %zmm3{%k2}
    {evex} vmovdqu8 0(%r8), %zmm25{%k3}
    {evex} vmovdqu8 8128(%r14), %zmm9{%k4}
    {evex} vmovdqu8 2147483647(%r15), %zmm31{%k5}
    {evex} vmovdqu8 0(%r12), %zmm20{%k6}
    {evex} vmovdqu8 -64(%rsp), %zmm12{%k7}
    {evex} vmovdqu8 4660(%r12), %zmm17{%k1}
    {evex} vmovdqu8 0(%r8,%r12,2), %zmm16{%k2}
    {evex} vmovdqu8 128(%rsp,%rax,4), %zmm3{%k3}
    {evex} vmovdqu8 -129(%r13,%r15,8), %zmm25{%k4}
    {evex} vmovdqu8 gnu_fwd(%rip), %zmm9{%k5}
    {evex} vmovdqu8 %zmm31, %zmm20{%k6}{z}
    {evex} vmovdqu8 0(%rdx), %zmm12{%k7}{z}
    {evex} vmovdqu8 -8192(%rcx), %zmm17{%k1}{z}
    {evex} vmovdqu8 1001(%r8), %zmm16{%k2}{z}
    {evex} vmovdqu8 0(%rsp), %zmm3{%k3}{z}
    {evex} vmovdqu8 8128(%r12), %zmm25{%k4}{z}
    {evex} vmovdqu8 -2147483648(%rsp), %zmm9{%k5}{z}
    {evex} vmovdqu8 0(%rcx,%rsi,1), %zmm31{%k6}{z}
    {evex} vmovdqu8 -64(%rbp,%rcx,2), %zmm20{%k7}{z}
    {evex} vmovdqu8 2147483647(%r12,%r9,4), %zmm12{%k1}{z}
    {evex} vmovdqu8 gnu_back(%rip), %zmm17{%k2}{z}
    {evex} {store} vmovdqu8 %xmm16, %xmm3
    {evex} {store} vmovdqu8 %xmm25, %xmm9{%k3}
    {evex} {store} vmovdqu8 %xmm31, %xmm20{%k4}{z}
    {evex} {store} vmovdqu8 %ymm12, %ymm17
    {evex} {store} vmovdqu8 %ymm16, %ymm3{%k5}
    {evex} {store} vmovdqu8 %ymm25, %ymm9{%k6}{z}
    {evex} {store} vmovdqu8 %zmm31, %zmm20
    {evex} {store} vmovdqu8 %zmm12, %zmm17{%k7}
    {evex} {store} vmovdqu8 %zmm16, %zmm3{%k1}{z}
    {evex} vmovdqu8 %xmm25, 0(%r9)
    {evex} vmovdqu8 %xmm9, 32(%rbp)
    {evex} vmovdqu8 %xmm31, 4660(%r13)
    {evex} vmovdqu8 %xmm20, 0(%r12)
    {evex} vmovdqu8 %xmm12, -2048(%rsp)
    {evex} vmovdqu8 %xmm17, -129(%r12)
    {evex} vmovdqu8 %xmm16, 0(%r12,%rbp,8)
    {evex} vmovdqu8 %xmm3, 2032(%rdi,%r12,1)
    {evex} vmovdqu8 %xmm25, 1001(%r15,%rax,2)
g58:
    {evex} vmovdqu8 %xmm9, gnu_fwd(%rip)
    {evex} vmovdqu8 %xmm31, 0(%rbx){%k2}
    {evex} vmovdqu8 %xmm20, -16(%rdx){%k3}
    {evex} vmovdqu8 %xmm12, -2147483648(%r9){%k4}
    {evex} vmovdqu8 %xmm17, 0(%rsp){%k5}
    {evex} vmovdqu8 %xmm16, 32(%r12){%k6}
    {evex} vmovdqu8 %xmm3, 2147483647(%rsp){%k7}
    {evex} vmovdqu8 %xmm25, 0(%rdx,%r15,4){%k1}
    {evex} vmovdqu8 %xmm9, -2048(%rax,%rsi,8){%k2}
    {evex} vmovdqu8 %xmm31, 4660(%r9,%rcx,1){%k3}
    {evex} vmovdqu8 %xmm20, gnu_back(%rip){%k4}
    {evex} vmovdqu8 %ymm12, 0(%r10)
    {evex} vmovdqu8 %ymm17, 64(%rbx)
    {evex} vmovdqu8 %ymm16, -129(%r10)
    {evex} vmovdqu8 %ymm3, 0(%r12)
    {evex} vmovdqu8 %ymm25, -4096(%rsp)
    {evex} vmovdqu8 %ymm9, 1001(%r12)
    {evex} vmovdqu8 %ymm31, 0(%r9,%r9,2)
    {evex} vmovdqu8 %ymm20, 4064(%rsp,%rbp,4)
    {evex} vmovdqu8 %ymm12, -2147483648(%r13,%r12,8)
    {evex} vmovdqu8 %ymm17, gnu_fwd(%rip)
    {evex} vmovdqu8 %ymm16, 0(%rsi){%k5}
    {evex} vmovdqu8 %ymm3, -32(%rsi){%k6}
    {evex} vmovdqu8 %ymm25, 2147483647(%r11){%k7}
    {evex} vmovdqu8 %ymm9, 0(%rsp){%k1}
    {evex} vmovdqu8 %ymm31, 64(%r12){%k2}
    {evex} vmovdqu8 %ymm20, 4660(%rsp){%k3}
    {evex} vmovdqu8 %ymm12, 0(%rsp,%rax,1){%k4}
    {evex} vmovdqu8 %ymm17, -4096(%rbp,%r15,2){%k5}
    {evex} vmovdqu8 %ymm16, -129(%r12,%rsi,4){%k6}
    {evex} vmovdqu8 %ymm3, gnu_back(%rip){%k7}
    {evex} vmovdqu8 %zmm25, 0(%r11)
    {evex} vmovdqu8 %zmm9, 128(%rdi)
    {evex} vmovdqu8 %zmm31, 1001(%r14)
    {evex} vmovdqu8 %zmm20, 0(%r12)
    {evex} vmovdqu8 %zmm12, -8192(%rsp)
    {evex} vmovdqu8 %zmm17, -2147483648(%r12)
    {evex} vmovdqu8 %zmm16, 0(%r14,%rcx,8)
    {evex} vmovdqu8 %zmm3, 8128(%rdi,%r9,1)
    {evex} vmovdqu8 %zmm25, 2147483647(%r15,%rbp,2)
    {evex} vmovdqu8 %zmm9, gnu_fwd(%rip)
    {evex} vmovdqu8 %zmm31, 0(%rdi){%k1}
    {evex} vmovdqu8 %zmm20, -64(%r15){%k2}
    {evex} vmovdqu8 %zmm12, 4660(%rcx){%k3}
    {evex} vmovdqu8 %zmm17, 0(%rsp){%k4}
    {evex} vmovdqu8 %zmm16, 128(%r12){%k5}
    {evex} vmovdqu8 %zmm3, -129(%rsp){%k6}
    {evex} vmovdqu8 %zmm25, 0(%rsi,%r12,4){%k7}
    {evex} vmovdqu8 %zmm9, -8192(%rax,%rax,8){%k1}
    {evex} vmovdqu8 %zmm31, 1001(%r9,%r15,1){%k2}
    {evex} vmovdqu8 %zmm20, gnu_back(%rip){%k3}
    {evex} vmovdqa64 %xmm12, %xmm17
    {evex} vmovdqa64 0(%r14), %xmm16
    {evex} vmovdqa64 2032(%r8), %xmm3
    {evex} vmovdqa64 -2147483648(%rbp), %xmm25
    {evex} vmovdqa64 0(%r12), %xmm9
    {evex} vmovdqa64 -16(%rsp), %xmm31
    {evex} vmovdqa64 2147483647(%r12), %xmm20
    {evex} vmovdqa64 0(%r15,%rsi,2), %xmm12
    {evex} vmovdqa64 32(%rsp,%rcx,4), %xmm17
    {evex} vmovdqa64 4660(%r13,%r9,8), %xmm16
    {evex} vmovdqa64 gnu_fwd(%rip), %xmm3
    {evex} vmovdqa64 %xmm25, %xmm9{%k4}
    {evex} vmovdqa64 0(%r15), %xmm31{%k5}
    {evex} vmovdqa64 -2048(%r13), %xmm20{%k6}
    {evex} vmovdqa64 -129(%rdx), %xmm12{%k7}
    {evex} vmovdqa64 0(%rsp), %xmm17{%k1}
    {evex} vmovdqa64 2032(%r12), %xmm16{%k2}
    {evex} vmovdqa64 1001(%rsp), %xmm3{%k3}
    {evex} vmovdqa64 0(%rax,%rbp,1), %xmm25{%k4}
    {evex} vmovdqa64 -16(%rbp,%r12,2), %xmm9{%k5}
    {evex} vmovdqa64 -2147483648(%r12,%rax,4), %xmm31{%k6}
    {evex} vmovdqa64 gnu_back(%rip), %xmm20{%k7}
    {evex} vmovdqa64 %xmm12, %xmm17{%k1}{z}
    {evex} vmovdqa64 0(%rcx), %xmm16{%k2}{z}
    {evex} vmovdqa64 32(%r9), %xmm3{%k3}{z}
    {evex} vmovdqa64 2147483647(%rbx), %xmm25{%k4}{z}
    {evex} vmovdqa64 0(%r12), %xmm9{%k5}{z}
    {evex} vmovdqa64 -2048(%rsp), %xmm31{%k6}{z}
    {evex} vmovdqa64 4660(%r12), %xmm20{%k7}{z}
    {evex} vmovdqa64 0(%r8,%r15,8), %xmm12{%k1}{z}
    {evex} vmovdqa64 2032(%rdi,%rsi,1), %xmm17{%k2}{z}
    {evex} vmovdqa64 -129(%r15,%rcx,2), %xmm16{%k3}{z}
    {evex} vmovdqa64 gnu_fwd(%rip), %xmm3{%k4}{z}
    {evex} vmovdqa64 %ymm25, %ymm9
    {evex} vmovdqa64 0(%r8), %ymm31
    {evex} vmovdqa64 4064(%r10), %ymm20
    {evex} vmovdqa64 1001(%rsi), %ymm12
    {evex} vmovdqa64 0(%rsp), %ymm17
    {evex} vmovdqa64 -32(%r12), %ymm16
    {evex} vmovdqa64 -2147483648(%rsp), %ymm3
    {evex} vmovdqa64 0(%rcx,%r9,4), %ymm25
    {evex} vmovdqa64 64(%rax,%rbp,8), %ymm9
    {evex} vmovdqa64 2147483647(%r9,%r12,1), %ymm31
    {evex} vmovdqa64 gnu_back(%rip), %ymm20
    {evex} vmovdqa64 %ymm12, %ymm17{%k5}
    {evex} vmovdqa64 0(%rdx), %ymm16{%k6}
    {evex} vmovdqa64 -4096(%r11), %ymm3{%k7}
    {evex} vmovdqa64 4660(%rdi), %ymm25{%k1}
    {evex} vmovdqa64 0(%r12), %ymm9{%k2}
    {evex} vmovdqa64 4064(%rsp), %ymm31{%k3}
    {evex} vmovdqa64 -129(%r12), %ymm20{%k4}
    {evex} vmovdqa64 0(%r12,%rax,2), %ymm12{%k5}
    {evex} vmovdqa64 -32(%rsp,%r15,4), %ymm17{%k6}
    {evex} vmovdqa64 1001(%r13,%rsi,8), %ymm16{%k7}
    {evex} vmovdqa64 gnu_fwd(%rip), %ymm3{%k1}
    {evex} vmovdqa64 %ymm25, %ymm9{%k2}{z}
    {evex} vmovdqa64 0(%r9), %ymm31{%k3}{z}
    {evex} vmovdqa64 64(%r14), %ymm20{%k4}{z}
    {evex} vmovdqa64 -2147483648(%r15), %ymm12{%k5}{z}
    {evex} vmovdqa64 0(%rsp), %ymm17{%k6}{z}
    {evex} vmovdqa64 -4096(%r12), %ymm16{%k7}{z}
    {evex} vmovdqa64 2147483647(%rsp), %ymm3{%k1}{z}
    {evex} vmovdqa64 0(%rdx,%rcx,1), %ymm25{%k2}{z}
    {evex} vmovdqa64 4064(%rbp,%r9,2), %ymm9{%k3}{z}
    {evex} vmovdqa64 4660(%r12,%rbp,4), %ymm31{%k4}{z}
    {evex} vmovdqa64 gnu_back(%rip), %ymm20{%k5}{z}
    {evex} vmovdqa64 %zmm12, %zmm17
    {evex} vmovdqa64 0(%rbx), %zmm16
    {evex} vmovdqa64 8128(%rcx), %zmm3
    {evex} vmovdqa64 -129(%r8), %zmm25
    {evex} vmovdqa64 0(%r12), %zmm9
    {evex} vmovdqa64 -64(%rsp), %zmm31
    {evex} vmovdqa64 1001(%r12), %zmm20
    {evex} vmovdqa64 0(%r9,%r12,8), %zmm12
    {evex} vmovdqa64 128(%rdi,%rax,1), %zmm17
    {evex} vmovdqa64 -2147483648(%r15,%r15,2), %zmm16
    {evex} vmovdqa64 gnu_fwd(%rip), %zmm3
    {evex} vmovdqa64 %zmm25, %zmm9{%k6}
    {evex} vmovdqa64 0(%r10), %zmm31{%k7}
    {evex} vmovdqa64 -8192(%rbp), %zmm20{%k1}
    {evex} vmovdqa64 2147483647(%r13), %zmm12{%k2}
    {evex} vmovdqa64 0(%rsp), %zmm17{%k3}
    {evex} vmovdqa64 8128(%r12), %zmm16{%k4}
    {evex} vmovdqa64 4660(%rsp), %zmm3{%k5}
    {evex} vmovdqa64 0(%rsp,%rsi,4), %zmm25{%k6}
    {evex} vmovdqa64 -64(%rax,%rcx,8), %zmm9{%k7}
    {evex} vmovdqa64 -129(%r9,%r9,1), %zmm31{%k1}
    {evex} vmovdqa64 gnu_back(%rip), %zmm20{%k2}
    {evex} vmovdqa64 %zmm12, %zmm17{%k3}{z}
    {evex} vmovdqa64 0(%rsi), %zmm16{%k4}{z}
    {evex} vmovdqa64 128(%rdx), %zmm3{%k5}{z}
    {evex} vmovdqa64 1001(%r9), %zmm25{%k6}{z}
    {evex} vmovdqa64 0(%r12), %zmm9{%k7}{z}
    {evex} vmovdqa64 -8192(%rsp), %zmm31{%k1}{z}
    {evex} vmovdqa64 -2147483648(%r12), %zmm20{%k2}{z}
    {evex} vmovdqa64 0(%r14,%rbp,2), %zmm12{%k3}{z}
    {evex} vmovdqa64 8128(%rsp,%r12,4), %zmm17{%k4}{z}
    {evex} vmovdqa64 2147483647(%r13,%rax,8), %zmm16{%k5}{z}
    {evex} vmovdqa64 gnu_fwd(%rip), %zmm3{%k6}{z}
    {evex} {store} vmovdqa64 %xmm25, %xmm9
    {evex} {store} vmovdqa64 %xmm31, %xmm20{%k7}
    {evex} {store} vmovdqa64 %xmm12, %xmm17{%k1}{z}
    {evex} {store} vmovdqa64 %ymm16, %ymm3
    {evex} {store} vmovdqa64 %ymm25, %ymm9{%k2}
    {evex} {store} vmovdqa64 %ymm31, %ymm20{%k3}{z}
    {evex} {store} vmovdqa64 %zmm12, %zmm17
    {evex} {store} vmovdqa64 %zmm16, %zmm3{%k4}
    {evex} {store} vmovdqa64 %zmm25, %zmm9{%k5}{z}
    {evex} vmovdqa64 %xmm31, 0(%r11)
    {evex} vmovdqa64 %xmm20, -16(%rbx)
    {evex} vmovdqa64 %xmm12, 4660(%r10)
    {evex} vmovdqa64 %xmm17, 0(%rsp)
    {evex} vmovdqa64 %xmm16, 32(%r12)
    {evex} vmovdqa64 %xmm3, -129(%rsp)
    {evex} vmovdqa64 %xmm25, 0(%rsi,%r15,1)
    {evex} vmovdqa64 %xmm9, -2048(%rbp,%rsi,2)
    {evex} vmovdqa64 %xmm31, 1001(%r12,%rcx,4)
    {evex} vmovdqa64 %xmm20, gnu_back(%rip)
    {evex} vmovdqa64 %xmm12, 0(%rdi){%k6}
    {evex} vmovdqa64 %xmm17, 2032(%rsi){%k7}
    {evex} vmovdqa64 %xmm16, -2147483648(%r11){%k1}
    {evex} vmovdqa64 %xmm3, 0(%r12){%k2}
    {evex} vmovdqa64 %xmm25, -16(%rsp){%k3}
    {evex} vmovdqa64 %xmm9, 2147483647(%r12){%k4}
    {evex} vmovdqa64 %xmm31, 0(%r15,%r9,8){%k5}
    {evex} vmovdqa64 %xmm20, 32(%rdi,%rbp,1){%k6}
    {evex} vmovdqa64 %xmm12, 4660(%r15,%r12,2){%k7}
    {evex} vmovdqa64 %xmm17, gnu_fwd(%rip){%k1}
    {evex} vmovdqa64 %ymm16, 0(%r14)
    {evex} vmovdqa64 %ymm3, -32(%rdi)
    {evex} vmovdqa64 %ymm25, -129(%r14)
    {evex} vmovdqa64 %ymm9, 0(%rsp)
    {evex} vmovdqa64 %ymm31, 64(%r12)
    {evex} vmovdqa64 %ymm20, 1001(%rsp)
    {evex} vmovdqa64 %ymm12, 0(%rax,%rax,4)
    {evex} vmovdqa64 %ymm17, -4096(%rax,%r15,8)
    {evex} vmovdqa64 %ymm16, -2147483648(%r9,%rsi,1)
    {evex} vmovdqa64 %ymm3, gnu_back(%rip)
    {evex} vmovdqa64 %ymm25, 0(%r15){%k2}
    {evex} vmovdqa64 %ymm9, 4064(%r15){%k3}
    {evex} vmovdqa64 %ymm31, 2147483647(%rcx){%k4}
    {evex} vmovdqa64 %ymm20, 0(%r12){%k5}
    {evex} vmovdqa64 %ymm12, -32(%rsp){%k6}
    {evex} vmovdqa64 %ymm17, 4660(%r12){%k7}
    {evex} vmovdqa64 %ymm16, 0(%r8,%rcx,2){%k1}
    {evex} vmovdqa64 %ymm3, 64(%rsp,%r9,4){%k2}
    {evex} vmovdqa64 %ymm25, -129(%r13,%rbp,8){%k3}
    {evex} vmovdqa64 %ymm9, gnu_fwd(%rip){%k4}
    {evex} vmovdqa64 %zmm31, 0(%rcx)
g59:
    {evex} vmovdqa64 %zmm20, -64(%r8)
    {evex} vmovdqa64 %zmm12, 1001(%rbp)
    {evex} vmovdqa64 %zmm17, 0(%rsp)
    {evex} vmovdqa64 %zmm16, 128(%r12)
    {evex} vmovdqa64 %zmm3, -2147483648(%rsp)
    {evex} vmovdqa64 %zmm25, 0(%rcx,%r12,1)
    {evex} vmovdqa64 %zmm9, -8192(%rbp,%rax,2)
    {evex} vmovdqa64 %zmm31, 2147483647(%r12,%r15,4)
    {evex} vmovdqa64 %zmm20, gnu_back(%rip)
    {evex} vmovdqa64 %zmm12, 0(%r8){%k5}
    {evex} vmovdqa64 %zmm17, 8128(%r13){%k6}
    {evex} vmovdqa64 %zmm16, 4660(%rdx){%k7}
    {evex} vmovdqa64 %zmm3, 0(%r12){%k1}
    {evex} vmovdqa64 %zmm25, -64(%rsp){%k2}
    {evex} vmovdqa64 %zmm9, -129(%r12){%k3}
    {evex} vmovdqa64 %zmm31, 0(%r12,%rsi,8){%k4}
    {evex} vmovdqa64 %zmm20, 128(%rdi,%rcx,1){%k5}
    {evex} vmovdqa64 %zmm12, 1001(%r15,%r9,2){%k6}
    {evex} vmovdqa64 %zmm17, gnu_fwd(%rip){%k7}
    {evex} vmovdqa32 %xmm16, %xmm3
    {evex} vmovdqa32 0(%rdx), %xmm25
    {evex} vmovdqa32 -2048(%r9), %xmm9
    {evex} vmovdqa32 -2147483648(%rbx), %xmm31
    {evex} vmovdqa32 0(%rsp), %xmm20
    {evex} vmovdqa32 2032(%r12), %xmm12
    {evex} vmovdqa32 2147483647(%rsp), %xmm17
    {evex} vmovdqa32 0(%rdx,%rbp,4), %xmm16
    {evex} vmovdqa32 -16(%rax,%r12,8), %xmm3
    {evex} vmovdqa32 4660(%r9,%rax,1), %xmm25
    {evex} vmovdqa32 gnu_back(%rip), %xmm9
    {evex} vmovdqa32 %xmm31, %xmm20{%k1}
    {evex} vmovdqa32 0(%r9), %xmm12{%k2}
    {evex} vmovdqa32 32(%r10), %xmm17{%k3}
    {evex} vmovdqa32 -129(%rsi), %xmm16{%k4}
    {evex} vmovdqa32 0(%r12), %xmm3{%k5}
    {evex} vmovdqa32 -2048(%rsp), %xmm25{%k6}
    {evex} vmovdqa32 1001(%r12), %xmm9{%k7}
    {evex} vmovdqa32 0(%r9,%r15,2), %xmm31{%k1}
    {evex} vmovdqa32 2032(%rsp,%rsi,4), %xmm20{%k2}
    {evex} vmovdqa32 -2147483648(%r13,%rcx,8), %xmm12{%k3}
    {evex} vmovdqa32 gnu_fwd(%rip), %xmm17{%k4}
    {evex} vmovdqa32 %xmm16, %xmm3{%k5}{z}
    {evex} vmovdqa32 0(%rbx), %xmm25{%k6}{z}
    {evex} vmovdqa32 -16(%r11), %xmm9{%k7}{z}
    {evex} vmovdqa32 2147483647(%rdi), %xmm31{%k1}{z}
    {evex} vmovdqa32 0(%rsp), %xmm20{%k2}{z}
    {evex} vmovdqa32 32(%r12), %xmm12{%k3}{z}
    {evex} vmovdqa32 4660(%rsp), %xmm17{%k4}{z}
    {evex} vmovdqa32 0(%rsp,%r9,1), %xmm16{%k5}{z}
    {evex} vmovdqa32 -2048(%rbp,%rbp,2), %xmm3{%k6}{z}
    {evex} vmovdqa32 -129(%r12,%r12,4), %xmm25{%k7}{z}
    {evex} vmovdqa32 gnu_back(%rip), %xmm9{%k1}{z}
    {evex} vmovdqa32 %ymm31, %ymm20
    {evex} vmovdqa32 0(%r10), %ymm12
    {evex} vmovdqa32 -4096(%r14), %ymm17
    {evex} vmovdqa32 1001(%r15), %ymm16
    {evex} vmovdqa32 0(%r12), %ymm3
    {evex} vmovdqa32 4064(%rsp), %ymm25
    {evex} vmovdqa32 -2147483648(%r12), %ymm9
    {evex} vmovdqa32 0(%r14,%rax,8), %ymm31
    {evex} vmovdqa32 -32(%rdi,%r15,1), %ymm20
    {evex} vmovdqa32 2147483647(%r15,%rsi,2), %ymm12
    {evex} vmovdqa32 gnu_fwd(%rip), %ymm17
    {evex} vmovdqa32 %ymm16, %ymm3{%k2}
    {evex} vmovdqa32 0(%rsi), %ymm25{%k3}
    {evex} vmovdqa32 64(%rcx), %ymm9{%k4}
    {evex} vmovdqa32 4660(%r8), %ymm31{%k5}
    {evex} vmovdqa32 0(%rsp), %ymm20{%k6}
    {evex} vmovdqa32 -4096(%r12), %ymm12{%k7}
    {evex} vmovdqa32 -129(%rsp), %ymm17{%k1}
    {evex} vmovdqa32 0(%rsi,%rcx,4), %ymm16{%k2}
    {evex} vmovdqa32 4064(%rax,%r9,8), %ymm3{%k3}
    {evex} vmovdqa32 1001(%r9,%rbp,1), %ymm25{%k4}
    {evex} vmovdqa32 gnu_back(%rip), %ymm9{%k5}
    {evex} vmovdqa32 %ymm31, %ymm20{%k6}{z}
    {evex} vmovdqa32 0(%r11), %ymm12{%k7}{z}
    {evex} vmovdqa32 -32(%rbp), %ymm17{%k1}{z}
    {evex} vmovdqa32 -2147483648(%r13), %ymm16{%k2}{z}
    {evex} vmovdqa32 0(%r12), %ymm3{%k3}{z}
    {evex} vmovdqa32 64(%rsp), %ymm25{%k4}{z}
    {evex} vmovdqa32 2147483647(%r12), %ymm9{%k5}{z}
    {evex} vmovdqa32 0(%r15,%r12,2), %ymm31{%k6}{z}
    {evex} vmovdqa32 -4096(%rsp,%rax,4), %ymm20{%k7}{z}
    {evex} vmovdqa32 4660(%r13,%r15,8), %ymm12{%k1}{z}
    {evex} vmovdqa32 gnu_fwd(%rip), %ymm17{%k2}{z}
    {evex} vmovdqa32 %zmm16, %zmm3
    {evex} vmovdqa32 0(%rdi), %zmm25
    {evex} vmovdqa32 -8192(%rdx), %zmm9
    {evex} vmovdqa32 -129(%r9), %zmm31
    {evex} vmovdqa32 0(%rsp), %zmm20
    {evex} vmovdqa32 8128(%r12), %zmm12
    {evex} vmovdqa32 1001(%rsp), %zmm17
    {evex} vmovdqa32 0(%rax,%rsi,1), %zmm16
    {evex} vmovdqa32 -64(%rbp,%rcx,2), %zmm3
    {evex} vmovdqa32 -2147483648(%r12,%r9,4), %zmm25
    {evex} vmovdqa32 gnu_back(%rip), %zmm9
    {evex} vmovdqa32 %zmm31, %zmm20{%k3}
    {evex} vmovdqa32 0(%r14), %zmm12{%k4}
    {evex} vmovdqa32 128(%rbx), %zmm17{%k5}
    {evex} vmovdqa32 2147483647(%r10), %zmm16{%k6}
    {evex} vmovdqa32 0(%r12), %zmm3{%k7}
    {evex} vmovdqa32 -8192(%rsp), %zmm25{%k1}
    {evex} vmovdqa32 4660(%r12), %zmm9{%k2}
    {evex} vmovdqa32 0(%r8,%rbp,8), %zmm31{%k3}
    {evex} vmovdqa32 8128(%rdi,%r12,1), %zmm20{%k4}
    {evex} vmovdqa32 -129(%r15,%rax,2), %zmm12{%k5}
    {evex} vmovdqa32 gnu_fwd(%rip), %zmm17{%k6}
    {evex} vmovdqa32 %zmm16, %zmm3{%k7}{z}
    {evex} vmovdqa32 0(%r15), %zmm25{%k1}{z}
    {evex} vmovdqa32 -64(%rsi), %zmm9{%k2}{z}
    {evex} vmovdqa32 1001(%r11), %zmm31{%k3}{z}
    {evex} vmovdqa32 0(%rsp), %zmm20{%k4}{z}
    {evex} vmovdqa32 128(%r12), %zmm12{%k5}{z}
    {evex} vmovdqa32 -2147483648(%rsp), %zmm17{%k6}{z}
    {evex} vmovdqa32 0(%rcx,%r15,4), %zmm16{%k7}{z}
    {evex} vmovdqa32 -8192(%rax,%rsi,8), %zmm3{%k1}{z}
    {evex} vmovdqa32 2147483647(%r9,%rcx,1), %zmm25{%k2}{z}
    {evex} vmovdqa32 gnu_back(%rip), %zmm9{%k3}{z}
    {evex} {store} vmovdqa32 %xmm31, %xmm20
    {evex} {store} vmovdqa32 %xmm12, %xmm17{%k4}
    {evex} {store} vmovdqa32 %xmm16, %xmm3{%k5}{z}
    {evex} {store} vmovdqa32 %ymm25, %ymm9
    {evex} {store} vmovdqa32 %ymm31, %ymm20{%k6}
    {evex} {store} vmovdqa32 %ymm12, %ymm17{%k7}{z}
    {evex} {store} vmovdqa32 %zmm16, %zmm3
    {evex} {store} vmovdqa32 %zmm25, %zmm9{%k1}
    {evex} {store} vmovdqa32 %zmm31, %zmm20{%k2}{z}
    {evex} vmovdqa32 %xmm12, 0(%rcx)
    {evex} vmovdqa32 %xmm17, 2032(%rdi)
    {evex} vmovdqa32 %xmm16, 4660(%r14)
    {evex} vmovdqa32 %xmm3, 0(%r12)
    {evex} vmovdqa32 %xmm25, -16(%rsp)
    {evex} vmovdqa32 %xmm9, -129(%r12)
    {evex} vmovdqa32 %xmm31, 0(%r12,%r9,2)
    {evex} vmovdqa32 %xmm20, 32(%rsp,%rbp,4)
    {evex} vmovdqa32 %xmm12, 1001(%r13,%r12,8)
    {evex} vmovdqa32 %xmm17, gnu_fwd(%rip)
    {evex} vmovdqa32 %xmm16, 0(%r8){%k3}
    {evex} vmovdqa32 %xmm3, -2048(%r15){%k4}
    {evex} vmovdqa32 %xmm25, -2147483648(%rcx){%k5}
    {evex} vmovdqa32 %xmm9, 0(%rsp){%k6}
    {evex} vmovdqa32 %xmm31, 2032(%r12){%k7}
    {evex} vmovdqa32 %xmm20, 2147483647(%rsp){%k1}
    {evex} vmovdqa32 %xmm12, 0(%rdx,%rax,1){%k2}
    {evex} vmovdqa32 %xmm17, -16(%rbp,%r15,2){%k3}
    {evex} vmovdqa32 %xmm16, 4660(%r12,%rsi,4){%k4}
    {evex} vmovdqa32 %xmm3, gnu_back(%rip){%k5}
    {evex} vmovdqa32 %ymm25, 0(%rdx)
    {evex} vmovdqa32 %ymm9, 4064(%r8)
    {evex} vmovdqa32 %ymm31, -129(%rbp)
    {evex} vmovdqa32 %ymm20, 0(%r12)
    {evex} vmovdqa32 %ymm12, -32(%rsp)
    {evex} vmovdqa32 %ymm17, 1001(%r12)
    {evex} vmovdqa32 %ymm16, 0(%r9,%rcx,8)
    {evex} vmovdqa32 %ymm3, 64(%rdi,%r9,1)
    {evex} vmovdqa32 %ymm25, -2147483648(%r15,%rbp,2)
    {evex} vmovdqa32 %ymm9, gnu_fwd(%rip)
    {evex} vmovdqa32 %ymm31, 0(%r9){%k6}
    {evex} vmovdqa32 %ymm20, -4096(%r13){%k7}
    {evex} vmovdqa32 %ymm12, 2147483647(%rdx){%k1}
    {evex} vmovdqa32 %ymm17, 0(%rsp){%k2}
    {evex} vmovdqa32 %ymm16, 4064(%r12){%k3}
    {evex} vmovdqa32 %ymm3, 4660(%rsp){%k4}
    {evex} vmovdqa32 %ymm25, 0(%rsp,%r12,4){%k5}
    {evex} vmovdqa32 %ymm9, -32(%rax,%rax,8){%k6}
    {evex} vmovdqa32 %ymm31, -129(%r9,%r15,1){%k7}
    {evex} vmovdqa32 %ymm20, gnu_back(%rip){%k1}
    {evex} vmovdqa32 %zmm12, 0(%rbx)
    {evex} vmovdqa32 %zmm17, 8128(%r9)
    {evex} vmovdqa32 %zmm16, 1001(%rbx)
    {evex} vmovdqa32 %zmm3, 0(%r12)
    {evex} vmovdqa32 %zmm25, -64(%rsp)
    {evex} vmovdqa32 %zmm9, -2147483648(%r12)
    {evex} vmovdqa32 %zmm31, 0(%r14,%rsi,2)
    {evex} vmovdqa32 %zmm20, 128(%rsp,%rcx,4)
    {evex} vmovdqa32 %zmm12, 2147483647(%r13,%r9,8)
    {evex} vmovdqa32 %zmm17, gnu_fwd(%rip)
    {evex} vmovdqa32 %zmm16, 0(%r10){%k2}
    {evex} vmovdqa32 %zmm3, -8192(%r10){%k3}
    {evex} vmovdqa32 %zmm25, 4660(%rsi){%k4}
    {evex} vmovdqa32 %zmm9, 0(%rsp){%k5}
    {evex} vmovdqa32 %zmm31, 8128(%r12){%k6}
    {evex} vmovdqa32 %zmm20, -129(%rsp){%k7}
    {evex} vmovdqa32 %zmm12, 0(%rsi,%rbp,1){%k1}
    {evex} vmovdqa32 %zmm17, -64(%rbp,%r12,2){%k2}
    {evex} vmovdqa32 %zmm16, 1001(%r12,%rax,4){%k3}
    {evex} vmovdqa32 %zmm3, gnu_back(%rip){%k4}
    {evex} vmovups %xmm25, %xmm9
    {evex} vmovups 0(%rsi), %xmm31
    {evex} vmovups 32(%r11), %xmm20
    {evex} vmovups -2147483648(%rdi), %xmm12
    {evex} vmovups 0(%r12), %xmm17
    {evex} vmovups -2048(%rsp), %xmm16
    {evex} vmovups 2147483647(%r12), %xmm3
    {evex} vmovups 0(%r15,%r15,8), %xmm25
    {evex} vmovups 2032(%rdi,%rsi,1), %xmm9
    {evex} vmovups 4660(%r15,%rcx,2), %xmm31
    {evex} vmovups gnu_fwd(%rip), %xmm20
    {evex} vmovups %xmm12, %xmm17{%k5}
    {evex} vmovups 0(%r11), %xmm16{%k6}
g60:
    {evex} vmovups -16(%r14), %xmm3{%k7}
    {evex} vmovups -129(%r15), %xmm25{%k1}
    {evex} vmovups 0(%rsp), %xmm9{%k2}
    {evex} vmovups 32(%r12), %xmm31{%k3}
    {evex} vmovups 1001(%rsp), %xmm20{%k4}
    {evex} vmovups 0(%rax,%r9,4), %xmm12{%k5}
    {evex} vmovups -2048(%rax,%rbp,8), %xmm17{%k6}
    {evex} vmovups -2147483648(%r9,%r12,1), %xmm16{%k7}
    {evex} vmovups gnu_back(%rip), %xmm3{%k1}
    {evex} vmovups %xmm25, %xmm9{%k2}{z}
    {evex} vmovups 0(%rdi), %xmm31{%k3}{z}
    {evex} vmovups 2032(%rcx), %xmm20{%k4}{z}
    {evex} vmovups 2147483647(%r8), %xmm12{%k5}{z}
    {evex} vmovups 0(%r12), %xmm17{%k6}{z}
    {evex} vmovups -16(%rsp), %xmm16{%k7}{z}
    {evex} vmovups 4660(%r12), %xmm3{%k1}{z}
    {evex} vmovups 0(%r8,%rax,2), %xmm25{%k2}{z}
    {evex} vmovups 32(%rsp,%r15,4), %xmm9{%k3}{z}
    {evex} vmovups -129(%r13,%rsi,8), %xmm31{%k4}{z}
    {evex} vmovups gnu_fwd(%rip), %xmm20{%k5}{z}
    {evex} vmovups %ymm12, %ymm17
    {evex} vmovups 0(%r14), %ymm16
    {evex} vmovups 64(%rbp), %ymm3
    {evex} vmovups 1001(%r13), %ymm25
    {evex} vmovups 0(%rsp), %ymm9
    {evex} vmovups -4096(%r12), %ymm31
    {evex} vmovups -2147483648(%rsp), %ymm20
    {evex} vmovups 0(%rcx,%rcx,1), %ymm12
    {evex} vmovups 4064(%rbp,%r9,2), %ymm17
    {evex} vmovups 2147483647(%r12,%rbp,4), %ymm16
    {evex} vmovups gnu_back(%rip), %ymm3
    {evex} vmovups %ymm25, %ymm9{%k6}
    {evex} vmovups 0(%r15), %ymm31{%k7}
    {evex} vmovups -32(%rdx), %ymm20{%k1}
    {evex} vmovups 4660(%r9), %ymm12{%k2}
    {evex} vmovups 0(%r12), %ymm17{%k3}
    {evex} vmovups 64(%rsp), %ymm16{%k4}
    {evex} vmovups -129(%r12), %ymm3{%k5}
    {evex} vmovups 0(%r12,%r12,8), %ymm25{%k6}
    {evex} vmovups -4096(%rdi,%rax,1), %ymm9{%k7}
    {evex} vmovups 1001(%r15,%r15,2), %ymm31{%k1}
    {evex} vmovups gnu_fwd(%rip), %ymm20{%k2}
    {evex} vmovups %ymm12, %ymm17{%k3}{z}
    {evex} vmovups 0(%rcx), %ymm16{%k4}{z}
    {evex} vmovups 4064(%rbx), %ymm3{%k5}{z}
    {evex} vmovups -2147483648(%r10), %ymm25{%k6}{z}
    {evex} vmovups 0(%rsp), %ymm9{%k7}{z}
    {evex} vmovups -32(%r12), %ymm31{%k1}{z}
    {evex} vmovups 2147483647(%rsp), %ymm20{%k2}{z}
    {evex} vmovups 0(%rdx,%rsi,4), %ymm12{%k3}{z}
    {evex} vmovups 64(%rax,%rcx,8), %ymm17{%k4}{z}
    {evex} vmovups 4660(%r9,%r9,1), %ymm16{%k5}{z}
    {evex} vmovups gnu_back(%rip), %ymm3{%k6}{z}
    {evex} vmovups %zmm25, %zmm9
    {evex} vmovups 0(%r8), %zmm31
    {evex} vmovups 128(%rsi), %zmm20
    {evex} vmovups -129(%r11), %zmm12
    {evex} vmovups 0(%r12), %zmm17
    {evex} vmovups -8192(%rsp), %zmm16
    {evex} vmovups 1001(%r12), %zmm3
    {evex} vmovups 0(%r9,%rbp,2), %zmm25
    {evex} vmovups 8128(%rsp,%r12,4), %zmm9
    {evex} vmovups -2147483648(%r13,%rax,8), %zmm31
    {evex} vmovups gnu_fwd(%rip), %zmm20
    {evex} vmovups %zmm12, %zmm17{%k7}
    {evex} vmovups 0(%rdx), %zmm16{%k1}
    {evex} vmovups -64(%rdi), %zmm3{%k2}
    {evex} vmovups 2147483647(%r14), %zmm25{%k3}
    {evex} vmovups 0(%rsp), %zmm9{%k4}
    {evex} vmovups 128(%r12), %zmm31{%k5}
    {evex} vmovups 4660(%rsp), %zmm20{%k6}
    {evex} vmovups 0(%rsp,%r15,1), %zmm12{%k7}
    {evex} vmovups -8192(%rbp,%rsi,2), %zmm17{%k1}
    {evex} vmovups -129(%r12,%rcx,4), %zmm16{%k2}
    {evex} vmovups gnu_back(%rip), %zmm3{%k3}
    {evex} vmovups %zmm25, %zmm9{%k4}{z}
    {evex} vmovups 0(%r9), %zmm31{%k5}{z}
    {evex} vmovups 8128(%r15), %zmm20{%k6}{z}
    {evex} vmovups 1001(%rcx), %zmm12{%k7}{z}
    {evex} vmovups 0(%r12), %zmm17{%k1}{z}
    {evex} vmovups -64(%rsp), %zmm16{%k2}{z}
    {evex} vmovups -2147483648(%r12), %zmm3{%k3}{z}
    {evex} vmovups 0(%r14,%r9,8), %zmm25{%k4}{z}
    {evex} vmovups 128(%rdi,%rbp,1), %zmm9{%k5}{z}
    {evex} vmovups 2147483647(%r15,%r12,2), %zmm31{%k6}{z}
    {evex} vmovups gnu_fwd(%rip), %zmm20{%k7}{z}
    {evex} {store} vmovups %xmm12, %xmm17
    {evex} {store} vmovups %xmm16, %xmm3{%k1}
    {evex} {store} vmovups %xmm25, %xmm9{%k2}{z}
    {evex} {store} vmovups %ymm31, %ymm20
    {evex} {store} vmovups %ymm12, %ymm17{%k3}
    {evex} {store} vmovups %ymm16, %ymm3{%k4}{z}
    {evex} {store} vmovups %zmm25, %zmm9
    {evex} {store} vmovups %zmm31, %zmm20{%k5}
    {evex} {store} vmovups %zmm12, %zmm17{%k6}{z}
    {evex} vmovups %xmm16, 0(%rbx)
    {evex} vmovups %xmm3, -2048(%r8)
    {evex} vmovups %xmm25, 4660(%rbp)
    {evex} vmovups %xmm9, 0(%rsp)
    {evex} vmovups %xmm31, 2032(%r12)
    {evex} vmovups %xmm20, -129(%rsp)
    {evex} vmovups %xmm12, 0(%rsi,%rax,4)
    {evex} vmovups %xmm17, -16(%rax,%r15,8)
    {evex} vmovups %xmm16, 1001(%r9,%rsi,1)
    {evex} vmovups %xmm3, gnu_back(%rip)
    {evex} vmovups %xmm25, 0(%r10){%k7}
    {evex} vmovups %xmm9, 32(%r13){%k1}
    {evex} vmovups %xmm31, -2147483648(%rdx){%k2}
    {evex} vmovups %xmm20, 0(%r12){%k3}
    {evex} vmovups %xmm12, -2048(%rsp){%k4}
    {evex} vmovups %xmm17, 2147483647(%r12){%k5}
    {evex} vmovups %xmm16, 0(%r15,%rcx,2){%k6}
    {evex} vmovups %xmm3, 2032(%rsp,%r9,4){%k7}
    {evex} vmovups %xmm25, 4660(%r13,%rbp,8){%k1}
    {evex} vmovups %xmm9, gnu_fwd(%rip){%k2}
    {evex} vmovups %ymm31, 0(%rsi)
    {evex} vmovups %ymm20, -4096(%r9)
    {evex} vmovups %ymm12, -129(%rbx)
    {evex} vmovups %ymm17, 0(%rsp)
    {evex} vmovups %ymm16, 4064(%r12)
    {evex} vmovups %ymm3, 1001(%rsp)
    {evex} vmovups %ymm25, 0(%rax,%r12,1)
    {evex} vmovups %ymm9, -32(%rbp,%rax,2)
    {evex} vmovups %ymm31, -2147483648(%r12,%r15,4)
    {evex} vmovups %ymm20, gnu_back(%rip)
    {evex} vmovups %ymm12, 0(%r11){%k3}
    {evex} vmovups %ymm17, 64(%r10){%k4}
    {evex} vmovups %ymm16, 2147483647(%rsi){%k5}
    {evex} vmovups %ymm3, 0(%r12){%k6}
    {evex} vmovups %ymm25, -4096(%rsp){%k7}
    {evex} vmovups %ymm9, 4660(%r12){%k1}
    {evex} vmovups %ymm31, 0(%r8,%rsi,8){%k2}
    {evex} vmovups %ymm20, 4064(%rdi,%rcx,1){%k3}
    {evex} vmovups %ymm12, -129(%r15,%r9,2){%k4}
    {evex} vmovups %ymm17, gnu_fwd(%rip){%k5}
    {evex} vmovups %zmm16, 0(%rdi)
    {evex} vmovups %zmm3, -8192(%r11)
    {evex} vmovups %zmm25, 1001(%rdi)
    {evex} vmovups %zmm9, 0(%rsp)
    {evex} vmovups %zmm31, 8128(%r12)
    {evex} vmovups %zmm20, -2147483648(%rsp)
    {evex} vmovups %zmm12, 0(%rcx,%rbp,4)
    {evex} vmovups %zmm17, -64(%rax,%r12,8)
    {evex} vmovups %zmm16, 2147483647(%r9,%rax,1)
    {evex} vmovups %zmm3, gnu_back(%rip)
    {evex} vmovups %zmm25, 0(%r14){%k6}
    {evex} vmovups %zmm9, 128(%r14){%k7}
    {evex} vmovups %zmm31, 4660(%r15){%k1}
    {evex} vmovups %zmm20, 0(%r12){%k2}
    {evex} vmovups %zmm12, -8192(%rsp){%k3}
    {evex} vmovups %zmm17, -129(%r12){%k4}
    {evex} vmovups %zmm16, 0(%r12,%r15,2){%k5}
    {evex} vmovups %zmm3, 8128(%rsp,%rsi,4){%k6}
    {evex} vmovups %zmm25, 1001(%r13,%rcx,8){%k7}
    {evex} vmovups %zmm9, gnu_fwd(%rip){%k1}
    {evex} vmovaps %xmm31, %xmm20
    {evex} vmovaps 0(%r15), %xmm12
    {evex} vmovaps -16(%rcx), %xmm17
    {evex} vmovaps -2147483648(%r8), %xmm16
    {evex} vmovaps 0(%rsp), %xmm3
    {evex} vmovaps 32(%r12), %xmm25
    {evex} vmovaps 2147483647(%rsp), %xmm9
    {evex} vmovaps 0(%rdx,%r9,1), %xmm31
    {evex} vmovaps -2048(%rbp,%rbp,2), %xmm20
    {evex} vmovaps 4660(%r12,%r12,4), %xmm12
    {evex} vmovaps gnu_back(%rip), %xmm17
    {evex} vmovaps %xmm16, %xmm3{%k2}
    {evex} vmovaps 0(%rcx), %xmm25{%k3}
    {evex} vmovaps 2032(%rbp), %xmm9{%k4}
    {evex} vmovaps -129(%r13), %xmm31{%k5}
    {evex} vmovaps 0(%r12), %xmm20{%k6}
    {evex} vmovaps -16(%rsp), %xmm12{%k7}
    {evex} vmovaps 1001(%r12), %xmm17{%k1}
    {evex} vmovaps 0(%r9,%rax,8), %xmm16{%k2}
    {evex} vmovaps 32(%rdi,%r15,1), %xmm3{%k3}
    {evex} vmovaps -2147483648(%r15,%rsi,2), %xmm25{%k4}
    {evex} vmovaps gnu_fwd(%rip), %xmm9{%k5}
    {evex} vmovaps %xmm31, %xmm20{%k6}{z}
    {evex} vmovaps 0(%r8), %xmm12{%k7}{z}
    {evex} vmovaps -2048(%rdx), %xmm17{%k1}{z}
    {evex} vmovaps 2147483647(%r9), %xmm16{%k2}{z}
    {evex} vmovaps 0(%rsp), %xmm3{%k3}{z}
    {evex} vmovaps 2032(%r12), %xmm25{%k4}{z}
    {evex} vmovaps 4660(%rsp), %xmm9{%k5}{z}
    {evex} vmovaps 0(%rsp,%rcx,4), %xmm31{%k6}{z}
    {evex} vmovaps -16(%rax,%r9,8), %xmm20{%k7}{z}
    {evex} vmovaps -129(%r9,%rbp,1), %xmm12{%k1}{z}
    {evex} vmovaps gnu_back(%rip), %xmm17{%k2}{z}
    {evex} vmovaps %ymm16, %ymm3
    {evex} vmovaps 0(%rdx), %ymm25
    {evex} vmovaps -32(%rbx), %ymm9
    {evex} vmovaps 1001(%r10), %ymm31
    {evex} vmovaps 0(%r12), %ymm20
    {evex} vmovaps 64(%rsp), %ymm12
    {evex} vmovaps -2147483648(%r12), %ymm17
    {evex} vmovaps 0(%r14,%r12,2), %ymm16
    {evex} vmovaps -4096(%rsp,%rax,4), %ymm3
    {evex} vmovaps 2147483647(%r13,%r15,8), %ymm25
    {evex} vmovaps gnu_fwd(%rip), %ymm9
    {evex} vmovaps %ymm31, %ymm20{%k3}
g61:
    {evex} vmovaps 0(%r9), %ymm12{%k4}
    {evex} vmovaps 4064(%rsi), %ymm17{%k5}
    {evex} vmovaps 4660(%r11), %ymm16{%k6}
    {evex} vmovaps 0(%rsp), %ymm3{%k7}
    {evex} vmovaps -32(%r12), %ymm25{%k1}
    {evex} vmovaps -129(%rsp), %ymm9{%k2}
    {evex} vmovaps 0(%rsi,%rsi,1), %ymm31{%k3}
    {evex} vmovaps 64(%rbp,%rcx,2), %ymm20{%k4}
    {evex} vmovaps 1001(%r12,%r9,4), %ymm12{%k5}
    {evex} vmovaps gnu_back(%rip), %ymm17{%k6}
    {evex} vmovaps %ymm16, %ymm3{%k7}{z}
    {evex} vmovaps 0(%rbx), %ymm25{%k1}{z}
    {evex} vmovaps -4096(%rdi), %ymm9{%k2}{z}
    {evex} vmovaps -2147483648(%r14), %ymm31{%k3}{z}
    {evex} vmovaps 0(%r12), %ymm20{%k4}{z}
    {evex} vmovaps 4064(%rsp), %ymm12{%k5}{z}
    {evex} vmovaps 2147483647(%r12), %ymm17{%k6}{z}
    {evex} vmovaps 0(%r15,%rbp,8), %ymm16{%k7}{z}
    {evex} vmovaps -32(%rdi,%r12,1), %ymm3{%k1}{z}
    {evex} vmovaps 4660(%r15,%rax,2), %ymm25{%k2}{z}
    {evex} vmovaps gnu_fwd(%rip), %ymm9{%k3}{z}
    {evex} vmovaps %zmm31, %zmm20
    {evex} vmovaps 0(%r10), %zmm12
    {evex} vmovaps -64(%r15), %zmm17
    {evex} vmovaps -129(%rcx), %zmm16
    {evex} vmovaps 0(%rsp), %zmm3
    {evex} vmovaps 128(%r12), %zmm25
    {evex} vmovaps 1001(%rsp), %zmm9
    {evex} vmovaps 0(%rax,%r15,4), %zmm31
    {evex} vmovaps -8192(%rax,%rsi,8), %zmm20
    {evex} vmovaps -2147483648(%r9,%rcx,1), %zmm12
    {evex} vmovaps gnu_back(%rip), %zmm17
    {evex} vmovaps %zmm16, %zmm3{%k4}
    {evex} vmovaps 0(%rsi), %zmm25{%k5}
    {evex} vmovaps 8128(%r8), %zmm9{%k6}
    {evex} vmovaps 2147483647(%rbp), %zmm31{%k7}
    {evex} vmovaps 0(%r12), %zmm20{%k1}
    {evex} vmovaps -64(%rsp), %zmm12{%k2}
    {evex} vmovaps 4660(%r12), %zmm17{%k3}
    {evex} vmovaps 0(%r8,%r9,2), %zmm16{%k4}
    {evex} vmovaps 128(%rsp,%rbp,4), %zmm3{%k5}
    {evex} vmovaps -129(%r13,%r12,8), %zmm25{%k6}
    {evex} vmovaps gnu_fwd(%rip), %zmm9{%k7}
    {evex} vmovaps %zmm31, %zmm20{%k1}{z}
    {evex} vmovaps 0(%r11), %zmm12{%k2}{z}
    {evex} vmovaps -8192(%r13), %zmm17{%k3}{z}
    {evex} vmovaps 1001(%rdx), %zmm16{%k4}{z}
    {evex} vmovaps 0(%rsp), %zmm3{%k5}{z}
    {evex} vmovaps 8128(%r12), %zmm25{%k6}{z}
    {evex} vmovaps -2147483648(%rsp), %zmm9{%k7}{z}
    {evex} vmovaps 0(%rcx,%rax,1), %zmm31{%k1}{z}
    {evex} vmovaps -64(%rbp,%r15,2), %zmm20{%k2}{z}
    {evex} vmovaps 2147483647(%r12,%rsi,4), %zmm12{%k3}{z}
    {evex} vmovaps gnu_back(%rip), %zmm17{%k4}{z}
    {evex} {store} vmovaps %xmm16, %xmm3
    {evex} {store} vmovaps %xmm25, %xmm9{%k5}
    {evex} {store} vmovaps %xmm31, %xmm20{%k6}{z}
    {evex} {store} vmovaps %ymm12, %ymm17
    {evex} {store} vmovaps %ymm16, %ymm3{%k7}
    {evex} {store} vmovaps %ymm25, %ymm9{%k1}{z}
    {evex} {store} vmovaps %zmm31, %zmm20
    {evex} {store} vmovaps %zmm12, %zmm17{%k2}
    {evex} {store} vmovaps %zmm16, %zmm3{%k3}{z}
    {evex} vmovaps %xmm25, 0(%rdi)
    {evex} vmovaps %xmm9, 32(%r9)
    {evex} vmovaps %xmm31, 4660(%rbx)
    {evex} vmovaps %xmm20, 0(%r12)
    {evex} vmovaps %xmm12, -2048(%rsp)
    {evex} vmovaps %xmm17, -129(%r12)
    {evex} vmovaps %xmm16, 0(%r12,%rcx,8)
    {evex} vmovaps %xmm3, 2032(%rdi,%r9,1)
    {evex} vmovaps %xmm25, 1001(%r15,%rbp,2)
    {evex} vmovaps %xmm9, gnu_fwd(%rip)
    {evex} vmovaps %xmm31, 0(%r14){%k4}
    {evex} vmovaps %xmm20, -16(%r10){%k5}
    {evex} vmovaps %xmm12, -2147483648(%rsi){%k6}
    {evex} vmovaps %xmm17, 0(%rsp){%k7}
    {evex} vmovaps %xmm16, 32(%r12){%k1}
    {evex} vmovaps %xmm3, 2147483647(%rsp){%k2}
    {evex} vmovaps %xmm25, 0(%rdx,%r12,4){%k3}
    {evex} vmovaps %xmm9, -2048(%rax,%rax,8){%k4}
    {evex} vmovaps %xmm31, 4660(%r9,%r15,1){%k5}
    {evex} vmovaps %xmm20, gnu_back(%rip){%k6}
    {evex} vmovaps %ymm12, 0(%r15)
    {evex} vmovaps %ymm17, 64(%r11)
    {evex} vmovaps %ymm16, -129(%rdi)
    {evex} vmovaps %ymm3, 0(%r12)
    {evex} vmovaps %ymm25, -4096(%rsp)
    {evex} vmovaps %ymm9, 1001(%r12)
    {evex} vmovaps %ymm31, 0(%r9,%rsi,2)
    {evex} vmovaps %ymm20, 4064(%rsp,%rcx,4)
    {evex} vmovaps %ymm12, -2147483648(%r13,%r9,8)
    {evex} vmovaps %ymm17, gnu_fwd(%rip)
    {evex} vmovaps %ymm16, 0(%rcx){%k7}
    {evex} vmovaps %ymm3, -32(%r14){%k1}
    {evex} vmovaps %ymm25, 2147483647(%r15){%k2}
    {evex} vmovaps %ymm9, 0(%rsp){%k3}
    {evex} vmovaps %ymm31, 64(%r12){%k4}
    {evex} vmovaps %ymm20, 4660(%rsp){%k5}
    {evex} vmovaps %ymm12, 0(%rsp,%rbp,1){%k6}
    {evex} vmovaps %ymm17, -4096(%rbp,%r12,2){%k7}
    {evex} vmovaps %ymm16, -129(%r12,%rax,4){%k1}
    {evex} vmovaps %ymm3, gnu_back(%rip){%k2}
    {evex} vmovaps %zmm25, 0(%r8)
    {evex} vmovaps %zmm9, 128(%rcx)
    {evex} vmovaps %zmm31, 1001(%r8)
    {evex} vmovaps %zmm20, 0(%r12)
    {evex} vmovaps %zmm12, -8192(%rsp)
    {evex} vmovaps %zmm17, -2147483648(%r12)
    {evex} vmovaps %zmm16, 0(%r14,%r15,8)
    {evex} vmovaps %zmm3, 8128(%rdi,%rsi,1)
    {evex} vmovaps %zmm25, 2147483647(%r15,%rcx,2)
    {evex} vmovaps %zmm9, gnu_fwd(%rip)
    {evex} vmovaps %zmm31, 0(%rdx){%k3}
    {evex} vmovaps %zmm20, -64(%rbp){%k4}
    {evex} vmovaps %zmm12, 4660(%r13){%k5}
    {evex} vmovaps %zmm17, 0(%rsp){%k6}
    {evex} vmovaps %zmm16, 128(%r12){%k7}
    {evex} vmovaps %zmm3, -129(%rsp){%k1}
    {evex} vmovaps %zmm25, 0(%rsi,%r9,4){%k2}
    {evex} vmovaps %zmm9, -8192(%rax,%rbp,8){%k3}
    {evex} vmovaps %zmm31, 1001(%r9,%r12,1){%k4}
    {evex} vmovaps %zmm20, gnu_back(%rip){%k5}
    {evex} vmovd %ebp, %xmm12
    {evex} vmovd 0(%r9), %xmm17
    {evex} vmovd -512(%rdx), %xmm16
    {evex} vmovd -2147483648(%r9), %xmm3
    {evex} vmovd 0(%r12), %xmm25
    {evex} vmovd 508(%rsp), %xmm9
    {evex} vmovd 2147483647(%r12), %xmm31
    {evex} vmovd 0(%r15,%rax,2), %xmm20
    {evex} vmovd -4(%rsp,%r15,4), %xmm12
    {evex} vmovd 4660(%r13,%rsi,8), %xmm17
    {evex} vmovd gnu_fwd(%rip), %xmm16
    {evex} vmovd %xmm3, %r8d
    {evex} vmovd %xmm25, 0(%rbx)
    {evex} vmovd %xmm9, 8(%rbx)
    {evex} vmovd %xmm31, -129(%r10)
    {evex} vmovd %xmm20, 0(%rsp)
    {evex} vmovd %xmm12, -512(%r12)
    {evex} vmovd %xmm17, 1001(%rsp)
    {evex} vmovd %xmm16, 0(%rax,%rcx,1)
    {evex} vmovd %xmm3, 508(%rbp,%r9,2)
    {evex} vmovd %xmm25, -2147483648(%r12,%rbp,4)
    {evex} vmovd %xmm9, gnu_back(%rip)
    {evex} vmovq %rcx, %xmm31
    {evex} vmovq 0(%r10), %xmm20
    {evex} vmovq -1024(%rsi), %xmm12
    {evex} vmovq 2147483647(%r11), %xmm17
    {evex} vmovq 0(%r12), %xmm16
    {evex} vmovq 1016(%rsp), %xmm3
    {evex} vmovq 4660(%r12), %xmm25
    {evex} vmovq 0(%r8,%r12,8), %xmm9
    {evex} vmovq -8(%rdi,%rax,1), %xmm31
    {evex} vmovq -129(%r15,%r15,2), %xmm20
    {evex} vmovq gnu_fwd(%rip), %xmm12
    {evex} vmovq %xmm17, %r9
    {evex} vmovq %xmm16, 0(%rsi)
    {evex} vmovq %xmm3, 16(%rdi)
    {evex} vmovq %xmm25, 1001(%r14)
    {evex} vmovq %xmm9, 0(%rsp)
    {evex} vmovq %xmm31, -1024(%r12)
    {evex} vmovq %xmm20, -2147483648(%rsp)
    {evex} vmovq %xmm12, 0(%rcx,%rsi,4)
    {evex} vmovq %xmm17, 1016(%rax,%rcx,8)
    {evex} vmovq %xmm16, 2147483647(%r9,%r9,1)
    {evex} vmovq %xmm3, gnu_back(%rip)
    {evex} vmovntdq %xmm25, 0(%r11)
    {evex} vmovntdq %xmm9, 2032(%r15)
    {evex} vmovntdq %xmm31, 4660(%rcx)
    {evex} vmovntdq %xmm20, 0(%r12)
    {evex} vmovntdq %xmm12, -16(%rsp)
    {evex} vmovntdq %xmm17, -129(%r12)
    {evex} vmovntdq %xmm16, 0(%r12,%rbp,2)
    {evex} vmovntdq %xmm3, 32(%rsp,%r12,4)
    {evex} vmovntdq %xmm25, 1001(%r13,%rax,8)
    {evex} vmovntdq %xmm9, gnu_fwd(%rip)
    {evex} vmovntdq %ymm31, 0(%rdi)
    {evex} vmovntdq %ymm20, 4064(%r8)
    {evex} vmovntdq %ymm12, -2147483648(%rbp)
    {evex} vmovntdq %ymm17, 0(%rsp)
    {evex} vmovntdq %ymm16, -32(%r12)
    {evex} vmovntdq %ymm3, 2147483647(%rsp)
    {evex} vmovntdq %ymm25, 0(%rdx,%r15,1)
    {evex} vmovntdq %ymm9, 64(%rbp,%rsi,2)
    {evex} vmovntdq %ymm31, 4660(%r12,%rcx,4)
    {evex} vmovntdq %ymm20, gnu_back(%rip)
    {evex} vmovntdq %zmm12, 0(%r14)
    {evex} vmovntdq %zmm17, 8128(%r13)
    {evex} vmovntdq %zmm16, -129(%rdx)
    {evex} vmovntdq %zmm3, 0(%r12)
    {evex} vmovntdq %zmm25, -64(%rsp)
    {evex} vmovntdq %zmm9, 1001(%r12)
    {evex} vmovntdq %zmm31, 0(%r9,%r9,8)
    {evex} vmovntdq %zmm20, 128(%rdi,%rbp,1)
    {evex} vmovntdq %zmm12, -2147483648(%r15,%r12,2)
    {evex} vmovntdq %zmm17, gnu_fwd(%rip)
    {evex} vpcmpeqb %xmm16, %xmm3, %k6
    {evex} vpcmpeqb 0(%r15), %xmm25, %k7
    {evex} vpcmpeqb -2048(%r9), %xmm9, %k1
g62:
    {evex} vpcmpeqb 2147483647(%rbx), %xmm31, %k2
    {evex} vpcmpeqb 0(%rsp), %xmm20, %k3
    {evex} vpcmpeqb 2032(%r12), %xmm12, %k4
    {evex} vpcmpeqb 4660(%rsp), %xmm17, %k5
    {evex} vpcmpeqb 0(%rsp,%rax,4), %xmm16, %k6
    {evex} vpcmpeqb -16(%rax,%r15,8), %xmm3, %k7
    {evex} vpcmpeqb -129(%r9,%rsi,1), %xmm25, %k1
    {evex} vpcmpeqb gnu_back(%rip), %xmm9, %k2
    {evex} vpcmpeqb %xmm31, %xmm20, %k3{%k4}
    {evex} vpcmpeqb 0(%rcx), %xmm12, %k5{%k6}
    {evex} vpcmpeqb 32(%r10), %xmm17, %k7{%k1}
    {evex} vpcmpeqb 1001(%rsi), %xmm16, %k2{%k3}
    {evex} vpcmpeqb 0(%r12), %xmm3, %k4{%k5}
    {evex} vpcmpeqb -2048(%rsp), %xmm25, %k6{%k7}
    {evex} vpcmpeqb -2147483648(%r12), %xmm9, %k1{%k2}
    {evex} vpcmpeqb 0(%r14,%rcx,2), %xmm31, %k3{%k4}
    {evex} vpcmpeqb 2032(%rsp,%r9,4), %xmm20, %k5{%k6}
    {evex} vpcmpeqb 2147483647(%r13,%rbp,8), %xmm12, %k7{%k1}
    {evex} vpcmpeqb gnu_fwd(%rip), %xmm17, %k2{%k3}
    {evex} vpcmpeqb %ymm16, %ymm3, %k4
    {evex} vpcmpeqb 0(%r8), %ymm25, %k5
    {evex} vpcmpeqb -4096(%r11), %ymm9, %k6
    {evex} vpcmpeqb 4660(%rdi), %ymm31, %k7
    {evex} vpcmpeqb 0(%rsp), %ymm20, %k1
    {evex} vpcmpeqb 4064(%r12), %ymm12, %k2
    {evex} vpcmpeqb -129(%rsp), %ymm17, %k3
    {evex} vpcmpeqb 0(%rsi,%r12,1), %ymm16, %k4
    {evex} vpcmpeqb -32(%rbp,%rax,2), %ymm3, %k5
    {evex} vpcmpeqb 1001(%r12,%r15,4), %ymm25, %k6
    {evex} vpcmpeqb gnu_back(%rip), %ymm9, %k7
    {evex} vpcmpeqb %ymm31, %ymm20, %k1{%k2}
    {evex} vpcmpeqb 0(%rdx), %ymm12, %k3{%k4}
    {evex} vpcmpeqb 64(%r14), %ymm17, %k5{%k6}
    {evex} vpcmpeqb -2147483648(%r15), %ymm16, %k7{%k1}
    {evex} vpcmpeqb 0(%r12), %ymm3, %k2{%k3}
    {evex} vpcmpeqb -4096(%rsp), %ymm25, %k4{%k5}
    {evex} vpcmpeqb 2147483647(%r12), %ymm9, %k6{%k7}
    {evex} vpcmpeqb 0(%r15,%rsi,8), %ymm31, %k1{%k2}
    {evex} vpcmpeqb 4064(%rdi,%rcx,1), %ymm20, %k3{%k4}
    {evex} vpcmpeqb 4660(%r15,%r9,2), %ymm12, %k5{%k6}
    {evex} vpcmpeqb gnu_fwd(%rip), %ymm17, %k7{%k1}
    {evex} vpcmpeqb %zmm16, %zmm3, %k2
    {evex} vpcmpeqb 0(%r9), %zmm25, %k3
    {evex} vpcmpeqb -8192(%rcx), %zmm9, %k4
    {evex} vpcmpeqb -129(%r8), %zmm31, %k5
    {evex} vpcmpeqb 0(%rsp), %zmm20, %k6
    {evex} vpcmpeqb 8128(%r12), %zmm12, %k7
    {evex} vpcmpeqb 1001(%rsp), %zmm17, %k1
    {evex} vpcmpeqb 0(%rax,%rbp,4), %zmm16, %k2
    {evex} vpcmpeqb -64(%rax,%r12,8), %zmm3, %k3
    {evex} vpcmpeqb -2147483648(%r9,%rax,1), %zmm25, %k4
    {evex} vpcmpeqb gnu_back(%rip), %zmm9, %k5
    {evex} vpcmpeqb %zmm31, %zmm20, %k6{%k7}
    {evex} vpcmpeqb 0(%rbx), %zmm12, %k1{%k2}
    {evex} vpcmpeqb 128(%rbp), %zmm17, %k3{%k4}
    {evex} vpcmpeqb 2147483647(%r13), %zmm16, %k5{%k6}
    {evex} vpcmpeqb 0(%r12), %zmm3, %k7{%k1}
    {evex} vpcmpeqb -8192(%rsp), %zmm25, %k2{%k3}
    {evex} vpcmpeqb 4660(%r12), %zmm9, %k4{%k5}
    {evex} vpcmpeqb 0(%r8,%r15,2), %zmm31, %k6{%k7}
    {evex} vpcmpeqb 8128(%rsp,%rsi,4), %zmm20, %k1{%k2}
    {evex} vpcmpeqb -129(%r13,%rcx,8), %zmm12, %k3{%k4}
    {evex} vpcmpeqb gnu_fwd(%rip), %zmm17, %k5{%k6}
    {evex} vpcmpeqd %xmm16, %xmm3, %k7
    {evex} vpcmpeqd 0(%r10), %xmm25, %k1
    {evex} vpcmpeqd -16(%rdx), %xmm9, %k2
    {evex} vpcmpeqd 1001(%r9), %xmm31, %k3
    {evex} vpcmpeqd 0(%rsp), %xmm20, %k4
    {evex} vpcmpeqd 32(%r12), %xmm12, %k5
    {evex} vpcmpeqd -2147483648(%rsp), %xmm17, %k6
    {evex} vpcmpeqd 0(%rcx,%r9,1), %xmm16, %k7
    {evex} vpcmpeqd -2048(%rbp,%rbp,2), %xmm3, %k1
    {evex} vpcmpeqd 2147483647(%r12,%r12,4), %xmm25, %k2
    {evex} vpcmpeqd gnu_back(%rip), %xmm9, %k3
    {evex} vpcmpeqd %xmm31, %xmm20, %k4{%k5}
    {evex} vpcmpeqd 0(%rsi), %xmm12, %k6{%k7}
    {evex} vpcmpeqd 2032(%rbx), %xmm17, %k1{%k2}
    {evex} vpcmpeqd 4660(%r10), %xmm16, %k3{%k4}
    {evex} vpcmpeqd 0(%r12), %xmm3, %k5{%k6}
    {evex} vpcmpeqd -16(%rsp), %xmm25, %k7{%k1}
    {evex} vpcmpeqd -129(%r12), %xmm9, %k2{%k3}
    {evex} vpcmpeqd 0(%r12,%rax,8), %xmm31, %k4{%k5}
    {evex} vpcmpeqd 32(%rdi,%r15,1), %xmm20, %k6{%k7}
    {evex} vpcmpeqd 1001(%r15,%rsi,2), %xmm12, %k1{%k2}
    {evex} vpcmpeqd gnu_fwd(%rip), %xmm17, %k3{%k4}
    {evex} vpcmpeqd %ymm16, %ymm3, %k5
    {evex} vpcmpeqd 0(%r11), %ymm25, %k6
    {evex} vpcmpeqd -32(%rsi), %ymm9, %k7
    {evex} vpcmpeqd -2147483648(%r11), %ymm31, %k1
    {evex} vpcmpeqd 0(%rsp), %ymm20, %k2
    {evex} vpcmpeqd 64(%r12), %ymm12, %k3
    {evex} vpcmpeqd 2147483647(%rsp), %ymm17, %k4
    {evex} vpcmpeqd 0(%rdx,%rcx,4), %ymm16, %k5
    {evex} vpcmpeqd -4096(%rax,%r9,8), %ymm3, %k6
    {evex} vpcmpeqd 4660(%r9,%rbp,1), %ymm25, %k7
    {evex} vpcmpeqd gnu_back(%rip), %ymm9, %k1
    {evex} vpcmpeqd %ymm31, %ymm20, %k2{%k3}
    {evex} vpcmpeqd 0(%rdi), %ymm12, %k4{%k5}
    {evex} vpcmpeqd 4064(%rdi), %ymm17, %k6{%k7}
    {evex} vpcmpeqd -129(%r14), %ymm16, %k1{%k2}
    {evex} vpcmpeqd 0(%r12), %ymm3, %k3{%k4}
    {evex} vpcmpeqd -32(%rsp), %ymm25, %k5{%k6}
    {evex} vpcmpeqd 1001(%r12), %ymm9, %k7{%k1}
    {evex} vpcmpeqd 0(%r9,%r12,2), %ymm31, %k2{%k3}
    {evex} vpcmpeqd 64(%rsp,%rax,4), %ymm20, %k4{%k5}
    {evex} vpcmpeqd -2147483648(%r13,%r15,8), %ymm12, %k6{%k7}
    {evex} vpcmpeqd gnu_fwd(%rip), %ymm17, %k1{%k2}
    {evex} vpcmpeqd %zmm16, %zmm3, %k3
    {evex} vpcmpeqd 0(%r14), %zmm25, %k4
    {evex} vpcmpeqd -64(%r15), %zmm9, %k5
    {evex} vpcmpeqd 2147483647(%rcx), %zmm31, %k6
    {evex} vpcmpeqd 0(%rsp), %zmm20, %k7
    {evex} vpcmpeqd 128(%r12), %zmm12, %k1
    {evex} vpcmpeqd 4660(%rsp), %zmm17, %k2
    {evex} vpcmpeqd 0(%rsp,%rsi,1), %zmm16, %k3
    {evex} vpcmpeqd -8192(%rbp,%rcx,2), %zmm3, %k4
    {evex} vpcmpeqd -129(%r12,%r9,4), %zmm25, %k5
    {evex} vpcmpeqd gnu_back(%rip), %zmm9, %k6
    {evex} vpcmpeqd %zmm31, %zmm20, %k7{%k1}
    {evex} vpcmpeqd 0(%r15), %zmm12, %k2{%k3}
    {evex} vpcmpeqd 8128(%r8), %zmm17, %k4{%k5}
    {evex} vpcmpeqd 1001(%rbp), %zmm16, %k6{%k7}
    {evex} vpcmpeqd 0(%r12), %zmm3, %k1{%k2}
    {evex} vpcmpeqd -64(%rsp), %zmm25, %k3{%k4}
    {evex} vpcmpeqd -2147483648(%r12), %zmm9, %k5{%k6}
    {evex} vpcmpeqd 0(%r14,%rbp,8), %zmm31, %k7{%k1}
    {evex} vpcmpeqd 128(%rdi,%r12,1), %zmm20, %k2{%k3}
    {evex} vpcmpeqd 2147483647(%r15,%rax,2), %zmm12, %k4{%k5}
    {evex} vpcmpeqd gnu_fwd(%rip), %zmm17, %k6{%k7}
    {evex} vptestmb %xmm16, %xmm3, %k1
    {evex} vptestmb 0(%rcx), %xmm25, %k2
    {evex} vptestmb -2048(%r13), %xmm9, %k3
    {evex} vptestmb 4660(%rdx), %xmm31, %k4
    {evex} vptestmb 0(%rsp), %xmm20, %k5
    {evex} vptestmb 2032(%r12), %xmm12, %k6
    {evex} vptestmb -129(%rsp), %xmm17, %k7
    {evex} vptestmb 0(%rsi,%r15,4), %xmm16, %k1
    {evex} vptestmb -16(%rax,%rsi,8), %xmm3, %k2
    {evex} vptestmb 1001(%r9,%rcx,1), %xmm25, %k3
    {evex} vptestmb gnu_back(%rip), %xmm9, %k4
    {evex} vptestmb %xmm31, %xmm20, %k5{%k6}
    {evex} vptestmb 0(%r8), %xmm12, %k7{%k1}
    {evex} vptestmb 32(%r9), %xmm17, %k2{%k3}
    {evex} vptestmb -2147483648(%rbx), %xmm16, %k4{%k5}
    {evex} vptestmb 0(%r12), %xmm3, %k6{%k7}
    {evex} vptestmb -2048(%rsp), %xmm25, %k1{%k2}
    {evex} vptestmb 2147483647(%r12), %xmm9, %k3{%k4}
    {evex} vptestmb 0(%r15,%r9,2), %xmm31, %k5{%k6}
    {evex} vptestmb 2032(%rsp,%rbp,4), %xmm20, %k7{%k1}
    {evex} vptestmb 4660(%r13,%r12,8), %xmm12, %k2{%k3}
    {evex} vptestmb gnu_fwd(%rip), %xmm17, %k4{%k5}
    {evex} vptestmb %ymm16, %ymm3, %k6
    {evex} vptestmb 0(%rdx), %ymm25, %k7
    {evex} vptestmb -4096(%r10), %ymm9, %k1
    {evex} vptestmb -129(%rsi), %ymm31, %k2
    {evex} vptestmb 0(%rsp), %ymm20, %k3
    {evex} vptestmb 4064(%r12), %ymm12, %k4
    {evex} vptestmb 1001(%rsp), %ymm17, %k5
    {evex} vptestmb 0(%rax,%rax,1), %ymm16, %k6
    {evex} vptestmb -32(%rbp,%r15,2), %ymm3, %k7
    {evex} vptestmb -2147483648(%r12,%rsi,4), %ymm25, %k1
    {evex} vptestmb gnu_back(%rip), %ymm9, %k2
    {evex} vptestmb %ymm31, %ymm20, %k3{%k4}
    {evex} vptestmb 0(%r9), %ymm12, %k5{%k6}
    {evex} vptestmb 64(%r11), %ymm17, %k7{%k1}
    {evex} vptestmb 2147483647(%rdi), %ymm16, %k2{%k3}
    {evex} vptestmb 0(%r12), %ymm3, %k4{%k5}
    {evex} vptestmb -4096(%rsp), %ymm25, %k6{%k7}
    {evex} vptestmb 4660(%r12), %ymm9, %k1{%k2}
    {evex} vptestmb 0(%r8,%rcx,8), %ymm31, %k3{%k4}
    {evex} vptestmb 4064(%rdi,%r9,1), %ymm20, %k5{%k6}
    {evex} vptestmb -129(%r15,%rbp,2), %ymm12, %k7{%k1}
    {evex} vptestmb gnu_fwd(%rip), %ymm17, %k2{%k3}
    {evex} vptestmb %zmm16, %zmm3, %k4
    {evex} vptestmb 0(%rbx), %zmm25, %k5
    {evex} vptestmb -8192(%r14), %zmm9, %k6
    {evex} vptestmb 1001(%r15), %zmm31, %k7
    {evex} vptestmb 0(%rsp), %zmm20, %k1
    {evex} vptestmb 8128(%r12), %zmm12, %k2
    {evex} vptestmb -2147483648(%rsp), %zmm17, %k3
    {evex} vptestmb 0(%rcx,%r12,4), %zmm16, %k4
    {evex} vptestmb -64(%rax,%rax,8), %zmm3, %k5
    {evex} vptestmb 2147483647(%r9,%r15,1), %zmm25, %k6
    {evex} vptestmb gnu_back(%rip), %zmm9, %k7
    {evex} vptestmb %zmm31, %zmm20, %k1{%k2}
    {evex} vptestmb 0(%r10), %zmm12, %k3{%k4}
    {evex} vptestmb 128(%rcx), %zmm17, %k5{%k6}
    {evex} vptestmb 4660(%r8), %zmm16, %k7{%k1}
    {evex} vptestmb 0(%r12), %zmm3, %k2{%k3}
    {evex} vptestmb -8192(%rsp), %zmm25, %k4{%k5}
    {evex} vptestmb -129(%r12), %zmm9, %k6{%k7}
    {evex} vptestmb 0(%r12,%rsi,2), %zmm31, %k1{%k2}
    {evex} vptestmb 8128(%rsp,%rcx,4), %zmm20, %k3{%k4}
    {evex} vptestmb 1001(%r13,%r9,8), %zmm12, %k5{%k6}
    {evex} vptestmb gnu_fwd(%rip), %zmm17, %k7{%k1}
    {evex} vptestmd %xmm16, %xmm3, %k2
    {evex} vptestmd 0(%rsi), %xmm25, %k3
    {evex} vptestmd -16(%rbp), %xmm9, %k4
    {evex} vptestmd -2147483648(%r13), %xmm31, %k5
    {evex} vptestmd 0(%rsp), %xmm20, %k6
g63:
    {evex} vptestmd 32(%r12), %xmm12, %k7
    {evex} vptestmd 2147483647(%rsp), %xmm17, %k1
    {evex} vptestmd 0(%rdx,%rbp,1), %xmm16, %k2
    {evex} vptestmd -2048(%rbp,%r12,2), %xmm3, %k3
    {evex} vptestmd 4660(%r12,%rax,4), %xmm25, %k4
    {evex} vptestmd gnu_back(%rip), %xmm9, %k5
    {evex} vptestmd %xmm31, %xmm20, %k6{%k7}
    {evex} vptestmd 0(%r11), %xmm12, %k1{%k2}
    {evex} vptestmd 2032(%rdx), %xmm17, %k3{%k4}
    {evex} vptestmd -129(%r9), %xmm16, %k5{%k6}
    {evex} vptestmd 0(%r12), %xmm3, %k7{%k1}
    {evex} vptestmd -16(%rsp), %xmm25, %k2{%k3}
    {evex} vptestmd 1001(%r12), %xmm9, %k4{%k5}
    {evex} vptestmd 0(%r9,%r15,8), %xmm31, %k6{%k7}
    {evex} vptestmd 32(%rdi,%rsi,1), %xmm20, %k1{%k2}
    {evex} vptestmd -2147483648(%r15,%rcx,2), %xmm12, %k3{%k4}
    {evex} vptestmd gnu_fwd(%rip), %xmm17, %k5{%k6}
    {evex} vptestmd %ymm16, %ymm3, %k7
    {evex} vptestmd 0(%rdi), %ymm25, %k1
    {evex} vptestmd -32(%rbx), %ymm9, %k2
    {evex} vptestmd 2147483647(%r10), %ymm31, %k3
    {evex} vptestmd 0(%rsp), %ymm20, %k4
    {evex} vptestmd 64(%r12), %ymm12, %k5
    {evex} vptestmd 4660(%rsp), %ymm17, %k6
    {evex} vptestmd 0(%rsp,%r9,4), %ymm16, %k7
    {evex} vptestmd -4096(%rax,%rbp,8), %ymm3, %k1
    {evex} vptestmd -129(%r9,%r12,1), %ymm25, %k2
    {evex} vptestmd gnu_back(%rip), %ymm9, %k3
    {evex} vptestmd %ymm31, %ymm20, %k4{%k5}
    {evex} vptestmd 0(%r14), %ymm12, %k6{%k7}
    {evex} vptestmd 4064(%rsi), %ymm17, %k1{%k2}
    {evex} vptestmd 1001(%r11), %ymm16, %k3{%k4}
    {evex} vptestmd 0(%r12), %ymm3, %k5{%k6}
    {evex} vptestmd -32(%rsp), %ymm25, %k7{%k1}
    {evex} vptestmd -2147483648(%r12), %ymm9, %k2{%k3}
    {evex} vptestmd 0(%r14,%rax,2), %ymm31, %k4{%k5}
    {evex} vptestmd 64(%rsp,%r15,4), %ymm20, %k6{%k7}
    {evex} vptestmd 2147483647(%r13,%rsi,8), %ymm12, %k1{%k2}
    {evex} vptestmd gnu_fwd(%rip), %ymm17, %k3{%k4}
    {evex} vptestmd %zmm16, %zmm3, %k5
    {evex} vptestmd 0(%r15), %zmm25, %k6
    {evex} vptestmd -64(%rdi), %zmm9, %k7
    {evex} vptestmd 4660(%r14), %zmm31, %k1
    {evex} vptestmd 0(%rsp), %zmm20, %k2
    {evex} vptestmd 128(%r12), %zmm12, %k3
    {evex} vptestmd -129(%rsp), %zmm17, %k4
    {evex} vptestmd 0(%rsi,%rcx,1), %zmm16, %k5
    {evex} vptestmd -8192(%rbp,%r9,2), %zmm3, %k6
    {evex} vptestmd 1001(%r12,%rbp,4), %zmm25, %k7
    {evex} vptestmd gnu_back(%rip), %zmm9, %k1
    {evex} vptestmd %zmm31, %zmm20, %k2{%k3}
    {evex} vptestmd 0(%rcx), %zmm12, %k4{%k5}
    {evex} vptestmd 8128(%r15), %zmm17, %k6{%k7}
    {evex} vptestmd -2147483648(%rcx), %zmm16, %k1{%k2}
    {evex} vptestmd 0(%r12), %zmm3, %k3{%k4}
    {evex} vptestmd -64(%rsp), %zmm25, %k5{%k6}
    {evex} vptestmd 2147483647(%r12), %zmm9, %k7{%k1}
    {evex} vptestmd 0(%r15,%r12,8), %zmm31, %k2{%k3}
    {evex} vptestmd 128(%rdi,%rax,1), %zmm20, %k4{%k5}
    {evex} vptestmd 4660(%r15,%r15,2), %zmm12, %k6{%k7}
    {evex} vptestmd gnu_fwd(%rip), %zmm17, %k1{%k2}
    {evex} vptestnmb %xmm16, %xmm3, %k3
    {evex} vptestnmb 0(%r8), %xmm25, %k4
    {evex} vptestnmb -2048(%r8), %xmm9, %k5
    {evex} vptestnmb -129(%rbp), %xmm31, %k6
    {evex} vptestnmb 0(%rsp), %xmm20, %k7
    {evex} vptestnmb 2032(%r12), %xmm12, %k1
    {evex} vptestnmb 1001(%rsp), %xmm17, %k2
    {evex} vptestnmb 0(%rax,%rsi,4), %xmm16, %k3
    {evex} vptestnmb -16(%rax,%rcx,8), %xmm3, %k4
    {evex} vptestnmb -2147483648(%r9,%r9,1), %xmm25, %k5
    {evex} vptestnmb gnu_back(%rip), %xmm9, %k6
    {evex} vptestnmb %xmm31, %xmm20, %k7{%k1}
    {evex} vptestnmb 0(%rdx), %xmm12, %k2{%k3}
    {evex} vptestnmb 32(%r13), %xmm17, %k4{%k5}
    {evex} vptestnmb 2147483647(%rdx), %xmm16, %k6{%k7}
    {evex} vptestnmb 0(%r12), %xmm3, %k1{%k2}
    {evex} vptestnmb -2048(%rsp), %xmm25, %k3{%k4}
    {evex} vptestnmb 4660(%r12), %xmm9, %k5{%k6}
    {evex} vptestnmb 0(%r8,%rbp,2), %xmm31, %k7{%k1}
    {evex} vptestnmb 2032(%rsp,%r12,4), %xmm20, %k2{%k3}
    {evex} vptestnmb -129(%r13,%rax,8), %xmm12, %k4{%k5}
    {evex} vptestnmb gnu_fwd(%rip), %xmm17, %k6{%k7}
    {evex} vptestnmb %ymm16, %ymm3, %k1
    {evex} vptestnmb 0(%r9), %ymm25, %k2
    {evex} vptestnmb -4096(%r9), %ymm9, %k3
    {evex} vptestnmb 1001(%rbx), %ymm31, %k4
    {evex} vptestnmb 0(%rsp), %ymm20, %k5
    {evex} vptestnmb 4064(%r12), %ymm12, %k6
    {evex} vptestnmb -2147483648(%rsp), %ymm17, %k7
    {evex} vptestnmb 0(%rcx,%r15,1), %ymm16, %k1
    {evex} vptestnmb -32(%rbp,%rsi,2), %ymm3, %k2
    {evex} vptestnmb 2147483647(%r12,%rcx,4), %ymm25, %k3
    {evex} vptestnmb gnu_back(%rip), %ymm9, %k4
    {evex} vptestnmb %ymm31, %ymm20, %k5{%k6}
    {evex} vptestnmb 0(%rbx), %ymm12, %k7{%k1}
    {evex} vptestnmb 64(%r10), %ymm17, %k2{%k3}
    {evex} vptestnmb 4660(%rsi), %ymm16, %k4{%k5}
    {evex} vptestnmb 0(%r12), %ymm3, %k6{%k7}
    {evex} vptestnmb -4096(%rsp), %ymm25, %k1{%k2}
    {evex} vptestnmb -129(%r12), %ymm9, %k3{%k4}
    {evex} vptestnmb 0(%r12,%r9,8), %ymm31, %k5{%k6}
    {evex} vptestnmb 4064(%rdi,%rbp,1), %ymm20, %k7{%k1}
    {evex} vptestnmb 1001(%r15,%r12,2), %ymm12, %k2{%k3}
    {evex} vptestnmb gnu_fwd(%rip), %ymm17, %k4{%k5}
    {evex} vptestnmb %zmm16, %zmm3, %k6
    {evex} vptestnmb 0(%r10), %zmm25, %k7
    {evex} vptestnmb -8192(%r11), %zmm9, %k1
    {evex} vptestnmb -2147483648(%rdi), %zmm31, %k2
    {evex} vptestnmb 0(%rsp), %zmm20, %k3
    {evex} vptestnmb 8128(%r12), %zmm12, %k4
    {evex} vptestnmb 2147483647(%rsp), %zmm17, %k5
    {evex} vptestnmb 0(%rdx,%rax,4), %zmm16, %k6
    {evex} vptestnmb -64(%rax,%r15,8), %zmm3, %k7
    {evex} vptestnmb 4660(%r9,%rsi,1), %zmm25, %k1
    {evex} vptestnmb gnu_back(%rip), %zmm9, %k2
    {evex} vptestnmb %zmm31, %zmm20, %k3{%k4}
    {evex} vptestnmb 0(%rsi), %zmm12, %k5{%k6}
    {evex} vptestnmb 128(%r14), %zmm17, %k7{%k1}
    {evex} vptestnmb -129(%r15), %zmm16, %k2{%k3}
    {evex} vptestnmb 0(%r12), %zmm3, %k4{%k5}
    {evex} vptestnmb -8192(%rsp), %zmm25, %k6{%k7}
    {evex} vptestnmb 1001(%r12), %zmm9, %k1{%k2}
    {evex} vptestnmb 0(%r9,%rcx,2), %zmm31, %k3{%k4}
    {evex} vptestnmb 8128(%rsp,%r9,4), %zmm20, %k5{%k6}
    {evex} vptestnmb -2147483648(%r13,%rbp,8), %zmm12, %k7{%k1}
    {evex} vptestnmb gnu_fwd(%rip), %zmm17, %k2{%k3}
    {evex} vptestnmd %xmm16, %xmm3, %k4
    {evex} vptestnmd 0(%r11), %xmm25, %k5
    {evex} vptestnmd -16(%rcx), %xmm9, %k6
    {evex} vptestnmd 2147483647(%r8), %xmm31, %k7
    {evex} vptestnmd 0(%rsp), %xmm20, %k1
    {evex} vptestnmd 32(%r12), %xmm12, %k2
    {evex} vptestnmd 4660(%rsp), %xmm17, %k3
    {evex} vptestnmd 0(%rsp,%r12,1), %xmm16, %k4
    {evex} vptestnmd -2048(%rbp,%rax,2), %xmm3, %k5
    {evex} vptestnmd -129(%r12,%r15,4), %xmm25, %k6
    {evex} vptestnmd gnu_back(%rip), %xmm9, %k7
    {evex} vptestnmd %xmm31, %xmm20, %k1{%k2}
    {evex} vptestnmd 0(%rdi), %xmm12, %k3{%k4}
    {evex} vptestnmd 2032(%rbp), %xmm17, %k5{%k6}
    {evex} vptestnmd 1001(%r13), %xmm16, %k7{%k1}
    {evex} vptestnmd 0(%r12), %xmm3, %k2{%k3}
    {evex} vptestnmd -16(%rsp), %xmm25, %k4{%k5}
    {evex} vptestnmd -2147483648(%r12), %xmm9, %k6{%k7}
    {evex} vptestnmd 0(%r14,%rsi,8), %xmm31, %k1{%k2}
    {evex} vptestnmd 32(%rdi,%rcx,1), %xmm20, %k3{%k4}
    {evex} vptestnmd 2147483647(%r15,%r9,2), %xmm12, %k5{%k6}
    {evex} vptestnmd gnu_fwd(%rip), %xmm17, %k7{%k1}
    {evex} vptestnmd %ymm16, %ymm3, %k2
    {evex} vptestnmd 0(%r14), %ymm25, %k3
    {evex} vptestnmd -32(%rdx), %ymm9, %k4
    {evex} vptestnmd 4660(%r9), %ymm31, %k5
    {evex} vptestnmd 0(%rsp), %ymm20, %k6
    {evex} vptestnmd 64(%r12), %ymm12, %k7
    {evex} vptestnmd -129(%rsp), %ymm17, %k1
    {evex} vptestnmd 0(%rsi,%rbp,4), %ymm16, %k2
    {evex} vptestnmd -4096(%rax,%r12,8), %ymm3, %k3
    {evex} vptestnmd 1001(%r9,%rax,1), %ymm25, %k4
    {evex} vptestnmd gnu_back(%rip), %ymm9, %k5
    {evex} vptestnmd %ymm31, %ymm20, %k6{%k7}
    {evex} vptestnmd 0(%r15), %ymm12, %k1{%k2}
    {evex} vptestnmd 4064(%rbx), %ymm17, %k3{%k4}
    {evex} vptestnmd -2147483648(%r10), %ymm16, %k5{%k6}
    {evex} vptestnmd 0(%r12), %ymm3, %k7{%k1}
    {evex} vptestnmd -32(%rsp), %ymm25, %k2{%k3}
    {evex} vptestnmd 2147483647(%r12), %ymm9, %k4{%k5}
    {evex} vptestnmd 0(%r15,%r15,2), %ymm31, %k6{%k7}
    {evex} vptestnmd 64(%rsp,%rsi,4), %ymm20, %k1{%k2}
    {evex} vptestnmd 4660(%r13,%rcx,8), %ymm12, %k3{%k4}
    {evex} vptestnmd gnu_fwd(%rip), %ymm17, %k5{%k6}
    {evex} vptestnmd %zmm16, %zmm3, %k7
    {evex} vptestnmd 0(%rcx), %zmm25, %k1
    {evex} vptestnmd -64(%rsi), %zmm9, %k2
    {evex} vptestnmd -129(%r11), %zmm31, %k3
    {evex} vptestnmd 0(%rsp), %zmm20, %k4
    {evex} vptestnmd 128(%r12), %zmm12, %k5
    {evex} vptestnmd 1001(%rsp), %zmm17, %k6
    {evex} vptestnmd 0(%rax,%r9,1), %zmm16, %k7
    {evex} vptestnmd -8192(%rbp,%rbp,2), %zmm3, %k1
    {evex} vptestnmd -2147483648(%r12,%r12,4), %zmm25, %k2
    {evex} vptestnmd gnu_back(%rip), %zmm9, %k3
    {evex} vptestnmd %zmm31, %zmm20, %k4{%k5}
    {evex} vptestnmd 0(%r8), %zmm12, %k6{%k7}
    {evex} vptestnmd 8128(%rdi), %zmm17, %k1{%k2}
    {evex} vptestnmd 2147483647(%r14), %zmm16, %k3{%k4}
    {evex} vptestnmd 0(%r12), %zmm3, %k5{%k6}
    {evex} vptestnmd -64(%rsp), %zmm25, %k7{%k1}
    {evex} vptestnmd 4660(%r12), %zmm9, %k2{%k3}
    {evex} vptestnmd 0(%r8,%rax,8), %zmm31, %k4{%k5}
    {evex} vptestnmd 128(%rdi,%r15,1), %zmm20, %k6{%k7}
    {evex} vptestnmd -129(%r15,%rsi,2), %zmm12, %k1{%k2}
    {evex} vptestnmd gnu_fwd(%rip), %zmm17, %k3{%k4}
    {evex} vpcmpltb %xmm16, %xmm3, %k5
    {evex} vpcmpltb 0(%rdx), %xmm25, %k6
    {evex} vpcmpltb -2048(%r15), %xmm9, %k7
    {evex} vpcmpltb 1001(%rcx), %xmm31, %k1
    {evex} vpcmpltb 0(%rsp), %xmm20, %k2
    {evex} vpcmpltb 2032(%r12), %xmm12, %k3
    {evex} vpcmpltb -2147483648(%rsp), %xmm17, %k4
g64:
    {evex} vpcmpltb 0(%rcx,%rcx,4), %xmm16, %k5
    {evex} vpcmpltb -16(%rax,%r9,8), %xmm3, %k6
    {evex} vpcmpltb 2147483647(%r9,%rbp,1), %xmm25, %k7
    {evex} vpcmpltb gnu_back(%rip), %xmm9, %k1
    {evex} vpcmpltb %xmm31, %xmm20, %k2{%k3}
    {evex} vpcmpltb 0(%r9), %xmm12, %k4{%k5}
    {evex} vpcmpltb 32(%r8), %xmm17, %k6{%k7}
    {evex} vpcmpltb 4660(%rbp), %xmm16, %k1{%k2}
    {evex} vpcmpltb 0(%r12), %xmm3, %k3{%k4}
    {evex} vpcmpltb -2048(%rsp), %xmm25, %k5{%k6}
    {evex} vpcmpltb -129(%r12), %xmm9, %k7{%k1}
    {evex} vpcmpltb 0(%r12,%r12,2), %xmm31, %k2{%k3}
    {evex} vpcmpltb 2032(%rsp,%rax,4), %xmm20, %k4{%k5}
    {evex} vpcmpltb 1001(%r13,%r15,8), %xmm12, %k6{%k7}
    {evex} vpcmpltb gnu_fwd(%rip), %xmm17, %k1{%k2}
    {evex} vpcmpltb %ymm16, %ymm3, %k3
    {evex} vpcmpltb 0(%rbx), %ymm25, %k4
    {evex} vpcmpltb -4096(%r13), %ymm9, %k5
    {evex} vpcmpltb -2147483648(%rdx), %ymm31, %k6
    {evex} vpcmpltb 0(%rsp), %ymm20, %k7
    {evex} vpcmpltb 4064(%r12), %ymm12, %k1
    {evex} vpcmpltb 2147483647(%rsp), %ymm17, %k2
    {evex} vpcmpltb 0(%rdx,%rsi,1), %ymm16, %k3
    {evex} vpcmpltb -32(%rbp,%rcx,2), %ymm3, %k4
    {evex} vpcmpltb 4660(%r12,%r9,4), %ymm25, %k5
    {evex} vpcmpltb gnu_back(%rip), %ymm9, %k6
    {evex} vpcmpltb %ymm31, %ymm20, %k7{%k1}
    {evex} vpcmpltb 0(%r10), %ymm12, %k2{%k3}
    {evex} vpcmpltb 64(%r9), %ymm17, %k4{%k5}
    {evex} vpcmpltb -129(%rbx), %ymm16, %k6{%k7}
    {evex} vpcmpltb 0(%r12), %ymm3, %k1{%k2}
    {evex} vpcmpltb -4096(%rsp), %ymm25, %k3{%k4}
    {evex} vpcmpltb 1001(%r12), %ymm9, %k5{%k6}
    {evex} vpcmpltb 0(%r9,%rbp,8), %ymm31, %k7{%k1}
    {evex} vpcmpltb 4064(%rdi,%r12,1), %ymm20, %k2{%k3}
    {evex} vpcmpltb -2147483648(%r15,%rax,2), %ymm12, %k4{%k5}
    {evex} vpcmpltb gnu_fwd(%rip), %ymm17, %k6{%k7}
    {evex} vpcmpltb %zmm16, %zmm3, %k1
    {evex} vpcmpltb 0(%rsi), %zmm25, %k2
    {evex} vpcmpltb -8192(%r10), %zmm9, %k3
    {evex} vpcmpltb 2147483647(%rsi), %zmm31, %k4
    {evex} vpcmpltb 0(%rsp), %zmm20, %k5
    {evex} vpcmpltb 8128(%r12), %zmm12, %k6
    {evex} vpcmpltb 4660(%rsp), %zmm17, %k7
    {evex} vpcmpltb 0(%rsp,%r15,4), %zmm16, %k1
    {evex} vpcmpltb -64(%rax,%rsi,8), %zmm3, %k2
    {evex} vpcmpltb -129(%r9,%rcx,1), %zmm25, %k3
    {evex} vpcmpltb gnu_back(%rip), %zmm9, %k4
    {evex} vpcmpltb %zmm31, %zmm20, %k5{%k6}
    {evex} vpcmpltb 0(%r11), %zmm12, %k7{%k1}
    {evex} vpcmpltb 128(%r11), %zmm17, %k2{%k3}
    {evex} vpcmpltb 1001(%rdi), %zmm16, %k4{%k5}
    {evex} vpcmpltb 0(%r12), %zmm3, %k6{%k7}
    {evex} vpcmpltb -8192(%rsp), %zmm25, %k1{%k2}
    {evex} vpcmpltb -2147483648(%r12), %zmm9, %k3{%k4}
    {evex} vpcmpltb 0(%r14,%r9,2), %zmm31, %k5{%k6}
    {evex} vpcmpltb 8128(%rsp,%rbp,4), %zmm20, %k7{%k1}
    {evex} vpcmpltb 2147483647(%r13,%r12,8), %zmm12, %k2{%k3}
    {evex} vpcmpltb gnu_fwd(%rip), %zmm17, %k4{%k5}
    {evex} vpcmpleb %xmm16, %xmm3, %k6
    {evex} vpcmpleb 0(%rdi), %xmm25, %k7
    {evex} vpcmpleb -16(%r14), %xmm9, %k1
    {evex} vpcmpleb 4660(%r15), %xmm31, %k2
    {evex} vpcmpleb 0(%rsp), %xmm20, %k3
    {evex} vpcmpleb 32(%r12), %xmm12, %k4
    {evex} vpcmpleb -129(%rsp), %xmm17, %k5
    {evex} vpcmpleb 0(%rsi,%rax,1), %xmm16, %k6
    {evex} vpcmpleb -2048(%rbp,%r15,2), %xmm3, %k7
    {evex} vpcmpleb 1001(%r12,%rsi,4), %xmm25, %k1
    {evex} vpcmpleb gnu_back(%rip), %xmm9, %k2
    {evex} vpcmpleb %xmm31, %xmm20, %k3{%k4}
    {evex} vpcmpleb 0(%r14), %xmm12, %k5{%k6}
    {evex} vpcmpleb 2032(%rcx), %xmm17, %k7{%k1}
    {evex} vpcmpleb -2147483648(%r8), %xmm16, %k2{%k3}
    {evex} vpcmpleb 0(%r12), %xmm3, %k4{%k5}
    {evex} vpcmpleb -16(%rsp), %xmm25, %k6{%k7}
    {evex} vpcmpleb 2147483647(%r12), %xmm9, %k1{%k2}
    {evex} vpcmpleb 0(%r15,%rcx,8), %xmm31, %k3{%k4}
    {evex} vpcmpleb 32(%rdi,%r9,1), %xmm20, %k5{%k6}
    {evex} vpcmpleb 4660(%r15,%rbp,2), %xmm12, %k7{%k1}
    {evex} vpcmpleb gnu_fwd(%rip), %xmm17, %k2{%k3}
    {evex} vpcmpleb %ymm16, %ymm3, %k4
    {evex} vpcmpleb 0(%r15), %ymm25, %k5
    {evex} vpcmpleb -32(%rbp), %ymm9, %k6
    {evex} vpcmpleb -129(%r13), %ymm31, %k7
    {evex} vpcmpleb 0(%rsp), %ymm20, %k1
    {evex} vpcmpleb 64(%r12), %ymm12, %k2
    {evex} vpcmpleb 1001(%rsp), %ymm17, %k3
    {evex} vpcmpleb 0(%rax,%r12,4), %ymm16, %k4
    {evex} vpcmpleb -4096(%rax,%rax,8), %ymm3, %k5
    {evex} vpcmpleb -2147483648(%r9,%r15,1), %ymm25, %k6
    {evex} vpcmpleb gnu_back(%rip), %ymm9, %k7
    {evex} vpcmpleb %ymm31, %ymm20, %k1{%k2}
    {evex} vpcmpleb 0(%rcx), %ymm12, %k3{%k4}
    {evex} vpcmpleb 4064(%rdx), %ymm17, %k5{%k6}
    {evex} vpcmpleb 2147483647(%r9), %ymm16, %k7{%k1}
    {evex} vpcmpleb 0(%r12), %ymm3, %k2{%k3}
    {evex} vpcmpleb -32(%rsp), %ymm25, %k4{%k5}
    {evex} vpcmpleb 4660(%r12), %ymm9, %k6{%k7}
    {evex} vpcmpleb 0(%r8,%rsi,2), %ymm31, %k1{%k2}
    {evex} vpcmpleb 64(%rsp,%rcx,4), %ymm20, %k3{%k4}
    {evex} vpcmpleb -129(%r13,%r9,8), %ymm12, %k5{%k6}
    {evex} vpcmpleb gnu_fwd(%rip), %ymm17, %k7{%k1}
    {evex} vpcmpleb %zmm16, %zmm3, %k2
    {evex} vpcmpleb 0(%r8), %zmm25, %k3
    {evex} vpcmpleb -64(%rbx), %zmm9, %k4
    {evex} vpcmpleb 1001(%r10), %zmm31, %k5
    {evex} vpcmpleb 0(%rsp), %zmm20, %k6
    {evex} vpcmpleb 128(%r12), %zmm12, %k7
    {evex} vpcmpleb -2147483648(%rsp), %zmm17, %k1
    {evex} vpcmpleb 0(%rcx,%rbp,1), %zmm16, %k2
    {evex} vpcmpleb -8192(%rbp,%r12,2), %zmm3, %k3
    {evex} vpcmpleb 2147483647(%r12,%rax,4), %zmm25, %k4
    {evex} vpcmpleb gnu_back(%rip), %zmm9, %k5
    {evex} vpcmpleb %zmm31, %zmm20, %k6{%k7}
    {evex} vpcmpleb 0(%rdx), %zmm12, %k1{%k2}
    {evex} vpcmpleb 8128(%rsi), %zmm17, %k3{%k4}
    {evex} vpcmpleb 4660(%r11), %zmm16, %k5{%k6}
    {evex} vpcmpleb 0(%r12), %zmm3, %k7{%k1}
    {evex} vpcmpleb -64(%rsp), %zmm25, %k2{%k3}
    {evex} vpcmpleb -129(%r12), %zmm9, %k4{%k5}
    {evex} vpcmpleb 0(%r12,%r15,8), %zmm31, %k6{%k7}
    {evex} vpcmpleb 128(%rdi,%rsi,1), %zmm20, %k1{%k2}
    {evex} vpcmpleb 1001(%r15,%rcx,2), %zmm12, %k3{%k4}
    {evex} vpcmpleb gnu_fwd(%rip), %zmm17, %k5{%k6}
    {evex} vpcmpneqb %xmm16, %xmm3, %k7
    {evex} vpcmpneqb 0(%r9), %xmm25, %k1
    {evex} vpcmpneqb -2048(%rdi), %xmm9, %k2
    {evex} vpcmpneqb -2147483648(%r14), %xmm31, %k3
    {evex} vpcmpneqb 0(%rsp), %xmm20, %k4
    {evex} vpcmpneqb 2032(%r12), %xmm12, %k5
    {evex} vpcmpneqb 2147483647(%rsp), %xmm17, %k6
    {evex} vpcmpneqb 0(%rdx,%r9,4), %xmm16, %k7
    {evex} vpcmpneqb -16(%rax,%rbp,8), %xmm3, %k1
    {evex} vpcmpneqb 4660(%r9,%r12,1), %xmm25, %k2
    {evex} vpcmpneqb gnu_back(%rip), %xmm9, %k3
    {evex} vpcmpneqb %xmm31, %xmm20, %k4{%k5}
    {evex} vpcmpneqb 0(%rbx), %xmm12, %k6{%k7}
    {evex} vpcmpneqb 32(%r15), %xmm17, %k1{%k2}
    {evex} vpcmpneqb -129(%rcx), %xmm16, %k3{%k4}
    {evex} vpcmpneqb 0(%r12), %xmm3, %k5{%k6}
    {evex} vpcmpneqb -2048(%rsp), %xmm25, %k7{%k1}
    {evex} vpcmpneqb 1001(%r12), %xmm9, %k2{%k3}
    {evex} vpcmpneqb 0(%r9,%rax,2), %xmm31, %k4{%k5}
    {evex} vpcmpneqb 2032(%rsp,%r15,4), %xmm20, %k6{%k7}
    {evex} vpcmpneqb -2147483648(%r13,%rsi,8), %xmm12, %k1{%k2}
    {evex} vpcmpneqb gnu_fwd(%rip), %xmm17, %k3{%k4}
    {evex} vpcmpneqb %ymm16, %ymm3, %k5
    {evex} vpcmpneqb 0(%r10), %ymm25, %k6
    {evex} vpcmpneqb -4096(%r8), %ymm9, %k7
    {evex} vpcmpneqb 2147483647(%rbp), %ymm31, %k1
    {evex} vpcmpneqb 0(%rsp), %ymm20, %k2
    {evex} vpcmpneqb 4064(%r12), %ymm12, %k3
    {evex} vpcmpneqb 4660(%rsp), %ymm17, %k4
    {evex} vpcmpneqb 0(%rsp,%rcx,1), %ymm16, %k5
    {evex} vpcmpneqb -32(%rbp,%r9,2), %ymm3, %k6
    {evex} vpcmpneqb -129(%r12,%rbp,4), %ymm25, %k7
    {evex} vpcmpneqb gnu_back(%rip), %ymm9, %k1
    {evex} vpcmpneqb %ymm31, %ymm20, %k2{%k3}
    {evex} vpcmpneqb 0(%rsi), %ymm12, %k4{%k5}
    {evex} vpcmpneqb 64(%r13), %ymm17, %k6{%k7}
    {evex} vpcmpneqb 1001(%rdx), %ymm16, %k1{%k2}
    {evex} vpcmpneqb 0(%r12), %ymm3, %k3{%k4}
    {evex} vpcmpneqb -4096(%rsp), %ymm25, %k5{%k6}
    {evex} vpcmpneqb -2147483648(%r12), %ymm9, %k7{%k1}
    {evex} vpcmpneqb 0(%r14,%r12,8), %ymm31, %k2{%k3}
    {evex} vpcmpneqb 4064(%rdi,%rax,1), %ymm20, %k4{%k5}
    {evex} vpcmpneqb 2147483647(%r15,%r15,2), %ymm12, %k6{%k7}
    {evex} vpcmpneqb gnu_fwd(%rip), %ymm17, %k1{%k2}
    {evex} vpcmpneqb %zmm16, %zmm3, %k3
    {evex} vpcmpneqb 0(%r11), %zmm25, %k4
    {evex} vpcmpneqb -8192(%r9), %zmm9, %k5
    {evex} vpcmpneqb 4660(%rbx), %zmm31, %k6
    {evex} vpcmpneqb 0(%rsp), %zmm20, %k7
    {evex} vpcmpneqb 8128(%r12), %zmm12, %k1
    {evex} vpcmpneqb -129(%rsp), %zmm17, %k2
    {evex} vpcmpneqb 0(%rsi,%rsi,4), %zmm16, %k3
    {evex} vpcmpneqb -64(%rax,%rcx,8), %zmm3, %k4
    {evex} vpcmpneqb 1001(%r9,%r9,1), %zmm25, %k5
    {evex} vpcmpneqb gnu_back(%rip), %zmm9, %k6
    {evex} vpcmpneqb %zmm31, %zmm20, %k7{%k1}
    {evex} vpcmpneqb 0(%rdi), %zmm12, %k2{%k3}
    {evex} vpcmpneqb 128(%r10), %zmm17, %k4{%k5}
    {evex} vpcmpneqb -2147483648(%rsi), %zmm16, %k6{%k7}
    {evex} vpcmpneqb 0(%r12), %zmm3, %k1{%k2}
    {evex} vpcmpneqb -8192(%rsp), %zmm25, %k3{%k4}
    {evex} vpcmpneqb 2147483647(%r12), %zmm9, %k5{%k6}
    {evex} vpcmpneqb 0(%r15,%rbp,2), %zmm31, %k7{%k1}
    {evex} vpcmpneqb 8128(%rsp,%r12,4), %zmm20, %k2{%k3}
    {evex} vpcmpneqb 4660(%r13,%rax,8), %zmm12, %k4{%k5}
    {evex} vpcmpneqb gnu_fwd(%rip), %zmm17, %k6{%k7}
    {evex} vpcmpnltb %xmm16, %xmm3, %k1
    {evex} vpcmpnltb 0(%r14), %xmm25, %k2
    {evex} vpcmpnltb -16(%r11), %xmm9, %k3
    {evex} vpcmpnltb -129(%rdi), %xmm31, %k4
    {evex} vpcmpnltb 0(%rsp), %xmm20, %k5
    {evex} vpcmpnltb 32(%r12), %xmm12, %k6
    {evex} vpcmpnltb 1001(%rsp), %xmm17, %k7
    {evex} vpcmpnltb 0(%rax,%r15,1), %xmm16, %k1
    {evex} vpcmpnltb -2048(%rbp,%rsi,2), %xmm3, %k2
g65:
    {evex} vpcmpnltb -2147483648(%r12,%rcx,4), %xmm25, %k3
    {evex} vpcmpnltb gnu_back(%rip), %xmm9, %k4
    {evex} vpcmpnltb %xmm31, %xmm20, %k5{%k6}
    {evex} vpcmpnltb 0(%r15), %xmm12, %k7{%k1}
    {evex} vpcmpnltb 2032(%r14), %xmm17, %k2{%k3}
    {evex} vpcmpnltb 2147483647(%r15), %xmm16, %k4{%k5}
    {evex} vpcmpnltb 0(%r12), %xmm3, %k6{%k7}
    {evex} vpcmpnltb -16(%rsp), %xmm25, %k1{%k2}
    {evex} vpcmpnltb 4660(%r12), %xmm9, %k3{%k4}
    {evex} vpcmpnltb 0(%r8,%r9,8), %xmm31, %k5{%k6}
    {evex} vpcmpnltb 32(%rdi,%rbp,1), %xmm20, %k7{%k1}
    {evex} vpcmpnltb -129(%r15,%r12,2), %xmm12, %k2{%k3}
    {evex} vpcmpnltb gnu_fwd(%rip), %xmm17, %k4{%k5}
    {evex} vpcmpnltb %ymm16, %ymm3, %k6
    {evex} vpcmpnltb 0(%rcx), %ymm25, %k7
    {evex} vpcmpnltb -32(%rcx), %ymm9, %k1
    {evex} vpcmpnltb 1001(%r8), %ymm31, %k2
    {evex} vpcmpnltb 0(%rsp), %ymm20, %k3
    {evex} vpcmpnltb 64(%r12), %ymm12, %k4
    {evex} vpcmpnltb -2147483648(%rsp), %ymm17, %k5
    {evex} vpcmpnltb 0(%rcx,%rax,4), %ymm16, %k6
    {evex} vpcmpnltb -4096(%rax,%r15,8), %ymm3, %k7
    {evex} vpcmpnltb 2147483647(%r9,%rsi,1), %ymm25, %k1
    {evex} vpcmpnltb gnu_back(%rip), %ymm9, %k2
    {evex} vpcmpnltb %ymm31, %ymm20, %k3{%k4}
    {evex} vpcmpnltb 0(%r8), %ymm12, %k5{%k6}
    {evex} vpcmpnltb 4064(%rbp), %ymm17, %k7{%k1}
    {evex} vpcmpnltb 4660(%r13), %ymm16, %k2{%k3}
    {evex} vpcmpnltb 0(%r12), %ymm3, %k4{%k5}
    {evex} vpcmpnltb -32(%rsp), %ymm25, %k6{%k7}
    {evex} vpcmpnltb -129(%r12), %ymm9, %k1{%k2}
    {evex} vpcmpnltb 0(%r12,%rcx,2), %ymm31, %k3{%k4}
    {evex} vpcmpnltb 64(%rsp,%r9,4), %ymm20, %k5{%k6}
    {evex} vpcmpnltb 1001(%r13,%rbp,8), %ymm12, %k7{%k1}
    {evex} vpcmpnltb gnu_fwd(%rip), %ymm17, %k2{%k3}
    {evex} vpcmpnltb %zmm16, %zmm3, %k4
    {evex} vpcmpnltb 0(%rdx), %zmm25, %k5
    {evex} vpcmpnltb -64(%rdx), %zmm9, %k6
    {evex} vpcmpnltb -2147483648(%r9), %zmm31, %k7
    {evex} vpcmpnltb 0(%rsp), %zmm20, %k1
    {evex} vpcmpnltb 128(%r12), %zmm12, %k2
    {evex} vpcmpnltb 2147483647(%rsp), %zmm17, %k3
    {evex} vpcmpnltb 0(%rdx,%r12,1), %zmm16, %k4
    {evex} vpcmpnltb -8192(%rbp,%rax,2), %zmm3, %k5
    {evex} vpcmpnltb 4660(%r12,%r15,4), %zmm25, %k6
    {evex} vpcmpnltb gnu_back(%rip), %zmm9, %k7
    {evex} vpcmpnltb %zmm31, %zmm20, %k1{%k2}
    {evex} vpcmpnltb 0(%r9), %zmm12, %k3{%k4}
    {evex} vpcmpnltb 8128(%rbx), %zmm17, %k5{%k6}
    {evex} vpcmpnltb -129(%r10), %zmm16, %k7{%k1}
    {evex} vpcmpnltb 0(%r12), %zmm3, %k2{%k3}
    {evex} vpcmpnltb -64(%rsp), %zmm25, %k4{%k5}
    {evex} vpcmpnltb 1001(%r12), %zmm9, %k6{%k7}
    {evex} vpcmpnltb 0(%r9,%rsi,8), %zmm31, %k1{%k2}
    {evex} vpcmpnltb 128(%rdi,%rcx,1), %zmm20, %k3{%k4}
    {evex} vpcmpnltb -2147483648(%r15,%r9,2), %zmm12, %k5{%k6}
    {evex} vpcmpnltb gnu_fwd(%rip), %zmm17, %k7{%k1}
    {evex} vpcmpnleb %xmm16, %xmm3, %k2
    {evex} vpcmpnleb 0(%rbx), %xmm25, %k3
    {evex} vpcmpnleb -2048(%rsi), %xmm9, %k4
    {evex} vpcmpnleb 2147483647(%r11), %xmm31, %k5
    {evex} vpcmpnleb 0(%rsp), %xmm20, %k6
    {evex} vpcmpnleb 2032(%r12), %xmm12, %k7
    {evex} vpcmpnleb 4660(%rsp), %xmm17, %k1
    {evex} vpcmpnleb 0(%rsp,%rbp,4), %xmm16, %k2
    {evex} vpcmpnleb -16(%rax,%r12,8), %xmm3, %k3
    {evex} vpcmpnleb -129(%r9,%rax,1), %xmm25, %k4
    {evex} vpcmpnleb gnu_back(%rip), %xmm9, %k5
    {evex} vpcmpnleb %xmm31, %xmm20, %k6{%k7}
    {evex} vpcmpnleb 0(%r10), %xmm12, %k1{%k2}
    {evex} vpcmpnleb 32(%rdi), %xmm17, %k3{%k4}
    {evex} vpcmpnleb 1001(%r14), %xmm16, %k5{%k6}
    {evex} vpcmpnleb 0(%r12), %xmm3, %k7{%k1}
    {evex} vpcmpnleb -2048(%rsp), %xmm25, %k2{%k3}
    {evex} vpcmpnleb -2147483648(%r12), %xmm9, %k4{%k5}
    {evex} vpcmpnleb 0(%r14,%r15,2), %xmm31, %k6{%k7}
    {evex} vpcmpnleb 2032(%rsp,%rsi,4), %xmm20, %k1{%k2}
    {evex} vpcmpnleb 2147483647(%r13,%rcx,8), %xmm12, %k3{%k4}
    {evex} vpcmpnleb gnu_fwd(%rip), %xmm17, %k5{%k6}
    {evex} vpcmpnleb %ymm16, %ymm3, %k7
    {evex} vpcmpnleb 0(%rsi), %ymm25, %k1
    {evex} vpcmpnleb -4096(%r15), %ymm9, %k2
    {evex} vpcmpnleb 4660(%rcx), %ymm31, %k3
    {evex} vpcmpnleb 0(%rsp), %ymm20, %k4
    {evex} vpcmpnleb 4064(%r12), %ymm12, %k5
    {evex} vpcmpnleb -129(%rsp), %ymm17, %k6
    {evex} vpcmpnleb 0(%rsi,%r9,1), %ymm16, %k7
    {evex} vpcmpnleb -32(%rbp,%rbp,2), %ymm3, %k1
    {evex} vpcmpnleb 1001(%r12,%r12,4), %ymm25, %k2
    {evex} vpcmpnleb gnu_back(%rip), %ymm9, %k3
    {evex} vpcmpnleb %ymm31, %ymm20, %k4{%k5}
    {evex} vpcmpnleb 0(%r11), %ymm12, %k6{%k7}
    {evex} vpcmpnleb 64(%r8), %ymm17, %k1{%k2}
    {evex} vpcmpnleb -2147483648(%rbp), %ymm16, %k3{%k4}
    {evex} vpcmpnleb 0(%r12), %ymm3, %k5{%k6}
    {evex} vpcmpnleb -4096(%rsp), %ymm25, %k7{%k1}
    {evex} vpcmpnleb 2147483647(%r12), %ymm9, %k2{%k3}
    {evex} vpcmpnleb 0(%r15,%rax,8), %ymm31, %k4{%k5}
    {evex} vpcmpnleb 4064(%rdi,%r15,1), %ymm20, %k6{%k7}
    {evex} vpcmpnleb 4660(%r15,%rsi,2), %ymm12, %k1{%k2}
    {evex} vpcmpnleb gnu_fwd(%rip), %ymm17, %k3{%k4}
    {evex} vpcmpnleb %zmm16, %zmm3, %k5
    {evex} vpcmpnleb 0(%rdi), %zmm25, %k6
    {evex} vpcmpnleb -8192(%r13), %zmm9, %k7
    {evex} vpcmpnleb -129(%rdx), %zmm31, %k1
    {evex} vpcmpnleb 0(%rsp), %zmm20, %k2
    {evex} vpcmpnleb 8128(%r12), %zmm12, %k3
    {evex} vpcmpnleb 1001(%rsp), %zmm17, %k4
    {evex} vpcmpnleb 0(%rax,%rcx,4), %zmm16, %k5
    {evex} vpcmpnleb -64(%rax,%r9,8), %zmm3, %k6
    {evex} vpcmpnleb -2147483648(%r9,%rbp,1), %zmm25, %k7
    {evex} vpcmpnleb gnu_back(%rip), %zmm9, %k1
    {evex} vpcmpnleb %zmm31, %zmm20, %k2{%k3}
    {evex} vpcmpnleb 0(%r14), %zmm12, %k4{%k5}
    {evex} vpcmpnleb 128(%r9), %zmm17, %k6{%k7}
    {evex} vpcmpnleb 2147483647(%rbx), %zmm16, %k1{%k2}
    {evex} vpcmpnleb 0(%r12), %zmm3, %k3{%k4}
    {evex} vpcmpnleb -8192(%rsp), %zmm25, %k5{%k6}
    {evex} vpcmpnleb 4660(%r12), %zmm9, %k7{%k1}
    {evex} vpcmpnleb 0(%r8,%r12,2), %zmm31, %k2{%k3}
    {evex} vpcmpnleb 8128(%rsp,%rax,4), %zmm20, %k4{%k5}
    {evex} vpcmpnleb -129(%r13,%r15,8), %zmm12, %k6{%k7}
    {evex} vpcmpnleb gnu_fwd(%rip), %zmm17, %k1{%k2}
    {evex} vpcmpequb %xmm16, %xmm3, %k3
    {evex} vpcmpequb 0(%r15), %xmm25, %k4
    {evex} vpcmpequb -16(%r10), %xmm9, %k5
    {evex} vpcmpequb 1001(%rsi), %xmm31, %k6
    {evex} vpcmpequb 0(%rsp), %xmm20, %k7
    {evex} vpcmpequb 32(%r12), %xmm12, %k1
    {evex} vpcmpequb -2147483648(%rsp), %xmm17, %k2
    {evex} vpcmpequb 0(%rcx,%rsi,1), %xmm16, %k3
    {evex} vpcmpequb -2048(%rbp,%rcx,2), %xmm3, %k4
    {evex} vpcmpequb 2147483647(%r12,%r9,4), %xmm25, %k5
    {evex} vpcmpequb gnu_back(%rip), %xmm9, %k6
    {evex} vpcmpequb %xmm31, %xmm20, %k7{%k1}
    {evex} vpcmpequb 0(%rcx), %xmm12, %k2{%k3}
    {evex} vpcmpequb 2032(%r11), %xmm17, %k4{%k5}
    {evex} vpcmpequb 4660(%rdi), %xmm16, %k6{%k7}
    {evex} vpcmpequb 0(%r12), %xmm3, %k1{%k2}
    {evex} vpcmpequb -16(%rsp), %xmm25, %k3{%k4}
    {evex} vpcmpequb -129(%r12), %xmm9, %k5{%k6}
    {evex} vpcmpequb 0(%r12,%rbp,8), %xmm31, %k7{%k1}
    {evex} vpcmpequb 32(%rdi,%r12,1), %xmm20, %k2{%k3}
    {evex} vpcmpequb 1001(%r15,%rax,2), %xmm12, %k4{%k5}
    {evex} vpcmpequb gnu_fwd(%rip), %xmm17, %k6{%k7}
    {evex} vpcmpequb %ymm16, %ymm3, %k1
    {evex} vpcmpequb 0(%r8), %ymm25, %k2
    {evex} vpcmpequb -32(%r14), %ymm9, %k3
    {evex} vpcmpequb -2147483648(%r15), %ymm31, %k4
    {evex} vpcmpequb 0(%rsp), %ymm20, %k5
    {evex} vpcmpequb 64(%r12), %ymm12, %k6
    {evex} vpcmpequb 2147483647(%rsp), %ymm17, %k7
    {evex} vpcmpequb 0(%rdx,%r15,4), %ymm16, %k1
    {evex} vpcmpequb -4096(%rax,%rsi,8), %ymm3, %k2
    {evex} vpcmpequb 4660(%r9,%rcx,1), %ymm25, %k3
    {evex} vpcmpequb gnu_back(%rip), %ymm9, %k4
    {evex} vpcmpequb %ymm31, %ymm20, %k5{%k6}
    {evex} vpcmpequb 0(%rdx), %ymm12, %k7{%k1}
    {evex} vpcmpequb 4064(%rcx), %ymm17, %k2{%k3}
    {evex} vpcmpequb -129(%r8), %ymm16, %k4{%k5}
    {evex} vpcmpequb 0(%r12), %ymm3, %k6{%k7}
    {evex} vpcmpequb -32(%rsp), %ymm25, %k1{%k2}
    {evex} vpcmpequb 1001(%r12), %ymm9, %k3{%k4}
    {evex} vpcmpequb 0(%r9,%r9,2), %ymm31, %k5{%k6}
    {evex} vpcmpequb 64(%rsp,%rbp,4), %ymm20, %k7{%k1}
    {evex} vpcmpequb -2147483648(%r13,%r12,8), %ymm12, %k2{%k3}
    {evex} vpcmpequb gnu_fwd(%rip), %ymm17, %k4{%k5}
    {evex} vpcmpequb %zmm16, %zmm3, %k6
    {evex} vpcmpequb 0(%r9), %zmm25, %k7
    {evex} vpcmpequb -64(%rbp), %zmm9, %k1
    {evex} vpcmpequb 2147483647(%r13), %zmm31, %k2
    {evex} vpcmpequb 0(%rsp), %zmm20, %k3
    {evex} vpcmpequb 128(%r12), %zmm12, %k4
    {evex} vpcmpequb 4660(%rsp), %zmm17, %k5
    {evex} vpcmpequb 0(%rsp,%rax,1), %zmm16, %k6
    {evex} vpcmpequb -8192(%rbp,%r15,2), %zmm3, %k7
    {evex} vpcmpequb -129(%r12,%rsi,4), %zmm25, %k1
    {evex} vpcmpequb gnu_back(%rip), %zmm9, %k2
    {evex} vpcmpequb %zmm31, %zmm20, %k3{%k4}
    {evex} vpcmpequb 0(%rbx), %zmm12, %k5{%k6}
    {evex} vpcmpequb 8128(%rdx), %zmm17, %k7{%k1}
    {evex} vpcmpequb 1001(%r9), %zmm16, %k2{%k3}
    {evex} vpcmpequb 0(%r12), %zmm3, %k4{%k5}
    {evex} vpcmpequb -64(%rsp), %zmm25, %k6{%k7}
    {evex} vpcmpequb -2147483648(%r12), %zmm9, %k1{%k2}
    {evex} vpcmpequb 0(%r14,%rcx,8), %zmm31, %k3{%k4}
    {evex} vpcmpequb 128(%rdi,%r9,1), %zmm20, %k5{%k6}
    {evex} vpcmpequb 2147483647(%r15,%rbp,2), %zmm12, %k7{%k1}
    {evex} vpcmpequb gnu_fwd(%rip), %zmm17, %k2{%k3}
    {evex} vpcmpltub %xmm16, %xmm3, %k4
    {evex} vpcmpltub 0(%r10), %xmm25, %k5
    {evex} vpcmpltub -2048(%rbx), %xmm9, %k6
    {evex} vpcmpltub 4660(%r10), %xmm31, %k7
    {evex} vpcmpltub 0(%rsp), %xmm20, %k1
    {evex} vpcmpltub 2032(%r12), %xmm12, %k2
    {evex} vpcmpltub -129(%rsp), %xmm17, %k3
    {evex} vpcmpltub 0(%rsi,%r12,4), %xmm16, %k4
    {evex} vpcmpltub -16(%rax,%rax,8), %xmm3, %k5
    {evex} vpcmpltub 1001(%r9,%r15,1), %xmm25, %k6
    {evex} vpcmpltub gnu_back(%rip), %xmm9, %k7
g66:
    {evex} vpcmpltub %xmm31, %xmm20, %k1{%k2}
    {evex} vpcmpltub 0(%rsi), %xmm12, %k3{%k4}
    {evex} vpcmpltub 32(%rsi), %xmm17, %k5{%k6}
    {evex} vpcmpltub -2147483648(%r11), %xmm16, %k7{%k1}
    {evex} vpcmpltub 0(%r12), %xmm3, %k2{%k3}
    {evex} vpcmpltub -2048(%rsp), %xmm25, %k4{%k5}
    {evex} vpcmpltub 2147483647(%r12), %xmm9, %k6{%k7}
    {evex} vpcmpltub 0(%r15,%rsi,2), %xmm31, %k1{%k2}
    {evex} vpcmpltub 2032(%rsp,%rcx,4), %xmm20, %k3{%k4}
    {evex} vpcmpltub 4660(%r13,%r9,8), %xmm12, %k5{%k6}
    {evex} vpcmpltub gnu_fwd(%rip), %xmm17, %k7{%k1}
    {evex} vpcmpltub %ymm16, %ymm3, %k2
    {evex} vpcmpltub 0(%r11), %ymm25, %k3
    {evex} vpcmpltub -4096(%rdi), %ymm9, %k4
    {evex} vpcmpltub -129(%r14), %ymm31, %k5
    {evex} vpcmpltub 0(%rsp), %ymm20, %k6
    {evex} vpcmpltub 4064(%r12), %ymm12, %k7
    {evex} vpcmpltub 1001(%rsp), %ymm17, %k1
    {evex} vpcmpltub 0(%rax,%rbp,1), %ymm16, %k2
    {evex} vpcmpltub -32(%rbp,%r12,2), %ymm3, %k3
    {evex} vpcmpltub -2147483648(%r12,%rax,4), %ymm25, %k4
    {evex} vpcmpltub gnu_back(%rip), %ymm9, %k5
    {evex} vpcmpltub %ymm31, %ymm20, %k6{%k7}
    {evex} vpcmpltub 0(%rdi), %ymm12, %k1{%k2}
    {evex} vpcmpltub 64(%r15), %ymm17, %k3{%k4}
    {evex} vpcmpltub 2147483647(%rcx), %ymm16, %k5{%k6}
    {evex} vpcmpltub 0(%r12), %ymm3, %k7{%k1}
    {evex} vpcmpltub -4096(%rsp), %ymm25, %k2{%k3}
    {evex} vpcmpltub 4660(%r12), %ymm9, %k4{%k5}
    {evex} vpcmpltub 0(%r8,%r15,8), %ymm31, %k6{%k7}
    {evex} vpcmpltub 4064(%rdi,%rsi,1), %ymm20, %k1{%k2}
    {evex} vpcmpltub -129(%r15,%rcx,2), %ymm12, %k3{%k4}
    {evex} vpcmpltub gnu_fwd(%rip), %ymm17, %k5{%k6}
    {evex} vpcmpltub %zmm16, %zmm3, %k7
    {evex} vpcmpltub 0(%r14), %zmm25, %k1
    {evex} vpcmpltub -8192(%r8), %zmm9, %k2
    {evex} vpcmpltub 1001(%rbp), %zmm31, %k3
    {evex} vpcmpltub 0(%rsp), %zmm20, %k4
    {evex} vpcmpltub 8128(%r12), %zmm12, %k5
    {evex} vpcmpltub -2147483648(%rsp), %zmm17, %k6
    {evex} vpcmpltub 0(%rcx,%r9,4), %zmm16, %k7
    {evex} vpcmpltub -64(%rax,%rbp,8), %zmm3, %k1
    {evex} vpcmpltub 2147483647(%r9,%r12,1), %zmm25, %k2
    {evex} vpcmpltub gnu_back(%rip), %zmm9, %k3
    {evex} vpcmpltub %zmm31, %zmm20, %k4{%k5}
    {evex} vpcmpltub 0(%r15), %zmm12, %k6{%k7}
    {evex} vpcmpltub 128(%r13), %zmm17, %k1{%k2}
    {evex} vpcmpltub 4660(%rdx), %zmm16, %k3{%k4}
    {evex} vpcmpltub 0(%r12), %zmm3, %k5{%k6}
    {evex} vpcmpltub -8192(%rsp), %zmm25, %k7{%k1}
    {evex} vpcmpltub -129(%r12), %zmm9, %k2{%k3}
    {evex} vpcmpltub 0(%r12,%rax,2), %zmm31, %k4{%k5}
    {evex} vpcmpltub 8128(%rsp,%r15,4), %zmm20, %k6{%k7}
    {evex} vpcmpltub 1001(%r13,%rsi,8), %zmm12, %k1{%k2}
    {evex} vpcmpltub gnu_fwd(%rip), %zmm17, %k3{%k4}
    {evex} vpcmpleub %xmm16, %xmm3, %k5
    {evex} vpcmpleub 0(%rcx), %xmm25, %k6
    {evex} vpcmpleub -16(%r9), %xmm9, %k7
    {evex} vpcmpleub -2147483648(%rbx), %xmm31, %k1
    {evex} vpcmpleub 0(%rsp), %xmm20, %k2
    {evex} vpcmpleub 32(%r12), %xmm12, %k3
    {evex} vpcmpleub 2147483647(%rsp), %xmm17, %k4
    {evex} vpcmpleub 0(%rdx,%rcx,1), %xmm16, %k5
    {evex} vpcmpleub -2048(%rbp,%r9,2), %xmm3, %k6
    {evex} vpcmpleub 4660(%r12,%rbp,4), %xmm25, %k7
    {evex} vpcmpleub gnu_back(%rip), %xmm9, %k1
    {evex} vpcmpleub %xmm31, %xmm20, %k2{%k3}
    {evex} vpcmpleub 0(%r8), %xmm12, %k4{%k5}
    {evex} vpcmpleub 2032(%r10), %xmm17, %k6{%k7}
    {evex} vpcmpleub -129(%rsi), %xmm16, %k1{%k2}
    {evex} vpcmpleub 0(%r12), %xmm3, %k3{%k4}
    {evex} vpcmpleub -16(%rsp), %xmm25, %k5{%k6}
    {evex} vpcmpleub 1001(%r12), %xmm9, %k7{%k1}
    {evex} vpcmpleub 0(%r9,%r12,8), %xmm31, %k2{%k3}
    {evex} vpcmpleub 32(%rdi,%rax,1), %xmm20, %k4{%k5}
    {evex} vpcmpleub -2147483648(%r15,%r15,2), %xmm12, %k6{%k7}
    {evex} vpcmpleub gnu_fwd(%rip), %xmm17, %k1{%k2}
    {evex} vpcmpleub %ymm16, %ymm3, %k3
    {evex} vpcmpleub 0(%rdx), %ymm25, %k4
    {evex} vpcmpleub -32(%r11), %ymm9, %k5
    {evex} vpcmpleub 2147483647(%rdi), %ymm31, %k6
    {evex} vpcmpleub 0(%rsp), %ymm20, %k7
    {evex} vpcmpleub 64(%r12), %ymm12, %k1
    {evex} vpcmpleub 4660(%rsp), %ymm17, %k2
    {evex} vpcmpleub 0(%rsp,%rsi,4), %ymm16, %k3
    {evex} vpcmpleub -4096(%rax,%rcx,8), %ymm3, %k4
    {evex} vpcmpleub -129(%r9,%r9,1), %ymm25, %k5
    {evex} vpcmpleub gnu_back(%rip), %ymm9, %k6
    {evex} vpcmpleub %ymm31, %ymm20, %k7{%k1}
    {evex} vpcmpleub 0(%r9), %ymm12, %k2{%k3}
    {evex} vpcmpleub 4064(%r14), %ymm17, %k4{%k5}
    {evex} vpcmpleub 1001(%r15), %ymm16, %k6{%k7}
    {evex} vpcmpleub 0(%r12), %ymm3, %k1{%k2}
    {evex} vpcmpleub -32(%rsp), %ymm25, %k3{%k4}
    {evex} vpcmpleub -2147483648(%r12), %ymm9, %k5{%k6}
    {evex} vpcmpleub 0(%r14,%rbp,2), %ymm31, %k7{%k1}
    {evex} vpcmpleub 64(%rsp,%r12,4), %ymm20, %k2{%k3}
    {evex} vpcmpleub 2147483647(%r13,%rax,8), %ymm12, %k4{%k5}
    {evex} vpcmpleub gnu_fwd(%rip), %ymm17, %k6{%k7}
    {evex} vpcmpleub %zmm16, %zmm3, %k1
    {evex} vpcmpleub 0(%rbx), %zmm25, %k2
    {evex} vpcmpleub -64(%rcx), %zmm9, %k3
    {evex} vpcmpleub 4660(%r8), %zmm31, %k4
    {evex} vpcmpleub 0(%rsp), %zmm20, %k5
    {evex} vpcmpleub 128(%r12), %zmm12, %k6
    {evex} vpcmpleub -129(%rsp), %zmm17, %k7
    {evex} vpcmpleub 0(%rsi,%r15,1), %zmm16, %k1
    {evex} vpcmpleub -8192(%rbp,%rsi,2), %zmm3, %k2
    {evex} vpcmpleub 1001(%r12,%rcx,4), %zmm25, %k3
    {evex} vpcmpleub gnu_back(%rip), %zmm9, %k4
    {evex} vpcmpleub %zmm31, %zmm20, %k5{%k6}
    {evex} vpcmpleub 0(%r10), %zmm12, %k7{%k1}
    {evex} vpcmpleub 8128(%rbp), %zmm17, %k2{%k3}
    {evex} vpcmpleub -2147483648(%r13), %zmm16, %k4{%k5}
    {evex} vpcmpleub 0(%r12), %zmm3, %k6{%k7}
    {evex} vpcmpleub -64(%rsp), %zmm25, %k1{%k2}
    {evex} vpcmpleub 2147483647(%r12), %zmm9, %k3{%k4}
    {evex} vpcmpleub 0(%r15,%r9,8), %zmm31, %k5{%k6}
    {evex} vpcmpleub 128(%rdi,%rbp,1), %zmm20, %k7{%k1}
    {evex} vpcmpleub 4660(%r15,%r12,2), %zmm12, %k2{%k3}
    {evex} vpcmpleub gnu_fwd(%rip), %zmm17, %k4{%k5}
    {evex} vpcmpnequb %xmm16, %xmm3, %k6
    {evex} vpcmpnequb 0(%rsi), %xmm25, %k7
    {evex} vpcmpnequb -2048(%rdx), %xmm9, %k1
    {evex} vpcmpnequb -129(%r9), %xmm31, %k2
    {evex} vpcmpnequb 0(%rsp), %xmm20, %k3
    {evex} vpcmpnequb 2032(%r12), %xmm12, %k4
    {evex} vpcmpnequb 1001(%rsp), %xmm17, %k5
    {evex} vpcmpnequb 0(%rax,%rax,4), %xmm16, %k6
    {evex} vpcmpnequb -16(%rax,%r15,8), %xmm3, %k7
    {evex} vpcmpnequb -2147483648(%r9,%rsi,1), %xmm25, %k1
    {evex} vpcmpnequb gnu_back(%rip), %xmm9, %k2
    {evex} vpcmpnequb %xmm31, %xmm20, %k3{%k4}
    {evex} vpcmpnequb 0(%r11), %xmm12, %k5{%k6}
    {evex} vpcmpnequb 32(%rbx), %xmm17, %k7{%k1}
    {evex} vpcmpnequb 2147483647(%r10), %xmm16, %k2{%k3}
    {evex} vpcmpnequb 0(%r12), %xmm3, %k4{%k5}
    {evex} vpcmpnequb -2048(%rsp), %xmm25, %k6{%k7}
    {evex} vpcmpnequb 4660(%r12), %xmm9, %k1{%k2}
    {evex} vpcmpnequb 0(%r8,%rcx,2), %xmm31, %k3{%k4}
    {evex} vpcmpnequb 2032(%rsp,%r9,4), %xmm20, %k5{%k6}
    {evex} vpcmpnequb -129(%r13,%rbp,8), %xmm12, %k7{%k1}
    {evex} vpcmpnequb gnu_fwd(%rip), %xmm17, %k2{%k3}
    {evex} vpcmpnequb %ymm16, %ymm3, %k4
    {evex} vpcmpnequb 0(%rdi), %ymm25, %k5
    {evex} vpcmpnequb -4096(%rsi), %ymm9, %k6
    {evex} vpcmpnequb 1001(%r11), %ymm31, %k7
    {evex} vpcmpnequb 0(%rsp), %ymm20, %k1
    {evex} vpcmpnequb 4064(%r12), %ymm12, %k2
    {evex} vpcmpnequb -2147483648(%rsp), %ymm17, %k3
    {evex} vpcmpnequb 0(%rcx,%r12,1), %ymm16, %k4
    {evex} vpcmpnequb -32(%rbp,%rax,2), %ymm3, %k5
    {evex} vpcmpnequb 2147483647(%r12,%r15,4), %ymm25, %k6
    {evex} vpcmpnequb gnu_back(%rip), %ymm9, %k7
    {evex} vpcmpnequb %ymm31, %ymm20, %k1{%k2}
    {evex} vpcmpnequb 0(%r14), %ymm12, %k3{%k4}
    {evex} vpcmpnequb 64(%rdi), %ymm17, %k5{%k6}
    {evex} vpcmpnequb 4660(%r14), %ymm16, %k7{%k1}
    {evex} vpcmpnequb 0(%r12), %ymm3, %k2{%k3}
    {evex} vpcmpnequb -4096(%rsp), %ymm25, %k4{%k5}
    {evex} vpcmpnequb -129(%r12), %ymm9, %k6{%k7}
    {evex} vpcmpnequb 0(%r12,%rsi,8), %ymm31, %k1{%k2}
    {evex} vpcmpnequb 4064(%rdi,%rcx,1), %ymm20, %k3{%k4}
    {evex} vpcmpnequb 1001(%r15,%r9,2), %ymm12, %k5{%k6}
    {evex} vpcmpnequb gnu_fwd(%rip), %ymm17, %k7{%k1}
    {evex} vpcmpnequb %zmm16, %zmm3, %k2
    {evex} vpcmpnequb 0(%r15), %zmm25, %k3
    {evex} vpcmpnequb -8192(%r15), %zmm9, %k4
    {evex} vpcmpnequb -2147483648(%rcx), %zmm31, %k5
    {evex} vpcmpnequb 0(%rsp), %zmm20, %k6
    {evex} vpcmpnequb 8128(%r12), %zmm12, %k7
    {evex} vpcmpnequb 2147483647(%rsp), %zmm17, %k1
    {evex} vpcmpnequb 0(%rdx,%rbp,4), %zmm16, %k2
    {evex} vpcmpnequb -64(%rax,%r12,8), %zmm3, %k3
    {evex} vpcmpnequb 4660(%r9,%rax,1), %zmm25, %k4
    {evex} vpcmpnequb gnu_back(%rip), %zmm9, %k5
    {evex} vpcmpnequb %zmm31, %zmm20, %k6{%k7}
    {evex} vpcmpnequb 0(%rcx), %zmm12, %k1{%k2}
    {evex} vpcmpnequb 128(%r8), %zmm17, %k3{%k4}
    {evex} vpcmpnequb -129(%rbp), %zmm16, %k5{%k6}
    {evex} vpcmpnequb 0(%r12), %zmm3, %k7{%k1}
    {evex} vpcmpnequb -8192(%rsp), %zmm25, %k2{%k3}
    {evex} vpcmpnequb 1001(%r12), %zmm9, %k4{%k5}
    {evex} vpcmpnequb 0(%r9,%r15,2), %zmm31, %k6{%k7}
    {evex} vpcmpnequb 8128(%rsp,%rsi,4), %zmm20, %k1{%k2}
    {evex} vpcmpnequb -2147483648(%r13,%rcx,8), %zmm12, %k3{%k4}
    {evex} vpcmpnequb gnu_fwd(%rip), %zmm17, %k5{%k6}
    {evex} vpcmpnltub %xmm16, %xmm3, %k7
    {evex} vpcmpnltub 0(%r8), %xmm25, %k1
    {evex} vpcmpnltub -16(%r13), %xmm9, %k2
    {evex} vpcmpnltub 2147483647(%rdx), %xmm31, %k3
    {evex} vpcmpnltub 0(%rsp), %xmm20, %k4
    {evex} vpcmpnltub 32(%r12), %xmm12, %k5
    {evex} vpcmpnltub 4660(%rsp), %xmm17, %k6
    {evex} vpcmpnltub 0(%rsp,%r9,1), %xmm16, %k7
    {evex} vpcmpnltub -2048(%rbp,%rbp,2), %xmm3, %k1
    {evex} vpcmpnltub -129(%r12,%r12,4), %xmm25, %k2
    {evex} vpcmpnltub gnu_back(%rip), %xmm9, %k3
    {evex} vpcmpnltub %xmm31, %xmm20, %k4{%k5}
    {evex} vpcmpnltub 0(%rdx), %xmm12, %k6{%k7}
g67:
    {evex} vpcmpnltub 2032(%r9), %xmm17, %k1{%k2}
    {evex} vpcmpnltub 1001(%rbx), %xmm16, %k3{%k4}
    {evex} vpcmpnltub 0(%r12), %xmm3, %k5{%k6}
    {evex} vpcmpnltub -16(%rsp), %xmm25, %k7{%k1}
    {evex} vpcmpnltub -2147483648(%r12), %xmm9, %k2{%k3}
    {evex} vpcmpnltub 0(%r14,%rax,8), %xmm31, %k4{%k5}
    {evex} vpcmpnltub 32(%rdi,%r15,1), %xmm20, %k6{%k7}
    {evex} vpcmpnltub 2147483647(%r15,%rsi,2), %xmm12, %k1{%k2}
    {evex} vpcmpnltub gnu_fwd(%rip), %xmm17, %k3{%k4}
    {evex} vpcmpnltub %ymm16, %ymm3, %k5
    {evex} vpcmpnltub 0(%r9), %ymm25, %k6
    {evex} vpcmpnltub -32(%r10), %ymm9, %k7
    {evex} vpcmpnltub 4660(%rsi), %ymm31, %k1
    {evex} vpcmpnltub 0(%rsp), %ymm20, %k2
    {evex} vpcmpnltub 64(%r12), %ymm12, %k3
    {evex} vpcmpnltub -129(%rsp), %ymm17, %k4
    {evex} vpcmpnltub 0(%rsi,%rcx,4), %ymm16, %k5
    {evex} vpcmpnltub -4096(%rax,%r9,8), %ymm3, %k6
    {evex} vpcmpnltub 1001(%r9,%rbp,1), %ymm25, %k7
    {evex} vpcmpnltub gnu_back(%rip), %ymm9, %k1
    {evex} vpcmpnltub %ymm31, %ymm20, %k2{%k3}
    {evex} vpcmpnltub 0(%rbx), %ymm12, %k4{%k5}
    {evex} vpcmpnltub 4064(%r11), %ymm17, %k6{%k7}
    {evex} vpcmpnltub -2147483648(%rdi), %ymm16, %k1{%k2}
    {evex} vpcmpnltub 0(%r12), %ymm3, %k3{%k4}
    {evex} vpcmpnltub -32(%rsp), %ymm25, %k5{%k6}
    {evex} vpcmpnltub 2147483647(%r12), %ymm9, %k7{%k1}
    {evex} vpcmpnltub 0(%r15,%r12,2), %ymm31, %k2{%k3}
    {evex} vpcmpnltub 64(%rsp,%rax,4), %ymm20, %k4{%k5}
    {evex} vpcmpnltub 4660(%r13,%r15,8), %ymm12, %k6{%k7}
    {evex} vpcmpnltub gnu_fwd(%rip), %ymm17, %k1{%k2}
    {evex} vpcmpnltub %zmm16, %zmm3, %k3
    {evex} vpcmpnltub 0(%r10), %zmm25, %k4
    {evex} vpcmpnltub -64(%r14), %zmm9, %k5
    {evex} vpcmpnltub -129(%r15), %zmm31, %k6
    {evex} vpcmpnltub 0(%rsp), %zmm20, %k7
    {evex} vpcmpnltub 128(%r12), %zmm12, %k1
    {evex} vpcmpnltub 1001(%rsp), %zmm17, %k2
    {evex} vpcmpnltub 0(%rax,%rsi,1), %zmm16, %k3
    {evex} vpcmpnltub -8192(%rbp,%rcx,2), %zmm3, %k4
    {evex} vpcmpnltub -2147483648(%r12,%r9,4), %zmm25, %k5
    {evex} vpcmpnltub gnu_back(%rip), %zmm9, %k6
    {evex} vpcmpnltub %zmm31, %zmm20, %k7{%k1}
    {evex} vpcmpnltub 0(%rsi), %zmm12, %k2{%k3}
    {evex} vpcmpnltub 8128(%rcx), %zmm17, %k4{%k5}
    {evex} vpcmpnltub 2147483647(%r8), %zmm16, %k6{%k7}
    {evex} vpcmpnltub 0(%r12), %zmm3, %k1{%k2}
    {evex} vpcmpnltub -64(%rsp), %zmm25, %k3{%k4}
    {evex} vpcmpnltub 4660(%r12), %zmm9, %k5{%k6}
    {evex} vpcmpnltub 0(%r8,%rbp,8), %zmm31, %k7{%k1}
    {evex} vpcmpnltub 128(%rdi,%r12,1), %zmm20, %k2{%k3}
    {evex} vpcmpnltub -129(%r15,%rax,2), %zmm12, %k4{%k5}
    {evex} vpcmpnltub gnu_fwd(%rip), %zmm17, %k6{%k7}
    {evex} vpcmpnleub %xmm16, %xmm3, %k1
    {evex} vpcmpnleub 0(%r11), %xmm25, %k2
    {evex} vpcmpnleub -2048(%rbp), %xmm9, %k3
    {evex} vpcmpnleub 1001(%r13), %xmm31, %k4
    {evex} vpcmpnleub 0(%rsp), %xmm20, %k5
    {evex} vpcmpnleub 2032(%r12), %xmm12, %k6
    {evex} vpcmpnleub -2147483648(%rsp), %xmm17, %k7
    {evex} vpcmpnleub 0(%rcx,%r15,4), %xmm16, %k1
    {evex} vpcmpnleub -16(%rax,%rsi,8), %xmm3, %k2
    {evex} vpcmpnleub 2147483647(%r9,%rcx,1), %xmm25, %k3
    {evex} vpcmpnleub gnu_back(%rip), %xmm9, %k4
    {evex} vpcmpnleub %xmm31, %xmm20, %k5{%k6}
    {evex} vpcmpnleub 0(%rdi), %xmm12, %k7{%k1}
    {evex} vpcmpnleub 32(%rdx), %xmm17, %k2{%k3}
    {evex} vpcmpnleub 4660(%r9), %xmm16, %k4{%k5}
    {evex} vpcmpnleub 0(%r12), %xmm3, %k6{%k7}
    {evex} vpcmpnleub -2048(%rsp), %xmm25, %k1{%k2}
    {evex} vpcmpnleub -129(%r12), %xmm9, %k3{%k4}
    {evex} vpcmpnleub 0(%r12,%r9,2), %xmm31, %k5{%k6}
    {evex} vpcmpnleub 2032(%rsp,%rbp,4), %xmm20, %k7{%k1}
    {evex} vpcmpnleub 1001(%r13,%r12,8), %xmm12, %k2{%k3}
    {evex} vpcmpnleub gnu_fwd(%rip), %xmm17, %k4{%k5}
    {evex} vpcmpnleub %ymm16, %ymm3, %k6
    {evex} vpcmpnleub 0(%r14), %ymm25, %k7
    {evex} vpcmpnleub -4096(%rbx), %ymm9, %k1
    {evex} vpcmpnleub -2147483648(%r10), %ymm31, %k2
    {evex} vpcmpnleub 0(%rsp), %ymm20, %k3
    {evex} vpcmpnleub 4064(%r12), %ymm12, %k4
    {evex} vpcmpnleub 2147483647(%rsp), %ymm17, %k5
    {evex} vpcmpnleub 0(%rdx,%rax,1), %ymm16, %k6
    {evex} vpcmpnleub -32(%rbp,%r15,2), %ymm3, %k7
    {evex} vpcmpnleub 4660(%r12,%rsi,4), %ymm25, %k1
    {evex} vpcmpnleub gnu_back(%rip), %ymm9, %k2
    {evex} vpcmpnleub %ymm31, %ymm20, %k3{%k4}
    {evex} vpcmpnleub 0(%r15), %ymm12, %k5{%k6}
    {evex} vpcmpnleub 64(%rsi), %ymm17, %k7{%k1}
    {evex} vpcmpnleub -129(%r11), %ymm16, %k2{%k3}
    {evex} vpcmpnleub 0(%r12), %ymm3, %k4{%k5}
    {evex} vpcmpnleub -4096(%rsp), %ymm25, %k6{%k7}
    {evex} vpcmpnleub 1001(%r12), %ymm9, %k1{%k2}
    {evex} vpcmpnleub 0(%r9,%rcx,8), %ymm31, %k3{%k4}
    {evex} vpcmpnleub 4064(%rdi,%r9,1), %ymm20, %k5{%k6}
    {evex} vpcmpnleub -2147483648(%r15,%rbp,2), %ymm12, %k7{%k1}
    {evex} vpcmpnleub gnu_fwd(%rip), %ymm17, %k2{%k3}
    {evex} vpcmpnleub %zmm16, %zmm3, %k4
    {evex} vpcmpnleub 0(%rcx), %zmm25, %k5
    {evex} vpcmpnleub -8192(%rdi), %zmm9, %k6
    {evex} vpcmpnleub 2147483647(%r14), %zmm31, %k7
    {evex} vpcmpnleub 0(%rsp), %zmm20, %k1
    {evex} vpcmpnleub 8128(%r12), %zmm12, %k2
    {evex} vpcmpnleub 4660(%rsp), %zmm17, %k3
    {evex} vpcmpnleub 0(%rsp,%r12,4), %zmm16, %k4
    {evex} vpcmpnleub -64(%rax,%rax,8), %zmm3, %k5
    {evex} vpcmpnleub -129(%r9,%r15,1), %zmm25, %k6
    {evex} vpcmpnleub gnu_back(%rip), %zmm9, %k7
    {evex} vpcmpnleub %zmm31, %zmm20, %k1{%k2}
    {evex} vpcmpnleub 0(%r8), %zmm12, %k3{%k4}
    {evex} vpcmpnleub 128(%r15), %zmm17, %k5{%k6}
    {evex} vpcmpnleub 1001(%rcx), %zmm16, %k7{%k1}
    {evex} vpcmpnleub 0(%r12), %zmm3, %k2{%k3}
    {evex} vpcmpnleub -8192(%rsp), %zmm25, %k4{%k5}
    {evex} vpcmpnleub -2147483648(%r12), %zmm9, %k6{%k7}
    {evex} vpcmpnleub 0(%r14,%rsi,2), %zmm31, %k1{%k2}
    {evex} vpcmpnleub 8128(%rsp,%rcx,4), %zmm20, %k3{%k4}
    {evex} vpcmpnleub 2147483647(%r13,%r9,8), %zmm12, %k5{%k6}
    {evex} vpcmpnleub gnu_fwd(%rip), %zmm17, %k7{%k1}
    {evex} vpcmpltd %xmm16, %xmm3, %k2
    {evex} vpcmpltd 0(%rdx), %xmm25, %k3
    {evex} vpcmpltd -16(%r8), %xmm9, %k4
    {evex} vpcmpltd 4660(%rbp), %xmm31, %k5
    {evex} vpcmpltd 0(%rsp), %xmm20, %k6
    {evex} vpcmpltd 32(%r12), %xmm12, %k7
    {evex} vpcmpltd -129(%rsp), %xmm17, %k1
    {evex} vpcmpltd 0(%rsi,%rbp,1), %xmm16, %k2
    {evex} vpcmpltd -2048(%rbp,%r12,2), %xmm3, %k3
    {evex} vpcmpltd 1001(%r12,%rax,4), %xmm25, %k4
    {evex} vpcmpltd gnu_back(%rip), %xmm9, %k5
    {evex} vpcmpltd %xmm31, %xmm20, %k6{%k7}
    {evex} vpcmpltd 0(%r9), %xmm12, %k1{%k2}
    {evex} vpcmpltd 2032(%r13), %xmm17, %k3{%k4}
    {evex} vpcmpltd -2147483648(%rdx), %xmm16, %k5{%k6}
    {evex} vpcmpltd 0(%r12), %xmm3, %k7{%k1}
    {evex} vpcmpltd -16(%rsp), %xmm25, %k2{%k3}
    {evex} vpcmpltd 2147483647(%r12), %xmm9, %k4{%k5}
    {evex} vpcmpltd 0(%r15,%r15,8), %xmm31, %k6{%k7}
    {evex} vpcmpltd 32(%rdi,%rsi,1), %xmm20, %k1{%k2}
    {evex} vpcmpltd 4660(%r15,%rcx,2), %xmm12, %k3{%k4}
    {evex} vpcmpltd gnu_fwd(%rip), %xmm17, %k5{%k6}
    {evex} vpcmpltd %ymm16, %ymm3, %k7
    {evex} vpcmpltd 0(%rbx), %ymm25, %k1
    {evex} vpcmpltd -32(%r9), %ymm9, %k2
    {evex} vpcmpltd -129(%rbx), %ymm31, %k3
    {evex} vpcmpltd 0(%rsp), %ymm20, %k4
    {evex} vpcmpltd 64(%r12), %ymm12, %k5
    {evex} vpcmpltd 1001(%rsp), %ymm17, %k6
    {evex} vpcmpltd 0(%rax,%r9,4), %ymm16, %k7
    {evex} vpcmpltd -4096(%rax,%rbp,8), %ymm3, %k1
    {evex} vpcmpltd -2147483648(%r9,%r12,1), %ymm25, %k2
    {evex} vpcmpltd gnu_back(%rip), %ymm9, %k3
    {evex} vpcmpltd %ymm31, %ymm20, %k4{%k5}
    {evex} vpcmpltd 0(%r10), %ymm12, %k6{%k7}
    {evex} vpcmpltd 4064(%r10), %ymm17, %k1{%k2}
    {evex} vpcmpltd 2147483647(%rsi), %ymm16, %k3{%k4}
    {evex} vpcmpltd 0(%r12), %ymm3, %k5{%k6}
    {evex} vpcmpltd -32(%rsp), %ymm25, %k7{%k1}
    {evex} vpcmpltd 4660(%r12), %ymm9, %k2{%k3}
    {evex} vpcmpltd 0(%r8,%rax,2), %ymm31, %k4{%k5}
    {evex} vpcmpltd 64(%rsp,%r15,4), %ymm20, %k6{%k7}
    {evex} vpcmpltd -129(%r13,%rsi,8), %ymm12, %k1{%k2}
    {evex} vpcmpltd gnu_fwd(%rip), %ymm17, %k3{%k4}
    {evex} vpcmpltd %zmm16, %zmm3, %k5
    {evex} vpcmpltd 0(%rsi), %zmm25, %k6
    {evex} vpcmpltd -64(%r11), %zmm9, %k7
    {evex} vpcmpltd 1001(%rdi), %zmm31, %k1
    {evex} vpcmpltd 0(%rsp), %zmm20, %k2
    {evex} vpcmpltd 128(%r12), %zmm12, %k3
    {evex} vpcmpltd -2147483648(%rsp), %zmm17, %k4
    {evex} vpcmpltd 0(%rcx,%rcx,1), %zmm16, %k5
    {evex} vpcmpltd -8192(%rbp,%r9,2), %zmm3, %k6
    {evex} vpcmpltd 2147483647(%r12,%rbp,4), %zmm25, %k7
    {evex} vpcmpltd gnu_back(%rip), %zmm9, %k1
    {evex} vpcmpltd %zmm31, %zmm20, %k2{%k3}
    {evex} vpcmpltd 0(%r11), %zmm12, %k4{%k5}
    {evex} vpcmpltd 8128(%r14), %zmm17, %k6{%k7}
    {evex} vpcmpltd 4660(%r15), %zmm16, %k1{%k2}
    {evex} vpcmpltd 0(%r12), %zmm3, %k3{%k4}
    {evex} vpcmpltd -64(%rsp), %zmm25, %k5{%k6}
    {evex} vpcmpltd -129(%r12), %zmm9, %k7{%k1}
    {evex} vpcmpltd 0(%r12,%r12,8), %zmm31, %k2{%k3}
    {evex} vpcmpltd 128(%rdi,%rax,1), %zmm20, %k4{%k5}
    {evex} vpcmpltd 1001(%r15,%r15,2), %zmm12, %k6{%k7}
    {evex} vpcmpltd gnu_fwd(%rip), %zmm17, %k1{%k2}
    {evex} vpcmpled %xmm16, %xmm3, %k3
    {evex} vpcmpled 0(%rdi), %xmm25, %k4
    {evex} vpcmpled -2048(%rcx), %xmm9, %k5
    {evex} vpcmpled -2147483648(%r8), %xmm31, %k6
    {evex} vpcmpled 0(%rsp), %xmm20, %k7
    {evex} vpcmpled 2032(%r12), %xmm12, %k1
    {evex} vpcmpled 2147483647(%rsp), %xmm17, %k2
    {evex} vpcmpled 0(%rdx,%rsi,4), %xmm16, %k3
    {evex} vpcmpled -16(%rax,%rcx,8), %xmm3, %k4
    {evex} vpcmpled 4660(%r9,%r9,1), %xmm25, %k5
    {evex} vpcmpled gnu_back(%rip), %xmm9, %k6
    {evex} vpcmpled %xmm31, %xmm20, %k7{%k1}
    {evex} vpcmpled 0(%r14), %xmm12, %k2{%k3}
    {evex} vpcmpled 32(%rbp), %xmm17, %k4{%k5}
    {evex} vpcmpled -129(%r13), %xmm16, %k6{%k7}
g68:
    {evex} vpcmpled 0(%r12), %xmm3, %k1{%k2}
    {evex} vpcmpled -2048(%rsp), %xmm25, %k3{%k4}
    {evex} vpcmpled 1001(%r12), %xmm9, %k5{%k6}
    {evex} vpcmpled 0(%r9,%rbp,2), %xmm31, %k7{%k1}
    {evex} vpcmpled 2032(%rsp,%r12,4), %xmm20, %k2{%k3}
    {evex} vpcmpled -2147483648(%r13,%rax,8), %xmm12, %k4{%k5}
    {evex} vpcmpled gnu_fwd(%rip), %xmm17, %k6{%k7}
    {evex} vpcmpled %ymm16, %ymm3, %k1
    {evex} vpcmpled 0(%r15), %ymm25, %k2
    {evex} vpcmpled -4096(%rdx), %ymm9, %k3
    {evex} vpcmpled 2147483647(%r9), %ymm31, %k4
    {evex} vpcmpled 0(%rsp), %ymm20, %k5
    {evex} vpcmpled 4064(%r12), %ymm12, %k6
    {evex} vpcmpled 4660(%rsp), %ymm17, %k7
    {evex} vpcmpled 0(%rsp,%r15,1), %ymm16, %k1
    {evex} vpcmpled -32(%rbp,%rsi,2), %ymm3, %k2
    {evex} vpcmpled -129(%r12,%rcx,4), %ymm25, %k3
    {evex} vpcmpled gnu_back(%rip), %ymm9, %k4
    {evex} vpcmpled %ymm31, %ymm20, %k5{%k6}
    {evex} vpcmpled 0(%rcx), %ymm12, %k7{%k1}
    {evex} vpcmpled 64(%rbx), %ymm17, %k2{%k3}
    {evex} vpcmpled 1001(%r10), %ymm16, %k4{%k5}
    {evex} vpcmpled 0(%r12), %ymm3, %k6{%k7}
    {evex} vpcmpled -4096(%rsp), %ymm25, %k1{%k2}
    {evex} vpcmpled -2147483648(%r12), %ymm9, %k3{%k4}
    {evex} vpcmpled 0(%r14,%r9,8), %ymm31, %k5{%k6}
    {evex} vpcmpled 4064(%rdi,%rbp,1), %ymm20, %k7{%k1}
    {evex} vpcmpled 2147483647(%r15,%r12,2), %ymm12, %k2{%k3}
    {evex} vpcmpled gnu_fwd(%rip), %ymm17, %k4{%k5}
    {evex} vpcmpled %zmm16, %zmm3, %k6
    {evex} vpcmpled 0(%r8), %zmm25, %k7
    {evex} vpcmpled -8192(%rsi), %zmm9, %k1
    {evex} vpcmpled 4660(%r11), %zmm31, %k2
    {evex} vpcmpled 0(%rsp), %zmm20, %k3
    {evex} vpcmpled 8128(%r12), %zmm12, %k4
    {evex} vpcmpled -129(%rsp), %zmm17, %k5
    {evex} vpcmpled 0(%rsi,%rax,4), %zmm16, %k6
    {evex} vpcmpled -64(%rax,%r15,8), %zmm3, %k7
    {evex} vpcmpled 1001(%r9,%rsi,1), %zmm25, %k1
    {evex} vpcmpled gnu_back(%rip), %zmm9, %k2
    {evex} vpcmpled %zmm31, %zmm20, %k3{%k4}
    {evex} vpcmpled 0(%rdx), %zmm12, %k5{%k6}
    {evex} vpcmpled 128(%rdi), %zmm17, %k7{%k1}
    {evex} vpcmpled -2147483648(%r14), %zmm16, %k2{%k3}
    {evex} vpcmpled 0(%r12), %zmm3, %k4{%k5}
    {evex} vpcmpled -8192(%rsp), %zmm25, %k6{%k7}
    {evex} vpcmpled 2147483647(%r12), %zmm9, %k1{%k2}
    {evex} vpcmpled 0(%r15,%rcx,2), %zmm31, %k3{%k4}
    {evex} vpcmpled 8128(%rsp,%r9,4), %zmm20, %k5{%k6}
    {evex} vpcmpled 4660(%r13,%rbp,8), %zmm12, %k7{%k1}
    {evex} vpcmpled gnu_fwd(%rip), %zmm17, %k2{%k3}
    {evex} vpcmpneqd %xmm16, %xmm3, %k4
    {evex} vpcmpneqd 0(%r9), %xmm25, %k5
    {evex} vpcmpneqd -16(%r15), %xmm9, %k6
    {evex} vpcmpneqd -129(%rcx), %xmm31, %k7
    {evex} vpcmpneqd 0(%rsp), %xmm20, %k1
    {evex} vpcmpneqd 32(%r12), %xmm12, %k2
    {evex} vpcmpneqd 1001(%rsp), %xmm17, %k3
    {evex} vpcmpneqd 0(%rax,%r12,1), %xmm16, %k4
    {evex} vpcmpneqd -2048(%rbp,%rax,2), %xmm3, %k5
    {evex} vpcmpneqd -2147483648(%r12,%r15,4), %xmm25, %k6
    {evex} vpcmpneqd gnu_back(%rip), %xmm9, %k7
    {evex} vpcmpneqd %xmm31, %xmm20, %k1{%k2}
    {evex} vpcmpneqd 0(%rbx), %xmm12, %k3{%k4}
    {evex} vpcmpneqd 2032(%r8), %xmm17, %k5{%k6}
    {evex} vpcmpneqd 2147483647(%rbp), %xmm16, %k7{%k1}
    {evex} vpcmpneqd 0(%r12), %xmm3, %k2{%k3}
    {evex} vpcmpneqd -16(%rsp), %xmm25, %k4{%k5}
    {evex} vpcmpneqd 4660(%r12), %xmm9, %k6{%k7}
    {evex} vpcmpneqd 0(%r8,%rsi,8), %xmm31, %k1{%k2}
    {evex} vpcmpneqd 32(%rdi,%rcx,1), %xmm20, %k3{%k4}
    {evex} vpcmpneqd -129(%r15,%r9,2), %xmm12, %k5{%k6}
    {evex} vpcmpneqd gnu_fwd(%rip), %xmm17, %k7{%k1}
    {evex} vpcmpneqd %ymm16, %ymm3, %k2
    {evex} vpcmpneqd 0(%r10), %ymm25, %k3
    {evex} vpcmpneqd -32(%r13), %ymm9, %k4
    {evex} vpcmpneqd 1001(%rdx), %ymm31, %k5
    {evex} vpcmpneqd 0(%rsp), %ymm20, %k6
    {evex} vpcmpneqd 64(%r12), %ymm12, %k7
    {evex} vpcmpneqd -2147483648(%rsp), %ymm17, %k1
    {evex} vpcmpneqd 0(%rcx,%rbp,4), %ymm16, %k2
    {evex} vpcmpneqd -4096(%rax,%r12,8), %ymm3, %k3
    {evex} vpcmpneqd 2147483647(%r9,%rax,1), %ymm25, %k4
    {evex} vpcmpneqd gnu_back(%rip), %ymm9, %k5
    {evex} vpcmpneqd %ymm31, %ymm20, %k6{%k7}
    {evex} vpcmpneqd 0(%rsi), %ymm12, %k1{%k2}
    {evex} vpcmpneqd 4064(%r9), %ymm17, %k3{%k4}
    {evex} vpcmpneqd 4660(%rbx), %ymm16, %k5{%k6}
    {evex} vpcmpneqd 0(%r12), %ymm3, %k7{%k1}
    {evex} vpcmpneqd -32(%rsp), %ymm25, %k2{%k3}
    {evex} vpcmpneqd -129(%r12), %ymm9, %k4{%k5}
    {evex} vpcmpneqd 0(%r12,%r15,2), %ymm31, %k6{%k7}
    {evex} vpcmpneqd 64(%rsp,%rsi,4), %ymm20, %k1{%k2}
    {evex} vpcmpneqd 1001(%r13,%rcx,8), %ymm12, %k3{%k4}
    {evex} vpcmpneqd gnu_fwd(%rip), %ymm17, %k5{%k6}
    {evex} vpcmpneqd %zmm16, %zmm3, %k7
    {evex} vpcmpneqd 0(%r11), %zmm25, %k1
    {evex} vpcmpneqd -64(%r10), %zmm9, %k2
    {evex} vpcmpneqd -2147483648(%rsi), %zmm31, %k3
    {evex} vpcmpneqd 0(%rsp), %zmm20, %k4
    {evex} vpcmpneqd 128(%r12), %zmm12, %k5
    {evex} vpcmpneqd 2147483647(%rsp), %zmm17, %k6
    {evex} vpcmpneqd 0(%rdx,%r9,1), %zmm16, %k7
    {evex} vpcmpneqd -8192(%rbp,%rbp,2), %zmm3, %k1
    {evex} vpcmpneqd 4660(%r12,%r12,4), %zmm25, %k2
    {evex} vpcmpneqd gnu_back(%rip), %zmm9, %k3
    {evex} vpcmpneqd %zmm31, %zmm20, %k4{%k5}
    {evex} vpcmpneqd 0(%rdi), %zmm12, %k6{%k7}
    {evex} vpcmpneqd 8128(%r11), %zmm17, %k1{%k2}
    {evex} vpcmpneqd -129(%rdi), %zmm16, %k3{%k4}
    {evex} vpcmpneqd 0(%r12), %zmm3, %k5{%k6}
    {evex} vpcmpneqd -64(%rsp), %zmm25, %k7{%k1}
    {evex} vpcmpneqd 1001(%r12), %zmm9, %k2{%k3}
    {evex} vpcmpneqd 0(%r9,%rax,8), %zmm31, %k4{%k5}
    {evex} vpcmpneqd 128(%rdi,%r15,1), %zmm20, %k6{%k7}
    {evex} vpcmpneqd -2147483648(%r15,%rsi,2), %zmm12, %k1{%k2}
    {evex} vpcmpneqd gnu_fwd(%rip), %zmm17, %k3{%k4}
    {evex} vpcmpnltd %xmm16, %xmm3, %k5
    {evex} vpcmpnltd 0(%r14), %xmm25, %k6
    {evex} vpcmpnltd -2048(%r14), %xmm9, %k7
    {evex} vpcmpnltd 2147483647(%r15), %xmm31, %k1
    {evex} vpcmpnltd 0(%rsp), %xmm20, %k2
    {evex} vpcmpnltd 2032(%r12), %xmm12, %k3
    {evex} vpcmpnltd 4660(%rsp), %xmm17, %k4
    {evex} vpcmpnltd 0(%rsp,%rcx,4), %xmm16, %k5
    {evex} vpcmpnltd -16(%rax,%r9,8), %xmm3, %k6
    {evex} vpcmpnltd -129(%r9,%rbp,1), %xmm25, %k7
    {evex} vpcmpnltd gnu_back(%rip), %xmm9, %k1
    {evex} vpcmpnltd %xmm31, %xmm20, %k2{%k3}
    {evex} vpcmpnltd 0(%r15), %xmm12, %k4{%k5}
    {evex} vpcmpnltd 32(%rcx), %xmm17, %k6{%k7}
    {evex} vpcmpnltd 1001(%r8), %xmm16, %k1{%k2}
    {evex} vpcmpnltd 0(%r12), %xmm3, %k3{%k4}
    {evex} vpcmpnltd -2048(%rsp), %xmm25, %k5{%k6}
    {evex} vpcmpnltd -2147483648(%r12), %xmm9, %k7{%k1}
    {evex} vpcmpnltd 0(%r14,%r12,2), %xmm31, %k2{%k3}
    {evex} vpcmpnltd 2032(%rsp,%rax,4), %xmm20, %k4{%k5}
    {evex} vpcmpnltd 2147483647(%r13,%r15,8), %xmm12, %k6{%k7}
    {evex} vpcmpnltd gnu_fwd(%rip), %xmm17, %k1{%k2}
    {evex} vpcmpnltd %ymm16, %ymm3, %k3
    {evex} vpcmpnltd 0(%rcx), %ymm25, %k4
    {evex} vpcmpnltd -4096(%rbp), %ymm9, %k5
    {evex} vpcmpnltd 4660(%r13), %ymm31, %k6
    {evex} vpcmpnltd 0(%rsp), %ymm20, %k7
    {evex} vpcmpnltd 4064(%r12), %ymm12, %k1
    {evex} vpcmpnltd -129(%rsp), %ymm17, %k2
    {evex} vpcmpnltd 0(%rsi,%rsi,1), %ymm16, %k3
    {evex} vpcmpnltd -32(%rbp,%rcx,2), %ymm3, %k4
    {evex} vpcmpnltd 1001(%r12,%r9,4), %ymm25, %k5
    {evex} vpcmpnltd gnu_back(%rip), %ymm9, %k6
    {evex} vpcmpnltd %ymm31, %ymm20, %k7{%k1}
    {evex} vpcmpnltd 0(%r8), %ymm12, %k2{%k3}
    {evex} vpcmpnltd 64(%rdx), %ymm17, %k4{%k5}
    {evex} vpcmpnltd -2147483648(%r9), %ymm16, %k6{%k7}
    {evex} vpcmpnltd 0(%r12), %ymm3, %k1{%k2}
    {evex} vpcmpnltd -4096(%rsp), %ymm25, %k3{%k4}
    {evex} vpcmpnltd 2147483647(%r12), %ymm9, %k5{%k6}
    {evex} vpcmpnltd 0(%r15,%rbp,8), %ymm31, %k7{%k1}
    {evex} vpcmpnltd 4064(%rdi,%r12,1), %ymm20, %k2{%k3}
    {evex} vpcmpnltd 4660(%r15,%rax,2), %ymm12, %k4{%k5}
    {evex} vpcmpnltd gnu_fwd(%rip), %ymm17, %k6{%k7}
    {evex} vpcmpnltd %zmm16, %zmm3, %k1
    {evex} vpcmpnltd 0(%rdx), %zmm25, %k2
    {evex} vpcmpnltd -8192(%rbx), %zmm9, %k3
    {evex} vpcmpnltd -129(%r10), %zmm31, %k4
    {evex} vpcmpnltd 0(%rsp), %zmm20, %k5
    {evex} vpcmpnltd 8128(%r12), %zmm12, %k6
    {evex} vpcmpnltd 1001(%rsp), %zmm17, %k7
    {evex} vpcmpnltd 0(%rax,%r15,4), %zmm16, %k1
    {evex} vpcmpnltd -64(%rax,%rsi,8), %zmm3, %k2
    {evex} vpcmpnltd -2147483648(%r9,%rcx,1), %zmm25, %k3
    {evex} vpcmpnltd gnu_back(%rip), %zmm9, %k4
    {evex} vpcmpnltd %zmm31, %zmm20, %k5{%k6}
    {evex} vpcmpnltd 0(%r9), %zmm12, %k7{%k1}
    {evex} vpcmpnltd 128(%rsi), %zmm17, %k2{%k3}
    {evex} vpcmpnltd 2147483647(%r11), %zmm16, %k4{%k5}
    {evex} vpcmpnltd 0(%r12), %zmm3, %k6{%k7}
    {evex} vpcmpnltd -8192(%rsp), %zmm25, %k1{%k2}
    {evex} vpcmpnltd 4660(%r12), %zmm9, %k3{%k4}
    {evex} vpcmpnltd 0(%r8,%r9,2), %zmm31, %k5{%k6}
    {evex} vpcmpnltd 8128(%rsp,%rbp,4), %zmm20, %k7{%k1}
    {evex} vpcmpnltd -129(%r13,%r12,8), %zmm12, %k2{%k3}
    {evex} vpcmpnltd gnu_fwd(%rip), %zmm17, %k4{%k5}
    {evex} vpcmpnled %xmm16, %xmm3, %k6
    {evex} vpcmpnled 0(%rbx), %xmm25, %k7
    {evex} vpcmpnled -16(%rdi), %xmm9, %k1
    {evex} vpcmpnled 1001(%r14), %xmm31, %k2
    {evex} vpcmpnled 0(%rsp), %xmm20, %k3
    {evex} vpcmpnled 32(%r12), %xmm12, %k4
    {evex} vpcmpnled -2147483648(%rsp), %xmm17, %k5
    {evex} vpcmpnled 0(%rcx,%rax,1), %xmm16, %k6
    {evex} vpcmpnled -2048(%rbp,%r15,2), %xmm3, %k7
    {evex} vpcmpnled 2147483647(%r12,%rsi,4), %xmm25, %k1
    {evex} vpcmpnled gnu_back(%rip), %xmm9, %k2
    {evex} vpcmpnled %xmm31, %xmm20, %k3{%k4}
    {evex} vpcmpnled 0(%r10), %xmm12, %k5{%k6}
    {evex} vpcmpnled 2032(%r15), %xmm17, %k7{%k1}
    {evex} vpcmpnled 4660(%rcx), %xmm16, %k2{%k3}
    {evex} vpcmpnled 0(%r12), %xmm3, %k4{%k5}
    {evex} vpcmpnled -16(%rsp), %xmm25, %k6{%k7}
g69:
    {evex} vpcmpnled -129(%r12), %xmm9, %k1{%k2}
    {evex} vpcmpnled 0(%r12,%rcx,8), %xmm31, %k3{%k4}
    {evex} vpcmpnled 32(%rdi,%r9,1), %xmm20, %k5{%k6}
    {evex} vpcmpnled 1001(%r15,%rbp,2), %xmm12, %k7{%k1}
    {evex} vpcmpnled gnu_fwd(%rip), %xmm17, %k2{%k3}
    {evex} vpcmpnled %ymm16, %ymm3, %k4
    {evex} vpcmpnled 0(%rsi), %ymm25, %k5
    {evex} vpcmpnled -32(%r8), %ymm9, %k6
    {evex} vpcmpnled -2147483648(%rbp), %ymm31, %k7
    {evex} vpcmpnled 0(%rsp), %ymm20, %k1
    {evex} vpcmpnled 64(%r12), %ymm12, %k2
    {evex} vpcmpnled 2147483647(%rsp), %ymm17, %k3
    {evex} vpcmpnled 0(%rdx,%r12,4), %ymm16, %k4
    {evex} vpcmpnled -4096(%rax,%rax,8), %ymm3, %k5
    {evex} vpcmpnled 4660(%r9,%r15,1), %ymm25, %k6
    {evex} vpcmpnled gnu_back(%rip), %ymm9, %k7
    {evex} vpcmpnled %ymm31, %ymm20, %k1{%k2}
    {evex} vpcmpnled 0(%r11), %ymm12, %k3{%k4}
    {evex} vpcmpnled 4064(%r13), %ymm17, %k5{%k6}
    {evex} vpcmpnled -129(%rdx), %ymm16, %k7{%k1}
    {evex} vpcmpnled 0(%r12), %ymm3, %k2{%k3}
    {evex} vpcmpnled -32(%rsp), %ymm25, %k4{%k5}
    {evex} vpcmpnled 1001(%r12), %ymm9, %k6{%k7}
    {evex} vpcmpnled 0(%r9,%rsi,2), %ymm31, %k1{%k2}
    {evex} vpcmpnled 64(%rsp,%rcx,4), %ymm20, %k3{%k4}
    {evex} vpcmpnled -2147483648(%r13,%r9,8), %ymm12, %k5{%k6}
    {evex} vpcmpnled gnu_fwd(%rip), %ymm17, %k7{%k1}
    {evex} vpcmpnled %zmm16, %zmm3, %k2
    {evex} vpcmpnled 0(%rdi), %zmm25, %k3
    {evex} vpcmpnled -64(%r9), %zmm9, %k4
    {evex} vpcmpnled 2147483647(%rbx), %zmm31, %k5
    {evex} vpcmpnled 0(%rsp), %zmm20, %k6
    {evex} vpcmpnled 128(%r12), %zmm12, %k7
    {evex} vpcmpnled 4660(%rsp), %zmm17, %k1
    {evex} vpcmpnled 0(%rsp,%rbp,1), %zmm16, %k2
    {evex} vpcmpnled -8192(%rbp,%r12,2), %zmm3, %k3
    {evex} vpcmpnled -129(%r12,%rax,4), %zmm25, %k4
    {evex} vpcmpnled gnu_back(%rip), %zmm9, %k5
    {evex} vpcmpnled %zmm31, %zmm20, %k6{%k7}
    {evex} vpcmpnled 0(%r14), %zmm12, %k1{%k2}
    {evex} vpcmpnled 8128(%r10), %zmm17, %k3{%k4}
    {evex} vpcmpnled 1001(%rsi), %zmm16, %k5{%k6}
    {evex} vpcmpnled 0(%r12), %zmm3, %k7{%k1}
    {evex} vpcmpnled -64(%rsp), %zmm25, %k2{%k3}
    {evex} vpcmpnled -2147483648(%r12), %zmm9, %k4{%k5}
    {evex} vpcmpnled 0(%r14,%r15,8), %zmm31, %k6{%k7}
    {evex} vpcmpnled 128(%rdi,%rsi,1), %zmm20, %k1{%k2}
    {evex} vpcmpnled 2147483647(%r15,%rcx,2), %zmm12, %k3{%k4}
    {evex} vpcmpnled gnu_fwd(%rip), %zmm17, %k5{%k6}
    {evex} vpcmpequd %xmm16, %xmm3, %k7
    {evex} vpcmpequd 0(%r15), %xmm25, %k1
    {evex} vpcmpequd -2048(%r11), %xmm9, %k2
    {evex} vpcmpequd 4660(%rdi), %xmm31, %k3
    {evex} vpcmpequd 0(%rsp), %xmm20, %k4
    {evex} vpcmpequd 2032(%r12), %xmm12, %k5
    {evex} vpcmpequd -129(%rsp), %xmm17, %k6
    {evex} vpcmpequd 0(%rsi,%r9,4), %xmm16, %k7
    {evex} vpcmpequd -16(%rax,%rbp,8), %xmm3, %k1
    {evex} vpcmpequd 1001(%r9,%r12,1), %xmm25, %k2
    {evex} vpcmpequd gnu_back(%rip), %xmm9, %k3
    {evex} vpcmpequd %xmm31, %xmm20, %k4{%k5}
    {evex} vpcmpequd 0(%rcx), %xmm12, %k6{%k7}
    {evex} vpcmpequd 32(%r14), %xmm17, %k1{%k2}
    {evex} vpcmpequd -2147483648(%r15), %xmm16, %k3{%k4}
    {evex} vpcmpequd 0(%r12), %xmm3, %k5{%k6}
    {evex} vpcmpequd -2048(%rsp), %xmm25, %k7{%k1}
    {evex} vpcmpequd 2147483647(%r12), %xmm9, %k2{%k3}
    {evex} vpcmpequd 0(%r15,%rax,2), %xmm31, %k4{%k5}
    {evex} vpcmpequd 2032(%rsp,%r15,4), %xmm20, %k6{%k7}
    {evex} vpcmpequd 4660(%r13,%rsi,8), %xmm12, %k1{%k2}
    {evex} vpcmpequd gnu_fwd(%rip), %xmm17, %k3{%k4}
    {evex} vpcmpequd %ymm16, %ymm3, %k5
    {evex} vpcmpequd 0(%r8), %ymm25, %k6
    {evex} vpcmpequd -4096(%rcx), %ymm9, %k7
    {evex} vpcmpequd -129(%r8), %ymm31, %k1
    {evex} vpcmpequd 0(%rsp), %ymm20, %k2
    {evex} vpcmpequd 4064(%r12), %ymm12, %k3
    {evex} vpcmpequd 1001(%rsp), %ymm17, %k4
    {evex} vpcmpequd 0(%rax,%rcx,1), %ymm16, %k5
    {evex} vpcmpequd -32(%rbp,%r9,2), %ymm3, %k6
    {evex} vpcmpequd -2147483648(%r12,%rbp,4), %ymm25, %k7
    {evex} vpcmpequd gnu_back(%rip), %ymm9, %k1
    {evex} vpcmpequd %ymm31, %ymm20, %k2{%k3}
    {evex} vpcmpequd 0(%rdx), %ymm12, %k4{%k5}
    {evex} vpcmpequd 64(%rbp), %ymm17, %k6{%k7}
    {evex} vpcmpequd 2147483647(%r13), %ymm16, %k1{%k2}
    {evex} vpcmpequd 0(%r12), %ymm3, %k3{%k4}
    {evex} vpcmpequd -4096(%rsp), %ymm25, %k5{%k6}
    {evex} vpcmpequd 4660(%r12), %ymm9, %k7{%k1}
    {evex} vpcmpequd 0(%r8,%r12,8), %ymm31, %k2{%k3}
    {evex} vpcmpequd 4064(%rdi,%rax,1), %ymm20, %k4{%k5}
    {evex} vpcmpequd -129(%r15,%r15,2), %ymm12, %k6{%k7}
    {evex} vpcmpequd gnu_fwd(%rip), %ymm17, %k1{%k2}
    {evex} vpcmpequd %zmm16, %zmm3, %k3
    {evex} vpcmpequd 0(%r9), %zmm25, %k4
    {evex} vpcmpequd -8192(%rdx), %zmm9, %k5
    {evex} vpcmpequd 1001(%r9), %zmm31, %k6
    {evex} vpcmpequd 0(%rsp), %zmm20, %k7
    {evex} vpcmpequd 8128(%r12), %zmm12, %k1
    {evex} vpcmpequd -2147483648(%rsp), %zmm17, %k2
    {evex} vpcmpequd 0(%rcx,%rsi,4), %zmm16, %k3
    {evex} vpcmpequd -64(%rax,%rcx,8), %zmm3, %k4
    {evex} vpcmpequd 2147483647(%r9,%r9,1), %zmm25, %k5
    {evex} vpcmpequd gnu_back(%rip), %zmm9, %k6
    {evex} vpcmpequd %zmm31, %zmm20, %k7{%k1}
    {evex} vpcmpequd 0(%rbx), %zmm12, %k2{%k3}
    {evex} vpcmpequd 128(%rbx), %zmm17, %k4{%k5}
    {evex} vpcmpequd 4660(%r10), %zmm16, %k6{%k7}
    {evex} vpcmpequd 0(%r12), %zmm3, %k1{%k2}
    {evex} vpcmpequd -8192(%rsp), %zmm25, %k3{%k4}
    {evex} vpcmpequd -129(%r12), %zmm9, %k5{%k6}
    {evex} vpcmpequd 0(%r12,%rbp,2), %zmm31, %k7{%k1}
    {evex} vpcmpequd 8128(%rsp,%r12,4), %zmm20, %k2{%k3}
    {evex} vpcmpequd 1001(%r13,%rax,8), %zmm12, %k4{%k5}
    {evex} vpcmpequd gnu_fwd(%rip), %zmm17, %k6{%k7}
    {evex} vpcmpltud %xmm16, %xmm3, %k1
    {evex} vpcmpltud 0(%r10), %xmm25, %k2
    {evex} vpcmpltud -16(%rsi), %xmm9, %k3
    {evex} vpcmpltud -2147483648(%r11), %xmm31, %k4
    {evex} vpcmpltud 0(%rsp), %xmm20, %k5
    {evex} vpcmpltud 32(%r12), %xmm12, %k6
    {evex} vpcmpltud 2147483647(%rsp), %xmm17, %k7
    {evex} vpcmpltud 0(%rdx,%r15,1), %xmm16, %k1
    {evex} vpcmpltud -2048(%rbp,%rsi,2), %xmm3, %k2
    {evex} vpcmpltud 4660(%r12,%rcx,4), %xmm25, %k3
    {evex} vpcmpltud gnu_back(%rip), %xmm9, %k4
    {evex} vpcmpltud %xmm31, %xmm20, %k5{%k6}
    {evex} vpcmpltud 0(%rsi), %xmm12, %k7{%k1}
    {evex} vpcmpltud 2032(%rdi), %xmm17, %k2{%k3}
    {evex} vpcmpltud -129(%r14), %xmm16, %k4{%k5}
    {evex} vpcmpltud 0(%r12), %xmm3, %k6{%k7}
    {evex} vpcmpltud -16(%rsp), %xmm25, %k1{%k2}
    {evex} vpcmpltud 1001(%r12), %xmm9, %k3{%k4}
    {evex} vpcmpltud 0(%r9,%r9,8), %xmm31, %k5{%k6}
    {evex} vpcmpltud 32(%rdi,%rbp,1), %xmm20, %k7{%k1}
    {evex} vpcmpltud -2147483648(%r15,%r12,2), %xmm12, %k2{%k3}
    {evex} vpcmpltud gnu_fwd(%rip), %xmm17, %k4{%k5}
    {evex} vpcmpltud %ymm16, %ymm3, %k6
    {evex} vpcmpltud 0(%r11), %ymm25, %k7
    {evex} vpcmpltud -32(%r15), %ymm9, %k1
    {evex} vpcmpltud 2147483647(%rcx), %ymm31, %k2
    {evex} vpcmpltud 0(%rsp), %ymm20, %k3
    {evex} vpcmpltud 64(%r12), %ymm12, %k4
    {evex} vpcmpltud 4660(%rsp), %ymm17, %k5
    {evex} vpcmpltud 0(%rsp,%rax,4), %ymm16, %k6
    {evex} vpcmpltud -4096(%rax,%r15,8), %ymm3, %k7
    {evex} vpcmpltud -129(%r9,%rsi,1), %ymm25, %k1
    {evex} vpcmpltud gnu_back(%rip), %ymm9, %k2
    {evex} vpcmpltud %ymm31, %ymm20, %k3{%k4}
    {evex} vpcmpltud 0(%rdi), %ymm12, %k5{%k6}
    {evex} vpcmpltud 4064(%r8), %ymm17, %k7{%k1}
    {evex} vpcmpltud 1001(%rbp), %ymm16, %k2{%k3}
    {evex} vpcmpltud 0(%r12), %ymm3, %k4{%k5}
    {evex} vpcmpltud -32(%rsp), %ymm25, %k6{%k7}
    {evex} vpcmpltud -2147483648(%r12), %ymm9, %k1{%k2}
    {evex} vpcmpltud 0(%r14,%rcx,2), %ymm31, %k3{%k4}
    {evex} vpcmpltud 64(%rsp,%r9,4), %ymm20, %k5{%k6}
    {evex} vpcmpltud 2147483647(%r13,%rbp,8), %ymm12, %k7{%k1}
    {evex} vpcmpltud gnu_fwd(%rip), %ymm17, %k2{%k3}
    {evex} vpcmpltud %zmm16, %zmm3, %k4
    {evex} vpcmpltud 0(%r14), %zmm25, %k5
    {evex} vpcmpltud -64(%r13), %zmm9, %k6
    {evex} vpcmpltud 4660(%rdx), %zmm31, %k7
    {evex} vpcmpltud 0(%rsp), %zmm20, %k1
    {evex} vpcmpltud 128(%r12), %zmm12, %k2
    {evex} vpcmpltud -129(%rsp), %zmm17, %k3
    {evex} vpcmpltud 0(%rsi,%r12,1), %zmm16, %k4
    {evex} vpcmpltud -8192(%rbp,%rax,2), %zmm3, %k5
    {evex} vpcmpltud 1001(%r12,%r15,4), %zmm25, %k6
    {evex} vpcmpltud gnu_back(%rip), %zmm9, %k7
    {evex} vpcmpltud %zmm31, %zmm20, %k1{%k2}
    {evex} vpcmpltud 0(%r15), %zmm12, %k3{%k4}
    {evex} vpcmpltud 8128(%r9), %zmm17, %k5{%k6}
    {evex} vpcmpltud -2147483648(%rbx), %zmm16, %k7{%k1}
    {evex} vpcmpltud 0(%r12), %zmm3, %k2{%k3}
    {evex} vpcmpltud -64(%rsp), %zmm25, %k4{%k5}
    {evex} vpcmpltud 2147483647(%r12), %zmm9, %k6{%k7}
    {evex} vpcmpltud 0(%r15,%rsi,8), %zmm31, %k1{%k2}
    {evex} vpcmpltud 128(%rdi,%rcx,1), %zmm20, %k3{%k4}
    {evex} vpcmpltud 4660(%r15,%r9,2), %zmm12, %k5{%k6}
    {evex} vpcmpltud gnu_fwd(%rip), %zmm17, %k7{%k1}
    {evex} vpcmpleud %xmm16, %xmm3, %k2
    {evex} vpcmpleud 0(%rcx), %xmm25, %k3
    {evex} vpcmpleud -2048(%r10), %xmm9, %k4
    {evex} vpcmpleud -129(%rsi), %xmm31, %k5
    {evex} vpcmpleud 0(%rsp), %xmm20, %k6
    {evex} vpcmpleud 2032(%r12), %xmm12, %k7
    {evex} vpcmpleud 1001(%rsp), %xmm17, %k1
    {evex} vpcmpleud 0(%rax,%rbp,4), %xmm16, %k2
    {evex} vpcmpleud -16(%rax,%r12,8), %xmm3, %k3
    {evex} vpcmpleud -2147483648(%r9,%rax,1), %xmm25, %k4
    {evex} vpcmpleud gnu_back(%rip), %xmm9, %k5
    {evex} vpcmpleud %xmm31, %xmm20, %k6{%k7}
    {evex} vpcmpleud 0(%r8), %xmm12, %k1{%k2}
    {evex} vpcmpleud 32(%r11), %xmm17, %k3{%k4}
    {evex} vpcmpleud 2147483647(%rdi), %xmm16, %k5{%k6}
    {evex} vpcmpleud 0(%r12), %xmm3, %k7{%k1}
    {evex} vpcmpleud -2048(%rsp), %xmm25, %k2{%k3}
    {evex} vpcmpleud 4660(%r12), %xmm9, %k4{%k5}
    {evex} vpcmpleud 0(%r8,%r15,2), %xmm31, %k6{%k7}
g70:
    {evex} vpcmpleud 2032(%rsp,%rsi,4), %xmm20, %k1{%k2}
    {evex} vpcmpleud -129(%r13,%rcx,8), %xmm12, %k3{%k4}
    {evex} vpcmpleud gnu_fwd(%rip), %xmm17, %k5{%k6}
    {evex} vpcmpleud %ymm16, %ymm3, %k7
    {evex} vpcmpleud 0(%rdx), %ymm25, %k1
    {evex} vpcmpleud -4096(%r14), %ymm9, %k2
    {evex} vpcmpleud 1001(%r15), %ymm31, %k3
    {evex} vpcmpleud 0(%rsp), %ymm20, %k4
    {evex} vpcmpleud 4064(%r12), %ymm12, %k5
    {evex} vpcmpleud -2147483648(%rsp), %ymm17, %k6
    {evex} vpcmpleud 0(%rcx,%r9,1), %ymm16, %k7
    {evex} vpcmpleud -32(%rbp,%rbp,2), %ymm3, %k1
    {evex} vpcmpleud 2147483647(%r12,%r12,4), %ymm25, %k2
    {evex} vpcmpleud gnu_back(%rip), %ymm9, %k3
    {evex} vpcmpleud %ymm31, %ymm20, %k4{%k5}
    {evex} vpcmpleud 0(%r9), %ymm12, %k6{%k7}
    {evex} vpcmpleud 64(%rcx), %ymm17, %k1{%k2}
    {evex} vpcmpleud 4660(%r8), %ymm16, %k3{%k4}
    {evex} vpcmpleud 0(%r12), %ymm3, %k5{%k6}
    {evex} vpcmpleud -4096(%rsp), %ymm25, %k7{%k1}
    {evex} vpcmpleud -129(%r12), %ymm9, %k2{%k3}
    {evex} vpcmpleud 0(%r12,%rax,8), %ymm31, %k4{%k5}
    {evex} vpcmpleud 4064(%rdi,%r15,1), %ymm20, %k6{%k7}
    {evex} vpcmpleud 1001(%r15,%rsi,2), %ymm12, %k1{%k2}
    {evex} vpcmpleud gnu_fwd(%rip), %ymm17, %k3{%k4}
    {evex} vpcmpleud %zmm16, %zmm3, %k5
    {evex} vpcmpleud 0(%rbx), %zmm25, %k6
    {evex} vpcmpleud -8192(%rbp), %zmm9, %k7
    {evex} vpcmpleud -2147483648(%r13), %zmm31, %k1
    {evex} vpcmpleud 0(%rsp), %zmm20, %k2
    {evex} vpcmpleud 8128(%r12), %zmm12, %k3
    {evex} vpcmpleud 2147483647(%rsp), %zmm17, %k4
    {evex} vpcmpleud 0(%rdx,%rcx,4), %zmm16, %k5
    {evex} vpcmpleud -64(%rax,%r9,8), %zmm3, %k6
    {evex} vpcmpleud 4660(%r9,%rbp,1), %zmm25, %k7
    {evex} vpcmpleud gnu_back(%rip), %zmm9, %k1
    {evex} vpcmpleud %zmm31, %zmm20, %k2{%k3}
    {evex} vpcmpleud 0(%r10), %zmm12, %k4{%k5}
    {evex} vpcmpleud 128(%rdx), %zmm17, %k6{%k7}
    {evex} vpcmpleud -129(%r9), %zmm16, %k1{%k2}
    {evex} vpcmpleud 0(%r12), %zmm3, %k3{%k4}
    {evex} vpcmpleud -8192(%rsp), %zmm25, %k5{%k6}
    {evex} vpcmpleud 1001(%r12), %zmm9, %k7{%k1}
    {evex} vpcmpleud 0(%r9,%r12,2), %zmm31, %k2{%k3}
    {evex} vpcmpleud 8128(%rsp,%rax,4), %zmm20, %k4{%k5}
    {evex} vpcmpleud -2147483648(%r13,%r15,8), %zmm12, %k6{%k7}
    {evex} vpcmpleud gnu_fwd(%rip), %zmm17, %k1{%k2}
    {evex} vpcmpnequd %xmm16, %xmm3, %k3
    {evex} vpcmpnequd 0(%rsi), %xmm25, %k4
    {evex} vpcmpnequd -16(%rbx), %xmm9, %k5
    {evex} vpcmpnequd 2147483647(%r10), %xmm31, %k6
    {evex} vpcmpnequd 0(%rsp), %xmm20, %k7
    {evex} vpcmpnequd 32(%r12), %xmm12, %k1
    {evex} vpcmpnequd 4660(%rsp), %xmm17, %k2
    {evex} vpcmpnequd 0(%rsp,%rsi,1), %xmm16, %k3
    {evex} vpcmpnequd -2048(%rbp,%rcx,2), %xmm3, %k4
    {evex} vpcmpnequd -129(%r12,%r9,4), %xmm25, %k5
    {evex} vpcmpnequd gnu_back(%rip), %xmm9, %k6
    {evex} vpcmpnequd %xmm31, %xmm20, %k7{%k1}
    {evex} vpcmpnequd 0(%r11), %xmm12, %k2{%k3}
    {evex} vpcmpnequd 2032(%rsi), %xmm17, %k4{%k5}
    {evex} vpcmpnequd 1001(%r11), %xmm16, %k6{%k7}
    {evex} vpcmpnequd 0(%r12), %xmm3, %k1{%k2}
    {evex} vpcmpnequd -16(%rsp), %xmm25, %k3{%k4}
    {evex} vpcmpnequd -2147483648(%r12), %xmm9, %k5{%k6}
    {evex} vpcmpnequd 0(%r14,%rbp,8), %xmm31, %k7{%k1}
    {evex} vpcmpnequd 32(%rdi,%r12,1), %xmm20, %k2{%k3}
    {evex} vpcmpnequd 2147483647(%r15,%rax,2), %xmm12, %k4{%k5}
    {evex} vpcmpnequd gnu_fwd(%rip), %xmm17, %k6{%k7}
    {evex} vpcmpnequd %ymm16, %ymm3, %k1
    {evex} vpcmpnequd 0(%rdi), %ymm25, %k2
    {evex} vpcmpnequd -32(%rdi), %ymm9, %k3
    {evex} vpcmpnequd 4660(%r14), %ymm31, %k4
    {evex} vpcmpnequd 0(%rsp), %ymm20, %k5
    {evex} vpcmpnequd 64(%r12), %ymm12, %k6
    {evex} vpcmpnequd -129(%rsp), %ymm17, %k7
    {evex} vpcmpnequd 0(%rsi,%r15,4), %ymm16, %k1
    {evex} vpcmpnequd -4096(%rax,%rsi,8), %ymm3, %k2
    {evex} vpcmpnequd 1001(%r9,%rcx,1), %ymm25, %k3
    {evex} vpcmpnequd gnu_back(%rip), %ymm9, %k4
    {evex} vpcmpnequd %ymm31, %ymm20, %k5{%k6}
    {evex} vpcmpnequd 0(%r14), %ymm12, %k7{%k1}
    {evex} vpcmpnequd 4064(%r15), %ymm17, %k2{%k3}
    {evex} vpcmpnequd -2147483648(%rcx), %ymm16, %k4{%k5}
    {evex} vpcmpnequd 0(%r12), %ymm3, %k6{%k7}
    {evex} vpcmpnequd -32(%rsp), %ymm25, %k1{%k2}
    {evex} vpcmpnequd 2147483647(%r12), %ymm9, %k3{%k4}
    {evex} vpcmpnequd 0(%r15,%r9,2), %ymm31, %k5{%k6}
    {evex} vpcmpnequd 64(%rsp,%rbp,4), %ymm20, %k7{%k1}
    {evex} vpcmpnequd 4660(%r13,%r12,8), %ymm12, %k2{%k3}
    {evex} vpcmpnequd gnu_fwd(%rip), %ymm17, %k4{%k5}
    {evex} vpcmpnequd %zmm16, %zmm3, %k6
    {evex} vpcmpnequd 0(%r15), %zmm25, %k7
    {evex} vpcmpnequd -64(%r8), %zmm9, %k1
    {evex} vpcmpnequd -129(%rbp), %zmm31, %k2
    {evex} vpcmpnequd 0(%rsp), %zmm20, %k3
    {evex} vpcmpnequd 128(%r12), %zmm12, %k4
    {evex} vpcmpnequd 1001(%rsp), %zmm17, %k5
    {evex} vpcmpnequd 0(%rax,%rax,1), %zmm16, %k6
    {evex} vpcmpnequd -8192(%rbp,%r15,2), %zmm3, %k7
    {evex} vpcmpnequd -2147483648(%r12,%rsi,4), %zmm25, %k1
    {evex} vpcmpnequd gnu_back(%rip), %zmm9, %k2
    {evex} vpcmpnequd %zmm31, %zmm20, %k3{%k4}
    {evex} vpcmpnequd 0(%rcx), %zmm12, %k5{%k6}
    {evex} vpcmpnequd 8128(%r13), %zmm17, %k7{%k1}
    {evex} vpcmpnequd 2147483647(%rdx), %zmm16, %k2{%k3}
    {evex} vpcmpnequd 0(%r12), %zmm3, %k4{%k5}
    {evex} vpcmpnequd -64(%rsp), %zmm25, %k6{%k7}
    {evex} vpcmpnequd 4660(%r12), %zmm9, %k1{%k2}
    {evex} vpcmpnequd 0(%r8,%rcx,8), %zmm31, %k3{%k4}
    {evex} vpcmpnequd 128(%rdi,%r9,1), %zmm20, %k5{%k6}
    {evex} vpcmpnequd -129(%r15,%rbp,2), %zmm12, %k7{%k1}
    {evex} vpcmpnequd gnu_fwd(%rip), %zmm17, %k2{%k3}
    {evex} vpcmpnltud %xmm16, %xmm3, %k4
    {evex} vpcmpnltud 0(%r8), %xmm25, %k5
    {evex} vpcmpnltud -2048(%r9), %xmm9, %k6
    {evex} vpcmpnltud 1001(%rbx), %xmm31, %k7
    {evex} vpcmpnltud 0(%rsp), %xmm20, %k1
    {evex} vpcmpnltud 2032(%r12), %xmm12, %k2
    {evex} vpcmpnltud -2147483648(%rsp), %xmm17, %k3
    {evex} vpcmpnltud 0(%rcx,%r12,4), %xmm16, %k4
    {evex} vpcmpnltud -16(%rax,%rax,8), %xmm3, %k5
    {evex} vpcmpnltud 2147483647(%r9,%r15,1), %xmm25, %k6
    {evex} vpcmpnltud gnu_back(%rip), %xmm9, %k7
    {evex} vpcmpnltud %xmm31, %xmm20, %k1{%k2}
    {evex} vpcmpnltud 0(%rdx), %xmm12, %k3{%k4}
    {evex} vpcmpnltud 32(%r10), %xmm17, %k5{%k6}
    {evex} vpcmpnltud 4660(%rsi), %xmm16, %k7{%k1}
    {evex} vpcmpnltud 0(%r12), %xmm3, %k2{%k3}
    {evex} vpcmpnltud -2048(%rsp), %xmm25, %k4{%k5}
    {evex} vpcmpnltud -129(%r12), %xmm9, %k6{%k7}
    {evex} vpcmpnltud 0(%r12,%rsi,2), %xmm31, %k1{%k2}
    {evex} vpcmpnltud 2032(%rsp,%rcx,4), %xmm20, %k3{%k4}
    {evex} vpcmpnltud 1001(%r13,%r9,8), %xmm12, %k5{%k6}
    {evex} vpcmpnltud gnu_fwd(%rip), %xmm17, %k7{%k1}
    {evex} vpcmpnltud %ymm16, %ymm3, %k2
    {evex} vpcmpnltud 0(%r9), %ymm25, %k3
    {evex} vpcmpnltud -4096(%r11), %ymm9, %k4
    {evex} vpcmpnltud -2147483648(%rdi), %ymm31, %k5
    {evex} vpcmpnltud 0(%rsp), %ymm20, %k6
    {evex} vpcmpnltud 4064(%r12), %ymm12, %k7
    {evex} vpcmpnltud 2147483647(%rsp), %ymm17, %k1
    {evex} vpcmpnltud 0(%rdx,%rbp,1), %ymm16, %k2
    {evex} vpcmpnltud -32(%rbp,%r12,2), %ymm3, %k3
    {evex} vpcmpnltud 4660(%r12,%rax,4), %ymm25, %k4
    {evex} vpcmpnltud gnu_back(%rip), %ymm9, %k5
    {evex} vpcmpnltud %ymm31, %ymm20, %k6{%k7}
    {evex} vpcmpnltud 0(%rbx), %ymm12, %k1{%k2}
    {evex} vpcmpnltud 64(%r14), %ymm17, %k3{%k4}
    {evex} vpcmpnltud -129(%r15), %ymm16, %k5{%k6}
    {evex} vpcmpnltud 0(%r12), %ymm3, %k7{%k1}
    {evex} vpcmpnltud -4096(%rsp), %ymm25, %k2{%k3}
    {evex} vpcmpnltud 1001(%r12), %ymm9, %k4{%k5}
    {evex} vpcmpnltud 0(%r9,%r15,8), %ymm31, %k6{%k7}
    {evex} vpcmpnltud 4064(%rdi,%rsi,1), %ymm20, %k1{%k2}
    {evex} vpcmpnltud -2147483648(%r15,%rcx,2), %ymm12, %k3{%k4}
    {evex} vpcmpnltud gnu_fwd(%rip), %ymm17, %k5{%k6}
    {evex} vpcmpnltud %zmm16, %zmm3, %k7
    {evex} vpcmpnltud 0(%r10), %zmm25, %k1
    {evex} vpcmpnltud -8192(%rcx), %zmm9, %k2
    {evex} vpcmpnltud 2147483647(%r8), %zmm31, %k3
    {evex} vpcmpnltud 0(%rsp), %zmm20, %k4
    {evex} vpcmpnltud 8128(%r12), %zmm12, %k5
    {evex} vpcmpnltud 4660(%rsp), %zmm17, %k6
    {evex} vpcmpnltud 0(%rsp,%r9,4), %zmm16, %k7
    {evex} vpcmpnltud -64(%rax,%rbp,8), %zmm3, %k1
    {evex} vpcmpnltud -129(%r9,%r12,1), %zmm25, %k2
    {evex} vpcmpnltud gnu_back(%rip), %zmm9, %k3
    {evex} vpcmpnltud %zmm31, %zmm20, %k4{%k5}
    {evex} vpcmpnltud 0(%rsi), %zmm12, %k6{%k7}
    {evex} vpcmpnltud 128(%rbp), %zmm17, %k1{%k2}
    {evex} vpcmpnltud 1001(%r13), %zmm16, %k3{%k4}
    {evex} vpcmpnltud 0(%r12), %zmm3, %k5{%k6}
    {evex} vpcmpnltud -8192(%rsp), %zmm25, %k7{%k1}
    {evex} vpcmpnltud -2147483648(%r12), %zmm9, %k2{%k3}
    {evex} vpcmpnltud 0(%r14,%rax,2), %zmm31, %k4{%k5}
    {evex} vpcmpnltud 8128(%rsp,%r15,4), %zmm20, %k6{%k7}
    {evex} vpcmpnltud 2147483647(%r13,%rsi,8), %zmm12, %k1{%k2}
    {evex} vpcmpnltud gnu_fwd(%rip), %zmm17, %k3{%k4}
    {evex} vpcmpnleud %xmm16, %xmm3, %k5
    {evex} vpcmpnleud 0(%r11), %xmm25, %k6
    {evex} vpcmpnleud -16(%rdx), %xmm9, %k7
    {evex} vpcmpnleud 4660(%r9), %xmm31, %k1
    {evex} vpcmpnleud 0(%rsp), %xmm20, %k2
    {evex} vpcmpnleud 32(%r12), %xmm12, %k3
    {evex} vpcmpnleud -129(%rsp), %xmm17, %k4
    {evex} vpcmpnleud 0(%rsi,%rcx,1), %xmm16, %k5
    {evex} vpcmpnleud -2048(%rbp,%r9,2), %xmm3, %k6
    {evex} vpcmpnleud 1001(%r12,%rbp,4), %xmm25, %k7
    {evex} vpcmpnleud gnu_back(%rip), %xmm9, %k1
    {evex} vpcmpnleud %xmm31, %xmm20, %k2{%k3}
    {evex} vpcmpnleud 0(%rdi), %xmm12, %k4{%k5}
    {evex} vpcmpnleud 2032(%rbx), %xmm17, %k6{%k7}
    {evex} vpcmpnleud -2147483648(%r10), %xmm16, %k1{%k2}
    {evex} vpcmpnleud 0(%r12), %xmm3, %k3{%k4}
    {evex} vpcmpnleud -16(%rsp), %xmm25, %k5{%k6}
    {evex} vpcmpnleud 2147483647(%r12), %xmm9, %k7{%k1}
    {evex} vpcmpnleud 0(%r15,%r12,8), %xmm31, %k2{%k3}
    {evex} vpcmpnleud 32(%rdi,%rax,1), %xmm20, %k4{%k5}
    {evex} vpcmpnleud 4660(%r15,%r15,2), %xmm12, %k6{%k7}
g71:
    {evex} vpcmpnleud gnu_fwd(%rip), %xmm17, %k1{%k2}
    {evex} vpcmpnleud %ymm16, %ymm3, %k3
    {evex} vpcmpnleud 0(%r14), %ymm25, %k4
    {evex} vpcmpnleud -32(%rsi), %ymm9, %k5
    {evex} vpcmpnleud -129(%r11), %ymm31, %k6
    {evex} vpcmpnleud 0(%rsp), %ymm20, %k7
    {evex} vpcmpnleud 64(%r12), %ymm12, %k1
    {evex} vpcmpnleud 1001(%rsp), %ymm17, %k2
    {evex} vpcmpnleud 0(%rax,%rsi,4), %ymm16, %k3
    {evex} vpcmpnleud -4096(%rax,%rcx,8), %ymm3, %k4
    {evex} vpcmpnleud -2147483648(%r9,%r9,1), %ymm25, %k5
    {evex} vpcmpnleud gnu_back(%rip), %ymm9, %k6
    {evex} vpcmpnleud %ymm31, %ymm20, %k7{%k1}
    {evex} vpcmpnleud 0(%r15), %ymm12, %k2{%k3}
    {evex} vpcmpnleud 4064(%rdi), %ymm17, %k4{%k5}
    {evex} vpcmpnleud 2147483647(%r14), %ymm16, %k6{%k7}
    {evex} vpcmpnleud 0(%r12), %ymm3, %k1{%k2}
    {evex} vpcmpnleud -32(%rsp), %ymm25, %k3{%k4}
    {evex} vpcmpnleud 4660(%r12), %ymm9, %k5{%k6}
    {evex} vpcmpnleud 0(%r8,%rbp,2), %ymm31, %k7{%k1}
    {evex} vpcmpnleud 64(%rsp,%r12,4), %ymm20, %k2{%k3}
    {evex} vpcmpnleud -129(%r13,%rax,8), %ymm12, %k4{%k5}
    {evex} vpcmpnleud gnu_fwd(%rip), %ymm17, %k6{%k7}
    {evex} vpcmpnleud %zmm16, %zmm3, %k1
    {evex} vpcmpnleud 0(%rcx), %zmm25, %k2
    {evex} vpcmpnleud -64(%r15), %zmm9, %k3
    {evex} vpcmpnleud 1001(%rcx), %zmm31, %k4
    {evex} vpcmpnleud 0(%rsp), %zmm20, %k5
    {evex} vpcmpnleud 128(%r12), %zmm12, %k6
    {evex} vpcmpnleud -2147483648(%rsp), %zmm17, %k7
    {evex} vpcmpnleud 0(%rcx,%r15,1), %zmm16, %k1
    {evex} vpcmpnleud -8192(%rbp,%rsi,2), %zmm3, %k2
    {evex} vpcmpnleud 2147483647(%r12,%rcx,4), %zmm25, %k3
    {evex} vpcmpnleud gnu_back(%rip), %zmm9, %k4
    {evex} vpcmpnleud %zmm31, %zmm20, %k5{%k6}
    {evex} vpcmpnleud 0(%r8), %zmm12, %k7{%k1}
    {evex} vpcmpnleud 8128(%r8), %zmm17, %k2{%k3}
    {evex} vpcmpnleud 4660(%rbp), %zmm16, %k4{%k5}
    {evex} vpcmpnleud 0(%r12), %zmm3, %k6{%k7}
    {evex} vpcmpnleud -64(%rsp), %zmm25, %k1{%k2}
    {evex} vpcmpnleud -129(%r12), %zmm9, %k3{%k4}
    {evex} vpcmpnleud 0(%r12,%r9,8), %zmm31, %k5{%k6}
    {evex} vpcmpnleud 128(%rdi,%rbp,1), %zmm20, %k7{%k1}
    {evex} vpcmpnleud 1001(%r15,%r12,2), %zmm12, %k2{%k3}
    {evex} vpcmpnleud gnu_fwd(%rip), %zmm17, %k4{%k5}
    {evex} vpminub %xmm16, %xmm3, %xmm25
    {evex} vpminub 0(%rdx), %xmm9, %xmm31
    {evex} vpminub -2048(%r13), %xmm20, %xmm12
    {evex} vpminub -2147483648(%rdx), %xmm17, %xmm16
    {evex} vpminub 0(%rsp), %xmm3, %xmm25
    {evex} vpminub 2032(%r12), %xmm9, %xmm31
    {evex} vpminub 2147483647(%rsp), %xmm20, %xmm12
    {evex} vpminub 0(%rdx,%rax,4), %xmm17, %xmm16
    {evex} vpminub -16(%rax,%r15,8), %xmm3, %xmm25
    {evex} vpminub 4660(%r9,%rsi,1), %xmm9, %xmm31
    {evex} vpminub gnu_back(%rip), %xmm20, %xmm12
    {evex} vpminub %xmm17, %xmm16, %xmm3{%k6}
    {evex} vpminub 0(%r9), %xmm25, %xmm9{%k7}
    {evex} vpminub 32(%r9), %xmm31, %xmm20{%k1}
    {evex} vpminub -129(%rbx), %xmm12, %xmm17{%k2}
    {evex} vpminub 0(%r12), %xmm16, %xmm3{%k3}
    {evex} vpminub -2048(%rsp), %xmm25, %xmm9{%k4}
    {evex} vpminub 1001(%r12), %xmm31, %xmm20{%k5}
    {evex} vpminub 0(%r9,%rcx,2), %xmm12, %xmm17{%k6}
    {evex} vpminub 2032(%rsp,%r9,4), %xmm16, %xmm3{%k7}
    {evex} vpminub -2147483648(%r13,%rbp,8), %xmm25, %xmm9{%k1}
    {evex} vpminub gnu_fwd(%rip), %xmm31, %xmm20{%k2}
    {evex} vpminub %xmm12, %xmm17, %xmm16{%k3}{z}
    {evex} vpminub 0(%rbx), %xmm3, %xmm25{%k4}{z}
    {evex} vpminub -16(%r10), %xmm9, %xmm31{%k5}{z}
    {evex} vpminub 2147483647(%rsi), %xmm20, %xmm12{%k6}{z}
    {evex} vpminub 0(%rsp), %xmm17, %xmm16{%k7}{z}
    {evex} vpminub 32(%r12), %xmm3, %xmm25{%k1}{z}
    {evex} vpminub 4660(%rsp), %xmm9, %xmm31{%k2}{z}
    {evex} vpminub 0(%rsp,%r12,1), %xmm20, %xmm12{%k3}{z}
    {evex} vpminub -2048(%rbp,%rax,2), %xmm17, %xmm16{%k4}{z}
    {evex} vpminub -129(%r12,%r15,4), %xmm3, %xmm25{%k5}{z}
    {evex} vpminub gnu_back(%rip), %xmm9, %xmm31{%k6}{z}
    {evex} vpminub %ymm20, %ymm12, %ymm17
    {evex} vpminub 0(%r10), %ymm16, %ymm3
    {evex} vpminub -4096(%r11), %ymm25, %ymm9
    {evex} vpminub 1001(%rdi), %ymm31, %ymm20
    {evex} vpminub 0(%r12), %ymm12, %ymm17
    {evex} vpminub 4064(%rsp), %ymm16, %ymm3
    {evex} vpminub -2147483648(%r12), %ymm25, %ymm9
    {evex} vpminub 0(%r14,%rsi,8), %ymm31, %ymm20
    {evex} vpminub -32(%rdi,%rcx,1), %ymm12, %ymm17
    {evex} vpminub 2147483647(%r15,%r9,2), %ymm16, %ymm3
    {evex} vpminub gnu_fwd(%rip), %ymm25, %ymm9
    {evex} vpminub %ymm31, %ymm20, %ymm12{%k7}
    {evex} vpminub 0(%rsi), %ymm17, %ymm16{%k1}
    {evex} vpminub 64(%r14), %ymm3, %ymm25{%k2}
    {evex} vpminub 4660(%r15), %ymm9, %ymm31{%k3}
    {evex} vpminub 0(%rsp), %ymm20, %ymm12{%k4}
    {evex} vpminub -4096(%r12), %ymm17, %ymm16{%k5}
    {evex} vpminub -129(%rsp), %ymm3, %ymm25{%k6}
    {evex} vpminub 0(%rsi,%rbp,4), %ymm9, %ymm31{%k7}
    {evex} vpminub 4064(%rax,%r12,8), %ymm20, %ymm12{%k1}
    {evex} vpminub 1001(%r9,%rax,1), %ymm17, %ymm16{%k2}
    {evex} vpminub gnu_back(%rip), %ymm3, %ymm25{%k3}
    {evex} vpminub %ymm9, %ymm31, %ymm20{%k4}{z}
    {evex} vpminub 0(%r11), %ymm12, %ymm17{%k5}{z}
    {evex} vpminub -32(%rcx), %ymm16, %ymm3{%k6}{z}
    {evex} vpminub -2147483648(%r8), %ymm25, %ymm9{%k7}{z}
    {evex} vpminub 0(%r12), %ymm31, %ymm20{%k1}{z}
    {evex} vpminub 64(%rsp), %ymm12, %ymm17{%k2}{z}
    {evex} vpminub 2147483647(%r12), %ymm16, %ymm3{%k3}{z}
    {evex} vpminub 0(%r15,%r15,2), %ymm25, %ymm9{%k4}{z}
    {evex} vpminub -4096(%rsp,%rsi,4), %ymm31, %ymm20{%k5}{z}
    {evex} vpminub 4660(%r13,%rcx,8), %ymm12, %ymm17{%k6}{z}
    {evex} vpminub gnu_fwd(%rip), %ymm16, %ymm3{%k7}{z}
    {evex} vpminub %zmm25, %zmm9, %zmm31
    {evex} vpminub 0(%rdi), %zmm20, %zmm12
    {evex} vpminub -8192(%rbp), %zmm17, %zmm16
    {evex} vpminub -129(%r13), %zmm3, %zmm25
    {evex} vpminub 0(%rsp), %zmm9, %zmm31
    {evex} vpminub 8128(%r12), %zmm20, %zmm12
    {evex} vpminub 1001(%rsp), %zmm17, %zmm16
    {evex} vpminub 0(%rax,%r9,1), %zmm3, %zmm25
    {evex} vpminub -64(%rbp,%rbp,2), %zmm9, %zmm31
    {evex} vpminub -2147483648(%r12,%r12,4), %zmm20, %zmm12
    {evex} vpminub gnu_back(%rip), %zmm17, %zmm16
    {evex} vpminub %zmm3, %zmm25, %zmm9{%k1}
    {evex} vpminub 0(%r14), %zmm31, %zmm20{%k2}
    {evex} vpminub 128(%rdx), %zmm12, %zmm17{%k3}
    {evex} vpminub 2147483647(%r9), %zmm16, %zmm3{%k4}
    {evex} vpminub 0(%r12), %zmm25, %zmm9{%k5}
    {evex} vpminub -8192(%rsp), %zmm31, %zmm20{%k6}
    {evex} vpminub 4660(%r12), %zmm12, %zmm17{%k7}
    {evex} vpminub 0(%r8,%rax,8), %zmm16, %zmm3{%k1}
    {evex} vpminub 8128(%rdi,%r15,1), %zmm25, %zmm9{%k2}
    {evex} vpminub -129(%r15,%rsi,2), %zmm31, %zmm20{%k3}
    {evex} vpminub gnu_fwd(%rip), %zmm12, %zmm17{%k4}
    {evex} vpminub %zmm16, %zmm3, %zmm25{%k5}{z}
    {evex} vpminub 0(%r15), %zmm9, %zmm31{%k6}{z}
    {evex} vpminub -64(%rbx), %zmm20, %zmm12{%k7}{z}
    {evex} vpminub 1001(%r10), %zmm17, %zmm16{%k1}{z}
    {evex} vpminub 0(%rsp), %zmm3, %zmm25{%k2}{z}
    {evex} vpminub 128(%r12), %zmm9, %zmm31{%k3}{z}
    {evex} vpminub -2147483648(%rsp), %zmm20, %zmm12{%k4}{z}
    {evex} vpminub 0(%rcx,%rcx,4), %zmm17, %zmm16{%k5}{z}
    {evex} vpminub -8192(%rax,%r9,8), %zmm3, %zmm25{%k6}{z}
    {evex} vpminub 2147483647(%r9,%rbp,1), %zmm9, %zmm31{%k7}{z}
    {evex} vpminub gnu_back(%rip), %zmm20, %zmm12{%k1}{z}
    {evex} vpmaxub %xmm17, %xmm16, %xmm3
    {evex} vpmaxub 0(%rcx), %xmm25, %xmm9
    {evex} vpmaxub 2032(%rsi), %xmm31, %xmm20
    {evex} vpmaxub 4660(%r11), %xmm12, %xmm17
    {evex} vpmaxub 0(%r12), %xmm16, %xmm3
    {evex} vpmaxub -16(%rsp), %xmm25, %xmm9
    {evex} vpmaxub -129(%r12), %xmm31, %xmm20
    {evex} vpmaxub 0(%r12,%r12,2), %xmm12, %xmm17
    {evex} vpmaxub 32(%rsp,%rax,4), %xmm16, %xmm3
    {evex} vpmaxub 1001(%r13,%r15,8), %xmm25, %xmm9
    {evex} vpmaxub gnu_fwd(%rip), %xmm31, %xmm20
    {evex} vpmaxub %xmm12, %xmm17, %xmm16{%k2}
    {evex} vpmaxub 0(%r8), %xmm3, %xmm25{%k3}
    {evex} vpmaxub -2048(%rdi), %xmm9, %xmm31{%k4}
    {evex} vpmaxub -2147483648(%r14), %xmm20, %xmm12{%k5}
    {evex} vpmaxub 0(%rsp), %xmm17, %xmm16{%k6}
    {evex} vpmaxub 2032(%r12), %xmm3, %xmm25{%k7}
    {evex} vpmaxub 2147483647(%rsp), %xmm9, %xmm31{%k1}
    {evex} vpmaxub 0(%rdx,%rsi,1), %xmm20, %xmm12{%k2}
    {evex} vpmaxub -16(%rbp,%rcx,2), %xmm17, %xmm16{%k3}
    {evex} vpmaxub 4660(%r12,%r9,4), %xmm3, %xmm25{%k4}
    {evex} vpmaxub gnu_back(%rip), %xmm9, %xmm31{%k5}
    {evex} vpmaxub %xmm20, %xmm12, %xmm17{%k6}{z}
    {evex} vpmaxub 0(%rdx), %xmm16, %xmm3{%k7}{z}
    {evex} vpmaxub 32(%r15), %xmm25, %xmm9{%k1}{z}
    {evex} vpmaxub -129(%rcx), %xmm31, %xmm20{%k2}{z}
    {evex} vpmaxub 0(%r12), %xmm12, %xmm17{%k3}{z}
    {evex} vpmaxub -2048(%rsp), %xmm16, %xmm3{%k4}{z}
    {evex} vpmaxub 1001(%r12), %xmm25, %xmm9{%k5}{z}
    {evex} vpmaxub 0(%r9,%rbp,8), %xmm31, %xmm20{%k6}{z}
    {evex} vpmaxub 2032(%rdi,%r12,1), %xmm12, %xmm17{%k7}{z}
    {evex} vpmaxub -2147483648(%r15,%rax,2), %xmm16, %xmm3{%k1}{z}
    {evex} vpmaxub gnu_fwd(%rip), %xmm25, %xmm9{%k2}{z}
    {evex} vpmaxub %ymm31, %ymm20, %ymm12
    {evex} vpmaxub 0(%r9), %ymm17, %ymm16
    {evex} vpmaxub 4064(%r8), %ymm3, %ymm25
    {evex} vpmaxub 2147483647(%rbp), %ymm9, %ymm31
    {evex} vpmaxub 0(%rsp), %ymm20, %ymm12
    {evex} vpmaxub -32(%r12), %ymm17, %ymm16
    {evex} vpmaxub 4660(%rsp), %ymm3, %ymm25
    {evex} vpmaxub 0(%rsp,%r15,4), %ymm9, %ymm31
    {evex} vpmaxub 64(%rax,%rsi,8), %ymm20, %ymm12
    {evex} vpmaxub -129(%r9,%rcx,1), %ymm17, %ymm16
    {evex} vpmaxub gnu_back(%rip), %ymm3, %ymm25
    {evex} vpmaxub %ymm9, %ymm31, %ymm20{%k3}
    {evex} vpmaxub 0(%rbx), %ymm12, %ymm17{%k4}
    {evex} vpmaxub -4096(%r13), %ymm16, %ymm3{%k5}
    {evex} vpmaxub 1001(%rdx), %ymm25, %ymm9{%k6}
    {evex} vpmaxub 0(%r12), %ymm31, %ymm20{%k7}
    {evex} vpmaxub 4064(%rsp), %ymm12, %ymm17{%k1}
    {evex} vpmaxub -2147483648(%r12), %ymm16, %ymm3{%k2}
    {evex} vpmaxub 0(%r14,%r9,2), %ymm25, %ymm9{%k3}
    {evex} vpmaxub -32(%rsp,%rbp,4), %ymm31, %ymm20{%k4}
    {evex} vpmaxub 2147483647(%r13,%r12,8), %ymm12, %ymm17{%k5}
    {evex} vpmaxub gnu_fwd(%rip), %ymm16, %ymm3{%k6}
    {evex} vpmaxub %ymm25, %ymm9, %ymm31{%k7}{z}
g72:
    {evex} vpmaxub 0(%r10), %ymm20, %ymm12{%k1}{z}
    {evex} vpmaxub 64(%r9), %ymm17, %ymm16{%k2}{z}
    {evex} vpmaxub 4660(%rbx), %ymm3, %ymm25{%k3}{z}
    {evex} vpmaxub 0(%rsp), %ymm9, %ymm31{%k4}{z}
    {evex} vpmaxub -4096(%r12), %ymm20, %ymm12{%k5}{z}
    {evex} vpmaxub -129(%rsp), %ymm17, %ymm16{%k6}{z}
    {evex} vpmaxub 0(%rsi,%rax,1), %ymm3, %ymm25{%k7}{z}
    {evex} vpmaxub 4064(%rbp,%r15,2), %ymm9, %ymm31{%k1}{z}
    {evex} vpmaxub 1001(%r12,%rsi,4), %ymm20, %ymm12{%k2}{z}
    {evex} vpmaxub gnu_back(%rip), %ymm17, %ymm16{%k3}{z}
    {evex} vpmaxub %zmm3, %zmm25, %zmm9
    {evex} vpmaxub 0(%rsi), %zmm31, %zmm20
    {evex} vpmaxub 8128(%r10), %zmm12, %zmm17
    {evex} vpmaxub -2147483648(%rsi), %zmm16, %zmm3
    {evex} vpmaxub 0(%r12), %zmm25, %zmm9
    {evex} vpmaxub -64(%rsp), %zmm31, %zmm20
    {evex} vpmaxub 2147483647(%r12), %zmm12, %zmm17
    {evex} vpmaxub 0(%r15,%rcx,8), %zmm16, %zmm3
    {evex} vpmaxub 128(%rdi,%r9,1), %zmm25, %zmm9
    {evex} vpmaxub 4660(%r15,%rbp,2), %zmm31, %zmm20
    {evex} vpmaxub gnu_fwd(%rip), %zmm12, %zmm17
    {evex} vpmaxub %zmm16, %zmm3, %zmm25{%k4}
    {evex} vpmaxub 0(%r11), %zmm9, %zmm31{%k5}
    {evex} vpmaxub -8192(%r11), %zmm20, %zmm12{%k6}
    {evex} vpmaxub -129(%rdi), %zmm17, %zmm16{%k7}
    {evex} vpmaxub 0(%rsp), %zmm3, %zmm25{%k1}
    {evex} vpmaxub 8128(%r12), %zmm9, %zmm31{%k2}
    {evex} vpmaxub 1001(%rsp), %zmm20, %zmm12{%k3}
    {evex} vpmaxub 0(%rax,%r12,4), %zmm17, %zmm16{%k4}
    {evex} vpmaxub -64(%rax,%rax,8), %zmm3, %zmm25{%k5}
    {evex} vpmaxub -2147483648(%r9,%r15,1), %zmm9, %zmm31{%k6}
    {evex} vpmaxub gnu_back(%rip), %zmm20, %zmm12{%k7}
    {evex} vpmaxub %zmm17, %zmm16, %zmm3{%k1}{z}
    {evex} vpmaxub 0(%rdi), %zmm25, %zmm9{%k2}{z}
    {evex} vpmaxub 128(%r14), %zmm31, %zmm20{%k3}{z}
    {evex} vpmaxub 2147483647(%r15), %zmm12, %zmm17{%k4}{z}
    {evex} vpmaxub 0(%r12), %zmm16, %zmm3{%k5}{z}
    {evex} vpmaxub -8192(%rsp), %zmm25, %zmm9{%k6}{z}
    {evex} vpmaxub 4660(%r12), %zmm31, %zmm20{%k7}{z}
    {evex} vpmaxub 0(%r8,%rsi,2), %zmm12, %zmm17{%k1}{z}
    {evex} vpmaxub 8128(%rsp,%rcx,4), %zmm16, %zmm3{%k2}{z}
    {evex} vpmaxub -129(%r13,%r9,8), %zmm25, %zmm9{%k3}{z}
    {evex} vpmaxub gnu_fwd(%rip), %zmm31, %zmm20{%k4}{z}
    {evex} vpminud %xmm12, %xmm17, %xmm16
    {evex} vpminud 0(%r14), %xmm3, %xmm25
    {evex} vpminud -16(%rcx), %xmm9, %xmm31
    {evex} vpminud 1001(%r8), %xmm20, %xmm12
    {evex} vpminud 0(%rsp), %xmm17, %xmm16
    {evex} vpminud 32(%r12), %xmm3, %xmm25
    {evex} vpminud -2147483648(%rsp), %xmm9, %xmm31
    {evex} vpminud 0(%rcx,%rbp,1), %xmm20, %xmm12
    {evex} vpminud -2048(%rbp,%r12,2), %xmm17, %xmm16
    {evex} vpminud 2147483647(%r12,%rax,4), %xmm3, %xmm25
    {evex} vpminud gnu_back(%rip), %xmm9, %xmm31
    {evex} vpminud %xmm20, %xmm12, %xmm17{%k5}
    {evex} vpminud 0(%r15), %xmm16, %xmm3{%k6}
    {evex} vpminud 2032(%rbp), %xmm25, %xmm9{%k7}
    {evex} vpminud 4660(%r13), %xmm31, %xmm20{%k1}
    {evex} vpminud 0(%r12), %xmm12, %xmm17{%k2}
    {evex} vpminud -16(%rsp), %xmm16, %xmm3{%k3}
    {evex} vpminud -129(%r12), %xmm25, %xmm9{%k4}
    {evex} vpminud 0(%r12,%r15,8), %xmm31, %xmm20{%k5}
    {evex} vpminud 32(%rdi,%rsi,1), %xmm12, %xmm17{%k6}
    {evex} vpminud 1001(%r15,%rcx,2), %xmm16, %xmm3{%k7}
    {evex} vpminud gnu_fwd(%rip), %xmm25, %xmm9{%k1}
    {evex} vpminud %xmm31, %xmm20, %xmm12{%k2}{z}
    {evex} vpminud 0(%rcx), %xmm17, %xmm16{%k3}{z}
    {evex} vpminud -2048(%rdx), %xmm3, %xmm25{%k4}{z}
    {evex} vpminud -2147483648(%r9), %xmm9, %xmm31{%k5}{z}
    {evex} vpminud 0(%rsp), %xmm20, %xmm12{%k6}{z}
    {evex} vpminud 2032(%r12), %xmm17, %xmm16{%k7}{z}
    {evex} vpminud 2147483647(%rsp), %xmm3, %xmm25{%k1}{z}
    {evex} vpminud 0(%rdx,%r9,4), %xmm9, %xmm31{%k2}{z}
    {evex} vpminud -16(%rax,%rbp,8), %xmm20, %xmm12{%k3}{z}
    {evex} vpminud 4660(%r9,%r12,1), %xmm17, %xmm16{%k4}{z}
    {evex} vpminud gnu_back(%rip), %xmm3, %xmm25{%k5}{z}
    {evex} vpminud %ymm9, %ymm31, %ymm20
    {evex} vpminud 0(%r8), %ymm12, %ymm17
    {evex} vpminud -32(%rbx), %ymm16, %ymm3
    {evex} vpminud -129(%r10), %ymm25, %ymm9
    {evex} vpminud 0(%r12), %ymm31, %ymm20
    {evex} vpminud 64(%rsp), %ymm12, %ymm17
    {evex} vpminud 1001(%r12), %ymm16, %ymm3
    {evex} vpminud 0(%r9,%rax,2), %ymm25, %ymm9
    {evex} vpminud -4096(%rsp,%r15,4), %ymm31, %ymm20
    {evex} vpminud -2147483648(%r13,%rsi,8), %ymm12, %ymm17
    {evex} vpminud gnu_fwd(%rip), %ymm16, %ymm3
    {evex} vpminud %ymm25, %ymm9, %ymm31{%k6}
    {evex} vpminud 0(%rdx), %ymm20, %ymm12{%k7}
    {evex} vpminud 4064(%rsi), %ymm17, %ymm16{%k1}
    {evex} vpminud 2147483647(%r11), %ymm3, %ymm25{%k2}
    {evex} vpminud 0(%rsp), %ymm9, %ymm31{%k3}
    {evex} vpminud -32(%r12), %ymm20, %ymm12{%k4}
    {evex} vpminud 4660(%rsp), %ymm17, %ymm16{%k5}
    {evex} vpminud 0(%rsp,%rcx,1), %ymm3, %ymm25{%k6}
    {evex} vpminud 64(%rbp,%r9,2), %ymm9, %ymm31{%k7}
    {evex} vpminud -129(%r12,%rbp,4), %ymm20, %ymm12{%k1}
    {evex} vpminud gnu_back(%rip), %ymm17, %ymm16{%k2}
    {evex} vpminud %ymm3, %ymm25, %ymm9{%k3}{z}
    {evex} vpminud 0(%r9), %ymm31, %ymm20{%k4}{z}
    {evex} vpminud -4096(%rdi), %ymm12, %ymm17{%k5}{z}
    {evex} vpminud 1001(%r14), %ymm16, %ymm3{%k6}{z}
    {evex} vpminud 0(%r12), %ymm25, %ymm9{%k7}{z}
    {evex} vpminud 4064(%rsp), %ymm31, %ymm20{%k1}{z}
    {evex} vpminud -2147483648(%r12), %ymm12, %ymm17{%k2}{z}
    {evex} vpminud 0(%r14,%r12,8), %ymm16, %ymm3{%k3}{z}
    {evex} vpminud -32(%rdi,%rax,1), %ymm25, %ymm9{%k4}{z}
    {evex} vpminud 2147483647(%r15,%r15,2), %ymm31, %ymm20{%k5}{z}
    {evex} vpminud gnu_fwd(%rip), %ymm12, %ymm17{%k6}{z}
    {evex} vpminud %zmm16, %zmm3, %zmm25
    {evex} vpminud 0(%rbx), %zmm9, %zmm31
    {evex} vpminud -64(%r15), %zmm20, %zmm12
    {evex} vpminud 4660(%rcx), %zmm17, %zmm16
    {evex} vpminud 0(%rsp), %zmm3, %zmm25
    {evex} vpminud 128(%r12), %zmm9, %zmm31
    {evex} vpminud -129(%rsp), %zmm20, %zmm12
    {evex} vpminud 0(%rsi,%rsi,4), %zmm17, %zmm16
    {evex} vpminud -8192(%rax,%rcx,8), %zmm3, %zmm25
    {evex} vpminud 1001(%r9,%r9,1), %zmm9, %zmm31
    {evex} vpminud gnu_back(%rip), %zmm20, %zmm12
    {evex} vpminud %zmm17, %zmm16, %zmm3{%k7}
    {evex} vpminud 0(%r10), %zmm25, %zmm9{%k1}
    {evex} vpminud 8128(%r8), %zmm31, %zmm20{%k2}
    {evex} vpminud -2147483648(%rbp), %zmm12, %zmm17{%k3}
    {evex} vpminud 0(%r12), %zmm16, %zmm3{%k4}
    {evex} vpminud -64(%rsp), %zmm25, %zmm9{%k5}
    {evex} vpminud 2147483647(%r12), %zmm31, %zmm20{%k6}
    {evex} vpminud 0(%r15,%rbp,2), %zmm12, %zmm17{%k7}
    {evex} vpminud 128(%rsp,%r12,4), %zmm16, %zmm3{%k1}
    {evex} vpminud 4660(%r13,%rax,8), %zmm25, %zmm9{%k2}
    {evex} vpminud gnu_fwd(%rip), %zmm31, %zmm20{%k3}
    {evex} vpminud %zmm12, %zmm17, %zmm16{%k4}{z}
    {evex} vpminud 0(%rsi), %zmm3, %zmm25{%k5}{z}
    {evex} vpminud -8192(%r13), %zmm9, %zmm31{%k6}{z}
    {evex} vpminud -129(%rdx), %zmm20, %zmm12{%k7}{z}
    {evex} vpminud 0(%rsp), %zmm17, %zmm16{%k1}{z}
    {evex} vpminud 8128(%r12), %zmm3, %zmm25{%k2}{z}
    {evex} vpminud 1001(%rsp), %zmm9, %zmm31{%k3}{z}
    {evex} vpminud 0(%rax,%r15,1), %zmm20, %zmm12{%k4}{z}
    {evex} vpminud -64(%rbp,%rsi,2), %zmm17, %zmm16{%k5}{z}
    {evex} vpminud -2147483648(%r12,%rcx,4), %zmm3, %zmm25{%k6}{z}
    {evex} vpminud gnu_back(%rip), %zmm9, %zmm31{%k7}{z}
    {evex} vpaddb %xmm20, %xmm12, %xmm17
    {evex} vpaddb 0(%r11), %xmm16, %xmm3
    {evex} vpaddb 32(%r9), %xmm25, %xmm9
    {evex} vpaddb 2147483647(%rbx), %xmm31, %xmm20
    {evex} vpaddb 0(%r12), %xmm12, %xmm17
    {evex} vpaddb -2048(%rsp), %xmm16, %xmm3
    {evex} vpaddb 4660(%r12), %xmm25, %xmm9
    {evex} vpaddb 0(%r8,%r9,8), %xmm31, %xmm20
    {evex} vpaddb 2032(%rdi,%rbp,1), %xmm12, %xmm17
    {evex} vpaddb -129(%r15,%r12,2), %xmm16, %xmm3
    {evex} vpaddb gnu_fwd(%rip), %xmm25, %xmm9
    {evex} vpaddb %xmm31, %xmm20, %xmm12{%k1}
    {evex} vpaddb 0(%rdi), %xmm17, %xmm16{%k2}
    {evex} vpaddb -16(%r10), %xmm3, %xmm25{%k3}
    {evex} vpaddb 1001(%rsi), %xmm9, %xmm31{%k4}
    {evex} vpaddb 0(%rsp), %xmm20, %xmm12{%k5}
    {evex} vpaddb 32(%r12), %xmm17, %xmm16{%k6}
    {evex} vpaddb -2147483648(%rsp), %xmm3, %xmm25{%k7}
    {evex} vpaddb 0(%rcx,%rax,4), %xmm9, %xmm31{%k1}
    {evex} vpaddb -2048(%rax,%r15,8), %xmm20, %xmm12{%k2}
    {evex} vpaddb 2147483647(%r9,%rsi,1), %xmm17, %xmm16{%k3}
    {evex} vpaddb gnu_back(%rip), %xmm3, %xmm25{%k4}
    {evex} vpaddb %xmm9, %xmm31, %xmm20{%k5}{z}
    {evex} vpaddb 0(%r14), %xmm12, %xmm17{%k6}{z}
    {evex} vpaddb 2032(%r11), %xmm16, %xmm3{%k7}{z}
    {evex} vpaddb 4660(%rdi), %xmm25, %xmm9{%k1}{z}
    {evex} vpaddb 0(%r12), %xmm31, %xmm20{%k2}{z}
    {evex} vpaddb -16(%rsp), %xmm12, %xmm17{%k3}{z}
    {evex} vpaddb -129(%r12), %xmm16, %xmm3{%k4}{z}
    {evex} vpaddb 0(%r12,%rcx,2), %xmm25, %xmm9{%k5}{z}
    {evex} vpaddb 32(%rsp,%r9,4), %xmm31, %xmm20{%k6}{z}
    {evex} vpaddb 1001(%r13,%rbp,8), %xmm12, %xmm17{%k7}{z}
    {evex} vpaddb gnu_fwd(%rip), %xmm16, %xmm3{%k1}{z}
    {evex} vpaddb %ymm25, %ymm9, %ymm31
    {evex} vpaddb 0(%r15), %ymm20, %ymm12
    {evex} vpaddb 64(%r14), %ymm17, %ymm16
    {evex} vpaddb -2147483648(%r15), %ymm3, %ymm25
    {evex} vpaddb 0(%rsp), %ymm9, %ymm31
    {evex} vpaddb -4096(%r12), %ymm20, %ymm12
    {evex} vpaddb 2147483647(%rsp), %ymm17, %ymm16
    {evex} vpaddb 0(%rdx,%r12,1), %ymm3, %ymm25
    {evex} vpaddb 4064(%rbp,%rax,2), %ymm9, %ymm31
    {evex} vpaddb 4660(%r12,%r15,4), %ymm20, %ymm12
    {evex} vpaddb gnu_back(%rip), %ymm17, %ymm16
    {evex} vpaddb %ymm3, %ymm25, %ymm9{%k2}
    {evex} vpaddb 0(%rcx), %ymm31, %ymm20{%k3}
    {evex} vpaddb -32(%rcx), %ymm12, %ymm17{%k4}
    {evex} vpaddb -129(%r8), %ymm16, %ymm3{%k5}
    {evex} vpaddb 0(%r12), %ymm25, %ymm9{%k6}
    {evex} vpaddb 64(%rsp), %ymm31, %ymm20{%k7}
    {evex} vpaddb 1001(%r12), %ymm12, %ymm17{%k1}
    {evex} vpaddb 0(%r9,%rsi,8), %ymm16, %ymm3{%k2}
    {evex} vpaddb -4096(%rdi,%rcx,1), %ymm25, %ymm9{%k3}
    {evex} vpaddb -2147483648(%r15,%r9,2), %ymm31, %ymm20{%k4}
    {evex} vpaddb gnu_fwd(%rip), %ymm12, %ymm17{%k5}
    {evex} vpaddb %ymm16, %ymm3, %ymm25{%k6}{z}
    {evex} vpaddb 0(%r8), %ymm9, %ymm31{%k7}{z}
    {evex} vpaddb 4064(%rbp), %ymm20, %ymm12{%k1}{z}
g73:
    {evex} vpaddb 2147483647(%r13), %ymm17, %ymm16{%k2}{z}
    {evex} vpaddb 0(%rsp), %ymm3, %ymm25{%k3}{z}
    {evex} vpaddb -32(%r12), %ymm9, %ymm31{%k4}{z}
    {evex} vpaddb 4660(%rsp), %ymm20, %ymm12{%k5}{z}
    {evex} vpaddb 0(%rsp,%rbp,4), %ymm17, %ymm16{%k6}{z}
    {evex} vpaddb 64(%rax,%r12,8), %ymm3, %ymm25{%k7}{z}
    {evex} vpaddb -129(%r9,%rax,1), %ymm9, %ymm31{%k1}{z}
    {evex} vpaddb gnu_back(%rip), %ymm20, %ymm12{%k2}{z}
    {evex} vpaddb %zmm17, %zmm16, %zmm3
    {evex} vpaddb 0(%rdx), %zmm25, %zmm9
    {evex} vpaddb 128(%rdx), %zmm31, %zmm20
    {evex} vpaddb 1001(%r9), %zmm12, %zmm17
    {evex} vpaddb 0(%r12), %zmm16, %zmm3
    {evex} vpaddb -8192(%rsp), %zmm25, %zmm9
    {evex} vpaddb -2147483648(%r12), %zmm31, %zmm20
    {evex} vpaddb 0(%r14,%r15,2), %zmm12, %zmm17
    {evex} vpaddb 8128(%rsp,%rsi,4), %zmm16, %zmm3
    {evex} vpaddb 2147483647(%r13,%rcx,8), %zmm25, %zmm9
    {evex} vpaddb gnu_fwd(%rip), %zmm31, %zmm20
    {evex} vpaddb %zmm12, %zmm17, %zmm16{%k3}
    {evex} vpaddb 0(%r9), %zmm3, %zmm25{%k4}
    {evex} vpaddb -64(%rbx), %zmm9, %zmm31{%k5}
    {evex} vpaddb 4660(%r10), %zmm20, %zmm12{%k6}
    {evex} vpaddb 0(%rsp), %zmm17, %zmm16{%k7}
    {evex} vpaddb 128(%r12), %zmm3, %zmm25{%k1}
    {evex} vpaddb -129(%rsp), %zmm9, %zmm31{%k2}
    {evex} vpaddb 0(%rsi,%r9,1), %zmm20, %zmm12{%k3}
    {evex} vpaddb -8192(%rbp,%rbp,2), %zmm17, %zmm16{%k4}
    {evex} vpaddb 1001(%r12,%r12,4), %zmm3, %zmm25{%k5}
    {evex} vpaddb gnu_back(%rip), %zmm9, %zmm31{%k6}
    {evex} vpaddb %zmm20, %zmm12, %zmm17{%k7}{z}
    {evex} vpaddb 0(%rbx), %zmm16, %zmm3{%k1}{z}
    {evex} vpaddb 8128(%rsi), %zmm25, %zmm9{%k2}{z}
    {evex} vpaddb -2147483648(%r11), %zmm31, %zmm20{%k3}{z}
    {evex} vpaddb 0(%r12), %zmm12, %zmm17{%k4}{z}
    {evex} vpaddb -64(%rsp), %zmm16, %zmm3{%k5}{z}
    {evex} vpaddb 2147483647(%r12), %zmm25, %zmm9{%k6}{z}
    {evex} vpaddb 0(%r15,%rax,8), %zmm31, %zmm20{%k7}{z}
    {evex} vpaddb 128(%rdi,%r15,1), %zmm12, %zmm17{%k1}{z}
    {evex} vpaddb 4660(%r15,%rsi,2), %zmm16, %zmm3{%k2}{z}
    {evex} vpaddb gnu_fwd(%rip), %zmm25, %zmm9{%k3}{z}
    {evex} vpsubb %xmm31, %xmm20, %xmm12
    {evex} vpsubb 0(%r10), %xmm17, %xmm16
    {evex} vpsubb -2048(%rdi), %xmm3, %xmm25
    {evex} vpsubb -129(%r14), %xmm9, %xmm31
    {evex} vpsubb 0(%rsp), %xmm20, %xmm12
    {evex} vpsubb 2032(%r12), %xmm17, %xmm16
    {evex} vpsubb 1001(%rsp), %xmm3, %xmm25
    {evex} vpsubb 0(%rax,%rcx,4), %xmm9, %xmm31
    {evex} vpsubb -16(%rax,%r9,8), %xmm20, %xmm12
    {evex} vpsubb -2147483648(%r9,%rbp,1), %xmm17, %xmm16
    {evex} vpsubb gnu_back(%rip), %xmm3, %xmm25
    {evex} vpsubb %xmm9, %xmm31, %xmm20{%k4}
    {evex} vpsubb 0(%rsi), %xmm12, %xmm17{%k5}
    {evex} vpsubb 32(%r15), %xmm16, %xmm3{%k6}
    {evex} vpsubb 2147483647(%rcx), %xmm25, %xmm9{%k7}
    {evex} vpsubb 0(%r12), %xmm31, %xmm20{%k1}
    {evex} vpsubb -2048(%rsp), %xmm12, %xmm17{%k2}
    {evex} vpsubb 4660(%r12), %xmm16, %xmm3{%k3}
    {evex} vpsubb 0(%r8,%r12,2), %xmm25, %xmm9{%k4}
    {evex} vpsubb 2032(%rsp,%rax,4), %xmm31, %xmm20{%k5}
    {evex} vpsubb -129(%r13,%r15,8), %xmm12, %xmm17{%k6}
    {evex} vpsubb gnu_fwd(%rip), %xmm16, %xmm3{%k7}
    {evex} vpsubb %xmm25, %xmm9, %xmm31{%k1}{z}
    {evex} vpsubb 0(%r11), %xmm20, %xmm12{%k2}{z}
    {evex} vpsubb -16(%r8), %xmm17, %xmm16{%k3}{z}
    {evex} vpsubb 1001(%rbp), %xmm3, %xmm25{%k4}{z}
    {evex} vpsubb 0(%rsp), %xmm9, %xmm31{%k5}{z}
    {evex} vpsubb 32(%r12), %xmm20, %xmm12{%k6}{z}
    {evex} vpsubb -2147483648(%rsp), %xmm17, %xmm16{%k7}{z}
    {evex} vpsubb 0(%rcx,%rsi,1), %xmm3, %xmm25{%k1}{z}
    {evex} vpsubb -2048(%rbp,%rcx,2), %xmm9, %xmm31{%k2}{z}
    {evex} vpsubb 2147483647(%r12,%r9,4), %xmm20, %xmm12{%k3}{z}
    {evex} vpsubb gnu_back(%rip), %xmm17, %xmm16{%k4}{z}
    {evex} vpsubb %ymm3, %ymm25, %ymm9
    {evex} vpsubb 0(%rdi), %ymm31, %ymm20
    {evex} vpsubb -4096(%r13), %ymm12, %ymm17
    {evex} vpsubb 4660(%rdx), %ymm16, %ymm3
    {evex} vpsubb 0(%r12), %ymm25, %ymm9
    {evex} vpsubb 4064(%rsp), %ymm31, %ymm20
    {evex} vpsubb -129(%r12), %ymm12, %ymm17
    {evex} vpsubb 0(%r12,%rbp,8), %ymm16, %ymm3
    {evex} vpsubb -32(%rdi,%r12,1), %ymm25, %ymm9
    {evex} vpsubb 1001(%r15,%rax,2), %ymm31, %ymm20
    {evex} vpsubb gnu_fwd(%rip), %ymm12, %ymm17
    {evex} vpsubb %ymm16, %ymm3, %ymm25{%k5}
    {evex} vpsubb 0(%r14), %ymm9, %ymm31{%k6}
    {evex} vpsubb 64(%r9), %ymm20, %ymm12{%k7}
    {evex} vpsubb -2147483648(%rbx), %ymm17, %ymm16{%k1}
    {evex} vpsubb 0(%rsp), %ymm3, %ymm25{%k2}
    {evex} vpsubb -4096(%r12), %ymm9, %ymm31{%k3}
    {evex} vpsubb 2147483647(%rsp), %ymm20, %ymm12{%k4}
    {evex} vpsubb 0(%rdx,%r15,4), %ymm17, %ymm16{%k5}
    {evex} vpsubb 4064(%rax,%rsi,8), %ymm3, %ymm25{%k6}
    {evex} vpsubb 4660(%r9,%rcx,1), %ymm9, %ymm31{%k7}
    {evex} vpsubb gnu_back(%rip), %ymm20, %ymm12{%k1}
    {evex} vpsubb %ymm17, %ymm16, %ymm3{%k2}{z}
    {evex} vpsubb 0(%r15), %ymm25, %ymm9{%k3}{z}
    {evex} vpsubb -32(%r10), %ymm31, %ymm20{%k4}{z}
    {evex} vpsubb -129(%rsi), %ymm12, %ymm17{%k5}{z}
    {evex} vpsubb 0(%r12), %ymm16, %ymm3{%k6}{z}
    {evex} vpsubb 64(%rsp), %ymm25, %ymm9{%k7}{z}
    {evex} vpsubb 1001(%r12), %ymm31, %ymm20{%k1}{z}
    {evex} vpsubb 0(%r9,%r9,2), %ymm12, %ymm17{%k2}{z}
    {evex} vpsubb -4096(%rsp,%rbp,4), %ymm16, %ymm3{%k3}{z}
    {evex} vpsubb -2147483648(%r13,%r12,8), %ymm25, %ymm9{%k4}{z}
    {evex} vpsubb gnu_fwd(%rip), %ymm31, %ymm20{%k5}{z}
    {evex} vpsubb %zmm12, %zmm17, %zmm16
    {evex} vpsubb 0(%rcx), %zmm3, %zmm25
    {evex} vpsubb -8192(%r11), %zmm9, %zmm31
    {evex} vpsubb 2147483647(%rdi), %zmm20, %zmm12
    {evex} vpsubb 0(%rsp), %zmm17, %zmm16
    {evex} vpsubb 8128(%r12), %zmm3, %zmm25
    {evex} vpsubb 4660(%rsp), %zmm9, %zmm31
    {evex} vpsubb 0(%rsp,%rax,1), %zmm20, %zmm12
    {evex} vpsubb -64(%rbp,%r15,2), %zmm17, %zmm16
    {evex} vpsubb -129(%r12,%rsi,4), %zmm3, %zmm25
    {evex} vpsubb gnu_back(%rip), %zmm9, %zmm31
    {evex} vpsubb %zmm20, %zmm12, %zmm17{%k6}
    {evex} vpsubb 0(%r8), %zmm16, %zmm3{%k7}
    {evex} vpsubb 128(%r14), %zmm25, %zmm9{%k1}
    {evex} vpsubb 1001(%r15), %zmm31, %zmm20{%k2}
    {evex} vpsubb 0(%r12), %zmm12, %zmm17{%k3}
    {evex} vpsubb -8192(%rsp), %zmm16, %zmm3{%k4}
    {evex} vpsubb -2147483648(%r12), %zmm25, %zmm9{%k5}
    {evex} vpsubb 0(%r14,%rcx,8), %zmm31, %zmm20{%k6}
    {evex} vpsubb 8128(%rdi,%r9,1), %zmm12, %zmm17{%k7}
    {evex} vpsubb 2147483647(%r15,%rbp,2), %zmm16, %zmm3{%k1}
    {evex} vpsubb gnu_fwd(%rip), %zmm25, %zmm9{%k2}
    {evex} vpsubb %zmm31, %zmm20, %zmm12{%k3}{z}
    {evex} vpsubb 0(%rdx), %zmm17, %zmm16{%k4}{z}
    {evex} vpsubb -64(%rcx), %zmm3, %zmm25{%k5}{z}
    {evex} vpsubb 4660(%r8), %zmm9, %zmm31{%k6}{z}
    {evex} vpsubb 0(%rsp), %zmm20, %zmm12{%k7}{z}
    {evex} vpsubb 128(%r12), %zmm17, %zmm16{%k1}{z}
    {evex} vpsubb -129(%rsp), %zmm3, %zmm25{%k2}{z}
    {evex} vpsubb 0(%rsi,%r12,4), %zmm9, %zmm31{%k3}{z}
    {evex} vpsubb -8192(%rax,%rax,8), %zmm20, %zmm12{%k4}{z}
    {evex} vpsubb 1001(%r9,%r15,1), %zmm17, %zmm16{%k5}{z}
    {evex} vpsubb gnu_back(%rip), %zmm3, %zmm25{%k6}{z}
    {evex} vpxorq %xmm9, %xmm31, %xmm20
    {evex} vpxorq 0(%r9), %xmm12, %xmm17
    {evex} vpxorq 2032(%rbp), %xmm16, %xmm3
    {evex} vpxorq -2147483648(%r13), %xmm25, %xmm9
    {evex} vpxorq 0(%r12), %xmm31, %xmm20
    {evex} vpxorq -16(%rsp), %xmm12, %xmm17
    {evex} vpxorq 2147483647(%r12), %xmm16, %xmm3
    {evex} vpxorq 0(%r15,%rsi,2), %xmm25, %xmm9
    {evex} vpxorq 32(%rsp,%rcx,4), %xmm31, %xmm20
    {evex} vpxorq 4660(%r13,%r9,8), %xmm12, %xmm17
    {evex} vpxorq gnu_fwd(%rip), %xmm16, %xmm3
    {evex} vpxorq %xmm25, %xmm9, %xmm31{%k7}
    {evex} vpxorq 0(%rbx), %xmm20, %xmm12{%k1}
    {evex} vpxorq -2048(%rdx), %xmm17, %xmm16{%k2}
    {evex} vpxorq -129(%r9), %xmm3, %xmm25{%k3}
    {evex} vpxorq 0(%rsp), %xmm9, %xmm31{%k4}
    {evex} vpxorq 2032(%r12), %xmm20, %xmm12{%k5}
    {evex} vpxorq 1001(%rsp), %xmm17, %xmm16{%k6}
    {evex} vpxorq 0(%rax,%rbp,1), %xmm3, %xmm25{%k7}
    {evex} vpxorq -16(%rbp,%r12,2), %xmm9, %xmm31{%k1}
    {evex} vpxorq -2147483648(%r12,%rax,4), %xmm20, %xmm12{%k2}
    {evex} vpxorq gnu_back(%rip), %xmm17, %xmm16{%k3}
    {evex} vpxorq %xmm3, %xmm25, %xmm9{%k4}{z}
    {evex} vpxorq 0(%r10), %xmm31, %xmm20{%k5}{z}
    {evex} vpxorq 32(%rbx), %xmm12, %xmm17{%k6}{z}
    {evex} vpxorq 2147483647(%r10), %xmm16, %xmm3{%k7}{z}
    {evex} vpxorq 0(%r12), %xmm25, %xmm9{%k1}{z}
    {evex} vpxorq -2048(%rsp), %xmm31, %xmm20{%k2}{z}
    {evex} vpxorq 4660(%r12), %xmm12, %xmm17{%k3}{z}
    {evex} vpxorq 0(%r8,%r15,8), %xmm16, %xmm3{%k4}{z}
    {evex} vpxorq 2032(%rdi,%rsi,1), %xmm25, %xmm9{%k5}{z}
    {evex} vpxorq -129(%r15,%rcx,2), %xmm31, %xmm20{%k6}{z}
    {evex} vpxorq gnu_fwd(%rip), %xmm12, %xmm17{%k7}{z}
    {evex} vpxorq %ymm16, %ymm3, %ymm25
    {evex} vpxorq 0(%rsi), %ymm9, %ymm31
    {evex} vpxorq 4064(%rsi), %ymm20, %ymm12
    {evex} vpxorq 1001(%r11), %ymm17, %ymm16
    {evex} vpxorq 0(%rsp), %ymm3, %ymm25
    {evex} vpxorq -32(%r12), %ymm9, %ymm31
    {evex} vpxorq -2147483648(%rsp), %ymm20, %ymm12
    {evex} vpxorq 0(%rcx,%r9,4), %ymm17, %ymm16
    {evex} vpxorq 64(%rax,%rbp,8), %ymm3, %ymm25
    {evex} vpxorq 2147483647(%r9,%r12,1), %ymm9, %ymm31
    {evex} vpxorq gnu_back(%rip), %ymm20, %ymm12
    {evex} vpxorq %ymm17, %ymm16, %ymm3{%k1}
    {evex} vpxorq 0(%r11), %ymm25, %ymm9{%k2}
    {evex} vpxorq -4096(%rdi), %ymm31, %ymm20{%k3}
    {evex} vpxorq 4660(%r14), %ymm12, %ymm17{%k4}
    {evex} vpxorq 0(%r12), %ymm16, %ymm3{%k5}
    {evex} vpxorq 4064(%rsp), %ymm25, %ymm9{%k6}
    {evex} vpxorq -129(%r12), %ymm31, %ymm20{%k7}
    {evex} vpxorq 0(%r12,%rax,2), %ymm12, %ymm17{%k1}
    {evex} vpxorq -32(%rsp,%r15,4), %ymm16, %ymm3{%k2}
    {evex} vpxorq 1001(%r13,%rsi,8), %ymm25, %ymm9{%k3}
    {evex} vpxorq gnu_fwd(%rip), %ymm31, %ymm20{%k4}
    {evex} vpxorq %ymm12, %ymm17, %ymm16{%k5}{z}
    {evex} vpxorq 0(%rdi), %ymm3, %ymm25{%k6}{z}
    {evex} vpxorq 64(%r15), %ymm9, %ymm31{%k7}{z}
    {evex} vpxorq -2147483648(%rcx), %ymm20, %ymm12{%k1}{z}
    {evex} vpxorq 0(%rsp), %ymm17, %ymm16{%k2}{z}
g74:
    {evex} vpxorq -4096(%r12), %ymm3, %ymm25{%k3}{z}
    {evex} vpxorq 2147483647(%rsp), %ymm9, %ymm31{%k4}{z}
    {evex} vpxorq 0(%rdx,%rcx,1), %ymm20, %ymm12{%k5}{z}
    {evex} vpxorq 4064(%rbp,%r9,2), %ymm17, %ymm16{%k6}{z}
    {evex} vpxorq 4660(%r12,%rbp,4), %ymm3, %ymm25{%k7}{z}
    {evex} vpxorq gnu_back(%rip), %ymm9, %ymm31{%k1}{z}
    {evex} vpxorq %zmm20, %zmm12, %zmm17
    {evex} vpxorq 0(%r14), %zmm16, %zmm3
    {evex} vpxorq 8128(%r8), %zmm25, %zmm9
    {evex} vpxorq -129(%rbp), %zmm31, %zmm20
    {evex} vpxorq 0(%r12), %zmm12, %zmm17
    {evex} vpxorq -64(%rsp), %zmm16, %zmm3
    {evex} vpxorq 1001(%r12), %zmm25, %zmm9
    {evex} vpxorq 0(%r9,%r12,8), %zmm31, %zmm20
    {evex} vpxorq 128(%rdi,%rax,1), %zmm12, %zmm17
    {evex} vpxorq -2147483648(%r15,%r15,2), %zmm16, %zmm3
    {evex} vpxorq gnu_fwd(%rip), %zmm25, %zmm9
    {evex} vpxorq %zmm31, %zmm20, %zmm12{%k2}
    {evex} vpxorq 0(%r15), %zmm17, %zmm16{%k3}
    {evex} vpxorq -8192(%r13), %zmm3, %zmm25{%k4}
    {evex} vpxorq 2147483647(%rdx), %zmm9, %zmm31{%k5}
    {evex} vpxorq 0(%rsp), %zmm20, %zmm12{%k6}
    {evex} vpxorq 8128(%r12), %zmm17, %zmm16{%k7}
    {evex} vpxorq 4660(%rsp), %zmm3, %zmm25{%k1}
    {evex} vpxorq 0(%rsp,%rsi,4), %zmm9, %zmm31{%k2}
    {evex} vpxorq -64(%rax,%rcx,8), %zmm20, %zmm12{%k3}
    {evex} vpxorq -129(%r9,%r9,1), %zmm17, %zmm16{%k4}
    {evex} vpxorq gnu_back(%rip), %zmm3, %zmm25{%k5}
    {evex} vpxorq %zmm9, %zmm31, %zmm20{%k6}{z}
    {evex} vpxorq 0(%rcx), %zmm12, %zmm17{%k7}{z}
    {evex} vpxorq 128(%r9), %zmm16, %zmm3{%k1}{z}
    {evex} vpxorq 1001(%rbx), %zmm25, %zmm9{%k2}{z}
    {evex} vpxorq 0(%r12), %zmm31, %zmm20{%k3}{z}
    {evex} vpxorq -8192(%rsp), %zmm12, %zmm17{%k4}{z}
    {evex} vpxorq -2147483648(%r12), %zmm16, %zmm3{%k5}{z}
    {evex} vpxorq 0(%r14,%rbp,2), %zmm25, %zmm9{%k6}{z}
    {evex} vpxorq 8128(%rsp,%r12,4), %zmm31, %zmm20{%k7}{z}
    {evex} vpxorq 2147483647(%r13,%rax,8), %zmm12, %zmm17{%k1}{z}
    {evex} vpxorq gnu_fwd(%rip), %zmm16, %zmm3{%k2}{z}
    {evex} vpxord %xmm25, %xmm9, %xmm31
    {evex} vpxord 0(%r8), %xmm20, %xmm12
    {evex} vpxord -16(%r10), %xmm17, %xmm16
    {evex} vpxord 4660(%rsi), %xmm3, %xmm25
    {evex} vpxord 0(%rsp), %xmm9, %xmm31
    {evex} vpxord 32(%r12), %xmm20, %xmm12
    {evex} vpxord -129(%rsp), %xmm17, %xmm16
    {evex} vpxord 0(%rsi,%r15,1), %xmm3, %xmm25
    {evex} vpxord -2048(%rbp,%rsi,2), %xmm9, %xmm31
    {evex} vpxord 1001(%r12,%rcx,4), %xmm20, %xmm12
    {evex} vpxord gnu_back(%rip), %xmm17, %xmm16
    {evex} vpxord %xmm3, %xmm25, %xmm9{%k3}
    {evex} vpxord 0(%rdx), %xmm31, %xmm20{%k4}
    {evex} vpxord 2032(%r11), %xmm12, %xmm17{%k5}
    {evex} vpxord -2147483648(%rdi), %xmm16, %xmm3{%k6}
    {evex} vpxord 0(%r12), %xmm25, %xmm9{%k7}
    {evex} vpxord -16(%rsp), %xmm31, %xmm20{%k1}
    {evex} vpxord 2147483647(%r12), %xmm12, %xmm17{%k2}
    {evex} vpxord 0(%r15,%r9,8), %xmm16, %xmm3{%k3}
    {evex} vpxord 32(%rdi,%rbp,1), %xmm25, %xmm9{%k4}
    {evex} vpxord 4660(%r15,%r12,2), %xmm31, %xmm20{%k5}
    {evex} vpxord gnu_fwd(%rip), %xmm12, %xmm17{%k6}
    {evex} vpxord %xmm16, %xmm3, %xmm25{%k7}{z}
    {evex} vpxord 0(%r9), %xmm9, %xmm31{%k1}{z}
    {evex} vpxord -2048(%r14), %xmm20, %xmm12{%k2}{z}
    {evex} vpxord -129(%r15), %xmm17, %xmm16{%k3}{z}
    {evex} vpxord 0(%rsp), %xmm3, %xmm25{%k4}{z}
    {evex} vpxord 2032(%r12), %xmm9, %xmm31{%k5}{z}
    {evex} vpxord 1001(%rsp), %xmm20, %xmm12{%k6}{z}
    {evex} vpxord 0(%rax,%rax,4), %xmm17, %xmm16{%k7}{z}
    {evex} vpxord -16(%rax,%r15,8), %xmm3, %xmm25{%k1}{z}
    {evex} vpxord -2147483648(%r9,%rsi,1), %xmm9, %xmm31{%k2}{z}
    {evex} vpxord gnu_back(%rip), %xmm20, %xmm12{%k3}{z}
    {evex} vpxord %ymm17, %ymm16, %ymm3
    {evex} vpxord 0(%rbx), %ymm25, %ymm9
    {evex} vpxord -32(%rcx), %ymm31, %ymm20
    {evex} vpxord 2147483647(%r8), %ymm12, %ymm17
    {evex} vpxord 0(%r12), %ymm16, %ymm3
    {evex} vpxord 64(%rsp), %ymm25, %ymm9
    {evex} vpxord 4660(%r12), %ymm31, %ymm20
    {evex} vpxord 0(%r8,%rcx,2), %ymm12, %ymm17
    {evex} vpxord -4096(%rsp,%r9,4), %ymm16, %ymm3
    {evex} vpxord -129(%r13,%rbp,8), %ymm25, %ymm9
    {evex} vpxord gnu_fwd(%rip), %ymm31, %ymm20
    {evex} vpxord %ymm12, %ymm17, %ymm16{%k4}
    {evex} vpxord 0(%r10), %ymm3, %ymm25{%k5}
    {evex} vpxord 4064(%rbp), %ymm9, %ymm31{%k6}
    {evex} vpxord 1001(%r13), %ymm20, %ymm12{%k7}
    {evex} vpxord 0(%rsp), %ymm17, %ymm16{%k1}
    {evex} vpxord -32(%r12), %ymm3, %ymm25{%k2}
    {evex} vpxord -2147483648(%rsp), %ymm9, %ymm31{%k3}
    {evex} vpxord 0(%rcx,%r12,1), %ymm20, %ymm12{%k4}
    {evex} vpxord 64(%rbp,%rax,2), %ymm17, %ymm16{%k5}
    {evex} vpxord 2147483647(%r12,%r15,4), %ymm3, %ymm25{%k6}
    {evex} vpxord gnu_back(%rip), %ymm9, %ymm31{%k7}
    {evex} vpxord %ymm20, %ymm12, %ymm17{%k1}{z}
    {evex} vpxord 0(%rsi), %ymm16, %ymm3{%k2}{z}
    {evex} vpxord -4096(%rdx), %ymm25, %ymm9{%k3}{z}
    {evex} vpxord 4660(%r9), %ymm31, %ymm20{%k4}{z}
    {evex} vpxord 0(%r12), %ymm12, %ymm17{%k5}{z}
    {evex} vpxord 4064(%rsp), %ymm16, %ymm3{%k6}{z}
    {evex} vpxord -129(%r12), %ymm25, %ymm9{%k7}{z}
    {evex} vpxord 0(%r12,%rsi,8), %ymm31, %ymm20{%k1}{z}
    {evex} vpxord -32(%rdi,%rcx,1), %ymm12, %ymm17{%k2}{z}
    {evex} vpxord 1001(%r15,%r9,2), %ymm16, %ymm3{%k3}{z}
    {evex} vpxord gnu_fwd(%rip), %ymm25, %ymm9{%k4}{z}
    {evex} vpxord %zmm31, %zmm20, %zmm12
    {evex} vpxord 0(%r11), %zmm17, %zmm16
    {evex} vpxord -64(%rbx), %zmm3, %zmm25
    {evex} vpxord -2147483648(%r10), %zmm9, %zmm31
    {evex} vpxord 0(%rsp), %zmm20, %zmm12
    {evex} vpxord 128(%r12), %zmm17, %zmm16
    {evex} vpxord 2147483647(%rsp), %zmm3, %zmm25
    {evex} vpxord 0(%rdx,%rbp,4), %zmm9, %zmm31
    {evex} vpxord -8192(%rax,%r12,8), %zmm20, %zmm12
    {evex} vpxord 4660(%r9,%rax,1), %zmm17, %zmm16
    {evex} vpxord gnu_back(%rip), %zmm3, %zmm25
    {evex} vpxord %zmm9, %zmm31, %zmm20{%k5}
    {evex} vpxord 0(%rdi), %zmm12, %zmm17{%k6}
    {evex} vpxord 8128(%rsi), %zmm16, %zmm3{%k7}
    {evex} vpxord -129(%r11), %zmm25, %zmm9{%k1}
    {evex} vpxord 0(%r12), %zmm31, %zmm20{%k2}
    {evex} vpxord -64(%rsp), %zmm12, %zmm17{%k3}
    {evex} vpxord 1001(%r12), %zmm16, %zmm3{%k4}
    {evex} vpxord 0(%r9,%r15,2), %zmm25, %zmm9{%k5}
    {evex} vpxord 128(%rsp,%rsi,4), %zmm31, %zmm20{%k6}
    {evex} vpxord -2147483648(%r13,%rcx,8), %zmm12, %zmm17{%k7}
    {evex} vpxord gnu_fwd(%rip), %zmm16, %zmm3{%k1}
    {evex} vpxord %zmm25, %zmm9, %zmm31{%k2}{z}
    {evex} vpxord 0(%r14), %zmm20, %zmm12{%k3}{z}
    {evex} vpxord -8192(%rdi), %zmm17, %zmm16{%k4}{z}
    {evex} vpxord 2147483647(%r14), %zmm3, %zmm25{%k5}{z}
    {evex} vpxord 0(%rsp), %zmm9, %zmm31{%k6}{z}
    {evex} vpxord 8128(%r12), %zmm20, %zmm12{%k7}{z}
    {evex} vpxord 4660(%rsp), %zmm17, %zmm16{%k1}{z}
    {evex} vpxord 0(%rsp,%r9,1), %zmm3, %zmm25{%k2}{z}
    {evex} vpxord -64(%rbp,%rbp,2), %zmm9, %zmm31{%k3}{z}
    {evex} vpxord -129(%r12,%r12,4), %zmm20, %zmm12{%k4}{z}
    {evex} vpxord gnu_back(%rip), %zmm17, %zmm16{%k5}{z}
    {evex} vporq %xmm3, %xmm25, %xmm9
    {evex} vporq 0(%r15), %xmm31, %xmm20
    {evex} vporq 32(%r15), %xmm12, %xmm17
    {evex} vporq 1001(%rcx), %xmm16, %xmm3
    {evex} vporq 0(%r12), %xmm25, %xmm9
    {evex} vporq -2048(%rsp), %xmm31, %xmm20
    {evex} vporq -2147483648(%r12), %xmm12, %xmm17
    {evex} vporq 0(%r14,%rax,8), %xmm16, %xmm3
    {evex} vporq 2032(%rdi,%r15,1), %xmm25, %xmm9
    {evex} vporq 2147483647(%r15,%rsi,2), %xmm31, %xmm20
    {evex} vporq gnu_fwd(%rip), %xmm12, %xmm17
    {evex} vporq %xmm16, %xmm3, %xmm25{%k6}
    {evex} vporq 0(%rcx), %xmm9, %xmm31{%k7}
    {evex} vporq -16(%r8), %xmm20, %xmm12{%k1}
    {evex} vporq 4660(%rbp), %xmm17, %xmm16{%k2}
    {evex} vporq 0(%rsp), %xmm3, %xmm25{%k3}
    {evex} vporq 32(%r12), %xmm9, %xmm31{%k4}
    {evex} vporq -129(%rsp), %xmm20, %xmm12{%k5}
    {evex} vporq 0(%rsi,%rcx,4), %xmm17, %xmm16{%k6}
    {evex} vporq -2048(%rax,%r9,8), %xmm3, %xmm25{%k7}
    {evex} vporq 1001(%r9,%rbp,1), %xmm9, %xmm31{%k1}
    {evex} vporq gnu_back(%rip), %xmm20, %xmm12{%k2}
    {evex} vporq %xmm17, %xmm16, %xmm3{%k3}{z}
    {evex} vporq 0(%r8), %xmm25, %xmm9{%k4}{z}
    {evex} vporq 2032(%r13), %xmm31, %xmm20{%k5}{z}
    {evex} vporq -2147483648(%rdx), %xmm12, %xmm17{%k6}{z}
    {evex} vporq 0(%r12), %xmm16, %xmm3{%k7}{z}
    {evex} vporq -16(%rsp), %xmm25, %xmm9{%k1}{z}
    {evex} vporq 2147483647(%r12), %xmm31, %xmm20{%k2}{z}
    {evex} vporq 0(%r15,%r12,2), %xmm12, %xmm17{%k3}{z}
    {evex} vporq 32(%rsp,%rax,4), %xmm16, %xmm3{%k4}{z}
    {evex} vporq 4660(%r13,%r15,8), %xmm25, %xmm9{%k5}{z}
    {evex} vporq gnu_fwd(%rip), %xmm31, %xmm20{%k6}{z}
    {evex} vporq %ymm12, %ymm17, %ymm16
    {evex} vporq 0(%rdx), %ymm3, %ymm25
    {evex} vporq 64(%r9), %ymm9, %ymm31
    {evex} vporq -129(%rbx), %ymm20, %ymm12
    {evex} vporq 0(%rsp), %ymm17, %ymm16
    {evex} vporq -4096(%r12), %ymm3, %ymm25
    {evex} vporq 1001(%rsp), %ymm9, %ymm31
    {evex} vporq 0(%rax,%rsi,1), %ymm20, %ymm12
    {evex} vporq 4064(%rbp,%rcx,2), %ymm17, %ymm16
    {evex} vporq -2147483648(%r12,%r9,4), %ymm3, %ymm25
    {evex} vporq gnu_back(%rip), %ymm9, %ymm31
    {evex} vporq %ymm20, %ymm12, %ymm17{%k7}
    {evex} vporq 0(%r9), %ymm16, %ymm3{%k1}
    {evex} vporq -32(%r10), %ymm25, %ymm9{%k2}
    {evex} vporq 2147483647(%rsi), %ymm31, %ymm20{%k3}
    {evex} vporq 0(%r12), %ymm12, %ymm17{%k4}
    {evex} vporq 64(%rsp), %ymm16, %ymm3{%k5}
    {evex} vporq 4660(%r12), %ymm25, %ymm9{%k6}
    {evex} vporq 0(%r8,%rbp,8), %ymm31, %ymm20{%k7}
    {evex} vporq -4096(%rdi,%r12,1), %ymm12, %ymm17{%k1}
    {evex} vporq -129(%r15,%rax,2), %ymm16, %ymm3{%k2}
    {evex} vporq gnu_fwd(%rip), %ymm25, %ymm9{%k3}
    {evex} vporq %ymm31, %ymm20, %ymm12{%k4}{z}
    {evex} vporq 0(%rbx), %ymm17, %ymm16{%k5}{z}
    {evex} vporq 4064(%r11), %ymm3, %ymm25{%k6}{z}
    {evex} vporq 1001(%rdi), %ymm9, %ymm31{%k7}{z}
    {evex} vporq 0(%rsp), %ymm20, %ymm12{%k1}{z}
    {evex} vporq -32(%r12), %ymm17, %ymm16{%k2}{z}
    {evex} vporq -2147483648(%rsp), %ymm3, %ymm25{%k3}{z}
g75:
    {evex} vporq 0(%rcx,%r15,4), %ymm9, %ymm31{%k4}{z}
    {evex} vporq 64(%rax,%rsi,8), %ymm20, %ymm12{%k5}{z}
    {evex} vporq 2147483647(%r9,%rcx,1), %ymm17, %ymm16{%k6}{z}
    {evex} vporq gnu_back(%rip), %ymm3, %ymm25{%k7}{z}
    {evex} vporq %zmm9, %zmm31, %zmm20
    {evex} vporq 0(%r10), %zmm12, %zmm17
    {evex} vporq 128(%r14), %zmm16, %zmm3
    {evex} vporq 4660(%r15), %zmm25, %zmm9
    {evex} vporq 0(%r12), %zmm31, %zmm20
    {evex} vporq -8192(%rsp), %zmm12, %zmm17
    {evex} vporq -129(%r12), %zmm16, %zmm3
    {evex} vporq 0(%r12,%r9,2), %zmm25, %zmm9
    {evex} vporq 8128(%rsp,%rbp,4), %zmm31, %zmm20
    {evex} vporq 1001(%r13,%r12,8), %zmm12, %zmm17
    {evex} vporq gnu_fwd(%rip), %zmm16, %zmm3
    {evex} vporq %zmm25, %zmm9, %zmm31{%k1}
    {evex} vporq 0(%rsi), %zmm20, %zmm12{%k2}
    {evex} vporq -64(%rcx), %zmm17, %zmm16{%k3}
    {evex} vporq -2147483648(%r8), %zmm3, %zmm25{%k4}
    {evex} vporq 0(%rsp), %zmm9, %zmm31{%k5}
    {evex} vporq 128(%r12), %zmm20, %zmm12{%k6}
    {evex} vporq 2147483647(%rsp), %zmm17, %zmm16{%k7}
    {evex} vporq 0(%rdx,%rax,1), %zmm3, %zmm25{%k1}
    {evex} vporq -8192(%rbp,%r15,2), %zmm9, %zmm31{%k2}
    {evex} vporq 4660(%r12,%rsi,4), %zmm20, %zmm12{%k3}
    {evex} vporq gnu_back(%rip), %zmm17, %zmm16{%k4}
    {evex} vporq %zmm3, %zmm25, %zmm9{%k5}{z}
    {evex} vporq 0(%r11), %zmm31, %zmm20{%k6}{z}
    {evex} vporq 8128(%rbp), %zmm12, %zmm17{%k7}{z}
    {evex} vporq -129(%r13), %zmm16, %zmm3{%k1}{z}
    {evex} vporq 0(%r12), %zmm25, %zmm9{%k2}{z}
    {evex} vporq -64(%rsp), %zmm31, %zmm20{%k3}{z}
    {evex} vporq 1001(%r12), %zmm12, %zmm17{%k4}{z}
    {evex} vporq 0(%r9,%rcx,8), %zmm16, %zmm3{%k5}{z}
    {evex} vporq 128(%rdi,%r9,1), %zmm25, %zmm9{%k6}{z}
    {evex} vporq -2147483648(%r15,%rbp,2), %zmm31, %zmm20{%k7}{z}
    {evex} vporq gnu_fwd(%rip), %zmm12, %zmm17{%k1}{z}
    {evex} vpandq %xmm16, %xmm3, %xmm25
    {evex} vpandq 0(%rdi), %xmm9, %xmm31
    {evex} vpandq -2048(%rdx), %xmm20, %xmm12
    {evex} vpandq 2147483647(%r9), %xmm17, %xmm16
    {evex} vpandq 0(%rsp), %xmm3, %xmm25
    {evex} vpandq 2032(%r12), %xmm9, %xmm31
    {evex} vpandq 4660(%rsp), %xmm20, %xmm12
    {evex} vpandq 0(%rsp,%r12,4), %xmm17, %xmm16
    {evex} vpandq -16(%rax,%rax,8), %xmm3, %xmm25
    {evex} vpandq -129(%r9,%r15,1), %xmm9, %xmm31
    {evex} vpandq gnu_back(%rip), %xmm20, %xmm12
    {evex} vpandq %xmm17, %xmm16, %xmm3{%k2}
    {evex} vpandq 0(%r14), %xmm25, %xmm9{%k3}
    {evex} vpandq 32(%rbx), %xmm31, %xmm20{%k4}
    {evex} vpandq 1001(%r10), %xmm12, %xmm17{%k5}
    {evex} vpandq 0(%r12), %xmm16, %xmm3{%k6}
    {evex} vpandq -2048(%rsp), %xmm25, %xmm9{%k7}
    {evex} vpandq -2147483648(%r12), %xmm31, %xmm20{%k1}
    {evex} vpandq 0(%r14,%rsi,2), %xmm12, %xmm17{%k2}
    {evex} vpandq 2032(%rsp,%rcx,4), %xmm16, %xmm3{%k3}
    {evex} vpandq 2147483647(%r13,%r9,8), %xmm25, %xmm9{%k4}
    {evex} vpandq gnu_fwd(%rip), %xmm31, %xmm20{%k5}
    {evex} vpandq %xmm12, %xmm17, %xmm16{%k6}{z}
    {evex} vpandq 0(%r15), %xmm3, %xmm25{%k7}{z}
    {evex} vpandq -16(%rsi), %xmm9, %xmm31{%k1}{z}
    {evex} vpandq 4660(%r11), %xmm20, %xmm12{%k2}{z}
    {evex} vpandq 0(%rsp), %xmm17, %xmm16{%k3}{z}
    {evex} vpandq 32(%r12), %xmm3, %xmm25{%k4}{z}
    {evex} vpandq -129(%rsp), %xmm9, %xmm31{%k5}{z}
    {evex} vpandq 0(%rsi,%rbp,1), %xmm20, %xmm12{%k6}{z}
    {evex} vpandq -2048(%rbp,%r12,2), %xmm17, %xmm16{%k7}{z}
    {evex} vpandq 1001(%r12,%rax,4), %xmm3, %xmm25{%k1}{z}
    {evex} vpandq gnu_back(%rip), %xmm9, %xmm31{%k2}{z}
    {evex} vpandq %ymm20, %ymm12, %ymm17
    {evex} vpandq 0(%rcx), %ymm16, %ymm3
    {evex} vpandq -4096(%rdi), %ymm25, %ymm9
    {evex} vpandq -2147483648(%r14), %ymm31, %ymm20
    {evex} vpandq 0(%r12), %ymm12, %ymm17
    {evex} vpandq 4064(%rsp), %ymm16, %ymm3
    {evex} vpandq 2147483647(%r12), %ymm25, %ymm9
    {evex} vpandq 0(%r15,%r15,8), %ymm31, %ymm20
    {evex} vpandq -32(%rdi,%rsi,1), %ymm12, %ymm17
    {evex} vpandq 4660(%r15,%rcx,2), %ymm16, %ymm3
    {evex} vpandq gnu_fwd(%rip), %ymm25, %ymm9
    {evex} vpandq %ymm31, %ymm20, %ymm12{%k3}
    {evex} vpandq 0(%r8), %ymm17, %ymm16{%k4}
    {evex} vpandq 64(%r15), %ymm3, %ymm25{%k5}
    {evex} vpandq -129(%rcx), %ymm9, %ymm31{%k6}
    {evex} vpandq 0(%rsp), %ymm20, %ymm12{%k7}
    {evex} vpandq -4096(%r12), %ymm17, %ymm16{%k1}
    {evex} vpandq 1001(%rsp), %ymm3, %ymm25{%k2}
    {evex} vpandq 0(%rax,%r9,4), %ymm9, %ymm31{%k3}
    {evex} vpandq 4064(%rax,%rbp,8), %ymm20, %ymm12{%k4}
    {evex} vpandq -2147483648(%r9,%r12,1), %ymm17, %ymm16{%k5}
    {evex} vpandq gnu_back(%rip), %ymm3, %ymm25{%k6}
    {evex} vpandq %ymm9, %ymm31, %ymm20{%k7}{z}
    {evex} vpandq 0(%rdx), %ymm12, %ymm17{%k1}{z}
    {evex} vpandq -32(%r8), %ymm16, %ymm3{%k2}{z}
    {evex} vpandq 2147483647(%rbp), %ymm25, %ymm9{%k3}{z}
    {evex} vpandq 0(%r12), %ymm31, %ymm20{%k4}{z}
    {evex} vpandq 64(%rsp), %ymm12, %ymm17{%k5}{z}
    {evex} vpandq 4660(%r12), %ymm16, %ymm3{%k6}{z}
    {evex} vpandq 0(%r8,%rax,2), %ymm25, %ymm9{%k7}{z}
    {evex} vpandq -4096(%rsp,%r15,4), %ymm31, %ymm20{%k1}{z}
    {evex} vpandq -129(%r13,%rsi,8), %ymm12, %ymm17{%k2}{z}
    {evex} vpandq gnu_fwd(%rip), %ymm16, %ymm3{%k3}{z}
    {evex} vpandq %zmm25, %zmm9, %zmm31
    {evex} vpandq 0(%r9), %zmm20, %zmm12
    {evex} vpandq -8192(%r13), %zmm17, %zmm16
    {evex} vpandq 1001(%rdx), %zmm3, %zmm25
    {evex} vpandq 0(%rsp), %zmm9, %zmm31
    {evex} vpandq 8128(%r12), %zmm20, %zmm12
    {evex} vpandq -2147483648(%rsp), %zmm17, %zmm16
    {evex} vpandq 0(%rcx,%rcx,1), %zmm3, %zmm25
    {evex} vpandq -64(%rbp,%r9,2), %zmm9, %zmm31
    {evex} vpandq 2147483647(%r12,%rbp,4), %zmm20, %zmm12
    {evex} vpandq gnu_back(%rip), %zmm17, %zmm16
    {evex} vpandq %zmm3, %zmm25, %zmm9{%k4}
    {evex} vpandq 0(%rbx), %zmm31, %zmm20{%k5}
    {evex} vpandq 128(%r9), %zmm12, %zmm17{%k6}
    {evex} vpandq 4660(%rbx), %zmm16, %zmm3{%k7}
    {evex} vpandq 0(%r12), %zmm25, %zmm9{%k1}
    {evex} vpandq -8192(%rsp), %zmm31, %zmm20{%k2}
    {evex} vpandq -129(%r12), %zmm12, %zmm17{%k3}
    {evex} vpandq 0(%r12,%r12,8), %zmm16, %zmm3{%k4}
    {evex} vpandq 8128(%rdi,%rax,1), %zmm25, %zmm9{%k5}
    {evex} vpandq 1001(%r15,%r15,2), %zmm31, %zmm20{%k6}
    {evex} vpandq gnu_fwd(%rip), %zmm12, %zmm17{%k7}
    {evex} vpandq %zmm16, %zmm3, %zmm25{%k1}{z}
    {evex} vpandq 0(%r10), %zmm9, %zmm31{%k2}{z}
    {evex} vpandq -64(%r10), %zmm20, %zmm12{%k3}{z}
    {evex} vpandq -2147483648(%rsi), %zmm17, %zmm16{%k4}{z}
    {evex} vpandq 0(%rsp), %zmm3, %zmm25{%k5}{z}
    {evex} vpandq 128(%r12), %zmm9, %zmm31{%k6}{z}
    {evex} vpandq 2147483647(%rsp), %zmm20, %zmm12{%k7}{z}
    {evex} vpandq 0(%rdx,%rsi,4), %zmm17, %zmm16{%k1}{z}
    {evex} vpandq -8192(%rax,%rcx,8), %zmm3, %zmm25{%k2}{z}
    {evex} vpandq 4660(%r9,%r9,1), %zmm9, %zmm31{%k3}{z}
    {evex} vpandq gnu_back(%rip), %zmm20, %zmm12{%k4}{z}
    {evex} vpandnq %xmm17, %xmm16, %xmm3
    {evex} vpandnq 0(%rsi), %xmm25, %xmm9
    {evex} vpandnq 2032(%r11), %xmm31, %xmm20
    {evex} vpandnq -129(%rdi), %xmm12, %xmm17
    {evex} vpandnq 0(%r12), %xmm16, %xmm3
    {evex} vpandnq -16(%rsp), %xmm25, %xmm9
    {evex} vpandnq 1001(%r12), %xmm31, %xmm20
    {evex} vpandnq 0(%r9,%rbp,2), %xmm12, %xmm17
    {evex} vpandnq 32(%rsp,%r12,4), %xmm16, %xmm3
    {evex} vpandnq -2147483648(%r13,%rax,8), %xmm25, %xmm9
    {evex} vpandnq gnu_fwd(%rip), %xmm31, %xmm20
    {evex} vpandnq %xmm12, %xmm17, %xmm16{%k5}
    {evex} vpandnq 0(%r11), %xmm3, %xmm25{%k6}
    {evex} vpandnq -2048(%r14), %xmm9, %xmm31{%k7}
    {evex} vpandnq 2147483647(%r15), %xmm20, %xmm12{%k1}
    {evex} vpandnq 0(%rsp), %xmm17, %xmm16{%k2}
    {evex} vpandnq 2032(%r12), %xmm3, %xmm25{%k3}
    {evex} vpandnq 4660(%rsp), %xmm9, %xmm31{%k4}
    {evex} vpandnq 0(%rsp,%r15,1), %xmm20, %xmm12{%k5}
    {evex} vpandnq -16(%rbp,%rsi,2), %xmm17, %xmm16{%k6}
    {evex} vpandnq -129(%r12,%rcx,4), %xmm3, %xmm25{%k7}
    {evex} vpandnq gnu_back(%rip), %xmm9, %xmm31{%k1}
    {evex} vpandnq %xmm20, %xmm12, %xmm17{%k2}{z}
    {evex} vpandnq 0(%rdi), %xmm16, %xmm3{%k3}{z}
    {evex} vpandnq 32(%rcx), %xmm25, %xmm9{%k4}{z}
    {evex} vpandnq 1001(%r8), %xmm31, %xmm20{%k5}{z}
    {evex} vpandnq 0(%r12), %xmm12, %xmm17{%k6}{z}
    {evex} vpandnq -2048(%rsp), %xmm16, %xmm3{%k7}{z}
    {evex} vpandnq -2147483648(%r12), %xmm25, %xmm9{%k1}{z}
    {evex} vpandnq 0(%r14,%r9,8), %xmm31, %xmm20{%k2}{z}
    {evex} vpandnq 2032(%rdi,%rbp,1), %xmm12, %xmm17{%k3}{z}
    {evex} vpandnq 2147483647(%r15,%r12,2), %xmm16, %xmm3{%k4}{z}
    {evex} vpandnq gnu_fwd(%rip), %xmm25, %xmm9{%k5}{z}
    {evex} vpandnq %ymm31, %ymm20, %ymm12
    {evex} vpandnq 0(%r14), %ymm17, %ymm16
    {evex} vpandnq 4064(%rbp), %ymm3, %ymm25
    {evex} vpandnq 4660(%r13), %ymm9, %ymm31
    {evex} vpandnq 0(%rsp), %ymm20, %ymm12
    {evex} vpandnq -32(%r12), %ymm17, %ymm16
    {evex} vpandnq -129(%rsp), %ymm3, %ymm25
    {evex} vpandnq 0(%rsi,%rax,4), %ymm9, %ymm31
    {evex} vpandnq 64(%rax,%r15,8), %ymm20, %ymm12
    {evex} vpandnq 1001(%r9,%rsi,1), %ymm17, %ymm16
    {evex} vpandnq gnu_back(%rip), %ymm3, %ymm25
    {evex} vpandnq %ymm9, %ymm31, %ymm20{%k6}
    {evex} vpandnq 0(%r15), %ymm12, %ymm17{%k7}
    {evex} vpandnq -4096(%rdx), %ymm16, %ymm3{%k1}
    {evex} vpandnq -2147483648(%r9), %ymm25, %ymm9{%k2}
    {evex} vpandnq 0(%r12), %ymm31, %ymm20{%k3}
    {evex} vpandnq 4064(%rsp), %ymm12, %ymm17{%k4}
    {evex} vpandnq 2147483647(%r12), %ymm16, %ymm3{%k5}
    {evex} vpandnq 0(%r15,%rcx,2), %ymm25, %ymm9{%k6}
    {evex} vpandnq -32(%rsp,%r9,4), %ymm31, %ymm20{%k7}
    {evex} vpandnq 4660(%r13,%rbp,8), %ymm12, %ymm17{%k1}
    {evex} vpandnq gnu_fwd(%rip), %ymm16, %ymm3{%k2}
    {evex} vpandnq %ymm25, %ymm9, %ymm31{%k3}{z}
    {evex} vpandnq 0(%rcx), %ymm20, %ymm12{%k4}{z}
    {evex} vpandnq 64(%rbx), %ymm17, %ymm16{%k5}{z}
    {evex} vpandnq -129(%r10), %ymm3, %ymm25{%k6}{z}
    {evex} vpandnq 0(%rsp), %ymm9, %ymm31{%k7}{z}
    {evex} vpandnq -4096(%r12), %ymm20, %ymm12{%k1}{z}
    {evex} vpandnq 1001(%rsp), %ymm17, %ymm16{%k2}{z}
    {evex} vpandnq 0(%rax,%r12,1), %ymm3, %ymm25{%k3}{z}
    {evex} vpandnq 4064(%rbp,%rax,2), %ymm9, %ymm31{%k4}{z}
g76:
    {evex} vpandnq -2147483648(%r12,%r15,4), %ymm20, %ymm12{%k5}{z}
    {evex} vpandnq gnu_back(%rip), %ymm17, %ymm16{%k6}{z}
    {evex} vpandnq %zmm3, %zmm25, %zmm9
    {evex} vpandnq 0(%r8), %zmm31, %zmm20
    {evex} vpandnq 8128(%rsi), %zmm12, %zmm17
    {evex} vpandnq 2147483647(%r11), %zmm16, %zmm3
    {evex} vpandnq 0(%r12), %zmm25, %zmm9
    {evex} vpandnq -64(%rsp), %zmm31, %zmm20
    {evex} vpandnq 4660(%r12), %zmm12, %zmm17
    {evex} vpandnq 0(%r8,%rsi,8), %zmm16, %zmm3
    {evex} vpandnq 128(%rdi,%rcx,1), %zmm25, %zmm9
    {evex} vpandnq -129(%r15,%r9,2), %zmm31, %zmm20
    {evex} vpandnq gnu_fwd(%rip), %zmm12, %zmm17
    {evex} vpandnq %zmm16, %zmm3, %zmm25{%k7}
    {evex} vpandnq 0(%rdx), %zmm9, %zmm31{%k1}
    {evex} vpandnq -8192(%rdi), %zmm20, %zmm12{%k2}
    {evex} vpandnq 1001(%r14), %zmm17, %zmm16{%k3}
    {evex} vpandnq 0(%rsp), %zmm3, %zmm25{%k4}
    {evex} vpandnq 8128(%r12), %zmm9, %zmm31{%k5}
    {evex} vpandnq -2147483648(%rsp), %zmm20, %zmm12{%k6}
    {evex} vpandnq 0(%rcx,%rbp,4), %zmm17, %zmm16{%k7}
    {evex} vpandnq -64(%rax,%r12,8), %zmm3, %zmm25{%k1}
    {evex} vpandnq 2147483647(%r9,%rax,1), %zmm9, %zmm31{%k2}
    {evex} vpandnq gnu_back(%rip), %zmm20, %zmm12{%k3}
    {evex} vpandnq %zmm17, %zmm16, %zmm3{%k4}{z}
    {evex} vpandnq 0(%r9), %zmm25, %zmm9{%k5}{z}
    {evex} vpandnq 128(%r15), %zmm31, %zmm20{%k6}{z}
    {evex} vpandnq 4660(%rcx), %zmm12, %zmm17{%k7}{z}
    {evex} vpandnq 0(%r12), %zmm16, %zmm3{%k1}{z}
    {evex} vpandnq -8192(%rsp), %zmm25, %zmm9{%k2}{z}
    {evex} vpandnq -129(%r12), %zmm31, %zmm20{%k3}{z}
    {evex} vpandnq 0(%r12,%r15,2), %zmm12, %zmm17{%k4}{z}
    {evex} vpandnq 8128(%rsp,%rsi,4), %zmm16, %zmm3{%k5}{z}
    {evex} vpandnq 1001(%r13,%rcx,8), %zmm25, %zmm9{%k6}{z}
    {evex} vpandnq gnu_fwd(%rip), %zmm31, %zmm20{%k7}{z}
    {evex} vpshufb %xmm12, %xmm17, %xmm16
    {evex} vpshufb 0(%rbx), %xmm3, %xmm25
    {evex} vpshufb -16(%r8), %xmm9, %xmm31
    {evex} vpshufb -2147483648(%rbp), %xmm20, %xmm12
    {evex} vpshufb 0(%rsp), %xmm17, %xmm16
    {evex} vpshufb 32(%r12), %xmm3, %xmm25
    {evex} vpshufb 2147483647(%rsp), %xmm9, %xmm31
    {evex} vpshufb 0(%rdx,%r9,1), %xmm20, %xmm12
    {evex} vpshufb -2048(%rbp,%rbp,2), %xmm17, %xmm16
    {evex} vpshufb 4660(%r12,%r12,4), %xmm3, %xmm25
    {evex} vpshufb gnu_back(%rip), %xmm9, %xmm31
    {evex} vpshufb %xmm20, %xmm12, %xmm17{%k1}
    {evex} vpshufb 0(%r10), %xmm16, %xmm3{%k2}
    {evex} vpshufb 2032(%r13), %xmm25, %xmm9{%k3}
    {evex} vpshufb -129(%rdx), %xmm31, %xmm20{%k4}
    {evex} vpshufb 0(%r12), %xmm12, %xmm17{%k5}
    {evex} vpshufb -16(%rsp), %xmm16, %xmm3{%k6}
    {evex} vpshufb 1001(%r12), %xmm25, %xmm9{%k7}
    {evex} vpshufb 0(%r9,%rax,8), %xmm31, %xmm20{%k1}
    {evex} vpshufb 32(%rdi,%r15,1), %xmm12, %xmm17{%k2}
    {evex} vpshufb -2147483648(%r15,%rsi,2), %xmm16, %xmm3{%k3}
    {evex} vpshufb gnu_fwd(%rip), %xmm25, %xmm9{%k4}
    {evex} vpshufb %xmm31, %xmm20, %xmm12{%k5}{z}
    {evex} vpshufb 0(%rsi), %xmm17, %xmm16{%k6}{z}
    {evex} vpshufb -2048(%r9), %xmm3, %xmm25{%k7}{z}
    {evex} vpshufb 2147483647(%rbx), %xmm9, %xmm31{%k1}{z}
    {evex} vpshufb 0(%rsp), %xmm20, %xmm12{%k2}{z}
    {evex} vpshufb 2032(%r12), %xmm17, %xmm16{%k3}{z}
    {evex} vpshufb 4660(%rsp), %xmm3, %xmm25{%k4}{z}
    {evex} vpshufb 0(%rsp,%rcx,4), %xmm9, %xmm31{%k5}{z}
    {evex} vpshufb -16(%rax,%r9,8), %xmm20, %xmm12{%k6}{z}
    {evex} vpshufb -129(%r9,%rbp,1), %xmm17, %xmm16{%k7}{z}
    {evex} vpshufb gnu_back(%rip), %xmm3, %xmm25{%k1}{z}
    {evex} vpshufb %ymm9, %ymm31, %ymm20
    {evex} vpshufb 0(%r11), %ymm12, %ymm17
    {evex} vpshufb -32(%r10), %ymm16, %ymm3
    {evex} vpshufb 1001(%rsi), %ymm25, %ymm9
    {evex} vpshufb 0(%r12), %ymm31, %ymm20
    {evex} vpshufb 64(%rsp), %ymm12, %ymm17
    {evex} vpshufb -2147483648(%r12), %ymm16, %ymm3
    {evex} vpshufb 0(%r14,%r12,2), %ymm25, %ymm9
    {evex} vpshufb -4096(%rsp,%rax,4), %ymm31, %ymm20
    {evex} vpshufb 2147483647(%r13,%r15,8), %ymm12, %ymm17
    {evex} vpshufb gnu_fwd(%rip), %ymm16, %ymm3
    {evex} vpshufb %ymm25, %ymm9, %ymm31{%k2}
    {evex} vpshufb 0(%rdi), %ymm20, %ymm12{%k3}
    {evex} vpshufb 4064(%r11), %ymm17, %ymm16{%k4}
    {evex} vpshufb 4660(%rdi), %ymm3, %ymm25{%k5}
    {evex} vpshufb 0(%rsp), %ymm9, %ymm31{%k6}
    {evex} vpshufb -32(%r12), %ymm20, %ymm12{%k7}
    {evex} vpshufb -129(%rsp), %ymm17, %ymm16{%k1}
    {evex} vpshufb 0(%rsi,%rsi,1), %ymm3, %ymm25{%k2}
    {evex} vpshufb 64(%rbp,%rcx,2), %ymm9, %ymm31{%k3}
    {evex} vpshufb 1001(%r12,%r9,4), %ymm20, %ymm12{%k4}
    {evex} vpshufb gnu_back(%rip), %ymm17, %ymm16{%k5}
    {evex} vpshufb %ymm3, %ymm25, %ymm9{%k6}{z}
    {evex} vpshufb 0(%r14), %ymm31, %ymm20{%k7}{z}
    {evex} vpshufb -4096(%r14), %ymm12, %ymm17{%k1}{z}
    {evex} vpshufb -2147483648(%r15), %ymm16, %ymm3{%k2}{z}
    {evex} vpshufb 0(%r12), %ymm25, %ymm9{%k3}{z}
    {evex} vpshufb 4064(%rsp), %ymm31, %ymm20{%k4}{z}
    {evex} vpshufb 2147483647(%r12), %ymm12, %ymm17{%k5}{z}
    {evex} vpshufb 0(%r15,%rbp,8), %ymm16, %ymm3{%k6}{z}
    {evex} vpshufb -32(%rdi,%r12,1), %ymm25, %ymm9{%k7}{z}
    {evex} vpshufb 4660(%r15,%rax,2), %ymm31, %ymm20{%k1}{z}
    {evex} vpshufb gnu_fwd(%rip), %ymm12, %ymm17{%k2}{z}
    {evex} vpshufb %zmm16, %zmm3, %zmm25
    {evex} vpshufb 0(%r15), %zmm9, %zmm31
    {evex} vpshufb -64(%rcx), %zmm20, %zmm12
    {evex} vpshufb -129(%r8), %zmm17, %zmm16
    {evex} vpshufb 0(%rsp), %zmm3, %zmm25
    {evex} vpshufb 128(%r12), %zmm9, %zmm31
    {evex} vpshufb 1001(%rsp), %zmm20, %zmm12
    {evex} vpshufb 0(%rax,%r15,4), %zmm17, %zmm16
    {evex} vpshufb -8192(%rax,%rsi,8), %zmm3, %zmm25
    {evex} vpshufb -2147483648(%r9,%rcx,1), %zmm9, %zmm31
    {evex} vpshufb gnu_back(%rip), %zmm20, %zmm12
    {evex} vpshufb %zmm17, %zmm16, %zmm3{%k3}
    {evex} vpshufb 0(%rcx), %zmm25, %zmm9{%k4}
    {evex} vpshufb 8128(%rbp), %zmm31, %zmm20{%k5}
    {evex} vpshufb 2147483647(%r13), %zmm12, %zmm17{%k6}
    {evex} vpshufb 0(%r12), %zmm16, %zmm3{%k7}
    {evex} vpshufb -64(%rsp), %zmm25, %zmm9{%k1}
    {evex} vpshufb 4660(%r12), %zmm31, %zmm20{%k2}
    {evex} vpshufb 0(%r8,%r9,2), %zmm12, %zmm17{%k3}
    {evex} vpshufb 128(%rsp,%rbp,4), %zmm16, %zmm3{%k4}
    {evex} vpshufb -129(%r13,%r12,8), %zmm25, %zmm9{%k5}
    {evex} vpshufb gnu_fwd(%rip), %zmm31, %zmm20{%k6}
    {evex} vpshufb %zmm12, %zmm17, %zmm16{%k7}{z}
    {evex} vpshufb 0(%r8), %zmm3, %zmm25{%k1}{z}
    {evex} vpshufb -8192(%rdx), %zmm9, %zmm31{%k2}{z}
    {evex} vpshufb 1001(%r9), %zmm20, %zmm12{%k3}{z}
    {evex} vpshufb 0(%rsp), %zmm17, %zmm16{%k4}{z}
    {evex} vpshufb 8128(%r12), %zmm3, %zmm25{%k5}{z}
    {evex} vpshufb -2147483648(%rsp), %zmm9, %zmm31{%k6}{z}
    {evex} vpshufb 0(%rcx,%rax,1), %zmm20, %zmm12{%k7}{z}
    {evex} vpshufb -64(%rbp,%r15,2), %zmm17, %zmm16{%k1}{z}
    {evex} vpshufb 2147483647(%r12,%rsi,4), %zmm3, %zmm25{%k2}{z}
    {evex} vpshufb gnu_back(%rip), %zmm9, %zmm31{%k3}{z}
    {evex} vpternlogd $63, %xmm20, %xmm12, %xmm17
    {evex} vpternlogd $7, 0(%rdx), %xmm16, %xmm3
    {evex} vpternlogd $0, 32(%rbx), %xmm25, %xmm9
    {evex} vpternlogd $255, 4660(%r10), %xmm31, %xmm20
    {evex} vpternlogd $63, 0(%r12), %xmm12, %xmm17
    {evex} vpternlogd $7, -2048(%rsp), %xmm16, %xmm3
    {evex} vpternlogd $0, -129(%r12), %xmm25, %xmm9
    {evex} vpternlogd $255, 0(%r12,%rcx,8), %xmm31, %xmm20
    {evex} vpternlogd $63, 2032(%rdi,%r9,1), %xmm12, %xmm17
    {evex} vpternlogd $7, 1001(%r15,%rbp,2), %xmm16, %xmm3
    {evex} vpternlogd $0, gnu_fwd(%rip), %xmm25, %xmm9
    {evex} vpternlogd $255, %xmm31, %xmm20, %xmm12{%k4}
    {evex} vpternlogd $63, 0(%r9), %xmm17, %xmm16{%k5}
    {evex} vpternlogd $7, -16(%rsi), %xmm3, %xmm25{%k6}
    {evex} vpternlogd $0, -2147483648(%r11), %xmm9, %xmm31{%k7}
    {evex} vpternlogd $255, 0(%rsp), %xmm20, %xmm12{%k1}
    {evex} vpternlogd $63, 32(%r12), %xmm17, %xmm16{%k2}
    {evex} vpternlogd $7, 2147483647(%rsp), %xmm3, %xmm25{%k3}
    {evex} vpternlogd $0, 0(%rdx,%r12,4), %xmm9, %xmm31{%k4}
    {evex} vpternlogd $255, -2048(%rax,%rax,8), %xmm20, %xmm12{%k5}
    {evex} vpternlogd $63, 4660(%r9,%r15,1), %xmm17, %xmm16{%k6}
    {evex} vpternlogd $7, gnu_back(%rip), %xmm3, %xmm25{%k7}
    {evex} vpternlogd $0, %xmm9, %xmm31, %xmm20{%k1}{z}
    {evex} vpternlogd $255, 0(%rbx), %xmm12, %xmm17{%k2}{z}
    {evex} vpternlogd $63, 2032(%rdi), %xmm16, %xmm3{%k3}{z}
    {evex} vpternlogd $7, -129(%r14), %xmm25, %xmm9{%k4}{z}
    {evex} vpternlogd $0, 0(%r12), %xmm31, %xmm20{%k5}{z}
    {evex} vpternlogd $255, -16(%rsp), %xmm12, %xmm17{%k6}{z}
    {evex} vpternlogd $63, 1001(%r12), %xmm16, %xmm3{%k7}{z}
    {evex} vpternlogd $7, 0(%r9,%rsi,2), %xmm25, %xmm9{%k1}{z}
    {evex} vpternlogd $0, 32(%rsp,%rcx,4), %xmm31, %xmm20{%k2}{z}
    {evex} vpternlogd $255, -2147483648(%r13,%r9,8), %xmm12, %xmm17{%k3}{z}
    {evex} vpternlogd $63, gnu_fwd(%rip), %xmm16, %xmm3{%k4}{z}
    {evex} vpternlogd $7, %ymm25, %ymm9, %ymm31
    {evex} vpternlogd $0, 0(%r10), %ymm20, %ymm12
    {evex} vpternlogd $255, 64(%r15), %ymm17, %ymm16
    {evex} vpternlogd $63, 2147483647(%rcx), %ymm3, %ymm25
    {evex} vpternlogd $7, 0(%rsp), %ymm9, %ymm31
    {evex} vpternlogd $0, -4096(%r12), %ymm20, %ymm12
    {evex} vpternlogd $255, 4660(%rsp), %ymm17, %ymm16
    {evex} vpternlogd $63, 0(%rsp,%rbp,1), %ymm3, %ymm25
    {evex} vpternlogd $7, 4064(%rbp,%r12,2), %ymm9, %ymm31
    {evex} vpternlogd $0, -129(%r12,%rax,4), %ymm20, %ymm12
    {evex} vpternlogd $255, gnu_back(%rip), %ymm17, %ymm16
    {evex} vpternlogd $63, %ymm3, %ymm25, %ymm9{%k5}
    {evex} vpternlogd $7, 0(%rsi), %ymm31, %ymm20{%k6}
    {evex} vpternlogd $0, -32(%r8), %ymm12, %ymm17{%k7}
    {evex} vpternlogd $255, 1001(%rbp), %ymm16, %ymm3{%k1}
    {evex} vpternlogd $63, 0(%r12), %ymm25, %ymm9{%k2}
    {evex} vpternlogd $7, 64(%rsp), %ymm31, %ymm20{%k3}
    {evex} vpternlogd $0, -2147483648(%r12), %ymm12, %ymm17{%k4}
    {evex} vpternlogd $255, 0(%r14,%r15,8), %ymm16, %ymm3{%k5}
    {evex} vpternlogd $63, -4096(%rdi,%rsi,1), %ymm25, %ymm9{%k6}
    {evex} vpternlogd $7, 2147483647(%r15,%rcx,2), %ymm31, %ymm20{%k7}
    {evex} vpternlogd $0, gnu_fwd(%rip), %ymm12, %ymm17{%k1}
    {evex} vpternlogd $255, %ymm16, %ymm3, %ymm25{%k2}{z}
    {evex} vpternlogd $63, 0(%r11), %ymm9, %ymm31{%k3}{z}
    {evex} vpternlogd $7, 4064(%r13), %ymm20, %ymm12{%k4}{z}
    {evex} vpternlogd $0, 4660(%rdx), %ymm17, %ymm16{%k5}{z}
    {evex} vpternlogd $255, 0(%rsp), %ymm3, %ymm25{%k6}{z}
    {evex} vpternlogd $63, -32(%r12), %ymm9, %ymm31{%k7}{z}
    {evex} vpternlogd $7, -129(%rsp), %ymm20, %ymm12{%k1}{z}
    {evex} vpternlogd $0, 0(%rsi,%r9,4), %ymm17, %ymm16{%k2}{z}
    {evex} vpternlogd $255, 64(%rax,%rbp,8), %ymm3, %ymm25{%k3}{z}
    {evex} vpternlogd $63, 1001(%r9,%r12,1), %ymm9, %ymm31{%k4}{z}
    {evex} vpternlogd $7, gnu_back(%rip), %ymm20, %ymm12{%k5}{z}
g77:
    {evex} vpternlogd $0, %zmm17, %zmm16, %zmm3
    {evex} vpternlogd $255, 0(%rdi), %zmm25, %zmm9
    {evex} vpternlogd $63, 128(%r9), %zmm31, %zmm20
    {evex} vpternlogd $7, -2147483648(%rbx), %zmm12, %zmm17
    {evex} vpternlogd $0, 0(%r12), %zmm16, %zmm3
    {evex} vpternlogd $255, -8192(%rsp), %zmm25, %zmm9
    {evex} vpternlogd $63, 2147483647(%r12), %zmm31, %zmm20
    {evex} vpternlogd $7, 0(%r15,%rax,2), %zmm12, %zmm17
    {evex} vpternlogd $0, 8128(%rsp,%r15,4), %zmm16, %zmm3
    {evex} vpternlogd $255, 4660(%r13,%rsi,8), %zmm25, %zmm9
    {evex} vpternlogd $63, gnu_fwd(%rip), %zmm31, %zmm20
    {evex} vpternlogd $7, %zmm12, %zmm17, %zmm16{%k6}
    {evex} vpternlogd $0, 0(%r14), %zmm3, %zmm25{%k7}
    {evex} vpternlogd $255, -64(%r10), %zmm9, %zmm31{%k1}
    {evex} vpternlogd $63, -129(%rsi), %zmm20, %zmm12{%k2}
    {evex} vpternlogd $7, 0(%rsp), %zmm17, %zmm16{%k3}
    {evex} vpternlogd $0, 128(%r12), %zmm3, %zmm25{%k4}
    {evex} vpternlogd $255, 1001(%rsp), %zmm9, %zmm31{%k5}
    {evex} vpternlogd $63, 0(%rax,%rcx,1), %zmm20, %zmm12{%k6}
    {evex} vpternlogd $7, -8192(%rbp,%r9,2), %zmm17, %zmm16{%k7}
    {evex} vpternlogd $0, -2147483648(%r12,%rbp,4), %zmm3, %zmm25{%k1}
    {evex} vpternlogd $255, gnu_back(%rip), %zmm9, %zmm31{%k2}
    {evex} vpternlogd $63, %zmm20, %zmm12, %zmm17{%k3}{z}
    {evex} vpternlogd $7, 0(%r15), %zmm16, %zmm3{%k4}{z}
    {evex} vpternlogd $0, 8128(%r11), %zmm25, %zmm9{%k5}{z}
    {evex} vpternlogd $255, 2147483647(%rdi), %zmm31, %zmm20{%k6}{z}
    {evex} vpternlogd $63, 0(%r12), %zmm12, %zmm17{%k7}{z}
    {evex} vpternlogd $7, -64(%rsp), %zmm16, %zmm3{%k1}{z}
    {evex} vpternlogd $0, 4660(%r12), %zmm25, %zmm9{%k2}{z}
    {evex} vpternlogd $255, 0(%r8,%r12,8), %zmm31, %zmm20{%k3}{z}
    {evex} vpternlogd $63, 128(%rdi,%rax,1), %zmm12, %zmm17{%k4}{z}
    {evex} vpternlogd $7, -129(%r15,%r15,2), %zmm16, %zmm3{%k5}{z}
    {evex} vpternlogd $0, gnu_fwd(%rip), %zmm25, %zmm9{%k6}{z}
    {evex} vpbroadcastb %xmm31, %xmm20
    {evex} vpbroadcastb 0(%rcx), %xmm12
    {evex} vpbroadcastb -128(%r14), %xmm17
    {evex} vpbroadcastb 1001(%r15), %xmm16
    {evex} vpbroadcastb 0(%rsp), %xmm3
    {evex} vpbroadcastb 127(%r12), %xmm25
    {evex} vpbroadcastb -2147483648(%rsp), %xmm9
    {evex} vpbroadcastb 0(%rcx,%rsi,4), %xmm31
    {evex} vpbroadcastb -1(%rax,%rcx,8), %xmm20
    {evex} vpbroadcastb 2147483647(%r9,%r9,1), %xmm12
    {evex} vpbroadcastb gnu_back(%rip), %xmm17
    {evex} vpbroadcastb %xmm16, %xmm3{%k7}
    {evex} vpbroadcastb 0(%r8), %xmm25{%k1}
    {evex} vpbroadcastb 2(%rcx), %xmm9{%k2}
    {evex} vpbroadcastb 4660(%r8), %xmm31{%k3}
    {evex} vpbroadcastb 0(%r12), %xmm20{%k4}
    {evex} vpbroadcastb -128(%rsp), %xmm12{%k5}
    {evex} vpbroadcastb -129(%r12), %xmm17{%k6}
    {evex} vpbroadcastb 0(%r12,%rbp,2), %xmm16{%k7}
    {evex} vpbroadcastb 127(%rsp,%r12,4), %xmm3{%k1}
    {evex} vpbroadcastb 1001(%r13,%rax,8), %xmm25{%k2}
    {evex} vpbroadcastb gnu_fwd(%rip), %xmm9{%k3}
    {evex} vpbroadcastb %xmm31, %xmm20{%k4}{z}
    {evex} vpbroadcastb 0(%rdx), %xmm12{%k5}{z}
    {evex} vpbroadcastb -1(%rbp), %xmm17{%k6}{z}
    {evex} vpbroadcastb -2147483648(%r13), %xmm16{%k7}{z}
    {evex} vpbroadcastb 0(%rsp), %xmm3{%k1}{z}
    {evex} vpbroadcastb 2(%r12), %xmm25{%k2}{z}
    {evex} vpbroadcastb 2147483647(%rsp), %xmm9{%k3}{z}
    {evex} vpbroadcastb 0(%rdx,%r15,1), %xmm31{%k4}{z}
    {evex} vpbroadcastb -128(%rbp,%rsi,2), %xmm20{%k5}{z}
    {evex} vpbroadcastb 4660(%r12,%rcx,4), %xmm12{%k6}{z}
    {evex} vpbroadcastb gnu_back(%rip), %xmm17{%k7}{z}
    {evex} vpbroadcastb %xmm16, %ymm3
    {evex} vpbroadcastb 0(%r9), %ymm25
    {evex} vpbroadcastb 127(%rdx), %ymm9
    {evex} vpbroadcastb -129(%r9), %ymm31
    {evex} vpbroadcastb 0(%r12), %ymm20
    {evex} vpbroadcastb -1(%rsp), %ymm12
    {evex} vpbroadcastb 1001(%r12), %ymm17
    {evex} vpbroadcastb 0(%r9,%r9,8), %ymm16
    {evex} vpbroadcastb 2(%rdi,%rbp,1), %ymm3
    {evex} vpbroadcastb -2147483648(%r15,%r12,2), %ymm25
    {evex} vpbroadcastb gnu_fwd(%rip), %ymm9
    {evex} vpbroadcastb %xmm31, %ymm20{%k1}
    {evex} vpbroadcastb 0(%rbx), %ymm12{%k2}
    {evex} vpbroadcastb -128(%rbx), %ymm17{%k3}
    {evex} vpbroadcastb 2147483647(%r10), %ymm16{%k4}
    {evex} vpbroadcastb 0(%rsp), %ymm3{%k5}
    {evex} vpbroadcastb 127(%r12), %ymm25{%k6}
    {evex} vpbroadcastb 4660(%rsp), %ymm9{%k7}
    {evex} vpbroadcastb 0(%rsp,%rax,4), %ymm31{%k1}
    {evex} vpbroadcastb -1(%rax,%r15,8), %ymm20{%k2}
    {evex} vpbroadcastb -129(%r9,%rsi,1), %ymm12{%k3}
    {evex} vpbroadcastb gnu_back(%rip), %ymm17{%k4}
    {evex} vpbroadcastb %xmm16, %ymm3{%k5}{z}
    {evex} vpbroadcastb 0(%r10), %ymm25{%k6}{z}
    {evex} vpbroadcastb 2(%rsi), %ymm9{%k7}{z}
    {evex} vpbroadcastb 1001(%r11), %ymm31{%k1}{z}
    {evex} vpbroadcastb 0(%r12), %ymm20{%k2}{z}
    {evex} vpbroadcastb -128(%rsp), %ymm12{%k3}{z}
    {evex} vpbroadcastb -2147483648(%r12), %ymm17{%k4}{z}
    {evex} vpbroadcastb 0(%r14,%rcx,2), %ymm16{%k5}{z}
    {evex} vpbroadcastb 127(%rsp,%r9,4), %ymm3{%k6}{z}
    {evex} vpbroadcastb 2147483647(%r13,%rbp,8), %ymm25{%k7}{z}
    {evex} vpbroadcastb gnu_fwd(%rip), %ymm9{%k1}{z}
    {evex} vpbroadcastb %xmm31, %zmm20
    {evex} vpbroadcastb 0(%rsi), %zmm12
    {evex} vpbroadcastb -1(%rdi), %zmm17
    {evex} vpbroadcastb 4660(%r14), %zmm16
    {evex} vpbroadcastb 0(%rsp), %zmm3
    {evex} vpbroadcastb 2(%r12), %zmm25
    {evex} vpbroadcastb -129(%rsp), %zmm9
    {evex} vpbroadcastb 0(%rsi,%r12,1), %zmm31
    {evex} vpbroadcastb -128(%rbp,%rax,2), %zmm20
    {evex} vpbroadcastb 1001(%r12,%r15,4), %zmm12
    {evex} vpbroadcastb gnu_back(%rip), %zmm17
    {evex} vpbroadcastb %xmm16, %zmm3{%k2}
    {evex} vpbroadcastb 0(%r11), %zmm25{%k3}
    {evex} vpbroadcastb 127(%r15), %zmm9{%k4}
    {evex} vpbroadcastb -2147483648(%rcx), %zmm31{%k5}
    {evex} vpbroadcastb 0(%r12), %zmm20{%k6}
    {evex} vpbroadcastb -1(%rsp), %zmm12{%k7}
    {evex} vpbroadcastb 2147483647(%r12), %zmm17{%k1}
    {evex} vpbroadcastb 0(%r15,%rsi,8), %zmm16{%k2}
    {evex} vpbroadcastb 2(%rdi,%rcx,1), %zmm3{%k3}
    {evex} vpbroadcastb 4660(%r15,%r9,2), %zmm25{%k4}
    {evex} vpbroadcastb gnu_fwd(%rip), %zmm9{%k5}
    {evex} vpbroadcastb %xmm31, %zmm20{%k6}{z}
    {evex} vpbroadcastb 0(%rdi), %zmm12{%k7}{z}
    {evex} vpbroadcastb -128(%r8), %zmm17{%k1}{z}
    {evex} vpbroadcastb -129(%rbp), %zmm16{%k2}{z}
    {evex} vpbroadcastb 0(%rsp), %zmm3{%k3}{z}
    {evex} vpbroadcastb 127(%r12), %zmm25{%k4}{z}
    {evex} vpbroadcastb 1001(%rsp), %zmm9{%k5}{z}
    {evex} vpbroadcastb 0(%rax,%rbp,4), %zmm31{%k6}{z}
    {evex} vpbroadcastb -1(%rax,%r12,8), %zmm20{%k7}{z}
    {evex} vpbroadcastb -2147483648(%r9,%rax,1), %zmm12{%k1}{z}
    {evex} vpbroadcastb gnu_back(%rip), %zmm17{%k2}{z}
    {evex} vpbroadcastd %xmm16, %xmm3
    {evex} vpbroadcastd 0(%r14), %xmm25
    {evex} vpbroadcastd -4(%r13), %xmm9
    {evex} vpbroadcastd 2147483647(%rdx), %xmm31
    {evex} vpbroadcastd 0(%r12), %xmm20
    {evex} vpbroadcastd 8(%rsp), %xmm12
    {evex} vpbroadcastd 4660(%r12), %xmm17
    {evex} vpbroadcastd 0(%r8,%r15,2), %xmm16
    {evex} vpbroadcastd -512(%rsp,%rsi,4), %xmm3
    {evex} vpbroadcastd -129(%r13,%rcx,8), %xmm25
    {evex} vpbroadcastd gnu_fwd(%rip), %xmm9
    {evex} vpbroadcastd %xmm31, %xmm20{%k3}
    {evex} vpbroadcastd 0(%r15), %xmm12{%k4}
    {evex} vpbroadcastd 508(%r9), %xmm17{%k5}
    {evex} vpbroadcastd 1001(%rbx), %xmm16{%k6}
    {evex} vpbroadcastd 0(%rsp), %xmm3{%k7}
    {evex} vpbroadcastd -4(%r12), %xmm25{%k1}
    {evex} vpbroadcastd -2147483648(%rsp), %xmm9{%k2}
    {evex} vpbroadcastd 0(%rcx,%r9,1), %xmm31{%k3}
    {evex} vpbroadcastd 8(%rbp,%rbp,2), %xmm20{%k4}
    {evex} vpbroadcastd 2147483647(%r12,%r12,4), %xmm12{%k5}
    {evex} vpbroadcastd gnu_back(%rip), %xmm17{%k6}
    {evex} vpbroadcastd %xmm16, %xmm3{%k7}{z}
    {evex} vpbroadcastd 0(%rcx), %xmm25{%k1}{z}
    {evex} vpbroadcastd -512(%r10), %xmm9{%k2}{z}
    {evex} vpbroadcastd 4660(%rsi), %xmm31{%k3}{z}
    {evex} vpbroadcastd 0(%r12), %xmm20{%k4}{z}
    {evex} vpbroadcastd 508(%rsp), %xmm12{%k5}{z}
    {evex} vpbroadcastd -129(%r12), %xmm17{%k6}{z}
    {evex} vpbroadcastd 0(%r12,%rax,8), %xmm16{%k7}{z}
    {evex} vpbroadcastd -4(%rdi,%r15,1), %xmm3{%k1}{z}
    {evex} vpbroadcastd 1001(%r15,%rsi,2), %xmm25{%k2}{z}
    {evex} vpbroadcastd gnu_fwd(%rip), %xmm9{%k3}{z}
    {evex} vpbroadcastd %xmm31, %ymm20
    {evex} vpbroadcastd 0(%r8), %ymm12
    {evex} vpbroadcastd 8(%r11), %ymm17
    {evex} vpbroadcastd -2147483648(%rdi), %ymm16
    {evex} vpbroadcastd 0(%rsp), %ymm3
    {evex} vpbroadcastd -512(%r12), %ymm25
    {evex} vpbroadcastd 2147483647(%rsp), %ymm9
    {evex} vpbroadcastd 0(%rdx,%rcx,4), %ymm31
    {evex} vpbroadcastd 508(%rax,%r9,8), %ymm20
    {evex} vpbroadcastd 4660(%r9,%rbp,1), %ymm12
    {evex} vpbroadcastd gnu_back(%rip), %ymm17
    {evex} vpbroadcastd %xmm16, %ymm3{%k4}
    {evex} vpbroadcastd 0(%rdx), %ymm25{%k5}
    {evex} vpbroadcastd -4(%r14), %ymm9{%k6}
    {evex} vpbroadcastd -129(%r15), %ymm31{%k7}
    {evex} vpbroadcastd 0(%r12), %ymm20{%k1}
    {evex} vpbroadcastd 8(%rsp), %ymm12{%k2}
    {evex} vpbroadcastd 1001(%r12), %ymm17{%k3}
    {evex} vpbroadcastd 0(%r9,%r12,2), %ymm16{%k4}
    {evex} vpbroadcastd -512(%rsp,%rax,4), %ymm3{%k5}
    {evex} vpbroadcastd -2147483648(%r13,%r15,8), %ymm25{%k6}
    {evex} vpbroadcastd gnu_fwd(%rip), %ymm9{%k7}
    {evex} vpbroadcastd %xmm31, %ymm20{%k1}{z}
    {evex} vpbroadcastd 0(%r9), %ymm12{%k2}{z}
    {evex} vpbroadcastd 508(%rcx), %ymm17{%k3}{z}
    {evex} vpbroadcastd 2147483647(%r8), %ymm16{%k4}{z}
    {evex} vpbroadcastd 0(%rsp), %ymm3{%k5}{z}
    {evex} vpbroadcastd -4(%r12), %ymm25{%k6}{z}
    {evex} vpbroadcastd 4660(%rsp), %ymm9{%k7}{z}
    {evex} vpbroadcastd 0(%rsp,%rsi,1), %ymm31{%k1}{z}
    {evex} vpbroadcastd 8(%rbp,%rcx,2), %ymm20{%k2}{z}
    {evex} vpbroadcastd -129(%r12,%r9,4), %ymm12{%k3}{z}
    {evex} vpbroadcastd gnu_back(%rip), %ymm17{%k4}{z}
    {evex} vpbroadcastd %xmm16, %zmm3
    {evex} vpbroadcastd 0(%rbx), %zmm25
g78:
    {evex} vpbroadcastd -512(%rbp), %zmm9
    {evex} vpbroadcastd 1001(%r13), %zmm31
    {evex} vpbroadcastd 0(%r12), %zmm20
    {evex} vpbroadcastd 508(%rsp), %zmm12
    {evex} vpbroadcastd -2147483648(%r12), %zmm17
    {evex} vpbroadcastd 0(%r14,%rbp,8), %zmm16
    {evex} vpbroadcastd -4(%rdi,%r12,1), %zmm3
    {evex} vpbroadcastd 2147483647(%r15,%rax,2), %zmm25
    {evex} vpbroadcastd gnu_fwd(%rip), %zmm9
    {evex} vpbroadcastd %xmm31, %zmm20{%k5}
    {evex} vpbroadcastd 0(%r10), %zmm12{%k6}
    {evex} vpbroadcastd 8(%rdx), %zmm17{%k7}
    {evex} vpbroadcastd 4660(%r9), %zmm16{%k1}
    {evex} vpbroadcastd 0(%rsp), %zmm3{%k2}
    {evex} vpbroadcastd -512(%r12), %zmm25{%k3}
    {evex} vpbroadcastd -129(%rsp), %zmm9{%k4}
    {evex} vpbroadcastd 0(%rsi,%r15,4), %zmm31{%k5}
    {evex} vpbroadcastd 508(%rax,%rsi,8), %zmm20{%k6}
    {evex} vpbroadcastd 1001(%r9,%rcx,1), %zmm12{%k7}
    {evex} vpbroadcastd gnu_back(%rip), %zmm17{%k1}
    {evex} vpbroadcastd %xmm16, %zmm3{%k2}{z}
    {evex} vpbroadcastd 0(%rsi), %zmm25{%k3}{z}
    {evex} vpbroadcastd -4(%rbx), %zmm9{%k4}{z}
    {evex} vpbroadcastd -2147483648(%r10), %zmm31{%k5}{z}
    {evex} vpbroadcastd 0(%r12), %zmm20{%k6}{z}
    {evex} vpbroadcastd 8(%rsp), %zmm12{%k7}{z}
    {evex} vpbroadcastd 2147483647(%r12), %zmm17{%k1}{z}
    {evex} vpbroadcastd 0(%r15,%r9,2), %zmm16{%k2}{z}
    {evex} vpbroadcastd -512(%rsp,%rbp,4), %zmm3{%k3}{z}
    {evex} vpbroadcastd 4660(%r13,%r12,8), %zmm25{%k4}{z}
    {evex} vpbroadcastd gnu_fwd(%rip), %zmm9{%k5}{z}
    {evex} vbroadcastss %xmm31, %ymm20
    {evex} vbroadcastss 0(%r11), %ymm12
    {evex} vbroadcastss 508(%rsi), %ymm17
    {evex} vbroadcastss -129(%r11), %ymm16
    {evex} vbroadcastss 0(%rsp), %ymm3
    {evex} vbroadcastss -4(%r12), %ymm25
    {evex} vbroadcastss 1001(%rsp), %ymm9
    {evex} vbroadcastss 0(%rax,%rax,1), %ymm31
    {evex} vbroadcastss 8(%rbp,%r15,2), %ymm20
    {evex} vbroadcastss -2147483648(%r12,%rsi,4), %ymm12
    {evex} vbroadcastss gnu_back(%rip), %ymm17
    {evex} vbroadcastss %xmm16, %ymm3{%k6}
    {evex} vbroadcastss 0(%rdi), %ymm25{%k7}
    {evex} vbroadcastss -512(%rdi), %ymm9{%k1}
    {evex} vbroadcastss 2147483647(%r14), %ymm31{%k2}
    {evex} vbroadcastss 0(%r12), %ymm20{%k3}
    {evex} vbroadcastss 508(%rsp), %ymm12{%k4}
    {evex} vbroadcastss 4660(%r12), %ymm17{%k5}
    {evex} vbroadcastss 0(%r8,%rcx,8), %ymm16{%k6}
    {evex} vbroadcastss -4(%rdi,%r9,1), %ymm3{%k7}
    {evex} vbroadcastss -129(%r15,%rbp,2), %ymm25{%k1}
    {evex} vbroadcastss gnu_fwd(%rip), %ymm9{%k2}
    {evex} vbroadcastss %xmm31, %ymm20{%k3}{z}
    {evex} vbroadcastss 0(%r14), %ymm12{%k4}{z}
    {evex} vbroadcastss 8(%r15), %ymm17{%k5}{z}
    {evex} vbroadcastss 1001(%rcx), %ymm16{%k6}{z}
    {evex} vbroadcastss 0(%rsp), %ymm3{%k7}{z}
    {evex} vbroadcastss -512(%r12), %ymm25{%k1}{z}
    {evex} vbroadcastss -2147483648(%rsp), %ymm9{%k2}{z}
    {evex} vbroadcastss 0(%rcx,%r12,4), %ymm31{%k3}{z}
    {evex} vbroadcastss 508(%rax,%rax,8), %ymm20{%k4}{z}
    {evex} vbroadcastss 2147483647(%r9,%r15,1), %ymm12{%k5}{z}
    {evex} vbroadcastss gnu_back(%rip), %ymm17{%k6}{z}
    {evex} vbroadcastss %xmm16, %zmm3
    {evex} vbroadcastss 0(%r15), %zmm25
    {evex} vbroadcastss -4(%r8), %zmm9
    {evex} vbroadcastss 4660(%rbp), %zmm31
    {evex} vbroadcastss 0(%r12), %zmm20
    {evex} vbroadcastss 8(%rsp), %zmm12
    {evex} vbroadcastss -129(%r12), %zmm17
    {evex} vbroadcastss 0(%r12,%rsi,2), %zmm16
    {evex} vbroadcastss -512(%rsp,%rcx,4), %zmm3
    {evex} vbroadcastss 1001(%r13,%r9,8), %zmm25
    {evex} vbroadcastss gnu_fwd(%rip), %zmm9
    {evex} vbroadcastss %xmm31, %zmm20{%k7}
    {evex} vbroadcastss 0(%rcx), %zmm12{%k1}
    {evex} vbroadcastss 508(%r13), %zmm17{%k2}
    {evex} vbroadcastss -2147483648(%rdx), %zmm16{%k3}
    {evex} vbroadcastss 0(%rsp), %zmm3{%k4}
    {evex} vbroadcastss -4(%r12), %zmm25{%k5}
    {evex} vbroadcastss 2147483647(%rsp), %zmm9{%k6}
    {evex} vbroadcastss 0(%rdx,%rbp,1), %zmm31{%k7}
    {evex} vbroadcastss 8(%rbp,%r12,2), %zmm20{%k1}
    {evex} vbroadcastss 4660(%r12,%rax,4), %zmm12{%k2}
    {evex} vbroadcastss gnu_back(%rip), %zmm17{%k3}
    {evex} vbroadcastss %xmm16, %zmm3{%k4}{z}
    {evex} vbroadcastss 0(%r8), %zmm25{%k5}{z}
    {evex} vbroadcastss -512(%r9), %zmm9{%k6}{z}
    {evex} vbroadcastss -129(%rbx), %zmm31{%k7}{z}
    {evex} vbroadcastss 0(%r12), %zmm20{%k1}{z}
    {evex} vbroadcastss 508(%rsp), %zmm12{%k2}{z}
    {evex} vbroadcastss 1001(%r12), %zmm17{%k3}{z}
    {evex} vbroadcastss 0(%r9,%r15,8), %zmm16{%k4}{z}
    {evex} vbroadcastss -4(%rdi,%rsi,1), %zmm3{%k5}{z}
    {evex} vbroadcastss -2147483648(%r15,%rcx,2), %zmm25{%k6}{z}
    {evex} vbroadcastss gnu_fwd(%rip), %zmm9{%k7}{z}
    {evex} vpbroadcastb %edx, %xmm31
    {evex} vpbroadcastb %r12d, %xmm20{%k1}
    {evex} vpbroadcastb %ebx, %xmm12{%k2}{z}
    {evex} vpbroadcastb %r13d, %ymm17
    {evex} vpbroadcastb %esi, %ymm16{%k3}
    {evex} vpbroadcastb %r14d, %ymm3{%k4}{z}
    {evex} vpbroadcastb %edi, %zmm25
    {evex} vpbroadcastb %r15d, %zmm9{%k5}
    {evex} vpbroadcastb %ebp, %zmm31{%k6}{z}
    {evex} vpbroadcastd %r8d, %xmm20
    {evex} vpbroadcastd %ecx, %xmm12{%k7}
    {evex} vpbroadcastd %r9d, %xmm17{%k1}{z}
    {evex} vpbroadcastd %edx, %ymm16
    {evex} vpbroadcastd %r12d, %ymm3{%k2}
    {evex} vpbroadcastd %ebx, %ymm25{%k3}{z}
    {evex} vpbroadcastd %r13d, %zmm9
    {evex} vpbroadcastd %esi, %zmm31{%k4}
    {evex} vpbroadcastd %r14d, %zmm20{%k5}{z}
    flds 0(%r15)
    flds -1(%r8)
    flds 4660(%r9)
    flds 0(%r12)
    flds 64(%r12)
    flds 128(%r12)
    flds 0(%r8,%r9,4)
    flds 8(%r12,%rbp,8)
    flds -129(%r13,%r12,1)
    flds 0(%rdi)
    flds -128(%rsi)
    flds -2147483648(%rdi)
    flds 0(%rsp)
    flds 127(%rsp)
    flds 2147483647(%rsp)
    flds 0(%rax,%rax,2)
    flds -1(%rsp,%rcx,4)
    flds 4660(%rbp,%rdx,8)
    flds gnu_back(%rip)
    flds 128
    fldl 0(%r8)
    fldl 64(%r10)
    fldl -129(%r11)
    fldl 0(%r12)
    fldl 8(%r12)
    fldl -2147483648(%r12)
    fldl 0(%r9,%rax,1)
    fldl -128(%r15,%r15,2)
    fldl 2147483647(%r8,%rsi,4)
    fldl 0(%rcx)
    fldl 127(%rcx)
    fldl 4660(%rdx)
    fldl 0(%rsp)
    fldl -1(%rsp)
    fldl 128(%rsp)
    fldl 0(%rcx,%rbx,8)
    fldl 64(%rsi,%rbp,1)
    fldl -129(%rdi,%rsi,2)
    fldl gnu_fwd(%rip)
    fldl -2147483648
    fldt 0(%r9)
    fldt 8(%r13)
    fldt 2147483647(%r14)
    fldt 0(%r12)
    fldt -128(%r12)
    fldt 4660(%r12)
    fldt 0(%r10,%rcx,4)
    fldt 127(%r9,%r9,8)
    fldt 128(%r12,%rbp,1)
    fldt 0(%rdx)
    fldt -1(%rbx)
    fldt -129(%rbp)
    fldt 0(%rsp)
    fldt 64(%rsp)
    fldt -2147483648(%rsp)
    fldt 0(%rdx,%rdi,2)
    fldt 8(%rax,%rax,4)
    fldt 2147483647(%rcx,%rcx,8)
    fldt gnu_back(%rip)
    fldt 4660
    fsts 0(%r10)
    fsts -128(%r15)
    fsts 128(%r8)
    fsts 0(%r12)
    fsts 127(%r12)
    fsts -129(%r12)
    fsts 0(%r11,%r12,1)
    fsts -1(%r13,%rax,2)
    fsts -2147483648(%r15,%r15,4)
    fsts 0(%rbx)
    fsts 64(%rsi)
    fsts 2147483647(%rdi)
    fsts 0(%rsp)
    fsts 8(%rsp)
    fsts 4660(%rsp)
    fsts 0(%rbx,%rdx,8)
    fsts -128(%rdx,%rbx,1)
    fsts 128(%rbx,%rbp,2)
    fsts gnu_fwd(%rip)
    fsts -129
    fstl 0(%r11)
    fstl 127(%r9)
    fstl -2147483648(%r10)
    fstl 0(%r12)
    fstl -1(%r12)
g79:
    fstl 2147483647(%r12)
    fstl 0(%r12,%rsi,4)
    fstl 64(%r8,%rcx,8)
    fstl 4660(%r9,%r9,1)
    fstl 0(%rsi)
    fstl 8(%rcx)
    fstl 128(%rdx)
    fstl 0(%rsp)
    fstl -128(%rsp)
    fstl -129(%rsp)
    fstl 0(%rsp,%rsi,2)
    fstl 127(%rsp,%rdi,4)
    fstl -2147483648(%rbp,%rax,8)
    fstl gnu_back(%rip)
    fstl 2147483647
    fstps 0(%r14)
    fstps -1(%r11)
    fstps 4660(%r13)
    fstps 0(%r12)
    fstps 64(%r12)
    fstps 128(%r12)
    fstps 0(%r14,%rbp,1)
    fstps 8(%r12,%r12,2)
    fstps -129(%r13,%rax,4)
    fstps 0(%rdi)
    fstps -128(%rbx)
    fstps -2147483648(%rbp)
    fstps 0(%rsp)
    fstps 127(%rsp)
    fstps 2147483647(%rsp)
    fstps 0(%rsi,%rcx,8)
    fstps -1(%rsi,%rdx,1)
    fstps 4660(%rdi,%rbx,2)
    fstps gnu_fwd(%rip)
    fstps 128
    fstpl 0(%r15)
    fstpl 64(%r14)
    fstpl -129(%r15)
    fstpl 0(%r12)
    fstpl 8(%r12)
    fstpl -2147483648(%r12)
    fstpl 0(%r15,%r15,4)
    fstpl -128(%r15,%rsi,8)
    fstpl 2147483647(%r8,%rcx,1)
    fstpl 0(%rcx)
    fstpl 127(%rsi)
    fstpl 4660(%rdi)
    fstpl 0(%rsp)
    fstpl -1(%rsp)
    fstpl 128(%rsp)
    fstpl 0(%rdi,%rbp,2)
    fstpl 64(%rax,%rsi,4)
    fstpl -129(%rcx,%rdi,8)
    fstpl gnu_back(%rip)
    fstpl -2147483648
    fstpt 0(%r8)
    fstpt 8(%r8)
    fstpt 2147483647(%r9)
    fstpt 0(%r12)
    fstpt -128(%r12)
    fstpt 4660(%r12)
    fstpt 0(%r8,%r9,1)
    fstpt 127(%r9,%rbp,2)
    fstpt 128(%r12,%r12,4)
    fstpt 0(%rdx)
    fstpt -1(%rcx)
    fstpt -129(%rdx)
    fstpt 0(%rsp)
    fstpt 64(%rsp)
    fstpt -2147483648(%rsp)
    fstpt 0(%rax,%rax,8)
    fstpt 8(%rdx,%rcx,1)
    fstpt 2147483647(%rbx,%rdx,2)
    fstpt gnu_fwd(%rip)
    fstpt 4660
    filds 0(%r9)
    filds -128(%r10)
    filds 128(%r11)
    filds 0(%r12)
    filds 127(%r12)
    filds -129(%r12)
    filds 0(%r9,%rax,4)
    filds -1(%r13,%r15,8)
    filds -2147483648(%r15,%rsi,1)
    filds 0(%rbx)
    filds 64(%rbx)
    filds 2147483647(%rbp)
    filds 0(%rsp)
    filds 8(%rsp)
    filds 4660(%rsp)
    filds 0(%rcx,%rbx,2)
    filds -128(%rsp,%rbp,4)
    filds 128(%rbp,%rsi,8)
    filds gnu_back(%rip)
    filds -129
    fildl 0(%r10)
    fildl 127(%r13)
    fildl -2147483648(%r14)
    fildl 0(%r12)
    fildl -1(%r12)
    fildl 2147483647(%r12)
    fildl 0(%r10,%rcx,1)
    fildl 64(%r8,%r9,2)
    fildl 4660(%r9,%rbp,4)
    fildl 0(%rsi)
    fildl 8(%rsi)
    fildl 128(%rdi)
    fildl 0(%rsp)
    fildl -128(%rsp)
    fildl -129(%rsp)
    fildl 0(%rdx,%rdi,8)
    fildl 127(%rsi,%rax,1)
    fildl -2147483648(%rdi,%rcx,2)
    fildl gnu_fwd(%rip)
    fildl 2147483647
    fildll 0(%r11)
    fildll -1(%r15)
    fildll 4660(%r8)
    fildll 0(%r12)
    fildll 64(%r12)
    fildll 128(%r12)
    fildll 0(%r11,%r12,4)
    fildll 8(%r12,%rax,8)
    fildll -129(%r13,%r15,1)
    fildll 0(%rdi)
    fildll -128(%rcx)
    fildll -2147483648(%rdx)
    fildll 0(%rsp)
    fildll 127(%rsp)
    fildll 2147483647(%rsp)
    fildll 0(%rbx,%rdx,2)
    fildll -1(%rax,%rbx,4)
    fildll 4660(%rcx,%rbp,8)
    fildll gnu_back(%rip)
    fildll 128
    fists 0(%r14)
    fists 64(%r9)
    fists -129(%r10)
    fists 0(%r12)
    fists 8(%r12)
    fists -2147483648(%r12)
    fists 0(%r12,%rsi,1)
    fists -128(%r15,%rcx,2)
    fists 2147483647(%r8,%r9,4)
    fists 0(%rcx)
    fists 127(%rbx)
    fists 4660(%rbp)
    fists 0(%rsp)
    fists -1(%rsp)
    fists 128(%rsp)
    fists 0(%rsp,%rsi,8)
    fists 64(%rdx,%rdi,1)
    fists -129(%rbx,%rax,2)
    fists gnu_fwd(%rip)
    fists -2147483648
    fistl 0(%r15)
    fistl 8(%r11)
    fistl 2147483647(%r13)
    fistl 0(%r12)
    fistl -128(%r12)
    fistl 4660(%r12)
    fistl 0(%r14,%rbp,4)
    fistl 127(%r9,%r12,8)
    fistl 128(%r12,%rax,1)
    fistl 0(%rdx)
    fistl -1(%rsi)
    fistl -129(%rdi)
    fistl 0(%rsp)
    fistl 64(%rsp)
    fistl -2147483648(%rsp)
    fistl 0(%rsi,%rcx,2)
    fistl 8(%rsp,%rdx,4)
    fistl 2147483647(%rbp,%rbx,8)
    fistl gnu_back(%rip)
    fistl 4660
    fistps 0(%r8)
    fistps -128(%r14)
    fistps 128(%r15)
    fistps 0(%r12)
    fistps 127(%r12)
    fistps -129(%r12)
    fistps 0(%r15,%r15,1)
    fistps -1(%r13,%rsi,2)
    fistps -2147483648(%r15,%rcx,4)
    fistps 0(%rbx)
    fistps 64(%rcx)
    fistps 2147483647(%rdx)
    fistps 0(%rsp)
    fistps 8(%rsp)
    fistps 4660(%rsp)
    fistps 0(%rdi,%rbp,8)
    fistps -128(%rsi,%rsi,1)
    fistps 128(%rdi,%rdi,2)
    fistps gnu_fwd(%rip)
    fistps -129
    fistpl 0(%r9)
    fistpl 127(%r8)
    fistpl -2147483648(%r9)
    fistpl 0(%r12)
    fistpl -1(%r12)
g80:
    fistpl 2147483647(%r12)
    fistpl 0(%r8,%r9,4)
    fistpl 64(%r8,%rbp,8)
    fistpl 4660(%r9,%r12,1)
    fistpl 0(%rsi)
    fistpl 8(%rbx)
    fistpl 128(%rbp)
    fistpl 0(%rsp)
    fistpl -128(%rsp)
    fistpl -129(%rsp)
    fistpl 0(%rax,%rax,2)
    fistpl 127(%rax,%rcx,4)
    fistpl -2147483648(%rcx,%rdx,8)
    fistpl gnu_back(%rip)
    fistpl 2147483647
    fistpll 0(%r10)
    fistpll -1(%r10)
    fistpll 4660(%r11)
    fistpll 0(%r12)
    fistpll 64(%r12)
    fistpll 128(%r12)
    fistpll 0(%r9,%rax,1)
    fistpll 8(%r12,%r15,2)
    fistpll -129(%r13,%rsi,4)
    fistpll 0(%rdi)
    fistpll -128(%rsi)
    fistpll -2147483648(%rdi)
    fistpll 0(%rsp)
    fistpll 127(%rsp)
    fistpll 2147483647(%rsp)
    fistpll 0(%rcx,%rbx,8)
    fistpll -1(%rdx,%rbp,1)
    fistpll 4660(%rbx,%rsi,2)
    fistpll gnu_fwd(%rip)
    fistpll 128
    fadds 0(%r11)
    fadds 64(%r13)
    fadds -129(%r14)
    fadds 0(%r12)
    fadds 8(%r12)
    fadds -2147483648(%r12)
    fadds 0(%r10,%rcx,4)
    fadds -128(%r15,%r9,8)
    fadds 2147483647(%r8,%rbp,1)
    fadds 0(%rcx)
    fadds 127(%rcx)
    fadds 4660(%rdx)
    fadds 0(%rsp)
    fadds -1(%rsp)
    fadds 128(%rsp)
    fadds 0(%rdx,%rdi,2)
    fadds 64(%rsp,%rax,4)
    fadds -129(%rbp,%rcx,8)
    fadds gnu_back(%rip)
    fadds -2147483648
    faddl 0(%r14)
    faddl 8(%r15)
    faddl 2147483647(%r8)
    faddl 0(%r12)
    faddl -128(%r12)
    faddl 4660(%r12)
    faddl 0(%r11,%r12,1)
    faddl 127(%r9,%rax,2)
    faddl 128(%r12,%r15,4)
    faddl 0(%rdx)
    faddl -1(%rbx)
    faddl -129(%rbp)
    faddl 0(%rsp)
    faddl 64(%rsp)
    faddl -2147483648(%rsp)
    faddl 0(%rbx,%rdx,8)
    faddl 8(%rsi,%rbx,1)
    faddl 2147483647(%rdi,%rbp,2)
    faddl gnu_fwd(%rip)
    faddl 4660
    fmuls 0(%r15)
    fmuls -128(%r9)
    fmuls 128(%r10)
    fmuls 0(%r12)
    fmuls 127(%r12)
    fmuls -129(%r12)
    fmuls 0(%r12,%rsi,4)
    fmuls -1(%r13,%rcx,8)
    fmuls -2147483648(%r15,%r9,1)
    fmuls 0(%rbx)
    fmuls 64(%rsi)
    fmuls 2147483647(%rdi)
    fmuls 0(%rsp)
    fmuls 8(%rsp)
    fmuls 4660(%rsp)
    fmuls 0(%rsp,%rsi,2)
    fmuls -128(%rax,%rdi,4)
    fmuls 128(%rcx,%rax,8)
    fmuls gnu_back(%rip)
    fmuls -129
    fmull 0(%r8)
    fmull 127(%r11)
    fmull -2147483648(%r13)
    fmull 0(%r12)
    fmull -1(%r12)
    fmull 2147483647(%r12)
    fmull 0(%r14,%rbp,1)
    fmull 64(%r8,%r12,2)
    fmull 4660(%r9,%rax,4)
    fmull 0(%rsi)
    fmull 8(%rcx)
    fmull 128(%rdx)
    fmull 0(%rsp)
    fmull -128(%rsp)
    fmull -129(%rsp)
    fmull 0(%rsi,%rcx,8)
    fmull 127(%rdx,%rdx,1)
    fmull -2147483648(%rbx,%rbx,2)
    fmull gnu_fwd(%rip)
    fmull 2147483647
    fcoms 0(%r9)
    fcoms -1(%r14)
    fcoms 4660(%r15)
    fcoms 0(%r12)
    fcoms 64(%r12)
    fcoms 128(%r12)
    fcoms 0(%r15,%r15,4)
    fcoms 8(%r12,%rsi,8)
    fcoms -129(%r13,%rcx,1)
    fcoms 0(%rdi)
    fcoms -128(%rbx)
    fcoms -2147483648(%rbp)
    fcoms 0(%rsp)
    fcoms 127(%rsp)
    fcoms 2147483647(%rsp)
    fcoms 0(%rdi,%rbp,2)
    fcoms -1(%rsp,%rsi,4)
    fcoms 4660(%rbp,%rdi,8)
    fcoms gnu_back(%rip)
    fcoms 128
    fcoml 0(%r10)
    fcoml 64(%r8)
    fcoml -129(%r9)
    fcoml 0(%r12)
    fcoml 8(%r12)
    fcoml -2147483648(%r12)
    fcoml 0(%r8,%r9,1)
    fcoml -128(%r15,%rbp,2)
    fcoml 2147483647(%r8,%r12,4)
    fcoml 0(%rcx)
    fcoml 127(%rsi)
    fcoml 4660(%rdi)
    fcoml 0(%rsp)
    fcoml -1(%rsp)
    fcoml 128(%rsp)
    fcoml 0(%rax,%rax,8)
    fcoml 64(%rsi,%rcx,1)
    fcoml -129(%rdi,%rdx,2)
    fcoml gnu_fwd(%rip)
    fcoml -2147483648
    fcomps 0(%r11)
    fcomps 8(%r10)
    fcomps 2147483647(%r11)
    fcomps 0(%r12)
    fcomps -128(%r12)
    fcomps 4660(%r12)
    fcomps 0(%r9,%rax,4)
    fcomps 127(%r9,%r15,8)
    fcomps 128(%r12,%rsi,1)
    fcomps 0(%rdx)
    fcomps -1(%rcx)
    fcomps -129(%rdx)
    fcomps 0(%rsp)
    fcomps 64(%rsp)
    fcomps -2147483648(%rsp)
    fcomps 0(%rcx,%rbx,2)
    fcomps 8(%rax,%rbp,4)
    fcomps 2147483647(%rcx,%rsi,8)
    fcomps gnu_back(%rip)
    fcomps 4660
    fcompl 0(%r14)
    fcompl -128(%r13)
    fcompl 128(%r14)
    fcompl 0(%r12)
    fcompl 127(%r12)
    fcompl -129(%r12)
    fcompl 0(%r10,%rcx,1)
    fcompl -1(%r13,%r9,2)
    fcompl -2147483648(%r15,%rbp,4)
    fcompl 0(%rbx)
    fcompl 64(%rbx)
    fcompl 2147483647(%rbp)
    fcompl 0(%rsp)
    fcompl 8(%rsp)
    fcompl 4660(%rsp)
    fcompl 0(%rdx,%rdi,8)
    fcompl -128(%rdx,%rax,1)
    fcompl 128(%rbx,%rcx,2)
    fcompl gnu_fwd(%rip)
    fcompl -129
    fsubs 0(%r15)
    fsubs 127(%r15)
    fsubs -2147483648(%r8)
    fsubs 0(%r12)
    fsubs -1(%r12)
g81:
    fsubs 2147483647(%r12)
    fsubs 0(%r11,%r12,4)
    fsubs 64(%r8,%rax,8)
    fsubs 4660(%r9,%r15,1)
    fsubs 0(%rsi)
    fsubs 8(%rsi)
    fsubs 128(%rdi)
    fsubs 0(%rsp)
    fsubs -128(%rsp)
    fsubs -129(%rsp)
    fsubs 0(%rbx,%rdx,2)
    fsubs 127(%rsp,%rbx,4)
    fsubs -2147483648(%rbp,%rbp,8)
    fsubs gnu_back(%rip)
    fsubs 2147483647
    fsubl 0(%r8)
    fsubl -1(%r9)
    fsubl 4660(%r10)
    fsubl 0(%r12)
    fsubl 64(%r12)
    fsubl 128(%r12)
    fsubl 0(%r12,%rsi,1)
    fsubl 8(%r12,%rcx,2)
    fsubl -129(%r13,%r9,4)
    fsubl 0(%rdi)
    fsubl -128(%rcx)
    fsubl -2147483648(%rdx)
    fsubl 0(%rsp)
    fsubl 127(%rsp)
    fsubl 2147483647(%rsp)
    fsubl 0(%rsp,%rsi,8)
    fsubl -1(%rsi,%rdi,1)
    fsubl 4660(%rdi,%rax,2)
    fsubl gnu_fwd(%rip)
    fsubl 128
    fsubrs 0(%r9)
    fsubrs 64(%r11)
    fsubrs -129(%r13)
    fsubrs 0(%r12)
    fsubrs 8(%r12)
    fsubrs -2147483648(%r12)
    fsubrs 0(%r14,%rbp,4)
    fsubrs -128(%r15,%r12,8)
    fsubrs 2147483647(%r8,%rax,1)
    fsubrs 0(%rcx)
    fsubrs 127(%rbx)
    fsubrs 4660(%rbp)
    fsubrs 0(%rsp)
    fsubrs -1(%rsp)
    fsubrs 128(%rsp)
    fsubrs 0(%rsi,%rcx,2)
    fsubrs 64(%rax,%rdx,4)
    fsubrs -129(%rcx,%rbx,8)
    fsubrs gnu_back(%rip)
    fsubrs -2147483648
    fsubrl 0(%r10)
    fsubrl 8(%r14)
    fsubrl 2147483647(%r15)
    fsubrl 0(%r12)
    fsubrl -128(%r12)
    fsubrl 4660(%r12)
    fsubrl 0(%r15,%r15,1)
    fsubrl 127(%r9,%rsi,2)
    fsubrl 128(%r12,%rcx,4)
    fsubrl 0(%rdx)
    fsubrl -1(%rsi)
    fsubrl -129(%rdi)
    fsubrl 0(%rsp)
    fsubrl 64(%rsp)
    fsubrl -2147483648(%rsp)
    fsubrl 0(%rdi,%rbp,8)
    fsubrl 8(%rdx,%rsi,1)
    fsubrl 2147483647(%rbx,%rdi,2)
    fsubrl gnu_fwd(%rip)
    fsubrl 4660
    fdivs 0(%r11)
    fdivs -128(%r8)
    fdivs 128(%r9)
    fdivs 0(%r12)
    fdivs 127(%r12)
    fdivs -129(%r12)
    fdivs 0(%r8,%r9,4)
    fdivs -1(%r13,%rbp,8)
    fdivs -2147483648(%r15,%r12,1)
    fdivs 0(%rbx)
    fdivs 64(%rcx)
    fdivs 2147483647(%rdx)
    fdivs 0(%rsp)
    fdivs 8(%rsp)
    fdivs 4660(%rsp)
    fdivs 0(%rax,%rax,2)
    fdivs -128(%rsp,%rcx,4)
    fdivs 128(%rbp,%rdx,8)
    fdivs gnu_back(%rip)
    fdivs -129
    fdivl 0(%r14)
    fdivl 127(%r10)
    fdivl -2147483648(%r11)
    fdivl 0(%r12)
    fdivl -1(%r12)
    fdivl 2147483647(%r12)
    fdivl 0(%r9,%rax,1)
    fdivl 64(%r8,%r15,2)
    fdivl 4660(%r9,%rsi,4)
    fdivl 0(%rsi)
    fdivl 8(%rbx)
    fdivl 128(%rbp)
    fdivl 0(%rsp)
    fdivl -128(%rsp)
    fdivl -129(%rsp)
    fdivl 0(%rcx,%rbx,8)
    fdivl 127(%rsi,%rbp,1)
    fdivl -2147483648(%rdi,%rsi,2)
    fdivl gnu_fwd(%rip)
    fdivl 2147483647
    fdivrs 0(%r15)
    fdivrs -1(%r13)
    fdivrs 4660(%r14)
    fdivrs 0(%r12)
    fdivrs 64(%r12)
    fdivrs 128(%r12)
    fdivrs 0(%r10,%rcx,4)
    fdivrs 8(%r12,%r9,8)
    fdivrs -129(%r13,%rbp,1)
    fdivrs 0(%rdi)
    fdivrs -128(%rsi)
    fdivrs -2147483648(%rdi)
    fdivrs 0(%rsp)
    fdivrs 127(%rsp)
    fdivrs 2147483647(%rsp)
    fdivrs 0(%rdx,%rdi,2)
    fdivrs -1(%rax,%rax,4)
    fdivrs 4660(%rcx,%rcx,8)
    fdivrs gnu_back(%rip)
    fdivrs 128
    fdivrl 0(%r8)
    fdivrl 64(%r15)
    fdivrl -129(%r8)
    fdivrl 0(%r12)
    fdivrl 8(%r12)
    fdivrl -2147483648(%r12)
    fdivrl 0(%r11,%r12,1)
    fdivrl -128(%r15,%rax,2)
    fdivrl 2147483647(%r8,%r15,4)
    fdivrl 0(%rcx)
    fdivrl 127(%rcx)
    fdivrl 4660(%rdx)
    fdivrl 0(%rsp)
    fdivrl -1(%rsp)
    fdivrl 128(%rsp)
    fdivrl 0(%rbx,%rdx,8)
    fdivrl 64(%rdx,%rbx,1)
    fdivrl -129(%rbx,%rbp,2)
    fdivrl gnu_fwd(%rip)
    fdivrl -2147483648
    fnstcw 0(%r9)
    fnstcw 8(%r9)
    fnstcw 2147483647(%r10)
    fnstcw 0(%r12)
    fnstcw -128(%r12)
    fnstcw 4660(%r12)
    fnstcw 0(%r12,%rsi,4)
    fnstcw 127(%r9,%rcx,8)
    fnstcw 128(%r12,%r9,1)
    fnstcw 0(%rdx)
    fnstcw -1(%rbx)
    fnstcw -129(%rbp)
    fnstcw 0(%rsp)
    fnstcw 64(%rsp)
    fnstcw -2147483648(%rsp)
    fnstcw 0(%rsp,%rsi,2)
    fnstcw 8(%rsp,%rdi,4)
    fnstcw 2147483647(%rbp,%rax,8)
    fnstcw gnu_back(%rip)
    fnstcw 4660
    fldcw 0(%r10)
    fldcw -128(%r11)
    fldcw 128(%r13)
    fldcw 0(%r12)
    fldcw 127(%r12)
    fldcw -129(%r12)
    fldcw 0(%r14,%rbp,1)
    fldcw -1(%r13,%r12,2)
    fldcw -2147483648(%r15,%rax,4)
    fldcw 0(%rbx)
    fldcw 64(%rsi)
    fldcw 2147483647(%rdi)
    fldcw 0(%rsp)
    fldcw 8(%rsp)
    fldcw 4660(%rsp)
    fldcw 0(%rsi,%rcx,8)
    fldcw -128(%rsi,%rdx,1)
    fldcw 128(%rdi,%rbx,2)
    fldcw gnu_fwd(%rip)
    fldcw -129
    fnstsw 0(%r11)
    fnstsw 127(%r14)
    fnstsw -2147483648(%r15)
    fnstsw 0(%r12)
    fnstsw -1(%r12)
g82:
    fnstsw 2147483647(%r12)
    fnstsw 0(%r15,%r15,4)
    fnstsw 64(%r8,%rsi,8)
    fnstsw 4660(%r9,%rcx,1)
    fnstsw 0(%rsi)
    fnstsw 8(%rcx)
    fnstsw 128(%rdx)
    fnstsw 0(%rsp)
    fnstsw -128(%rsp)
    fnstsw -129(%rsp)
    fnstsw 0(%rdi,%rbp,2)
    fnstsw 127(%rax,%rsi,4)
    fnstsw -2147483648(%rcx,%rdi,8)
    fnstsw gnu_back(%rip)
    fnstsw 2147483647
    fnstenv 0(%r14)
    fnstenv -1(%r8)
    fnstenv 4660(%r9)
    fnstenv 0(%r12)
    fnstenv 64(%r12)
    fnstenv 128(%r12)
    fnstenv 0(%r8,%r9,1)
    fnstenv 8(%r12,%rbp,2)
    fnstenv -129(%r13,%r12,4)
    fnstenv 0(%rdi)
    fnstenv -128(%rbx)
    fnstenv -2147483648(%rbp)
    fnstenv 0(%rsp)
    fnstenv 127(%rsp)
    fnstenv 2147483647(%rsp)
    fnstenv 0(%rax,%rax,8)
    fnstenv -1(%rdx,%rcx,1)
    fnstenv 4660(%rbx,%rdx,2)
    fnstenv gnu_fwd(%rip)
    fnstenv 128
    fldenv 0(%r15)
    fldenv 64(%r10)
    fldenv -129(%r11)
    fldenv 0(%r12)
    fldenv 8(%r12)
    fldenv -2147483648(%r12)
    fldenv 0(%r9,%rax,4)
    fldenv -128(%r15,%r15,8)
    fldenv 2147483647(%r8,%rsi,1)
    fldenv 0(%rcx)
    fldenv 127(%rsi)
    fldenv 4660(%rdi)
    fldenv 0(%rsp)
    fldenv -1(%rsp)
    fldenv 128(%rsp)
    fldenv 0(%rcx,%rbx,2)
    fldenv 64(%rsp,%rbp,4)
    fldenv -129(%rbp,%rsi,8)
    fldenv gnu_back(%rip)
    fldenv -2147483648
    fstcw 0(%r8)
    fstcw 8(%r13)
    fstcw 2147483647(%r14)
    fstcw 0(%r12)
    fstcw -128(%r12)
    fstcw 4660(%r12)
    fstcw 0(%r10,%rcx,1)
    fstcw 127(%r9,%r9,2)
    fstcw 128(%r12,%rbp,4)
    fstcw 0(%rdx)
    fstcw -1(%rcx)
    fstcw -129(%rdx)
    fstcw 0(%rsp)
    fstcw 64(%rsp)
    fstcw -2147483648(%rsp)
    fstcw 0(%rdx,%rdi,8)
    fstcw 8(%rsi,%rax,1)
    fstcw 2147483647(%rdi,%rcx,2)
    fstcw gnu_fwd(%rip)
    fstcw 4660
    fstsw 0(%r9)
    fstsw -128(%r15)
    fstsw 128(%r8)
    fstsw 0(%r12)
    fstsw 127(%r12)
    fstsw -129(%r12)
    fstsw 0(%r11,%r12,4)
    fstsw -1(%r13,%rax,8)
    fstsw -2147483648(%r15,%r15,1)
    fstsw 0(%rbx)
    fstsw 64(%rbx)
    fstsw 2147483647(%rbp)
    fstsw 0(%rsp)
    fstsw 8(%rsp)
    fstsw 4660(%rsp)
    fstsw 0(%rbx,%rdx,2)
    fstsw -128(%rax,%rbx,4)
    fstsw 128(%rcx,%rbp,8)
    fstsw gnu_back(%rip)
    fstsw -129
    fstenv 0(%r10)
    fstenv 127(%r9)
    fstenv -2147483648(%r10)
    fstenv 0(%r12)
    fstenv -1(%r12)
    fstenv 2147483647(%r12)
    fstenv 0(%r12,%rsi,1)
    fstenv 64(%r8,%rcx,2)
    fstenv 4660(%r9,%r9,4)
    fstenv 0(%rsi)
    fstenv 8(%rsi)
    fstenv 128(%rdi)
    fstenv 0(%rsp)
    fstenv -128(%rsp)
    fstenv -129(%rsp)
    fstenv 0(%rsp,%rsi,8)
    fstenv 127(%rdx,%rdi,1)
    fstenv -2147483648(%rbx,%rax,2)
    fstenv gnu_fwd(%rip)
    fstenv 2147483647
    fld %st(1)
    fst %st(2)
    fstp %st(3)
    fxch %st(4)
    ffree %st(5)
    ffreep %st(6)
    fucom %st(7)
    fucomp %st(1)
    fcom %st(2)
    fcomp %st(3)
    fcomi %st(4), %st
    fcomip %st(5), %st
    fucomi %st(6), %st
    fucomip %st(7), %st
    fadd %st(1), %st
    fmul %st(2), %st
    fsub %st(3), %st
    fsubr %st(4), %st
    fdiv %st(5), %st
    fdivr %st(6), %st
    fadd %st, %st(7)
    fmul %st, %st(1)
    fsub %st, %st(2)
    fsubr %st, %st(3)
    fdiv %st, %st(4)
    fdivr %st, %st(5)
    faddp %st, %st(6)
    fmulp %st, %st(7)
    fsubp %st, %st(1)
    fsubrp %st, %st(2)
    fdivp %st, %st(3)
    fdivrp %st, %st(4)
    fld1
    fldz
    fldl2e
    fldl2t
    fldlg2
    fldln2
    fldpi
    f2xm1
    fscale
    fprem
    fprem1
    frndint
    fxam
    fxtract
    fyl2x
    fyl2xp1
    fabs
    fchs
    fsqrt
    fsin
    fcos
    fsincos
    fptan
    fpatan
    ftst
    fcompp
    fucompp
    fnclex
    fninit
    fdecstp
    fincstp
    fnstsw %ax
    fstsw %ax
    fxsave 0(%r11)
    fxsave -1(%r11)
    fxsave 4660(%r13)
    fxsave 0(%r12)
    fxsave 64(%r12)
    fxsave 128(%r12)
    fxsave 0(%r14,%rbp,4)
    fxsave 8(%r12,%r12,8)
    fxsave -129(%r13,%rax,1)
    fxsave 0(%rdi)
    fxsave -128(%rcx)
    fxsave -2147483648(%rdx)
    fxsave 0(%rsp)
    fxsave 127(%rsp)
    fxsave 2147483647(%rsp)
    fxsave 0(%rsi,%rcx,2)
    fxsave -1(%rsp,%rdx,4)
    fxsave 4660(%rbp,%rbx,8)
    fxsave gnu_back(%rip)
    fxsave 128
g83:
    fxrstor 0(%r14)
    fxrstor 64(%r14)
    fxrstor -129(%r15)
    fxrstor 0(%r12)
    fxrstor 8(%r12)
    fxrstor -2147483648(%r12)
    fxrstor 0(%r15,%r15,1)
    fxrstor -128(%r15,%rsi,2)
    fxrstor 2147483647(%r8,%rcx,4)
    fxrstor 0(%rcx)
    fxrstor 127(%rbx)
    fxrstor 4660(%rbp)
    fxrstor 0(%rsp)
    fxrstor -1(%rsp)
    fxrstor 128(%rsp)
    fxrstor 0(%rdi,%rbp,8)
    fxrstor 64(%rsi,%rsi,1)
    fxrstor -129(%rdi,%rdi,2)
    fxrstor gnu_fwd(%rip)
    fxrstor -2147483648
    xsave 0(%r15)
    xsave 8(%r8)
    xsave 2147483647(%r9)
    xsave 0(%r12)
    xsave -128(%r12)
    xsave 4660(%r12)
    xsave 0(%r8,%r9,4)
    xsave 127(%r9,%rbp,8)
    xsave 128(%r12,%r12,1)
    xsave 0(%rdx)
    xsave -1(%rsi)
    xsave -129(%rdi)
    xsave 0(%rsp)
    xsave 64(%rsp)
    xsave -2147483648(%rsp)
    xsave 0(%rax,%rax,2)
    xsave 8(%rax,%rcx,4)
    xsave 2147483647(%rcx,%rdx,8)
    xsave gnu_back(%rip)
    xsave 4660
    xrstor 0(%r8)
    xrstor -128(%r10)
    xrstor 128(%r11)
    xrstor 0(%r12)
    xrstor 127(%r12)
    xrstor -129(%r12)
    xrstor 0(%r9,%rax,1)
    xrstor -1(%r13,%r15,2)
    xrstor -2147483648(%r15,%rsi,4)
    xrstor 0(%rbx)
    xrstor 64(%rcx)
    xrstor 2147483647(%rdx)
    xrstor 0(%rsp)
    xrstor 8(%rsp)
    xrstor 4660(%rsp)
    xrstor 0(%rcx,%rbx,8)
    xrstor -128(%rdx,%rbp,1)
    xrstor 128(%rbx,%rsi,2)
    xrstor gnu_fwd(%rip)
    xrstor -129
    xsavec 0(%r9)
    xsavec 127(%r13)
    xsavec -2147483648(%r14)
    xsavec 0(%r12)
    xsavec -1(%r12)
    xsavec 2147483647(%r12)
    xsavec 0(%r10,%rcx,4)
    xsavec 64(%r8,%r9,8)
    xsavec 4660(%r9,%rbp,1)
    xsavec 0(%rsi)
    xsavec 8(%rbx)
    xsavec 128(%rbp)
    xsavec 0(%rsp)
    xsavec -128(%rsp)
    xsavec -129(%rsp)
    xsavec 0(%rdx,%rdi,2)
    xsavec 127(%rsp,%rax,4)
    xsavec -2147483648(%rbp,%rcx,8)
    xsavec gnu_back(%rip)
    xsavec 2147483647
    ldmxcsr 0(%r10)
    ldmxcsr -1(%r15)
    ldmxcsr 4660(%r8)
    ldmxcsr 0(%r12)
    ldmxcsr 64(%r12)
    ldmxcsr 128(%r12)
    ldmxcsr 0(%r11,%r12,1)
    ldmxcsr 8(%r12,%rax,2)
    ldmxcsr -129(%r13,%r15,4)
    ldmxcsr 0(%rdi)
    ldmxcsr -128(%rsi)
    ldmxcsr -2147483648(%rdi)
    ldmxcsr 0(%rsp)
    ldmxcsr 127(%rsp)
    ldmxcsr 2147483647(%rsp)
    ldmxcsr 0(%rbx,%rdx,8)
    ldmxcsr -1(%rsi,%rbx,1)
    ldmxcsr 4660(%rdi,%rbp,2)
    ldmxcsr gnu_fwd(%rip)
    ldmxcsr 128
    stmxcsr 0(%r11)
    stmxcsr 64(%r9)
    stmxcsr -129(%r10)
    stmxcsr 0(%r12)
    stmxcsr 8(%r12)
    stmxcsr -2147483648(%r12)
    stmxcsr 0(%r12,%rsi,4)
    stmxcsr -128(%r15,%rcx,8)
    stmxcsr 2147483647(%r8,%r9,1)
    stmxcsr 0(%rcx)
    stmxcsr 127(%rcx)
    stmxcsr 4660(%rdx)
    stmxcsr 0(%rsp)
    stmxcsr -1(%rsp)
    stmxcsr 128(%rsp)
    stmxcsr 0(%rsp,%rsi,2)
    stmxcsr 64(%rax,%rdi,4)
    stmxcsr -129(%rcx,%rax,8)
    stmxcsr gnu_back(%rip)
    stmxcsr -2147483648
    prefetcht0 0(%r14)
    prefetcht0 8(%r11)
    prefetcht0 2147483647(%r13)
    prefetcht0 0(%r12)
    prefetcht0 -128(%r12)
    prefetcht0 4660(%r12)
    prefetcht0 0(%r14,%rbp,1)
    prefetcht0 127(%r9,%r12,2)
    prefetcht0 128(%r12,%rax,4)
    prefetcht0 0(%rdx)
    prefetcht0 -1(%rbx)
    prefetcht0 -129(%rbp)
    prefetcht0 0(%rsp)
    prefetcht0 64(%rsp)
    prefetcht0 -2147483648(%rsp)
    prefetcht0 0(%rsi,%rcx,8)
    prefetcht0 8(%rdx,%rdx,1)
    prefetcht0 2147483647(%rbx,%rbx,2)
    prefetcht0 gnu_fwd(%rip)
    prefetcht0 4660
    prefetcht1 0(%r15)
    prefetcht1 -128(%r14)
    prefetcht1 128(%r15)
    prefetcht1 0(%r12)
    prefetcht1 127(%r12)
    prefetcht1 -129(%r12)
    prefetcht1 0(%r15,%r15,4)
    prefetcht1 -1(%r13,%rsi,8)
    prefetcht1 -2147483648(%r15,%rcx,1)
    prefetcht1 0(%rbx)
    prefetcht1 64(%rsi)
    prefetcht1 2147483647(%rdi)
    prefetcht1 0(%rsp)
    prefetcht1 8(%rsp)
    prefetcht1 4660(%rsp)
    prefetcht1 0(%rdi,%rbp,2)
    prefetcht1 -128(%rsp,%rsi,4)
    prefetcht1 128(%rbp,%rdi,8)
    prefetcht1 gnu_back(%rip)
    prefetcht1 -129
    prefetcht2 0(%r8)
    prefetcht2 127(%r8)
    prefetcht2 -2147483648(%r9)
    prefetcht2 0(%r12)
    prefetcht2 -1(%r12)
    prefetcht2 2147483647(%r12)
    prefetcht2 0(%r8,%r9,1)
    prefetcht2 64(%r8,%rbp,2)
    prefetcht2 4660(%r9,%r12,4)
    prefetcht2 0(%rsi)
    prefetcht2 8(%rcx)
    prefetcht2 128(%rdx)
    prefetcht2 0(%rsp)
    prefetcht2 -128(%rsp)
    prefetcht2 -129(%rsp)
    prefetcht2 0(%rax,%rax,8)
    prefetcht2 127(%rsi,%rcx,1)
    prefetcht2 -2147483648(%rdi,%rdx,2)
    prefetcht2 gnu_fwd(%rip)
    prefetcht2 2147483647
    prefetchnta 0(%r9)
    prefetchnta -1(%r10)
    prefetchnta 4660(%r11)
    prefetchnta 0(%r12)
    prefetchnta 64(%r12)
    prefetchnta 128(%r12)
    prefetchnta 0(%r9,%rax,4)
    prefetchnta 8(%r12,%r15,8)
    prefetchnta -129(%r13,%rsi,1)
    prefetchnta 0(%rdi)
    prefetchnta -128(%rbx)
    prefetchnta -2147483648(%rbp)
    prefetchnta 0(%rsp)
    prefetchnta 127(%rsp)
    prefetchnta 2147483647(%rsp)
    prefetchnta 0(%rcx,%rbx,2)
    prefetchnta -1(%rax,%rbp,4)
    prefetchnta 4660(%rcx,%rsi,8)
    prefetchnta gnu_back(%rip)
    prefetchnta 128
g84:
    xsave64 0(%rdx)
    xsave64 64(%r10)
    xsave64 -129(%rsi)
    xsave64 0(%rsp)
    xsave64 8(%r12)
    xsave64 -2147483648(%rsp)
    xsave64 0(%rsp,%rcx,1)
    xsave64 -128(%rax,%r9,2)
    xsave64 2147483647(%r9,%rbp,4)
    xsave64 gnu_fwd(%rip)
    xsave64 4660
    xrstor64 0(%r9)
    xrstor64 127(%r11)
    xrstor64 128(%rdi)
    xrstor64 0(%r12)
    xrstor64 -1(%rsp)
    xrstor64 -129(%r12)
    xrstor64 0(%r14,%r12,8)
    xrstor64 64(%rsp,%rax,1)
    xrstor64 -2147483648(%r13,%r15,2)
    xrstor64 gnu_back(%rip)
    xrstor64 2147483647
    xsavec64 0(%rbx)
    xsavec64 8(%r14)
    xsavec64 4660(%r15)
    xsavec64 0(%rsp)
    xsavec64 -128(%r12)
    xsavec64 128(%rsp)
    xsavec64 0(%rsi,%rsi,4)
    xsavec64 127(%rbp,%rcx,8)
    xsavec64 -129(%r12,%r9,1)
    xsavec64 gnu_fwd(%rip)
    xsavec64 -2147483648
    fxsave64 0(%r10)
    fxsave64 -1(%rcx)
    fxsave64 2147483647(%r8)
    fxsave64 0(%r12)
    fxsave64 64(%rsp)
    fxsave64 4660(%r12)
    fxsave64 0(%r15,%rbp,2)
    fxsave64 8(%rdi,%r12,4)
    fxsave64 128(%r15,%rax,8)
    fxsave64 gnu_back(%rip)
    fxsave64 -129
    fxrstor64 0(%rsi)
    fxrstor64 -128(%rbp)
    fxrstor64 -2147483648(%r13)
    fxrstor64 0(%rsp)
    fxrstor64 127(%r12)
    fxrstor64 2147483647(%rsp)
    fxrstor64 0(%rax,%r15,1)
    fxrstor64 -1(%rax,%rsi,2)
    fxrstor64 4660(%r9,%rcx,4)
    fxrstor64 gnu_fwd(%rip)
    fxrstor64 128
    movbe 0(%r11), %r14d
    movbe 64(%rdx), %r8d
    movbe -129(%r9), %r12d
    movbe 0(%r12), %r13d
    movbe 8(%rsp), %r15d
    movbe -2147483648(%r12), %r9d
    movbe 0(%r8,%r9,8), %r10d
    movbe -128(%rsp,%rbp,1), %r11d
    movbe 2147483647(%r13,%r12,2), %r14d
    movbe gnu_back(%rip), %r8d
    movbe 4660, %r12d
    movbe 0(%rcx), %edi
    movbe 127(%rsi), %ebp
    movbe 128(%rdi), %esp
    movbe 0(%rsp), %ecx
    movbe -1(%rsp), %edx
    movbe -129(%rsp), %ebx
    movbe 0(%rdx,%rdi,4), %esi
    movbe 64(%rdx,%rax,8), %edi
    movbe -2147483648(%rbx,%rcx,1), %ebp
    movbe gnu_fwd(%rip), %esp
    movbe 2147483647, %ecx
    movbe %r13d, 0(%rdi)
    movbe %r15d, 8(%rbx)
    movbe %r9d, 4660(%r10)
    movbe %r10d, 0(%rsp)
    movbe %r11d, -128(%r12)
    movbe %r14d, 128(%rsp)
    movbe %r8d, 0(%rcx,%rax,2)
    movbe %r12d, 127(%rbp,%r15,4)
    movbe %r13d, -129(%r12,%rsi,8)
    movbe %r15d, gnu_back(%rip)
    movbe %r9d, -2147483648
    movbe %edx, 0(%rdx)
    movbe %ebx, -1(%rcx)
    movbe %esi, 2147483647(%rdx)
    movbe %edi, 0(%rsp)
    movbe %ebp, 64(%rsp)
    movbe %esp, 4660(%rsp)
    movbe %ecx, 0(%rbx,%rdx,1)
    movbe %edx, 8(%rsp,%rbx,2)
    movbe %ebx, 128(%rbp,%rbp,4)
    movbe %esi, gnu_fwd(%rip)
    movbe %edi, -129
    movbe 0(%r14), %r10
    movbe -128(%rsi), %r11
    movbe -2147483648(%r11), %r14
    movbe 0(%r12), %r8
    movbe 127(%rsp), %r12
    movbe 2147483647(%r12), %r13
    movbe 0(%r12,%rcx,8), %r15
    movbe -1(%rdi,%r9,1), %r9
    movbe 4660(%r15,%rbp,2), %r10
    movbe gnu_back(%rip), %r11
    movbe 128, %r14
    movbe %r8, 0(%r15)
    movbe %r12, 64(%rdi)
    movbe %r13, -129(%r14)
    movbe %r15, 0(%rsp)
    movbe %r9, 8(%r12)
    movbe %r10, -2147483648(%rsp)
    movbe %r11, 0(%rdx,%r12,4)
    movbe %r14, -128(%rax,%rax,8)
    movbe %r8, 2147483647(%r9,%r15,1)
    movbe %r12, gnu_fwd(%rip)
    movbe %r13, 4660
    xtest
    xgetbv
    rdpkru
    wrpkru
    endbr64
    .byte 0x64
    .byte 0x65
    .byte 0x2e
    .byte 0x3e
    .byte 0x66
    .byte 0x67
    .byte 0x3e
gnu_fwd:
