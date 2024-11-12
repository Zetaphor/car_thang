{
  lib,
  ...
}:
with lib;
{
  options.vars = {
    guiEnabled = mkOption {
      type = types.bool;
      description = "whether cage is enabled";
    };

    doomEnabled = mkOption {
      type = types.bool;
      description = "whether doom is enabled :)";
    };

    cogEnabled = mkOption {
      type = types.bool;
      description = "whether cog is enabled";
    };

    firefoxEnabled = mkOption {
      type = types.bool;
      description = "whether firefox is enabled";
    };

    chromiumEnabled = mkOption {
      type = types.bool;
      description = "whether chromium is enabled";
    };
  };

  # config.age.secrets.spotify_env = {
  #   file = ../secrets/spotify-env.age;
  #   mode = "644";
  #   owner = "superbird";
  #   group = "wheel";
  # };
}
