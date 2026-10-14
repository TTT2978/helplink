#!/bin/sh
# HelpLink - one-line installer.
#   curl -sL https://raw.githubusercontent.com/YOUR_USER/helplink/main/install.sh | sh
# Downloads helplink.zip from the repo, unzips it to ~/.helplink/app, then starts setup.sh.
# Everything is wrapped in main() so the whole script is read before anything runs
# (important when it is piped into sh).

main() {
  REPO="${HELPLINK_REPO:-TTT2978/helplink}"
  BRANCH="${HELPLINK_BRANCH:-main}"
  URL="${HELPLINK_URL:-https://raw.githubusercontent.com/$REPO/$BRANCH/helplink.zip}"
  HL_HOME="${HELPLINK_HOME:-$HOME/.helplink}"

  have() { command -v "$1" >/dev/null 2>&1; }
  die()  { printf '[x] %s\n' "$*" >&2; exit 1; }

  printf '[+] HelpLink installer\n'
  printf '[+] Downloading / Đang tải: %s\n' "$URL"

  TMP=$(mktemp -d 2>/dev/null || mktemp -d -t helplink) || die "mktemp failed"
  trap 'rm -rf "$TMP"' EXIT INT TERM

  if have curl; then curl -fsSL -o "$TMP/helplink.zip" "$URL" || die "download failed / tải thất bại (check REPO name: $REPO)"
  elif have wget; then wget -qO "$TMP/helplink.zip" "$URL" || die "download failed / tải thất bại"
  else die "curl or wget is required / cần curl hoặc wget"
  fi

  mkdir -p "$TMP/x"
  if have unzip; then
    unzip -q -o "$TMP/helplink.zip" -d "$TMP/x" || die "unzip failed"
  elif have python3; then
    python3 -c "import sys,zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$TMP/helplink.zip" "$TMP/x" || die "unzip failed"
  elif have python; then
    python -c "import sys,zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$TMP/helplink.zip" "$TMP/x" || die "unzip failed"
  else
    die "need unzip or python3 to open the zip / cần unzip hoặc python3 (Termux: pkg install unzip | Debian: sudo apt install unzip)"
  fi

  printf '[+] Unzipped / Đã giải nén -> %s/app\n' "$HL_HOME"
  mkdir -p "$HL_HOME"
  rm -rf "$HL_HOME/app"
  if [ -d "$TMP/x/helplink" ]; then mv "$TMP/x/helplink" "$HL_HOME/app"; else mv "$TMP/x" "$HL_HOME/app"; fi
  chmod +x "$HL_HOME/app/setup.sh" "$HL_HOME/app/bin/helplink" 2>/dev/null

  # prompts must read from the keyboard, not from the curl pipe
  if ( : </dev/tty ) 2>/dev/null; then
    sh "$HL_HOME/app/setup.sh" </dev/tty
  else
    sh "$HL_HOME/app/setup.sh"
  fi
}

main "$@"
