# Loopback-only staging of hyperdoc-catalog-topic-maps on a NixOS host, for an operator who opts in.
#
# Nothing in this repository imports it and it is not enabled by default. It adds one systemd service of its own, beside
# the production hyperdoc-catalog service, which it does not touch, and no reverse-proxy route, firewall rule or port
# opening. The service is not started at boot: an operator starts and stops it (docs/topic-maps-deployment/staging.md).
{ config, lib, ... }:
let
  cfg = config.services.hyperdoc-catalog-topic-maps-staging;
  name = "hyperdoc-catalog-topic-maps-staging";
in
{
  options.services.hyperdoc-catalog-topic-maps-staging = {
    enable = lib.mkEnableOption "the loopback-only staging Catalog with the pinned Topic Maps snapshot";
    package = lib.mkOption {
      type = lib.types.package;
      description = "hyperdoc-catalog-topic-maps from this flake (packages.<system>.hyperdoc-catalog-topic-maps).";
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = ''
        The loopback port the Catalog listens on. There is no default: choose a port that nothing on the host
        listens on (`ss -ltn`), so that the staging Catalog cannot collide with an existing service.
      '';
    };
    catalogSystem = lib.mkOption {
      type = lib.types.str;
      default = "topic-maps-deployment-review-asdf-collision";
      description = ''
        The ASDF system the Catalog loads in addition to its default books: by default the review reading
        "Deploying Topic Maps with HyperDoc". The packaged executable refuses the legacy Project Workspace and the
        page-attached system loader, and any system that depends on them, before it starts.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.port > 1023;
        message = "services.${name}.port must be an unprivileged port.";
      }
    ];

    systemd.services.${name} = {
      description = "HyperDoc Catalog with Topic Maps (staging, loopback only)";
      # Not at boot: systemctl start/stop ${name}.
      wantedBy = [ ];
      environment = {
        # The executable also refuses any other host before it loads anything.
        HYPERDOC_CATALOG_HOST = "127.0.0.1";
        HYPERDOC_CATALOG_PORT = toString cfg.port;
        HYPERDOC_CATALOG_SYSTEM = cfg.catalogSystem;
        HYPERDOC_FEDWIKI_SITE_ROOT = "/var/lib/${name}/site/";
        # The first start compiles the Lisp systems into this cache; later starts reuse it.
        XDG_CACHE_HOME = "/var/cache/${name}";
        HOME = "/var/lib/${name}";
      };
      preStart = ''
        mkdir -p /var/lib/${name}/site/pages
      '';
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/hyperdoc-catalog-topic-maps";
        # A stopped or failed staging Catalog stays stopped; the operator decides.
        Restart = "no";
        DynamicUser = true;
        StateDirectory = name;
        CacheDirectory = name;
        # Only loopback is reachable, in either direction: the Catalog needs no other network.
        IPAddressDeny = "any";
        IPAddressAllow = "localhost";
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        # The first start compiles a large Lisp image; these bound what it can take from the host.
        MemoryMax = "3G";
        TasksMax = 256;
      };
    };
  };
}
