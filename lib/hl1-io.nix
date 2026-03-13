{ lib, ... }:
with lib;
{
  imports = [
    ./option-definitions/backup.nix
    ./option-definitions/bastion.nix
    ./option-definitions/consul.nix
    ./option-definitions/domains.nix
    ./option-definitions/ingress.nix
    ./option-definitions/mail.nix
    ./option-definitions/monitoring.nix
    ./option-definitions/node-meta.nix
    ./option-definitions/nomad.nix
    ./option-definitions/systemd.nix
    ./option-definitions/vault.nix
    ./option-definitions/profile.nix

  ];
  # option definitions
  options.hl1-io = {
    datacenter = mkOption {
      type = types.str;
      default = "hl1-io";
      description = "Cosmetic description of the cluster used in places like Consul / Nomad";
    };
    master = mkOption {
      type = types.str;
    };
    cluster-label = mkOption {
      type = types.str;
      default = "-";
    };
    hliac-location = mkOption {
      type = types.str;
      default = "git+ssh://git@github.com/hl1-io/lib";
    };
  };

}
