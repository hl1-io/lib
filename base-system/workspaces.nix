{
  example = {
    roots = [ "$HOME/code" ];
    prefix = "hl1_";
    functions = {
      load_credentials = {
        description = "";
        content = ''
          set -gx VAULT_ADDR https://vault.example.com

          set -gx CONSUL_HTTP_ADDR https://consul.example.com
          set -gx CONSUL_HTTP_AUTH "$(pass show creds/consul/username):$(pass show creds/consul/password)"
        '';
      };
    };
    cleanup = "";
  };
}
