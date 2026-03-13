{ lib, ... }:
with lib;
{
  options.hl1-io.pki = {
    caCert = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "PEM-encoded root CA certificate, installed system-wide and distributed to /etc/certs/root_ca.crt";
      example = "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----\n";
    };

    hostCaPub = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "SSH host CA public key, distributed to /etc/certs/host_ca.pub";
      example = "ecdsa-sha2-nistp256 AAAA...";
    };

    userCaPub = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "SSH user CA public key, distributed to /etc/certs/user_ca.pub and trusted by sshd";
      example = "ecdsa-sha2-nistp256 AAAA...";
    };

    caFingerprint = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Fingerprint of the root CA certificate, used to configure the step CLI client";
      example = "7b1c58d99a067a170dcadd3b892af2c903f594d6bcc4d2d04762a05962a3618d";
    };
  };
}
