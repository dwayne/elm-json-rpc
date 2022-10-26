{
  pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/451c1a3e32ac73288d0f6fa48d53c9f2c1c5a3d8.tar.gz") {}
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.elmPackages.elm
    pkgs.elmPackages.elm-format
    pkgs.elmPackages.elm-test
  ];

  shellHook = ''
    export project="$PWD"
    export PATH="$project/bin:$PATH"
  '';
}
