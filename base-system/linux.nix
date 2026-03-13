{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ./monitoring.nix
    ./backups.nix
    ./file-transfers.nix
  ];

  environment.systemPackages = with pkgs; [
    nfs-utils
    libnfs
    fishPlugins.done
    usbutils
  ];

  environment.enableAllTerminfo = true;
  services.printing.enable = lib.mkDefault false;
  services.pulseaudio.enable = lib.mkDefault false;
  services.xserver.enable = lib.mkDefault false;
  services.libinput.enable = lib.mkDefault false;
  programs.git.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [ stdenv.cc.cc ];

  services.openssh.enable = true;
  services.openssh.openFirewall = true;
  systemd.services."alsa-store".enable = false;

  users.defaultUserShell = pkgs.fish;

  users.groups."${config.hl1-io.profile.username}" = { };
  users.users."${config.hl1-io.profile.username}" = {
    uid = 1000;
    isNormalUser = true;
    home = "/home/${config.hl1-io.profile.username}";
    createHome = true;
    group = "${config.hl1-io.profile.username}";
    openssh = {
      authorizedKeys.keys = config.hl1-io.profile.authorizedKeys;
    };
  };

  nix.optimise.automatic = true;
  nix.optimise.dates = [ "03:45" ]; # Optional; allows customizing optimisation schedule

  services.openssh.extraConfig = ''
    TrustedUserCAKeys /etc/certs/user_ca.pub
  '';
}
