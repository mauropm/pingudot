"""PINGUDOT art: pixel font (BMFont), UI chrome, item icons, effects."""
from common import Canvas, C, pack, recolor, out_path, shade, mix
from PIL import Image, ImageDraw
import json, math

# ---------------------------------------------------------------------------
# 5x7 pixel font, packed into 6x8 cells
# ---------------------------------------------------------------------------
GLYPHS = {}
def G(ch, rows):
    GLYPHS[ch] = [int(r, 2) if isinstance(r, str) else r for r in rows]

# fmt: off
G(" ", ["000000","000000","000000","000000","000000","000000","000000"])
G("A", ["011100","100010","100010","111110","100010","100010","100010"])
G("B", ["111100","100010","100010","111100","100010","100010","111100"])
G("C", ["011110","100000","100000","100000","100000","100000","011110"])
G("D", ["111100","100010","100010","100010","100010","100010","111100"])
G("E", ["111110","100000","100000","111100","100000","100000","111110"])
G("F", ["111110","100000","100000","111100","100000","100000","100000"])
G("G", ["011110","100000","100000","101110","100010","100010","011110"])
G("H", ["100010","100010","100010","111110","100010","100010","100010"])
G("I", ["111110","001000","001000","001000","001000","001000","111110"])
G("J", ["001110","000100","000100","000100","000100","100100","111000"])
G("K", ["100010","100100","101000","110000","101000","100100","100010"])
G("L", ["100000","100000","100000","100000","100000","100000","111110"])
G("M", ["100010","110110","101010","101010","100010","100010","100010"])
G("N", ["100010","110010","101010","100110","100010","100010","100010"])
G("O", ["011100","100010","100010","100010","100010","100010","011100"])
G("P", ["111100","100010","100010","111100","100000","100000","100000"])
G("Q", ["011100","100010","100010","100010","101010","100100","011010"])
G("R", ["111100","100010","100010","111100","101000","100100","100010"])
G("S", ["011110","100000","100000","011100","000010","000010","111100"])
G("T", ["111110","001000","001000","001000","001000","001000","001000"])
G("U", ["100010","100010","100010","100010","100010","100010","011100"])
G("V", ["100010","100010","100010","100010","100010","010100","001000"])
G("W", ["100010","100010","100010","101010","101010","110110","100010"])
G("X", ["100010","100010","010100","001000","010100","100010","100010"])
G("Y", ["100010","100010","010100","001000","001000","001000","001000"])
G("Z", ["111110","000010","000100","001000","010000","100000","111110"])
G("0", ["011100","100010","100010","100010","100010","100010","011100"])
G("1", ["001000","011000","001000","001000","001000","001000","011100"])
G("2", ["111100","000010","000010","001100","010000","100000","111110"])
G("3", ["111100","000010","000010","011100","000010","000010","111100"])
G("4", ["000110","001010","010010","111110","000010","000010","000010"])
G("5", ["111110","100000","111100","000010","000010","100010","111100"])
G("6", ["011100","100000","100000","111100","100010","100010","111100"])
G("7", ["111110","000010","000100","001000","010000","010000","010000"])
G("8", ["111100","100010","100010","111100","100010","100010","111100"])
G("9", ["111100","100010","100010","111110","000010","000010","111100"])
G(".", ["000000","000000","000000","000000","000000","011000","011000"])
G(",", ["000000","000000","000000","000000","000000","011000","110000"])
G("!", ["001000","001000","001000","001000","001000","000000","001000"])
G("?", ["111100","000010","000100","001000","001000","000000","001000"])
G("'", ["011000","010000","000000","000000","000000","000000","000000"])
G('"', ["011010","011010","000000","000000","000000","000000","000000"])
G(":", ["000000","011000","011000","000000","011000","011000","000000"])
G(";", ["000000","011000","011000","000000","011000","110000","000000"])
G("/", ["000010","000100","000100","001000","010000","010000","100000"])
G("\\", ["100000","010000","010000","001000","000100","000100","000010"])
G("-", ["000000","000000","000000","111110","000000","000000","000000"])
G("+", ["000000","001000","001000","111110","001000","001000","000000"])
G("=", ["000000","000000","111110","000000","111110","000000","000000"])
G("_", ["000000","000000","000000","000000","000000","000000","111111"])
G("(", ["000100","001000","010000","010000","010000","001000","000100"])
G(")", ["010000","001000","000100","000100","000100","001000","010000"])
G("[", ["011100","010000","010000","010000","010000","010000","011100"])
G("]", ["001110","000100","000100","000100","000100","000100","001110"])
G("%", ["110010","110100","000100","001000","010000","010110","100110"])
G("$", ["001000","011110","101010","011100","101010","011110","001000"])
G("#", ["010100","111110","010100","010100","111110","010100","000000"])
G("&", ["011000","100100","101000","010100","101010","100100","011010"])
G("*", ["000000","101010","011100","111110","011100","101010","000000"])
G("@", ["011100","100010","101110","101010","101110","100000","011100"])
G("<", ["000100","001000","010000","100000","010000","001000","000100"])
G(">", ["010000","001000","000100","000010","000100","001000","010000"])
G("|", ["001000","001000","001000","001000","001000","001000","001000"])
G("~", ["000000","000000","010010","101100","000000","000000","000000"])
G("^", ["001000","010100","100010","000000","000000","000000","000000"])
G("{", ["001100","010000","010000","111000","010000","010000","001100"])
G("}", ["001100","000100","000100","000111","000100","000100","001100"])
for c in "abcdefghijklmnopqrstuvwxyz":
    if c in "jkqvy":
        continue
    G(c, GLYPHS[c.upper()])
G("k", ["100000","100000","100100","101000","110000","101000","100100"])
G("j", ["000100","000000","000100","000100","000100","100100","111000"])
G("v", ["000000","100010","100010","100010","010100","010100","001000"])
G("y", ["100010","100010","100010","111110","000010","000100","111000"])
G("q", ["011100","100010","100010","100010","011110","000010","000110"])
G("w", ["000000","100010","100010","101010","101010","110110","000000"])
G("m", ["000000","110110","101010","101010","100010","100010","000000"])
G("s", ["000000","011110","100000","011100","000010","111100","000000"])
G("x", ["000000","100010","010100","001000","010100","100010","000000"])
G("z", ["000000","111110","000100","001000","010000","111110","000000"])
G("t", ["010000","010000","111000","010000","010010","001100","000000"])
G("i", ["001000","000000","011000","001000","001000","001000","011100"])
G("l", ["011000","001000","001000","001000","001000","001000","011100"])
G("p", ["000000","111100","100010","111100","100000","100000","100000"])
G("b", ["100000","100000","111100","100010","100010","100010","111100"])
G("d", ["000010","000010","011110","100110","100010","100010","011110"])
G("g", ["000000","011110","100010","100010","111110","000010","111100"])
G("h", ["100000","100000","110100","101100","100100","100100","100100"])
G("n", ["000000","110100","101100","100100","100100","100100","100100"])
G("r", ["000000","101100","110000","100000","100000","100000","100000"])
G("u", ["000000","100010","100010","100010","100110","011010","000000"])
G("o", ["000000","011100","100010","100010","100010","011100","000000"])
G("a", ["000000","011100","000010","011110","100010","011110","000000"])
G("c", ["000000","011110","100000","100000","100000","011110","000000"])
G("e", ["000000","011100","100010","111110","100000","011100","000000"])
G("f", ["011100","100010","100000","111000","100000","100000","100000"])
# fmt: on

def gen_font():
    W = 6
    H = 8
    cols = 16
    rows = (127 - 32 + cols) // cols
    cv = Canvas(cols * W, rows * H)
    chars = []
    for code in range(32, 127):
        ch = chr(code)
        rows_b = GLYPHS.get(ch, GLYPHS.get(ch.upper(), None))
        if rows_b is None:
            continue
        idx = code - 32
        x0, y0 = (idx % cols) * W, (idx // cols) * H
        col = C("#ffffff")
        for ry in range(7):
            bits = rows_b[ry]
            for bx in range(6):
                if bits & (1 << (5 - bx)):
                    cv.px(x0 + bx, y0 + ry, col)
        chars.append((code, x0, y0, 6, 7))
    pw, ph = cv.im.size
    cv.im.save(out_path("assets/fonts/pixel6x8.png"))
    # Binary AngelCode BMFont v3 — the only format Godot's importer parses.
    import struct, hashlib
    png_hash = hashlib.sha1(cv.im.tobytes()).hexdigest()[:8]
    data = bytearray(b"BMF")
    data.append(3)
    name = ("Pixel6x8-" + png_hash).encode() + b"\x00"
    info = struct.pack("<h", 8) + bytes([0x40, 0x00]) + struct.pack("<H", 100) \
        + bytes([1]) + bytes(4) + bytes([0, 0]) + bytes([0]) + name
    data.append(1)
    data += struct.pack("<I", len(info)) + info
    common = struct.pack("<HH", H, 8) + struct.pack("<HH", pw, ph) \
        + struct.pack("<H", 1) + bytes([0, 0, 0, 0, 0])
    assert len(common) == 15
    data.append(2)
    data += struct.pack("<I", len(common)) + common
    pages = b"pixel6x8.png\x00"
    data.append(3)
    data += struct.pack("<I", len(pages)) + pages
    cbuf = b""
    for code, x0, y0, cw, chh in chars:
        w = 0 if code == 32 else cw
        cbuf += struct.pack("<I7hBB", code, x0, y0, w, chh, 0, 1, W, 0, 15)
    data.append(4)
    data += struct.pack("<I", len(cbuf)) + cbuf
    with open(out_path("assets/fonts/pixel6x8.fnt"), "wb") as f:
        f.write(bytes(data))
    with open(out_path("assets/fonts/pixel6x8.json"), "w") as f:
        json.dump({"cell": [W, H], "cols": cols,
                   "glyphs": {chr(c): [x, y, cw, 7] for c, x, y, cw, _ in chars}}, f)
    prev = Image.new("RGB", (pw, ph), (24, 18, 48))
    src = cv.im
    prev.paste(src, (0, 0), src)
    prev.save("/tmp/font_preview.png")

# ---------------------------------------------------------------------------
# UI chrome
# ---------------------------------------------------------------------------
INK = C("#101828"); PAPER = C("#f2f2f2"); BLUE = C("#2a5ad0"); LBLUE = C("#8ecff0")
RED = C("#e2282e"); GREEN = C("#2aa02e"); GOLD = C("#f7c94b"); PURPLE = C("#7a3fe8")
DARK = C("#16121f")

def ui():
    # 9-slice dialog frame (inner 16px, border 8px) — classic SNES white/blue box
    f = Canvas(48, 48)
    f.rect(0, 0, 48, 48, INK)
    f.rect(2, 2, 44, 44, BLUE)
    f.rect(4, 4, 40, 40, PAPER)
    f.rect(6, 6, 36, 36, mix(PAPER, LBLUE, 0.35))
    f.frame_rect(6, 6, 36, 36, LBLUE)
    f.px(1, 1, C("#8ecff0")); f.px(46, 1, C("#8ecff0")); f.px(1, 46, C("#8ecff0")); f.px(46, 46, C("#8ecff0"))
    f.save("assets/ui/panel.png")
    # dark variant (menus)
    d = Canvas(48, 48)
    d.rect(0, 0, 48, 48, C("#000000"))
    d.rect(2, 2, 44, 44, PURPLE)
    d.rect(4, 4, 40, 40, C("#241a40"))
    d.frame_rect(6, 6, 36, 36, C("#5a3fe8"))
    d.px(1, 1, LBLUE); d.px(46, 1, LBLUE); d.px(1, 46, LBLUE); d.px(46, 46, LBLUE)
    d.save("assets/ui/panel_dark.png")
    # dialogue window: deep blue SNES-style box with white text
    q = Canvas(48, 48)
    q.rect(0, 0, 48, 48, C("#0a0818"))
    q.rect(1, 1, 46, 46, C("#e8eef8"))
    q.rect(2, 2, 44, 44, C("#2a3a8a"))
    q.rect(4, 4, 40, 40, C("#16205a"))
    q.frame_rect(5, 5, 38, 38, C("#3a4aa8"))
    q.px(0, 0, C("#ffffff")); q.px(47, 0, C("#ffffff"))
    q.px(0, 47, C("#ffffff")); q.px(47, 47, C("#ffffff"))
    q.save("assets/ui/panel_dialogue.png")
    # red variant (game over / boss)
    r = Canvas(48, 48)
    r.rect(0, 0, 48, 48, INK)
    r.rect(2, 2, 44, 44, C("#6a0f0f"))
    r.rect(4, 4, 40, 40, C("#380a12"))
    r.frame_rect(6, 6, 36, 36, RED)
    r.save("assets/ui/panel_red.png")
    # cursor arrow
    cu = Canvas(12, 14)
    cu.poly([(2, 1), (2, 11), (4.5, 9), (6, 13), (8, 12), (6.5, 8.5), (10, 8)], PAPER)
    cu.poly([(2, 2), (2, 9), (8, 7)], INK)
    cu.outline(); cu.save("assets/ui/cursor.png")
    # bar back + fills (10x10 nine-patch-ish; game stretches)
    for name, base, light, dark in [
        ("bar_back", C("#101018"), C("#2a2a3a"), C("#000000")),
        ("bar_hp", C("#2aa02e"), C("#6ec72c"), C("#14501a")),
        ("bar_en", C("#2a5ad0"), C("#2de3ff"), C("#142a80")),
        ("bar_xp", C("#f7c94b"), C("#fff4d0"), C("#a0781a")),
        ("bar_enemy", C("#e2282e"), C("#ff8c6b"), C("#7a1010")),
    ]:
        b = Canvas(10, 10)
        b.rect(0, 0, 10, 10, dark)
        b.rect(1, 1, 8, 8, base)
        b.rect(1, 1, 8, 2, light)
        b.rect(1, 8, 8, 1, shade(base, 0.6))
        b.save(f"assets/ui/{name}.png")
    # coin icon 10x10 + big coin
    for sz, nm in ((10, "coin"), (16, "coin_big")):
        c = Canvas(sz, sz)
        c.ellipse(sz // 2, sz // 2, sz // 2 - 1, sz // 2 - 1, GOLD)
        c.ellipse(sz // 2, sz // 2, sz // 2 - 2, sz // 2 - 2, shade(GOLD, 0.82))
        c.rect(sz // 2 - 1, sz // 2 - 2, 2, 5, GOLD)
        c.outline((INK)); c.save(f"assets/ui/{nm}.png")
    # heart
    h = Canvas(12, 10)
    h.ellipse(4, 4, 3, 3, RED); h.ellipse(8, 4, 3, 3, RED)
    h.poly([(1, 5), (11, 5), (6, 10)], RED)
    h.px(3, 3, C("#ff8c8c"))
    h.outline((INK)); h.save("assets/ui/heart.png")
    # energy cell
    e = Canvas(10, 12)
    e.rect(1, 2, 8, 9, C("#101828")); e.frame_rect(1, 2, 8, 9, C("#9aa4b2"))
    e.rect(3, 0, 4, 2, C("#9aa4b2"))
    e.rect(2, 6, 6, 4, C("#2de3ff")); e.rect(3, 7, 2, 2, C("#ffffff"))
    e.outline((INK)); e.save("assets/ui/energy.png")
    # trophy (achievements)
    t = Canvas(14, 14)
    t.rect(4, 2, 6, 5, GOLD); t.poly([(3, 2), (11, 2), (7, 8)], GOLD)
    t.rect(6, 7, 2, 3, shade(GOLD, 0.8)); t.rect(4, 10, 6, 2, shade(GOLD, 0.8))
    t.px(3, 3, C("#fff4d0")); t.outline((INK)); t.save("assets/ui/trophy.png")
    # star for bonus
    st = Canvas(12, 12)
    pts = []
    for i in range(10):
        ang = -math.pi / 2 + i * math.pi / 5
        rr = 5.5 if i % 2 == 0 else 2.3
        pts.append((6 + rr * math.cos(ang), 6 + rr * math.sin(ang)))
    st.poly(pts, GOLD); st.outline((INK)); st.save("assets/ui/star.png")
    # button plate
    bp = Canvas(40, 16)
    bp.rect(0, 0, 40, 16, INK); bp.rect(1, 1, 38, 13, C("#2a5ad0"))
    bp.rect(1, 1, 38, 2, C("#5a8af0")); bp.rect(1, 12, 38, 2, C("#1a3a90"))
    bp.save("assets/ui/button.png")
    # selector hand (menu)
    sh = Canvas(16, 12)
    sh.rect(1, 4, 10, 4, GOLD); sh.rect(11, 5, 3, 2, GOLD)
    sh.rect(3, 2, 2, 2, GOLD); sh.rect(6, 1, 2, 3, GOLD); sh.rect(9, 2, 2, 2, GOLD)
    sh.outline((INK)); sh.save("assets/ui/hand.png")
    # key (root access) icon
    k = Canvas(12, 12)
    k.ellipse(4, 6, 3, 3, GOLD); k.ellipse(4, 6, 1, 1, INK)
    k.rect(6, 5, 5, 2, GOLD); k.rect(9, 7, 1, 2, GOLD); k.rect(11, 7, 1, 2, GOLD)
    k.outline((INK)); k.save("assets/ui/key.png")

# ---------------------------------------------------------------------------
# ability icons + effects
# ---------------------------------------------------------------------------
def icons_effects():
    # ability icons 16x16
    kp = Canvas(16, 16)
    kp.rect(1, 3, 14, 10, INK); kp.frame_rect(1, 3, 14, 10, C("#8a8f9a"))
    kp.rect(3, 5, 10, 6, C("#e2282e"))
    kp.rect(4, 6, 8, 1, C("#ffffff")); kp.rect(4, 8, 6, 1, C("#ffb0b0"))
    kp.rect(5, 13, 6, 2, C("#8a8f9a"))
    kp.outline((INK)); kp.im.save(out_path("assets/ui/ability_kernelpanic.png"))
    fb = Canvas(16, 16)
    for ang in (0, math.pi * 0.66, math.pi * 1.33):
        x, y = 8 + int(4 * math.cos(ang)), 8 + int(4 * math.sin(ang))
        fb.rect(x - 1, y - 1, 3, 3, C("#d0d0d8"))
        fb.rect(x - 2, y - 2, 1, 1, C("#f2f2f2")); fb.rect(x + 2, y - 2, 1, 1, C("#f2f2f2"))
        fb.px(x, y + 2, C("#8a8f9a"))
    fb.outline((INK)); fb.im.save(out_path("assets/ui/ability_forkbomb.png"))
    ra = Canvas(16, 16)
    ra.ellipse(5, 8, 4, 4, GOLD); ra.ellipse(5, 8, 2, 2, INK)
    ra.rect(8, 7, 7, 2, GOLD); ra.rect(12, 9, 1, 3, GOLD); ra.rect(14, 9, 1, 3, GOLD)
    ra.px(3, 5, C("#fff4d0"))
    ra.outline((INK)); ra.im.save(out_path("assets/ui/ability_root.png"))
    sf = Canvas(16, 16)
    sf.rect(2, 2, 12, 12, C("#241a40")); sf.frame_rect(2, 2, 12, 12, C("#5a3fe8"))
    sf.rect(4, 5, 8, 1, C("#2de3ff")); sf.rect(4, 7, 5, 1, C("#e2282e"))
    sf.poly([(10, 8), (14, 12), (8, 12)], C("#f7e94b"))
    sf.outline((INK)); sf.im.save(out_path("assets/ui/ability_segfault.png"))
    # small status icons
    for nm, col in (("status_bslue", C("#2d6aff")), ("status_port", C("#f7c94b")),
                    ("status_smell", C("#6ec72c")), ("status_license", C("#e2282e"))):
        s = Canvas(10, 10)
        s.ellipse(5, 5, 4, 4, col); s.ellipse(5, 5, 2, 2, shade(col, 1.5))
        s.outline((INK)); s.im.save(out_path(f"assets/ui/{nm}.png"))

    def emit(name, frames, fps, loop, cell):
        sheets.setdefault(name, {})[name] = frames
        anims.setdefault(name, {})[name] = {"cell": list(cell), "fps": fps, "loop": loop}

    sheets, anims = {}, {}
    # fireball 8x8 x4
    fr = []
    for i, r in enumerate((3, 3, 4, 4)):
        b = Canvas(8, 8)
        b.ellipse(4, 4, r, r, C("#ff8c14"))
        b.ellipse(4, 4, r - 1, r - 1, C("#ffd23e"))
        b.ellipse(3, 3, 1, 1, C("#ffffff"))
        b.shade_bottom(0.8); b.outline((120, 30, 0)); fr.append(b.im)
    emit("fireball", fr, 12, True, (8, 8))
    # floppy disc projectile 12x12 x2
    fr = []
    for k in range(2):
        b = Canvas(12, 12)
        b.rect(1, 1, 10, 10, C("#2d6aff")); b.frame_rect(1, 1, 10, 10, C("#101828"))
        b.rect(3, 1 + k, 6, 3, C("#c8c8d0")); b.rect(5, 1 + k, 2, 2, C("#101828"))
        b.rect(3, 7, 6, 3, C("#f2f2f2"))
        b.outline((INK)); fr.append(b.im)
    emit("disc", fr, 12, True, (12, 12))
    # segfault shard 12x12 x2
    fr = []
    for k in range(2):
        b = Canvas(12, 12)
        b.poly([(2, 8 + k), (6, 2), (10, 8 + k), (6, 10)], C("#7a3fe8"))
        b.poly([(4, 7), (6, 3), (8, 7)], C("#c77dff"))
        b.outline((INK)); fr.append(b.im)
    emit("shard", fr, 12, True, (12, 12))
    # slash arc 32x32 x4
    fr = []
    for k in range(4):
        b = Canvas(32, 32)
        for i in range(3):
            a0 = math.radians(220 + k * 25 + i * 6)
            a1 = math.radians(320 + k * 25 + i * 6)
            rr = 14 - i * 3
            pts = [(16 + rr * math.cos(a0), 16 + rr * math.sin(a0))]
            for st in range(9):
                aa = a0 + (a1 - a0) * st / 8
                pts.append((16 + rr * math.cos(aa), 16 + rr * math.sin(aa)))
            for t in range(len(pts) - 1):
                b.line(int(pts[t][0]), int(pts[t][1]), int(pts[t + 1][0]), int(pts[t + 1][1]),
                       C("#ffffff") if k < 2 else C("#c8c8d0"))
        b.outline((90, 90, 120)); fr.append(b.im)
    emit("slash", fr, 16, False, (32, 32))
    # hit spark 12x12 x4
    fr = []
    for k in range(4):
        b = Canvas(12, 12)
        col = [C("#ffffff"), C("#ffd23e"), C("#ff8c14"), C("#e2282e")][k]
        for ang in range(8):
            a = ang * math.pi / 4
            r0, r1 = (2 + k * 2, 6 + k * 2)
            b.line(int(6 + r0 * math.cos(a)), int(6 + r0 * math.sin(a)),
                   int(6 + r1 * math.cos(a)), int(6 + r1 * math.sin(a)), col)
        b.outline((120, 40, 0)); fr.append(b.im)
    emit("spark", fr, 18, False, (12, 12))
    # explosion 20x20 x5
    fr = []
    for k in range(5):
        b = Canvas(20, 20)
        r = 3 + k * 2
        cols = [C("#fff4d0"), C("#ffd23e"), C("#ff8c14"), C("#e2282e"), C("#6a0f0f")]
        c1, c2 = cols[min(k, 4)], cols[min(k + 1, 4)]
        b.ellipse(10, 10, r, r, c2)
        if k < 3:
            b.ellipse(10, 10, max(1, r - 3), max(1, r - 3), c1)
        b.outline((60, 20, 0)); fr.append(b.im)
    emit("boom", fr, 14, False, (20, 20))
    # stink puff 12x12 x4
    fr = []
    for k in range(4):
        b = Canvas(12, 12)
        for i in range(3):
            ang = k * 0.8 + i * 2.1
            b.ellipse(6 + int(3 * math.cos(ang)), 6 + int(3 * math.sin(ang)), 3, 2,
                      C("#6ec72c") if i % 2 else C("#9aff5e"))
        b.outline((40, 90, 20)); fr.append(b.im)
    emit("stink", fr, 8, True, (12, 12))
    # text wave (hipster rant) 16x16 x2
    fr = []
    for k in range(2):
        b = Canvas(16, 16)
        for r in range(0, 16, 4):
            for c0 in range(0, 16, 3):
                if (r + c0 + k) % 6 < 3:
                    b.rect(c0, r, 2, 2, C("#c8c8d0"))
        b.outline((INK)); fr.append(b.im)
    emit("wavetext", fr, 10, True, (16, 16))
    # blue screen flash 32x32
    b = Canvas(32, 32)
    b.rect(0, 0, 32, 32, C("#1030c8"))
    b.rect(6, 10, 20, 2, C("#ffffff")); b.rect(6, 15, 14, 2, C("#d0d0f8")); b.rect(6, 19, 17, 2, C("#d0d0f8"))
    b.outline((INK)); 
    emit("bsod", [b.im], 6, True, (32, 32))
    # mini penguin clone for fork bomb 16x16 x2 (walk cycle simplified)
    fr = []
    for k in range(2):
        b = Canvas(16, 16)
        b.ellipse(8, 9, 4, 5, C("#15151f"))
        b.ellipse(8, 10, 2.5, 3.5, C("#f2f2f2"))
        b.ellipse(8, 4, 3, 3, C("#15151f"))
        b.px(7, 3, C("#ffffff")); b.px(9, 3, C("#ffffff"))
        b.poly([(6, 5), (10, 5), (8, 7)], C("#ff9a1f"))
        b.rect(4 - k, 14, 3, 1, C("#ff8c14")); b.rect(9 + k, 14, 3, 1, C("#ff8c14"))
        b.outline((INK)); fr.append(b.im)
    emit("clone", fr, 8, True, (16, 16))
    # levelup ring 32x32 x4
    fr = []
    for k in range(4):
        b = Canvas(32, 32)
        r = 4 + k * 3
        for ang in range(8):
            a = ang * math.pi / 4 + k * 0.2
            b.rect(int(16 + r * math.cos(a)), int(16 + r * math.sin(a)), 2, 2,
                   C("#fff4d0") if k % 2 else C("#f7e94b"))
        b.outline((140, 110, 0)); fr.append(b.im)
    emit("ring", fr, 10, False, (32, 32))

    for fam in sheets:
        pack(sheets[fam], anims[fam], f"assets/effects/{fam}.png")

# ---------------------------------------------------------------------------
# item icons 16x16 (keyed by id in items.json)
# ---------------------------------------------------------------------------
def item_icon(kind):
    b = Canvas(16, 16)
    if kind == "keyboard":
        b.rect(1, 5, 14, 8, C("#3a3f48")); b.frame_rect(1, 5, 14, 8, C("#16161f"))
        for r in range(2):
            for c0 in range(6):
                b.rect(2 + c0 * 2, 6 + r * 3, 2, 2, C("#d0d0d8"))
        b.rect(2, 3, 2, 2, C("#ff3b3b")); b.rect(12, 3, 2, 2, C("#2de3ff"))
    elif kind == "armor":
        b.poly([(3, 2), (13, 2), (13, 8), (8, 14), (3, 8)], C("#2d6aff"))
        b.poly([(5, 4), (11, 4), (11, 8), (8, 11), (5, 8)], C("#8ecff0"))
        b.rect(7, 5, 2, 4, C("#ffffff"))
    elif kind == "cable":
        b.rect(1, 3, 3, 3, C("#9aa4b2")); b.rect(12, 10, 3, 3, C("#9aa4b2"))
        for i in range(3):
            b.line(2, 6, 6 + i * 2, 12, C("#2aa02e"))
        b.line(4, 9, 12, 11, C("#6ec72c"))
    elif kind == "boots":
        b.rect(3, 2, 4, 7, C("#8a5a2a")); b.rect(3, 9, 8, 4, C("#6a4018"))
        b.rect(1, 13, 10, 2, C("#16161f"))
        b.rect(8, 4, 3, 5, C("#2d6aff")); b.rect(9, 8, 4, 3, C("#1640a0"))
        b.rect(10, 11, 4, 2, C("#16161f"))
    elif kind == "kernel":
        b.ellipse(8, 8, 6, 6, C("#e2282e")); b.ellipse(8, 8, 4, 4, C("#ff8c6b"))
        b.rect(7, 1, 2, 3, C("#16161f")); b.rect(3, 2, 2, 2, C("#16161f")); b.rect(11, 2, 2, 2, C("#16161f"))
        b.rect(2, 11, 12, 2, C("#16161f"))  # "unpatched" warning stripe
    elif kind == "gpu":
        b.rect(1, 4, 14, 8, C("#2a2a3a")); b.frame_rect(1, 4, 14, 8, C("#6a7280"))
        b.ellipse(5, 8, 2.5, 2.5, C("#9aa4b2")); b.rect(9, 6, 3, 4, C("#f7c94b"))
        b.px(13, 5, C("#ff3b3b"))
    elif kind == "coffee":
        b.rect(3, 4, 8, 9, C("#f2f2f2")); b.frame_rect(3, 4, 8, 9, C("#8a8f9a"))
        b.rect(4, 5, 6, 3, C("#6a4526"))
        b.rect(11, 6, 2, 4, C("#c8c8d0"))
        b.px(5, 2, C("#d0d0d8")); b.px(7, 1, C("#d0d0d8"))
    elif kind == "energy":
        b.rect(4, 1, 8, 14, C("#101828")); b.frame_rect(4, 1, 8, 14, C("#2de3ff"))
        b.poly([(8, 3), (5, 8), (8, 8), (7, 13), (11, 7), (8, 7)], C("#f7e94b"))
    elif kind == "patch":
        b.rect(2, 6, 12, 4, C("#9aa4b2"))
        b.rect(6, 2, 4, 12, C("#9aa4b2"))
        b.rect(7, 3, 2, 10, C("#6a7280")); b.rect(3, 7, 10, 2, C("#6a7280"))
    elif kind == "usb":
        b.rect(4, 2, 8, 10, C("#e2282e")); b.frame_rect(4, 2, 8, 10, C("#9c1018"))
        b.rect(5, 4, 6, 3, C("#f7e94b")); b.rect(6, 12, 4, 2, C("#c8c8d0"))
    elif kind == "router":
        b.rect(1, 8, 14, 5, C("#3a3f48")); b.rect(2, 9, 12, 1, C("#16161f"))
        for i in range(5):
            b.px(3 + i * 2, 11, C("#6ec72c"))
        b.rect(2, 2, 1, 6, C("#16161f")); b.rect(12, 3, 1, 5, C("#16161f"))
    elif kind == "ring":
        b.ellipse(8, 9, 5, 5, C("#f7c94b")); b.ellipse(8, 9, 3, 3, C("#241a40"))
        b.poly([(6, 4), (10, 4), (8, 1)], C("#2de3ff"))
    elif kind == "hat":
        b.poly([(2, 12), (14, 12), (12, 3), (6, 2)], C("#6a4526"))
        b.rect(1, 12, 14, 2, C("#7a5230"))
        b.poly([(4, 6), (6, 5), (5, 8)], C("#9aff5e"))
    elif kind == "sticker":
        b.rect(2, 4, 12, 8, C("#f2f2f2")); b.frame_rect(2, 4, 12, 8, C("#8a8f9a"))
        b.poly([(5, 10), (8, 5), (11, 10)], C("#2d6aff"))
    elif kind == "mouse":
        b.ellipse(8, 8, 5, 6, C("#c8c8d0")); b.line(8, 3, 8, 8, C("#8a8f9a"))
        b.rect(7, 2, 2, 2, C("#ff3b3b"))
    elif kind == "monitor":
        b.rect(1, 3, 14, 9, C("#16161f")); b.frame_rect(1, 3, 14, 9, C("#6a7280"))
        b.rect(2, 4, 12, 7, C("#0a2010"))
        b.rect(3, 5, 6, 1, C("#6ec72c")); b.rect(3, 7, 9, 1, C("#6ec72c"))
        b.rect(6, 12, 4, 2, C("#6a7280"))
    elif kind == "card":
        b.rect(1, 4, 14, 9, C("#241a40")); b.frame_rect(1, 4, 14, 9, C("#5a3fe8"))
        b.rect(2, 6, 5, 4, C("#f7c94b"))
        b.rect(8, 10, 6, 1, C("#c77dff"))
    elif kind == "box":
        b.poly([(2, 6), (8, 3), (14, 6), (8, 9)], C("#a06a30"))
        b.poly([(2, 6), (2, 12), (8, 15), (8, 9)], C("#8a5a2a"))
        b.poly([(14, 6), (14, 12), (8, 15), (8, 9)], C("#6a4018"))
    elif kind == "fish":
        b.ellipse(7, 8, 5, 4, C("#8ecff0")); b.poly([(12, 8), (15, 5), (15, 11)], C("#2d6aff"))
        b.px(4, 7, C("#16161f")); b.line(5, 9, 8, 10, C("#5a9ac0"))
    else:
        b.rect(2, 2, 12, 12, C("#8a8f9a"))
    b.outline((INK))
    return b.im

ITEM_KINDS = {
    # id -> icon kind
    "kb_legendary": "keyboard", "armor_gnu": "armor", "cable_10gbe": "cable",
    "boots_root": "boots", "kernel_unpatched": "kernel", "gpu_cheap": "gpu",
    "coffee": "coffee", "ram_up": "energy", "ssd_boost": "router", "mouse_ergo": "mouse",
    "usb_sticky": "usb", "ring_admin": "ring", "hat_censor": "hat",
    "sticker_gpl": "sticker", "monitor_curve": "monitor", "card_honor": "card",
    "box_swag": "box", "fish_frozen": "fish", "cookie": "patch", "wifi_router": "router",
    "heal_small": "coffee", "heal_big": "box", "en_small": "energy", "en_big": "energy",
    "patch_software": "patch", "boot_disk": "usb", "dodge_tonic": "energy",
}

def items():
    for iid, kind in ITEM_KINDS.items():
        item_icon(kind).save(out_path(f"assets/ui/items/{iid}.png"))
    # rarity borders for inventory slots
    for nm, col in (("slot_common", C("#8a8f9a")), ("slot_rare", C("#2d6aff")),
                    ("slot_epic", C("#7a3fe8")), ("slot_legendary", C("#f7c94b"))):
        s = Canvas(20, 20)
        s.rect(0, 0, 20, 20, C("#101018"))
        s.frame_rect(1, 1, 18, 18, col)
        s.px(0, 0, shade(col, 1.5)); s.px(19, 0, shade(col, 1.5))
        s.px(0, 19, shade(col, 0.6)); s.px(19, 19, shade(col, 0.6))
        s.save(f"assets/ui/{nm}.png")

def title_card():
    # Big chunky PINGUDOT logotype, 256x96
    txt = "PINGUDOT"
    scale = 6
    gw = 6
    canvas = Image.new("RGBA", (288, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(canvas)
    total_w = len(txt) * gw * scale
    x0 = (288 - total_w) // 2
    y0 = 8
    for ci, ch in enumerate(txt):
        rows = GLYPHS[ch]
        ox = x0 + ci * gw * scale
        for ry in range(7):
            bits = rows[ry]
            for bx in range(6):
                if bits & (1 << (5 - bx)):
                    # gradient fill orange->yellow per row
                    t = ry / 6.0
                    col = mix(C("#f08000"), C("#f7e94b"), t)
                    d.rectangle([ox + bx * scale, y0 + ry * scale,
                                 ox + bx * scale + scale - 1, y0 + ry * scale + scale - 1],
                                fill=col + (255,))
        # drop shadow
        for ry in range(7):
            bits = rows[ry]
            for bx in range(6):
                if bits & (1 << (5 - bx)):
                    d.point((ox + bx * scale + scale, y0 + ry * scale + scale), (10, 8, 20, 255))
    cv = Canvas.from_image(canvas)
    cv.save("assets/ui/title.png")
    # small "16-bit" tagline strip
    tag = Image.new("RGBA", (288, 16), (0, 0, 0, 0))
    td = ImageDraw.Draw(tag)
    t = "MISSION: SILICON VALLEY TO OAXACA"
    tx = 8
    for ch in t:
        rows = GLYPHS.get(ch.upper())
        if rows:
            for ry in range(7):
                bits = rows[ry]
                for bx in range(6):
                    if bits & (1 << (5 - bx)):
                        td.point((tx + bx, 4 + ry), (45, 227, 255, 255))
            tx += 7
        else:
            tx += 7
    tag.save(out_path("assets/ui/tagline.png"))


if __name__ == "__main__":
    gen_font()
    ui()
    icons_effects()
    items()
    title_card()
    print("ui + font + effects done")
