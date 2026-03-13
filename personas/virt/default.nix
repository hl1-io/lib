{ ... }: {
  virtualisation.incus.enable = true;
  virtualisation.incus.preseed = {

  };

  virtualisation.incus.softDaemonRestart = true;
  virtualisation.incus.ui.enable = true;

  networking.nftables.enable = true;
}
