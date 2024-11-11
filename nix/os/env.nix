{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # needed
    libgpiod_1
    btrfs-progs

    # needed - gui
    wlr-randr

    # useful
    btop
    neovim

    # fun
    neofetch
  ];

  time.timeZone = "America/New_York";
}
