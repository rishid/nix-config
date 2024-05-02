rec {

  users.rishi = [ 
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID/W4zB/IqV+O9s8MMiIq+7BobnEkUUQf0wkZTpL7WpZ dhupar@Dhupars-MacBook-Air"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEXm2SFCDKxeYHRM7SClgUh9S/oZKBYRItGTbgDmY/gY rdhupar@bos-mpl6a 2024-01-05T15:03:49Z"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkgaulO1q8vc/9oBiYDiWKbMuVhbqOEajnR1QOprsh0 rishi@nixos 2024-01-05T19:20:13Z"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICfVvipTVmw/XOD4FKfiknzOoR7lTItsC1YAy+DV/hnP rishi@server 2024-05-02T19:16:05Z"
  ];
  users.github = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICCnPNUGJwIAsoI2obJy+NwvNgqdt1Cd1mU1pvdtC7nk GHA@nixos-config"
  ];
  users.all = builtins.concatLists [ users.rishi users.github ];

  systems.server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE64OSHAUT4xG55JCpsKgNfH/G+OXPou3PLEQCkbW1W8";
  systems.all = [ systems.server ];

  all = users.all ++ systems.all;

}
