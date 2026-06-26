#!/usr/bin/env bash
# Install / uninstall the text thumbnailer.
# Usage: ./install.sh [install|uninstall]   (default: install)
set -Eeuo pipefail

BIN_DST=/usr/local/bin/textthumb
THUMB_DST=/usr/share/thumbnailers/text.thumbnailer
SRC_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# system paths need root; run file ops through sudo when not already root
SUDO=""
[[ $EUID -ne 0 ]] && SUDO="sudo"

# resolve the invoking user's home, even when the script runs under sudo
user_home() {
  if [[ -n "${SUDO_USER:-}" ]]; then getent passwd "$SUDO_USER" | cut -d: -f6
  else printf '%s\n' "$HOME"; fi
}

clear_cache() {
  local home; home="$(user_home)"
  rm -rf "$home"/.cache/thumbnails/{normal,large,x-large,xx-large,fail} 2>/dev/null || true
  echo "Cleared thumbnail cache: $home/.cache/thumbnails"
}

restart_nautilus() {
  command -v nautilus >/dev/null 2>&1 || return 0
  if [[ -n "${SUDO_USER:-}" ]]; then sudo -u "$SUDO_USER" nautilus -q 2>/dev/null || true
  else nautilus -q 2>/dev/null || true; fi
}

do_install() {
  command -v magick >/dev/null 2>&1 || { echo "Error: ImageMagick ('magick') not found." >&2; exit 1; }
  if ! magick -list format 2>/dev/null | grep -qi pango; then
    echo "Warning: ImageMagick has no Pango delegate — thumbnails may be blank." >&2
  fi
  $SUDO install -Dm755 "$SRC_DIR/textthumb"        "$BIN_DST"
  $SUDO install -Dm644 "$SRC_DIR/text.thumbnailer" "$THUMB_DST"
  echo "Installed:"
  echo "  $BIN_DST"
  echo "  $THUMB_DST"
  clear_cache
  restart_nautilus
  echo "Done. Reopen a folder in Files to see text thumbnails."
}

do_uninstall() {
  $SUDO rm -f "$BIN_DST" "$THUMB_DST"
  echo "Removed:"
  echo "  $BIN_DST"
  echo "  $THUMB_DST"
  clear_cache
  restart_nautilus
  echo "Uninstalled."
}

case "${1:-install}" in
  install)                do_install ;;
  uninstall|-u|--uninstall) do_uninstall ;;
  -h|--help|help)         echo "Usage: $0 [install|uninstall]" ;;
  *) echo "Unknown command: $1" >&2; echo "Usage: $0 [install|uninstall]" >&2; exit 1 ;;
esac
