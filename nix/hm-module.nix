self:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.niri-notify-focus;
  tomlFormat = pkgs.formats.toml { };
  configFile = tomlFormat.generate "niri-notify-focus-config.toml" cfg.settings;
in
{
  options.services.niri-notify-focus = {
    enable = lib.mkEnableOption "niri-notify-focus, a daemon that focuses the source window when a notification is clicked under niri";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.niri-notify-focus;
      defaultText = lib.literalExpression "niri-notify-focus.packages.\${system}.niri-notify-focus";
      description = "The niri-notify-focus package to use.";
    };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          effect = "shrink";
          pulse_pixels = 50;
        }
      '';
      description = ''
        Settings written to `$XDG_CONFIG_HOME/niri-notify-focus/config.toml`.
        See <https://github.com/Oaklight/niri-notify-focus/blob/master/config.toml.example>
        for available keys.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."niri-notify-focus/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = configFile;
    };

    systemd.user.services.niri-notify-focus = {
      Unit = {
        Description = "Focus source window on notification click (niri)";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        # niri-notify-focus reads config once at startup. Embed the config
        # store path so the unit definition changes (and home-manager
        # restarts the unit) whenever settings change.
        X-Restart-Triggers = [ "${configFile}" ];
      };
      Service = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
