{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/master";
    simple-nixos-mailserver.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    {
      nixpkgs,
      home-manager,
      simple-nixos-mailserver,
      self,
      ...
    }:
    {
      boot.bios = import ./boot-methods/bios.nix;
      boot.uefi = import ./boot-methods/uefi.nix;
      boot.rpi = import ./boot-methods/rpi.nix;

      lang = {
        javascript = import ./personas/workstation/lang/javascript.pkgs.nix;
        rust = import ./personas/workstation/lang/rust.pkgs.nix;
        go = import ./personas/workstation/lang/go.pkgs.nix;
      };

      personas = {
        base = import ./base-system;
        linux = import ./base-system/linux.nix;
        darwin = import ./base-system/darwin.nix;

        consul.client = import ./personas/consul/client;
        consul.server = import ./personas/consul/server;

        nomad.client = import ./personas/nomad/client;
        nomad.server = import ./personas/nomad/server;

        certificate-authority = import ./personas/certificate-authority;
        ingress = import ./personas/ingress;
        llm = import ./personas/llm;

        monitoring-sink = import ./personas/monitoring-sink;
        object-storage = import ./personas/object-storage;
        idp = import ./personas/idp;
        tailscale-node = import ./personas/tailscale-node;
        vault = import ./personas/vault/server;

        kiosk.retro = import ./personas/kiosk/retro;
        workstation = import ./personas/workstation;
        workstation-user = import ./personas/workstation/user;
        bastion = import ./personas/bastion;
        mailserver = (
          { ... }:
          {
            imports = [
              simple-nixos-mailserver.nixosModule
              ./personas/mailserver
            ];
          }
        );

        rustdesk = {
          server = import ./personas/rustdesk/server.nix;
          relay = import ./personas/rustdesk/relay.nix;
        };
      };

      inject-fish-functions = import ./base-system/fish-configuration.nix;
      lib =
        { config, lib, ... }:
        {
          # inline module
          imports = [ ./lib/hl1-io.nix ];
          _module.args.hlib = import ./lib {
            inherit config;
            inherit lib;
          };
        };

      colmena = {
        meta = {
          nixpkgs = import nixpkgs { system = "x86_64-linux"; };
        };
      };
      # For use by nixd to get autocomplete
      options = (import ./lib/options-export.nix) { inherit nixpkgs; };

      ## THIS SHOULD NOT BE USED ##
      ##
      ##   This is in place for use with the nix langauge server to provide
      ##   completions for home-manager specific items
      ##
      ##
      __home-manager = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          (
            { ... }:
            {
              home.stateVersion = "23.05";
              home.username = "__";
              home.homeDirectory = /home/__;
            }
          )
        ];
      };
    };
}
