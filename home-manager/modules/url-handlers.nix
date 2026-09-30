# URL scheme handlers that GNOME actually uses.
#
# Browsers open custom-scheme links (nxm://, claude://, ...) through the
# xdg-desktop-portal, a long-running service that misses new .desktop
# entries behind the ~/.nix-profile symlink and then reports "No apps
# available". Each handler's entry therefore goes in
# ~/.local/share/applications, where it also shadows any copy in the
# profile under the same desktop file ID.
#
# The defaults are set with xdg-mime instead of xdg.mimeApps, which
# would take over all of mimeapps.list; they are re-applied on every
# switch so they survive other tools rewriting that file.
{ config, lib, pkgs, ... }:

let
  cfg = config.xdg.urlHandlers;
in {
  options.xdg.urlHandlers = lib.mkOption {
    default = { };
    description = "Scheme handlers, keyed by desktop file ID.";
    example = lib.literalExpression ''
      {
        "com.anthropic.Claude.desktop" = {
          source  = "''${pkgs.claude-desktop}/share/applications/com.anthropic.Claude.desktop";
          schemes = [ "claude" ];
        };
      }
    '';
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        source = lib.mkOption {
          type        = lib.types.path;
          description = "The .desktop file; use pkgs.writeText for an inline one.";
        };
        schemes = lib.mkOption {
          type        = lib.types.listOf lib.types.str;
          description = "URL schemes to make this entry the default for.";
        };
      };
    });
  };

  config = lib.mkIf (cfg != { }) {
    xdg.dataFile = lib.mapAttrs' (id: h:
      lib.nameValuePair "applications/${id}" { inherit (h) source; }
    ) cfg;

    home.activation.urlHandlers = lib.hm.dag.entryAfter [ "linkGeneration" ]
      (lib.concatStrings (lib.mapAttrsToList (id: h: ''
        run ${pkgs.xdg-utils}/bin/xdg-mime default ${lib.escapeShellArg id} \
          ${lib.escapeShellArgs (map (s: "x-scheme-handler/${s}") h.schemes)}
      '') cfg));
  };
}
