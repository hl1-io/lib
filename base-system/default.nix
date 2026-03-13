{
  pkgs,
  lib,
  config,
  system,
  ...
}:
{
  hl1-io.backup.paths = [
    "/home"
    "/root"
  ];
  nixpkgs.config.allowUnfree = lib.mkDefault true;
  nix.settings.experimental-features = [
    "flakes"
    "nix-command"
  ];

  system.stateVersion = lib.mkDefault "23.05";
  time.timeZone = lib.mkDefault "America/Chicago";

  environment.systemPackages = with pkgs; [
    helix # Modal Text Editor
    zellij # Terminal Multiplexer

    wget # HTTP Util
    fish # Shell
    nil # Nix Language Server
    nixd # Nix Language Server
    git # Version Control

    gitui # QOL Git TUI
    gum # Shell script prompt util
    magic-wormhole # File Transfer Util
    step-cli # Certificates CLI Tool
    fastfetch # System Info Splash

    jq
    yq-go # JSON / YAML utilities

    viddy # Better Watch
    btop # Better top
    lsd # Better ls
    fd # Better find
    bat # Better cat
    ripgrep # Better Grep

    duf # better df
    dust # better du

    openssl # Crypto Toolkit

    asciinema # Terminal Recorder

    inetutils # Network Util Pack

    dig # DNS Utils

    nixfmt-rfc-style # .nix formatter

    viu # terminal image player
    pandoc # document converter
    glow # markdown renderer
    tv # CSV Renderer
    links2 # TUI Browser
    pciutils

    fishPlugins.done
    fishPlugins.colored-man-pages
    starship

    chafa
    fzf
    file
    nushell
    hexyl
    procs
    gping

    marksman # Markdown LSP
    frogmouth # Markdown browser for the terminal
    xplr

    lsof

    visidata # CSV / TSV / SQLite / Parquet(?) explorer
  ];

  # Shell Configuration
  programs.fish = {
    enable = true;
    shellAliases = {
      ls = "lsd";
      cat = "bat";
      watch = "viddy";
      find = "fd";
      df = "duf";
      du = "dust";
      files = "xplr";
    };
  };

  # TODO: make this useful in some way
  # security.auditd.enable = true;
  # security.audit.enable = true;
  # security.audit.rules = [
  #   "-a exit,always -F arch=b64 -S execve"
  # ];
  # # TODO: Create an audit group and assign read permissions to the audit
  # # group to the /var/log/audit directory (and all child files)
  # users.groups.audit = {};
  # services.logrotate = {
  #   enable = lib.mkDefault true;
  #   settings = {
  #     header = { dateext = true; };
  #     "/var/log/audit/audit.log" = {
  #       frequency = "daily";
  #       rotate = 30;
  #     };
  #   };
  # };

  # Disable items that are not needed

  environment.variables.EDITOR = "hx";
  environment.variables.BROWSER = lib.mkDefault "links";

  home-manager.users =
    let
      defaultUserConfiguration = (
        if (lib.hasInfix "linux" system) then
          ./linux-user.nix
        else if (lib.hasInfix "darwin" system) then
          ./darwin-user.nix
        else
          ({ ... }: { })
      );
    in
    {
      root = (
        { ... }:
        {
          imports = [
            defaultUserConfiguration
            ./default-user.nix
          ];
        }
      );
      "${config.hl1-ioprofile.username}" = (
        { ... }:
        {
          imports = [
            defaultUserConfiguration
            ./default-user.nix
          ];
        }
      );
    };

  home-manager.backupFileExtension = "bak";

  users.users.root = { };
  users.users."${config.hl1-io.profile.username}" = { };

  environment.etc."root_ca.crt" = lib.mkIf (config.hl1-io.pki.caCert != null) {
    enable = true;
    text = config.hl1-io.pki.caCert;
    target = "./certs/root_ca.crt";
  };

  environment.etc."host_ca.pub" = lib.mkIf (config.hl1-io.pki.hostCaPub != null) {
    enable = true;
    text = config.hl1-io.pki.hostCaPub;
    target = "./certs/host_ca.pub";
  };

  environment.etc."user_ca.pub" = lib.mkIf (config.hl1-io.pki.userCaPub != null) {
    enable = true;
    text = config.hl1-io.pki.userCaPub;
    target = "./certs/user_ca.pub";
  };

  ## TODO: Restrict root login to yubikey agent?

  security.pki.certificates = lib.mkIf (config.hl1-io.pki.caCert != null) [
    config.hl1-io.pki.caCert
  ];

  environment.variables.VAULT_ADDR = "https://vault.${config.hl1-io.domains.primary}";

}
