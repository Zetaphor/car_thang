{ ... }:
{
  users = {
    users = {
      superbird = {
        isNormalUser = true;
        home = "/home/superbird";
        initialPassword = "superbird";
        description = "Superbird User";

        extraGroups = [
          "wheel"
          "networkmanager"
          "audio"
          "video"
          "input"
          "bluetooth"
        ];
        uid = 1000;

        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpdDgIOGMxVO08WFKDtwSHfYrud9803nJDrGg9jpPbC"
        ];
      };

      root = {
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpdDgIOGMxVO08WFKDtwSHfYrud9803nJDrGg9jpPbC joey"
        ];
      };
    };
    groups.superbird.gid = 1000;
  };

  security.sudo.extraConfig = ''
    %wheel	ALL=(root)	NOPASSWD: ALL
  '';
}
