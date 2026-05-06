{ config, pkgs, ... }:
let
  cfg = config.hl1-io.space-engineers;
  user = "spaceengineers";
  group = "spaceengineers";
  appManifest = "${cfg.installDir}/game/steamapps/appmanifest_${toString cfg.steamAppId}.acf";

  installScript = pkgs.writeShellScript "se-install" ''
    set -euo pipefail

    echo "Installing Space Engineers (App ID ${toString cfg.steamAppId}) via SteamCMD..."
    ${pkgs.steamcmd}/bin/steamcmd \
      +force_install_dir ${cfg.installDir}/game \
      +login anonymous \
      +app_update ${toString cfg.steamAppId} validate \
      +quit

    # Download the latest Proton GE release if not already present.
    # proton-ge-bin from nixpkgs cannot be used here because it outputs a bare
    # archive file that buildEnv cannot merge; we fetch from GitHub instead.
    PROTON_DIR="${cfg.installDir}/proton"
    if [ ! -f "$PROTON_DIR/proton" ]; then
      echo "Fetching latest Proton GE release metadata..."
      RELEASE=$(${pkgs.curl}/bin/curl -sf \
        "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest")
      TARBALL_URL=$(echo "$RELEASE" \
        | ${pkgs.jq}/bin/jq -r '.assets[] | select(.name | endswith(".tar.gz")) | .browser_download_url')
      echo "Downloading $TARBALL_URL ..."
      mkdir -p "$PROTON_DIR"
      ${pkgs.curl}/bin/curl -L "$TARBALL_URL" \
        | ${pkgs.gnutar}/bin/tar -xz -C "$PROTON_DIR" --strip-components=1
      echo "Proton GE installed to $PROTON_DIR"
    else
      echo "Proton GE already present, skipping download."
    fi

    echo "Installation complete."
  '';
in
{
  systemd.services.space-engineers-install = {
    description = "Space Engineers: First-run installation via SteamCMD";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
      "systemd-tmpfiles-setup.service"
    ];
    wants = [ "network-online.target" ];
    # Skip if already installed
    unitConfig.ConditionPathExists = "!${appManifest}";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = user;
      Group = group;
      Environment = "HOME=${cfg.installDir}";
      ExecStart = installScript;
      StandardOutput = "journal";
      StandardError = "journal";
      SyslogIdentifier = "space-engineers-install";
    };
  };
}
