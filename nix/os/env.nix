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

  environment.sessionVariables = {
    # XDG_CACHE_HOME = "$HOME/.cache";
    # XDG_CONFIG_DIRS = "/etc/xdg";
    # XDG_CONFIG_HOME = "$HOME/.config";
    # XDG_DATA_DIRS = "/usr/local/share/:/usr/share/";
    # XDG_DATA_HOME = "$HOME/.local/share";
    # XDG_STATE_HOME = "$HOME/.local/state";

    # QT_QPA_PLATFORMTHEME = "gtk3";
    # QT_XCB_GL_INTEGRATION = "xcb_egl";
    # QT_QPA_PLATFORM = "wayland";
    # QT_QPA_PLATFORM = "wayland-egl";

    # WLR_RENDERER = "vulkan";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    QT_SCALE_FACTOR = "1";
    MOZ_ENABLE_WAYLAND = "1";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    CLUTTER_BACKEND = "wayland";
    NIXOS_OZONE_WL = "1";
    XDG_SESSION_TYPE = "wayland";
  };

  time.timeZone = "America/New_York";
}
