{ config, lib, pkgs, ... }:

let
  cfg = config.desktop;
  kwriteconfig = "${pkgs.kdePackages.kconfig}/bin/kwriteconfig6";
in {
  # Written key by key rather than through xdg.configFile, because Plasma
  # keeps its other input settings in the same file and rewrites it.
  # Plasma reads these at login, so a change applies from the next one.
  config = lib.mkIf (cfg.environment == "plasma") {
    home.activation.plasmaKeyboard = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${kwriteconfig} --file kcminputrc --group Keyboard \
        --key KeyRepeat ${if cfg.keyboard.repeat then "repeat" else "nothing"}
      run ${kwriteconfig} --file kcminputrc --group Keyboard \
        --key RepeatDelay ${toString cfg.keyboard.repeatDelay}
      # Plasma takes a rate in repeats per second, not an interval.
      run ${kwriteconfig} --file kcminputrc --group Keyboard \
        --key RepeatRate ${toString (1000 / cfg.keyboard.repeatInterval)}
    '';
  };
}
