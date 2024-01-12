rec {

  users.rishi = [ 
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID/W4zB/IqV+O9s8MMiIq+7BobnEkUUQf0wkZTpL7WpZ dhupar@Dhupars-MacBook-Air"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEXm2SFCDKxeYHRM7SClgUh9S/oZKBYRItGTbgDmY/gY rdhupar@bos-mpl6a 2024-01-05T15:03:49Z"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkgaulO1q8vc/9oBiYDiWKbMuVhbqOEajnR1QOprsh0 rishi@nixos 2024-01-05T19:20:13Z"
  ];
  users.all = builtins.concatLists [ users.rishi ];

  systems.server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE64OSHAUT4xG55JCpsKgNfH/G+OXPou3PLEQCkbW1W8";
  systems.all = [ systems.server ];

  all = users.all ++ systems.all;

}
