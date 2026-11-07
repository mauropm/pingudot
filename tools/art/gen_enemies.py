"""PINGUDOT art: enemy families + CTO boss.

Outputs one atlas + manifest per family under res://assets/enemies/.
Elite variants are palette remaps of the base frames.
"""
from common import Canvas, C, pack, recolor, shade, mix
from PIL import Image
import math

def finish(cv, outline_col=(10, 10, 18)):
    cv.shade_bottom(0.78)
    cv.outline(outline_col)
    return cv.im

# ---------------------------------------------------------------------------
# BSDemon — red port-obsessed imp with boots and a flame tail
# ---------------------------------------------------------------------------
D_RED = C("#e2282e"); D_RED_D = C("#9c1018"); D_HORN = C("#f7e94b")
D_EYE = C("#fff4d0"); D_MOUTH = C("#3a0a0a"); BOOT = C("#161616")
D_TAIL = C("#ff8c14"); D_TAIL2 = C("#ffd23e")

def bsdemon(p):
    cv = Canvas(24, 24)
    cx = 12 + p.get("lean", 0)
    bob = p.get("bob", 0)
    body = D_RED
    if p.get("hurt"):
        body = C("#ffffff")
    # flame tail
    f = p.get("tail", 0)
    cv.poly([(cx + 7, 16), (cx + 11, 13 - f), (cx + 9, 17), (cx + 12, 16 - f)], D_TAIL)
    cv.poly([(cx + 8, 16), (cx + 10, 14 - f)], D_TAIL2)
    # boots
    by = 21
    cv.rect(cx - 6 + p.get("legL", 0), by - 3, 4, 3, BOOT)
    cv.rect(cx - 7 + p.get("legL", 0), by - 1, 5, 2, BOOT)
    cv.rect(cx + 2 - p.get("legR", 0), by - 3, 4, 3, BOOT)
    cv.rect(cx + 2 - p.get("legR", 0), by - 1, 5, 2, BOOT)
    cv.rect(cx - 6 + p.get("legL", 0), by - 1, 5, 1, C("#4a4a4a"))
    cv.rect(cx + 2 - p.get("legR", 0), by - 1, 5, 1, C("#4a4a4a"))
    # arms
    if p.get("cast"):
        cv.line(cx - 8, 12 + bob, cx - 11, 8 + bob, body)
        cv.line(cx + 8, 12 + bob, cx + 11, 8 + bob, body)
    else:
        cv.line(cx - 7, 13 + bob, cx - 9, 16 + bob, body)
        cv.line(cx + 7, 13 + bob, cx + 9, 16 + bob, body)
    # body+head: one imp blob
    cv.ellipse(cx, 13 + bob, 6, 6, body)
    cv.ellipse(cx, 16 + bob, 5, 4, body)
    # horns
    cv.poly([(cx - 4, 7 + bob), (cx - 6, 3 + bob), (cx - 2, 8 + bob)], D_HORN)
    cv.poly([(cx + 4, 7 + bob), (cx + 6, 3 + bob), (cx + 2, 8 + bob)], D_HORN)
    # pointy ears
    cv.poly([(cx - 6, 11 + bob), (cx - 9, 10 + bob), (cx - 6, 13 + bob)], body)
    cv.poly([(cx + 6, 11 + bob), (cx + 9, 10 + bob), (cx + 6, 13 + bob)], body)
    # eyes (mischievous)
    if p.get("hurt"):
        cv.px(cx - 2, 11 + bob, D_MOUTH); cv.px(cx + 2, 11 + bob, D_MOUTH)
    else:
        cv.rect(cx - 3, 10 + bob, 2, 2, D_EYE)
        cv.rect(cx + 2, 10 + bob, 2, 2, D_EYE)
        cv.px(cx - 3, 11 + bob, D_MOUTH); cv.px(cx + 2, 11 + bob, D_MOUTH)
        cv.line(cx - 4, 9 + bob, cx - 1, 10 + bob, D_RED_D)
        cv.line(cx + 4, 9 + bob, cx + 1, 10 + bob, D_RED_D)
    # grin with fangs
    cv.line(cx - 3, 14 + bob, cx + 3, 14 + bob, D_MOUTH)
    cv.poly([(cx - 2, 14), (cx - 1, 14), (cx - 1, 16)], WHITE := C("#ffffff"))
    cv.poly([(cx + 2, 14), (cx + 1, 14), (cx + 1, 16)], WHITE)
    if p.get("cast"):
        # fireball in hand
        cv.ellipse(cx + 11, 7 + bob, 2, 2, D_TAIL2)
        cv.ellipse(cx + 11, 7 + bob, 1, 1, WHITE)
    if p.get("fork"):
        for dx, dy in ((-8, -6), (8, -6), (0, -9)):
            cv.rect(cx + dx, 12 + dy, 1, 3, C("#d0d0d8"))
            cv.rect(cx + dx - 1, 12 + dy, 3, 1, C("#d0d0d8"))
    return cv

# ---------------------------------------------------------------------------
# Little Bill — tiny body, enormous head, premium everything
# ---------------------------------------------------------------------------
B_SKIN = C("#f2c295"); B_HAIR = C("#8c6a4a"); B_WHITE = C("#f2f2f2")
B_SHIRT = C("#dcdcdc"); B_DOT = C("#9a9a9a"); B_PANTS = C("#2a2a3a")
B_GOLD = C("#f7c94b"); B_GOLD_D = C("#c08a10"); B_BLUE = C("#2de3ff")
B_LENS = C("#2de3ff")

def littlebill(p):
    cv = Canvas(24, 24)
    cx = 12 + p.get("lean", 0)
    bob = p.get("bob", 0)
    if p.get("hurt"):
        cv.ellipse(cx, 8 + bob, 6, 5, C("#ffffff"))
        cv.px(cx - 2, 8, C("#303030")); cv.px(cx + 2, 8, C("#303030"))
        cv.rect(cx - 3, 16, 6, 5, B_PANTS)
        return cv
    # legs (short!)
    cv.rect(cx - 3 + p.get("legL", 0), 20, 2, 3, B_PANTS)
    cv.rect(cx + 1 - p.get("legR", 0), 20, 2, 3, B_PANTS)
    cv.rect(cx - 4 + p.get("legL", 0), 22, 3, 1, C("#161616"))
    cv.rect(cx + 1 - p.get("legR", 0), 22, 3, 1, C("#161616"))
    # tiny torso: white dotted tee
    cv.rect(cx - 4, 15 + bob, 8, 5, B_SHIRT)
    for dx in (-3, 0, 3):
        cv.px(cx + dx, 16 + bob, B_DOT)
        cv.px(cx + dx, 18 + bob, B_DOT)
    # tiny arms
    if p.get("raise"):
        cv.rect(cx - 6, 12 + bob, 2, 3, B_SKIN)
        cv.rect(cx + 4, 12 + bob, 2, 3, B_SKIN)
    else:
        cv.rect(cx - 6, 15 + bob, 2, 4, B_SKIN)
        cv.rect(cx + 4, 15 + bob, 2, 4, B_SKIN)
    # enormous head
    cv.ellipse(cx, 9 + bob, 6, 6, B_SKIN)
    cv.ellipse(cx, 6 + bob, 5, 2, B_HAIR)          # slick hair cap
    cv.rect(cx - 6, 8 + bob, 2, 2, B_HAIR)          # side hair
    cv.rect(cx + 4, 8 + bob, 2, 2, B_HAIR)
    # big glasses
    cv.frame_rect(cx - 5, 7 + bob, 4, 4, C("#d4a017"))
    cv.frame_rect(cx + 1, 7 + bob, 4, 4, C("#d4a017"))
    cv.rect(cx - 4, 8 + bob, 2, 2, B_LENS)
    cv.rect(cx + 2, 8 + bob, 2, 2, B_LENS)
    cv.line(cx - 1, 9 + bob, cx + 1, 9 + bob, C("#d4a017"))
    # smirk
    cv.line(cx - 1, 13 + bob, cx + 2, 12 + bob, C("#a06848"))
    if p.get("wallet"):
        # comically oversized wallet
        cv.rect(cx + 5, 10 + bob, 9, 7, B_GOLD)
        cv.frame_rect(cx + 5, 10 + bob, 9, 7, B_GOLD_D)
        cv.rect(cx + 6, 11 + bob, 7, 2, C("#fff4d0"))
        cv.px(cx + 9, 14 + bob, B_GOLD_D)
    if p.get("screen"):
        # blue screen tablet
        cv.rect(cx - 14, 6 + bob, 8, 6, C("#1040ff"))
        cv.frame_rect(cx - 14, 6 + bob, 8, 6, C("#2de3ff"))
        cv.rect(cx - 12, 8 + bob, 4, 1, C("#ffffff"))
    return cv

# ---------------------------------------------------------------------------
# GPL Hipster — beard, hoodie energy, stink aura
# ---------------------------------------------------------------------------
H_HAIR = C("#6a4526"); H_SKIN = C("#e8b98a"); H_BLACK = C("#191922")
H_BEARD = C("#7a5230"); H_GREEN = C("#6ec72c"); H_EYE = C("#30303a")

def gplhipster(p):
    cv = Canvas(24, 24)
    cx = 12 + p.get("lean", 0)
    bob = p.get("bob", 0)
    if p.get("hurt"):
        cv.ellipse(cx, 12, 6, 7, C("#ffffff"))
        return cv
    # legs
    cv.rect(cx - 3 + p.get("legL", 0), 19, 2, 4, H_BLACK)
    cv.rect(cx + 1 - p.get("legR", 0), 19, 2, 4, H_BLACK)
    cv.rect(cx - 4 + p.get("legL", 0), 22, 4, 1, C("#3a3a3a"))
    cv.rect(cx + 1 - p.get("legR", 0), 22, 4, 1, C("#3a3a3a"))
    # torso: black GPL tee
    cv.rect(cx - 5, 13 + bob, 10, 7, H_BLACK)
    cv.rect(cx - 3, 15 + bob, 1, 3, C("#f2f2f2"))  # G
    cv.rect(cx - 1, 15 + bob, 1, 3, C("#f2f2f2")); cv.rect(cx - 1, 15 + bob, 2, 1, C("#f2f2f2"))  # P
    cv.rect(cx + 2, 15 + bob, 1, 3, C("#f2f2f2")); cv.rect(cx + 2, 18 + bob, 2, 1, C("#f2f2f2"))  # L
    # arms
    if p.get("rant"):
        cv.line(cx - 6, 14 + bob, cx - 9, 10 + bob, H_SKIN)
    else:
        cv.rect(cx - 6, 13 + bob, 2, 6, H_BLACK)
    cv.rect(cx + 5, 13 + bob, 2, 6, H_BLACK)
    # head
    cv.ellipse(cx, 9 + bob, 5, 5, H_SKIN)
    # unkempt beard
    cv.poly([(cx - 5, 9 + bob), (cx + 5, 9 + bob), (cx + 4, 15 + bob), (cx, 16 + bob), (cx - 4, 15 + bob)], H_BEARD)
    cv.rect(cx - 2, 11 + bob, 4, 1, C("#c08a60"))
    if p.get("rant"):
        cv.rect(cx - 1, 11 + bob, 2, 2, C("#3a0a0a"))  # open yelling mouth
    # messy hair
    for dx, dy in ((-5, -2), (-3, -4), (0, -5), (3, -4), (5, -2), (2, -2), (-2, -1)):
        cv.rect(cx + dx, 6 + bob + dy, 2, 3, H_HAIR)
    # tired eyes
    cv.rect(cx - 3, 8 + bob, 2, 1, H_EYE)
    cv.rect(cx + 2, 8 + bob, 2, 1, H_EYE)
    # stink cloud
    t = p.get("stink", 0)
    for i in range(3 + p.get("stinkN", 0)):
        ang = t * 0.7 + i * 2.3
        sx = int(cx + 7 * math.cos(ang))
        sy = int(8 + 4 * math.sin(ang * 0.6)) - (i * 3 % 5)
        cv.ellipse(sx, sy, 2, 1, mix(H_GREEN, C("#9aff5e"), (i % 3) / 2))
    if p.get("waves"):
        for i in range(3):
            cv.rect(cx + 6 + i * 3, 8 - i, 2, 1, C("#ffffff"))
            cv.rect(cx + 6 + i * 3 + 1, 10 - i, 1, 1, C("#d0d0d8"))
    return cv

# ---------------------------------------------------------------------------
# Corporate Security Bot — Area 2 mook
# ---------------------------------------------------------------------------
S_BODY = C("#8a8f9a"); S_DARK = C("#4a4f58"); S_RED = C("#ff3b3b")

def secbot(p):
    cv = Canvas(24, 24)
    cx = 12 + p.get("lean", 0); bob = p.get("bob", 0)
    if p.get("hurt"):
        cv.rect(cx - 6, 8, 12, 12, C("#ffffff"))
        return cv
    # wheels
    cv.ellipse(cx - 4, 21, 3, 2, S_DARK)
    cv.ellipse(cx + 4, 21, 3, 2, S_DARK)
    # body
    cv.rect(cx - 6, 11 + bob, 12, 9, S_BODY)
    cv.frame_rect(cx - 6, 11 + bob, 12, 9, S_DARK)
    cv.rect(cx - 4, 14 + bob, 8, 2, S_DARK)
    # head / visor
    cv.rect(cx - 5, 6 + bob, 10, 5, S_BODY)
    vis = S_RED if not p.get("blink") else C("#ffb0b0")
    cv.rect(cx - 4, 8 + bob, 8, 2, vis)
    cv.px(cx - 2, 8 + bob, C("#ffffff")); cv.px(cx + 2, 8 + bob, C("#ffffff"))
    # antenna
    cv.rect(cx, 2 + bob, 1, 4, S_DARK)
    cv.rect(cx - 1, 1 + bob, 3, 1, C("#f7e94b"))
    if p.get("zap"):
        cv.rect(cx + 6, 12 + bob, 3, 2, C("#2de3ff"))
        cv.line(cx + 9, 13 + bob, cx + 12, 12 + bob, C("#ffffff"))
    return cv

# ---------------------------------------------------------------------------
# THE CTO OF EVERYTHING — final boss
# ---------------------------------------------------------------------------
T_SUIT = C("#2a2a3a"); T_SHIRT = C("#f2f2f2"); T_TIE = C("#e2282e")
T_SKIN = C("#f2c295"); T_METAL = C("#9aa4b2"); T_CYAN = C("#2de3ff")

def cto(p):
    cv = Canvas(56, 56)
    cx = 28 + p.get("lean", 0); bob = p.get("bob", 0)
    suit = p.get("suit", T_SUIT); phase = p.get("phase", 1)
    # mechanical arms
    for sgn in (-1, 1):
        x = cx + 11 * sgn
        cv.rect(x - 1, 24 + bob, 2, 8, T_METAL)
        cv.rect(x - 2, 30 + bob, 4, 3, C("#5a626e"))
        if p.get("raise", 0) > 0:
            cv.rect(x - 2, 18 + bob, 4, 4, C("#5a626e"))
    # legs
    cv.rect(cx - 6, 44, 5, 8, suit)
    cv.rect(cx + 1, 44, 5, 8, suit)
    cv.rect(cx - 7, 51, 6, 2, C("#161616"))
    cv.rect(cx + 1, 51, 6, 2, C("#161616"))
    # torso: huge executive body
    cv.poly([(cx - 11, 44), (cx + 11, 44), (cx + 9, 24 + bob), (cx - 9, 24 + bob)], suit)
    cv.poly([(cx - 4, 24 + bob), (cx + 4, 24 + bob), (cx + 2, 40), (cx - 2, 40)], T_SHIRT)
    cv.poly([(cx - 2, 25 + bob), (cx + 2, 25 + bob), (cx, 38)], T_TIE)
    cv.px(cx, 27 + bob, C("#ffd23e"))
    # giant head
    cv.ellipse(cx, 14 + bob, 10, 10, T_SKIN)
    cv.ellipse(cx, 10 + bob, 8, 4, shade(T_SKIN, 1.15))  # shiny bald spot
    # brows & eyes
    if phase >= 2:
        cv.rect(cx - 7, 12 + bob, 4, 2, T_CYAN)
        cv.rect(cx + 3, 12 + bob, 4, 2, T_CYAN)
        if phase == 3:
            cv.rect(cx - 7, 12 + bob, 4, 2, C("#ff3b3b"))
            cv.rect(cx + 3, 12 + bob, 4, 2, C("#ff3b3b"))
    else:
        cv.rect(cx - 6, 12 + bob, 3, 2, C("#20202a"))
        cv.rect(cx + 3, 12 + bob, 3, 2, C("#20202a"))
    cv.line(cx - 8, 9 + bob, cx - 3, 10 + bob, C("#605040"))
    cv.line(cx + 8, 9 + bob, cx + 3, 10 + bob, C("#605040"))
    # mouth: smug line / yelling
    if p.get("yell"):
        cv.ellipse(cx, 19 + bob, 3, 2, C("#5a1a1a"))
    else:
        cv.line(cx - 3, 19 + bob, cx + 3, 19 + bob, C("#a06848"))
    # earpieces / headset
    cv.rect(cx - 11, 13 + bob, 2, 5, T_METAL)
    cv.rect(cx + 9, 13 + bob, 2, 5, T_METAL)
    # floating screens behind
    if p.get("screens"):
        for sx, sy, wgt in ((2, 20, 12), (42, 16, 10), (44, 34, 8)):
            cv.rect(sx, sy, wgt, 8, C("#101828"))
            cv.frame_rect(sx, sy, wgt, 8, T_METAL)
            cv.rect(sx + 2, sy + 2, wgt - 5, 1, T_CYAN if phase != 3 else C("#ff8c14"))
            cv.rect(sx + 2, sy + 4, wgt - 3, 1, C("#6a7280"))
    # laptop in right claw
    if p.get("laptop"):
        cv.rect(cx + 10, 20 + bob, 12, 7, C("#3a3f48"))
        cv.rect(cx + 11, 21 + bob, 10, 5, C("#101828"))
        cv.rect(cx + 12, 22 + bob, 6, 1, T_CYAN)
    # thrown slide (PowerPoint)
    if p.get("slide"):
        sx, sy = p["slide"]
        cv.rect(sx, sy, 10, 7, C("#f2f2f2"))
        cv.frame_rect(sx, sy, 10, 7, C("#8a8f9a"))
        cv.rect(sx + 2, sy + 1, 6, 2, C("#2de3ff"))
        cv.rect(sx + 2, sy + 4, 5, 1, C("#9aa4b2"))
        cv.rect(sx + 3, sy + 5, 4, 1, C("#9aa4b2"))
    if p.get("summon"):
        cv.ellipse(cx, 46, 12, 3, T_CYAN)
    return cv

def build():
    import os
    os.makedirs("res://x", exist_ok=True) if False else None
    sheets = {}
    anims = {}

    def add(family, name, frames, fps, loop, cell):
        sheets.setdefault(family, {})[name] = frames
        anims.setdefault(family, {})[name] = {"cell": list(cell), "fps": fps, "loop": loop}

    # --- BSDemon -------------------------------------------------------------
    F = (24, 24)
    idle = [{"bob": b, "tail": t} for b, t in ((0, 0), (1, 1), (0, 0), (-1, 1))]
    walk = [{"bob": b, "legL": l, "legR": r, "tail": t}
            for b, l, r, t in ((0, 1, 0, 0), (-1, 0, 0, 1), (0, 0, 1, 0), (-1, 0, 0, 1))]
    atk = [{"lean": -1, "bob": 1}, {"cast": True, "lean": 1, "bob": -1}, {"cast": True, "lean": 2}]
    spec = [{"fork": True, "bob": -1}, {"fork": True, "bob": 1, "lean": 1}]
    hurt = [{"hurt": True}]
    death0 = [None]
    # death frames: pop into splinters
    poof1 = Canvas(*F); poof2 = Canvas(*F)
    for i in range(7):
        ang = i * 0.9
        r = 4
        poof1.ellipse(12 + int(r * math.cos(ang)), 12 + int(r * math.sin(ang)), 2, 2, D_TAIL)
        r = 8
        poof2.ellipse(12 + int(r * math.cos(ang)), 12 + int(r * math.sin(ang)), 1, 1, D_TAIL2)
    poof1.rect(9, 9, 6, 6, D_RED); poof1.rect(10, 10, 4, 4, D_MOUTH)
    poof1_img = finish(poof1); poof2_img = finish(poof2)
    death = [finish(bsdemon({"bob": -2, "hurt": True})), poof1_img, poof2_img]
    add("bsdemon", "idle", [finish(bsdemon(p)) for p in idle], 6, True, F)
    add("bsdemon", "walk", [finish(bsdemon(p)) for p in walk], 8, True, F)
    add("bsdemon", "attack", [finish(bsdemon(p)) for p in atk], 12, False, F)
    add("bsdemon", "special", [finish(bsdemon(p)) for p in spec], 8, False, F)
    add("bsdemon", "hurt", [finish(bsdemon(p)) for p in hurt], 8, False, F)
    add("bsdemon", "death", death, 10, False, F)

    # --- Little Bill ---------------------------------------------------------
    b_idle = [{"bob": b} for b in (0, 1, 0, -1)]
    b_walk = [{"legL": 1, "bob": 0}, {"legR": 1, "bob": -1}, {"legL": 0, "bob": 1}, {"legR": 0, "bob": 0}]
    b_atk = [{"lean": -2, "bob": 1}, {"raise": True, "wallet": True, "lean": 2, "bob": -1}, {"raise": True, "wallet": True, "lean": 3}]
    b_spec = [{"screen": True}, {"screen": True, "bob": -1}]
    add("littlebill", "idle", [finish(littlebill(p)) for p in b_idle], 5, True, F)
    add("littlebill", "walk", [finish(littlebill(p)) for p in b_walk], 8, True, F)
    add("littlebill", "attack", [finish(littlebill(p)) for p in b_atk], 10, False, F)
    add("littlebill", "special", [finish(littlebill(p)) for p in b_spec], 6, False, F)
    add("littlebill", "hurt", [finish(littlebill({"hurt": True}))], 8, False, F)
    d1 = littlebill({"bob": 2}); d2 = Canvas(*F)
    d2.ellipse(12, 14, 4, 4, B_GOLD); d2.rect(10, 10, 4, 3, B_HAIR)
    add("littlebill", "death", [finish(d1), finish(d2), poof2_img], 8, False, F)

    # --- GPL Hipster ----------------------------------------------------------
    h_idle = [{"bob": b, "stink": i} for i, b in enumerate((0, 1, 0, -1))]
    h_walk = [{"legL": 1, "bob": 0, "stink": 0}, {"legR": 1, "bob": -1, "stink": 1},
              {"legL": 0, "bob": 1, "stink": 2}, {"legR": 0, "bob": 0, "stink": 3}]
    h_atk = [{"lean": -2, "rant": True}, {"rant": True, "waves": True, "lean": 1}, {"rant": True, "waves": True, "lean": 2, "stink": 2, "stinkN": 2}]
    h_spec = [{"stink": 1, "stinkN": 3}, {"stink": 3, "stinkN": 5}]
    add("gplhipster", "idle", [finish(gplhipster(p)) for p in h_idle], 5, True, F)
    add("gplhipster", "walk", [finish(gplhipster(p)) for p in h_walk], 8, True, F)
    add("gplhipster", "attack", [finish(gplhipster(p)) for p in h_atk], 10, False, F)
    add("gplhipster", "special", [finish(gplhipster(p)) for p in h_spec], 6, False, F)
    add("gplhipster", "hurt", [finish(gplhipster({"hurt": True}))], 8, False, F)
    hd1 = gplhipster({"bob": 2, "hurt": True})
    add("gplhipster", "death", [finish(hd1), poof2_img, poof1_img], 8, False, F)

    # --- Security Bot ----------------------------------------------------------
    add("secbot", "idle", [finish(secbot({"bob": 0})), finish(secbot({"bob": -1, "blink": True})),
                           finish(secbot({"bob": 0})), finish(secbot({"bob": 1}))], 5, True, F)
    add("secbot", "walk", [finish(secbot({"lean": -1})), finish(secbot({"lean": 1})),
                           finish(secbot({"lean": -1, "bob": 1})), finish(secbot({"lean": 1, "bob": 1}))], 10, True, F)
    add("secbot", "attack", [finish(secbot({"bob": -1})), finish(secbot({"zap": True})), finish(secbot({"zap": True, "lean": 1}))], 10, False, F)
    add("secbot", "hurt", [finish(secbot({"hurt": True}))], 8, False, F)
    bd = Canvas(*F); bd.rect(6, 10, 12, 8, S_DARK); bd.rect(8, 16, 8, 2, C("#ffffff"))
    add("secbot", "death", [finish(secbot({"hurt": True})), finish(bd), poof2_img], 8, False, F)

    # --- CTO boss ---------------------------------------------------------------
    BF = (56, 56)
    p1_idle = [{"bob": b} for b in (0, -1, 0, 1)]
    add("cto", "idle", [finish(cto({**p, "screens": True})) for p in p1_idle], 4, True, BF)
    p2_idle = [{"bob": b, "phase": 2} for b in (0, -1, 0, 1)]
    add("cto", "idle2", [finish(cto({**p, "screens": True})) for p in p2_idle], 5, True, BF)
    p3_idle = [{"bob": b, "phase": 3, "yell": True} for b in (0, -2, 0, -1)]
    add("cto", "idle3", [finish(cto({**p, "screens": True})) for p in p3_idle], 6, True, BF)
    add("cto", "walk", [finish(cto({**p, "screens": True})) for p in
                        [{"bob": 0}, {"bob": -1}, {"lean": 1, "bob": 0}, {"bob": -1}]], 6, True, BF)
    atk_sl = [{"lean": -3}, {"lean": 0, "slide": (30, 8)}, {"lean": 3, "slide": (40, 4)}]
    add("cto", "attack", [finish(cto({**p, "laptop": True})) for p in atk_sl], 10, False, BF)
    atk_sm = [{"raise": 1}, {"raise": 2, "summon": True}, {"raise": 1, "summon": True}]
    add("cto", "special", [finish(cto(p)) for p in atk_sm], 8, False, BF)
    atk_lp = [{"lean": 2}, {"lean": -2, "laptop": True}, {"lean": 4, "yell": True}]
    add("cto", "attack2", [finish(cto({**p, "laptop": True, "phase": 2})) for p in atk_lp], 10, False, BF)
    h1 = cto({"phase": 1}); h2 = cto({"phase": 2, "yell": True}); h3 = cto({"phase": 3})
    add("cto", "hurt", [finish(cto({"phase": 1, "bob": 2})), finish(cto({"phase": 2, "bob": 2, "yell": True}))], 6, False, BF)
    br1 = Canvas(*BF); br1.rect(14, 12, 28, 32, T_SUIT); br1.ellipse(28, 8, 10, 8, B_GOLD)
    add("cto", "death", [finish(cto({"phase": 3, "bob": 3, "yell": True})), finish(cto({"phase": 3, "bob": 6})),
                         finish(br1), poof2_img], 8, False, BF)

    # --- elite palette swaps -----------------------------------------------------
    elite_map_bsd = {D_RED: C("#7a3fe8"), D_RED_D: C("#4a18a8"), D_TAIL: C("#c77dff"),
                     D_TAIL2: C("#ffd23e"), D_HORN: C("#f2f2f2")}
    elite_map_bill = {B_SHIRT: C("#161616"), B_DOT: C("#f7c94b"), B_GOLD: C("#2de3ff"),
                      B_GOLD_D: C("#0a86c7"), B_PANTS: C("#3a1a5a")}
    elite_map_hip = {H_BLACK: C("#4a18a8"), H_BEARD: C("#1f1f1f"), H_GREEN: C("#e2282e"),
                     H_HAIR: C("#2a2a2a")}
    elite_map_bot = {S_BODY: C("#f7c94b"), S_DARK: C("#8a4a00"), S_RED: C("#2de3ff")}
    for fam, mp in (("bsdemon", elite_map_bsd), ("littlebill", elite_map_bill),
                    ("gplhipster", elite_map_hip), ("secbot", elite_map_bot)):
        sheets[fam + "_elite"] = {}
        anims[fam + "_elite"] = {}
        for nm, fr in sheets[fam].items():
            sheets[fam + "_elite"][nm] = [recolor(f, mp) for f in fr]
            anims[fam + "_elite"][nm] = anims[fam][nm]

    for fam in sheets:
        pack(sheets[fam], anims[fam], f"assets/enemies/{fam}.png")

if __name__ == "__main__":
    build()
