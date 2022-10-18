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
    manifest = {
      url = "./example/west.yml";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, mach-nix, zephyr-sdk-arm, zephyr, manifest, ... }: {
    overlay = final: prev: {

      zephyr-sdk-arm = zephyr-sdk-arm.packages.${prev.system}.default;

      lib = 
        let 
          fromYAML = yaml: builtins.fromJSON (
            builtins.readFile (
              final.runCommand "from-yaml"
                {
                  inherit yaml;
                  allowSubstitutes = false;
                  preferLocalBuild = true;
                }
                ''
                  ${final.remarshal}/bin/remarshal  \
                    -if yaml \
                    -i <(echo "$yaml") \
                    -of json \
                    -o $out
                ''
            )
          );

          readYAML = path: fromYAML (builtins.readFile path);
        in prev.lib // {
          inherit fromYAML readYAML;
        };

    };
  } // flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
    let
      pkgs = import nixpkgs { 
        inherit system; 
        overlays = [ 
          self.overlay 
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
          zephyrManifestInfo = pkgs.lib.lists.findFirst (x: x.name == "zephyr") null (pkgs.lib.readYAML "${manifest}").manifest.projects;
          zephyrManifestRev = if isNull zephyrManifestInfo then null else zephyrManifestInfo.revision;

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
          pythonRequirements = pkgs.lib.concatStrings (map (x: builtins.readFile x) pythonRequirementsFiles);
          pythonEnv = mach-nix.lib.${system}.mkPython { 
            requirements = pythonRequirements;
          };
        in 
        assert pkgs.lib.asserts.assertMsg (zephyr.rev == zephyrManifestRev) "Zephyr revisions from west manifest and flake must match";
        pkgs.mkShell (builtins.trace zephyrManifestInfo {
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
        });

    });
}