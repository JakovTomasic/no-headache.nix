{ pkgs, system, absPath } :
let
  mainScript = pkgs.writeShellScriptBin "nohead" ''
    export SYSTEM_NAME="${system}"
    export NIX_STORE_ABS_PATH="${absPath}"
    "${absPath}/devshells/main/scripts/main.sh" $@
  '';

  # These packages are included in most Unix environments so installing new version of them might be an overhead.
  requirements = with pkgs; [
    procps   # for ps, kill, top, uptime, etc.
    gnugrep  # GNU grep
    gawk     # GNU awk
    bash
  ];
in
  pkgs.mkShell {
    packages = requirements ++ [ mainScript ];

    shellHook = ''
      echo "Dev shell loaded."
    '';
  }
