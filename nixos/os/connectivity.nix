{ lib, pkgs, ... }:
{
  networking = {
    hostName = "superbird";
    interfaces.usb0.ipv4.addresses = [
      {
        address = "172.16.42.2";
        prefixLength = 24;
      }
    ];
    defaultGateway = {
      address = "172.16.42.1";
      interface = "usb0";
    };
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];

    interfaces.bnep0 = {
      useDHCP = true;
    };

    firewall.enable = lib.mkForce false;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    settings = {
      General = {
        Name = "Superbird";
      };
    };
  };

  hardware.firmware = [
    (pkgs.runCommandNoCC "firmware-bluetooth-brcm" { } ''
      mkdir -p $out/lib/firmware/brcm
      cp ${../resources/firmware/brcm/BCM.hcd} $out/lib/firmware/brcm/BCM.hcd
      cp ${../resources/firmware/brcm/BCM20703A2.hcd} $out/lib/firmware/brcm/BCM20703A2.hcd
    '')
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
    extraConfig = ''
      PermitEmptyPasswords yes
    '';
  };

  environment.etc."ssh/ssh_host_ed25519_key" = {
    source = ../resources/ssh/ssh_host_ed25519_key;
    mode = "0600";
  };
  environment.etc."ssh/ssh_host_ed25519_key.pub" = {
    source = ../resources/ssh/ssh_host_ed25519_key.pub;
    mode = "0644";
  };
  environment.etc."ssh/ssh_host_rsa_key" = {
    source = ../resources/ssh/ssh_host_rsa_key;
    mode = "0600";
  };
  environment.etc."ssh/ssh_host_rsa_key.pub" = {
    source = ../resources/ssh/ssh_host_rsa_key.pub;
    mode = "0644";
  };

  systemd.services.bluetooth.wantedBy = [ "default.target" ];
  systemd.services.bluetooth-adapter = {
    enable = true;
    before = [ "bluetooth.service" ];
    requiredBy = [ "bluetooth.service" ];
    script = ''
      ${pkgs.libgpiod_1}/bin/gpioset 0 82=1
      sleep 1
      ${pkgs.bluez}/bin/btattach -P bcm -B /dev/ttyAML6
    '';
  };
}
