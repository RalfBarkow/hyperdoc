{ config, lib, pkgs, ... }:
let
  cfg = config.services.hyperdoc;
  inherit (lib) mkEnableOption mkIf mkOption types optionalAttrs;
in
{
  options.services.hyperdoc = {
    enable = mkEnableOption "HyperDoc service";

    package = mkOption {
      type = types.package;
      description = "HyperDoc package exposing bin/hyperdoc-release-start.";
      example = lib.literalExpression "self.packages.${pkgs.system}.hyperdoc-release";
    };

    serviceName = mkOption {
      type = types.str;
      default = "hyperdoc";
      description = "Systemd service name used for HyperDoc runtime.";
    };

    user = mkOption {
      type = types.str;
      default = "hyperdoc";
      description = "Runtime user for HyperDoc service.";
    };

    group = mkOption {
      type = types.str;
      default = "hyperdoc";
      description = "Runtime group for HyperDoc service.";
    };

    bindAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Bind address passed to HyperDoc runtime.";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Bind port passed to HyperDoc runtime.";
    };

    publicOrigin = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Public origin for canonical URLs, e.g. https://dreyeck.ch.";
    };

    reverseProxyDomain = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Reverse proxy domain for documentation/operator context.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/hyperdoc/data";
      description = "Persistent runtime data directory for HyperDoc service.";
    };
  };

  config = mkIf cfg.enable {
    users.groups = optionalAttrs (cfg.group == "hyperdoc") {
      hyperdoc = { };
    };

    users.users = optionalAttrs (cfg.user == "hyperdoc") {
      hyperdoc = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.dataDir;
        createHome = true;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.${cfg.serviceName} = {
      description = "HyperDoc service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/hyperdoc-release-start";
        Restart = "on-failure";
        RestartSec = "3s";
        NoNewPrivileges = true;
      };
      environment = {
        HYPERDOC_BIND_ADDRESS = cfg.bindAddress;
        HYPERDOC_PORT = toString cfg.port;
        HYPERDOC_DEVELOPMENT = "0";
        HYPERDOC_DEBUG = "0";
        HYPERDOC_USE_THREAD = "0";
        HYPERDOC_DATA_DIR = cfg.dataDir;
      } // optionalAttrs (cfg.publicOrigin != null) {
        HYPERDOC_PUBLIC_ORIGIN = cfg.publicOrigin;
      } // optionalAttrs (cfg.reverseProxyDomain != null) {
        HYPERDOC_REVERSE_PROXY_DOMAIN = cfg.reverseProxyDomain;
      };
    };
  };
}
