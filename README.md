# clipboard.zsh

Clipboard commands for zsh that work locally and over SSH.

- `clipcopy` copies standard input; `clippaste` writes the clipboard to standard output
- Backends: `pbcopy`/`pbpaste` (macOS), `wl-copy`/`wl-paste` (Wayland), `xclip` (X11)
- Over SSH, or with no backend, `clipcopy` uses OSC 52 so the terminal sets the clipboard
- `clipcat FILE` copies a file; `clipclear [SECONDS]` clears the clipboard after a delay (default 45) unless it changed
- Optional vi-mode integration: yanks (`y`, `yy`, `Y`) go to the clipboard and `p`/`P` read it. Deletes and changes stay in the editor, so removed text never reaches the clipboard.

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
CLIPBOARD_YANK_HIGHLIGHT='bg=blue,fg=0,bold'  # yank flash colour
CLIPBOARD_YANK_FLASH_MS=150                   # yank flash duration
```

The aliases are `cpwd` (copy the current directory), and the global aliases `clipp` (paste) and `clipc` (copy). Global aliases expand anywhere on the command line, so turn them off if that gets in the way. When [zalias](https://github.com/devastion/zalias) is loaded first, they are defined through it.

## License

MIT
