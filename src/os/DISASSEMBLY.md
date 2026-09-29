# Disassembly: the RISC-V OS image into boot_flow.txt

`boot_flow.txt` is both human documentation *and* the input the bootstrap
compiler (`src/compiler/ttpc`) re-assembles back into a bootable image. There
are no boot stages: QEMU's `virt` machine with `-bios none` drops the whole
image at `0x80000000` and jumps to its first byte in M-mode. So the file is one
region, dumped from `os.elf` in a single pass:

```bash
make -C src/os disasm      # (re)builds os.elf, writes src/os/boot_flow.txt
```

which runs, from `src/os/`:

```bash
{
  echo "[1] os.elf  file 0x0  (loads @0x80000000)  rv64 (.text + .rodata)"
  riscv64-none-elf-objdump -D -j .text -j .rodata $BUILD/os.elf | awk -f boot_flow.awk
} > boot_flow.txt
```

Run it after any change to the OS so the round-trip stays valid.

Three rules drive how it is generated:

* **The address column is a file offset, not a load address.** ttpc writes
  each line's bytes into the image at the address in the first column
  (`fseek`), so that address must be where the bytes live *in the flat
  `os.bin`*, i.e. the runtime address minus `0x80000000`. objdump dumps the ELF
  at its runtime addresses (so symbols resolve), and `boot_flow.awk` rewrites
  only the first column. Labels (`<_start>`, `<kmain>`), branch targets and
  `#` comments keep their runtime addresses, for reading.
* **Bytes are in memory order.** objdump prints a RISC-V instruction as one
  little-endian number (`f14022f3`, or `02a1` for a compressed one); ttpc reads
  space-separated bytes in the order they sit in memory. `boot_flow.awk`
  rewrites the column: `f14022f3` -> `f3 22 40 f1`.
* **Everything is disassembled, code and data alike, with `-D`.** ttpc only
  reads the address and raw-byte columns; the mnemonic is informational. So the
  string literals in `.rodata` are dumped with `-D` too (they show as bogus
  instructions: `unimp`, `.insn`, `fld`, ...), but the bytes round-trip
  exactly. objdump collapses long zero runs to `...`, which ttpc skips; those
  gaps become zero holes in the image, exactly the padding we want.

Only `.text` and `.rodata` are dumped: they are all of the image. `.bss` and
the boot stack have no bytes in the file (`entry.S` zeroes `.bss` at boot), and
there is no `.data` yet. If initialised globals appear, add `-j .data -j .sdata`.

Key flags: `-D` = disassemble *all* bytes incl. data, `-j` = only these
sections (skips `.riscv.attributes` and `.comment`, which aren't loaded). The
ELF records the ISA (`rv64imac`), so no `-m` is needed.

## Re-assembling into a bootable image

`ttpc` reads this file and writes the bytes back to their file offsets:

```bash
make os compiler                                       # build os.elf and ttpc
make -C src/os bin                                     # flat build/os/os.bin
./build/compiler/ttpc src/os/boot_flow.txt build/compiler/ttpos.img
cmp -n $(stat -c%s build/os/os.bin) build/os/os.bin build/compiler/ttpos.img
make compiler-test                                     # boot it in QEMU
```

The `cmp` is the round-trip check: a faithful re-assembly is byte-for-byte equal
to `os.bin` (objcopy's flat image of `os.elf`). `-n` limits the compare to
`os.bin`'s length, because ttpc pads its output with zeros to 1 MiB.
`compiler-test` boots the result with `-kernel` just like `make os-test`; QEMU
loads a raw image at `0x80000000` the same way it loads the ELF.

ttpc decodes every RISC-V instruction line into its fields (opcode, funct
bits, registers, immediate; compressed ones too) and rebuilds the bytes from
them. Lines that are no instruction (the `unimp` padding and the `.rodata`
strings) are *passed through*: their raw bytes go straight into the image.
Each decoded `.text` line is also re-assembled from its mnemonic and operands,
checking ttpc's encoder against objdump's text.
