"""PINGUDOT art: tilesets, parallax backgrounds, level objects, the airplane.

Each area gets a 16px tilestrip (fixed tile IDs) + a 384x216 parallax sky.
"""
from common import Canvas, C, pack, shade, mix, out_path
from PIL import Image
import json, math, random

TILE = 16
N_TILES = 13
# tile ids (same order in every area tileset):
T_FLOOR_A, T_FLOOR_B, T_FLOOR_C, T_WALL_TOP, T_WALL_FACE, T_HAZARD, \
T_DECO, T_DECO2, T_EXIT, T_GATE, T_MACHINE, T_VOID = range(12)

AREAS = {
    "area1": {"floor": ["#f7d87a", "#efd06e", "#e8c45e"], "wall": ["#7a5a2a", "#5a3f1a"],
              "haz": "#2d9cd8", "deco": "#2aa02e", "mach": "#9aa4b2",
              "sky1": "#79c8f0", "sky2": "#f2f7d0", "void": "#0a0a12"},
    "area2": {"floor": ["#8a3038", "#7e2c34", "#93363e"], "wall": ["#c8b090", "#8a7050"],
              "haz": "#ff6a1f", "deco": "#d0d0d8", "mach": "#6a7280",
              "sky1": "#4a4460", "sky2": "#c87850", "void": "#120a14"},
    "area3": {"floor": ["#2a3a4a", "#243444", "#30404f"], "wall": ["#16202c", "#0a1018"],
              "haz": "#e2282e", "deco": "#2de3ff", "mach": "#3a5a6a",
              "sky1": "#060812", "sky2": "#102030", "void": "#04060c"},
    "area4": {"floor": ["#e6e6ea", "#dcdce2", "#f0f0f4"], "wall": ["#8ecff0", "#5a9ac0"],
              "haz": "#f7c94b", "deco": "#2de3ff", "mach": "#c0c8d0",
              "sky1": "#f09a4b", "sky2": "#ffd23e", "void": "#1a1033"},
    "area5": {"floor": ["#6a6a72", "#5e5e66", "#72727a"], "wall": ["#3a3a42", "#26262e"],
              "haz": "#f7e94b", "deco": "#ff3b3b", "mach": "#8a8f9a",
              "sky1": "#2a2050", "sky2": "#7a3fe8", "void": "#08080f"},
}

def dither(cv, x, y, w, h, ca, cb, seed=0, p=0.25):
    rnd = random.Random(seed)
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            cv.px(xx, yy, cb if rnd.random() < p else ca)

def tileset(area, spec):
    cv = Canvas(TILE * N_TILES, TILE)
    fl = [C(x) for x in spec["floor"]]
    wa = [C(x) for x in spec["wall"]]
    # floors: subtle dither variants
    cv.noisy_fill(0 * TILE, 0, TILE, TILE, [fl[0], fl[1]], [3, 1], seed=hash(area) % 999)
    cv.noisy_fill(1 * TILE, 0, TILE, TILE, [fl[1], fl[2]], [3, 1], seed=hash(area + "b") % 999)
    cv.rect(2 * TILE, 0, TILE, TILE, fl[2])
    cv.line(2 * TILE + 3, 0, 2 * TILE + 3, TILE - 1, shade(fl[2], 0.85))
    cv.line(2 * TILE + 8, 4, 2 * TILE + 8, TILE - 1, shade(fl[2], 1.1))
    # wall top (solid cap)
    cv.rect(3 * TILE, 0, TILE, TILE, wa[0])
    cv.frame_rect(3 * TILE, 0, TILE, TILE, wa[1])
    dither(cv, 3 * TILE + 2, 2, TILE - 4, TILE - 4, wa[0], wa[1], p=0.2)
    # wall face
    cv.rect(4 * TILE, 0, TILE, TILE, wa[1])
    cv.rect(4 * TILE, 0, TILE, 4, wa[0])
    for i in range(0, TILE, 4):
        cv.line(4 * TILE + i, 4, 4 * TILE + i, TILE, shade(wa[1], 0.7))
    # hazard: animated-looking energy / fire
    hc = C(spec["haz"])
    cv.rect(5 * TILE, 0, TILE, TILE, fl[0])
    for i in range(0, TILE, 2):
        cv.rect(5 * TILE + i, (i * 3) % TILE, 2, 2, hc)
    dither(cv, 5 * TILE, 0, TILE, TILE, fl[0], shade(hc, 0.6), p=0.15)
    # deco flat (graffiti / cables / coffee spills)
    dc = C(spec["deco"])
    cv.noisy_fill(6 * TILE, 0, TILE, TILE, [fl[0], fl[1]], [3, 1], seed=99)
    cv.line(6 * TILE + 2, 12, 6 * TILE + 6, 4, dc)
    cv.line(6 * TILE + 6, 4, 6 * TILE + 12, 9, dc)
    cv.px(6 * TILE + 12, 9, shade(dc, 1.4))
    # deco2
    cv.noisy_fill(7 * TILE, 0, TILE, TILE, [fl[1], fl[2]], [2, 1], seed=42)
    cv.rect(7 * TILE + 4, 5, 6, 5, C(spec["mach"]))
    cv.rect(7 * TILE + 5, 6, 4, 2, dc)
    # exit portal / door down
    cv.rect(8 * TILE, 0, TILE, TILE, C("#0a0a12"))
    cv.frame_rect(8 * TILE, 0, TILE, TILE, C(spec["deco"]))
    cv.poly([(8 * TILE + 8, 3), (8 * TILE + 12, 8), (8 * TILE + 4, 8)], C(spec["deco"]))
    cv.poly([(8 * TILE + 4, 10), (8 * TILE + 12, 10), (8 * TILE + 8, 14)], shade(C(spec["deco"]), 0.7))
    # gate (to boss / next area)
    cv.rect(9 * TILE, 0, TILE, TILE, C("#0a0a12"))
    for i in range(0, TILE, 4):
        cv.rect(9 * TILE + i, 0, 2, TILE, C(spec["mach"]))
    cv.rect(9 * TILE, 6, TILE, 2, C(spec["haz"]))
    # machine (save/crypto/vending base, 16x16 chunky box)
    m = C(spec["mach"])
    cv.rect(10 * TILE + 1, 2, 14, 13, m)
    cv.frame_rect(10 * TILE + 1, 2, 14, 13, shade(m, 0.6))
    cv.rect(10 * TILE + 3, 4, 10, 5, C("#101828"))
    cv.rect(10 * TILE + 4, 5, 6, 1, C(spec["deco"]))
    cv.rect(10 * TILE + 3, 11, 4, 2, shade(m, 1.3))
    # liquid (water for grid tile 9)
    lc = C("#2d8ce8")
    if spec.get("liquid"):
        lc = C(spec["liquid"])
    cv.rect(12 * TILE, 0, TILE, TILE, lc)
    for yy in range(0, TILE, 4):
        cv.line(12 * TILE, yy + 1, 12 * TILE + 15, yy + 1, shade(lc, 1.25))
        cv.rect(12 * TILE + 2 + ((yy * 3) % 11), yy, 3, 1, C("#ffffff"))
    # void
    cv.rect(11 * TILE, 0, TILE, TILE, C(spec["void"]))
    cv.save(f"assets/environments/tilesets/{area}.png")

def parallax(area, spec):
    cv = Canvas(384, 216)
    s1, s2 = C(spec["sky1"]), C(spec["sky2"])
    for yy in range(216):
        col = mix(s2, s1, yy / 215)
        cv.rect(0, yy, 384, 1, col)
    rnd = random.Random(hash(area) % 777)
    if area == "area1":
        # sun, sea band, distant sailboats
        cv.ellipse(300, 40, 18, 18, C("#ffd23e"))
        cv.ellipse(300, 40, 15, 15, C("#fff4d0"))
        cv.rect(0, 120, 384, 30, C("#1f6fd8"))
        dither(cv, 0, 120, 384, 6, C("#2d8ce8"), C("#6ecbff"), p=0.3)
        for i in range(6):
            x = 30 + i * 60 + rnd.randint(-8, 8)
            cv.poly([(x, 118), (x + 10, 118), (x + 5, 104)], C("#f2f2f2"))
        for i in range(24):
            x = i * 16
            cv.poly([(x, 216), (x + 8, 170 + rnd.randint(0, 14)), (x + 16, 216)], C("#2a7a2a"))
    elif area == "area2":
        # graveyard of office towers with 'GONE PUBLIC' neon
        for i in range(10):
            x = i * 40 + rnd.randint(-6, 6)
            h = 60 + rnd.randint(0, 60)
            cv.rect(x, 216 - h, 34, h, C("#2a2438"))
            for wy in range(216 - h + 6, 210, 10):
                for wx in range(x + 4, x + 30, 8):
                    cv.rect(wx, wy, 4, 5, C("#f7c94b") if rnd.random() < 0.3 else C("#171220"))
        cv.rect(150, 84, 70, 16, C("#120e1a"))
        cv.frame_rect(150, 84, 70, 16, C("#e2282e"))
        cv.noisy_fill(152, 86, 66, 12, [C("#e2282e")], seed=3)
    elif area == "area3":
        # server hall: racks with blinking LEDs
        for i in range(14):
            x = i * 28
            cv.rect(x, 60, 24, 156, C("#141c28"))
            cv.frame_rect(x, 60, 24, 156, C("#0a0f16"))
            for k in range(10):
                yy = 66 + k * 14
                cv.rect(x + 2, yy, 20, 4, C("#1e2836"))
                cv.px(x + 20, yy + 1, C("#6ec72c") if (i + k) % 3 else C("#ff3b3b"))
                cv.px(x + 22, yy + 2, C("#2de3ff"))
    elif area == "area4":
        # unicorn towers: glass,估值 signs, flying certificates
        for i in range(7):
            x = i * 56
            cv.rect(x + 4, 30 + (i % 3) * 16, 44, 216, C("#9adcff" if i % 2 else "#c8ecff"))
            cv.frame_rect(x + 4, 30 + (i % 3) * 16, 44, 216, C("#5a9ac0"))
            for wy in range(40 + (i % 3) * 16, 210, 12):
                cv.line(x + 6, wy, x + 46, wy, C("#7cc0e8"))
        for i in range(9):
            x, y = rnd.randint(20, 350), rnd.randint(20, 90)
            cv.rect(x, y, 10, 6, C("#f2f2f2"))
            cv.rect(x + 1, y + 1, 8, 1, C("#e2282e"))
    elif area == "area5":
        # night airport: hangars, runway lights, control tower, plane silhouette in hangar
        cv.rect(0, 150, 384, 66, C("#26262e"))
        for i in range(5):
            x = i * 80
            cv.poly([(x, 150), (x + 34, 118), (x + 68, 150)], C("#1a1a22"))
            cv.frame_rect(x + 8, 132, 52, 18, C("#3a3a42"))
        cv.rect(240, 80, 18, 70, C("#3a3a42"))
        cv.rect(234, 74, 30, 10, C("#2de3ff"))
        for i in range(24):
            cv.rect(i * 16 + 4, 168, 2, 2, C("#ffd23e") if i % 2 else C("#2de3ff"))
    cv.save(f"assets/environments/backgrounds/{area}_bg.png")

def objects():
    """Standalone 16/32px level objects: palms, desks, servers, signs, ATM, chests."""
    objs = {}

    def single(cv, name):
        objs[name] = [cv.im]

    # palm tree 32x48
    p = Canvas(32, 48)
    p.rect(14, 18, 4, 30, C("#8a5a2a"))
    for i in range(30, 48, 4): p.px(13, i, C("#6a4018")); p.px(18, i - 2, C("#6a4018"))
    for ang in (0.6, 1.6, 2.6, 3.7, 4.7, 5.7):
        x2, y2 = 16 + int(12 * math.cos(ang)), 14 + int(8 * math.sin(ang))
        p.poly([(16, 14), (x2, y2), (16 + int(9 * math.cos(ang + 0.4)), 14 + int(7 * math.sin(ang + 0.4)))], C("#2aa02e"))
    p.ellipse(16, 14, 3, 3, C("#6ec72c"))
    finish(p); single(p, "palm")
    # dead crypto ATM 16x24
    a = Canvas(16, 24)
    a.rect(1, 2, 14, 20, C("#8a8f9a")); a.frame_rect(1, 2, 14, 20, C("#4a4f58"))
    a.rect(3, 4, 10, 7, C("#101828"))
    a.rect(4, 6, 6, 1, C("#ff3b3b")); a.px(5, 8, C("#f7c94b"))
    a.rect(3, 14, 10, 2, C("#3a3f48")); a.rect(6, 18, 4, 2, C("#161616"))
    a.line(1, 2, 14, 21, C("#ff3b3b"))  # crack
    finish(a); single(a, "atm")
    # office desk 24x16
    d = Canvas(24, 16)
    d.rect(0, 6, 24, 4, C("#c8b090")); d.rect(0, 10, 3, 6, C("#8a7050")); d.rect(21, 10, 3, 6, C("#8a7050"))
    d.rect(8, 0, 8, 6, C("#3a3f48")); d.rect(9, 1, 6, 4, C("#2de3ff"))
    d.rect(17, 3, 3, 3, C("#f2f2f2"))  # coffee cup
    finish(d); single(d, "desk")
    # server rack 16x32
    s = Canvas(16, 32)
    s.rect(1, 0, 14, 32, C("#141c28")); s.frame_rect(1, 0, 14, 32, C("#2a3a4a"))
    for k in range(8):
        y = 2 + k * 4
        s.rect(2, y, 12, 3, C("#1e2836"))
        s.px(12, y + 1, C("#6ec72c") if k % 2 else C("#ff3b3b"))
    finish(s); single(s, "rack")
    # billboard 32x24
    b = Canvas(32, 24)
    b.rect(6, 12, 2, 12, C("#6a7280")); b.rect(24, 12, 2, 12, C("#6a7280"))
    b.rect(0, 0, 32, 13, C("#101828")); b.frame_rect(0, 0, 32, 13, C("#f7e94b"))
    b.rect(3, 3, 20, 2, C("#2de3ff")); b.rect(3, 7, 14, 2, C("#e2282e"))
    b.rect(24, 4, 5, 5, C("#6ec72c"))
    finish(b); single(b, "billboard")
    # treasure chest (swag box) 16x14
    t = Canvas(16, 14)
    t.rect(0, 4, 16, 10, C("#8a5a2a")); t.frame_rect(0, 4, 16, 10, C("#5a3a14"))
    t.rect(0, 0, 16, 5, C("#a06a30")); t.frame_rect(0, 0, 16, 5, C("#5a3a14"))
    t.rect(7, 3, 2, 4, C("#f7e94b"))
    finish(t); single(t, "chest")
    # checkpoint terminal 16x24
    c = Canvas(16, 24)
    c.rect(1, 4, 14, 18, C("#3a5a6a")); c.frame_rect(1, 4, 14, 18, C("#16202c"))
    c.rect(3, 6, 10, 8, C("#0a0f16"))
    c.poly([(8, 7), (11, 12), (5, 12)], C("#2de3ff"))  # penguin logo
    c.rect(3, 17, 10, 2, C("#9aa4b2"))
    c.px(12, 18, C("#6ec72c"))
    finish(c); single(c, "checkpoint")
    # vending machine 16x28
    v = Canvas(16, 28)
    v.rect(1, 0, 14, 27, C("#e2282e")); v.frame_rect(1, 0, 14, 27, C("#9c1018"))
    v.rect(3, 2, 8, 12, C("#101828"))
    for r in range(3):
        for cc in range(2):
            v.rect(3 + cc * 5, 2 + r * 5, 4, 4, C("#2de3ff") if (r + cc) % 2 else C("#f7e94b"))
    v.rect(11, 4, 3, 6, C("#f2f2f2"))
    v.rect(3, 18, 10, 3, C("#161616"))
    finish(v); single(v, "vendor")
    # office door 16x24 (locked exit)
    e = Canvas(16, 24)
    e.rect(1, 1, 14, 23, C("#8a5a2a")); e.frame_rect(1, 1, 14, 23, C("#5a3a14"))
    e.rect(3, 3, 10, 9, C("#6a4018")); e.px(12, 13, C("#f7e94b"))
    finish(e); single(e, "door")
    # coffee spill hazard decal 16x16
    h = Canvas(16, 16)
    h.ellipse(8, 8, 6, 4, C("#5a3a14")); h.ellipse(7, 7, 3, 2, C("#6a4526"))
    single(h, "spill")
    # gate bars 32x16
    g = Canvas(32, 16)
    g.rect(0, 0, 32, 2, C("#f7c94b")); g.rect(0, 4, 32, 2, C("#161616"))
    for i in range(0, 32, 8):
        g.rect(i, 0, 4, 2, C("#f7c94b")); g.rect(i + 4, 4, 4, 2, C("#f7c94b"))
    finish(g); single(g, "gate")

    import os
    base = "assets/environments/objects"
    names = []
    for name, frames in objs.items():
        frames[0].save(out_path(f"{base}/{name}.png"))
        names.append(name)
    with open(out_path(f"{base}/manifest.json"), "w") as f:
        json.dump({"objects": {n: {"cell": list(objs[n][0].size), "frames": 1} for n in names}}, f, indent=1)
    print("objects:", names)

def airplane():
    cv = Canvas(96, 40)
    # black triangular stealth jet with two bright blue lines
    cv.poly([(2, 22), (92, 12), (96, 16), (92, 20), (2, 26)], C("#0d0d12"))
    cv.poly([(6, 20), (40, 16), (30, 8), (18, 16)], C("#16161f"))  # wing back edge
    cv.poly([(20, 24), (52, 20), (46, 30), (24, 28)], C("#101018"))  # lower wing
    cv.poly([(86, 14), (94, 15), (90, 10)], C("#0d0d12"))  # nose tip
    cv.line(6, 21, 90, 15, C("#2de3ff"))
    cv.line(6, 23, 90, 17, C("#2de3ff"))
    cv.rect(2, 20, 2, 6, C("#0d0d12"))
    cv.ellipse(78, 18, 2, 1, C("#7a3fe8"))  # cockpit glow
    cv.rect(88, 15, 6, 1, C("#f7e94b"))
    finish(cv, (4, 4, 8))
    cv.save("assets/environments/airplane.png")
    # contrail puff + runway lights
    t = Canvas(32, 16)
    t.ellipse(8, 8, 6, 4, C("#ffffff")); t.ellipse(20, 8, 5, 3, C("#d0d8e8"))
    t.ellipse(27, 9, 3, 2, C("#a0b0c8"))
    t.save(out_path("assets/effects/contrail.png"))

def finish_unused(cv): pass

def finish(cv, col=(10, 10, 18)):
    cv.shade_bottom(0.78)
    cv.outline(col)
    return cv

if __name__ == "__main__":
    for area, spec in AREAS.items():
        tileset(area, spec)
        parallax(area, spec)
    objects()
    airplane()
