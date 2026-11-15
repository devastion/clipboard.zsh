
_clipboard_flash_yank() {
  emulate -L zsh

  local -a saved_highlight=("$region_highlight[@]")
  local -i start="${CURSOR}" end

  if [[ "${WIDGET}" == *whole-line* || "${CUTBUFFER}" == *$'\n' ]]; then
    start=$((${#LBUFFER} - ${#${LBUFFER##*$'\n'}}))
  fi

  end=$((start + ${#CUTBUFFER}))

  ((end > ${#BUFFER})) &&
    end="${#BUFFER}"

  ((end > start)) ||
    return 0

  region_highlight+=(
    "${start} ${end} ${CLIPBOARD_YANK_HIGHLIGHT:-"bg=blue,fg=0,bold"}"
  )

  zle -R

  zmodload zsh/zselect
  zselect -t $((${CLIPBOARD_YANK_FLASH_MS:-150} / 10))

  region_highlight=("$saved_highlight[@]")
  zle -R
}

typeset -g _clipboard_last_synced=''
typeset -gi _clipboard_cut_is_newer=0

clipboard-vi-yank() {
  emulate -L zsh

  zle ".${WIDGET}" || return

  print -rn -- "${CUTBUFFER}" | clipcopy 2> /dev/null
  _clipboard_last_synced="${CUTBUFFER}"
  _clipboard_cut_is_newer=0

  _clipboard_flash_yank

  return 0
}

clipboard-vi-cut() {
  emulate -L zsh

  local buffer_before="${BUFFER}"

  zle ".${WIDGET}" || return
  [[ "${BUFFER}" == "${buffer_before}" ]] || _clipboard_cut_is_newer=1
  return 0
}

clipboard-vi-put() {
  emulate -L zsh

  local widget="${WIDGET}"
  local content

  content="$(
    clippaste 2> /dev/null
    print -rn x
  )"

  content="${content%x}"

  if ((_clipboard_cut_is_newer)); then
    _clipboard_cut_is_newer=0
    _clipboard_last_synced="${content}"
  elif [[ -n "${content}" && "${content}" != "${_clipboard_last_synced}" ]]; then
    CUTBUFFER="${content}"
    _clipboard_last_synced="${content}"
  fi

  zle ".${widget}"
}

() {
  local widget

  for widget in \
    vi-yank \
    vi-yank-eol \
    vi-yank-whole-line; do
    zle -N "${widget}" clipboard-vi-yank
  done

  for widget in \
    vi-change \
    vi-change-eol \
    vi-change-whole-line \
    vi-delete \
    vi-substitute \
    vi-kill-eol \
    vi-kill-line; do
    zle -N "${widget}" clipboard-vi-cut
  done

  for widget in \
    vi-put-after \
    vi-put-before; do
    zle -N "${widget}" clipboard-vi-put
  done
}

bindkey -M viopp -- 'y' vi-yank-whole-line
