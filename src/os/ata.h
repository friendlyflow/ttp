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

#define ATA_SECTOR 512

// Polled ATA PIO read/write of the primary master (LBA28). buf must hold
// count*512 bytes. Return 0 on success, -1 on a drive error. count is 1..255.
// QEMU's default `pc` machine exposes this drive at the legacy 0x1F0 ports.
int ata_read(uint32_t lba, uint8_t count, void *buf);
int ata_write(uint32_t lba, uint8_t count, const void *buf);
