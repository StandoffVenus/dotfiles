# Desktop settings, declared once and applied to whichever desktop
# environment is in use.
#
# Each environment keeps these settings in its own store (dconf for
# GNOME, kcminputrc for Plasma), so switching desktops means changing
# `desktop.environment` here and the desktopManager in ~/.config/nixos.
# Home Manager runs standalone and cannot read the latter, so the two
# must be kept in step by hand.
{ lib, ... }:

{
  imports = [
    ./url-handlers.nix
    ./gnome.nix
    ./plasma.nix
  ];

  options.desktop = {
    environment = lib.mkOption {
      type        = lib.types.enum [ "gnome" "plasma" ];
      description = "The desktop environment the settings are written for.";
    };

    keyboard = {
      repeat = lib.mkOption {
        type        = lib.types.bool;
        default     = true;
        description = "Whether a held key repeats.";
      };
      repeatDelay = lib.mkOption {
        type        = lib.types.ints.positive;
        default     = 500;
        description = "Milliseconds a key is held before it starts repeating.";
      };
      repeatInterval = lib.mkOption {
        type        = lib.types.ints.positive;
        default     = 30;
        description = "Milliseconds between repeats.";
      };
    };
  };
}
