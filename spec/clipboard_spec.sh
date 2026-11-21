# shellcheck shell=sh

Describe 'clipboard'
  BeforeEach 'load_plugin' 'make_bin'

  Describe '_clipboard_detect_backend'
    It 'fails when no tools are present'
      When call isolated _clipboard_detect_backend copy
      The status should be failure
    End

    It 'does not accept pbpaste alone for copy'
      stub pbpaste 'echo hi'
      When call isolated _clipboard_detect_backend copy
      The status should be failure
    End

    It 'accepts pbpaste for paste'
      stub pbpaste 'echo hi'
      detect() { _clipboard_detect_backend paste && echo "${REPLY}"; }
      When call isolated detect
      The output should eq macos
    End

    It 'has no local backend over ssh'
      stub_clipboard
      ssh_detect() { SSH_CONNECTION=x _clipboard_detect_backend copy; }
      When call isolated ssh_detect
      The status should be failure
    End

    It 'falls back to xsel when X11 has no xclip'
      stub xsel 'cat'
      detect() { DISPLAY=:0 _clipboard_detect_backend copy && echo "${REPLY}"; }
      When call isolated detect
      The output should eq xsel
    End

    It 'detects termux'
      stub termux-clipboard-set 'cat'
      detect() { _clipboard_detect_backend copy && echo "${REPLY}"; }
      When call isolated detect
      The output should eq termux
    End

    It 'detects WSL only inside WSL'
      stub clip.exe 'cat'
      detect() { WSL_DISTRO_NAME=Ubuntu _clipboard_detect_backend copy && echo "${REPLY}"; }
      When call isolated detect
      The output should eq wsl
    End

    It 'does not use clip.exe outside WSL'
      stub clip.exe 'cat'
      When call isolated _clipboard_detect_backend copy
      The status should be failure
    End

    It 'honours a forced backend, even over ssh'
      stub_clipboard
      detect() {
        zstyle ':clipboard:' backend macos
        SSH_CONNECTION=x _clipboard_detect_backend copy && echo "${REPLY}"
      }
      When call isolated detect
      The output should eq macos
    End

    It 'rejects an unknown forced backend in clipcopy and clippaste'
      stub_clipboard
      bad() {
        zstyle ':clipboard:' backend wayand
        clipcopy < /dev/null 2>&1
        print -r -- "copy=$?"
        clippaste 2>&1
        print -r -- "paste=$?"
      }
      When call isolated bad
      The output should include 'clipcopy: unknown clipboard backend'
      The output should include 'copy=2'
      The output should include 'clippaste: unknown clipboard backend'
      The output should include 'paste=2'
    End

    It 'skips local tools when osc52 is forced'
      stub_clipboard
      detect() { zstyle ':clipboard:' backend osc52; _clipboard_detect_backend copy; }
      When call isolated detect
      The status should be failure
    End

    It 'rejects an unknown operation'
      When call _clipboard_detect_backend bogus
      The status should eq 2
    End
  End

  Describe 'clipcopy and clippaste'
    It 'round-trips data'
      stub_clipboard
      roundtrip() { print -rn -- hello | clipcopy && clippaste; }
      When call isolated roundtrip
      The output should eq hello
    End
  End

  Describe 'clipcat'
    It 'prints usage without arguments'
      When call isolated clipcat
      The status should eq 2
      The stderr should be present
    End

    It 'concatenates several files'
      stub_clipboard
      copy_files() {
        print -rn -- one > "${SHELLSPEC_TMPBASE}/a"
        print -rn -- two > "${SHELLSPEC_TMPBASE}/b"
        clipcat "${SHELLSPEC_TMPBASE}/a" "${SHELLSPEC_TMPBASE}/b" && clippaste
      }
      When call isolated copy_files
      The output should eq onetwo
    End

    It 'rejects a non-file'
      stub_clipboard
      When call isolated clipcat "${SHELLSPEC_TMPBASE}/nope"
      The status should be failure
      The stderr should be present
    End

    It 'copies a file'
      stub_clipboard
      copy_file() {
        print -rn -- filedata > "${SHELLSPEC_TMPBASE}/f"
        clipcat "${SHELLSPEC_TMPBASE}/f" && clippaste
      }
      When call isolated copy_file
      The output should eq filedata
    End
  End

  Describe 'clipclear'
    It 'rejects a bad delay'
      stub_clipboard
      When call isolated clipclear abc
      The status should eq 2
      The stderr should be present
    End

    It 'passes the delay to sleep'
      stub_clipboard
      stub_sleep
      delay() {
        clipclear 7
        while [ ! -s "${SLEEP_LOG}" ]; do "${REAL_SLEEP}" 0.02; done
        cat "${SLEEP_LOG}"
        : > "${SLEEP_GO}"
      }
      When call isolated delay
      The output should eq 7
    End

    It 'clears the clipboard after the delay'
      stub_clipboard
      stub_sleep
      run() {
        print -rn -- x | clipcopy
        clipclear 1
        release_sleep ''
        clippaste
      }
      When call isolated run
      The output should eq ''
    End

    It 'clears unconditionally when the clipboard cannot be read'
      stub wl-copy "cat > ${CLIP_FILE}"
      stub_sleep
      run() {
        export WAYLAND_DISPLAY=wayland-0
        print -rn -- secret > "${CLIP_FILE}"
        clipclear 1
        : > "${SLEEP_GO}"
        "${REAL_SLEEP}" 0.3
        cat "${CLIP_FILE}"
      }
      When call isolated run
      The output should eq ''
    End

    It 'skips clearing if the clipboard changed'
      stub_clipboard
      stub_sleep
      run() {
        print -rn -- keep | clipcopy
        clipclear 1
        print -rn -- changed | clipcopy
        : > "${SLEEP_GO}"
        "${REAL_SLEEP}" 0.3
        clippaste
      }
      When call isolated run
      The output should eq changed
    End
  End
End
