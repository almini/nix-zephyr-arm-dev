{
  inputs = {
    zephyr = {
      url = "github:zephyrproject-rtos/zephyr?ref=d2ffa8a3ebf085b0bc6a255aad5dd490c9e03ca5";
      flake = false;
    };
    manifest = {
      url = "./west.yml";
      flake = false;
    };
    zephyr-arm-dev = {
      url = "github:almini/nix-zephyr-arm-dev";
      inputs.zephyr.follows = "zephyr";
      inputs.manifest.follows = "manifest";
    };
  };

  outputs = { self, zephyr-arm-dev, ... }: let 
    flake-utils = zephyr-arm-dev.inputs.flake-utils;
  in flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system: 
    builtins.trace zephyr-arm-dev {
      devShells.default = zephyr-arm-dev.devShells.${system}.default;
    });
}