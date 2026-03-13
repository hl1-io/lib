{ nixpkgs }:
(nixpkgs.lib.evalModules {
  modules = [
    "${nixpkgs}/nixos/modules/misc/assertions.nix"
    ({ config, lib, ... }: {
      config = {
        _module.args.hlib = import ./default.nix {
          inherit config;
          inherit lib;
        };
        _module.args.nodes = { };
        assertions = lib.mkForce [ ];
        warnings = lib.mkForce [ ];

      };
    })
    ./hl1-io.nix
  ];
}).options

/* If home-manager is also being used here:

  # This is all needed to appease the home-manager gods
  "${nixpkgs}/nixos/modules/config/shells-environment.nix"
  "${nixpkgs}/nixos/modules/config/nsswitch.nix"
  "${nixpkgs}/nixos/modules/config/nix.nix"
  "${nixpkgs}/nixos/modules/config/sysctl.nix"
  "${nixpkgs}/nixos/modules/config/system-environment.nix"
  "${nixpkgs}/nixos/modules/config/system-path.nix"
  "${nixpkgs}/nixos/modules/config/users-groups.nix"
  "${nixpkgs}/nixos/modules/services/hardware/udev.nix"
  "${nixpkgs}/nixos/modules/hardware/uinput.nix"
  "${nixpkgs}/nixos/modules/misc/assertions.nix"
  "${nixpkgs}/nixos/modules/misc/extra-arguments.nix"
  "${nixpkgs}/nixos/modules/misc/ids.nix"
  "${nixpkgs}/nixos/modules/misc/lib.nix"
  "${nixpkgs}/nixos/modules/misc/meta.nix"
  "${nixpkgs}/nixos/modules/misc/nixpkgs.nix"
  "${nixpkgs}/nixos/modules/security/apparmor.nix"
  "${nixpkgs}/nixos/modules/security/pam.nix"
  "${nixpkgs}/nixos/modules/security/sudo-rs.nix"
  "${nixpkgs}/nixos/modules/security/sudo.nix"
  "${nixpkgs}/nixos/modules/security/wrappers"
  "${nixpkgs}/nixos/modules/system/activation/top-level.nix"
  "${nixpkgs}/nixos/modules/system/activation/activation-script.nix"
  "${nixpkgs}/nixos/modules/system/boot/stage-1.nix"
  "${nixpkgs}/nixos/modules/system/boot/stage-2.nix"
  "${nixpkgs}/nixos/modules/system/boot/kernel.nix"
  "${nixpkgs}/nixos/modules/system/boot/systemd.nix"
  "${nixpkgs}/nixos/modules/system/boot/systemd/initrd.nix"
  "${nixpkgs}/nixos/modules/system/boot/systemd/user.nix"
  "${nixpkgs}/nixos/modules/system/boot/systemd/sysusers.nix"
  "${nixpkgs}/nixos/modules/system/boot/systemd/tmpfiles.nix"
  "${nixpkgs}/nixos/modules/system/etc/etc.nix"
  "${nixpkgs}/nixos/modules/services/display-managers"
  "${nixpkgs}/nixos/modules/services/hardware/keyd.nix"
  "${nixpkgs}/nixos/modules/services/system/dbus.nix"
  "${nixpkgs}/nixos/modules/services/system/nix-daemon.nix"
  "${nixpkgs}/nixos/modules/services/logging/logrotate.nix"
  "${nixpkgs}/nixos/modules/tasks/filesystems.nix"
  "${nixpkgs}/nixos/modules/tasks/swraid.nix"

  home-manager.nixosModules.home-manager
*/
