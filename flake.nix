{
  description = "ttp — the trust project: bare-metal x86_64 kernel";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });

      # Cross toolchain targeting x86_64-elf, providing the
      # `x86_64-elf-gcc` / `x86_64-elf-ld` binaries the Makefile expects.
      toolchain = pkgs: with pkgs.pkgsCross.x86_64-embedded.buildPackages; [
        gcc
        binutils
      ];
    in
    {
      devShells = forAllSystems ({ pkgs }: {
        default = pkgs.mkShell {
          packages = (toolchain pkgs) ++ (with pkgs; [
            nasm
            gnumake
            coreutils # dd
            qemu       # qemu-system-x86_64 for `make test`
          ]);
        };
      });

      packages = forAllSystems ({ pkgs }: {
        default = pkgs.stdenv.mkDerivation {
          pname = "ttp";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = (toolchain pkgs) ++ (with pkgs; [
            nasm
            gnumake
            coreutils
          ]);

          buildPhase = "make";

          installPhase = ''
            mkdir -p $out
            cp build/ttpos.img $out/
          '';
        };
      });
    };
}
