{
  description = "Rux Programming Language";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    
    # Swap Nix's default GCC stdenv for LLVM/Clang 22
    stdenv = pkgs.llvmPackages_22.stdenv;

    rux-pkg = stdenv.mkDerivation {
      pname = "rux";
      version = "main";

      src = pkgs.fetchFromGitHub {
        owner = "rux-lang";
        repo = "Rux";
        rev = "main";
        # Remember to update this hash after your first `nix build` attempt
        hash = pkgs.lib.fakeHash; 
      };

      nativeBuildInputs = with pkgs; [
        llvmPackages_22.clang # Explicitly bring Clang into the build environment
        cmake
        ninja
      ];

      # Force CMake to use Clang during the configure phase
      cmakeFlags = [
        "-DCMAKE_CXX_COMPILER=clang++"
        "-DCMAKE_C_COMPILER=clang"
      ];

      installPhase = ''
        runHook preInstall
        
        mkdir -p $out/bin
        find . -name "rux" -type f -executable -exec cp {} $out/bin/ \;
        
        runHook postInstall
      '';
    };

  in {
    # 1. Package output (for `nix build` and `nix profile`)
    packages.${system} = {
      default = rux-pkg;
      rux = rux-pkg;
    };

    # 2. Overlay output (for system-wide nixos-rebuild and legacy nix-env)
    overlays.default = final: prev: {
      rux = rux-pkg;
    };

    # 3. Dev shell (for `nix develop`)
    devShells.${system}.default = pkgs.mkShell.override { inherit stdenv; } {
      nativeBuildInputs = with pkgs; [ 
        llvmPackages_22.clang 
        cmake 
        ninja 
        git 
      ];
      
      # Ensure manual terminal usage defaults to Clang
      shellHook = ''
        export CC=clang
        export CXX=clang++
        echo "Rux dev environment loaded."
        echo "Using compiler: $(clang++ --version | head -n1)"
      '';
    };
  };
}
