# clsw: Claude Code account switcher

Switch between several Claude Code logins (personal, work, team, ...) without losing history.
`~/.claude` stays untouched, so `/resume` still sees all your sessions after a switch.

Only two things are swapped:

- the OAuth token (macOS Keychain, or `~/.claude/.credentials.json` on Linux/Windows)
- the `oauthAccount` block in `~/.claude.json`

Profiles live in `~/.claude-switcher/`.

## Install

### macOS / Linux

Requirements: `bash`, plus `jq` or `python3` (macOS ships python3 with the Xcode CLT).

```bash
mkdir -p ~/.local/bin
cp ccswitch.sh ~/.local/bin/clsw
chmod +x ~/.local/bin/clsw
```

Make sure `~/.local/bin` is on your `PATH`. If `clsw` is "command not found", add this to `~/.zshrc` or `~/.bashrc` and open a new terminal:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Windows (PowerShell)

```powershell
New-Item -ItemType Directory -Force "$HOME\bin" | Out-Null
Copy-Item ccswitch.ps1 "$HOME\bin\ccswitch.ps1"

# allow local scripts (once per user)
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

# add the clsw command to your PowerShell profile
if (!(Test-Path $PROFILE)) { New-Item -ItemType File -Force $PROFILE | Out-Null }
Add-Content $PROFILE 'function clsw { & "$HOME\bin\ccswitch.ps1" @args }'
```

Open a new PowerShell window, then `clsw list` should work.

Optional, for `cmd.exe`: create `%USERPROFILE%\bin\clsw.cmd` and put `%USERPROFILE%\bin` on `PATH`:

```bat
@powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\bin\ccswitch.ps1" %*
```

## Usage

```text
clsw save <name>   save the current Claude Code login as profile <name>
clsw use <name>    switch to profile <name>
clsw list          list profiles (* = active)
```

macOS/Linux shortcuts: `clsw` alone runs `list`, and `clsw <name>` runs `use <name>`.

### First-time setup

1. Run `claude` and `/login` with account A. Quit claude.
2. `clsw save personal`
3. Run `claude`, then `/login` with account B. Quit claude.
4. `clsw save work`

### Daily use

```bash
clsw list
#   personal  me@gmail.com
# * work      me@company.com

clsw use personal    # or just: clsw personal
```

After switching, **restart claude**. Already-open sessions keep the old account. Then use `/resume` to continue any previous session with the new account.

On switch, the token of the account you leave is re-saved first. Claude refreshes tokens over time, so profiles stay valid.

## Notes

- **macOS**: tokens are stored in the Keychain (`Claude Code-credentials` for the live login, `ccswitch-<name>` per profile). The first switch may show a Keychain access prompt; choose "Always Allow". Set `CCSWITCH_FILE_MODE=1` to use plain files like on Linux.
- **Linux / Windows**: profile tokens are plain files in `~/.claude-switcher/`. On Linux the folder is `chmod 700`. On Windows, keep that folder private.
- `CLAUDE_CONFIG_DIR` is respected if you use a custom config directory.
- Profile names: letters, digits, `.`, `_`, `-`.

## Uninstall

```bash
rm ~/.local/bin/clsw
rm -rf ~/.claude-switcher
# macOS: also remove saved profiles from Keychain
security delete-generic-password -s ccswitch-<name>
```

Windows: delete `$HOME\bin\ccswitch.ps1`, the `clsw` line in `$PROFILE`, and `$HOME\.claude-switcher`.
