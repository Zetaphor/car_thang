{
  pkgs,
  lib,
  config,
  ...
}:
let
  doom = "${pkgs.doomretro}/bin/doomretro -iwad /etc/games/DOOM.WAD";
  cog = "${pkgs.cog}/bin/cog https://google.com/";
  firefox = "${pkgs.firefox}/bin/firefox";
  chromium = "${pkgs.ungoogled-chromium}/bin/chromium";

  car_thang_der = (
    pkgs.callPackage ../../app/thang.nix { envFile = config.age.secrets.spotify_env.path; }
  );
  car_thang = "${car_thang_der}/bin/car_thang";

  app = "${pkgs.writeScriptBin "start-cage-app" ''
    #!/usr/bin/env bash
    wlr-randr --output DSI-1 --transform 270

    exec ${
      if config.vars.doomEnabled == true then
        doom
      else if config.vars.cogEnabled == true then
        cog
      else if config.vars.firefoxEnabled == true then
        firefox
      else if config.vars.chromiumEnabled == true then
        chromium
      else
        car_thang
    }
  ''}/bin/start-cage-app";
in
{
  config = lib.mkIf config.vars.guiEnabled {
    services.cage = {
      enable = true;
      user = "superbird";
      program = "${app}";
      extraArguments = [ "-d" ];
    };

    services.udev.packages = [
      (pkgs.writeTextFile {
        name = "touchscreen_udev";
        text = ''
          KERNEL=="event2", SUBSYSTEM=="input", ENV{LIBINPUT_CALIBRATION_MATRIX}="0 1 0 -1 0 1" ENV{WL_OUTPUT}="DSI-1"
        '';
        destination = "/etc/udev/rules.d/97-touchscreen.rules";
      })
    ];

    # programs.sway.enable = true;

    # services.greetd = {
    #   enable = true;
    #   settings = rec {
    #     initial_session = {
    #       command = "${session} ${doom}";
    #       user = "superbird";
    #     };
    #     default_session = initial_session;
    #   };
    # };
  };
}
