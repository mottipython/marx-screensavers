#!/bin/sh
# The Marx Brothers screen savers, all in one Windows setup program: fetches each
# one's latest Windows setup from its own releases, unpacks its files, then builds
# dist/MarxBrothers-ScreenSavers-Setup-VERSION.exe around them
# (packaging/windows/marx-screensavers.nsi).
#
#   sh tools/build-bundle.sh [VERSION]
#
# Needs gh (signed in) and makensis, or podman with the anathem-build image.
set -eu
VERSION=${1:-1.0.0}
cd "$(dirname "$0")/.."
# id, the screen saver's name, its .scr: in the order they're listed
SAVERS="mirror-scene|The Mirror Scene|MirrorScene
captain-spaulding|Hooray for Captain Spaulding|CaptainSpaulding
duck-soup|Duck Soup|DuckSoup
groucho-clock|The Groucho Clock|GrouchoClock
groucho-time|Groucho Time|GrouchoTime
harpos-coat|Harpo's Coat|HarposCoat"

mkdir -p build/setups dist
rm -rf build/files
: > build/savers.nsh
n=0
echo "$SAVERS" | while IFS='|' read -r id title scr; do
    gh release download -R "mottipython/$id" --pattern '*Setup*.exe' -D build/setups --clobber
    setup=$(cd build/setups && ls -t "$scr"-Setup-*.exe | head -1)
    version=${setup#"$scr"-Setup-}; version=${version%.exe}
    # its files, unpacked from its own setup: the bundle installs them itself, rather
    # than running setup programs from inside a setup program (which antivirus takes
    # for a dropper and quietly stops)
    7z x -y -o"build/files/$id" "build/setups/$setup" "$id.exe" SDL2.dll SDL3.dll README.txt LICENSE.txt "\$WINDIR/System32/$scr.scr" > /dev/null
    mv "build/files/$id/\$WINDIR/System32/$scr.scr" "build/files/$id/"
    rm -rf "build/files/$id/\$WINDIR"
    ls "build/files/$id"
    echo "!insertmacro SAVER $n \"$title\" \"$id\" \"$scr\" \"$version\"" >> build/savers.nsh
    n=$((n + 1))
done
echo "!define NSAVERS $(echo "$SAVERS" | wc -l)" >> build/savers.nsh
cat build/savers.nsh

if command -v makensis > /dev/null; then
    makensis -V2 -DVERSION="$VERSION" packaging/windows/marx-screensavers.nsi
else
    podman run --rm --security-opt label=disable -v "$PWD":/src -w /src anathem-build \
        makensis -V2 -DVERSION="$VERSION" packaging/windows/marx-screensavers.nsi
fi
ls -la "dist/MarxBrothers-ScreenSavers-Setup-$VERSION.exe"
