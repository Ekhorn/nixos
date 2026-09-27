{ pkgs, ... }:

{
  programs.gnome-shell = {
    enable = true;
    extensions = with pkgs.gnomeExtensions; [
      { package = auto-move-windows; }
      { package = pip-on-top; }
      # { package = places-menu; }
      { package = status-icons; }
      { package = system-monitor; }
      # { package = tiling-shell; }
    ];
  };
}
