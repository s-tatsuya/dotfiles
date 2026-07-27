{ ... }:
{
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
  };

  # Touch ID で sudo を解除（要再起動で有効化）
  security.pam.services.sudo_local.touchIdAuth = true;
}
