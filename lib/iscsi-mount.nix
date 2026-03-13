{
  lib, pkgs, config, ...
}: let

  mkIscsiTarget = name: cfg:
  with cfg; ({...}: let 
   iscsiPortal = portal ? config.hl1-io.iscsi.defaultPortal;
  in {
    config = lib.mkIf enable {
      systemd.services."iscsi-mount-${name}" = {
        description = "Automount iSCSI target ${name} from ${iscsiPortal}";
        after = ["network.target" "iscsid.service" ];
        wants = [ "iscsid.service" ];

        serviceConfig = {
          ExecStartPre = "${pkgs.openiscsi}/bin/iscsiadm -m discovery -t sendtargets -p ${iscsiPortal}";
          ExecStart = "${pkgs.openiscsi}/bin/iscsiadm -m node -T ${target} -p ${iscsiPortal} --login";
          ExecStop = "${pkgs.openiscsi}/bin/iscsiadm -m node -T ${target} -p ${iscsiPortal} --logout";
          Restart = "on-failure";
          RemainAfterExit = true;        
        };
        wantedBy = ["multi-user.target"];
      };

      fileSystems."${mountPath}" = {
        device = "/dev/disk/by-path/"; # TODO: Identify this
        fsType = ""; # TODO: Figure out how to do LVM
      };
    };
  });
in {
  imports = lib.mapAttrsToList mkIscsiTarget config.hl1-io.iscsi.mounts;
}
