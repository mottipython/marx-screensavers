#!/bin/sh
# The Marx Brothers screen savers, all in one Mac installer package: fetches each
# one's latest screen saver module from its own releases and builds
# dist/MarxBrothers-ScreenSavers-VERSION.pkg, which puts them all in
# /Library/Screen Savers for everyone on the Mac. Runs on macOS (pkgbuild,
# productbuild): .github/workflows/bundles.yml.
#
#   sh tools/build-mac-bundle.sh [VERSION]
set -eu
VERSION=${1:-1.0.0}
ALL="mirror-scene captain-spaulding duck-soup groucho-clock groucho-time harpos-coat"
cd "$(dirname "$0")/.."
rm -rf build/mac; mkdir -p build/mac/zips "build/mac/root/Library/Screen Savers" dist
for name in $ALL; do
    gh release download -R "mottipython/$name" --pattern '*-mac-screensaver.zip' -D build/mac/zips --clobber
done
for z in build/mac/zips/*.zip; do ditto -x -k "$z" "build/mac/root/Library/Screen Savers"; done
ls "build/mac/root/Library/Screen Savers"
# installed where they are meant to go, not "relocated" to some other copy of the
# same bundle the Installer happens to find on the Mac
pkgbuild --analyze --root build/mac/root build/mac/components.plist
plutil -p build/mac/components.plist
n=$(/usr/libexec/PlistBuddy -c 'Print' build/mac/components.plist | grep -c 'RootRelativeBundlePath')
i=0
while [ $i -lt "$n" ]; do
    /usr/libexec/PlistBuddy -c "Set :$i:BundleIsRelocatable false" build/mac/components.plist 2>/dev/null ||
        /usr/libexec/PlistBuddy -c "Add :$i:BundleIsRelocatable bool false" build/mac/components.plist
    i=$((i + 1))
done
pkgbuild --root build/mac/root --component-plist build/mac/components.plist \
    --identifier io.github.mottipython.marx-screensavers --version "$VERSION" --install-location / \
    build/mac/marx-screensavers.pkg
# the Installer's first page (inline text is ignored: it has to be a file)
mkdir -p build/mac/resources
cat > build/mac/resources/welcome.txt <<TXT
This puts the six Marx Brothers screen savers on this Mac: The Mirror Scene, Hooray for Captain Spaulding, Duck Soup, The Groucho Clock, Groucho Time and Harpo's Coat.

Afterwards, choose one in System Settings, Screen Saver: they are at the end of the list.
TXT
cat > build/mac/distribution.xml <<XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>The Marx Brothers Screen Savers</title>
    <welcome file="welcome.txt" mime-type="text/plain"/>
    <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
    <domains enable_localSystem="true"/>
    <choices-outline><line choice="all"/></choices-outline>
    <choice id="all" title="The Marx Brothers Screen Savers"><pkg-ref id="io.github.mottipython.marx-screensavers"/></choice>
    <pkg-ref id="io.github.mottipython.marx-screensavers" version="$VERSION">marx-screensavers.pkg</pkg-ref>
</installer-gui-script>
XML
productbuild --distribution build/mac/distribution.xml --package-path build/mac --resources build/mac/resources \
    "dist/MarxBrothers-ScreenSavers-$VERSION.pkg"
ls -la "dist/MarxBrothers-ScreenSavers-$VERSION.pkg"
