#!/bin/sh
# Install the Marx Brothers screensavers on a Mac.
#
#   all of them:
#     curl -fsSL https://raw.githubusercontent.com/mottipython/marx-screensavers/main/tools/mac-install.sh | sh
#   only some:
#     curl -fsSL https://raw.githubusercontent.com/mottipython/marx-screensavers/main/tools/mac-install.sh | sh -s -- mirror-scene
#   take them off again (all, or the ones named):
#     curl -fsSL https://raw.githubusercontent.com/mottipython/marx-screensavers/main/tools/mac-install.sh | sh -s -- --uninstall
#
# Each screen saver module goes into ~/Library/Screen Savers, for your user only, so no
# password is asked for. Then choose one in System Settings, Screen Saver.
ALL="mirror-scene captain-spaulding duck-soup groucho-clock groucho-time"
title() {
    case "$1" in
    mirror-scene) echo "The Mirror Scene" ;; captain-spaulding) echo "Hooray for Captain Spaulding" ;; duck-soup) echo "Duck Soup" ;; groucho-clock) echo "The Groucho Clock" ;; groucho-time) echo "Groucho Time" ;;
    *) return 1 ;;
    esac
}
[ "$(uname -s)" = Darwin ] || { echo "This is for macOS."; exit 1; }
uninstall=0; chosen=""
for a in "$@"; do
    case "$a" in
    --uninstall) uninstall=1 ;;
    -h|--help) sed -n '2,12p' "$0" 2>/dev/null; echo "Names: $ALL"; exit 0 ;;
    *) title "$a" >/dev/null || { echo "No screensaver called $a. Names: $ALL"; exit 1; }; chosen="$chosen $a" ;;
    esac
done
[ -n "$chosen" ] || chosen=$ALL
dest="$HOME/Library/Screen Savers"; mkdir -p "$dest"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
bad=0
for name in $chosen; do
    t=$(title "$name")
    if [ $uninstall = 1 ]; then
        if [ -d "$dest/$t.saver" ]; then rm -rf "$dest/$t.saver"; echo "removed    $t"; fi
        continue
    fi
    url=$(curl -fsSL "https://api.github.com/repos/mottipython/$name/releases/latest" | grep browser_download_url | grep -- '-mac-screensaver.zip' | sed 's/.*"\(https[^"]*\)".*/\1/' | head -1)
    if [ -z "$url" ] || ! curl -fsSL -o "$tmp/$name.zip" "$url"; then echo "FAILED     $t: could not download it"; bad=1; continue; fi
    rm -rf "$tmp/x"; mkdir "$tmp/x"
    if ! ditto -x -k "$tmp/$name.zip" "$tmp/x" || [ ! -d "$tmp/x/$t.saver" ]; then echo "FAILED     $t: the download was not what was expected"; bad=1; continue; fi
    rm -rf "$dest/$t.saver"; cp -R "$tmp/x/$t.saver" "$dest/"
    xattr -dr com.apple.quarantine "$dest/$t.saver" 2>/dev/null
    echo "installed  $t"
done
if [ $uninstall = 1 ]; then echo "Done."; exit 0; fi
echo
echo "They are in System Settings, Screen Saver, at the end of the list. Opening it now."
open "x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension" 2>/dev/null || open "/System/Library/PreferencePanes/DesktopScreenEffectsPref.prefPane" 2>/dev/null
exit $bad
