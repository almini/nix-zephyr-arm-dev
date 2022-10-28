{
  description = "Zephyr ARM development tools";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    pypi-deps-db = {
      url = "github:DavHau/pypi-deps-db";
    };
    mach-nix = {
      url = "mach-nix/3.5.0";
      inputs.pypi-deps-db.follows = "pypi-deps-db";
    };
    zephyr-sdk-arm = {
      url = "github:almini/nix-zephyr-sdk-arm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zephyr = {
      url = "github:zephyrproject-rtos/zephyr?ref=zephyr-v3.2.0";
      flake = false;
    };
  };

  outputs = { nixpkgs, flake-utils, mach-nix, zephyr-sdk-arm, zephyr, ... }: flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
    let
      overlay = final: prev: {
        zephyr-sdk-arm = zephyr-sdk-arm.packages.${prev.system}.default;
      };

      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          overlay
        ];
      };
    in
    {
      packages = {
        inherit (pkgs)
          zephyr-sdk-arm;
      };

      devShells.default =
        let
          # Read requirements files to get Python dependencies
          # mach-nix is not capable of using a requirements.txt with -r directives
          # Using list of requirements files: read each file, concatenate contents in single string
          pythonRequirementsFiles = [
            "${zephyr}/scripts/requirements-base.txt"
            "${zephyr}/scripts/requirements-build-test.txt"
            "${zephyr}/scripts/requirements-compliance.txt"
            "${zephyr}/scripts/requirements-doc.txt"
            "${zephyr}/scripts/requirements-extras.txt"
            "${zephyr}/scripts/requirements-run-test.txt"
          ];
          pythonRequirements = pkgs.lib.concatStrings (map builtins.readFile pythonRequirementsFiles);
          pythonEnv = mach-nix.lib.${system}.mkPython {
            requirements = pythonRequirements;
          };
        in
        pkgs.mkShell {
          buildInputs = with pkgs; [
            cmake
            ninja
            stlink
            pkgs.zephyr-sdk-arm
            pythonEnv
          ];

          shellHook = ''
            export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
            export ZEPHYR_SDK_INSTALL_DIR=${pkgs.zephyr-sdk-arm}
          '';
        };

    });
}
