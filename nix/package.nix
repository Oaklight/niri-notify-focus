{
  lib,
  stdenvNoCC,
  python3,
  makeWrapper,
  niri,
}:

let
  pythonEnv = python3.withPackages (ps: with ps; [
    dbus-python
    pygobject3
  ]);
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "niri-notify-focus";
  version = "0.2.0";

  src = ../.;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 niri-notify-focus $out/bin/niri-notify-focus
    install -Dm644 niri-notify-focus.service \
      $out/lib/systemd/user/niri-notify-focus.service
    install -Dm644 LICENSE \
      $out/share/licenses/niri-notify-focus/LICENSE
    install -Dm644 config.toml.example \
      $out/share/doc/niri-notify-focus/config.toml.example
    runHook postInstall
  '';

  postFixup = ''
    substituteInPlace $out/bin/niri-notify-focus \
      --replace-fail "/usr/bin/env python3" "${pythonEnv}/bin/python3"
    wrapProgram $out/bin/niri-notify-focus \
      --prefix PATH : ${lib.makeBinPath [ niri ]}
    substituteInPlace $out/lib/systemd/user/niri-notify-focus.service \
      --replace-fail "/usr/bin/niri-notify-focus" "$out/bin/niri-notify-focus"
  '';

  meta = {
    description = "Focus source window on notification click for the niri Wayland compositor";
    homepage = "https://github.com/Oaklight/niri-notify-focus";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "niri-notify-focus";
  };
})
