"""PINGUDOT audio: chiptune SFX + looping music tracks rendered to WAV.

Pure numpy synthesis: square/triangle leads, pulse bass, noise percussion.
Writes res://assets/audio/sfx/*.wav and res://assets/audio/music/*.wav.
"""
import numpy as np, wave, os

SR = 22050
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

def w(path, data, sr=SR):
    os.makedirs(os.path.dirname(os.path.join(ROOT, path)), exist_ok=True)
    d = np.asarray(data, dtype=np.float64) * 0.9
    peak = float(np.max(np.abs(d))) if d.size else 0.0
    if peak > 0.98:                     # keep headroom without clipping
        d = d / peak * 0.98
    d = np.clip(d, -1, 1)
    pcm = (d * 32767).astype(np.int16)
    with wave.open(os.path.join(ROOT, path), "wb") as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(sr)
        f.writeframes(pcm.tobytes())

def tone(freq, dur, kind="square", vol=0.5, attack=0.005, decay=0.1, vib=0.0, vibrate=0.0, sr=SR, duty=0.5):
    n = int(sr * dur)
    t = np.arange(n) / sr
    ph = 2 * np.pi * freq * t
    if vib:
        ph += vib * np.sin(2 * np.pi * vibrate * t)
    if kind == "square":
        s = np.where((ph / (2 * np.pi)) % 1.0 < duty, 1.0, -1.0)
    elif kind == "tri":
        fmod = (ph / (2 * np.pi)) % 1.0
        s = 4 * np.abs(fmod - 0.5) - 1
    elif kind == "sine":
        s = np.sin(ph)
    elif kind == "noise":
        rng = np.random.RandomState(int(freq * 1000) % 99991)
        return rng.uniform(-1, 1, n)
    else:
        s = np.sin(ph)
    env = np.ones(n)
    na = max(1, int(sr * attack))
    env[:na] *= np.linspace(0, 1, na)
    if decay:
        nd = min(n - na, int(sr * decay))
        env[-nd:] *= np.linspace(1, 0, nd)
    return s * env * vol

def slide(f0, f1, dur, kind="square", vol=0.5, sr=SR, duty=0.5):
    n = int(dur * sr)
    out = np.zeros(n)
    fs = np.linspace(f0, f1, n)
    ph = np.cumsum(2 * np.pi * fs / sr)
    s = np.where((ph / (2 * np.pi)) % 1 < duty, 1.0, -1.0)
    if kind == "sine":
        s = np.sin(ph)
    env = np.ones(n); nd = max(1, n // 8); env[-nd:] = np.linspace(1, 0, nd)
    return s * env * vol

def noise_burst(dur, vol=0.5, lp=None, sr=SR):
    n = int(dur * sr)
    rng = np.random.RandomState(7)
    s = rng.uniform(-1, 1, n)
    if lp:
        k = int(sr / lp * 2)
        kernel = np.hanning(k); kernel /= kernel.sum()
        s = np.convolve(s, kernel, mode="same")
    env = np.ones(n); nd = max(1, n // 4); env[-nd:] = np.linspace(1, 0, nd)
    return s * env * vol

def seq(notes, kind="square", vol=0.4, step=None, sr=SR, vib=0.0, duty=0.5, vibrate=5.5):
    """notes: list of midi or None. step = seconds per note."""
    bpm = 120
    step = step or (60 / bpm / 2)
    out = np.zeros(int(len(notes) * step * sr))
    for i, nt in enumerate(notes):
        if nt is None:
            continue
        f = 440 * 2 ** ((nt - 69) / 12)
        seg = tone(f, step * 1.95, kind=kind, vol=vol, decay=step * 0.9, vib=vib,
                   vibrate=vibrate, sr=sr, duty=duty)
        start = int(i * step * sr)
        end = min(len(out), start + len(seg))
        out[start:end] += seg[:end - start]
    return out

# ---------------------------------------------------------------------------
# SFX
# ---------------------------------------------------------------------------
def padsum(*segs):
    m = max(len(x) for x in segs)
    out = np.zeros(m)
    for x in segs:
        out[:len(x)] += x
    return out

def sfx():
    s = {}
    s["step"] = noise_burst(0.05, 0.25, lp=2200)
    s["jump"] = slide(300, 700, 0.15, vol=0.4)
    s["slash"] = padsum(noise_burst(0.12, 0.5, lp=1200), tone(880, 0.08, "square", 0.2, decay=0.08))
    s["shoot"] = slide(900, 400, 0.12, kind="square", vol=0.35, duty=0.25)
    s["hurt"] = slide(400, 120, 0.22, "square", 0.5, duty=0.7)
    s["enemy_hurt"] = slide(500, 200, 0.15, "square", 0.4)
    s["enemy_die"] = padsum(noise_burst(0.3, 0.45), slide(300, 60, 0.3, "tri", 0.4))
    s["boom"] = noise_burst(0.5, 0.7, lp=900)
    s["coin"] = padsum(tone(988, 0.07, "square", 0.4, decay=0.03), tone(1319, 0.2, "square", 0.4, decay=0.15))
    s["heal"] = padsum(tone(523, 0.1, "tri", 0.5), tone(659, 0.1, "tri", 0.5), tone(784, 0.25, "tri", 0.5, decay=0.2))
    s["energy"] = padsum(tone(660, 0.06, "square", 0.3, duty=0.1), tone(880, 0.12, "square", 0.3, duty=0.1))
    s["item_get"] = seq([72, 76, 79, 84], "square", 0.35, step=0.09)
    s["levelup"] = padsum(seq([60, 64, 67, 72, 76, 79], "tri", 0.5, step=0.1), seq([72, 79, 84, 91], "square", 0.25, step=0.1))
    s["ui_move"] = tone(660, 0.05, "square", 0.25, decay=0.04)
    s["ui_ok"] = padsum(tone(880, 0.08, "square", 0.35), tone(1174, 0.1, "square", 0.3))
    s["ui_back"] = tone(300, 0.1, "square", 0.3)
    s["kernelpanic"] = padsum(noise_burst(0.6, 0.6, lp=1500), seq([96, 95, 94, 93, 92], "square", 0.4, step=0.09, duty=0.2))
    s["forkbomb"] = padsum(tone(500, 0.08, "square", 0.3) * 3, seq([84, 88, 91], "tri", 0.4, step=0.08))
    s["rootaccess"] = padsum(seq([48, 55, 60, 64, 67], "tri", 0.5, step=0.08), tone(110, 0.4, "square", 0.3, duty=0.1))
    s["segfault"] = slide(1200, 200, 0.25, "square", 0.45, duty=0.3)
    s["fireball"] = padsum(noise_burst(0.25, 0.4, lp=700), slide(200, 90, 0.3, "sine", 0.5))
    s["penguin"] = padsum(slide(700, 350, 0.12, "sine", 0.5), slide(360, 620, 0.1, "sine", 0.4))
    s["save"] = seq([79, 84], "tri", 0.4, step=0.12)
    s["door"] = padsum(noise_burst(0.2, 0.3, lp=400), tone(120, 0.2, "tri", 0.5))
    s["hazard"] = slide(2000, 800, 0.1, "square", 0.25, duty=0.15)
    s["blue"] = padsum(tone(1000, 0.3, "square", 0.3, duty=0.05), noise_burst(0.3, 0.2))
    s["stink"] = slide(160, 90, 0.5, "sine", 0.5)
    s["boss_intro"] = padsum(seq([45, 45, 48, 45, 52, 51], "square", 0.5, step=0.18, duty=0.6), noise_burst(0.9, 0.3))
    s["boss_hurt"] = slide(220, 90, 0.3, "square", 0.5, duty=0.8)
    s["boss_die"] = padsum(noise_burst(1.2, 0.7), seq([36, 35, 34, 33], "tri", 0.6, step=0.3))
    s["victory"] = seq([67, 67, 67, 72, 69, 74], "square", 0.45, step=0.14)
    s["ocean"] = noise_burst(1.6, 0.12, lp=500)
    s["glitch"] = padsum(noise_burst(0.18, 0.3), slide(1500, 300, 0.18, "square", 0.2, duty=0.12))
    s["paywall"] = padsum(tone(880, 0.07, "square", 0.35), tone(740, 0.07, "square", 0.35), tone(622, 0.12, "square", 0.35))
    s["engine"] = padsum(noise_burst(1.0, 0.4, lp=300), tone(70, 1.0, "square", 0.3, duty=0.3))
    s["achievement"] = seq([72, 76, 79, 84, 88], "tri", 0.4, step=0.07)
    # ---- MIGGY / secret character -------------------------------------------
    s["terminal_type"] = padsum(tone(1400, 0.025, "square", 0.25, decay=0.02),
                                tone(900, 0.015, "square", 0.15))
    s["miggy_unlock"] = padsum(seq([76, 79, 83, 88], "square", 0.35, step=0.09),
                               seq([64, None, 64, None], "tri", 0.2, step=0.18))
    s["miggy_spawn"] = padsum(slide(1600, 180, 0.4, "square", 0.3, duty=0.2),
                              noise_burst(0.25, 0.3))
    s["miggy_shoot"] = slide(1300, 500, 0.12, "square", 0.35, duty=0.25)
    s["collider"] = padsum(slide(120, 800, 0.45, "square", 0.3, duty=0.3),
                           noise_burst(0.5, 0.6, lp=1600),
                           slide(600, 60, 0.35, "sine", 0.5))
    s["gnome_shock"] = padsum(noise_burst(0.35, 0.4, lp=5000),
                              seq([96, 91, 88, 84, 79], "square", 0.3, step=0.05, duty=0.15))
    s["mono_overdrive"] = padsum(slide(180, 1400, 0.55, "square", 0.35, duty=0.25),
                                 seq([72, 76, 79, 84, 88], "tri", 0.25, step=0.08))
    s["bonobo_shield"] = padsum(tone(740, 0.12, "square", 0.3, duty=0.1),
                                tone(1108, 0.3, "tri", 0.4),
                                tone(740, 0.15, "square", 0.2, duty=0.1))
    s["gobject_factory"] = padsum(seq([72, 79, 84], "square", 0.35, step=0.07),
                                  noise_burst(0.12, 0.2))
    s["dual_wield"] = padsum(tone(900, 0.04, "square", 0.3),
                             tone(1200, 0.05, "square", 0.3),
                             noise_burst(0.1, 0.2, lp=3000))
    s["ultimate_rmrf"] = padsum(slide(120, 28, 2.2, "sine", 0.7),
                                noise_burst(2.0, 0.45, lp=600),
                                seq([96, 84, 72, 60, 48, 36], "square", 0.3, step=0.18, duty=0.2),
                                slide(2000, 200, 0.6, "square", 0.2, duty=0.1))
    s["miggy_ult"] = padsum(tone(55, 0.8, "tri", 0.6),
                            noise_burst(0.5, 0.35, lp=500))
    for name, data in s.items():
        if len(data) < SR * 0.03:
            data = np.concatenate([data, np.zeros(SR // 50)])
        w(f"assets/audio/sfx/{name}.wav", data)
    print(f"{len(s)} sfx")

# ---------------------------------------------------------------------------
# MUSIC — short looping chiptune tracks
# ---------------------------------------------------------------------------
def drums(pat, step, vol=0.25):
    """pat: string of 'k','h','s','.' per step."""
    n = len(pat)
    out = np.zeros(int(n * step * SR))
    rng = np.random.RandomState(3)
    for i, c in enumerate(pat):
        start = int(i * step * SR)
        if c == "k":
            seg = slide(150, 45, step * 0.9, "sine", 0.8)
        elif c == "s":
            seg = padsum(noise_burst(step * 0.8, vol * 2, lp=2500), tone(200, step * 0.5, "sine", 0.4))
        elif c == "h":
            seg = noise_burst(step * 0.35, vol * 0.8, lp=6000)
        else:
            continue
        end = min(len(out), start + len(seg))
        out[start:end] += seg[:end - start]
    return out

def bassline(notes, step, vol=0.4):
    return seq(notes, "tri", vol, step=step)

def pad(chords, step, vol=0.12, duty=0.5):
    out = np.zeros(int(len(chords) * 4 * step * SR))
    for i, ch in enumerate(chords):
        start = int(i * 4 * step * SR)
        for nt in ch:
            f = 440 * 2 ** ((nt - 69) / 12)
            seg = tone(f, 4 * step * 0.98, "square", vol, decay=step, duty=duty)
            out[start:start + len(seg)] += seg
    return out

def mix(*tracks):
    m = max(len(t) for t in tracks)
    out = np.zeros(m)
    for t in tracks:
        out[:len(t)] += t
    return out

def transpose(notes, semis):
    return [n + semis if n is not None else None for n in notes]


def pad_beat(chords, step, vol=0.08, duty=0.3):
    return pad(chords, step, vol, duty)


def make_track(path, bpm, melody, bass, drum_pat, chords=None, lead="square",
               lead_vol=0.3, duty=0.5, bass_vol=0.4, drum_vol=0.2, pad_vol=0.0,
               vib=0.0, counter=None, counter_kind="tri", counter_vol=0.16,
               sections=None):
    """Render a ~4-section chiptune loop (A/B/A/C) instead of a tiny 2-bar hook."""
    step = 60.0 / bpm / 2.0          # 8th notes
    if sections is None:
        sections = [(0, 0.5), (3, 0.42), (0, 0.5), (-2, 0.45)]
    parts = []
    for tr, duty_v in sections:
        mel = seq(transpose(melody, tr), lead, lead_vol, step=step,
                  duty=duty_v, vib=vib, vibrate=5.5)
        bs = bassline(transpose(bass, tr), step, bass_vol)
        pat = drum_pat * (1 + int(len(melody) / max(1, len(drum_pat))))
        ds = drums(pat, step, vol=drum_vol)
        segs = [mel, bs, ds]
        if counter is not None:
            segs.append(seq(transpose(counter, tr), counter_kind, counter_vol,
                            step=step, duty=0.25, vib=0.0))
        if chords is not None and pad_vol > 0:
            segs.append(pad_beat([[n + tr for n in c] for c in chords], step, pad_vol))
        target = int(len(melody) * step * SR)
        seg = mix(*segs)
        if len(seg) < target:
            seg = np.concatenate([seg, np.zeros(target - len(seg))])
        seg = seg[:target]
        # 12 ms micro-fades at section joins: inaudible, prevents clicks
        nf = max(1, int(SR * 0.012))
        seg[:nf] *= np.linspace(0, 1, nf)
        seg[-nf:] *= np.linspace(1, 0, nf)
        parts.append(seg)
    out = np.concatenate(parts)
    # whole-loop de-click, 8 ms
    nf = max(1, int(SR * 0.008))
    out[:nf] *= np.linspace(0, 1, nf)
    out[-nf:] *= np.linspace(1, 0, nf)
    w(path, out)
    print(path, "%.1fs" % (len(out) / SR))


def music():
    # each melody/bass list is one 4-bar section (32 eighth notes) -----------------
    # -- main menu: bold heroic loop ------------------------------------------
    mel = ([67, 71, 74, 79, 76, 74, 71, 67, 69, 72, 76, 81, 79, 76, 72, 69,
            67, 71, 74, 79, 83, 81, 79, 76, 74, 71, 67, 71, 74, 79, 76, None])
    make_track("assets/audio/music/menu.wav", 132, mel,
               [43, None, 43, None, 48, None, 48, None,
                45, None, 45, None, 40, None, 43, None] * 2,
               "k.h.s.h.k.h.s.h.",
               chords=[[67, 71], [71, 74], [69, 72], [68, 71]] * 2,
               lead="square", duty=0.4, lead_vol=0.30, bass_vol=0.40,
               drum_vol=0.22, pad_vol=0.07)

    # -- area 1: beach of broken promises — breezy major ------------------------
    mel = [64, 67, 71, 74, 72, 71, 67, 64, 62, 67, 71, 74, 71, 67, 64, 62,
           60, 64, 67, 72, 71, 67, 64, 60, 62, 65, 69, 72, 71, 67, 64, None]
    make_track("assets/audio/music/area1.wav", 120, mel,
               [48, 48, 52, 52, 45, 45, 50, 50,
                41, 41, 45, 45, 43, 43, 47, 47] * 2,
               "k..h.s..k..h.s.h",
               lead="tri", lead_vol=0.42, bass_vol=0.35, drum_vol=0.17,
               vib=0.15)

    # -- area 2: startup graveyard — moody minor --------------------------------
    mel = [57, None, 60, 64, None, 60, 57, None, 53, None, 55, 59, None, 57, 53, None,
           57, None, 60, 64, None, 67, 69, None, 65, None, 62, 59, None, 57, 55, None]
    counter = [52, None, 55, 59, None, 55, 52, None, 48, None, 50, 55, None, 52, 48, None,
               52, None, 55, 59, None, 60, 62, None, 60, None, 57, 55, None, 52, 50, None]
    make_track("assets/audio/music/area2.wav", 132, mel,
               [33, 33, 36, 36, 31, 31, 34, 34] * 2,
               "k...s...k..ks.",
               chords=[[57, 60], [53, 57], [55, 59], [52, 55]] * 2,
               lead="square", duty=0.25, lead_vol=0.28, bass_vol=0.42,
               drum_vol=0.17, pad_vol=0.05, counter=counter)

    # -- area 3: open source warzone — driving dark arps ------------------------
    arp = [52, 55, 59, 64, 59, 55, 52, 55, 57, 60, 64, 67, 64, 60, 57, 60,
           50, 53, 57, 62, 57, 53, 50, 53, 55, 59, 62, 67, 62, 59, 55, None]
    make_track("assets/audio/music/area3.wav", 150, arp,
               [40, 40, 40, 43, 41, 41, 41, 44] * 2,
               "k.hks.h.k.hks.hh",
               lead="square", duty=0.15, lead_vol=0.22, bass_vol=0.45,
               drum_vol=0.20, sections=[(0, 0.15), (3, 0.12), (0, 0.15), (-2, 0.18)])

    # -- area 4: valley of unicorns — glossy, overpriced major ------------------
    mel = [76, 79, 83, 88, 86, 83, 79, 76, 81, 84, 88, 84, 81, 77, 81, 84,
           76, 79, 83, 88, 91, 88, 83, 79, 81, 84, 88, 91, 88, 84, 81, None]
    counter = [64, 68, 71, 76, 74, 71, 68, 64, 69, 72, 76, 72, 69, 65, 69, 72,
               64, 68, 71, 76, 79, 76, 71, 68, 69, 72, 76, 79, 76, 72, 69, None]
    make_track("assets/audio/music/area4.wav", 132, mel,
               [52, None, 47, None, 49, None, 44, None] * 2,
               "k.h.s.h.k.hks.h.",
               chords=[[64, 68, 71], [65, 69, 72]] * 4,
               lead="square", duty=0.4, lead_vol=0.25, bass_vol=0.4,
               drum_vol=0.17, pad_vol=0.045, counter=counter, counter_vol=0.18)

    # -- area 5: oakland terminal — tense, industrial ---------------------------
    arp = [67, None, 68, None, 71, None, 68, None, 67, None, 66, None, 64, None, 66, None,
           67, None, 68, None, 71, None, 68, None, 63, None, 62, None, 60, None, 62, None]
    drone = [43, None, None, None, 43, None, None, None, 43, None, None, None, 44, None, None, None] * 2
    make_track("assets/audio/music/area5.wav", 132, arp,
               [31, 31, 31, 32, 31, 31, 29, 29] * 2,
               "kk..s..kkk..s.k.",
               lead="square", duty=0.1, lead_vol=0.20, bass_vol=0.5,
               drum_vol=0.22, counter=drone, counter_kind="tri", counter_vol=0.12,
               sections=[(0, 0.10), (1, 0.10), (0, 0.10), (-1, 0.12)])

    # -- boss theme: frantic -----------------------------------------------------
    mel = [69, 72, 76, 72, 69, 68, 69, None, 64, 68, 71, 68, 64, 63, 64, None,
           69, 72, 76, 79, 76, 72, 69, None, 71, 74, 77, 74, 71, 68, 71, None]
    make_track("assets/audio/music/boss.wav", 160, mel,
               [33, 33, 34, 34, 35, 35, 36, 36, 33, 33, 34, 34, 31, 31, 32, 32] * 2,
               "kkhksh.kkhkshh",
               lead="square", duty=0.35, lead_vol=0.30, bass_vol=0.5,
               drum_vol=0.25, sections=[(0, 0.35), (3, 0.3), (0, 0.35), (5, 0.28)])

    # -- ending: warm, hopeful ----------------------------------------------------
    mel = [64, 67, 71, 76, 74, 71, 69, 67, 64, 67, 72, 76, 79, 76, 72, 69,
           64, 67, 71, 76, 79, 83, 81, 79, 76, 72, 69, 67, 64, 67, 71, None]
    make_track("assets/audio/music/ending.wav", 96, mel,
               [48, 45, 43, 48] * 4,
               "k...h...s...h...",
               chords=[[60, 64, 67], [57, 60, 64], [55, 59, 62], [60, 64, 67]] * 2,
               lead="tri", lead_vol=0.45, bass_vol=0.3, drum_vol=0.0,
               pad_vol=0.08, vib=0.2,
               sections=[(0, 0.5), (3, 0.5), (0, 0.5), (-2, 0.5)])

    # -- credits: mellow loop ------------------------------------------------------
    mel = [60, 64, 67, 72, 71, 67, 64, 60, 57, 60, 64, 69, 67, 64, 60, 57,
           60, 64, 67, 72, 74, 72, 67, 64, 62, 60, 64, 67, 64, 60, 57, None]
    make_track("assets/audio/music/credits.wav", 96, mel,
               [48, None, 45, None, 41, None, 43, None] * 2,
               "k..h.s..h.",
               lead="tri", lead_vol=0.4, bass_vol=0.3, drum_vol=0.10,
               sections=[(0, 0.5), (3, 0.5), (0, 0.5), (-2, 0.5)])

    # -- game over jingle (not looped) ---------------------------------------------
    mel = seq([57, 56, 55, 53], "square", 0.4, step=0.22, duty=0.5)
    w("assets/audio/music/gameover.wav", mix(mel, bassline([33, 32, 31, 29], 0.22, 0.4)))
    print("music done")


if __name__ == "__main__":
    sfx()
    music()
