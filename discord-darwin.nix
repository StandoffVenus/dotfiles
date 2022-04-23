{ stdenv, fetchurl, undmg }:

let
  version = "1.0.0";
  release = "https://discord.com/api/download?platform=osx";
in stdenv.mkDerivation rec {
  pname = "Discord";
  inherit version;

  buildInputs = [ undmg ];
  sourceRoot = ".";
  phases = [ "unpackPhase" "installPhase" ];

  src = fetchurl {
    name = "discord-${version}.dmg";
    url = "${release}";
    sha256 = "1i19qlaiflr1hj2qsywl9pxqi2gqh1l4iy7hgbqxhrkaml9ljc6a";
  };

  installPhase = ''
    mkdir -p "$out/Applications"
    cp -r Discord.app "$out/Applications"
  '';

  meta = with stdenv.lib; {
    description = "Discord";
    homepage = "https://discord.com";
    maintainers = [ maintainers.mule ];
  };
}
