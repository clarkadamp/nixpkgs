{
  lib,
  stdenv,
  fetchzip,
  pkg-config,
  fontconfig,
  freetype,
  libX11,
  libXft,
  ncurses,
  writeText,
  config,
  conf ? config.st.conf or null,
  patches ? config.st.patches or [ ],
  extraLibs ? config.st.extraLibs or [ ],
  nixosTests,
  # update script dependencies
  gitUpdater,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "st";
  version = "0.9.2";

  src = fetchzip {
    url = "https://dl.suckless.org/st/st-${finalAttrs.version}.tar.gz";
    hash = "sha256-pFyK4XvV5Z4gBja8J996zF6wkdgQCNVccqUJ5+ejB/w=";
  };

  outputs = [
    "out"
    "terminfo"
  ];

  inherit patches;

  configFile = lib.optionalString (conf != null) (writeText "config.def.h" conf);

  postPatch =
    lib.optionalString (conf != null) "cp ${finalAttrs.configFile} config.def.h"
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      substituteInPlace config.mk --replace "-lrt" ""
    '';

  strictDeps = true;

  makeFlags = [
    "PKG_CONFIG=${stdenv.cc.targetPrefix}pkg-config"
  ];

  nativeBuildInputs = [
    pkg-config
    ncurses
    fontconfig
    freetype
  ];
  buildInputs = [
    libX11
    libXft
  ] ++ extraLibs;

  preInstall = ''
    export TERMINFO=$terminfo/share/terminfo
    mkdir -p $TERMINFO $out/nix-support
    echo "$terminfo" >> $out/nix-support/propagated-user-env-packages
  '';

  installFlags = [ "PREFIX=$(out)" ];

  passthru = {
    tests.test = nixosTests.terminal-emulators.st;
    updateScript = gitUpdater {
      url = "git://git.suckless.org/st";
    };
  };

  meta = {
    homepage = "https://st.suckless.org/";
    description = "Simple Terminal for X from Suckless.org Community";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ qusic ];
    platforms = lib.platforms.unix;
    mainProgram = "st";
  };
})
