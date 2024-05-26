
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
- [x] Jellyseerr
- [x] Unpackerr
- [x] Jellyfin
- [x] Watchtower?
- [x] Cloudflare-ddns
- [x] Immich photo backup / test it is working
- [x] Add media path configs and create the directories
- [x] Change all the paths in all the services to new location
- [ ] Auth: Create more users
- [ ] Auth: can user change password?
- [ ] power: check usage and optimize
- [x] Enable Auth on all endpoints
- [x] Do we need to do basic-auth and forward anywhere?
- [x] Move sftpjail out of security.nix
- [ ] PlexTraktSync
    https://github.com/Taxel/PlexTraktSync
- [ ] Test Jellyfin on Roku
- [x] Make lldap available via local network and tailscale only

Transition
- [x] Confirm USB backup is up-to-date
- [x] server: remove both hard drives
- [x] syno: remove one HD and install in server
  - [x] server: partition and add to nix as data drive in mergerfs
- [x] server: rsync synology to data drive
- [x] syno: insert enterprise drive and force rebuild
- [ ] syno: remove other HD and install in server
  - [ ] server: partition and add to nix as snapraid
  - [ ] server: trigger snapraid sync
- [ ] syno: insert enterprise drive and force rebuild
- [ ] server: rsync (again) synology to data drive
- [ ] change over port forwarding
- [ ] server: wait till server is running smoothly, then move external drive over
- [ ] server: add a daily rsync from server to synology

Low Priority
- [ ] smart raid alt: https://github.com/AnalogJ/scrutiny
- [ ] container updates
- [ ] airprint
- [ ] systemd notify on failure
- [ ] auto container updates
- [ ] systemd notify on failure, general handler. can use ntfy.sh
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
- [x] MergerFS
- [x] Docker socket proxy
- [x] Jellyfin
- [ ] Fix server power light
- [ ] Uptime Kuma / statping
- [x] Homepage
- [ ] https://github.com/AnalogJ/scrutiny

- [ ] Mailrise

## Rsync data from Synology to new server

--delete --delete-excluded

```bash
keychain ~/.ssh/id25519
sudo bash
RSYNC_ARGS="--rsync-path=/usr/bin/rsync -ahP --exclude @eaDir/"
rsync $RSYNC_ARGS rishi@192.168.1.111:/volume1/applications/ /mnt/pool/applications
rsync $RSYNC_ARGS rishi@192.168.1.111:/volume1/backup/ /mnt/pool/backup
rsync $RSYNC_ARGS \
  -og --chown media:media \
  rishi@192.168.1.111:/volume1/data/ /mnt/pool/media
rsync $RSYNC_ARGS \
  --exclude 'home-gallery/' \
  --exclude 'oveerseerr/cache/' \
  --exclude 'plex/Library/Application Support/Plex Media Server/Cache/' \
  rishi@192.168.1.111:/volume1/docker /mnt/pool/backup
rsync $RSYNC_ARGS rishi@192.168.1.111:/volume1/documents/ /mnt/pool/documents
rsync $RSYNC_ARGS rishi@192.168.1.111:/volume1/etc /mnt/pool/backup
rsync $RSYNC_ARGS \
  -og --chown photos:photos \
  rishi@192.168.1.111:/volume1/photo/ /mnt/pool/photos
```

rclone copy syno_sftp:/data /mnt/pool/media \
  --sftp-path-override /volume1/data \
  --multi-thread-streams=32 -v

rclone copy syno_sftp:/photo /mnt/pool/photos \
  --sftp-path-override /volume1/photo \
  --multi-thread-streams=32

If needed:
find /mnt/user -name @eaDir -exec rm '{}' \;

sudo chown -R media:media /path/to/directory
find /path/to/directory -type f -exec chmod 640 {} \;
find /path/to/directory -type d -exec chmod 750 {} \;


## Adding a Raw Hard Drive to a NixOS System and Formatting it with ext4 (largefile option)

### Step 1: Identify the New Hard Drive
 * Open a terminal and run `lsblk` to list all disks and their device paths (e.g., `/dev/sda`).
 * Note the device path of the raw hard drive you want to add.

```bash
lsblk
```
### Step 2: Partition the Hard Drive

Create a New GPT Partition Table with sgdisk

Note: all commands must be run with root privileges 

#### Step 1: Verify the Device is Empty
* Run `sgdisk -v /dev/device` to verify the device is empty and has no existing partition table.

#### Step 2: Create a New GPT Partition Table
* Run `sgdisk --clear /dev/device` to create a new GPT partition table. The `--clear` option will clear the existing partition table and create a new one.

#### Step 3: Create a Single Partition for Storage
* Run `sgdisk --new 1:0:0 --change-name 1:"Storage" /dev/device` to create a single partition spanning the entire device. The options used are:
	+ `-n 1:0:0` to create a new partition with the following attributes:
		- `1` is the partition number
		- `0` is the starting sector (default is 2048)
		- `0` is the ending sector (default is the last sector on the device)
	+ `-c 1:"Storage"` to set the partition name to "Storage"

#### Step 4: Verify the Partition Table
* Run `sgdisk -p /dev/device` to verify the partition table and ensure the new partition has been created correctly.

#### Step 3: Format the Hard Drive with ext4 and largefile Option
* Format each partition with ext4 and the largefile option by running:
```bash
sudo mkfs.ext4 -L <LABEL> -T largefile /dev/partition
```

#### Step 4: Update nix config
To make the mount persistent across reboots, you need to add an entry to your NixOS configuration. Open /etc/nixos/configuration.nix in your preferred text editor and add the following under the fileSystems attribute:

```bash
{
  fileSystems."/mnt/mynewdrive" = {
    device = "/dev/sda1";
    fsType = "ext4";
    options = [ "defaults" "largefile" ];
  };
}
```


/mnt/disks/
/mnt/parity/

/mnt/flash
/mnt/depot   
/mnt/pool    (combine of flash and depot)
