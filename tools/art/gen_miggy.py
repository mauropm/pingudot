"""PINGUDOT art: MIGGY — the secret open-source hacker character.

Original design, not a likeness: black tee with an abstract pixel "X" mark,
messy hair, confident smirk, terminal-green wristband.

Outputs:
  assets/characters/miggy.png + miggy_manifest.json
  assets/ui/ability_miggy_*.png (7 icons)
  assets/effects/miggy_*.png (one atlas per effect)
"""
from common import Canvas, C, pack, mix, shade, out_path
from PIL import Image
import math

INK = C("#0a0a14")
SHIRT = C("#1b1b27")
SHIRT_HI = C("#343447")
SKIN = C("#e8b98a")
SKIN_D = C("#c08a60")
HAIR = C("#2b1f16")
HAIR_HI = C("#5a4229")
JEANS = C("#33476b")
JEANS_HI = C("#455f8a")
SHOE = C("#101018")
PURPLE = C("#7a3fe8")
PURPLE_HI = C("#c77dff")
ORANGE = C("#ff8c14")
GREEN = C("#6ec72c")
WHITE = C("#f2f2f2")
CYAN = C("#2de3ff")

CELL = (24, 32)


def finish(cv, outline=INK):
    cv.shade_bottom(0.8)
    cv.outline(outline)
    return cv.im


def draw_front(p):
    cv = Canvas(*CELL)
    cx = 12 + p.get("lean", 0)
    bob = p.get("bob", 0)
    wing = p.get("arm", 0)          # arm swing / extension
    legL = p.get("legL", 0)
    legR = p.get("legR", 0)
    cast = p.get("cast", False)
    eye = p.get("eye", "cool")
    mouth = p.get("mouth", False)
    ultra = p.get("glow", False)
    crouch = p.get("crouch", False)

    feet = 30 - (2 if crouch else 0)
    # legs (jeans)
    cv.rect(cx - 4, 24 + bob, 3, 6 - (1 if crouch else 0), JEANS)
    cv.rect(cx + 1, 24 + bob, 3, 6 - (1 if crouch else 0), JEANS)
    cv.rect(cx - 4 + legL, feet - 2, 3, 2, SHOE)
    cv.rect(cx + 1 + legR, feet - 2, 3, 2, SHOE)
    cv.rect(cx - 4 + legL, feet - 1, 4, 1, C("#2a2a34"))
    cv.rect(cx + 1 + legR, feet - 1, 4, 1, C("#2a2a34"))
    # torso: black tee
    ty = 15 + bob
    cv.rect(cx - 5, ty, 10, 10, SHIRT)
    cv.rect(cx - 5, ty, 10, 2, SHIRT_HI)
    cv.rect(cx - 5, ty + 9, 10, 1, C("#0c0c12"))
    # lanyard (conference badge)
    cv.line(cx - 4, ty, cx - 1, ty + 4, C("#9aa4b2"))
    cv.line(cx + 4, ty, cx + 1, ty + 4, C("#9aa4b2"))
    cv.rect(cx - 1, ty + 4, 3, 2, C("#e8eef8"))
    # abstract pixel X logo (original): 4 chunky arms in purple/orange
    lx = cx - 2
    ly = ty + 3
    for i in range(3):
        cv.px(lx + i, ly + i, PURPLE)
        cv.px(lx + 3 - i, ly + i, ORANGE)
    cv.px(cx, ty + 5, PURPLE_HI)
    # arms
    if cast or p.get("arms_up"):
        cv.rect(cx - 8, 12 + bob, 3, 4, SHIRT)
        cv.rect(cx + 5, 12 + bob, 3, 4, SHIRT)
        cv.rect(cx - 8, 10 + bob, 2, 2, SKIN)
        cv.rect(cx + 6, 10 + bob, 2, 2, SKIN)
    elif p.get("attack"):
        cv.rect(cx - 7, 17 + bob, 3, 4, SHIRT)
        cv.rect(cx + 5, 17 + bob, 3, 2, SHIRT)
        cv.rect(cx + 7, 17 + bob, 4, 2, SKIN)   # extended arm
        cv.rect(cx + 10, 17 + bob, 2, 2, SKIN)
    else:
        cv.rect(cx - 7, 16 + bob, 2, 5 + (wing if wing > 0 else 0), SHIRT)
        cv.rect(cx + 5, 16 + bob, 2, 5 - (wing if wing < 0 else 0), SHIRT)
        cv.rect(cx - 7, 21 + bob, 2, 2, SKIN)
        cv.rect(cx + 5, 21 + bob, 2, 2, SKIN)
        # terminal wristband
        cv.rect(cx - 7, 20 + bob, 2, 1, GREEN)
    # neck + head
    cv.rect(cx - 1, ty - 2, 2, 2, SKIN_D)
    hy = 10 + bob
    cv.ellipse(cx, hy, 5, 5, SKIN)
    # messy hair: spikes
    cv.ellipse(cx, hy - 3, 5, 3, HAIR)
    for dx, dy, w in ((-5, -4, 2), (-3, -6, 2), (0, -7, 3), (3, -6, 2), (5, -4, 2),
                      (-4, -2, 1), (4, -2, 1)):
        cv.rect(cx + dx, hy + dy, w, 2, HAIR)
    cv.rect(cx - 3, hy - 5, 3, 1, HAIR_HI)
    cv.rect(cx + 1, hy - 6, 2, 1, HAIR_HI)
    # ears
    cv.rect(cx - 6, hy, 1, 2, SKIN)
    cv.rect(cx + 5, hy, 1, 2, SKIN)
    # eyes: confident (one brow up)
    if eye == "blink":
        cv.rect(cx - 4, hy, 2, 1, SKIN_D)
        cv.rect(cx + 2, hy, 2, 1, SKIN_D)
    elif eye == "happy":
        cv.px(cx - 3, hy, INK); cv.px(cx - 2, hy - 1, INK)
        cv.px(cx + 2, hy, INK); cv.px(cx + 3, hy - 1, INK)
    elif eye == "x":
        cv.line(cx - 4, hy - 1, cx - 2, hy + 1, INK)
        cv.line(cx - 2, hy - 1, cx - 4, hy + 1, INK)
        cv.line(cx + 2, hy - 1, cx + 4, hy + 1, INK)
        cv.line(cx + 4, hy - 1, cx + 2, hy + 1, INK)
    else:  # cool
        cv.rect(cx - 4, hy - 1, 2, 2, WHITE)
        cv.rect(cx + 2, hy - 1, 2, 2, WHITE)
        cv.px(cx - 3, hy, INK); cv.px(cx + 3, hy, INK)
        cv.line(cx - 5, hy - 2, cx - 2, hy - 2, HAIR)   # raised brow
        cv.line(cx + 1, hy - 3, cx + 4, hy - 2, HAIR)   # other brow
    # nose + smirk
    cv.px(cx, hy + 2, SKIN_D)
    if mouth or eye == "happy":
        cv.line(cx - 1, hy + 3, cx + 2, hy + 4, SKIN_D)
        cv.rect(cx + 1, hy + 3, 1, 1, C("#7a3a3a"))
    else:
        cv.line(cx - 1, hy + 4, cx + 2, hy + 4, SKIN_D)
        cv.px(cx + 2, hy + 3, SKIN_D)
    # beard shadow / stubble detail
    cv.px(cx - 3, hy + 3, SKIN_D); cv.px(cx - 3, hy + 4, SKIN_D)
    cv.px(cx + 3, hy + 3, SKIN_D)
    # glow / aura
    if ultra:
        for i, col in enumerate((PURPLE, PURPLE_HI, CYAN)):
            ang = i * 2.1
            cv.rect(int(cx + 9 * math.cos(ang)), int(20 + 6 * math.sin(ang)), 2, 2, col)
    if p.get("spawn"):
        for i in range(5):
            cv.px(cx - 8 + i * 4, 4 + (i * 3) % 9, GREEN)
            cv.px(cx + 7 - i, 20 + i * 2, PURPLE)
    return cv


def draw_back(p):
    cv = Canvas(*CELL)
    cx = 12
    bob = p.get("bob", 0)
    cv.rect(cx - 4 + p.get("legL", 0), 24 + bob, 3, 6, JEANS)
    cv.rect(cx + 1 + p.get("legR", 0), 24 + bob, 3, 6, JEANS)
    cv.rect(cx - 4 + p.get("legL", 0), 29, 4, 2, SHOE)
    cv.rect(cx + 1 + p.get("legR", 0), 29, 4, 2, SHOE)
    ty = 15 + bob
    cv.rect(cx - 5, ty, 10, 10, SHIRT)
    cv.rect(cx - 5, ty, 10, 2, SHIRT_HI)
    # terminal prompt on the back
    cv.rect(cx - 3, ty + 3, 2, 1, GREEN)
    cv.rect(cx + 1, ty + 4, 1, 2, GREEN)
    cv.rect(cx - 2, ty + 6, 4, 1, GREEN)
    # arms
    cv.rect(cx - 7, 16 + bob, 2, 6, SHIRT)
    cv.rect(cx + 5, 16 + bob, 2, 6, SHIRT)
    cv.rect(cx - 7, 21 + bob, 2, 2, SKIN)
    cv.rect(cx + 5, 21 + bob, 2, 2, SKIN)
    # head back (messy hair)
    hy = 10 + bob
    cv.ellipse(cx, hy, 5, 5, SKIN)
    cv.ellipse(cx, hy - 1, 5, 4, HAIR)
    for dx, dy, w in ((-5, -3, 2), (-3, -6, 3), (1, -6, 3), (4, -4, 2), (-4, 0, 1), (4, 1, 1)):
        cv.rect(cx + dx, hy + dy, w, 2, HAIR)
    cv.rect(cx - 2, hy + 1, 4, 1, HAIR_HI)
    cv.rect(cx - 1, hy + 4, 2, 1, SKIN_D)
    return cv


def build():
    sheets = {}
    anims = {}

    def add(name, frames, fps, loop):
        sheets[name] = [finish(f) for f in frames]
        anims[name] = {"cell": list(CELL), "fps": fps, "loop": loop}

    # idle
    add("idle", [draw_front({"bob": b, "eye": "cool" if i != 2 else "blink"})
                 for i, b in enumerate((0, 1, 0, 0))], 5, True)
    # walk
    add("walk", [draw_front({"legL": l, "legR": r, "bob": b, "arm": a})
                 for l, r, b, a in ((-2, 0, 0, 0), (-1, 1, -1, 1), (0, 2, 0, 1),
                                    (1, 1, 1, 0), (0, 2, 0, 1), (-2, 0, -1, 1))], 10, True)
    add("run", [draw_front({"legL": l, "legR": r, "bob": b, "lean": ln, "arm": 2, "eye": "cool"})
                for l, r, b, ln in ((-3, 1, -2, 2), (-1, 3, 0, 2), (2, -2, -2, 1), (1, 0, 1, 0))], 13, True)
    add("jump", [draw_front({"bob": -2, "legL": -1, "legR": 1, "arms_up": True, "eye": "happy"})], 8, False)
    add("fall", [draw_front({"bob": 1, "legL": 1, "legR": -1, "arms_up": True, "eye": "cool"})], 8, False)
    # attack: keyboard slap
    add("attack", [draw_front({"lean": -1, "arm": -1}),
                   draw_front({"lean": 2, "attack": True, "mouth": True}),
                   draw_front({"lean": 1, "eye": "cool"})], 14, False)
    add("ranged", [draw_front({"arms_up": True, "bob": -1, "eye": "cool"}),
                   draw_front({"lean": 1, "arm": 2, "mouth": True})], 10, False)
    add("special", [draw_front({"arms_up": True, "cast": True, "bob": -1, "glow": True}),
                    draw_front({"arms_up": True, "cast": True, "bob": -2, "glow": True, "eye": "happy"}),
                    draw_front({"arm": 1, "eye": "cool"})], 10, False)
    add("dodge", [draw_front({"crouch": True, "bob": 2, "eye": "cool"}),
                  draw_front({"crouch": True, "lean": 3, "bob": 1})], 12, False)
    add("hurt", [draw_front({"lean": -2, "bob": 1, "eye": "x", "mouth": True})], 8, False)
    add("death", [draw_front({"eye": "x", "mouth": True, "bob": 2, "lean": -1}),
                  draw_front({"eye": "x", "crouch": True, "bob": 3, "tuck": True})], 8, False)
    add("victory", [draw_front({"bob": 2, "eye": "happy"}),
                    draw_front({"bob": -2, "arms_up": True, "eye": "happy", "mouth": True, "glow": True}),
                    draw_front({"bob": 0, "eye": "cool"})], 8, False)
    add("interact", [draw_front({"arm": 1, "eye": "cool"}), draw_front({"arm": 1, "bob": -1})], 6, False)
    # spawn: glitchy materialization
    add("spawn", [draw_front({"spawn": True, "eye": "x"}),
                  draw_front({"spawn": True, "eye": "cool", "bob": -1}),
                  draw_front({"spawn": True, "eye": "cool", "glow": True}),
                  draw_front({"eye": "cool", "glow": True, "mouth": True})], 8, False)
    # ultimate pose
    add("ultimate", [draw_front({"arms_up": True, "glow": True, "eye": "cool"}),
                     draw_front({"arms_up": True, "glow": True, "eye": "happy", "mouth": True}),
                     draw_front({"glow": True, "eye": "cool", "lean": 1}),
                     draw_front({"glow": True, "eye": "happy", "bob": -1})], 6, True)
    add("idle_back", [draw_back({"bob": 0}), draw_back({"bob": 1})], 4, True)
    add("walk_back", [draw_back({"legL": -2, "bob": 0}), draw_back({"legL": 0, "bob": -1}),
                      draw_back({"legL": 2, "bob": 0}), draw_back({"legL": 0, "bob": 1})], 10, True)

    # portrait 24x24
    por = Canvas(24, 24)
    cx, hy = 12, 12
    por.ellipse(cx, hy, 9, 9, SKIN)
    por.ellipse(cx, hy - 4, 9, 5, HAIR)
    for dx, dy, w in ((-9, -5, 2), (-7, -8, 3), (-2, -9, 3), (3, -8, 3), (7, -5, 2),
                      (-8, 0, 1), (8, 1, 1)):
        por.rect(cx + dx, hy + dy, w, 2, HAIR)
    por.rect(cx - 4, hy - 7, 3, 1, HAIR_HI)
    por.rect(cx + 2, hy - 8, 2, 1, HAIR_HI)
    # eyes
    por.rect(cx - 5, hy - 2, 3, 2, WHITE)
    por.rect(cx + 2, hy - 2, 3, 2, WHITE)
    por.rect(cx - 4, hy - 1, 1, 1, INK)
    por.rect(cx + 3, hy - 1, 1, 1, INK)
    por.line(cx - 6, hy - 4, cx - 2, hy - 4, HAIR)
    por.line(cx + 1, hy - 5, cx + 5, hy - 4, HAIR)
    por.line(cx - 1, hy + 2, cx + 3, hy + 3, SKIN_D)
    por.rect(cx - 1, hy + 4, 3, 1, C("#7a3a3a"))
    por.px(cx + 3, hy + 3, SKIN_D)
    # tee strap visible at the bottom
    por.rect(0, 21, 24, 3, SHIRT)
    for i in range(3):
        por.px(9 + i, 22, PURPLE)
        por.px(15 - i, 22, ORANGE)
    sheets["portrait"] = [finish(por)]
    anims["portrait"] = {"cell": [24, 24], "fps": 1, "loop": False}

    pack(sheets, anims, "assets/characters/miggy.png")
    print("miggy atlas")


# ---------------------------------------------------------------------------
# Effects + ability icons
# ---------------------------------------------------------------------------
def effects():
    def emit(name, frames, cell, fps=10, loop=False):
        cv = Canvas(*cell)
        sheet = name
        d = {name: {"cell": list(cell), "fps": fps, "loop": loop}}
        pack({sheet: frames}, d, f"assets/effects/{name}.png")

    # midnight panels: dark blue file-manager panels with teal borders
    pnl = []
    for i in range(2):
        b = Canvas(34, 40)
        b.rect(1, 1, 32, 38, C("#0a1226"))
        b.frame_rect(1, 1, 32, 38, CYAN)
        b.rect(3, 3, 28, 5, C("#163a6a"))
        b.rect(4, 4, 10, 2, C("#9adcff"))
        for r in range(5):
            yy = 11 + r * 4
            b.rect(4, yy, 2, 2, CYAN if (r + i) % 2 else GREEN)
            b.rect(8, yy, 14 + (r % 3) * 2, 1, C("#4a6a9a"))
        b.rect(4, 32, 26, 1, C("#4a6a9a"))
        b.rect(4, 35, 10, 2, CYAN)
        b.outline(INK)
        pnl.append(b.im)
    emit("collider_panel", pnl, (34, 40), 6, True)

    # collider explosion: purple/cyan ring + debris
    frames = []
    for k in range(5):
        b = Canvas(40, 40)
        r = 4 + k * 4
        for ang in range(12):
            a = ang * math.tau / 12 + k * 0.2
            rr = r + (6 if ang % 2 else 0)
            b.rect(int(20 + rr * math.cos(a)), int(20 + rr * math.sin(a)), 3, 3,
                   PURPLE if ang % 2 else CYAN)
            if k >= 2:
                b.rect(int(20 + (rr + 5) * math.cos(a)), int(20 + (rr + 5) * math.sin(a)), 2, 2, ORANGE)
        b.outline(INK)
        frames.append(b.im)
    emit("collider_boom", frames, (40, 40), 14, False)

    # GNOME-ish windows (original abstract desktop): panels with header dots
    frames = []
    for k in range(3):
        b = Canvas(44, 30)
        off = k * 2
        b.rect(2 + off, 2, 26, 18, C("#e8eef8"))
        b.frame_rect(2 + off, 2, 26, 18, C("#16205a"))
        b.rect(3 + off, 3, 24, 4, C("#16205a"))
        b.px(5 + off, 5, C("#ff5a5a")); b.px(8 + off, 5, C("#f7c94b")); b.px(11 + off, 5, C("#6ec72c"))
        b.rect(5 + off, 9, 14, 2, C("#7a8ab8"))
        b.rect(5 + off, 13, 10, 2, C("#7a8ab8"))
        b.rect(14, 8, 28, 18, C("#e8eef8"))
        b.frame_rect(14, 8, 28, 18, C("#16205a"))
        b.rect(15, 9, 26, 4, PURPLE)
        b.rect(18, 16, 12, 2, C("#7a8ab8"))
        b.rect(18, 20, 8, 2, C("#7a8ab8"))
        b.frame_rect(0, 0, 44, 30, C("#0a1226"))
        b.outline(INK)
        frames.append(b.im)
    emit("gnome_windows", frames, (44, 30), 7, True)

    # electric wave (ring)
    frames = []
    for k in range(4):
        b = Canvas(36, 36)
        r = 5 + k * 4
        for ang in range(16):
            a = ang * math.tau / 16
            rr = r + (3 if ang % 3 == 0 else 0)
            b.rect(int(18 + rr * math.cos(a)), int(18 + rr * math.sin(a)), 2, 2,
                   CYAN if ang % 2 else WHITE)
        b.outline(INK)
        frames.append(b.im)
    emit("gnome_wave", frames, (36, 36), 12, False)

    # code fragments / IL instructions
    frames = []
    for k in range(3):
        b = Canvas(10, 10)
        b.rect(1, 1, 8, 2, PURPLE)
        b.rect(1, 4, 6, 1, PURPLE_HI)
        b.rect(1, 6, 7, 1, CYAN)
        b.px(8, 8 + (k % 2), GREEN)
        b.outline(INK)
        frames.append(b.im)
    emit("code_frag", frames, (10, 10), 10, True)

    # mono aura: purple flame ring behind the character
    frames = []
    for k in range(4):
        b = Canvas(30, 36)
        for i in range(10):
            a = i * math.tau / 10 + k * 0.3
            rr = 11 + (i % 3)
            b.rect(int(15 + rr * math.cos(a)), int(20 + rr * 0.9 * math.sin(a)), 2, 3,
                   PURPLE if i % 2 else PURPLE_HI)
        b.outline(INK)
        frames.append(b.im)
    emit("mono_aura", frames, (30, 36), 12, True)

    # bonobo components
    frames = []
    for k in range(4):
        b = Canvas(36, 36)
        for i in range(4):
            a = i * math.tau / 4 + k * 0.4
            x = int(18 + 11 * math.cos(a)); y = int(18 + 11 * math.sin(a))
            b.rect(x - 3, y - 3, 7, 7, C("#163a6a"))
            b.frame_rect(x - 3, y - 3, 7, 7, CYAN)
            b.rect(x - 1, y - 1, 3, 3, PURPLE)
        b.outline(INK)
        frames.append(b.im)
    emit("bonobo_shield", frames, (36, 36), 10, True)

    # GObject clone (mini Miggy) 16x20
    frames = []
    for k in range(2):
        b = Canvas(16, 20)
        b.ellipse(8, 12, 4, 5, SHIRT)
        for i in range(3):
            b.px(6 + i, 11, PURPLE)
            b.px(10 - i, 11, ORANGE)
        b.ellipse(8, 5, 3, 3, SKIN)
        b.ellipse(8, 3, 3, 2, HAIR)
        b.px(6, 5, INK); b.px(9, 5, INK)
        b.rect(5, 16, 2, 2, JEANS); b.rect(9, 16, 2, 2, JEANS)
        b.rect(3 - k, 19, 3, 1, SHOE); b.rect(10 + k, 19, 3, 1, SHOE)
        b.outline(INK)
        frames.append(b.im)
    emit("gobject_clone", frames, (16, 20), 8, True)

    # file / folder projectiles
    file_frames = []
    for k in range(2):
        b = Canvas(12, 12)
        b.rect(1, 1, 9, 9, C("#e8eef8"))
        b.frame_rect(1, 1, 9, 9, C("#4a6a9a"))
        b.rect(3, 4, 5, 1, C("#7a8ab8"))
        b.rect(3, 6, 4, 1, C("#7a8ab8"))
        b.rect(3, 8, 5, 1, CYAN)
        b.outline(INK)
        file_frames.append(b.im)
    emit("file_proj", file_frames, (12, 12), 12, True)
    folder_frames = []
    for k in range(2):
        b = Canvas(14, 12)
        b.rect(1, 3, 12, 8, C("#f0b429"))
        b.rect(2, 1, 5, 3, C("#f0b429"))
        b.frame_rect(1, 3, 12, 8, C("#a06a10"))
        b.rect(3, 5, 8, 1, C("#fff4d0"))
        b.rect(3, 7 + k, 5, 1, C("#d08a10"))
        b.outline(INK)
        folder_frames.append(b.im)
    emit("folder_proj", folder_frames, (14, 12), 8, True)

    # dual-wield panel (small)
    dual = Canvas(20, 26)
    dual.rect(1, 1, 18, 24, C("#0a1226"))
    dual.frame_rect(1, 1, 18, 24, CYAN)
    dual.rect(3, 3, 14, 3, C("#163a6a"))
    for r in range(4):
        dual.rect(3, 8 + r * 4, 2, 2, GREEN)
        dual.rect(6, 9 + r * 4, 10, 1, C("#4a6a9a"))
    dual.rect(3, 23, 8, 1, CYAN)
    dual.outline(INK)
    emit("dual_panel", [dual.im], (20, 26), 1, False)

    # ultimate vortex
    frames = []
    for k in range(6):
        b = Canvas(64, 64)
        for i in range(26):
            a = i * math.tau / 26 + k * 0.5
            rr = 6 + i * 1.8
            col = [PURPLE, PURPLE_HI, CYAN, GREEN, ORANGE][i % 5]
            x = int(32 + rr * math.cos(a)); y = int(32 + rr * math.sin(a))
            b.rect(x, y, 2, 2, col)
            if i % 4 == 0:
                b.rect(int(32 + (rr * 0.6) * math.cos(a + 0.4)),
                       int(32 + (rr * 0.6) * math.sin(a + 0.4)), 1, 1, WHITE)
        b.outline(INK)
        frames.append(b.im)
    emit("vortex", frames, (64, 64), 12, True)

    # terminal cursor block (for UI use)
    cur = Canvas(8, 10)
    cur.rect(0, 2, 6, 6, GREEN)
    emit("term_cursor", [cur.im], (8, 10), 2, True)

    # ability icons 16x16
    def icon(name, draw):
        b = Canvas(16, 16)
        b.rect(0, 0, 16, 16, C("#0a1226"))
        draw(b)
        b.frame_rect(0, 0, 16, 16, INK)
        b.outline(INK)
        b.im.save(out_path(f"assets/ui/{name}.png"))

    def i_collider(b):
        b.rect(1, 2, 5, 12, C("#163a6a")); b.frame_rect(1, 2, 5, 12, CYAN)
        b.rect(10, 2, 5, 12, C("#163a6a")); b.frame_rect(10, 2, 5, 12, CYAN)
        b.rect(6, 6, 4, 4, PURPLE); b.rect(7, 7, 2, 2, WHITE)
    def i_gnome(b):
        b.rect(2, 3, 12, 9, WHITE); b.frame_rect(2, 3, 12, 9, C("#16205a"))
        b.rect(3, 4, 10, 2, PURPLE)
        b.line(8, 6, 5, 13, CYAN); b.line(8, 6, 11, 13, CYAN)
    def i_mono(b):
        b.ellipse(8, 8, 5, 5, PURPLE); b.ellipse(8, 8, 3, 3, PURPLE_HI)
        b.rect(7, 2, 2, 3, CYAN); b.rect(2, 7, 3, 2, CYAN); b.rect(11, 7, 3, 2, CYAN)
    def i_bonobo(b):
        for x, y in ((2,2),(9,2),(2,9),(9,9)):
            b.rect(x, y, 5, 5, C("#163a6a")); b.frame_rect(x, y, 5, 5, CYAN)
        b.rect(7, 7, 2, 2, PURPLE_HI)
    def i_gobject(b):
        b.ellipse(5, 6, 3, 3, SKIN); b.rect(3, 9, 4, 4, SHIRT)
        b.ellipse(11, 9, 2, 2, SKIN); b.rect(10, 11, 3, 3, SHIRT)
        b.px(4, 5, INK); b.px(6, 5, INK); b.px(10, 8, INK); b.px(12, 8, INK)
    def i_dual(b):
        b.rect(1, 2, 5, 10, C("#163a6a")); b.frame_rect(1, 2, 5, 10, CYAN)
        b.rect(10, 4, 5, 10, C("#163a6a")); b.frame_rect(10, 4, 5, 10, CYAN)
        b.rect(7, 3, 2, 2, WHITE); b.rect(8, 6, 3, 2, C("#f0b429"))
    def i_ultimate(b):
        b.rect(1, 3, 14, 10, C("#05050a")); b.frame_rect(1, 3, 14, 10, GREEN)
        b.rect(3, 5, 4, 1, GREEN); b.rect(3, 7, 7, 1, GREEN); b.rect(3, 9, 5, 1, CYAN)
        b.rect(10, 8, 2, 2, C("#ff5a5a"))
    icon("ability_midnight_collider", i_collider)
    icon("ability_gnome_shell_shock", i_gnome)
    icon("ability_mono_overdrive", i_mono)
    icon("ability_bonobo_interface", i_bonobo)
    icon("ability_gobject_factory", i_gobject)
    icon("ability_dual_wield", i_dual)
    icon("ability_final_recursion", i_ultimate)
    print("miggy effects + icons")


if __name__ == "__main__":
    build()
    effects()
