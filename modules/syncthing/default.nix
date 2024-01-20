# modules.restic.enable = true;
{ config, lib, pkgs, this, ... }:

let
  cfg = config.modules.syncthing;
in {
  # services.ntfy-sh = {
#       enable = true;
#       settings = {
#         base-url = "https://ntfy.dhupar.xyz";
#         listen-http = ":${toString port}";
#         behind-proxy = true;
#       };
#     };
}
