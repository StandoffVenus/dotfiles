{ config, lib, ... }:

let
  cfg = config.desktop;

  # macOS counts both settings in 15 ms ticks, and 1 is the fastest it takes.
  ticks = ms: lib.max 1 (ms / 15);
in {
  # macOS reads these at login, so a change applies from the next one.
  config = lib.mkIf (cfg.environment == "macos") {
    targets.darwin.defaults.NSGlobalDomain =
      if cfg.keyboard.repeat then {
        InitialKeyRepeat = ticks cfg.keyboard.repeatDelay;
        KeyRepeat        = ticks cfg.keyboard.repeatInterval;
        # Otherwise holding a letter opens the accent picker instead of
        # repeating it.
        ApplePressAndHoldEnabled = false;
      } else {
        # There is no off switch; a delay of 75 minutes amounts to one.
        InitialKeyRepeat = 300000;
      };
  };
}
