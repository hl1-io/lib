{ config, ... }: {
  # hl1-io.consul.services.oauth2-proxy = {
  #   subdomain = "oauth2";
  #   label = "OAuth2 Proxy";
  #   port = 4180;
  #   address = config.hl1-io.node-meta.expected-fqdn;
  # };
  services.oauth2-proxy = {
    enable = true;
    requestLogging = true;
    reverseProxy = true;
    keyFile = "/var/keys/oauth2-proxy";
    email.domains =  "*";
    httpAddress = "0.0.0.0:4180";
    cookie = {
      domain = config.hl1-io.domains.authDomain ? config.hl1-io.domains.primary;
    };
  };

  networking.firewall.allowedTCPPorts = [ 4180 ];
  
  environment.etc."traefik.dyn/oauth-proxy.yaml" = {
    user = "traefik";
    group = "traefik";
    text = ''
      http:
        middlewares:
          oauth:
            chain:
              middlewares:
                - oauth-signin
                - oauth-verify

          oauth-verify:
              forwardAuth:
                  address: "http://${config.hl1-io.node-meta.expected-fqdn}:4180/oauth2/auth"
    '';
  };
}
