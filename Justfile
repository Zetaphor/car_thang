run-app:
  cargo run -p car_thang

nixos-push:
  cd nixos && nix run github:serokell/deploy-rs

initrd-build:
  cd nixos && nix build '.#nixosConfigurations.initrd.config.system.build.initfs' -j$(nproc) --show-trace
  echo "initrd is $(stat -Lc%s -- nixos/result/initrd | numfmt --to=iec)"

nixos-build-fs:
  cd nixos && nix build '.#nixosConfigurations.superbird.config.system.build.btrfs' -j$(nproc) --show-trace

nixos-write-fs-to-disk:
  just nixos-build-fs
  dd if=nixos/result status=progress | ssh root@172.16.42.2 dd of=/dev/mmcblk2p2

nixos-build:
  cd nixos && nix build '.#nixosConfigurations.superbird.config.system.build.toplevel' -j$(nproc) --show-trace

nixos-build-qemu:
  cd nixos && nix build '.#nixosConfigurations.qemu.config.system.build.toplevel' -j$(nproc) --show-trace

nixos-build-qemu-init:
  cd nixos && nix build '.#nixosConfigurations.qemu.config.system.build.initfs' -j$(nproc) --show-trace
  echo "initrd is $(stat -Lc%s -- nixos/result/initrd | numfmt --to=iec)"

nixos-secret name:
  cd nixos/secrets && nix run github:ryantm/agenix -- -e {{name}}.age

edit-nixos-secret name:
  cd nixos/secrets && nix run github:ryantm/agenix -- -e {{name}}.age