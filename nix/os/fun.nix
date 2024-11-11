{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.vars.doomEnabled {
    environment.etc."DOOM.WAD" = {
      source = pkgs.fetchurl {
        url = "https://archive.org/download/theultimatedoom_doom2_doom.wad/DOOM.WAD%20%28For%20GZDoom%29/DOOM.WAD";
        hash = "sha256-b982GEe0YijP69nzrwnNhEKCrHXz7bthykyycQPOLn8=";
      };
      target = "games/DOOM.WAD";
      mode = "0755";
    };
  };
}
