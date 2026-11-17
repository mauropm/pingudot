"""PINGUDOT ending cinematics art.

Generates the two character-specific epilogues' environments:

  Pingu  — Puerto Escondido: three sunset stages, sun, clouds, surf, palms,
           birds.
  Miggy  — winter apartment: room, CRT monitor animations, snow, lamp glow.

Run from tools/art:
    python3 gen_endings.py
"""
from common import Canvas, C, mix, pack, out_path
from PIL import Image, ImageDraw
import math, random

W, H = 384, 216
INK = C("#0a0a12")


# ---------------------------------------------------------------------------
# tiny 3x5 pixel font (posters, screen headers)
# ---------------------------------------------------------------------------
GLYPHS = {
    "A": ["010", "101", "111", "101", "101"],
    "B": ["110", "101", "110", "101", "110"],
    "C": ["011", "100", "100", "100", "011"],
    "D": ["110", "101", "101", "101", "110"],
    "E": ["111", "100", "110", "100", "111"],
    "F": ["111", "100", "110", "100", "100"],
    "G": ["011", "100", "101", "101", "011"],
    "H": ["101", "101", "111", "101", "101"],
    "I": ["111", "010", "010", "010", "111"],
    "J": ["001", "001", "001", "101", "010"],
    "K": ["101", "101", "110", "101", "101"],
    "L": ["100", "100", "100", "100", "111"],
    "M": ["101", "111", "111", "101", "101"],
    "N": ["101", "111", "111", "111", "101"],
    "O": ["010", "101", "101", "101", "010"],
    "P": ["110", "101", "110", "100", "100"],
    "Q": ["010", "101", "101", "111", "011"],
    "R": ["110", "101", "110", "101", "101"],
    "S": ["011", "100", "010", "001", "110"],
    "T": ["111", "010", "010", "010", "010"],
    "U": ["101", "101", "101", "101", "111"],
    "V": ["101", "101", "101", "101", "010"],
    "W": ["101", "101", "111", "111", "101"],
    "X": ["101", "101", "010", "101", "101"],
    "Y": ["101", "101", "010", "010", "010"],
    "Z": ["111", "001", "010", "100", "111"],
    "0": ["111", "101", "101", "101", "111"],
    "1": ["010", "110", "010", "010", "111"],
    "2": ["110", "001", "010", "100", "111"],
    "3": ["110", "001", "010", "001", "110"],
    "4": ["101", "101", "111", "001", "001"],
    "5": ["111", "100", "110", "001", "110"],
    "6": ["011", "100", "111", "101", "111"],
    "7": ["111", "001", "010", "010", "010"],
    "8": ["111", "101", "111", "101", "111"],
    "9": ["111", "101", "111", "001", "110"],
    " ": ["000", "000", "000", "000", "000"],
    ".": ["000", "000", "000", "000", "010"],
    ":": ["000", "010", "000", "010", "000"],
    "-": ["000", "000", "111", "000", "000"],
    "+": ["000", "010", "111", "010", "000"],
    "=": ["000", "111", "000", "111", "000"],
    "/": ["001", "001", "010", "100", "100"],
    ">": ["100", "010", "001", "010", "100"],
}


def text(cv, x, y, s, col, scale=1):
    for ch in s.upper():
        g = GLYPHS.get(ch, GLYPHS[" "])
        for gy, row in enumerate(g):
            for gx, v in enumerate(row):
                if v == "1":
                    cv.rect(x + gx * scale, y + gy * scale, scale, scale, col)
        x += 4 * scale


def text_w(s, scale=1):
    return max(0, len(s) * 4 * scale - scale)


def vgrad(cv, y0, y1, stops):
    """Vertical gradient. stops = [(t, color), ...]."""
    for y in range(y0, y1):
        t = (y - y0) / max(1, y1 - y0 - 1)
        lo = stops[0]
        hi = stops[-1]
        for i in range(len(stops) - 1):
            if stops[i][0] <= t <= stops[i + 1][0]:
                lo, hi = stops[i], stops[i + 1]
                break
        span = max(1e-5, hi[0] - lo[0])
        cv.rect(0, y, W, 1, mix(lo[1], hi[1], (t - lo[0]) / span))


def dither_band(cv, x, y, w, h, cols, seed=1, p=0.28):
    cv.noisy_fill(x, y, w, h, cols, seed=seed) if False else None
    rnd = random.Random(seed)
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            cv.px(xx, yy, cols[1] if rnd.random() < p else cols[0])


def wrap_dash(d, x, y, w, h, col):
    """Draw a dash that wraps around the 384px tile seam."""
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=col)
    if x < 0:
        d.rectangle([x + W, y, x + W + w - 1, y + h - 1], fill=col)
    if x + w > W:
        d.rectangle([x - W, y, x - W + w - 1, y + h - 1], fill=col)


# ---------------------------------------------------------------------------
# Pingu — Puerto Escondido beach
# ---------------------------------------------------------------------------
def pingu_stage(name, phase):
    cv = Canvas(W, H)
    rnd = random.Random(11 + phase)

    if phase == 0:      # late afternoon
        sky = [(0.0, C("#3f7fc4")), (0.45, C("#83c4e6")),
               (0.78, C("#f6d9a6")), (1.0, C("#ffe9bd"))]
        sea_top, sea_bot = C("#2d7fc0"), C("#17538e")
        sand_top, sand_bot = C("#efcd92"), C("#c99a5e")
        hill = C("#5a6a9a")
        cloud_cols = [C("#f8ecd8"), C("#fff6e8")]
    elif phase == 1:    # full sunset
        sky = [(0.0, C("#241a4e")), (0.32, C("#6a2a70")),
               (0.58, C("#d24a64")), (0.80, C("#ff8a4a")),
               (1.0, C("#ffd07a"))]
        sea_top, sea_bot = C("#5a3466"), C("#221a44")
        sand_top, sand_bot = C("#b07a56"), C("#6e4638")
        hill = C("#3a2448")
        cloud_cols = [C("#d85a70"), C("#ffb07a")]
    else:               # night
        sky = [(0.0, C("#040414")), (0.45, C("#0a1030")),
               (0.78, C("#1c2048")), (1.0, C("#35305e"))]
        sea_top, sea_bot = C("#0a1430"), C("#050a1e")
        sand_top, sand_bot = C("#3a2e42"), C("#201828")
        hill = C("#141428")
        cloud_cols = [C("#2a3058"), C("#3a3f6a")]

    vgrad(cv, 0, 126, sky)

    # stars at night
    if phase == 2:
        for _ in range(70):
            x, y = rnd.randint(0, W - 1), rnd.randint(2, 112)
            b = rnd.choice([C("#8a96c8"), C("#c8d4ff"), C("#5a6490")])
            cv.px(x, y, b)
            if rnd.random() < 0.12:
                cv.rect(x, y, 2, 1, b)

    # soft cloud bands
    for i in range(5):
        cy = 28 + i * 15 + rnd.randint(-3, 3)
        cx = rnd.randint(-20, 360)
        cw = rnd.randint(60, 150)
        cv.rect(cx, cy, cw, 1, cloud_cols[0])
        cv.rect(cx + 6, cy + 1, cw - 14, 1, cloud_cols[1])
        cv.rect(cx + 14, cy + 2, cw - 30, 1, cloud_cols[0])
        for xx in range(cx, min(W, cx + cw)):
            if (xx * 7 + i) % 11 == 0:
                cv.px(xx, cy - 1, cloud_cols[1])

    # distant headlands on the horizon
    cv.poly([(0, 126), (0, 104), (18, 100), (38, 108), (58, 102), (82, 112),
             (96, 126)], hill)
    cv.poly([(300, 126), (320, 110), (342, 106), (360, 112), (384, 104),
             (384, 126)], hill)
    if phase < 2:
        for x in range(24, 80, 7):
            cv.line(x, 112, x + 2, 104, mix(hill, C("#101020"), 0.35))
        for x in range(322, 372, 8):
            cv.line(x, 116, x + 2, 108, mix(hill, C("#101020"), 0.35))

    # ocean
    for y in range(126, 160):
        t = (y - 126) / 33
        cv.rect(0, y, W, 1, mix(sea_top, sea_bot, t))
    # shimmer dashes, denser near the horizon
    for y in range(128, 158, 2):
        for _ in range(10):
            x = rnd.randint(0, W - 1)
            ln = rnd.randint(2, 9)
            col = mix(sea_top, C("#ffffff"), 0.35 if phase < 2 else 0.18)
            cv.rect(x, y, ln, 1, col)
    # sun / moon reflection column
    if phase < 2:
        cxr = 282
        for y in range(128, 158):
            wdt = max(2, 20 - (y - 128) // 2)
            for _ in range(3):
                x = cxr - wdt // 2 + rnd.randint(0, wdt)
                cv.rect(x, y, rnd.randint(2, 6), 1,
                        C("#ffd27a") if phase == 1 else C("#ffe9bd"))
    else:
        for y in range(128, 156, 3):
            cv.rect(274 + (y % 7), y, 9, 1, C("#2a3560"))

    # beach
    for y in range(160, H):
        t = (y - 160) / (H - 160)
        cv.rect(0, y, W, 1, mix(sand_top, sand_bot, t))
    dither_band(cv, 0, 164, W, 10, [sand_top, mix(sand_top, sand_bot, 0.35)],
                seed=5 + phase, p=0.22)
    # wet sand line + foam marks
    cv.rect(0, 160, W, 2, mix(sand_top, C("#ffffff"), 0.35))
    for _ in range(26):
        x = rnd.randint(0, W - 1)
        cv.rect(x, 161 + rnd.randint(0, 2), rnd.randint(3, 12), 1,
                C("#fff4dc") if phase < 2 else C("#6a6a92"))
    # shells / pebbles
    for _ in range(18):
        x, y = rnd.randint(6, W - 8), rnd.randint(170, 208)
        col = C("#fff0d0") if rnd.random() < 0.5 else C("#8a6a5a")
        cv.px(x, y, col)
        if rnd.random() < 0.4:
            cv.px(x + 1, y, col)

    # subtle vignette/edge tint
    for y in range(H):
        if y > 198:
            cv.rect(0, y, W, 1, mix(C("#1a1020"), sand_bot, (y - 198) / 18))
    cv.save(f"assets/environments/endings/{name}.png")
    print("ending bg", name)


def pingu_sun():
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for r, a in ((30, 12), (24, 20), (19, 32), (15, 52)):
        d.ellipse([32 - r, 32 - r, 32 + r, 32 + r], fill=(255, 196, 110, a))
    d.ellipse([22, 22, 42, 42], fill=(255, 214, 120, 255))
    d.ellipse([25, 25, 39, 39], fill=(255, 242, 190, 255))
    d.ellipse([28, 28, 34, 34], fill=(255, 255, 235, 255))
    im.save(out_path("assets/environments/endings/pingu_sun.png"))
    print("pingu sun")


def pingu_clouds():
    im = Image.new("RGBA", (W, 56), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rnd = random.Random(21)
    for _ in range(7):
        cx, cy = rnd.randint(0, W - 1), rnd.randint(10, 42)
        for i in range(rnd.randint(3, 6)):
            w = rnd.randint(18, 44)
            h = rnd.randint(3, 7)
            x = cx + rnd.randint(-24, 24)
            y = cy + rnd.randint(-5, 5)
            col = (255, 236, 210, rnd.randint(45, 95))
            wrap_dash(d, x, y, w, h, col)
            wrap_dash(d, x + 4, y + h, w - 8, 2, (255, 250, 235, 60))
    im.save(out_path("assets/environments/endings/pingu_clouds.png"))
    print("pingu clouds")


def pingu_waves():
    im = Image.new("RGBA", (W, 30), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rnd = random.Random(33)
    for _ in range(46):
        x = rnd.randint(0, W - 1)
        y = rnd.randint(0, 28)
        ln = rnd.randint(3, 16)
        a = rnd.randint(40, 130)
        wrap_dash(d, x, y, ln, 1, (210, 240, 255, a))
        if rnd.random() < 0.3:
            wrap_dash(d, x + 2, y + 1, max(2, ln - 4), 1, (255, 255, 255, a // 2))
    im.save(out_path("assets/environments/endings/pingu_waves.png"))
    print("pingu waves")


def pingu_foam():
    im = Image.new("RGBA", (W, 10), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rnd = random.Random(44)
    for _ in range(34):
        x = rnd.randint(0, W - 1)
        y = rnd.randint(0, 5)
        ln = rnd.randint(5, 22)
        wrap_dash(d, x, y, ln, 1, (255, 250, 240, rnd.randint(70, 150)))
        if rnd.random() < 0.5:
            wrap_dash(d, x + 3, y + 1, max(2, ln - 5), 1, (255, 255, 255, 60))
    im.save(out_path("assets/environments/endings/pingu_foam.png"))
    print("pingu foam")


def pingu_palm():
    cv = Canvas(64, 112)
    dark = C("#160f1e")
    rim = C("#c46a44")
    # curved trunk
    for i in range(58):
        t = i / 57
        x = 34 - int(10 * t * t)
        y = 110 - i
        wdt = 5 - int(2 * t)
        cv.rect(x, y, wdt, 1, dark)
        if i % 16 == 0:
            cv.rect(x, y, 1, 1, C("#5a3a32"))
        if i % 6 == 0:
            cv.rect(x + wdt - 1, y, 1, 1, C("#3a2830"))
    # bushy fronds: a dark core wedge with a warm rim on the sunset side
    topx, topy = 24, 50
    for ang, ln in ((-2.9, 25), (-2.5, 30), (-2.1, 30), (-1.7, 27),
                    (-1.3, 30), (-0.9, 26), (-0.4, 28), (0.1, 22), (-3.3, 19)):
        ex = int(topx + math.cos(ang) * ln)
        ey = int(topy + math.sin(ang) * ln * 0.55)
        cv.line(topx, topy, ex, ey, dark)
        cv.line(topx, topy + 1, ex, ey + 1, dark)
        for k in range(2, ln, 2):
            t = k / ln
            lx = int(topx + (ex - topx) * t)
            ly = int(topy + (ey - topy) * t)
            thick = 2 if t < 0.55 else 1
            cv.rect(lx, ly - thick, thick + 1, thick * 2 + 1, dark)
            if t < 0.85 and k % 4 == 0:
                cv.px(lx + 1, ly - thick, C("#7a4a3a"))
        cv.px(ex, ey, rim)
        cv.px(ex - 1, ey, C("#8a4a3a"))
    cv.ellipse(topx, topy, 4, 3, dark)
    cv.px(topx - 1, topy + 2, C("#5a3a2a"))
    cv.px(topx + 2, topy + 2, C("#5a3a2a"))
    cv.save("assets/environments/endings/pingu_palm.png")
    print("pingu palm")


def pingu_birds():
    frames = []
    for f in range(3):
        cv = Canvas(8, 6)
        col = C("#241a33")
        if f == 0:
            cv.line(1, 3, 3, 1, col); cv.line(3, 1, 4, 3, col)
            cv.line(4, 3, 5, 1, col); cv.line(5, 1, 7, 3, col)
        elif f == 1:
            cv.line(1, 2, 3, 3, col); cv.line(3, 3, 4, 2, col)
            cv.line(4, 2, 5, 3, col); cv.line(5, 3, 7, 2, col)
        else:
            cv.line(1, 3, 3, 4, col); cv.line(3, 4, 4, 3, col)
            cv.line(4, 3, 5, 4, col); cv.line(5, 4, 7, 3, col)
        frames.append(cv.im)
    pack({"fly": frames}, {"fly": {"cell": [8, 6], "fps": 7, "loop": True}},
         "assets/environments/endings/pingu_birds.png")
    print("pingu birds")


# ---------------------------------------------------------------------------
# Miggy — winter apartment
# ---------------------------------------------------------------------------
def miggy_room():
    cv = Canvas(W, H)
    rnd = random.Random(77)
    # wall
    for y in range(0, 176):
        t = y / 175
        cv.rect(0, y, W, 1, mix(C("#0b0916"), C("#1d1730"), t))
    for x in range(0, W, 48):
        cv.line(x, 0, x, 174, C("#141024"))
    for x in range(24, W, 48):
        for y in range(8, 168, 24):
            cv.px(x, y, C("#252040"))
    # floor
    for y in range(176, H):
        t = (y - 176) / 40
        cv.rect(0, y, W, 1, mix(C("#2c1f2e"), C("#170f1b"), t))
    for i in range(-2, 11):
        cv.line(i * 42, 176, i * 42 - 22, H, C("#211626"))
    cv.rect(0, 172, W, 5, C("#120c1a"))
    cv.rect(0, 172, W, 1, C("#3c2c46"))

    # ── window ─────────────────────────────────────────────────────────────
    cv.rect(10, 12, 92, 78, C("#2a2036"))
    cv.frame_rect(10, 12, 92, 78, C("#4a3858"))
    cv.rect(16, 18, 80, 66, C("#070b20"))
    for y in range(18, 84):
        t = (y - 18) / 65
        cv.rect(18, y, 76, 1, mix(C("#060a1e"), C("#18244a"), t))
    # distant snowy roofs and a lamppost
    cv.poly([(18, 78), (30, 58), (44, 76), (58, 60), (74, 78), (94, 64),
             (94, 84), (18, 84)], C("#141a38"))
    cv.rect(70, 58, 1, 22, C("#2a3058"))
    cv.ellipse(70, 56, 2, 2, C("#c8a060"))
    for _ in range(24):
        x, y = rnd.randint(19, 92), rnd.randint(19, 80)
        cv.px(x, y, C("#8ea4d8"))
    # mullions + sill + snow
    cv.rect(54, 18, 2, 66, C("#4a3858"))
    cv.rect(16, 50, 80, 2, C("#4a3858"))
    cv.rect(12, 88, 90, 4, C("#5a4468"))
    cv.rect(12, 88, 90, 1, C("#c8d8ff"))
    # curtains
    cv.rect(6, 14, 8, 76, C("#221a30"))
    cv.rect(98, 14, 8, 76, C("#221a30"))

    # ── shelf + books ──────────────────────────────────────────────────────
    cv.rect(108, 64, 68, 3, C("#4a3650"))
    cv.rect(108, 64, 68, 1, C("#7a5a7a"))
    bx = 110
    for i in range(9):
        w = rnd.randint(3, 6)
        h = rnd.randint(10, 20)
        col = [C("#6a4a8a"), C("#2a5a7a"), C("#8a5a3a"), C("#3a6a4a"),
               C("#8a3a4a")][i % 5]
        cv.rect(bx, 64 - h, w, h, col)
        cv.rect(bx, 64 - h, w, 1, mix(col, C("#ffffff"), 0.25))
        bx += w + 1
    # little plant
    cv.rect(170, 56, 5, 8, C("#5a3a2a"))
    for dx, dy in ((-2, 0), (2, 0), (0, -3), (-3, -3), (3, -2)):
        cv.rect(172 + dx, 52 + dy, 2, 3, C("#3a7a4a"))

    # ── posters ────────────────────────────────────────────────────────────
    cv.rect(104, 16, 66, 34, C("#dfe8f4"))
    cv.frame_rect(104, 16, 66, 34, C("#3a4a70"))
    text(cv, 108, 21, "WORKS", C("#1a2a4a"), 1)
    text(cv, 108, 29, "WITH", C("#1a2a4a"), 1)
    text(cv, 108, 37, "MONO", C("#7a3fe8"), 1)

    cv.rect(292, 18, 54, 30, C("#1a1730"))
    cv.frame_rect(292, 18, 54, 30, C("#5a4a7a"))
    text(cv, 298, 24, "GODOT", C("#6ec72c"), 1)
    text(cv, 298, 34, "INSIDE", C("#2de3ff"), 1)

    # sticky notes
    for i, (x, y, col) in enumerate([(180, 20, C("#f7e94b")),
                                     (190, 30, C("#ff9a5a")),
                                     (205, 22, C("#7ae0a0"))]):
        cv.rect(x, y, 9, 9, col)
        cv.rect(x + 1, y + 2, 6, 1, C("#6a6a50"))
        cv.rect(x + 1, y + 5, 4, 1, C("#6a6a50"))

    # ── chair ──────────────────────────────────────────────────────────────
    cv.rect(96, 132, 84, 46, C("#231a2c"))
    cv.rect(102, 138, 72, 34, C("#2e2338"))
    cv.rect(102, 138, 72, 2, C("#3e3048"))
    cv.rect(110, 176, 6, 34, C("#1a1422"))
    cv.rect(158, 176, 6, 34, C("#1a1422"))
    cv.ellipse(113, 210, 5, 2, C("#120c1a"))
    cv.ellipse(161, 210, 5, 2, C("#120c1a"))

    # ── desk ───────────────────────────────────────────────────────────────
    cv.rect(198, 160, 174, 10, C("#8a6448"))
    cv.rect(198, 160, 174, 2, C("#b08a62"))
    cv.rect(198, 170, 174, 36, C("#4a3028"))
    cv.rect(200, 172, 170, 2, C("#5e3e32"))
    cv.rect(202, 176, 2, 30, C("#2e1e1a"))
    cv.rect(362, 176, 2, 30, C("#2e1e1a"))
    # drawers
    cv.rect(342, 176, 24, 12, C("#5e3e32"))
    cv.rect(344, 178, 20, 8, C("#6e4a3a"))
    cv.rect(350, 181, 8, 1, C("#c8a060"))

    # monitor bezels (screens are separate animated sprites)
    def bezel(x, y, sw, sh):
        cv.rect(x - 5, y - 5, sw + 10, sh + 10, C("#14121c"))
        cv.frame_rect(x - 5, y - 5, sw + 10, sh + 10, C("#2e2a3a"))
        cv.rect(x - 1, y - 1, sw + 2, sh + 2, C("#05050a"))
        cv.rect(x + sw // 2 - 6, y + sh + 5, 12, 3, C("#1e1a28"))
        cv.rect(x + sw // 2 - 10, y + sh + 8, 20, 2, C("#14111c"))
        cv.px(x + sw + 2, y + sh + 2, C("#6ec72c"))

    bezel(206, 112, 44, 34)     # left
    bezel(258, 100, 64, 44)     # main
    bezel(334, 120, 36, 30)     # right

    # keyboard
    cv.rect(202, 163, 72, 7, C("#2a2634"))
    cv.rect(202, 163, 72, 1, C("#4a4458"))
    for kx in range(204, 272, 4):
        cv.rect(kx, 165, 2, 2, C("#6a6478"))
    cv.rect(230, 168, 16, 1, C("#14121c"))

    # mug + books + gear on the desk
    cv.rect(286, 154, 9, 8, C("#c8c8d8"))
    cv.rect(286, 154, 9, 2, C("#e8e8f4"))
    cv.rect(295, 156, 3, 4, C("#c8c8d8"))
    cv.rect(312, 152, 22, 10, C("#3a5a7a"))
    cv.rect(312, 152, 22, 2, C("#5a8ab0"))
    cv.rect(314, 155, 12, 1, C("#c8d8e8"))
    cv.rect(300, 150, 8, 12, C("#6a3a5a"))
    cv.rect(302, 152, 4, 2, C("#f7e94b"))

    # desk lamp (left edge) + warm shade
    cv.rect(188, 140, 2, 22, C("#4a4458"))
    cv.rect(180, 136, 18, 6, C("#c8a060"))
    cv.rect(180, 142, 18, 2, C("#8a6a3a"))
    cv.rect(186, 160, 10, 2, C("#3a3040"))

    # cables / rug
    cv.rect(214, 206, 96, 3, C("#3a2a4a"))
    cv.rect(160, 206, 54, 3, C("#3a2a4a"))
    cv.line(230, 170, 236, 206, C("#241a30"))
    cv.line(300, 170, 292, 206, C("#241a30"))

    cv.save("assets/environments/endings/miggy_room.png")
    print("miggy room")


def lamp_glow():
    im = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for r in range(46, 2, -3):
        a = int(38 * (1 - r / 48) ** 1.6) + 4
        d.ellipse([48 - r, 48 - r, 48 + r, 48 + r], fill=(255, 196, 110, a))
    im.save(out_path("assets/environments/endings/miggy_lamp_glow.png"))
    print("lamp glow")


def snowflake():
    im = Image.new("RGBA", (4, 4), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.point((1, 1), fill=(235, 242, 255, 255))
    d.point((2, 1), fill=(210, 225, 255, 160))
    im.save(out_path("assets/environments/endings/miggy_snow.png"))
    print("snowflake")


def monitor(name, sw, sh, kind):
    frames = []
    offs = (0, 1, 2, 1) if kind != "godot" else (0, 0, 1, 1)
    for f in range(4):
        cv = Canvas(sw, sh)
        bg = C("#050810")
        cv.rect(0, 0, sw, sh, bg)
        cv.frame_rect(0, 0, sw, sh, C("#1e2430"))
        off = offs[f]
        if kind == "terminal":
            cv.rect(0, 0, sw, 6, C("#16322a"))
            text(cv, 2, 1, "ROOT", C("#6ec72c"), 1)
            for i in range((sh - 10) // 4 + 2):
                y = 8 + i * 4 - off
                if y < 6:
                    continue
                width = (sw - 8) - ((i * 7 + f * 3) % max(4, sw // 3))
                cv.rect(3, y, max(3, width), 1, C("#2e8a4a"))
                if i % 3 == 0:
                    cv.rect(3, y, max(2, width // 3), 1, C("#8ef0a8"))
            if f % 2 == 0:
                cv.rect(sw - 7, sh - 6, 4, 2, C("#6ec72c"))
        elif kind == "godot":
            cv.rect(0, 0, sw, 6, C("#20304a"))
            text(cv, 2, 1, "GODOT", C("#9adcff"), 1)
            cv.rect(0, 6, sw // 3, sh - 6, C("#121a28"))
            for i in range(6):
                cv.rect(2, 9 + i * 5, (sw // 3) - 4, 1, C("#2a4a6a"))
            cv.rect(sw // 3, 6, 1, sh - 6, C("#2a3a52"))
            # viewport grid
            for gx in range(sw // 3 + 4, sw - 3, 7):
                cv.line(gx, 10, gx, sh - 8, C("#10202e"))
            cv.rect(sw // 3 + 6, 14, sw // 3, sh // 3, C("#2a6a8a"))
            cv.rect(sw // 3 + 8, 16, sw // 3 - 4, sh // 3 - 4, C("#4a9aba"))
            # code lines
            for i in range(4):
                cv.rect(sw // 3 + 3, sh - 14 + i * 3, sw // 2, 1, C("#6a8ab0"))
            if f >= 2:
                cv.rect(sw // 3 + 3, sh - 8, 3, 3, C("#f7e94b"))
        else:
            cv.rect(0, 0, sw, 6, C("#241a3a"))
            text(cv, 2, 1, "MONO", C("#c77dff"), 1)
            # abstract runtime ring
            cx, cy = sw // 2, 17
            for r, col in ((9, C("#3a1a6a")), (6, C("#7a3fe8")), (3, C("#c77dff"))):
                cv.frame_rect(cx - r, cy - r, r * 2 + 1, r * 2 + 1, col)
            for i in range(3):
                cv.rect(4, sh - 14 + i * 3, max(6, sw - 12 - i * 5), 1, C("#7a5a9a"))
            # progress bar
            fillw = int((sw - 10) * (0.55 + f * 0.15))
            cv.rect(5, sh - 4, sw - 10, 2, C("#1e1230"))
            cv.rect(5, sh - 4, fillw, 2, C("#c77dff"))
        frames.append(cv.im)
    pack({"screen": frames},
         {"screen": {"cell": [sw, sh], "fps": 4, "loop": True}},
         f"assets/environments/endings/{name}.png")
    print("monitor", name)


if __name__ == "__main__":
    pingu_stage("pingu_beach_day", 0)
    pingu_stage("pingu_beach_sunset", 1)
    pingu_stage("pingu_beach_night", 2)
    pingu_sun()
    pingu_clouds()
    pingu_waves()
    pingu_foam()
    pingu_palm()
    pingu_birds()
    miggy_room()
    lamp_glow()
    snowflake()
    monitor("miggy_monitor_terminal", 44, 34, "terminal")
    monitor("miggy_monitor_godot", 64, 44, "godot")
    monitor("miggy_monitor_mono", 36, 30, "mono")
    print("endings art done")
