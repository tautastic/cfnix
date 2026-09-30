{ config, lib, ... }:

{
  services.postgresql = {
    enable = true;

    settings.listen_addresses = "localhost";

    authentication = lib.mkOverride 10 ''
      # Unix socket: trust, since reaching it already means being this user.
      local all all trust
      # Loopback TCP still wants the password.
      host all all 127.0.0.1/32 scram-sha-256
      host all all ::1/128      scram-sha-256
    '';

    ensureDatabases = config.me.databases;

    ensureUsers = [{
      name = config.me.username;
      ensureClauses = {
        createdb = true;
        password = config.me.postgresVerifier;
      };
    }];
  };
}
