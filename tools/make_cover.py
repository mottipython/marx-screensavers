"""The index page's cover: Duck Soup's curtains and swags, and the six screensavers
hanging on ropes on the stage between them, in two rows under a title card. It is also
the picture to post with a link to the page.

    duck-soup --snapshot stage.bmp --time 2.95 --size 2000x1050 --seed 7 --mute   (then make it a PNG)
    tools/make_cover.py stage.png docs/cover.jpg MIRROR.jpg SPAULDING.jpg DUCKSOUP.jpg \
        GROUCHOCLOCK.jpg GROUCHOTIME.jpg HARPOSCOAT.jpg

The pictures used: mirror-scene 01-nose-to-nose, captain-spaulding
03-hello-i-must-be-going, duck-soup 03-honk, groucho-clock 01-seven-fifty-two,
groucho-time 05-raquel-torres and harpos-coat 01-a-candle-burning-at-both-ends.
"""
import sys, numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

stage_path, out, *shots = sys.argv[1:]
st = Image.open(stage_path).convert("RGB"); W, H = st.size
a = np.asarray(st).astype(int); r, g, b = a[..., 0], a[..., 1], a[..., 2]
velvet = (r > 60) & (g < 75) & (r > g * 2.2) & (r > b * 1.4)
gold = (r > 150) & (g > 110) & (b < 90) & (r - b > 70)
cloth = velvet.copy(); cloth[:int(H * 0.2)] |= gold[:int(H * 0.2)]      # the curtains, and the pelmet's braid
L = np.zeros(H, int); R = np.full(H, W)
for y in range(H):
    xs = np.nonzero(velvet[y, :int(W * 0.2)])[0]; L[y] = xs.max() + 8 if len(xs) else 0
    xs = np.nonzero(velvet[y, int(W * 0.8):])[0]; R[y] = int(W * 0.8) + xs.min() - 8 if len(xs) else W
P = np.zeros(W, int)
for x in range(W):
    ys = np.nonzero(cloth[:int(H * 0.3), x])[0]; P[x] = ys.max() + 8 if len(ys) else 0
# the stage behind: a dark warm backdrop, lit from above in the middle
yy, xx = np.mgrid[0:H, 0:W]
light = np.exp(-(((xx - W / 2) / (W * 0.42)) ** 2 + ((yy - H * 0.45) / (H * 0.75)) ** 2))
back = np.stack([28 + 70 * light, 18 + 42 * light, 16 + 30 * light], -1)
grain = np.random.default_rng(3).normal(0, 3, (H, W, 1))
back = np.clip(back + grain, 0, 255)
inside = (xx > L[:, None]) & (xx < R[:, None]) & (yy > P[None, :])
# the stage floor: boards running back from the footlights
floor = int(H * 0.915)
boards = np.stack([92 + 0 * xx, 60 + 0 * xx, 34 + 0 * xx], -1).astype(float)
boards *= (0.85 + 0.15 * ((xx // 140) % 2))[..., None]
boards *= (0.75 + 0.35 * ((yy - floor) / (H - floor)).clip(0, 1))[..., None]
back = np.where((yy >= floor)[..., None], boards, back)
img = np.where(inside[..., None], back, a).astype(np.uint8)
im = Image.fromarray(img); d = ImageDraw.Draw(im)
d.line([(0, floor), (W, floor)], fill=(30, 24, 20), width=5)
d.line([(0, floor + 4), (W, floor + 4)], fill=(150, 108, 62), width=2)
GOLD, DARK_GOLD, INK, ROPE = (205, 168, 92), (140, 104, 44), (30, 24, 20), (150, 116, 66)
SILVER, GREY = (228, 226, 218), (172, 170, 166)
serif = "/usr/share/fonts/liberation-serif/LiberationSerif-Bold.ttf"
def font(px): return ImageFont.truetype(serif, px)
def centred(text, cx, y, f, fill, spacing=0):
    w = sum(d.textlength(c, font=f) for c in text) + spacing * (len(text) - 1); x = cx - w / 2
    for c in text: d.text((x, y), c, font=f, fill=fill); x += d.textlength(c, font=f) + spacing
def plate(x0, y0, x1, y1):
    d.rectangle([x0 + 8, y0 + 10, x1 + 8, y1 + 10], fill=(10, 8, 8))
    d.rectangle([x0, y0, x1, y1], fill=(20, 19, 22))
    d.rectangle([x0 + 10, y0 + 10, x1 - 10, y1 - 10], outline=GOLD, width=5)
    for cx, cy in ((x0 + 22, y0 + 22), (x1 - 22, y0 + 22), (x0 + 22, y1 - 22), (x1 - 22, y1 - 22)):
        d.ellipse([cx - 7, cy - 7, cx + 7, cy + 7], fill=GOLD)
def rope(x, y0, y1):
    d.line([(x, y0), (x, y1)], fill=INK, width=7); d.line([(x, y0), (x, y1)], fill=ROPE, width=4)
    d.ellipse([x - 8, y1 - 8, x + 8, y1 + 8], fill=GOLD)
# the title card, on two ropes from the swags
tx0, tx1, ty0, ty1 = W * 0.30, W * 0.70, H * 0.12, H * 0.30
for x in (W * 0.36, W * 0.64): rope(x, 0, ty0 + 6)
plate(tx0, ty0, tx1, ty1)
centred("THE", W / 2, ty0 + 22, font(int(H * 0.03)), SILVER, 6)
centred("MARX BROTHERS", W / 2, ty0 + 44, font(int(H * 0.066)), SILVER, 4)
centred("— SCREENSAVERS —", W / 2, ty0 + 44 + H * 0.082, font(int(H * 0.028)), GREY, 8)
# the six, each a picture in a gilt frame, hung on ropes, with its name beneath
pw = int(W * 0.19); ph = int(pw * 9 / 16); gap = int(W * 0.035)
names = ["THE MIRROR SCENE", "CAPTAIN SPAULDING", "DUCK SOUP", "THE GROUCHO CLOCK", "GROUCHO TIME", "HARPO'S COAT"]
tilts = (-1.2, 0.6, -0.6, 0.8, -0.9, 1.0)
for i, (path, name) in enumerate(zip(shots, names)):
    row, col = divmod(i, 3)
    x = (W - 3 * pw - 2 * gap) // 2 + col * (pw + gap); py = int(H * (0.36 if row == 0 else 0.645))
    pic = Image.open(path).convert("RGB")
    pr = pic.width / pic.height
    if pr > 16 / 9: cw = int(pic.height * 16 / 9); pic = pic.crop(((pic.width - cw) // 2, 0, (pic.width + cw) // 2, pic.height))
    else: ch = int(pic.width * 9 / 16); pic = pic.crop((0, (pic.height - ch) // 2, pic.width, (pic.height + ch) // 2))
    pic = pic.resize((pw, ph), Image.LANCZOS)
    fr = Image.new("RGBA", (pw + 36, ph + 36), GOLD + (255,)); fd = ImageDraw.Draw(fr)
    fd.rectangle([0, 0, pw + 35, ph + 35], outline=INK, width=4)
    fd.rectangle([10, 10, pw + 25, ph + 25], outline=DARK_GOLD, width=4)
    fr.paste(pic, (18, 18)); fd.rectangle([17, 17, pw + 18, ph + 18], outline=INK, width=2)
    fr = fr.rotate(tilts[i], resample=Image.BICUBIC, expand=True)
    sh = Image.new("RGBA", fr.size, (0, 0, 0, 0)); sh.putalpha(fr.split()[3].point(lambda v: v * 0.55))
    sh = sh.filter(ImageFilter.GaussianBlur(10))
    top = 0 if row == 0 else int(H * 0.36) + ph + 70
    if row == 0 and col == 1: top = int(ty1)
    for rx in (x + pw * 0.25, x + pw * 0.75): rope(int(rx), top, py + 4)
    im.paste(sh, (x + 10, py + 14), sh); im.paste(fr, (x - 18, py - 18), fr)
    centred(name, x + pw / 2, py + ph + 30, font(int(H * 0.027)), SILVER, 4)
im.save(out, quality=90)
print(out, im.size)
