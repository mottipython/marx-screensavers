#!/bin/sh
# Install the Marx Brothers screensavers on Linux: the newest package of each, .deb
# on Debian, Ubuntu and Mint, .rpm on Fedora, Nobara and openSUSE, all in one go.
#
#   all of them:
#     curl -fsSL https://raw.githubusercontent.com/mottipython/marx-screensavers/main/tools/linux-install.sh | sh
#   only some:
#     curl -fsSL https://raw.githubusercontent.com/mottipython/marx-screensavers/main/tools/linux-install.sh | sh -s -- duck-soup groucho-time
#   take them off again (all, or the ones named):
#     curl -fsSL https://raw.githubusercontent.com/mottipython/marx-screensavers/main/tools/linux-install.sh | sh -s -- --uninstall
#
# It asks for your password once, to install the packages. With screensaver-service
# installed they appear in its list of screen savers; without it, each one comes on
# by itself when the computer is left alone (see each one's README).
ALL="mirror-scene captain-spaulding duck-soup groucho-clock groucho-time harpos-coat"
[ "$(uname -s)" = Linux ] || { echo "This is for Linux."; exit 1; }
[ "$(uname -m)" = x86_64 ] || { echo "These are built for 64-bit PCs (x86_64) only."; exit 1; }
uninstall=0; chosen=""
for a in "$@"; do
    case "$a" in
    --uninstall) uninstall=1 ;;
    -h|--help) sed -n '2,15p' "$0" 2>/dev/null; echo "Names: $ALL"; exit 0 ;;
    *) case " $ALL " in *" $a "*) chosen="$chosen $a" ;; *) echo "No screensaver called $a. Names: $ALL"; exit 1 ;; esac ;;
    esac
done
[ -n "$chosen" ] || chosen=$ALL

# the package manager, and how to become root for it
if command -v apt-get > /dev/null; then kind=deb; pm=apt
elif command -v dnf > /dev/null; then kind=rpm; pm=dnf
elif command -v zypper > /dev/null; then kind=rpm; pm=zypper
else echo "No apt, dnf or zypper here: download the packages from each one's releases instead."; exit 1
fi
if [ "$(id -u)" = 0 ]; then root=""
elif command -v sudo > /dev/null; then root=sudo
elif command -v pkexec > /dev/null; then root=pkexec
else echo "Needs sudo or pkexec to install the packages."; exit 1
fi

if [ $uninstall = 1 ]; then
    case $pm in
    apt) $root apt-get remove -y $chosen ;;
    dnf) $root dnf remove -y $chosen ;;
    zypper) $root zypper --non-interactive remove $chosen ;;
    esac
    exit $?
fi

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
chmod 755 "$tmp"                      # apt reads the files as its own user
files=""; bad=0
for name in $chosen; do
    case $kind in deb) want='_amd64\.deb"' ;; rpm) want='\.x86_64\.rpm"' ;; esac
    url=$(curl -fsSL "https://api.github.com/repos/mottipython/$name/releases/latest" | grep browser_download_url | grep -- "$want" | sed 's/.*"\(https[^"]*\)".*/\1/' | head -1)
    file="$tmp/${url##*/}"
    if [ -z "$url" ] || ! curl -fsSL -o "$file" "$url"; then echo "FAILED     $name: could not download it"; bad=1; continue; fi
    chmod 644 "$file"
    echo "downloaded ${url##*/}"
    files="$files $file"
done
[ -n "$files" ] || exit 1
echo "Installing (your password may be asked for)..."
case $pm in
apt) $root apt-get install -y $files ;;
dnf) $root dnf install -y $files ;;
zypper) $root zypper --non-interactive install --allow-unsigned-rpm $files ;;
esac || exit 1
echo
echo "Done. With screensaver-service, choose one in its settings; otherwise they come on by themselves when the computer is left alone."
exit $bad
