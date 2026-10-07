{
  username = "REDACTED[SYS_USER]";

  passwordHash = "REDACTED[USER_PASSWORD_HASH]";

  postgresVerifier = "REDACTED[POSTGRES_SCRAM]";

  git = {
    default = "REDACTED[GIT_USER_1]";
    identities = {
      "REDACTED[GIT_USER_1]" = {
        email = "REDACTED[GIT_EMAIL_1]";
        key = "REDACTED[GIT_USER_1]_id_ed25519";
        color = 66;
      };
      "REDACTED[GIT_USER_2]" = {
        email = "REDACTED[GIT_EMAIL_2]";
        key = "REDACTED[GIT_USER_2]_id_ed25519";
        color = 178;
      };
    };
  };
}
