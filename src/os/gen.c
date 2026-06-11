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

#include "gen.h"
#include "ata.h"
#include "heap.h"
#include "string.h"
#include "hash.h"
#include <node.h>

// On-disk layout (in the free tail of the 2048-sector image, past the kernel):
//   LBA 1024            : superblock (1 sector)
//   LBA 1088 + i*60     : generation i's serialized node stream (<= 30 KB)
#define GEN_SUPER_LBA   1024
#define GEN_BASE_LBA    1088
#define GEN_SLOT_SECS   60
#define GEN_MAGIC       0x47505454u            // 'TTPG'

struct gen_slot {
    uint8_t  root_id[32];
    uint32_t len;                              // serialized byte length
    uint32_t pad;
};

struct gen_super {
    uint32_t magic;
    uint32_t count;
    uint32_t current;
    uint32_t pad;
    struct gen_slot slot[GEN_MAX];             // 16 + 12*40 = 496 <= 512
};

// The superblock lives in a full sector buffer so we can read/write it directly.
static uint8_t superbuf[ATA_SECTOR];
static struct gen_super *S = (struct gen_super *)superbuf;

void gen_init(void) {
    if (ata_read(GEN_SUPER_LBA, 1, superbuf) != 0 || S->magic != GEN_MAGIC) {
        memset(superbuf, 0, sizeof superbuf);
        S->magic = GEN_MAGIC;
        S->count = 0;
        S->current = 0;
    }
}

int gen_count(void) { return (int)S->count; }
int gen_current(void) { return (int)S->current; }

const uint8_t *gen_root_id(int i) {
    if (i < 0 || i >= (int)S->count) return NULL;
    return S->slot[i].root_id;
}

static uint32_t lba_of(int i) { return GEN_BASE_LBA + (uint32_t)i * GEN_SLOT_SECS; }

struct node *gen_load(int i) {
    if (i < 0 || i >= (int)S->count) return NULL;
    uint32_t len = S->slot[i].len;
    if (len == 0 || len > GEN_SLOT_SECS * ATA_SECTOR) return NULL;
    uint32_t secs = (len + ATA_SECTOR - 1) / ATA_SECTOR;
    uint8_t *buf = (uint8_t *)malloc(secs * ATA_SECTOR);
    if (!buf) return NULL;
    if (ata_read(lba_of(i), (uint8_t)secs, buf) != 0) return NULL;
    return node_read_mem(buf, len);
}

int gen_save(struct node *root) {
    if (S->count >= GEN_MAX) return -1;        // log full (no eviction yet)

    size_t len = 0;
    node_write_mem(root, NULL, 0, &len);       // measure
    if (len == 0 || len > GEN_SLOT_SECS * ATA_SECTOR) return -1;

    uint32_t secs = ((uint32_t)len + ATA_SECTOR - 1) / ATA_SECTOR;
    uint8_t *buf = (uint8_t *)malloc(secs * ATA_SECTOR);
    if (!buf) return -1;
    memset(buf, 0, secs * ATA_SECTOR);         // clean the tail of the last sector
    if (node_write_mem(root, buf, secs * ATA_SECTOR, NULL) != 0) return -1;

    int idx = (int)S->count;
    if (ata_write(lba_of(idx), (uint8_t)secs, buf) != 0) return -1;

    node_source_id(root, S->slot[idx].root_id);
    S->slot[idx].len = (uint32_t)len;
    S->count = (uint32_t)idx + 1;
    S->current = (uint32_t)idx;
    if (ata_write(GEN_SUPER_LBA, 1, superbuf) != 0) return -1;
    return idx;
}

void gen_set_current(int i) {
    if (i < 0 || i >= (int)S->count) return;
    S->current = (uint32_t)i;
    ata_write(GEN_SUPER_LBA, 1, superbuf);
}
