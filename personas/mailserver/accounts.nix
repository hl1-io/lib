{ config,  hlib, lib, ... }: {
  config = let accounts = config.hl1-io.mail.account; in {
    mailserver.loginAccounts = lib.mapAttrs' (name: account: lib.nameValuePair "${name}@${account.domain}" {
      hashedPasswordFile = "/run/keys/__mailbox_${name}";
      sendOnly = account.serviceAccount;
    }) accounts; 

    deployment.keys = lib.mapAttrs' (name: account: lib.nameValuePair "__mailbox_${name}" {
      keyCommand = account.passwordCommand;
    }) accounts;
  };
}