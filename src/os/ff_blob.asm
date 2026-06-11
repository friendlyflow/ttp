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

; The "ff" — the serialized node program — embedded into the kernel image as a
; read-only blob. At boot the kernel rebuilds the tree from it with
; node_read_mem(ff_blob_start, ff_blob_end - ff_blob_start). M8 replaces this
; with loading the nodes from disk; the format and the load call stay the same.

[bits 64]
section .rodata

global ff_blob_start
global ff_blob_end

ff_blob_start:
    incbin "ff/program.nodes"
ff_blob_end:
