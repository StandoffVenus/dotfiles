{ stdenv, fetchurl, undmg }:

let
  release = "https://download.mozilla.org/?product=firefox-latest&os=osx&lang=en-US";
  hash = "1w35ph0kmv7mvm2cg693h56cfpc89gba226acjcblbr94ji7m03y";
in stdenv.mkDerivation rec {
  pname = "Firefox";
  version = "latest";

  buildInputs = [ undmg ];
  sourceRoot = ".";
  phases = [ "unpackPhase" "installPhase" ];

  src = fetchurl {
    name = "Firefox.dmg";
    url = "${release}";
    sha256 = hash;
  };

  installPhase = ''
    mkdir -p "$out/Applications"
    cp -r Firefox.app "$out/Applications"
  '';

  meta = with stdenv.lib; {
    description = "Mozilla Firefox";
    homepage = "https://www.mozilla.org/en-US/firefox";
    maintainers = [ maintainers.mule ];
  };
}
