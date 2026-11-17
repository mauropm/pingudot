"""PINGUDOT art generator: Pingu sprite sheets.

Produces a packed sprite sheet + JSON manifest for slicing at runtime:
res://assets/characters/pingu.png  and pingu_manifest.json
"""
from common import Canvas, C, save_sheet, out_path
from PIL import Image
import json, math

INK = C("#0a0a12")      # outline
BODY = C("#15151f")     # near-black body
BODY2 = C("#232333")    # body highlight
BELLY = C("#f2f2f2")
BEAK = C("#ff9a1f")
BEAK_D = C("#d96e00")
FEET = C("#ff8c14")
PACK = C("#2aa02e")
PACK_D = C("#16661c")
WHITE = C("#ffffff")
RED = C("#e2282e")
CYAN = C("#2de3ff")

CELL = (24, 32)

def new_frame():
    return Canvas(*CELL)

def draw_front(pose):
    """Render a front-facing penguin into a Canvas.

    pose keys: bob, legL, legR, wing (angle amount), lean, eye(open|blink|angry|x|happy),
    ball, aura, arms_up, point, crouch, disc, mouth
    """
    cv = new_frame()
    cx = 12 + pose.get("lean", 0)
    bob = pose.get("bob", 0)
    eye = pose.get("eye", "angry")

    if pose.get("ball"):
        # Barrel roll: a spinning black ball with feet and beak.
        rx = 8
        cv.ellipse(cx, 22, rx, rx - 1, BODY)
        cv.ellipse(cx - 2, 21, 3, 3, BELLY)
        cv.poly([(cx + 6, 18), (cx + 10, 20), (cx + 6, 22)], BEAK)
        cv.ellipse(cx - 3, 29, 2, 1, FEET)
        cv.ellipse(cx + 3, 29, 2, 1, FEET)
        cv.line(cx + 1, 16, cx + 4, 14, BODY2)
        return cv

    feet_y = 30 if not pose.get("tuck") else 26
    # feet
    cv.ellipse(cx - 3 + pose.get("legL", 0), feet_y, 3, 1, FEET)
    cv.ellipse(cx + 3 + pose.get("legR", 0), feet_y, 3, 1, FEET)

    # backpack peeking from behind (draw first)
    cv.rect(cx + 6, 16 + bob, 3, 8, PACK)
    cv.rect(cx + 6, 16 + bob, 3, 2, PACK_D)

    # wings behind body
    w = pose.get("wing", 0)
    cv.ellipse(cx - 8 - w, 20 + bob + pose.get("wingY", 0), 2, 5 - pose.get("wingS", 0), BODY)
    if pose.get("arms_up"):
        cv.ellipse(cx + 8 + w, 14 + bob, 2, 5, BODY)
    else:
        cv.ellipse(cx + 8 + w, 20 + bob + pose.get("wingY", 0), 2, 5 - pose.get("wingS", 0), BODY)

    # body
    cv.ellipse(cx, 21 + bob, 6, 8, BODY)
    # belly
    cv.ellipse(cx, 22 + bob, 4, 6, BELLY)

    # head
    hy = 10 + bob
    cv.ellipse(cx, hy, 5, 5, BODY)
    # eyes
    if eye == "x":
        for ex in (cx - 3, cx + 2):
            cv.line(ex, hy - 2, ex + 1, hy - 1, WHITE)
            cv.line(ex + 1, hy - 2, ex, hy - 1, WHITE)
    elif eye == "blink":
        cv.line(cx - 3, hy - 1, cx - 2, hy - 1, WHITE)
        cv.line(cx + 2, hy - 1, cx + 3, hy - 1, WHITE)
    elif eye == "happy":
        cv.line(cx - 4, hy - 2, cx - 3, hy - 1, WHITE)
        cv.line(cx - 3, hy - 1, cx - 2, hy - 2, WHITE)
        cv.line(cx + 2, hy - 2, cx + 3, hy - 1, WHITE)
        cv.line(cx + 3, hy - 1, cx + 4, hy - 2, WHITE)
    elif eye == "open":
        cv.ellipse(cx - 3, hy - 1, 1, 2, WHITE)
        cv.ellipse(cx + 3, hy - 1, 1, 2, WHITE)
        cv.px(cx - 3, hy, BODY2)
        cv.px(cx + 3, hy, BODY2)
    else:  # angry
        cv.rect(cx - 4, hy - 2, 2, 2, WHITE)
        cv.rect(cx + 2, hy - 2, 2, 2, WHITE)
        cv.px(cx - 3, hy - 1, INK)
        cv.px(cx + 3, hy - 1, INK)
        cv.line(cx - 5, hy - 3, cx - 3, hy - 2, BODY)
        cv.line(cx + 5, hy - 3, cx + 3, hy - 2, BODY)

    # beak
    if pose.get("mouth"):
        cv.poly([(cx - 3, hy + 2), (cx + 3, hy + 2), (cx, hy + 6)], BEAK)
        cv.poly([(cx - 1, hy + 3), (cx + 1, hy + 3), (cx, hy + 4)], WHITE)
    else:
        cv.poly([(cx - 3, hy + 2), (cx + 3, hy + 2), (cx, hy + 5)], BEAK)
        cv.line(cx - 2, hy + 3, cx + 2, hy + 3, BEAK_D)

    # straps
    cv.rect(cx - 2, 15 + bob, 1, 3, PACK_D)
    cv.rect(cx + 2, 15 + bob, 1, 3, PACK_D)

    if pose.get("aura"):
        for i, c in enumerate([CYAN, RED, CYAN]):
            ang = i * 2.1
            ax = int(cx + 9 * math.cos(ang))
            ay = int(22 + 4 * math.sin(ang))
            cv.rect(ax, ay, 2, 1, c)
    if pose.get("disc"):
        dx, dy = pose["disc"]
        cv.rect(dx, dy, 5, 5, C("#f7e94b"))
        cv.rect(dx + 1, dy + 1, 3, 2, INK)
        cv.rect(dx + 1, dy + 3, 3, 1, WHITE)
    if pose.get("point"):
        cv.rect(cx + 8, 19 + bob, 4, 1, BODY)
        cv.rect(cx + 12, 19 + bob, 1, 1, BEAK)
    if pose.get("slash"):
        cv.line(cx + 8, 12, cx + 13, 22, WHITE)
        cv.line(cx + 9, 12, cx + 14, 22, CYAN)
    return cv

def draw_back(pose):
    cv = new_frame()
    cx = 12
    bob = pose.get("bob", 0)
    cv.ellipse(cx - 3 + pose.get("legL", 0), 30, 3, 1, FEET)
    cv.ellipse(cx + 3 + pose.get("legR", 0), 30, 3, 1, FEET)
    cv.ellipse(cx, 21 + bob, 6, 8, BODY)
    cv.ellipse(cx, 10 + bob, 5, 5, BODY)
    # ears/fluff
    cv.rect(cx - 5, 6 + bob, 1, 2, BODY2)
    cv.rect(cx + 4, 6 + bob, 1, 2, BODY2)
    # big backpack
    cv.rect(cx - 4, 15 + bob, 8, 9, PACK)
    cv.rect(cx - 4, 15 + bob, 8, 2, PACK_D)
    cv.frame_rect(cx - 4, 15 + bob, 8, 9, PACK_D)
    cv.rect(cx - 1, 18 + bob, 2, 2, C("#f7e94b"))  # bedroll buckle
    # wings at sides
    cv.ellipse(cx - 8, 20 + bob, 2, 5, BODY)
    cv.ellipse(cx + 8, 20 + bob, 2, 5, BODY)
    # tail
    cv.poly([(cx - 1, 28 + bob), (cx + 1, 28 + bob), (cx, 30 + bob)], BODY2)
    return cv

def finish(cv):
    cv.shade_bottom(0.8)
    cv.outline((10, 10, 18))
    return cv.im

def build():
    sheet = {}
    anims = {}

    def emit(name, frames, fps, loop, cell=(24, 32), kind="front"):
        sheet[name] = frames
        anims[name] = {"frames": len(frames), "fps": fps, "loop": loop,
                       "cell": list(cell), "kind": kind}

    # ---- idle: breathe + blink --------------------------------------------
    emit("idle", [finish(draw_front(p)) for p in [
        {"bob": 0, "eye": "angry"},
        {"bob": 0, "eye": "angry"},
        {"bob": 1, "eye": "blink"},
        {"bob": 0, "eye": "angry"},
    ]], 6, True)

    # ---- walk -------------------------------------------------------------
    walk_poses = [
        {"legL": -2, "legR": 0, "bob": 0, "wing": 0},
        {"legL": -1, "legR": 1, "bob": -1, "wing": 1},
        {"legL": 0, "legR": 2, "bob": 0, "wing": 1},
        {"legL": 1, "legR": 1, "bob": 1, "wing": 0},
        {"legL": 0, "legR": 2, "bob": 0, "wing": 1},
        {"legL": -2, "legR": 0, "bob": -1, "wing": 1},
    ]
    emit("walk", [finish(draw_front({**p, "eye": "angry"})) for p in walk_poses], 10, True)

    back_walk = [
        {"legL": -2, "bob": 0}, {"legL": 0, "bob": -1},
        {"legL": 2, "bob": 0}, {"legL": 0, "bob": 1},
    ]
    emit("walk_back", [finish(draw_back(p)) for p in back_walk], 10, True)
    emit("idle_back", [finish(draw_back({"bob": 0})), finish(draw_back({"bob": 1}))], 4, True)

    # ---- run (wings back, big strides) -------------------------------------
    run_poses = [
        {"legL": -3, "legR": 1, "bob": -2, "wing": 2, "wingY": 2, "wingS": 2, "eye": "open"},
        {"legL": -1, "legR": 3, "bob": 1, "wing": 1, "wingY": 1, "wingS": 1},
        {"legL": 2, "legR": -2, "bob": -2, "wing": 2, "wingY": 2, "wingS": 2, "eye": "open"},
        {"legL": 0, "legR": 0, "bob": 1, "tuck": True, "wing": 1},
    ]
    emit("run", [finish(draw_front({**p, "eye": p.get("eye", "angry"), "mouth": True})) for p in run_poses], 12, True)

    # ---- jump / fall -------------------------------------------------------
    emit("jump", [finish(draw_front({"tuck": True, "wing": 3, "wingY": -3, "wingS": 3, "bob": -1, "eye": "open"}))], 8, False)
    emit("fall", [finish(draw_front({"wing": -1, "wingY": -4, "bob": 1, "eye": "x", "mouth": True}))], 8, False)

    # ---- melee attack (wing slash) -----------------------------------------
    emit("attack", [
        finish(draw_front({"lean": -2, "wing": -1, "bob": 0, "eye": "angry"})),
        finish(draw_front({"lean": 2, "wing": 3, "slash": True, "bob": -1, "eye": "angry", "mouth": True})),
        finish(draw_front({"lean": 1, "wing": 1, "bob": 0, "eye": "angry"})),
    ], 14, False)

    # ---- ranged (throw floppy disc) ----------------------------------------
    emit("ranged", [
        finish(draw_front({"arms_up": True, "disc": (14, 6), "bob": -1, "eye": "open"})),
        finish(draw_front({"lean": 2, "arms_up": False, "wing": 2, "eye": "angry", "mouth": True})),
    ], 10, False)

    # ---- special (channel + burst) -----------------------------------------
    emit("special", [
        finish(draw_front({"arms_up": True, "aura": True, "bob": -1, "eye": "open", "mouth": True})),
        finish(draw_front({"arms_up": True, "aura": True, "bob": -2, "eye": "happy"})),
        finish(draw_front({"lean": 1, "wing": 2, "bob": 0, "eye": "angry"})),
    ], 10, False)

    # ---- dodge roll --------------------------------------------------------
    emit("dodge", [
        finish(draw_front({"bob": 2, "crouch": True, "eye": "open"})),
        finish(draw_front({"ball": True, "lean": 3})),
    ], 12, False)

    # ---- hurt / death / victory / interact ----------------------------------
    emit("hurt", [finish(draw_front({"lean": -2, "bob": 1, "eye": "x", "mouth": True, "wing": -1}))], 8, False)
    emit("death", [
        finish(draw_front({"lean": -1, "eye": "x", "mouth": True, "wing": -1, "bob": 1})),
        finish(draw_front({"eye": "x", "bob": 3, "tuck": True, "legL": 2, "legR": 3})),
    ], 8, False)
    emit("victory", [
        finish(draw_front({"bob": 2, "eye": "happy", "mouth": True})),
        finish(draw_front({"bob": -3, "arms_up": True, "wing": 3, "eye": "happy", "mouth": True, "tuck": True})),
        finish(draw_front({"bob": 0, "eye": "angry"})),
    ], 8, False)
    emit("interact", [
        finish(draw_front({"point": True, "eye": "open"})),
        finish(draw_front({"point": True, "eye": "angry", "bob": -1})),
    ], 6, False)

    # ---- seated, watching the ocean (beach ending) --------------------------
    def draw_sit(pose):
        cv = new_frame()
        cx = 12 + pose.get("lean", 0)
        bob = pose.get("bob", 0)
        # feet poke out in front of the seated body
        cv.ellipse(cx - 4, 29 + bob, 3, 1, FEET)
        cv.ellipse(cx + 4, 29 + bob, 3, 1, FEET)
        # body, low and round
        cv.ellipse(cx, 23 + bob, 8, 8, BODY)
        # backpack seen from behind
        cv.rect(cx - 5, 16 + bob, 10, 10, PACK)
        cv.rect(cx - 5, 16 + bob, 10, 2, PACK_D)
        cv.frame_rect(cx - 5, 16 + bob, 10, 10, PACK_D)
        cv.rect(cx - 1, 20 + bob, 2, 2, C("#f7e94b"))
        # wings resting at the sides
        cv.ellipse(cx - 9, 23 + bob, 2, 5, BODY)
        cv.ellipse(cx + 9, 23 + bob, 2, 5, BODY)
        # head from behind, fluffy
        hy = 9 + bob
        cv.ellipse(cx, hy, 5, 5, BODY)
        cv.rect(cx - 5, hy - 4, 1, 2, BODY2)
        cv.rect(cx + 4, hy - 4, 1, 2, BODY2)
        cv.rect(cx - 2, hy - 6, 4, 1, BODY2)
        cv.rect(cx - 1, hy - 6, 2, 1, C("#2f2f42"))
        return cv

    emit("sit", [finish(draw_sit(p)) for p in [
        {"bob": 0}, {"bob": 1}, {"bob": 1, "lean": -1}, {"bob": 0, "lean": 1},
        {"bob": 0}, {"bob": 1, "lean": -1},
    ]], 4, True)
    emit("sit_idle", [finish(draw_sit({"bob": 0})), finish(draw_sit({"bob": 1}))], 3, True)

    # ---- HUD portrait -------------------------------------------------------
    por = Canvas(24, 24)
    por.ellipse(12, 13, 10, 10, BODY)
    por.rect(7, 9, 3, 3, WHITE); por.rect(14, 9, 3, 3, WHITE)
    por.px(9, 11, INK); por.px(16, 11, INK)
    por.line(6, 8, 10, 9, BODY2); por.line(18, 8, 14, 9, BODY2)
    por.poly([(9, 14), (15, 14), (12, 19)], BEAK)
    por.line(10, 15, 14, 15, BEAK_D)
    finish(por)
    sheet["portrait"] = [por.im]
    anims["portrait"] = {"frames": 1, "fps": 1, "loop": False, "cell": [24, 24], "kind": "front"}

    # pack everything into one atlas row-by-row with manifest offsets
    total_w = max(len(fr) for fr in sheet.values())
    imgs = {}
    y = 0
    layout = {}
    for name, frames in sheet.items():
        cellw, cellh = anims[name]["cell"]
        for i, fr in enumerate(frames):
            imgs[(name, i)] = fr
        y += cellh
    H = sum(anims[n]["cell"][1] for n in sheet)
    W = max(len(sheet[n]) * anims[n]["cell"][0] for n in sheet)
    atlas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    yy = 0
    for name, frames in sheet.items():
        cw, ch = anims[name]["cell"]
        for i, fr in enumerate(frames):
            atlas.paste(fr, (i * cw, yy))
        layout[name] = {"cell": list(anims[name]["cell"]), "frames": len(frames),
                        "fps": anims[name]["fps"], "loop": anims[name]["loop"],
                        "row_y": yy}
        yy += ch
    atlas.save(out_path("assets/characters/pingu.png"))
    with open(out_path("assets/characters/pingu_manifest.json"), "w") as f:
        json.dump({"anims": layout}, f, indent=1)
    print("pingu atlas", atlas.size)

if __name__ == "__main__":
    build()
