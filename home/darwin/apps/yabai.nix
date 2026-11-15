{ pkgs, ... }: {
  home.file.".yabairc" = {
    text = ''
      yabai -m config layout bsp

      # Set all padding and gaps to 20pt (default: 0)
      yabai -m config top_padding    10
      yabai -m config bottom_padding 10
      yabai -m config left_padding   10
      yabai -m config right_padding  10
      yabai -m config window_gap     10

      yabai -m config auto_balance on

      # set focus follows mouse mode (default: off, options: off, autoraise, autofocus)
      yabai -m config focus_follows_mouse autoraise
    '';
  };
}



