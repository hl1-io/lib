{ config, pkgs, ... }:
{
  fonts.packages = with pkgs.nerd-fonts; [ hack ];
  users.users."${config.hl1-io.profile.email}" = {
    uid = 501;
    home = "/Users/${config.hl1-io.profile.email}";
    shell = pkgs.fish;
  };
  users.users.root.home = "/var/root";
  users.knownUsers = [ "${config.hl1-io.profile.email}" ];
}
