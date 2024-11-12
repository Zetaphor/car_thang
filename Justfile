run-app:
  cargo run -p car_thang

nixos-push:
  cd nix && nix run github:serokell/deploy-rs

initrd-build:
  cd nix && nix build '.#nixosConfigurations.initrd.config.system.build.initfs' -j$(nproc) --show-trace
  echo "initrd is $(stat -Lc%s -- nix/result/initrd | numfmt --to=iec)"

nixos-build-fs:
  cd nix && nix build '.#nixosConfigurations.superbird.config.system.build.btrfs' -j$(nproc) --show-trace
  echo "rootfs is $(stat -Lc%s -- nix/result | numfmt --to=iec)"

nixos-write-fs-to-disk:
  just nixos-build-fs
  dd if=nix/result status=progress | ssh root@172.16.42.2 dd of=/dev/mmcblk2p2

nixos-build:
  cd nix && nix build '.#nixosConfigurations.superbird.config.system.build.toplevel' -j$(nproc) --show-trace

nixos-install:
  #!/bin/bash
  mkdir -p  ./install/linux

  if [ ! -f ./install/linux/kernel ]; then
    pushd nix || exit 1
    nix build '.#nixosConfigurations.initrd.config.system.build.toplevel' --show-trace -j"$(nproc)"
    echo "kernel is $(stat -Lc%s -- result/kernel | numfmt --to=iec)"
    popd || exit 1
    cp ./nix/result/kernel ./install/linux/
  fi

  if [ ! -f ./install/linux/initrd.img ]; then
    pushd nix || exit 1
    nix build '.#nixosConfigurations.initrd.config.system.build.initfs' --show-trace -j"$(nproc)"
    echo "initrd is $(stat -Lc%s -- result/initrd | numfmt --to=iec)"
    popd || exit 1
    cp ./nix/result/initrd.img ./install/linux/
  fi

  if [ ! -f ./install/linux/rootfs.img ]; then
    pushd nix || exit 1
    nix build '.#nixosConfigurations.superbird.config.system.build.btrfs' --show-trace -j"$(nproc)"
    echo "rootfs is $(stat -Lc%s -- result | numfmt --to=iec)"
    popd || exit 1
    just shrink-img
    cp ./tmp/rootfs.img ./install/linux/rootfs.img
  fi

  if [ ! -f ./install/linux/meson-g12a-superbird.dtb ]; then
    cp ./nix/resources/meson-g12a-superbird.dtb ./install/linux/
  fi

  cd install && ./install.sh

shrink-img:
  #!/bin/bash
  rm -rf ./tmp
  mkdir -p ./tmp
  cp nix/result ./tmp/rootfs.img
  sudo losetup /dev/loop0 ./tmp/rootfs.img
  sudo mkdir -p /mnt/image
  sudo mount -o compress=zstd,noatime /dev/loop0 /mnt/image
  sudo btrfs subvolume set-default 256 /mnt/image

  echo "defragmenting and compressing filesystem - this will take a while"
  sudo btrfs filesystem defragment -r -czlib /mnt/image/root
  sudo btrfs property set /mnt/image/root compression zstd

  min_size=$(sudo btrfs filesystem usage -b /mnt/image | grep "Free (estimated)" | awk -F'min: ' '{print $2}' | awk '{gsub(/[()]/, ""); print $1 - 104857600}')
  sudo btrfs filesystem resize "-$min_size" /mnt/image

  for i in {0..5}
  do
    min_size=$(sudo btrfs filesystem usage -b /mnt/image | grep "Free (estimated)" | awk -F'min: ' '{print $2}' | awk '{gsub(/[()]/, ""); print $1 - 1024}')
    sudo btrfs filesystem resize "-$min_size" /mnt/image
  done

  sudo umount /mnt/image
  sudo losetup -d /dev/loop0

  trim_size=$(<./tmp/rootfs.img perl -e 'seek(STDIN, 0x10070, 0) or sysread(STDIN, $_, 0x10070) == 0x10070 or die "seek"; sysread(STDIN, $_, 8) == 8 or die "read"; print unpack("Q<", $_), "\n"')
  sudo truncate -s $trim_size ./tmp/rootfs.img

zip-release:
  #!/bin/bash
  set -euo pipefail

  rm -rf /tmp/superbird-release
  mkdir /tmp/superbird-release
  mkdir /tmp/superbird-release/linux

  pushd nix || exit 1
  nix build '.#nixosConfigurations.initrd.config.system.build.toplevel' --show-trace -j"$(nproc)"
  cp ./result/kernel /tmp/superbird-release/linux
  nix build '.#nixosConfigurations.initrd.config.system.build.initfs' --show-trace -j"$(nproc)"
  cp ./result/initrd.img /tmp/superbird-release/linux
  nix build '.#nixosConfigurations.superbird.config.system.build.btrfs' --show-trace -j"$(nproc)"
  popd || exit 1
  just shrink-img
  cp ./tmp/rootfs.img /tmp/superbird-release/linux
  cp ./nix/resources/meson-g12a-superbird.dtb /tmp/superbird-release/linux

  cp -r ./install/boot /tmp/superbird-release/
  cp -r ./install/env /tmp/superbird-release/
  cp -r ./install/scripts /tmp/superbird-release/
  cp ./install/install.sh /tmp/superbird-release/
  cp ./install/install.py /tmp/superbird-release/
  cp ./install/superbird_device.py /tmp/superbird-release/

  cd /tmp/superbird-release
  zip -r /tmp/superbird-release.zip .

nixos-build-qemu:
  cd nix && nix build '.#nixosConfigurations.qemu.config.system.build.toplevel' -j$(nproc) --show-trace

nixos-build-qemu-init:
  cd nix && nix build '.#nixosConfigurations.qemu.config.system.build.initfs' -j$(nproc) --show-trace
  echo "initrd is $(stat -Lc%s -- nix/result/initrd | numfmt --to=iec)"

nixos-secret name:
  cd nix/secrets && nix run github:ryantm/agenix -- -e {{name}}.age

edit-nixos-secret name:
  cd nix/secrets && nix run github:ryantm/agenix -- -e {{name}}.age