; ttp — the trust project: a self-hosting OS and compiler.
; Copyright (C) 2026  Nico Verrijdt
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <https://www.gnu.org/licenses/>.

[bits 16]
[org 0x7C00]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Load the rest of the OS (stage2 + kernel) with the INT 13h extended read
    ; (AH=42h, LBA + Disk Address Packet). Unlike the CHS read it replaced, this
    ; does not cap at one track, so the kernel can keep growing past ~32 KB.
    mov ah, 0x42
    mov dl, 0x80
    mov si, dap
    int 0x13
    jc disk_error

    jmp 0x1000:0x0000

disk_error:
    hlt
    jmp disk_error

; Disk Address Packet: load SECTORS sectors from LBA 1 (stage2) to 0x1000:0000
; (physical 0x10000). 127 sectors = ~63 KB, well clear of the kernel stack.
dap:
    db 0x10          ; packet size
    db 0x00          ; reserved
    dw 127           ; sectors to transfer
    dw 0x0000        ; destination offset
    dw 0x1000        ; destination segment -> 0x10000
    dq 1             ; starting LBA (stage2 sits at LBA 1)

times 510 - ($ - $$) db 0
dw 0xAA55