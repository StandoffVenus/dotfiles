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

  # Weekly sweep of the store, so /nix does not creep back up to filling the
  # disk. The timer runs as root and so only expires root-owned profiles:
  # home-manager generations are left alone, and `nix-clean` (defined in
  # ~/.config/home-manager) is still the way to expire those and to force a
  # collection on demand. 30d is deliberately lax; it keeps a month of
  # rollbacks, and nix-clean --all is there when the disk is actually tight.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
    randomizedDelaySec = "30min";
  };

  # Hard-links identical files in the store. Runs separately from gc because
  # doing both at once is slow and they have nothing to do with each other.
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  boot.kernelPackages = pkgs.linuxPackages_6_18;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Without a cap the boot menu keeps listing generations that gc has already
  # deleted from the store, which makes those entries unbootable.
  boot.loader.systemd-boot.configurationLimit = 5;

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

  # YubiKey (FIDO U2F) as an alternative to password for sudo and polkit.
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

  # Not for the first login of a session: "sufficient" returns before
  # pam_gnome_keyring sees a password, which leaves the login keyring
  # locked, and with it every app storing secrets through libsecret (Brave,
  # Claude Desktop). Typing the password there unlocks it; the key stays a
  # shortcut where no keyring is involved. u2f.enable turns u2fAuth on for
  # every service, hence the explicit false for login (and the TTYs).
  security.pam.services = {
    sudo.u2fAuth = true;
    polkit-1.u2fAuth = true;
    login.u2fAuth = false;

    # GDM serves both the first login and the lock screen, through this
    # service. Its stack is just a substack of login, so u2fAuth has no
    # effect here and the rules are written out. The key is only offered
    # once the user already has a graphical session, i.e. at the lock
    # screen, where the keyring is already unlocked. With the key plugged
    # in, the password prompt appears only after the touch times out.
    gdm-password.rules.auth =
      let
        loginOrder = config.security.pam.services.gdm-password.rules.auth.login.order;

        hasGraphicalSession = pkgs.writeShellScript "has-graphical-session" ''
          sessions=$(${pkgs.systemd}/bin/loginctl show-user "$PAM_USER" \
            -p Sessions --value 2>/dev/null) || exit 1
          for s in $sessions; do
            case $(${pkgs.systemd}/bin/loginctl show-session "$s" -p Type --value) in
              wayland|x11) exit 0 ;;
            esac
          done
          exit 1
        '';
      in {
        # On failure, jumps over the u2f rule straight to the password.
        u2f-if-unlocking = {
          order      = loginOrder - 20;
          control    = "[success=ignore default=1]";
          modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
          args       = [ "quiet" "${hasGraphicalSession}" ];
        };
        u2f = {
          order      = loginOrder - 10;
          control    = "sufficient";
          modulePath = "${pkgs.pam_u2f}/lib/security/pam_u2f.so";
          inherit (config.security.pam.u2f) settings;
        };
      };
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

    # Bitwarden's "Unlock with system authentication" asks polkit, which
    # only reads actions from the system profile; the app itself comes from
    # home-manager. Its own setup would write this to /usr/share, which the
    # nixpkgs build disables. With polkit-1.u2fAuth above, a key touch
    # unlocks the vault, falling back to the password.
    (runCommand "bitwarden-polkit-policy" { } ''
      install -Dm644 -t $out/share/polkit-1/actions \
        ${bitwarden-desktop}/share/polkit-1/actions/com.bitwarden.Bitwarden.policy
    '')
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
