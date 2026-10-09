# Brave and Chrome with the same extensions, and the native messaging host
# the Gopass Bridge extension talks to.
{
  homeManager.gui =
    { pkgs, ... }:
    let
      webExtensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
        { id = "kkhfnlkhiapbiehimabddjbimfaijdhk"; } # Gopass Bridge
        { id = "hfjbmagddngcpeloejdejnfgbamkjaeg"; } # vimium
      ];
      # gopass-jsonapi ships the manifests (and its wrapper script) itself
      nativeMessagingHosts = [ pkgs.gopass-jsonapi ];
    in
    {
      programs.google-chrome = {
        enable = true;
        inherit nativeMessagingHosts;
      };
      programs.brave = {
        enable = true;
        extensions = webExtensions;
        inherit nativeMessagingHosts;
      };
    };
}
