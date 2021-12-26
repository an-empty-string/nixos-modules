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
    hosts = [
      {
        name = "gemini.tris.fyi";
        paths."/" = {
          root = "/var/gemini";
          autoindex = true;
          cgi = false;
        };
        paths."/pydoc/" = {
          type = "pydoc";
        };
      }
    ];
  };
}
