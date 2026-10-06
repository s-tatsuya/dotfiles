{ ... }:
{
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;

    # 日本語 - ローマ字入力で ¥ キーを \ にする（0 = ¥, 1 = \）
    CustomUserPreferences."com.apple.inputmethod.Kotoeri" = {
      JIMPrefCharacterForYenKey = 1;
    };
  };

  # Touch ID で sudo を解除（要再起動で有効化）
  security.pam.services.sudo_local.touchIdAuth = true;
}
