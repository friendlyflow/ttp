# The Trust Project

**ttp** — the trust project: a self-hosting OS and compiler, a bare-metal RISC-V OS
([src/os](src/os)) and a content-addressed compiler ([src/compiler](src/compiler))
that grows organically from a minimal seed.

## Build

A [Nix](https://nixos.org) flake provides the cross toolchain
(`riscv64-none-elf-gcc`, `qemu`, …):

```sh
nix develop          # enter a shell with the toolchain
make                 # build everything  -> build/
make os              # build the OS       -> build/os/os.elf
make compiler        # build the compiler -> build/compiler/ttpc
make os-test         # boot the OS in a qemu-system-riscv64 window (Ctrl-D to quit)
make os-console      # same, serial console in this terminal (Ctrl-D or Ctrl-A X)
make clean           # remove build/
```

The root [Makefile](Makefile) calls the per-component Makefiles in
[src/os](src/os/Makefile) and [src/compiler](src/compiler/Makefile),
collecting their artifacts under `build/`.

## License

Copyright (C) 2026  Nico Verrijdt

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version. See [LICENSE](LICENSE) for the full text.
