{
  imports = [ 
    ./common.nix
    ../services/amethyst.nix
  ];

  users.groups.gemini = {
    members = [ "tris" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/gemini 775 root gemini"
  ];

  services.amethyst = {
    enable = true;
    hosts = "gemini.tris.fyi";

    path."/" = {
      root = "/var/gemini";
      autoindex = true;
    };
  };
}
