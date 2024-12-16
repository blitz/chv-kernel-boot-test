{ stdenv, meson, ninja }:
stdenv.mkDerivation {
  name = "init";

  src = ./init;

  nativeBuildInputs = [ meson ninja ];

  meta = {
    mainProgram = "init";
  };
}
