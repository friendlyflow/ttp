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

    ; Load the OS (stage2 + kernel) with the INT 13h extended read (AH=42h, LBA +
    ; Disk Address Packet), in 64-sector / 32 KB chunks to successive real-mode
    ; segments. A single DAP call can't cross a 64 KB segment, so chunking lets
    ; the kernel grow far past one segment (here: 8 * 32 KB = 256 KB).
    mov cx, 8                       ; 8 chunks
.load:
    mov ah, 0x42
    mov dl, 0x80
    mov si, dap
    int 0x13
    jc disk_error
    add word [dap_seg], 0x800       ; advance 32 KB (0x8000 / 16) in the segment
    add dword [dap_lba], 64         ; next 64 LBAs
    dec cx
    jnz .load

    jmp 0x1000:0x0000

disk_error:
    hlt
    jmp disk_error

; Disk Address Packet: one 64-sector chunk; dap_seg and dap_lba advance per chunk.
; Chunk 0 lands at 0x1000:0000 (physical 0x10000); stage2 sits at LBA 1.
dap:
    db 0x10          ; packet size
    db 0x00          ; reserved
    dw 64            ; sectors per chunk
    dw 0x0000        ; destination offset
dap_seg:
    dw 0x1000        ; destination segment (advances +0x800 per chunk)
dap_lba:
    dq 1             ; starting LBA (advances +64 per chunk)

times 510 - ($ - $$) db 0
dw 0xAA55