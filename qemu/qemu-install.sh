#!/bin/bash

root=$(git rev-parse --show-toplevel)

if [ ! -f "$root"/qemu/emmc.img ]; then
  qemu-img create -f qcow2 "$root"/qemu/emmc.img 4G
fi

if [ ! -f "$root"/qemu/kernel ]; then
  pushd nix || exit 1

  nix build '.#nixosConfigurations.qemu-initrd.config.system.build.toplevel' --show-trace -j"$(nproc)"
  cp result/kernel "$root"/qemu

  popd || exit 1
fi

if [ ! -f "$root"/qemu/btrfs.img ]; then
  pushd nix || exit 1

  nix build '.#nixosConfigurations.qemu.config.system.build.btrfs' --show-trace -j"$(nproc)"
  cp result "$root"/qemu/btrfs.img

  popd || exit 1
fi

if [ ! -f "$root"/nix/result/initrd.img ]; then
  pushd nix || exit 1

  nix build '.#nixosConfigurations.qemu-initrd.config.system.build.initfs' --show-trace -j"$(nproc)"

  popd || exit 1
fi

sudo qemu-system-aarch64 \
  -machine virt -cpu cortex-a53 -m 2048 -smp 4 \
  -serial stdio -device VGA \
  -kernel "$root"/qemu/kernel \
  -append "rdinit=/superbird/init superbird.qemu superbird.partition" \
  -initrd "$root"/nix/result/initrd.img \
  -drive file="$root"/qemu/emmc.img,if=virtio \
  -drive file="$root"/qemu/btrfs.img,if=virtio,format=raw \
  -accel tcg
