services.ntfy-sh = {
      enable = true;
      settings = {
        base-url = "https://ntfy.dhupar.xyz";
        listen-http = ":${toString port}";
        behind-proxy = true;
      };
    };
