{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {

  buildInputs = [
    pkgs.glfw
    pkgs.vulkan-headers
    pkgs.vulkan-loader
    pkgs.vulkan-tools
    pkgs.shaderc
  ];

  LD_LIBRARY_PATH="${pkgs.vulkan-loader}/lib";
}
