{
  inputs = {
    zephyr = {
      url = "github:zephyrproject-rtos/zephyr?ref=4256cd41df6c60f1832fd2deb14edc30ac7debab";
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