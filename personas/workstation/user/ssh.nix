{ home, pkgs, ... }:

# https://github.com/nix-community/home-manager/blob/master/modules/programs/ssh.nix#L342
{
  programs.ssh.enable = true;
  programs.ssh.addKeysToAgent = "yes";
}
