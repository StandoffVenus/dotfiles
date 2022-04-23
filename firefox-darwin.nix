{ stdenv, fetchurl, undmg }:

let
  appVersion = "99.0.1";
  file = "Firefox%20${appVersion}.dmg";
  release = "https://ftp.mozilla.org/pub/firefox/releases/99.0.1/mac/en-US/${file}";
in stdenv.mkDerivation rec {
  pname = "Firefox";
  version = "${appVersion}";

  buildInputs = [ undmg ];
  sourceRoot = ".";
  phases = [ "unpackPhase" "installPhase" ];

  src = fetchurl {
    name = "firefox-${version}.dmg";
    url = "${release}";
    sha256 = "be6d89efe9af77a9fb2989d9918f70c1721a8193d208e8e8593e4e50c16813af";
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
