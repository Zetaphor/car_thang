{ pkgs, ... }:
{
  # environment.etc."DOOM.WAD" = {
  #   source = ../resources/DOOM.WAD;
  #   target = "games/DOOM.WAD";
  #   mode = "0755";
  # };

  environment.systemPackages = with pkgs; [
    btop
    wlr-randr
    neovim
  ];

  age.secrets.spotify_env = {
    file = ../secrets/spotify-env.age;
    mode = "644";
    owner = "superbird";
    group = "wheel";
  };

  time.timeZone = "America/New_York";
}
