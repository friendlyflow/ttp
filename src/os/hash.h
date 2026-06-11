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
#include <stddef.h>

struct node;

// SHA-256 of a buffer into out[32]. Used to content-address nodes (the Merkle
// key) and compiled binaries.
void sha256(const void *data, size_t len, uint8_t out[32]);

// The source id of a node: sha256(content || each non-meta child's source id),
// computed post-order. Stored into n->id (and every descendant's id) and copied
// to out[32]. meta is excluded, so caching a binary never changes an id.
void node_source_id(struct node *n, uint8_t out[32]);
