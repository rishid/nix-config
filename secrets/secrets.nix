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

  # CloudFlare DNS API Token used by Traefik & Let's Encrypt
  # ---------------------------------------------------------------------------
  # OPENVPN_USERNAME=xxxxxx
  # OPENVPN_PASSWORD=xxxxxx
  # ---------------------------------------------------------------------------
  "files/transmission-ovpn.age".publicKeys = all;
  
  # Restic
  # Plain text password generated using Restic
  "files/restic-password.age".publicKeys = all;
  # BorgBase.com URL
  "files/restic-borgbase-env.age".publicKeys = all;

  # Vaultwarden private environment variables
  "files/vaultwarden-env.age".publicKeys = all;

  # Authelia and LDAP
  "files/authelia-jwt.age".publicKeys = all;
  "files/authelia-storage.age".publicKeys = all;
  "files/authelia-session.age".publicKeys = all;
  "files/authelia-oidc-hmac.age".publicKeys = all;
  "files/authelia-oidc-issuer.age".publicKeys = all;
  "files/lldap-jwt-secret.age".publicKeys = all;
  "files/lldap-user-password.age".publicKeys = all;

  # *arr secrets
  "files/bazarr-api-key.age".publicKeys = all;
  "files/sonarr-api-key.age".publicKeys = all;
  "files/radarr-api-key.age".publicKeys = all;
  "files/unpackerr-env.age".publicKeys = all;
  "files/jellyfin-api-key.age".publicKeys = all;

  "files/immich-api-key.age".publicKeys = all;
}
