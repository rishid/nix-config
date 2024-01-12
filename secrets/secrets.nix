with (import ./keys); {

  # Password hash for NixOS user account
  # > mkpasswd -m sha-512 mySecr3tpa$$w0rd!
  "files/password-hash.age".publicKeys = all;
  
}
