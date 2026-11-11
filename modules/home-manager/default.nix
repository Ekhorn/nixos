{
  # The following modules MUST be specific, and NOT general like "security" or
  # "services", only "common" is allowed.
  alacritty = import ./alacritty.nix;
  btop = import ./btop.nix;
  common = import ./common.nix;
  editorconfig = import ./editorconfig.nix;
  dconf = import ./dconf.nix;
  gh = import ./gh.nix;
  git = import ./git.nix;
  gnome = import ./gnome.nix;
  gtk = import ./gtk.nix;
  helix = import ./helix.nix;
  # hypridle = import ./hypridle.nix;
  # hyprland = import ./hyprland.nix;
  # hyprlock = import ./hyprlock.nix;
  # hyprpaper = import ./hyprpaper.nix;
  java = import ./java.nix;
  keepassxc = import ./keepassxc.nix;
  # latex = import ./latex.nix;
  # rofi = import ./rofi.nix;
  tmux = import ./tmux.nix;
  # waybar = import ./waybar.nix;
  zed = import ./zed;
  zsh = import ./zsh.nix;
}
