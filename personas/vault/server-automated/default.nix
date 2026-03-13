{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ vault step-cli ];
  networking.firewall.allowedTCPPorts = [ config.hl1-io.vault.port ];

  services.vault = with config; {
    enable = true;
    dev = false;
    address = "0.0.0.0:${toString hl1-io.vault.port}";
    package = pkgs.vault-bin; # Enable UI Support
    storageBackend = "consul";
    storageConfig = ''
      address = "127.0.0.1:8500"
      path = "vault"
    '';
    listenerExtraConfig = ''
      address = "0.0.0.0:${toString hl1-io.vault.port}"
    '';
  };

  systemd.services.vault.postStart = with config;
    with pkgs; ''
      export VAULT_ADDR=http://127.0.0.1:${toString hl1-io.vault.port}
      alias vault=${vault}/bin/vault

      STATUS=$(vault status -format=json)

      ${vault}/bin/vault operator init --format json > /root/cred.json
    '';

  systemd.services.vault-init = with config;
    with pkgs; {
      enable = true;
      serviceConfig = { type = "oneshot"; };
      wantedBy = [ "multi-user.target" ];
      before = [ "tofu.service" ];
      requires = [ "vault.service" ];
      after = [ "vault.service" ];
      environment = {
        VAULT_ADDR = "http://127.0.0.1:${toString hl1-io.vault.port}";
      };

      script = ''
        #!/usr/bin/env fish
        set STATUS "$(vault status)"


        set SEALED "$(echo $STATUS | grep Sealed | awk '{print $2}')"
        set INITIALIZED "$(echo $STATUS | grep Initialized | awk '{print $2}')"

        alias vault ${vault}/bin/vault

        echo "Vault is currently sealed: $SEALED"
        echo "Vault is currently initialized: $INITIALIZED"

        if [ $INITIALIZED = false ]
            echo "Vault needs to be initialized!"
            set INIT_RESULT "$(vault operator init -key-shares=10 -key-threshold=5 -format=json)"
            set ROOT_TOKEN "$(echo $INIT_RESULT | jq .root_token -r)"
            set UNSEAL_KEYS "$(echo $INIT_RESULT | jq .unseal_keys_b64.[] -r)"

            set prev "$(pwd)"
            cd ~/hliac/secrets
            ls -lah vault/transient
            rm vault/transient/root-token -f
            rm vault/transient/unseal-keys -f
            ls -lah vault/transient
            echo $ROOT_TOKEN | agenix -e vault/transient/root-token
            echo $UNSEAL_KEYS | agenix -e vault/transient/unseal-keys
            cd $prev
        end

        if [ $SEALED = true ]
            echo "Vault needs to be unsealed!"
            set prev "$(pwd)"
            cd ~/hliac/secrets
            set UNSEAL_KEYS "$(EDITOR=cat agenix -e vault/transient/unseal-keys 2> /dev/null)"
            cd $prev
            for key in (echo $UNSEAL_KEYS)
                vault operator unseal $key
            end
        end
      '';
    };

}
