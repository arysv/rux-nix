{
  description = "Rux Programming Language";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    cmake-nix.url = "github:arysv/cmake-nix";
  };

  outputs = { self, nixpkgs, cmake-nix }: 
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    
    stdenv = pkgs.llvmPackages_22.libcxxStdenv;
    
    cmake42 = cmake-nix.packages.${system}.default;

    rux-pkg = stdenv.mkDerivation {
      pname = "rux";
      version = "main";

      src = pkgs.fetchFromGitHub {
        owner = "rux-lang";
        repo = "Rux";
        rev = "main";
        hash = "sha256-m7R+pyNvKfPcvyu/1LH/d9UvuH7e46I2xSX5c1I7QAM="; 
      };

      nativeBuildInputs = [
        cmake42
        pkgs.ninja
      ];

      cmakeFlags = [
        "-DCMAKE_CXX_SCAN_FOR_MODULES=OFF"
      ];

      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin
        find .. -name "rux" -type f -exec cp {} $out/bin/ \;
        chmod +x $out/bin/rux
        runHook postInstall
      '';
  in {
    packages.${system} = {
      default = rux-pkg;
      rux = rux-pkg;
    };

    overlays.default = final: prev: {
      rux = rux-pkg;
    };

    devShells.${system}.default = pkgs.mkShell.override { inherit stdenv; } {
      nativeBuildInputs = [ 
        cmake42
        pkgs.ninja 
        pkgs.git 
      ];
      
      shellHook = ''
        echo "Rux dev environment loaded (Pure LLVM/libc++)."
      '';
    };
  };
}
