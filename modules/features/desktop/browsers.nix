# Brave and Chrome with the same extensions, and the native messaging host
# the Gopass Bridge extension talks to.
{
  homeManager.gui =
    { pkgs, ... }:
    let
      # Browsers invoke this with the extension origin as argv[1], which
      # gopass-jsonapi's own "listen" subcommand ignores, so a thin wrapper is
      # enough.
      gopassJsonapiWrapper = pkgs.writeShellScript "gopass-jsonapi-wrapper" ''
        exec ${pkgs.gopass-jsonapi}/bin/gopass-jsonapi listen
      '';
      webExtensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
        { id = "kkhfnlkhiapbiehimabddjbimfaijdhk"; } # Gopass Bridge
        { id = "hfjbmagddngcpeloejdejnfgbamkjaeg"; } # vimium
      ];
    in
    {
      home.packages = [ pkgs.gopass-jsonapi ];
      programs.google-chrome.enable = true;
      programs.brave = {
        enable = true;
        extensions = webExtensions;
      };
      xdg.configFile."BraveSoftware/Brave-Browser/NativeMessagingHosts/com.justwatch.gopass.json".text =
        builtins.toJSON
          {
            name = "com.justwatch.gopass";
            description = "Gopass wrapper to search and return passwords";
            path = "${gopassJsonapiWrapper}";
            type = "stdio";
            allowed_origins = [ "chrome-extension://kkhfnlkhiapbiehimabddjbimfaijdhk/" ];
          };
    };
}
