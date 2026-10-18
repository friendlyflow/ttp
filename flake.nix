{
  description = "ttp — the trust project: bare-metal RISC-V OS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    raddebugger = {
      url = "github:EpicGamesExt/raddebugger";
      flake = false;
    };
    # glibc as released upstream, pinned by its narHash in flake.lock: the
    # source src/glibc translates into ff (not nixpkgs' glibc, which is
    # patched).
    glibc-src = {
      url = "https://ftp.gnu.org/gnu/glibc/glibc-2.44.tar.xz";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, raddebugger, glibc-src }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });

      # Cross toolchain targeting bare-metal RISC-V, providing the
      # `riscv64-none-elf-gcc` / `-objdump` binaries src/os expects.
      toolchain = pkgs: with pkgs.pkgsCross.riscv64-embedded.buildPackages; [
        gcc
        binutils
      ];

      # GNU as for the other targets ttpc assembles for: the twins of the
      # ff programs it checks its encodings against.
      twins = pkgs: with pkgs.pkgsCross; [
        x86_64-embedded.buildPackages.binutils
        aarch64-embedded.buildPackages.binutils
        arm-embedded.buildPackages.binutils
      ];

      # glibc for riscv64 Linux, built from glibc-src (src/glibc): the
      # cross gcc and binutils of riscv64-unknown-linux-gnu, the kernel's
      # headers, what glibc's build needs, and clang (unwrapped: its .i are
      # already preprocessed, and the wrapper's host flags are no riscv64
      # flags) to read its C as a tree.
      glibcTools = pkgs: with pkgs; [
        pkgsCross.riscv64.buildPackages.gcc
        pkgsCross.riscv64.buildPackages.binutils
        bison
        python3
        llvmPackages.clang-unwrapped
      ];

      # RAD Debugger, built from source with upstream's build.sh. Its Linux
      # port is x86_64-only (hand-written BLAKE3 asm, -msse2/-mcx16).
      raddbg = pkgs: pkgs.clangStdenv.mkDerivation {
        pname = "raddbg";
        version = "unstable-${raddebugger.lastModifiedDate}";
        src = raddebugger;

        nativeBuildInputs = with pkgs; [ pkg-config llvmPackages.bintools makeWrapper ];
        buildInputs = with pkgs; [
          freetype
          libx11
          libxext
          libxfixes
          libxrandr
          libGL
        ];

        buildPhase = ''
          runHook preBuild
          bash build.sh raddbg release
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          install -Dm755 build/raddbg $out/bin/raddbg
          # Message boxes and the file picker shell out to zenity.
          wrapProgram $out/bin/raddbg --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.zenity ]}
          runHook postInstall
        '';

        meta.platforms = [ "x86_64-linux" ];
      };
      isX86Linux = pkgs: pkgs.stdenv.hostPlatform.system == "x86_64-linux";
    in
    {
      devShells = forAllSystems ({ pkgs }: {
        default = pkgs.mkShell {
          packages = (toolchain pkgs) ++ (twins pkgs) ++ (with pkgs; [
            gnumake
            qemu # qemu-system-riscv64 for `make os-test`, qemu-<arch> for the programs
            # src/compiler/gen/mkff.pl generates test.ff; c2ff.pl reads the ASTs
            # of glibc with JSON::XS (80 times faster than core JSON::PP)
            (perl.withPackages (p: [ p.JSONXS ]))
            fish
            # profiling and debugging ttpc where it runs natively (the host
            # builds): perf samples it, gdb looks inside
            perf
            gdb
          ]) ++ (glibcTools pkgs) ++ pkgs.lib.optional (isX86Linux pkgs) (raddbg pkgs);

          # For src/glibc: the pinned source, the kernel's headers, and the
          # cross gcc without nixpkgs' wrapper (which would add nixpkgs'
          # own glibc to every compile).
          GLIBC_SRC = "${glibc-src}";
          GLIBC_HEADERS = "${pkgs.pkgsCross.riscv64.linuxHeaders}/include";
          GLIBC_CC = "${pkgs.pkgsCross.riscv64.buildPackages.gcc.cc}/bin/riscv64-unknown-linux-gnu-gcc";
          C2FF_CLANG = "${pkgs.llvmPackages.clang-unwrapped}/bin/clang";

          # `nix develop` always starts bash; drop into fish instead.
          # Guard against re-exec loops and non-interactive invocations
          # (e.g. `nix develop -c make`).
          shellHook = ''
            if [ -z "$IN_NIX_FISH" ] && [ -t 1 ]; then
              export IN_NIX_FISH=1
              exec fish
            fi
          '';
        };
      });

      packages = forAllSystems ({ pkgs }: {
        default = pkgs.stdenv.mkDerivation {
          pname = "ttp";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = (toolchain pkgs) ++ (with pkgs; [
            gnumake
          ]);

          buildPhase = "make os";

          installPhase = ''
            mkdir -p $out
            cp build/os/os.elf $out/
          '';
        };
      } // pkgs.lib.optionalAttrs (isX86Linux pkgs) {
        raddbg = raddbg pkgs;
      });
    };
}
