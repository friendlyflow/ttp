# Disassembly: full 16 -> 32 -> 64 bit boot flow into boot_flow.txt

Each stage runs in a different CPU mode, so each region is disassembled in its
own mode. The kernel objects are re-linked to ELF (kept symbols) instead of the
Makefile's `--oformat binary`. Run from src_os/ after `ninja -C build` / `make`.

The kernel32.bin region offsets below come from the NASM listing — regenerate
and re-read them if kernel32.asm changes:
    nasm -f bin kernel32.asm -l /tmp/k32.lst   # offset = 2nd column per label

```bash
# stage 3 needs an ELF (with symbols); same link as the Makefile minus --oformat binary
x86_64-elf-ld -T linker.ld -o build/kernel.elf \
  build/kernel_entry.o build/kernel_main.o build/vga.o build/tss.o \
  build/syscall.o build/userspace.o build/user_program.o

# carve kernel32.bin into its mode/data regions (skip/count in DECIMAL bytes)
#   0x00..0x1A 16-bit | 0x1A..0x8D 32-bit | 0x8D..0xED GDT data | 0xED..0x103 64-bit
dd if=build/kernel32.bin of=/tmp/k32_16.bin   bs=1 skip=0   count=26  status=none
dd if=build/kernel32.bin of=/tmp/k32_32.bin   bs=1 skip=26  count=115 status=none
dd if=build/kernel32.bin of=/tmp/k32_data.bin bs=1 skip=141 count=96  status=none
dd if=build/kernel32.bin of=/tmp/k32_64.bin   bs=1 skip=237 count=22  status=none
OD=x86_64-elf-objdump

{
  echo "[1] boot.bin       16-bit @0x7C00"
  $OD -D -b binary -mi386 -Mintel,addr16,data16 --adjust-vma=0x7C00  build/boot.bin
  echo "[2a] kernel32.bin  16-bit @0x10000"
  $OD -D -b binary -mi386 -Mintel,addr16,data16 --adjust-vma=0x10000 /tmp/k32_16.bin
  echo "[2b] kernel32.bin  32-bit @0x1001A (pmode32)"
  $OD -D -b binary -mi386 -Mintel                --adjust-vma=0x1001A /tmp/k32_32.bin
  echo "[2c] kernel32.bin  DATA  @0x1008D (GDT32 + GDT64 tables)"
  $OD -s -b binary                               --adjust-vma=0x1008D /tmp/k32_data.bin
  echo "[2d] kernel32.bin  64-bit @0x100ED (long_mode)"
  $OD -D -b binary -mi386:x86-64 -Mintel         --adjust-vma=0x100ED /tmp/k32_64.bin
  echo "[3] kernel.elf     64-bit @0x11000 (symbols)"
  $OD -d -Mintel build/kernel.elf
  echo "[4] kernel.elf     .rodata string literals (data, not code)"
  # GCC merges string literals into .rodata.str1.* (sizes/names vary with the
  # optimizer), so auto-collect every .rodata* section instead of hard-coding.
  RODATA=$($OD -h build/kernel.elf | awk '/\.rodata/{printf " -j %s", $2}')
  $OD -s $RODATA build/kernel.elf
} > boot_flow.txt
```

Key flags: `-b binary` = raw (no ELF headers), `-m` picks the CPU mode the flat
binary doesn't record (`i386` real/prot, `i386:x86-64` long), `--adjust-vma` sets
the real load address, `-Mintel` = NASM-style syntax, `-Maddr16,data16` = 16-bit.
Stage [4] uses `-s` (raw section contents + ASCII) because the strings are data:
`-d` only disassembles code, so the printed text never appears in a code dump —
you only see the pointers (`movabs rdi,0x116b8`) the call sites load.
