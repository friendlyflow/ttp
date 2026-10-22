# The Trust Project

**ttp** — the trust project: a self-hosting OS and compiler, a bare-metal RISC-V OS
([src/os](src/os)) and a content-addressed compiler ([src/compiler](src/compiler))
that grows organically from a minimal seed.

## Build

A [Nix](https://nixos.org) flake provides the cross toolchain
(`riscv64-none-elf-gcc`, `qemu`, …) and GNU as for x86_64, aarch64 and arm
(to check ttpc's encodings against):

```sh
nix develop          # enter a shell with the toolchain
make                 # build everything  -> build/
make os              # build the OS       -> build/os/os.elf
make compiler        # build the compiler -> build/compiler/ttpc
make compiler-check  # assemble the ff test programs, compare with GNU as, run them; build and run the C ones,
                     # for riscv64, x86_64, aarch64 and arm
make bootstrap       # ttpc assembles itself from ff (see src/compiler/PLAN.md)
make os-test         # boot the OS in a qemu-system-riscv64 window (Ctrl-D to quit)
make os-console      # same, serial console in this terminal (Ctrl-D or Ctrl-A X)
make clean           # remove build/
```

ttpc builds for four targets: `ttpc --target x86_64 shared.ff prog.ff out`
(riscv64, x86_64, aarch64, arm; riscv64 without `--target`). `ttpc build.ff`
runs a build file, which says itself what to build (`include`, `workspace`,
`add file`, `compile`, as in Jai). It runs on
riscv64 itself, under `qemu-riscv64` elsewhere; see
[src/compiler/PLAN.md](src/compiler/PLAN.md).

The root [Makefile](Makefile) calls the per-component Makefiles in
[src/os](src/os/Makefile) and [src/compiler](src/compiler/Makefile),
collecting their artifacts under `build/`.

## License

Copyright (C) 2026  Nico Verrijdt

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, version 3 of the License (GPL-3.0-only). See [LICENSE](LICENSE)
for the full text.
