{ stdenv, fetchurl, undmg }:

let
  appVersion = "100.0.0";
  release = "https://download.mozilla.org/?product=firefox-latest&os=osx&lang=en-US";
  hash = "0414dsw0pgyik6lfd151al5nsrsh7dvp3bkqygxxn4cpj2b3pyi5";
in stdenv.mkDerivation rec {
  pname = "Firefox";
  version = "${appVersion}";

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
