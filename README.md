
nix flake update

nixos-rebuild switch --flake .#server  


TODO:

References to review:
- make shares: https://github.com/notthebee/nix-config/blob/3d3b66c63098afde4c7bca60054c1fe56da206be/machines/nixos/emily/shares/default.nix#L36
- make media dirs https://github.com/notthebee/nix-config/blob/3d3b66c63098afde4c7bca60054c1fe56da206be/services/arr/default.nix#L37
- HA config: https://github.com/notthebee/nix-config/blob/3d3b66c63098afde4c7bca60054c1fe56da206be/services/smarthome/homeassistant.nix#L8
- paperless: https://www.reddit.com/r/selfhosted/comments/10eiy4n/paperlessngx_for_ios/
- paperless: https://www.reddit.com/r/selfhosted/comments/171rd8n/a_deep_dive_into_paperlessngx/
- recipes: https://github.com/mealie-recipes/mealie
- restic review: https://github.com/NobbZ/nixos-config/blob/1868cda7a1a02d9772978663a0d7cb1fa5e5208f/home/modules/services/restic/default.nix#L79
- youtube dl https://github.com/jmbannon/ytdl-sub https://github.com/alexta69/metube https://github.com/meeb/tubesync
 
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
- [ ] airprint
- [ ] systemd notify on failure
- [ ] Look into OIDC w/ Jellyfin
- [X] Get apex domain working and loading homepage-dashboard
- [ ] Speedtest
- [ ] Enable fail2ban
- [ ] auto camera copy: https://github.com/stonfute/BashUSBCopy
- [ ] See if any app can provide terminal in event ssh goes down (or screw up config)
- [ ] Setup backup on external disk
- [ ] Rclone google drive backup
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
