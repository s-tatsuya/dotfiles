{ ... }:
{
  # GitHub への認証は SSH 鍵ではなく gh（＝HTTPS + OAuth トークン）に一本化する。
  # 理由は README の「GitHub 認証方式」を参照。
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
