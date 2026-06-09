# The Trust Project

**ttp** — the trust project: a self-hosting OS and compiler, a bare-metal x86_64 kernel
([src/os](src/os)) and a content-addressed compiler ([src/compiler](src/compiler))
that grows organically from a minimal seed.

## Build

A [Nix](https://nixos.org) flake provides the cross toolchain
(`x86_64-elf-gcc`, `nasm`, `qemu`, …):

```sh
nix develop          # enter a shell with the toolchain
make                 # build everything  -> build/
make os              # build the OS image -> build/os/myos.img
make compiler        # build the compiler -> build/compiler/ttpc
make test            # boot the OS image in qemu
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
