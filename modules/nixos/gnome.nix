{ pkgs, ... }:

{
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  services.gnome.gnome-software.enable = false;

  environment.gnome.excludePackages = with pkgs; [
    # epiphany # web browser
    # gnome-characters
    gnome-console
    gnome-contacts
    gnome-connections
    gnome-maps
    gnome-music
    gnome-logs
    gnome-terminal
    gnome-tour
    papers # document viewer
    yelp # help
  ];
}
