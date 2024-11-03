{ pkgs, config, ... }:
let
  # doom = "${pkgs.doomretro}/bin/doomretro -iwad /etc/games/DOOM.WAD";
  car_thang = (
    pkgs.callPackage ../../car-thang.nix { envFile = config.age.secrets.spotify_env.path; }
  );

  transparent-cursor = pkgs.fetchFromGitHub {
    owner = "johnodon";
    repo = "Transparent_Cursor_Theme";
    rev = "22cf8e6b6ccbd93a7f0ff36d98a5b454f18bed77";
    sha256 = "sha256-wf5wnSiJsDqcHznbg6rRCZEq/pUneRkqFIJ+mNWb4Go=";
  };

  app = "${pkgs.writeScriptBin "start-cage-app" ''
    #!/usr/bin/env bash
    wlr-randr --output DSI-1 --transform 270

    exec ${car_thang}/bin/car_thang
  ''}/bin/start-cage-app";
in
{
  environment.sessionVariables = {
    XCURSOR_PATH = "${transparent-cursor}/Transparent";
    XCURSOR_SIZE = 0;
  };

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
}
