{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.services.amethyst;
in
{
  imports = [
  ];

  options = {
    services.amethyst = {
      enable = mkEnableOption "Amethyst Gemini server";

      openFirewall = mkOption {
        default = true;
        type = types.bool;
      };

      package = mkOption {
        default = pkgs.callPackage (import (pkgs.fetchFromGitHub {
          owner = "an-empty-string";
          repo = "amethyst";
          rev = "47ae6894fbf4aebb42d55574cb4a9a86de2ffd0a";
          hash = "sha256-K7iCdLfwj+VD1IEUmcuB2Bzb5Nkf1Lo372j4bJ9RINA=";
        })) {
          extensionPackages = [
            (pkgs.callPackage (import (pkgs.fetchFromGitHub {
              owner = "an-empty-string";
              repo = "amethyst_extensions";
              rev = "44e01342b0d904ce4b4e77ffee34e8cced122bd8";
              hash = "sha256-vdV6hyLN3l1xHTTq9w/ISqUKYZnSoX18hMlDR00ReEo=";
            })) {})
          ];
        };
        type = types.package;
      };

      port = mkOption {
        type = types.int;
        example = literalExpression "1965";
        default = 1965;
        description = "The port Amethyst will listen on.";
      };

      hosts = mkOption {
        default = { };
        type = types.listOf (types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Name of host described by this block";
              example = literalExpression ''"gemini.tris.fyi"'';
            };

            tls = mkOption {
              type = types.attrs;
              example = literalExpression ''
                {
                  auto = false;
                  cert_path = "/path/to/cert.pem";
                  key_path = "/path/to/key.pem";
                }
              '';

              default = {};
              description = "TLS options for the host";
            };

            paths = mkOption {
              type = types.attrs;
              example = literalExpression ''
                {
                  "/" = {
                    root = "/var/gemini";
                    autoindex = true;
                    cgi = false;
                  };
                }
              '';

              default = {
                "/" = {
                  root = "/var/gemini";
                  autoindex = true;
                  cgi = false;
                };
              };

              description = "Path configuration for the host";
            };
          };
        });
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (length cfg.hosts) > 0;
        message = "You must define at least one host to enable Amethyst.";
      }
    ];

    environment.etc."amethyst.conf".text = builtins.toJSON cfg;

    systemd.services.amethyst = {
      description = "Amethyst Gemini server";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        DynamicUser = "yes";
        StateDirectory = "amethyst";
        ExecStart = "${cfg.package}/bin/amethyst /etc/amethyst.conf";
        ReadWritePaths = sort lessThan (unique (
          filter isString (lists.flatten (
            map (h: (
              mapAttrsToList
                (p: pc: if hasAttr "root" pc then pc.root else null) h.paths
              )
            ) cfg.hosts
          ))
        ));
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
