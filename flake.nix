{
  description = "Kernel Boot Tests for Cloud Hypervisor";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [
      "x86_64-linux"

      # TODO This should work, when we fix the hardcoded references to
      # bzImage below.
      #
      # "aarch64-linux"
    ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = nixpkgs.lib;
      in {
        packages = {
          hello = pkgs.pkgsStatic.callPackage ./init.nix {};

          helloInitrd = pkgs.runCommand "hello-initrd" {
            nativeBuildInputs = with pkgs; [
              libarchive
            ];
          } ''
            mkdir -p root
            install -m 0555 ${lib.getExe self.packages.${system}.hello} root/init
            bsdtar -cf root.cpio --format newc -C root init
            mv root.cpio $out
          '';

          kernel = pkgs.linux_6_6;

          bootDir = pkgs.runCommand "boot-dir" {} ''
            mkdir -p $out
            cp ${self.packages.${system}.kernel}/bzImage $out/
            cp ${self.packages.${system}.helloInitrd} $out/initrd
          '';

          bootTest = pkgs.writeShellScriptBin "boot-kernel" ''
            DIR=${self.packages.${system}.bootDir}

            ${lib.getExe pkgs.cloud-hypervisor} \
              --kernel "$DIR/bzImage" \
              --initramfs "$DIR/initrd" \
              --cmdline "console=ttyS0" \
              --console off \
              --serial tty
          '';
        };

        checks.default = pkgs.runCommand "boot-test" {} ''
          # TODO This requires nested virtualization.
          timeout 60 ${lib.getExe self.packages.${system}.bootTest} | tee test.log

          grep -Fq "HELLO WORLD" test.log

          mv test.log $out
        '';
      });
}
