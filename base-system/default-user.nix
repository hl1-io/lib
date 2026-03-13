{
  config,
  lib,
  osConfig,
  ...
}:
{
  # Configuration for userland programs
  home.stateVersion = lib.mkDefault "23.05";

  home.file.".step/config/defaults.json" = lib.mkIf (osConfig.hl1-io.pki.caFingerprint != null) {
    enable = true;
    force = true;
    onChange = "echo $(date) > ~/stepca-update";
    text =
      let
        domain = with osConfig.hl1-io.domains; if caUrl != null then caUrl else "stepca.${primary}";
      in
      ''
        {
          "ca-url": "https://${domain}",
          "fingerprint": "${osConfig.hl1-io.pki.caFingerprint}",
          "root": "/etc/certs/root_ca.crt",
          "redirect-url": ""
        }
      '';
  };

  programs.fish = {
    enable = true;
  };
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    enableTransience = false;
    settings = { };
  };

  programs.helix = {
    enable = true;
    settings = {
      theme = "papercolor-dark";
      editor = {
        true-color = true;
        indent-guides.render = true;
      };
      keys = {
        insert.tab = "insert_tab";
      };
    };
    languages = {
      language = [
        {
          name = "nix";
          language-servers = [ "nixd" ];
          auto-format = true;
        }
      ];
      language-server.nixd = {
        command = "nixd";
        config = {
          eval.target.args = [ "--impure" ];
          options.hl1.expr = ''(builtins.getFlake "${osConfig.hl1-io.hliac-location}").outputs.options'';
        };
      };
    };
    defaultEditor = true;
  };

  programs.git = {
    enable = true;
    extraConfig = {
      user = with config.hl1-io.profile; {
        email = email;
        name = givenName + " " + familyName;
      };
      pull = {
        rebase = false;
      };
      push = {
        autoSetupRemote = true;
      };
      init = {
        defaultBranch = "main";
      };
    };
  };

  programs.tealdeer = {
    enable = true;
    settings.updates.auto_update = true;
  };

  # TODO: Fix this for mac
  # services.ssh-agent.enable = true;
}
