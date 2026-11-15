0=${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}
0=${${(M)0:#/*}:-$PWD/$0}

((${fpath[(Ie)${0:h}/functions]})) || fpath=("${0:h}/functions" $fpath)
autoload -Uz clipcopy clippaste clipcat clipclear _clipboard_detect_backend

if zstyle -T ':clipboard:' aliases; then
  if ((${+functions[zalias]})); then
    zalias -e -b -d 'Copy the current directory path to the clipboard' cpwd='pwd | clipcopy'
    zalias -g -e -b -d 'Paste from the clipboard' clipp='clippaste'
    zalias -g -e -b -d 'Copy input to the clipboard' clipc='clipcopy'
  else
    alias cpwd='pwd | clipcopy'
    alias -g clipp='clippaste' clipc='clipcopy'
  fi
fi

if [[ -o zle ]] && zstyle -T ':clipboard:' vi-mode; then
  source "${0:h}/clipboard-zle.zsh"
fi
