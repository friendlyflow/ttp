# Disassembly: full 16 -> 32 -> 64 bit boot flow into boot_flow.txt

`boot_flow.txt` is both human documentation *and* the input the bootstrap
compiler (`src/compiler/ttpc`) re-assembles back into a bootable disk image. So
two rules drive how it is generated:

* **Addresses are disk offsets, not load addresses.** ttpc writes each line's
  bytes into the image at the address in the first column (`fseek`), so that
  address must be where the bytes live *in the .img file*, not where the CPU
  runs them at boot. The three regions sit at the offsets `src/os/Makefile`
  `dd`s them to: boot.bin @ `0x0`, kernel32.bin @ `0x200`, kernel.bin @ `0x1200`
  (sectors 0, 1, 9). Their *load* addresses (`0x7C00` / `0x10000` / `0x11000`)
  are noted in the banners for reading only. We set them with `--adjust-vma`.
* **Everything is disassembled, code and data alike, with `-D`.** ttpc only
  reads the raw-byte column of each line; the mnemonic is informational. So
  even GDT tables and string literals are dumped with `-D` (they show as
  garbage / `(bad)` mnemonics, but the bytes round-trip exactly). objdump
  collapses long zero runs to `...`, which ttpc skips — those gaps become zero
  holes in the image, exactly the padding we want.

Each stage runs in a different CPU mode, so each region is disassembled in its
own mode, against the flat `.bin` files (no ELF). Run from `src/os/` after
`make` (so `build/boot.bin` etc. exist).

The kernel32.bin region offsets below come from the NASM listing — regenerate
and re-read them if kernel32.asm changes:
    nasm -f bin kernel32.asm -l /tmp/k32.lst   # offset = 2nd column per label

```bash
BUILD=../../build/os                              # where `make` drops the .bin files

# carve kernel32.bin into its mode/data regions (skip/count in DECIMAL bytes)
#   0x00..0x1A 16-bit | 0x1A..0x8D 32-bit | 0x8D..0xED GDT data | 0xED..0x103 64-bit
dd if=$BUILD/kernel32.bin of=/tmp/k32_16.bin   bs=1 skip=0   count=26  status=none
dd if=$BUILD/kernel32.bin of=/tmp/k32_32.bin   bs=1 skip=26  count=115 status=none
dd if=$BUILD/kernel32.bin of=/tmp/k32_data.bin bs=1 skip=141 count=96  status=none
dd if=$BUILD/kernel32.bin of=/tmp/k32_64.bin   bs=1 skip=237 count=22  status=none
OD=x86_64-elf-objdump

# --adjust-vma = the region's DISK OFFSET in ttpos.img (not its load address).
{
  echo "[1] boot.bin       disk 0x0    (loads @0x7C00)  16-bit"
  $OD -D -b binary -mi386 -Mintel,addr16,data16 --adjust-vma=0x0    $BUILD/boot.bin
  echo "[2a] kernel32.bin  disk 0x200  (loads @0x10000) 16-bit"
  $OD -D -b binary -mi386 -Mintel,addr16,data16 --adjust-vma=0x200  /tmp/k32_16.bin
  echo "[2b] kernel32.bin  disk 0x21A  (loads @0x1001A) 32-bit (pmode32)"
  $OD -D -b binary -mi386 -Mintel               --adjust-vma=0x21A  /tmp/k32_32.bin
  echo "[2c] kernel32.bin  disk 0x28D  (loads @0x1008D) DATA (GDT32 + GDT64)"
  $OD -D -b binary -mi386                        --adjust-vma=0x28D  /tmp/k32_data.bin
  echo "[2d] kernel32.bin  disk 0x2ED  (loads @0x100ED) 64-bit (long_mode)"
  $OD -D -b binary -mi386:x86-64 -Mintel         --adjust-vma=0x2ED  /tmp/k32_64.bin
  echo "[3] kernel.bin     disk 0x1200 (loads @0x11000) 64-bit (code + .rodata)"
  $OD -D -b binary -mi386:x86-64 -Mintel         --adjust-vma=0x1200 $BUILD/kernel.bin
} > boot_flow.txt
```

Key flags: `-b binary` = raw flat file (no ELF headers), `-D` = disassemble
*all* bytes incl. data, `-m` picks the CPU mode the flat binary doesn't record
(`i386` real/prot, `i386:x86-64` long), `--adjust-vma` sets the disk offset,
`-Mintel` = NASM-style syntax, `-Maddr16,data16` = 16-bit. Stage [3] dumps the
flat `kernel.bin` (not a re-linked ELF): the OS does not use ELF, and the flat
binary is what actually lands on disk, so its bytes — string literals included —
reproduce the image verbatim. The string text shows up as bogus instructions in
the dump (objdump's `-D` decodes data as code); that is expected and harmless,
because only the raw bytes are re-assembled.

## Re-assembling into a bootable image

`ttpc` reads this file and writes the bytes back to their disk offsets:

```bash
make compiler                                          # build build/compiler/ttpc
./build/compiler/ttpc src/os/boot_flow.txt build/compiler/ttpos.img
cmp build/os/ttpos.img build/compiler/ttpos.img        # must be identical
make compiler-test                                     # boot it in QEMU
```

The `cmp` is the round-trip check: a faithful re-assembly is byte-for-byte equal
to the `dd`-built OS image (zeros vs. holes compare equal).
