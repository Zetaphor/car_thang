let
  joey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpdDgIOGMxVO08WFKDtwSHfYrud9803nJDrGg9jpPbC";
  superbird_user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINYwYlpDn4uEudtnOCN+cQTQXq3mDHeF3kUt8wkj1D9t superbird@superbird";
  users = [
    joey
    superbird_user
  ];

  superbird = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXXYiuwaWx6mqiM0q5wKnSVgjcfiDN2ra7Fc/0WwUwx";
  systems = [ superbird ];
in
{
  "spotify-env.age".publicKeys = users ++ systems;
}
