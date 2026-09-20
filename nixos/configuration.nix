{ config, pkgs, ... }:

let
  lib = pkgs.lib;

  liam = rec {
    username = "kaiser";
    homeDir  = "/home/${username}";
  };

  mkBind = target:
    assert lib.isString target;
    {
      device  = target;
      fsType  = "none";
      options = [ "bind" ];
    };

  mkDiskByUuid = opts:
    assert lib.isAttrs  opts;
    assert lib.isString opts.uuid;
    assert lib.isList   opts.options;
    {
      device  = "/dev/disk/by-uuid/${opts.uuid}";
      fsType  = opts.fsType or "ext4";
      options = opts.options;
    };
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

  nixpkgs.config = {
    allowUnfree = true;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.kernelPackages = pkgs.linuxPackages_6_18;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  networking.networkmanager.enable = true;
  networking.hostName = "kaiser_nixos";

  fileSystems =
    let
      home  = "/mnt/home-${liam.username}";
      games = "/mnt/games";
    in {
      "${liam.homeDir}"       = mkBind home;
      "${liam.homeDir}/Games" = mkBind games;

      "${home}" = mkDiskByUuid {
        uuid    = "79f6a2b3-ceea-4317-b35d-169dc4eaf0fb";
        options = [ "auto" "relatime" "nodev" "x-systemd.device-timeout=10" ];
      };

      "${games}" = mkDiskByUuid {
        uuid    = "f83c7313-49ad-4b0e-ab40-af8d8bb1713f";
        options = [ "auto" "noatime" "nofail" "nodev" "x-systemd.device-timeout=10" ];
      };
    };

  time.timeZone = "America/Chicago";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  security.rtkit.enable = true;

  # YubiKey (FIDO U2F) as an alternative to password for login and sudo.
  # control = "sufficient": touching the key grants access immediately;
  # if it's absent/unregistered, PAM falls through to the password prompt.
  # Enroll a key with: pamu2fcfg -o pam://kaiser_nixos -i pam://kaiser_nixos
  # then add the printed line to /etc/u2f_mappings as "kaiser:<line>".
  security.pam.u2f = {
    enable = true;
    control = "sufficient";
    settings = {
      cue = true;
      authfile = "/etc/u2f_mappings";
      origin = "pam://kaiser_nixos";
      appid = "pam://kaiser_nixos";
    };
  };

  security.pam.services = {
    sudo.u2fAuth = true;
    login.u2fAuth = true;
    gdm-password.u2fAuth = true;
    polkit-1.u2fAuth = true;
  };

  security.pam.loginLimits = [
    {
      domain = "@audio";
      item   = "memlock";
      type   = "-";
      value  = "unlimited";
    }
    {
      domain = "@audio";
      item   = "rtprio";
      type   = "-";
      value  = "99";
    }
  ];

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
    pulse.enable = true;
  };

  services.libinput = {
    enable = true;
    mouse = {
      scrollMethod = "button";
      scrollButton = 274;
      additionalOptions = ''
        Option "ScrollButtonLock" "true"
      '';
    };
  };

  users.users."${liam.username}" = {
    isNormalUser = true;
    home         = liam.homeDir;
    description  = "Liam";
    extraGroups  = [
      "networkmanager"
      "wheel"
      "audio"
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    pam_u2f
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {

  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
}
