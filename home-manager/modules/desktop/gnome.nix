{ config, lib, ... }:

let
  cfg = config.desktop;
in {
  config = lib.mkIf (cfg.environment == "gnome") {
    dconf.settings."org/gnome/desktop/peripherals/keyboard" = {
      inherit (cfg.keyboard) repeat;
      delay           = lib.hm.gvariant.mkUint32 cfg.keyboard.repeatDelay;
      repeat-interval = lib.hm.gvariant.mkUint32 cfg.keyboard.repeatInterval;
    };
  };
}
