# GE-Proton9-27, the last GE build on the Proton 9 base. Fallout: New
# Vegas is a 2010 32-bit title and is markedly less stable on the
# Proton 11 line that both Experimental and current GE now sit on.
#
# steamDisplayName must equal version, and the compatibilitytools.d
# directory must use that same string. It is tempting to shorten it to
# "GE-Proton9", but the tool then reports two different names: the vdf
# and directory say GE-Proton9 while its version file says
# GE-Proton9-27. SteamTinkerLaunch resolves one to the other, feeds the
# result back into its own fixProtonVersionMismatch, and spins forever
# without ever launching.
#
# version and src must be overridden together: src's URL interpolates
# finalAttrs.version, so bumping version alone re-points the download
# while keeping the old hash.
_final: prev: {
  proton-ge9 =
    (prev.proton-ge-bin.override {
      steamDisplayName = "GE-Proton9-27";
    }).overrideAttrs
      (_finalAttrs: {
        version = "GE-Proton9-27";
        src = prev.fetchzip {
          url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton9-27/GE-Proton9-27.tar.gz";
          hash = "sha256-70au1dx9co3X+X7xkBCDGf1BxEouuw3zN+7eDyT7i5c=";
        };
      });
}
