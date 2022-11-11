{
  pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/df2bcbbd1c2aa144261cf1b0003c889c075dc693.tar.gz") {}
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.elmPackages.elm
    pkgs.elmPackages.elm-doc-preview
    pkgs.elmPackages.elm-format
    pkgs.elmPackages.elm-test
    pkgs.nodejs-18_x
  ];

  shellHook = ''
    export project="$PWD"
    export PATH="$project/bin:$PATH"

    npm install --loglevel error > /dev/null
  '';
}
