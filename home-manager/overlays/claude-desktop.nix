# Claude Desktop, from Anthropic's own apt repository (Linux beta).
#
# nixpkgs has no package, so this runs the upstream .deb unmodified
# inside an FHS environment. The app looks for Cowork's VM pieces at
# fixed Debian paths (/usr/share/OVMF/OVMF_CODE_4M.fd, /usr/bin/virtiofsd,
# qemu-system-* on PATH) and downloads its own Claude Code binaries at
# runtime, so patching the ELF files would not be enough anyway.
#
# The repository's package index is vendored next to this file, and the
# newest entry in it picks the version, URL and checksum, so a version
# bump is just a refresh of that file:
#
#   curl -fsSL https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages \
#     -o overlays/claude-desktop-Packages-amd64
#
# Everything Cowork needs (QEMU, OVMF, virtiofsd) lives only inside the
# FHS environment; only the launcher, icons, claude:// handler and GNOME
# search provider reach the profile. No system changes are needed:
# NixOS's udev rules make /dev/kvm and /dev/vhost-vsock 0666, and
# vhost_vsock loads on first open through its devname alias, so neither
# the kvm group nor boot.kernelModules is required (despite upstream's
# Debian instructions).
_final: prev:
let
  inherit (prev) lib;

  repo = "https://downloads.claude.ai/claude-desktop/apt/stable";

  # Only the amd64 index is vendored; arm64 would need its own.
  debArch = "amd64";

  # Debian control stanzas: "Key: value" lines, continuation lines
  # (leading space) ignored, stanzas separated by a blank line.
  parseStanza = stanza: lib.listToAttrs (lib.concatMap (line:
    let m = builtins.match "([A-Za-z0-9-]+): (.*)" line;
    in lib.optional (m != null) (lib.nameValuePair (lib.elemAt m 0) (lib.elemAt m 1))
  ) (lib.splitString "\n" stanza));

  latest = lib.last (lib.sort (a: b: lib.versionOlder a.Version b.Version)
    (lib.filter (p: p ? Package && p.Package == "claude-desktop")
      (map parseStanza (lib.splitString "\n\n"
        (builtins.readFile ./claude-desktop-Packages-${debArch})))));

  unwrapped = prev.stdenvNoCC.mkDerivation {
    pname   = "claude-desktop-unwrapped";
    version = latest.Version;

    src = prev.fetchurl {
      url    = "${repo}/${latest.Filename}";
      sha256 = latest.SHA256;
    };

    nativeBuildInputs = [ prev.dpkg ];

    # chrome-sandbox is setuid in the .deb, which the build sandbox refuses.
    # Chromium falls back to its user-namespace sandbox without it.
    unpackPhase = "dpkg-deb --fsys-tarfile $src | tar -x --no-same-owner --no-same-permissions";

    # Mirror the .deb's /usr, plus the GNOME Shell search provider that
    # its postinst would register. The D-Bus service is rewritten to use
    # nixpkgs' gjs; the provider only reads ~/.config/Claude and launches
    # the app through its .desktop entry.
    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -a usr/bin usr/lib usr/share $out/

      sp=$out/lib/claude-desktop/resources/gnome-search-provider
      install -Dm644 $sp/com.anthropic.Claude.search-provider.ini \
        -t $out/share/gnome-shell/search-providers
      install -Dm644 $sp/com.anthropic.Claude.SearchProvider.service \
        -t $out/share/dbus-1/services
      substituteInPlace $out/share/dbus-1/services/com.anthropic.Claude.SearchProvider.service \
        --replace-fail /usr/bin/gjs ${prev.gjs}/bin/gjs \
        --replace-fail /usr/lib/claude-desktop $out/lib/claude-desktop

      runHook postInstall
    '';

    dontStrip    = true;
    dontPatchELF = true;
  };

  # Debian's ovmf package layout, which the app probes for.
  ovmf = prev.runCommand "ovmf-debian-layout" { } ''
    mkdir -p $out/share/OVMF
    for kind in CODE VARS; do
      ln -s ${prev.OVMF.fd}/FV/OVMF_$kind.fd $out/share/OVMF/OVMF_$kind.fd
      ln -s ${prev.OVMF.fd}/FV/OVMF_$kind.fd $out/share/OVMF/OVMF_''${kind}_4M.fd
    done
  '';
in {
  claude-desktop = prev.buildFHSEnv {
    pname   = "claude-desktop";
    inherit (unwrapped) version;

    # The .deb's Depends and Recommends, by their nixpkgs names.
    targetPkgs = pkgs: with pkgs; [
      unwrapped

      # Depends
      gtk3
      libnotify
      nss
      nspr
      xdg-utils
      at-spi2-atk
      at-spi2-core
      libdrm
      libgbm
      mesa
      libglvnd # libEGL/libGL; drivers come from /run/opengl-driver
      libxcb
      libsecret
      glib
      libxtst
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxkbcommon
      libxshmfence
      util-linux # libuuid
      cups
      dbus
      expat
      pango
      cairo
      systemd # libudev
      vulkan-loader

      # Recommends
      alsa-lib
      libpulseaudio
      libayatana-appindicator
      cacert

      # Cowork's VM
      qemu_kvm
      ovmf
      virtiofsd
      libseccomp # for the bundled virtiofsd fallback
      libcap_ng

      # Tools the app and its Claude Code sessions shell out to.
      bash
      coreutils
      git
      openssh
      procps
      which
    ];

    runScript = "/usr/lib/claude-desktop/claude-desktop";

    # Only the entry points leave the FHS: the launcher, its icons, the
    # claude:// handler, and the GNOME search provider.
    extraInstallCommands = ''
      mkdir -p $out/share
      cp -r ${unwrapped}/share/icons ${unwrapped}/share/gnome-shell \
        ${unwrapped}/share/dbus-1 $out/share/
      install -Dm644 ${unwrapped}/share/applications/com.anthropic.Claude.desktop \
        -t $out/share/applications
    '';

    meta = {
      description = "Desktop application for Claude.ai";
      homepage    = "https://claude.ai";
      license     = lib.licenses.unfree;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      platforms   = [ "x86_64-linux" ];
      mainProgram = "claude-desktop";
    };
  };
}
