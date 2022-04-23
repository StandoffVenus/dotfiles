{ stdenv, fetchurl, undmg, ... }:

with stdenv;
let
  arch = if (isAarch32 || isAarch64) then
      "arm"
    else
      "amd";
  bits = if is32bit then "32" else "64";

  file = "Docker.dmg";
  appVersion = "1.0.0";
  release = "https://desktop.docker.com/mac/main/${arch}${bits}/${file}";
in mkDerivation rec {
  pname = "Docker";
  version = "${appVersion}";

  buildInputs = [ undmg ];
  sourceRoot = ".";
  phases = [ "unpackPhase" "installPhase" ];

  src = fetchurl {
    name = "docker.dmg";
    url = "${release}";
    sha256 = "0gz7k126rjlhsl1kfnrmdnik6kjdq84zx33np60hmh9h5imflnnf";
  };

  installPhase = ''
    mkdir -p "$out/Applications"
    cp -r Docker.app "$out/Applications"
  '';

  meta = with lib; {
    description = "Docker";
    homepage = "https://www.docker.com";
    maintainers = [ maintainers.mule ];
  };
}
