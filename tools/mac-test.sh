#!/bin/sh
# Test every Marx Brothers screensaver on this Mac, and say what works.
#   curl -fsSL https://raw.githubusercontent.com/mottipython/marx-screensavers/main/tools/mac-test.sh | sh
# Name some to test only those:  ... | sh -s -- duck-soup harpos-coat
#
# For each one it downloads the latest release's Mac files and checks:
#   - the files: both zips are there, the app and the module are the release's version,
#     and they run on both kinds of Mac (Apple Silicon and Intel);
#   - the screen saver module: it loads the way macOS loads it, runs for three seconds,
#     and draws a picture that is not blank (with test-saver, a small helper from this
#     project's releases, since macOS won't load one into its own tools); then it is
#     installed for this user;
#   - the app: it draws a picture that is not blank, the picture moves over time, its
#     sound is not silent, and it runs in a window for ten seconds without dying;
#   - and that none of it left a crash report.
# Everything is written to ~/marx-mac-test: report.txt, and report.html with the
# pictures, which it opens at the end. Nothing needs a password or a developer tool.
[ "$(uname)" = Darwin ] || { echo "This is for macOS."; exit 1; }
ALL="mirror-scene captain-spaulding duck-soup groucho-clock groucho-time harpos-coat"
chosen="$*"; [ -n "$chosen" ] || chosen=$ALL
dir="$HOME/marx-mac-test"; report="$dir/report.txt"; html="$dir/report.html"
mkdir -p "$dir" "$HOME/Library/Screen Savers"; cd "$dir" || exit 1
: > "$report"
say() { echo "$*" | tee -a "$report"; }
touch "$dir/.started"

# A little JavaScript for Automation (built into macOS) to look at the pixels of a
# picture: the apps' .bmp pictures are read byte by byte, anything else by macOS.
cat > check.js <<'EOF'
ObjC.import('Cocoa');
function load(path) {
  var data = $.NSData.dataWithContentsOfFile(path);
  if (data.isNil()) return null;
  if (/\.bmp$/i.test(path)) {
    var s = ObjC.unwrap($.NSString.alloc.initWithDataEncoding(data, 5));    // one char per byte
    var u = function (o, n) { var v = 0; for (var k = n - 1; k >= 0; k--) v = v * 256 + s.charCodeAt(o + k); return v; };
    var off = u(10, 4), w = u(18, 4), h = u(22, 4), bpp = u(28, 2);
    var down = h > 0x7fffffff; if (down) h = 0x100000000 - h;
    var row = Math.floor((bpp * w + 31) / 32) * 4, step = bpp / 8;
    var rgb = function (x, y) {
      var p = off + (down ? y : h - 1 - y) * row + x * step;
      return [s.charCodeAt(p + 2), s.charCodeAt(p + 1), s.charCodeAt(p)]; };
    return { w: w, h: h, rgb: rgb, at: function (x, y) { var c = rgb(x, y); return (c[0] + c[1] + c[2]) / 3; } };
  }
  var rep = $.NSBitmapImageRep.imageRepWithData(data);
  if (rep.isNil()) return null;
  var rgb = function (x, y) {
    var c = rep.colorAtXY(x, y).colorUsingColorSpace($.NSColorSpace.sRGBColorSpace);
    return [c.redComponent * 255, c.greenComponent * 255, c.blueComponent * 255]; };
  return { w: rep.pixelsWide, h: rep.pixelsHigh, rgb: rgb, at: function (x, y) { var c = rgb(x, y); return (c[0] + c[1] + c[2]) / 3; } };
}
// a grid of samples of its brightness, n across
function samples(pic, n) {
  var out = [], m = Math.round(n * 9 / 16);
  for (var j = 0; j < m; j++) for (var i = 0; i < n; i++)
    out.push(pic.at(Math.floor((i + 0.5) * pic.w / n), Math.floor((j + 0.5) * pic.h / m)));
  return out;
}
function run(argv) {
  if (argv[0] == 'stats') {                 // stats PICTURE: size, mean, spread
    var pic = load(argv[1]); if (!pic) return 'unreadable';
    var s = samples(pic, 48), m = 0, v = 0;
    s.forEach(function (x) { m += x; }); m /= s.length;
    s.forEach(function (x) { v += (x - m) * (x - m); });
    return pic.w + ' ' + pic.h + ' ' + m.toFixed(1) + ' ' + Math.sqrt(v / s.length).toFixed(1);
  }
  if (argv[0] == 'png') {                   // png PICTURE OUT.png: a 640-wide copy for the report
    var pic = load(argv[1]); if (!pic) return 'unreadable';
    var w = 640, h = Math.round(640 * pic.h / pic.w), row = [], pad = (4 - (w * 3) % 4) % 4, body = [];
    for (var y = h - 1; y >= 0; y--) {                  // a plain 24-bit BMP, bottom row first
      row = [];
      for (var x = 0; x < w; x++) {
        var sx = Math.floor(x * pic.w / w), sy = Math.floor(y * pic.h / h), c = pic.rgb(sx, sy);
        row.push(String.fromCharCode(c[2], c[1], c[0]));
      }
      for (var k = 0; k < pad; k++) row.push('\0');
      body.push(row.join(''));
    }
    var data = body.join(''), le = function (v, n) { var t = ''; for (var k = 0; k < n; k++) { t += String.fromCharCode(v & 255); v = Math.floor(v / 256); } return t; };
    var head = 'BM' + le(54 + data.length, 4) + le(0, 4) + le(54, 4) + le(40, 4) + le(w, 4) + le(h, 4) + le(1, 2) + le(24, 2) + le(0, 4) + le(data.length, 4) + le(2835, 4) + le(2835, 4) + le(0, 4) + le(0, 4);
    var bytes = $(head + data).dataUsingEncoding(5);
    var r = $.NSBitmapImageRep.imageRepWithData(bytes);
    if (r.isNil()) return 'unreadable';
    var png = r.representationUsingTypeProperties($.NSBitmapImageFileTypePNG, $());
    return png.writeToFileAtomically(argv[2], true) ? 'ok' : 'unwritable';
  }
  if (argv[0] == 'diff') {                  // diff A B: how many of 14400 points differ
    var a = load(argv[1]), b = load(argv[2]); if (!a || !b) return 'unreadable';
    var sa = samples(a, 160), sb = samples(b, 160), d = 0;
    for (var k = 0; k < sa.length; k++) if (Math.abs(sa[k] - sb[k]) > 12) d++;
    return '' + d;
  }
}
EOF
# test-saver: loads a screen saver module as macOS does and saves what it drew
helper="$dir/test-saver"
if [ ! -x "$helper" ]; then
    curl -fsSL -o "$dir/test-saver.zip" https://github.com/mottipython/marx-screensavers/releases/download/test-saver/test-saver.zip \
        && ditto -x -k "$dir/test-saver.zip" "$dir" && chmod +x "$helper"
fi
js() { osascript -l JavaScript check.js "$@" 2>&1 | tail -1; }
# a picture is blank if it is all one colour, near enough
blank() { set -- $(js stats "$1"); [ "$#" -lt 4 ] || [ "${4%.*}" -lt 4 ]; }

cat > "$html" <<EOF
<!doctype html><meta charset="utf-8"><title>Marx Brothers screensavers on this Mac</title>
<style>body{font:15px -apple-system,sans-serif;margin:24px;background:#faf8f4;color:#222}
h2{margin:28px 0 6px}.ok{color:#17702d}.bad{color:#b3261e;font-weight:600}
img{width:320px;border:1px solid #ccc;margin:4px 8px 0 0;vertical-align:top}
figure{display:inline-block;margin:0}figcaption{font-size:12px;color:#666}li{margin:2px 0}</style>
<h1>Marx Brothers screensavers on this Mac</h1>
<p>$(sw_vers -productName) $(sw_vers -productVersion), $(uname -m), $(date)</p>
EOF

say "Mac: $(sw_vers -productName) $(sw_vers -productVersion), $(uname -m)"
say ""
fails=0
for repo in $chosen; do
    say "== $repo"
    bad=0; notes=""
    note() {                                # note ok|FAIL|-- TEXT
        say "   $1  $2"
        case $1 in FAIL) bad=1; c=bad ;; ok) c=ok ;; *) c="" ;; esac
        notes="$notes<li class=\"$c\">$1 &nbsp;$2</li>"
    }
    pics=""
    pic() { [ -s "$1" ] && pics="$pics<figure><img src=\"$1\"><figcaption>$2</figcaption></figure>"; }

    # the files
    json=$(curl -fsSL "https://api.github.com/repos/mottipython/$repo/releases/latest")
    tag=$(echo "$json" | grep '"tag_name"' | head -1 | sed 's/.*"v\{0,1\}\([^"]*\)".*/\1/')
    urls=$(echo "$json" | grep browser_download_url | grep -- '-mac' | sed 's/.*"\(https[^"]*\)".*/\1/')
    rm -rf "$repo"; mkdir "$repo"
    n=0; for u in $urls; do curl -fsSL -o "$repo/$n.zip" "$u" && ditto -x -k "$repo/$n.zip" "$repo" && n=$((n + 1)); done
    xattr -dr com.apple.quarantine "$repo" 2>/dev/null
    if [ $n -ge 2 ]; then note ok "release $tag: downloaded the app and the module"; else note FAIL "release $tag: found $n of the 2 Mac downloads"; fi
    app=$(ls -d "$repo"/*.app 2>/dev/null | head -1); saver=$(ls -d "$repo"/*.saver 2>/dev/null | head -1)
    for b in "$app" "$saver"; do
        [ -n "$b" ] || continue
        what=module; [ "${b%.app}" = "$b" ] || what=app
        v=$(plutil -extract CFBundleShortVersionString raw "$b/Contents/Info.plist" 2>/dev/null)
        exe=$(plutil -extract CFBundleExecutable raw "$b/Contents/Info.plist" 2>/dev/null)
        archs=$(file -b "$b/Contents/MacOS/$exe" 2>/dev/null)
        case "$archs" in *x86_64*arm64*|*arm64*x86_64*) a="Apple Silicon and Intel" ;; *) a="only: $archs" ;; esac
        if [ "$v" = "$tag" ] && [ "$a" = "Apple Silicon and Intel" ]; then note ok "$what: version $v, for $a"
        else note FAIL "$what: version '$v' (release $tag), for $a"; fi
    done

    # the screen saver module
    if [ -n "$saver" ]; then
        if [ -x "$helper" ]; then
            r=$("$helper" "$saver" "$repo/saver.png" 2>&1 | tail -1)
            if [ ! -s "$repo/saver.png" ]; then note FAIL "module: $r"
            elif blank "$repo/saver.png"; then note FAIL "module loads and runs, but draws a blank picture"
            else note ok "module loads, runs for 3 s and draws"; fi
        else note -- "module: not tried (could not get the test-saver helper)"; fi
        pic "$repo/saver.png" "the screen saver module, after 3 s"
        rm -rf "$HOME/Library/Screen Savers/$(basename "$saver")"; cp -R "$saver" "$HOME/Library/Screen Savers/"
        note -- "module installed in ~/Library/Screen Savers"
    else note FAIL "no screen saver module"; fi

    # the app
    bin="$app/Contents/MacOS/$repo"
    if [ -x "$bin" ]; then
        ok=1
        for t in 2 7; do
            SDL_VIDEODRIVER=dummy "$bin" --snapshot "$repo/app$t.bmp" --time $t --size 1280x720 >"$repo/log$t.txt" 2>&1 &
            p=$!; i=0; while kill -0 $p 2>/dev/null && [ $i -lt 60 ]; do sleep 1; i=$((i + 1)); done
            if kill -0 $p 2>/dev/null; then kill $p; ok=0; note FAIL "app: a picture at $t s took over a minute"; fi
        done
        if [ ! -s "$repo/app2.bmp" ] || [ ! -s "$repo/app7.bmp" ]; then
            [ $ok = 0 ] || note FAIL "app does not draw ($(head -1 "$repo/log2.txt"))"
        elif blank "$repo/app2.bmp"; then note FAIL "app draws a blank picture"
        else
            d=$(js diff "$repo/app2.bmp" "$repo/app7.bmp")
            if [ "$d" -ge 2 ] 2>/dev/null; then note ok "app draws, and moves (between 2 s and 7 s, $d of 14400 points changed)"
            else note FAIL "app draws, but does not move (between 2 s and 7 s, $d of 14400 points changed)"; fi
        fi
        for t in 2 7; do [ -s "$repo/app$t.bmp" ] && js png "$repo/app$t.bmp" "$repo/app$t.png" >/dev/null; done
        pic "$repo/app2.png" "the app at 2 s"; pic "$repo/app7.png" "the app at 7 s"
        # the sound, if the app can write it out
        if grep -a -q -- '--wav' "$bin"; then
            "$bin" --wav "$repo/sound.wav" --time 30 >/dev/null 2>&1
            if [ -s "$repo/sound.wav" ] && od -An -v -tu1 -j 44 "$repo/sound.wav" | tr -s ' ' '\n' | grep -qv '^0*$'; then
                note ok "sound: 30 s of it is not silent ($(( $(wc -c < "$repo/sound.wav") / 1024 )) KB)"
            else note FAIL "sound: 30 s of it is silent or missing"; fi
        else note -- "sound: this one can't write its sound out to check (older version)"; fi
        # a real window, for ten seconds
        "$bin" --window >"$repo/window.txt" 2>&1 &
        p=$!; sleep 10
        if kill -0 $p 2>/dev/null; then
            screencapture -x "$repo/screen.png" 2>/dev/null
            kill $p 2>/dev/null; wait $p 2>/dev/null
            note ok "app runs in a window for 10 s"
            pic "$repo/screen.png" "the screen, with its window (blank or desktop only if Terminal may not record the screen)"
        else wait $p; note FAIL "app's window closed by itself, exit $? ($(head -1 "$repo/window.txt"))"; fi
    else note FAIL "no app"; fi

    # crashes
    crash=$(find "$HOME/Library/Logs/DiagnosticReports" -newer "$dir/.started" 2>/dev/null | grep -i -e "$repo" -e test-saver | head -1)
    if [ -n "$crash" ]; then note FAIL "a crash report: $crash"; else note ok "no crash reports"; fi

    if [ $bad = 0 ]; then say "   => all good"; s="<span class=ok>all good</span>"
    else say "   => SOMETHING FAILED"; s="<span class=bad>something failed</span>"; fails=$((fails + 1)); fi
    say ""
    echo "<h2>$repo $tag: $s</h2><ul>$notes</ul>$pics" >> "$html"
done
if [ $fails = 0 ]; then say "Everything passed."; else say "$fails of them had a failure (marked FAIL above)."; fi
say "Last: open the Screen Saver settings, pick one at the end of the list, and press Preview."
echo "<p>Last: open the Screen Saver settings, pick one at the end of the list, and press Preview.</p>" >> "$html"
open "$html"
echo; echo "The report is in $report, with pictures in $html"
