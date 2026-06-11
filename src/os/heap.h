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

#pragma once
#include <stddef.h>

// Bump allocator. The heap lives in the free hole 0x100000..0x1F0000 inside the
// 2 MB identity-mapped region (above the 1 MB mark, below the 2 MB page top).
// malloc advances a brk pointer; free is a no-op for now. This is enough to load
// and navigate the ff tree. A real free-list arrives with editing (M7).
//
// The standard names let the shared node.h core call malloc/realloc/calloc/free
// unchanged, both here and in the host build.

void   heap_init(void);
void  *malloc(size_t n);
void   free(void *p);
void  *realloc(void *p, size_t n);
void  *calloc(size_t count, size_t size);

size_t heap_used(void);   // bytes handed out so far
size_t heap_free(void);   // bytes still available before OOM
