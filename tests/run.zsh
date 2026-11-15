#!/usr/bin/env zsh
emulate zsh
setopt no_unset
root="${0:A:h:h}"
fails=0
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
fpath=("${root}/functions" $fpath)
autoload -Uz clipcopy clippaste clipcat clipclear _clipboard_detect_backend

check() {
  if [[ "$2" == "$3" ]]; then
    print -r -- "ok   $1"
  else
    print -r -- "FAIL $1: expected '$2' got '$3'"
    ((fails++))
  fi
}

stub() {
  print -r -- "#!/bin/sh
$2" > "${tmp}/bin/$1"
  chmod +x "${tmp}/bin/$1"
}

mkdir "${tmp}/bin"
for tool in cat cksum sleep base64 chmod rm; do
  ln -s "$(command -v ${tool})" "${tmp}/bin/${tool}"
done
PATH="${tmp}/bin"
unset SSH_CONNECTION SSH_TTY SSH_CLIENT WAYLAND_DISPLAY DISPLAY
REPLY=''
rehash

_clipboard_detect_backend copy && r=yes || r=no
check "no tools fails" no "${r}"

stub pbpaste 'echo hi'
rehash
_clipboard_detect_backend copy && r=yes || r=no
check "pbpaste alone does not satisfy copy" no "${r}"
_clipboard_detect_backend paste && r=yes || r=no
check "pbpaste satisfies paste" "yes:macos" "${r}:${REPLY}"

stub pbcopy "cat > ${tmp}/clip"
stub pbpaste "cat ${tmp}/clip"
rehash
print -rn -- hello | clipcopy
check "clipcopy and clippaste roundtrip" hello "$(clippaste)"

(
  SSH_CONNECTION=x
  _clipboard_detect_backend copy
) && r=yes || r=no
check "ssh has no local backend" no "${r}"

clipcat "${tmp}/nope" 2> /dev/null && r=yes || r=no
check "clipcat rejects non-file" no "${r}"
print -rn -- filedata > "${tmp}/f"
clipcat "${tmp}/f"
check "clipcat copies file" filedata "$(clippaste)"

clipclear abc 2> /dev/null
check "clipclear rejects bad delay" 2 "$?"
clipclear 1
sleep 2
check "clipclear clears" "" "$(clippaste)"
print -rn -- keep | clipcopy
clipclear 1
print -rn -- changed | clipcopy
sleep 2
check "clipclear skips if changed" changed "$(clippaste)"

exit $((fails > 0))
