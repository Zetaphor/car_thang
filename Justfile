nixos-push:
  cd nixos-superbird && nix run github:serokell/deploy-rs

nixos-build-fs:
  cd nixos-superbird && nix build '.#nixosConfigurations.superbird.config.system.build.ext4' --show-trace

nixos-build:
  cd nixos-superbird && nix build '.#nixosConfigurations.superbird.config.system.build.toplevel' --show-trace

nixos-secret name:
  cd nixos-superbird/secrets && nix run github:ryantm/agenix -- -e {{name}}.age

edit-nixos-secret name:
  cd nixos-superbird/secrets && nix run github:ryantm/agenix -- -e {{name}}.age