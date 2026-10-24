/* SPDX-License-Identifier: GPL-3.0-only
 * Copyright (C) 2026 Nico Verrijdt
 * This file is part of ttp. It is free software: you can redistribute it
 * and/or modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, version 3 of the License.
 * It comes with no warranty. See the file LICENSE for the full text.
 *
 * unwind.c FILE: libgcc's unwinder walks the frames of an ff program built
 * with ttpc -g (progs/cdebug.ff). gcc builds this (static, against glibc's
 * libc.a and libgcc_eh) far from ff's addresses; it maps FILE's PT_LOAD
 * where FILE says, gives libgcc FILE's frames (.eh_frame through
 * PT_GNU_EH_FRAME, __register_frame; arm's .ARM.exidx through PT_ARM_EXIDX,
 * which __gnu_Unwind_Find_exidx returns for its addresses), points FILE's
 * hook at walk and calls deep (3): walk runs _Unwind_Backtrace and prints
 * each frame by FILE's symbols (.symtab), "gcc" for one of this program's,
 * up to the first of this program's past FILE's. */
#include <unwind.h>

typedef unsigned long ulong;
int open(const char *, int, ...);
long read(int, void *, ulong);
void *mmap(void *, ulong, int, int, int, long);
int printf(const char *, ...);
void *memcpy(void *, const void *, ulong);
int strcmp(const char *, const char *);
void __register_frame(void *);

#if __SIZEOF_POINTER__ == 8
typedef struct { unsigned char ident[16]; unsigned short type, machine; unsigned version; ulong entry, phoff, shoff; unsigned flags; unsigned short ehsize, phentsize, phnum, shentsize, shnum, shstrndx; } Ehdr;
typedef struct { unsigned type, flags; ulong offset, vaddr, paddr, filesz, memsz, align; } Phdr;
typedef struct { unsigned name, type; ulong flags, addr, offset, size; unsigned link, info; ulong addralign, entsize; } Shdr;
typedef struct { unsigned name; unsigned char info, other; unsigned short shndx; ulong value, size; } Sym;
#else
typedef struct { unsigned char ident[16]; unsigned short type, machine; unsigned version; ulong entry, phoff, shoff; unsigned flags; unsigned short ehsize, phentsize, phnum, shentsize, shnum, shstrndx; } Ehdr;
typedef struct { unsigned type; ulong offset, vaddr, paddr, filesz, memsz; unsigned flags; ulong align; } Phdr;
typedef struct { unsigned name, type; ulong flags, addr, offset, size; unsigned link, info; ulong addralign, entsize; } Shdr;
typedef struct { unsigned name; ulong value, size; unsigned char info, other; unsigned short shndx; } Sym;
#endif

static unsigned char file[1 << 22];
static Sym *syms;
static ulong nsyms;
static const char *strs;
static ulong lo, hi;
static int ff_seen, frames;

static const char *name_of(ulong ip)
{
    if (ip < lo || ip >= hi)
        return 0;
    for (ulong i = 0; i < nsyms; i++)
        if ((syms[i].info & 15) == 2 && ip >= syms[i].value && ip < syms[i].value + syms[i].size)
            return strs + syms[i].name;
    return "?";
}

static ulong sym(const char *n)
{
    for (ulong i = 0; i < nsyms; i++)
        if (!strcmp(strs + syms[i].name, n))
            return syms[i].value;
    return 0;
}

static _Unwind_Reason_Code trace(struct _Unwind_Context *c, void *a)
{
    ulong ip = _Unwind_GetIP(c) - 1;
    const char *n = name_of(ip);
    (void) a;
    if (++frames > 32)
        return _URC_END_OF_STACK;
    printf("%s\n", n ? n : "gcc");
    if (n)
        ff_seen = 1;
    else if (ff_seen)
        return _URC_END_OF_STACK;
    return _URC_NO_REASON;
}

#ifdef __x86_64__
__attribute__((force_align_arg_pointer))
#endif
static long walk(long x)
{
    _Unwind_Backtrace(trace, 0);
    return x;
}

#ifdef __arm__
static ulong exidx, nexidx;
extern char __exidx_start[], __exidx_end[];
_Unwind_Ptr __gnu_Unwind_Find_exidx(_Unwind_Ptr pc, int *n)
{
    if (pc >= lo && pc < hi) {
        *n = nexidx;
        return exidx;
    }
    *n = (__exidx_end - __exidx_start) / 8;
    return (_Unwind_Ptr) __exidx_start;
}
#endif

int main(int argc, char **argv)
{
    Ehdr *e = (Ehdr *) file;
    int fd = argc == 2 ? open(argv[1], 0) : -1;
    long len = 0, r;
    if (fd < 0)
        return printf("usage: unwind FILE\n"), 2;
    while ((r = read(fd, file + len, sizeof file - len)) > 0)
        len += r;
    void *eh = 0;
    for (int i = 0; i < e->phnum; i++) {
        Phdr *p = (Phdr *) (file + e->phoff + i * e->phentsize);
        if (p->type == 1 && !hi) {
            ulong page = p->vaddr & ~4095ul;
            if (mmap((void *) page, p->vaddr + p->memsz - page, 7, 0x32, -1, 0) != (void *) page)
                return printf("unwind: no memory at %lx\n", page), 1;
            memcpy((void *) p->vaddr, file + p->offset, p->filesz);
            lo = p->vaddr, hi = p->vaddr + p->memsz;
        }
        if (p->type == 0x6474e550) {
            unsigned char *h = (unsigned char *) p->vaddr;
            eh = h + 4 + *(int *) (h + 4);
        }
#ifdef __arm__
        if (p->type == 0x70000001)
            exidx = p->vaddr, nexidx = p->memsz / 8;
#endif
    }
    for (int i = 0; i < e->shnum; i++) {
        Shdr *s = (Shdr *) (file + e->shoff + i * e->shentsize);
        if (s->type == 2) {
            syms = (Sym *) (file + s->offset), nsyms = s->size / sizeof (Sym);
            strs = (char *) file + ((Shdr *) (file + e->shoff + s->link * e->shentsize))->offset;
        }
    }
    if (!eh || !syms)
        return printf("unwind: %s has no .eh_frame or .symtab\n", argv[1]), 1;
#ifndef __arm__
    __register_frame(eh);
#endif
    long (**hook)(long) = (long (**)(long)) sym("hook");
    long (*deep)(long) = (long (*)(long)) sym("deep");
    if (!hook || !deep)
        return printf("unwind: no hook or deep\n"), 1;
    *hook = walk;
    printf("deep 3: %ld\n", deep(3));
    return 0;
}
