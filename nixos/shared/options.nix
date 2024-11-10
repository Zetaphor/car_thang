{
  lib,
  ...
}:
with lib;
{
  options.vars = {
    doomEnabled = mkOption {
      type = types.bool;
      description = "whether doom is enabled :)";
    };
  };

  # config.age.secrets.spotify_env = {
  #   file = ../secrets/spotify-env.age;
  #   mode = "644";
  #   owner = "superbird";
  #   group = "wheel";
  # };
}
