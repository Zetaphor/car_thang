{ pkgs, ... }:
{
  imports = [
    ./profile.nix
    ./sys.nix
    ./net.nix
    ./user.nix
    ./env.nix
    ./gui.nix
  ];

  system.stateVersion = "24.11";
}
