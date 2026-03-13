{ hlib, pkgs, ... }:

{
  hl1-io.node-meta.personas = [ "object-storage" ];
  environment.systemPackages = with pkgs; [ minio-client ];
  services.minio = {
    enable = true;
    browser = true;
  };

  hl1-io.consul.services = {
    "minio-ui" = {
      enable = true;
      label = "Minio UI";
      port = 9001;
      subdomain = "minio";
    };
    "minio" = {
      enable = true;
      label = "Minio S3 API";
      port = 9000;
      subdomain = "s3";
    };
  };

  networking.firewall.allowedTCPPorts = [
    9000 # S3
    9001 # Console
  ];

}
