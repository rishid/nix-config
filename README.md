
nix flake update

nixos-rebuild switch --flake .#server  


TODO:

Ordered by Priority:
- [x] Authelia
- [x] SMART tools monitoring and notifications
- [x] Prowlarr
- [x] Transmission
- [x] Sonarr
- [x] Radarr
- [x] Bazarr restore
- [ ] Jellyseerr
- [x] Unpackerr
- [x] Jellyfin
- [x] Watchtower?
- [x] Cloudflare-ddns
- [x] Immich photo backup / test it is working
- [ ] Add media path configs and create the directories
- [ ] Auth: Create more users
- [ ] Auth: can user change password?
- [x] Enable Auth on all endpoints
- [x] Do we need to do basic-auth and forward anywhere?
- [ ] Move sftpjail out of security.nix
- [ ] PlexTraktSync
    https://github.com/Taxel/PlexTraktSync
- [ ] Test Jellyfin on Roku
- [ ] Make lldap available via local network and tailscale only

Low Priority
- [ ] container updates
- [ ] systemd notify on failure
- [ ] Look into OIDC w/ Jellyfin
- [X] Get apex domain working and loading homepage-dashboard
- [ ] Speedtest
- [ ] Enable fail2ban
- [ ] See if any app can provide terminal in event ssh goes down (or screw up config)
- [ ] Setup backup on external disk
- [x] Disable login to FileBrowser
- [ ] add a mkMediaUser fn in lib
- [x] add homepage-dashboard
    ref: https://github.com/LongerHV/nixos-configuration/blob/424d51e746951244369c21a45acf79d050244f8c/modules/nixos/homelab/homepage.nix#L3
- [ ] MergerFS
- [x] Docker socket proxy
- [x] Jellyfin
- [ ] Fix server power light
- [ ] Uptime Kuma / statping
- [x] Homepage

- [ ] Mailrise


HOWTO

rsync from Synology to new server
rsync --rsync-path=/usr/bin/rsync @192.168.1.111:... .
