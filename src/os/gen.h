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
#include <stdint.h>

struct node;

// Generations — NixOS-style. Each save serializes the ff tree to a fixed disk
// slot and records its root id in a superblock; a later boot can load any of
// them, so an edit can be rolled back by booting an earlier generation.

#define GEN_MAX 12

void           gen_init(void);            // read the superblock (format if absent)
int            gen_count(void);           // number of saved generations
const uint8_t *gen_root_id(int i);        // generation i's 32-byte root id, or NULL
struct node   *gen_load(int i);           // rebuild generation i's tree, or NULL
int            gen_save(struct node *root);// write a new generation; returns its index or -1
void           gen_set_current(int i);    // persist which generation was booted
int            gen_current(void);         // the generation recorded as booted
