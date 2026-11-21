# clipboard.zsh

Clipboard commands for zsh that work locally and over SSH.

- `clipcopy` copies standard input; `clippaste` writes the clipboard to standard output
- Backends: `pbcopy`/`pbpaste` (macOS), `wl-copy`/`wl-paste` (Wayland), `xclip` or `xsel` (X11), `termux-clipboard-*` (Termux), `clip.exe`/`powershell.exe` (WSL)
- Over SSH, or with no backend, `clipcopy` uses OSC 52 so the terminal sets the clipboard. Inside tmux it wraps the sequence in a passthrough. OSC 52 cannot read the clipboard, so `clippaste` fails there.
- `clipcat FILE...` copies files (`-` is standard input); `clipclear [SECONDS]` clears the clipboard after a delay (default 45) unless it changed. Where the clipboard can't be read (OSC 52), it clears without checking.
- Optional vi-mode integration: yanks (`y`, `yy`, `Y`) go to the clipboard and `p`/`P` read it. Deletes and changes (including `x`) stay in the editor, so removed text never reaches the clipboard.

## Install

Source `clipboard.plugin.zsh`, or point your plugin manager at this repository:

```sh
git clone https://github.com/devastion/clipboard.zsh.git ~/.zsh/clipboard.zsh
echo 'source ~/.zsh/clipboard.zsh/clipboard.plugin.zsh' >> ~/.zshrc
```

## Configuration

Set these before sourcing the plugin.

```zsh
zstyle ':clipboard:' aliases no   # skip the cpwd, clipp and clipc aliases
zstyle ':clipboard:' vi-mode no   # skip the vi-mode yank and put widgets
zstyle ':clipboard:' backend xsel # force a backend: macos wayland x11 xsel termux wsl osc52
CLIPBOARD_YANK_HIGHLIGHT='bg=blue,fg=0,bold'  # yank flash colour
CLIPBOARD_YANK_FLASH_MS=150                   # yank flash duration
```

The aliases are `cpwd` (copy the current directory, no trailing newline), and the global aliases `clipp` (paste) and `clipc` (copy). Global aliases expand anywhere on the command line, so turn them off if that gets in the way. When [zalias](https://github.com/devastion/zalias) is loaded first, they are defined through it.

## Testing

Tests use [ShellSpec](https://github.com/shellspec/shellspec) and run under zsh:

```sh
shellspec
```

## License

MIT
