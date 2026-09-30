{
  username = "@@SYS_USER@@";

  passwordHash = "@@USER_PASSWORD_HASH@@";

  postgresVerifier = "@@POSTGRES_SCRAM@@";

  git = {
    default = "@@GIT_USER_1@@";
    identities = {
      "@@GIT_USER_1@@" = {
        email = "@@GIT_EMAIL_1@@";
        key = "@@GIT_USER_1@@_id_ed25519";
        color = 66;
      };
      "@@GIT_USER_2@@" = {
        email = "@@GIT_EMAIL_2@@";
        key = "@@GIT_USER_2@@_id_ed25519";
        color = 178;
      };
    };
  };
}
