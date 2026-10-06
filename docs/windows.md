# Windows

The dotfiles run inside WSL2, through the Linux path of the README's [Setup](../README.md#setup).
Native Windows is not supported: the shell and tmux config, the statusline and every Claude Code
hook are zsh or bash.

1. In an administrator PowerShell, `wsl --install` installs WSL2 with Ubuntu. Reboot and create
   the Linux user.
2. In the Ubuntu shell, follow [Setup](../README.md#setup) as Linux. Skip the macOS-only packages
   and step 9.
3. Install Claude Code inside WSL with the Linux installer, not on Windows. Its hooks and the
   statusline then run under WSL's bash, as they do on macOS.
4. Terminal: Windows Terminal with its Ubuntu profile. Install JetBrains Mono Nerd Font on the
   Windows side and set it as that profile's font. Ghostty has no Windows build.
