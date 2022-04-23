{ stdenv, fetchurl, undmg }:

let
  appVersion = "0.53";
  release = "https://github.com/rxhanson/Rectangle/releases/download/v${appVersion}/Rectangle${appVersion}.dmg";
in stdenv.mkDerivation rec {
  pname = "Rectangle";
  version = "${appVersion}";

  buildInputs = [ undmg ];
  sourceRoot = ".";
  phases = [ "unpackPhase" "installPhase" ];
  installPhase = ''
    mkdir -p "$out/Applications"
    cp -r Rectangle.app "$out/Applications/${pname}.app"
  '';

  src = fetchurl {
    name = "rectangle-${appVersion}.dmg";
    url = "${release}";
  };

  meta = with stdenv.lib; {
    description = "Rectangle";
    homepage = "https://rectangleapp.com";
    maintainers = [ maintainers.mule ];
  };
}
