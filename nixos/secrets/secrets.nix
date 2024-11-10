let
  joey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpdDgIOGMxVO08WFKDtwSHfYrud9803nJDrGg9jpPbC";
  users = [ joey ];

  superbird = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFaFWtxWDkiD9OkAY1g4gzGsiOyAAbs+AGWFIBXJHN//";
  systems = [ superbird ];
in
{
  "spotify-env.age".publicKeys = users ++ systems;
}
