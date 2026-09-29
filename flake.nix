{
  description = "ttp — the trust project: bare-metal RISC-V OS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
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
    in
    {
      devShells = forAllSystems ({ pkgs }: {
        default = pkgs.mkShell {
          packages = (toolchain pkgs) ++ (with pkgs; [
            gnumake
            qemu # qemu-system-riscv64 for `make os-test`
            fish
          ]);

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
      });
    };
}
