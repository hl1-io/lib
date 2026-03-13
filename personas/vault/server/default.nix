{ pkgs, ... }: {
  hl1-io.node-meta.personas = [ "vault" ];
  environment.systemPackages = with pkgs; [ vault-bin consul ];

  services.vault.enable = true;
  services.vault.dev = false;
  services.vault.address = "0.0.0.0:4444";
  services.vault.package = pkgs.vault-bin;
  services.vault.extraConfig = ''
    ui = true

    service_registration "consul" {
      address = "127.0.0.1:8500"
      service_tags = "traefik.enable=true"
    }
  '';

  networking.firewall.allowedTCPPorts = [ 4444 ];

  services.vault.storageBackend = "consul";
  services.vault.storageConfig = ''
    address = "127.0.0.1:8500"
    path    = "vault"
  '';
}
