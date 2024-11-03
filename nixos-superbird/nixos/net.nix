{ pkgs, ... }:
{
  networking = {
    hostName = "superbird";
    interfaces.usb0.ipv4.addresses = [
      {
        address = "172.16.42.2";
        prefixLength = 24;
      }
    ];
    defaultGateway = "172.16.42.1";
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];

    firewall.enable = false;
    dhcpcd.enable = false;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };
}
