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

#include "ata.h"
#include "io.h"

// Primary ATA bus I/O ports.
#define ATA_DATA    0x1F0
#define ATA_SECCNT  0x1F2
#define ATA_LBA0    0x1F3
#define ATA_LBA1    0x1F4
#define ATA_LBA2    0x1F5
#define ATA_DRIVE   0x1F6
#define ATA_STATUS  0x1F7   // read: status; write: command
#define ATA_CMD     0x1F7

#define ST_BSY 0x80
#define ST_DRQ 0x08
#define ST_ERR 0x01

#define CMD_READ  0x20
#define CMD_WRITE 0x30
#define CMD_FLUSH 0xE7

// Spin until BSY clears. Returns -1 if the drive flags an error.
static int ata_wait_ready(void) {
    uint8_t st;
    do { st = inb(ATA_STATUS); } while (st & ST_BSY);
    return (st & ST_ERR) ? -1 : 0;
}

// Wait for DRQ (data ready for one sector's transfer).
static int ata_wait_drq(void) {
    uint8_t st;
    for (;;) {
        st = inb(ATA_STATUS);
        if (st & ST_ERR) return -1;
        if (!(st & ST_BSY) && (st & ST_DRQ)) return 0;
    }
}

static void ata_select(uint32_t lba, uint8_t count) {
    ata_wait_ready();
    outb(ATA_DRIVE, 0xE0 | ((lba >> 24) & 0x0F));   // master, LBA mode
    outb(ATA_SECCNT, count);
    outb(ATA_LBA0, (uint8_t)(lba));
    outb(ATA_LBA1, (uint8_t)(lba >> 8));
    outb(ATA_LBA2, (uint8_t)(lba >> 16));
}

int ata_read(uint32_t lba, uint8_t count, void *buf) {
    uint16_t *p = (uint16_t *)buf;
    ata_select(lba, count);
    outb(ATA_CMD, CMD_READ);
    for (int s = 0; s < count; s++) {
        if (ata_wait_drq() < 0) return -1;
        for (int i = 0; i < ATA_SECTOR / 2; i++)
            p[i] = inw(ATA_DATA);
        p += ATA_SECTOR / 2;
    }
    return 0;
}

int ata_write(uint32_t lba, uint8_t count, const void *buf) {
    const uint16_t *p = (const uint16_t *)buf;
    ata_select(lba, count);
    outb(ATA_CMD, CMD_WRITE);
    for (int s = 0; s < count; s++) {
        if (ata_wait_drq() < 0) return -1;
        for (int i = 0; i < ATA_SECTOR / 2; i++)
            outw(ATA_DATA, p[i]);
        p += ATA_SECTOR / 2;
    }
    outb(ATA_CMD, CMD_FLUSH);     // flush the write cache to media
    return ata_wait_ready();
}
