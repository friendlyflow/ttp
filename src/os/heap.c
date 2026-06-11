/*
 * ttp — the trust project: a self-hosting OS and compiler.
 * Copyright (C) 2026  Nico Verrijdt
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "heap.h"
#include "string.h"
#include <stdint.h>

// Free hole inside the 2 MB identity map: above 1 MB, below the 2 MB page top.
#define HEAP_START 0x100000UL
#define HEAP_END   0x1F0000UL

// Each block carries a 16-byte header storing its usable size (so realloc knows
// how much to copy). 16 bytes keeps the returned payload 16-byte aligned.
#define HDR 16

static uint64_t cur;   // next free address; 0 until initialized

void heap_init(void) { cur = HEAP_START; }

void *malloc(size_t n) {
    if (cur == 0) heap_init();
    size_t a = (n + 15) & ~(size_t)15;      // round up to 16
    uint64_t base = cur;
    if (base + HDR + a > HEAP_END) return NULL;   // OOM
    *(uint64_t *)base = a;                   // remember usable size
    cur = base + HDR + a;
    return (void *)(base + HDR);
}

// Bump allocator: nothing is reclaimed yet. A real free-list arrives in M7.
void free(void *p) { (void)p; }

void *realloc(void *p, size_t n) {
    if (!p) return malloc(n);
    uint64_t old = *(uint64_t *)((uint64_t)p - HDR);
    void *q = malloc(n);
    if (q) memcpy(q, p, old < n ? old : n);
    return q;
}

void *calloc(size_t count, size_t size) {
    size_t n = count * size;
    void *p = malloc(n);
    if (p) memset(p, 0, n);
    return p;
}

size_t heap_used(void) { return (size_t)(cur - HEAP_START); }
size_t heap_free(void) { return (size_t)(HEAP_END - cur); }
