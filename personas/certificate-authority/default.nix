{ config, pkgs, hlib, ... }: {
  hl1-io.node-meta.personas = [ "certificate-authority" ];

  environment.systemPackages = with pkgs; [ step-ca step-cli ];

  hl1-io.consul.services."step-ca" = {
    enable = true;
    label = "Step Certificate Authority";
    port = 4443;
    subdomain = "stepca";
    httpsBackend = true;
    address = config.hl1-io.node-meta.expected-fqdn;
  };

  services.step-ca = {
    enable = true;
    intermediatePasswordFile = "/etc/step-ca/password.txt";
    openFirewall = true;
    address = "";
    port = 4443;
    settings = pkgs.lib.recursiveUpdate (pkgs.lib.importJSON ./ca.json) {
      dnsNames = [
        "${config.hl1-io.node-meta.expected-fqdn}"
        "localhost"
        "stepca.${config.hl1-io.domains.primary}"
      ];
    };
  };

  environment.etc."step-ca/templates" = { source = ./templates; };

  # TODO: It isn't clear if this is actually needed                                                                                                                          
  system.activationScripts = {
    stepca-setup = ''
      chown step-ca:step-ca -R /etc/smallstep
      chown step-ca:step-ca -R /etc/step-ca
      chmod 700 /etc/smallstep
      chmod 700 /etc/step-ca
    '';
  };

  deployment.keys = {
    "stepca-password-file" = {
      name = "password.txt";
      permissions = "0400";
      destDir = "/etc/step-ca";
      keyCommand = hlib.readPass "step/password.txt";
    };
    "stepca-root-key" = {
      name = "root_ca_key";
      keyCommand = hlib.readPass "step/root_ca.key";
      destDir = "/etc/step-ca/secrets";
    };
    "stepca-root-crt" = {
      name = "root_ca.crt";
      keyCommand = hlib.readPass "step/root_ca.crt";
      destDir = "/etc/step-ca/certs";
    };
    # Intermediate
    "stepca-intermediate-key" = {
      name = "intermediate_ca_key";
      keyCommand = hlib.readPass "step/intermediate_ca.key";
      destDir = "/etc/step-ca/secrets";
    };
    "stepca-intermediate-crt" = {
      name = "intermediate_ca.crt";
      keyCommand = hlib.readPass "step/intermediate_ca.crt";
      destDir = "/etc/step-ca/certs";
    };
    # SSH
    "stepca-ssh-host-key" = {
      name = "ssh_host_ca_key";
      keyCommand = hlib.readPass "step/ssh_host_ca_key";
      destDir = "/etc/step-ca/secrets";
    };
    "stepca-ssh-host-crt" = {
      name = "ssh_host_ca_key.pub";
      keyCommand = hlib.readPass "step/ssh_host_ca_key.pub";
      destDir = "/etc/step-ca/certs";
    };
    "stepca-ssh-user-key" = {
      name = "ssh_user_ca_key";
      keyCommand = hlib.readPass "step/ssh_user_ca_key";
      destDir = "/etc/step-ca/secrets";
    };
    "stepca-ssh-user-crt" = {
      name = "ssh_user_ca_key.pub";
      keyCommand = hlib.readPass "step/ssh_user_ca_key.pub";
      destDir = "/etc/step-ca/certs";
    };
  };
}

