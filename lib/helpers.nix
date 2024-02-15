
mkMediaUser = { name, uid }:
  {
    inherit name;
      value =
        {
          inherit name uid shell;
          isNormalUser = true;
          isSystemUser = false;
          extraGroups = groups;
        }
        // (
          if password == null
          then {
            initialPassword = "helloworld";
          }
          else {
            hashedPassword = password;
          }
        );
    };
