# shellcheck shell=sh
# Loaded by ShellSpec (running under zsh). Plugin code is zsh-only, so it is
# sourced from inside a function that switches to zsh emulation.

load_plugin() {
  emulate -L zsh
  fpath=("${SHELLSPEC_PROJECT_ROOT}/functions" $fpath)
  autoload -Uz clipcopy clippaste clipcat clipclear _clipboard_detect_backend
}

# Build a PATH holding only the listed real tools, in $TOOLS_DIR.
make_bin() {
  REAL_SLEEP="$(command -v sleep)"
  TOOLS_DIR="${SHELLSPEC_TMPBASE}/bin"
  rm -rf "${TOOLS_DIR}"
  mkdir -p "${TOOLS_DIR}"
  for tool in cat cksum base64 chmod rm; do
    ln -sf "$(command -v "${tool}")" "${TOOLS_DIR}/${tool}"
  done
  unset SSH_CONNECTION SSH_TTY SSH_CLIENT WAYLAND_DISPLAY DISPLAY
  CLIP_FILE="${SHELLSPEC_TMPBASE}/clip"
}

# stub NAME BODY: create an executable shell stub in $TOOLS_DIR.
stub() {
  printf '#!/bin/sh\n%s\n' "$2" > "${TOOLS_DIR}/$1"
  chmod +x "${TOOLS_DIR}/$1"
}

stub_clipboard() {
  stub pbcopy "cat > ${CLIP_FILE}"
  stub pbpaste "cat ${CLIP_FILE}"
}

# Run a command with the restricted PATH.
isolated() {
  PATH="${TOOLS_DIR}"
  rehash
  "$@"
}

spec_helper_precheck() {
  load_plugin
}

# Replace `sleep` with a stub that records its argument in $SLEEP_LOG and
# blocks until $SLEEP_GO exists, so specs control when the delay "ends".
stub_sleep() {
  SLEEP_LOG="${SHELLSPEC_TMPBASE}/sleep.log"
  SLEEP_GO="${SHELLSPEC_TMPBASE}/sleep.go"
  rm -f "${SLEEP_LOG}" "${SLEEP_GO}"
  stub sleep "echo \"\$1\" > ${SLEEP_LOG}
while [ ! -e ${SLEEP_GO} ]; do ${REAL_SLEEP} 0.02; done"
}

# Release the stubbed sleep, then wait until the clipboard holds $1 (max ~2s).
release_sleep() {
  : > "${SLEEP_GO}"
  i=0
  while [ "$(clippaste)" != "$1" ] && [ "${i}" -lt 100 ]; do
    "${REAL_SLEEP}" 0.02
    i=$((i + 1))
  done
}
