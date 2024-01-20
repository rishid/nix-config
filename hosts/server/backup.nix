# modules.restic = {
  #   enable = true;
  #   repositoryPath = "/restic";
  #   passwordFile = config.age.secrets.restic-password.path;
  #   # timerConfig = {
  #   #   OnCalendar = "02:00";
  #   #   RandomizedDelaySec = "1h";
  #   # };

  #   prune = {
  #     options = [
  #       "--keep-daily 7"
  #       "--keep-weekly 5"
  #       "--keep-monthly 12"
  #       "--keep-yearly 75"
  #     ];
  #     timerConfig = {
  #       OnCalendar = "07:00";
  #       RandomizedDelaySec = "2h";
  #     };
  #   };
  # };
  asd

modules.restic.local = {
  enable = true;
  repositoryPath = "/restic";
  initialize = true;
  passwordFile = config.age.secrets.restic-password.path;  
  prune = {
    options = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
      "--keep-yearly 75"
    ];
    timerConfig = {
      OnCalendar = "07:00";
      RandomizedDelaySec = "2h";
    };
  };
}
