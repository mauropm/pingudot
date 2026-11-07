"""PINGUDOT pixel art toolkit.

A tiny drawing library used by every generator script. Sprites are drawn at
1x into fixed-size cells, then auto-outlined and auto-shaded so the whole
game keeps one consistent 16-bit look.
"""
from PIL import Image, ImageDraw
import os, json

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

def out_path(rel):
    p = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    return p

def C(hexstr):
    h = hexstr.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def shade(col, f):
    return tuple(max(0, min(255, int(c * f))) for c in col)

def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

class Canvas:
    """Small RGBA pixel canvas with retro-friendly helpers."""

    def __init__(self, w, h, fill=None):
        self.w, self.h = w, h
        if fill is None:
            self.im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        else:
            self.im = Image.new("RGBA", (w, h), fill + (255,))
        self.d = ImageDraw.Draw(self.im)

    # -- primitives ---------------------------------------------------------
    def px(self, x, y, col):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.d.point((x, y), col + (255,))

    def rect(self, x, y, w, h, col):
        self.d.rectangle([x, y, x + w - 1, y + h - 1], fill=col + (255,))

    def frame_rect(self, x, y, w, h, col):
        self.rect(x, y, w, 1, col); self.rect(x, y + h - 1, w, 1, col)
        self.rect(x, y, 1, h, col); self.rect(x + w - 1, y, 1, h, col)

    def ellipse(self, cx, cy, rx, ry, col):
        self.d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=col + (255,))

    def poly(self, pts, col):
        self.d.polygon(pts, fill=col + (255,))

    def line(self, x0, y0, x1, y1, col):
        self.d.line([x0, y0, x1, y1], fill=col + (255,), width=1)

    def noisy_fill(self, x, y, w, h, cols, weights=None, seed=1):
        """Fill a rect with a deterministic weighted dither of colors."""
        import random
        rnd = random.Random(seed)
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                col = rnd.choices(cols, weights=weights)[0] if weights else rnd.choice(cols)
                self.px(xx, yy, col)

    def flip_h(self):
        return Canvas(self.w, self.h, None) if False else Canvas.from_image(
            self.im.transpose(Image.FLIP_LEFT_RIGHT))

    @staticmethod
    def from_image(im):
        c = Canvas(im.width, im.height)
        c.im = im
        c.d = ImageDraw.Draw(c.im)
        return c

    # -- silhouette passes ---------------------------------------------------
    def outline(self, col=(13, 10, 23)):
        """Add a 1px outline around every shape."""
        import numpy as np
        a = np.array(self.im)
        alpha = a[:, :, 3]
        edge = np.zeros_like(alpha, dtype=bool)
        edge[1:, :] |= alpha[:-1, :] > 20
        edge[:-1, :] |= alpha[1:, :] > 20
        edge[:, 1:] |= alpha[:, :-1] > 20
        edge[:, :-1] |= alpha[:, 1:] > 20
        edge &= alpha == 0
        a[edge] = (*col, 255)
        self.im = Image.fromarray(a)
        self.d = ImageDraw.Draw(self.im)

    def shade_bottom(self, factor=0.78, col=None):
        """Darken the last opaque pixel above any transparent/other-color row.

        This fakes bottom-edge shading on every rounded shape for free.
        """
        s = self.im.load()
        edits = []
        for yy in range(self.h - 1):
            for xx in range(self.w):
                r, g, b, a = s[xx, yy]
                if a == 0:
                    continue
                r2, g2, b2, a2 = s[xx, yy + 1]
                if a2 > 0 and (r2, g2, b2) == (r, g, b):
                    edits.append((xx, yy, shade((r, g, b), factor)))
        for xx, yy, c in edits:
            s[xx, yy] = c + (255,)

    def top_light(self, factor=1.22):
        s = self.im.load()
        edits = []
        for yy in range(1, self.h):
            for xx in range(self.w):
                r, g, b, a = s[xx, yy]
                if a == 0:
                    continue
                r2, g2, b2, a2 = s[xx, yy - 1]
                if a2 > 0 and (r2, g2, b2) == (r, g, b):
                    edits.append((xx, yy, shade((r, g, b), factor)))
        for xx, yy, c in edits:
            s[xx, yy] = c + (255,)

    def save(self, rel):
        self.im.save(out_path(rel))

def pack(sheets, anims, rel):
    """Pack {name: [PIL.Image]} into an atlas (one row per anim) + manifest JSON.

    anims: {name: {"cell": [w,h], "fps": f, "loop": bool}}
    Writes <rel> and <rel without ext>_manifest.json next to it.
    """
    W = max(len(sheets[n]) * anims[n]["cell"][0] for n in sheets)
    H = sum(anims[n]["cell"][1] for n in sheets)
    atlas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    layout, yy = {}, 0
    for name, frames in sheets.items():
        cw, ch = anims[name]["cell"]
        for i, fr in enumerate(frames):
            atlas.paste(fr, (i * cw, yy))
        layout[name] = {"cell": [cw, ch], "frames": len(frames),
                        "fps": anims[name]["fps"], "loop": anims[name]["loop"], "row_y": yy}
        yy += ch
    atlas.save(out_path(rel))
    import json, os
    base = rel.rsplit(".", 1)[0]
    with open(out_path(base + "_manifest.json"), "w") as f:
        json.dump({"anims": layout}, f, indent=1)
    print(rel, atlas.size)

def save_sheet(frames, cell, rel, cols=None):
    """frames: list of PIL.Image same size. Arrange in a grid."""
    w, h = cell
    n = len(frames)
    cols = cols or n
    rows = (n + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * w, rows * h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(f, ((i % cols) * w, (i // cols) * h))
    sheet.save(out_path(rel))
    return {"cell": [w, h], "frames": n, "cols": cols}

def recolor(img, mapping):
    """Swap palette colors in a PIL RGBA image (for elite skins)."""
    a = img.copy()
    pxd = a.load()
    for yy in range(a.height):
        for xx in range(a.width):
            p = pxd[xx, yy]
            if p[3] == 0:
                continue
            key = (p[0], p[1], p[2])
            if key in mapping:
                pxd[xx, yy] = (*mapping[key], p[3])
    return a
