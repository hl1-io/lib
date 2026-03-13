{ pkgs, ... }: {
  hl1-io.node-meta.personas = [ "workstation" ];
  environment.systemPackages = with pkgs; [
    colmena
    gopass # Password manager
    kanidm # IAC CLI
    terraform-ls
    stdenv.cc.cc.lib
    # nodePackages_latest.graphql-language-service-cli
  ];

  programs.fish.shellAliases = {
    passGit = "gitui -d ~/.password-store";
    pass = "gopass";
  };

  programs.gnupg.agent.enable = true;

  # Allow some ports to be used
  networking.firewall.allowedTCPPortRanges = [
    {
      from = 8000;
      to = 9000;
    }
    {
      from = 3000;
      to = 3100;
    }
    {
      from = 5000;
      to = 6100;
    }
  ];

  # Enable Docker
  boot.kernel.sysctl = { "net.ipv4.ip_unprivileged_port_start" = 0; };
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

}
