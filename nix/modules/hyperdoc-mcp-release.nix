{ config, lib, pkgs, ... }:
let
  cfg = config.services.hyperdocMcp;
  inherit (lib) concatStringsSep mkEnableOption mkIf mkOption optionalAttrs types;
in
{
  options.services.hyperdocMcp = {
    enable = mkEnableOption "HyperDoc DMX MCP service";

    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = "HyperDoc package exposing bin/hyperdoc-mcp-release-start.";
      example = lib.literalExpression "self.packages.${pkgs.system}.hyperdoc-release";
    };

    packagePath = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Pinned executable root as a plain string path exposing bin/hyperdoc-mcp-release-start.";
      example = "/nix/store/0123456789abcdefghijklmnopqrstuv-hyperdoc-release";
    };

    serviceName = mkOption {
      type = types.str;
      default = "hyperdoc-mcp";
      description = "Systemd service name used for the HyperDoc MCP runtime.";
    };

    user = mkOption {
      type = types.str;
      default = "hyperdoc-mcp";
      description = "Runtime user for the HyperDoc MCP service.";
    };

    group = mkOption {
      type = types.str;
      default = "hyperdoc-mcp";
      description = "Runtime group for the HyperDoc MCP service.";
    };

    bindAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Bind address passed to the HyperDoc MCP runtime.";
    };

    port = mkOption {
      type = types.port;
      default = 8787;
      description = "Bind port passed to the HyperDoc MCP runtime.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/hyperdoc/mcp";
      description = "Persistent runtime data directory for the HyperDoc MCP service.";
    };

    workspaceTopicmapId = mkOption {
      type = types.int;
      default = 919822;
      description = "DMX topicmap id exposed as the shared workspace.";
    };

    dmxBaseUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional DMX base URL used by the MCP read/write adapter.";
    };

    dmxWorkspaceId = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Optional DMX workspace topic id sent as the default dmx_workspace_id cookie for guarded DMX writes.";
    };

    dmxImportEnvironmentFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional systemd EnvironmentFile path string exporting HYPERDOC_DMX_IMPORT_AUTH_* credentials for authenticated DMX writes.";
    };

    enableLiveWrites = mkOption {
      type = types.bool;
      default = false;
      description = "Enable guarded MCP live writes. Keep false until the DMX backend contract is proven.";
    };

    allowedOrigins = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Allowed HTTP origins for the MCP Streamable HTTP endpoint.";
    };

    bearerTokenFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional systemd EnvironmentFile path string exporting HYPERDOC_MCP_BEARER_TOKEN=... for guarded live writes.";
    };

    reverseProxyHost = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional HTTPS host exposing the MCP endpoint via nginx.";
      example = "mcp.dreyeck.ch";
    };

    reverseProxyPath = mkOption {
      type = types.str;
      default = "/mcp";
      description = "HTTP path exposed by the reverse proxy for the MCP endpoint.";
    };

    useACMEHost = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional existing ACME host whose certificate should be reused for the reverse-proxy vhost.";
      example = "dreyeck.ch";
    };
  };

  config = mkIf cfg.enable (let
    execRoot =
      if cfg.package != null
      then "${cfg.package}"
      else cfg.packagePath;
  in {
    assertions = [
      {
        assertion = cfg.package != null || cfg.packagePath != null;
        message = "services.hyperdocMcp requires either package or packagePath to expose bin/hyperdoc-mcp-release-start.";
      }
    ];

    users.groups = optionalAttrs (cfg.group == "hyperdoc-mcp") {
      hyperdoc-mcp = { };
    };

    users.users = optionalAttrs (cfg.user == "hyperdoc-mcp") {
      hyperdoc-mcp = {
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
      description = "HyperDoc DMX MCP service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${execRoot}/bin/hyperdoc-mcp-release-start";
        Restart = "on-failure";
        RestartSec = "3s";
        NoNewPrivileges = true;
      } // optionalAttrs (cfg.bearerTokenFile != null || cfg.dmxImportEnvironmentFile != null) {
        EnvironmentFile = builtins.filter (path: path != null) [
          cfg.bearerTokenFile
          cfg.dmxImportEnvironmentFile
        ];
      };
      environment = {
        HYPERDOC_MCP_BIND_ADDRESS = cfg.bindAddress;
        HYPERDOC_MCP_PORT = toString cfg.port;
        HYPERDOC_MCP_WORKSPACE_TOPICMAP_ID = toString cfg.workspaceTopicmapId;
        HYPERDOC_MCP_ENABLE_LIVE_WRITES = if cfg.enableLiveWrites then "1" else "0";
      } // optionalAttrs (cfg.allowedOrigins != [ ]) {
        HYPERDOC_MCP_ALLOWED_ORIGINS = concatStringsSep "," cfg.allowedOrigins;
      } // optionalAttrs (cfg.dmxBaseUrl != null) {
        HYPERDOC_DMX_IMPORT_BASE_URL = cfg.dmxBaseUrl;
      } // optionalAttrs (cfg.dmxWorkspaceId != null) {
        HYPERDOC_DMX_IMPORT_WORKSPACE_ID = toString cfg.dmxWorkspaceId;
      };
    };

    services.nginx = mkIf (cfg.reverseProxyHost != null) {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts.${cfg.reverseProxyHost} = {
        forceSSL = true;
        locations.${cfg.reverseProxyPath} = {
          proxyPass = "http://${cfg.bindAddress}:${toString cfg.port}/mcp";
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          '';
        };
      } // optionalAttrs (cfg.useACMEHost != null) {
        useACMEHost = cfg.useACMEHost;
      } // optionalAttrs (cfg.useACMEHost == null) {
        enableACME = true;
      };
    };
  });
}
