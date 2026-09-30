{
  homeManager.base = { pkgs, ... }: {
    home.packages = with pkgs; [ bc ];
  };
  homeManager.gui = { pkgs, ... }: {
    home.packages = with pkgs; [ qalculate-gtk ];
  };
}
