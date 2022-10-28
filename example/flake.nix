{
  inputs = {
    zephyr = {
      url = "github:zephyrproject-rtos/zephyr?ref=4256cd41df6c60f1832fd2deb14edc30ac7debab";
      flake = false;
    };
    zephyr-arm-dev = {
      url = "github:almini/nix-zephyr-arm-dev";
      inputs.zephyr.follows = "zephyr";
    };
  };

  outputs = { self, zephyr-arm-dev, ... }:
    let
      inherit (zephyr-arm-dev.inputs) flake-utils;
    in
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      {
        devShells.default = zephyr-arm-dev.devShells.${system}.default;
      });
}
