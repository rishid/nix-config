with (import ./keys); {

  # Password hash for NixOS user account
  # > mkpasswd -m sha-512 mySecr3tpa$$w0rd!
  "files/password-hash.age".publicKeys = all;

  # Plain-text password (typically used in web services)
  "files/password.age".publicKeys = all;

  # Traefik Environment Variables
  # ---------------------------------------------------------------------------
  # CloudFlare DNS API Token 
  # > https://dash.cloudflare.com/profile/api-tokens
  # ---------------------------------------------------------------------------
  # CF_DNS_API_TOKEN=xxxxxx
  # ---------------------------------------------------------------------------
  # Encoded ISY authentication header
  # > echo -n $ISY_USERNAME:$ISY_PASSWORD | base64
  # ---------------------------------------------------------------------------
  # ISY_BASIC_AUTH=xxxxxx
  # ---------------------------------------------------------------------------
  "files/traefik-env.age".publicKeys = all;

  # Basic Auth for traefik
  # > nix shell nixpkgs#apacheHttpd -c htpasswd -nb USERNAME PASSWORD
  # ---------------------------------------------------------------------------
  # USERNAME:$apr1$9GXtleUd$Bc0cNYaR42mIUvys6zJfB/
  # ---------------------------------------------------------------------------
  "files/basic-auth.age".publicKeys = all;

  # CloudFlare DNS API Token used by Traefik & Let's Encrypt
  # ---------------------------------------------------------------------------
  # CF_DNS_API_TOKEN=xxxxxx
  # ---------------------------------------------------------------------------
  "files/cloudflare-env.age".publicKeys = all;
  
}