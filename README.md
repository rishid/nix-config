
nix flake update

nixos-rebuild switch --flake .#server  


TODO:

Ordered by Priority:
- [x] Authelia
- [x] SMART tools monitoring and notifications
- [x] Prowlarr
- [ ] Transmission
- [ ] Sonarr
- [ ] Radarr
- [ ] Immich photo backup / test it is working
- [ ] Auth: Create more users
- [ ] Auth: can user change password?
- [ ] Enable Auth on all endpoints
- [ ] Look into OIDC w/ Jellyfin
- [ ] Do we need to do basic-auth and forward anywhere?
- [ ] Move sftpjail out of security.nix
- [ ] PlexTraktSync
    https://github.com/Taxel/PlexTraktSync
- [ ] Test Jellyfin on Roku
- [ ] Make lldap available via local network and tailscale only

Low Priority
- [ ] Enable fail2ban
- [ ] See if any app can provide terminal in event ssh goes down (or screw up config)
- [ ] Setup backup on external disk
- [ ] Disable login to FileBrowser
- [ ] add a mkMediaUser fn in lib
- [ ] add homepage-dashboard
    ref: https://github.com/LongerHV/nixos-configuration/blob/424d51e746951244369c21a45acf79d050244f8c/modules/nixos/homelab/homepage.nix#L3
- [ ] MergerFS
- [x] Docker socket proxy
- [x] Jellyfin
- [ ] Fix server power light
- [ ] Uptime Kuma / statping
- [ ] Homepage

- [ ] Mailrise


HOWTO

rsync from Synology to new server
rsync --rsync-path=/usr/bin/rsync @192.168.1.111:... .
