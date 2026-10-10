#!/usr/bin/env bash
# ccswitch.sh (macOS/Linux): swap Claude Code login, keep ~/.claude so /resume works.
# usage: ./ccswitch.sh save <name> | use <name> | list
set -euo pipefail
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"; CRED="$CFG/.credentials.json"
CJ="$HOME/.claude.json"; [ -n "${CLAUDE_CONFIG_DIR:-}" ] && CJ="$CFG/.claude.json"
D="$HOME/.claude-switcher"; mkdir -p "$D"; chmod 700 "$D"; umask 077
KC="Claude Code-credentials"; ME="$(id -un)"
MAC=; [ "$(uname)" = Darwin ] && [ -z "${CCSWITCH_FILE_MODE:-}" ] && MAC=1

# token: keychain on mac, file elsewhere
get_live() { if [ $MAC ]; then security find-generic-password -s "$KC" -a "$ME" -w; else cat "$CRED"; fi; }
set_live() { if [ $MAC ]; then security add-generic-password -U -s "$KC" -a "$ME" -w "$1"; else printf %s "$1" > "$CRED"; fi; }
get_prof() { if [ $MAC ]; then security find-generic-password -s "ccswitch-$1" -a "$ME" -w; else cat "$D/$1.cred"; fi; }
set_prof() { if [ $MAC ]; then security add-generic-password -U -s "ccswitch-$1" -a "$ME" -w "$2"; else printf %s "$2" > "$D/$1.cred"; fi; }

# oauthAccount json: jq or python3
get_acct() { if command -v jq >/dev/null; then jq -c .oauthAccount "$CJ"; else python3 -c "import json;print(json.dumps(json.load(open('$CJ'))['oauthAccount'],separators=(',',':')))"; fi; }
set_acct() { if command -v jq >/dev/null; then jq --argjson a "$(cat "$1")" '.oauthAccount=$a' "$CJ" > "$CJ.tmp"
             else python3 -c "import json;d=json.load(open('$CJ'));d['oauthAccount']=json.load(open('$1'));json.dump(d,open('$CJ.tmp','w'),indent=2)"; fi
             mv "$CJ.tmp" "$CJ"; }

snap() { c="$(get_live)" || { echo "no login, run /login first" >&2; exit 1; }
         get_acct > "$D/$1.acct"; set_prof "$1" "$c"; echo "$1" > "$D/active"; }
act() { cat "$D/active" 2>/dev/null || true; }
ok() { [[ "${1:-}" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "usage: $0 $2 <name>"; exit 1; }; }

[ $# -eq 0 ] && set -- list
[ $# -eq 1 ] && [ -f "$D/$1.acct" ] && set -- use "$1"   # shortcut: `clsw team`
case "${1:-}" in
  save) ok "${2:-}" save; snap "$2"; echo "saved current login as '$2'" ;;
  use)  ok "${2:-}" use; [ -f "$D/$2.acct" ] || { echo "no profile '$2'. try: list"; exit 1; }
        [ -n "$(act)" ] && snap "$(act)"   # keep refreshed token of account we leave
        set_live "$(get_prof "$2")"; set_acct "$D/$2.acct"; echo "$2" > "$D/active"
        echo "now: $2. Restart claude (open sessions keep old account), then /resume" ;;
  list) for f in "$D"/*.acct; do [ -e "$f" ] || continue; n=$(basename "$f" .acct)
          printf '%s %s  %s\n' "$([ "$n" = "$(act)" ] && echo '*' || echo ' ')" "$n" "$(grep -o '"emailAddress":"[^"]*"' "$f" | cut -d'"' -f4)"; done ;;
  *)    echo "usage: $0 save <name> | use <name> | list"; exit 1 ;;
esac
