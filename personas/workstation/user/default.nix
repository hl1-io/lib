{ pkgs, ... }:
{
  imports = [ ./ssh.nix ];

  home.packages = with pkgs; [
    mkpasswd
    gnupg
    gopass
    colmena
    gpg-tui
  ];
}
