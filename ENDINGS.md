# Character Endings

PINGUDOT now has two different epilogues. The one that plays is chosen
automatically from the run's character; there is no menu option and no input
required.

| Run | Ending | Scene |
|---|---|---|
| Pingu | **Puerto Escondido** | `res://scenes/cinematics/PinguEnding.tscn` |
| MIGGY | **The Hacker's Winter** | `res://scenes/cinematics/MiggyEnding.tscn` |

---

## 1. Flow

```
boss defeated
  └─ LevelDirector: cto_die / cto_outro dialogue
      └─ Main.start_ending()
          ├─ if active character == "miggy" -> MiggyEnding
          └─ otherwise                       -> PinguEnding
              └─ EndingSequence.finished
                  └─ Main.show_credits()
                      └─ CreditsScreen.finished -> Main.show_menu()
```

`Main.start_ending()` is guarded, so the ending cannot start twice:

- it only runs from `Screen.GAME`;
- it refuses to start if any modal is already open (pause/settings/game over)
  or an `EndingSequence` is already the modal;
- it sets `Screen.ENDING` immediately.

During the cinematic:

- the gameplay world is set to `PROCESS_MODE_DISABLED` (enemies, hazards,
  timers and the player are frozen; this is safer than pausing the whole tree
  because audio and UI keep running);
- the HUD is hidden;
- `Main` ignores gameplay input because the screen is no longer `GAME`;
- the ending consumes any key/mouse press itself (`EndingSequence._unhandled_input`).

`mission_complete` is written to the save before the cinematic starts. After
credits, `Main.show_menu()` clears everything and unpauses normally.

---

## 2. Shared framework — `scripts/cinematics/EndingSequence.gd`

| Feature | Implementation |
|---|---|
| Fade in/out | full-screen `ColorRect` (z=1000) tweened via `_fade_in` / `_fade_out` |
| Captions | `_say(text, color, hold)` — non-blocking top strip with fade in/out |
| Title card | `_final(title, sub)` — forces the screen black, hides the world, shows the credits prompt |
| Camera | `_camera(scale, duration, pivot)` — tweens a world `Control` around a pivot (nearest filtering preserved) |
| Ambient audio | `_play_ambient(path, db)` — looping `AudioStreamWAV` on the SFX bus; `_finish()` fades and stops it |
| Skip | any key / mouse press after 1 second; `_finish()` is idempotent |
| Timing | `_wait(seconds)` returns `false` if the player skipped |

Subclasses only implement `_build()` (sprites/UI inside `_world`), `_play()`
(the timeline) and `_animate(delta)` (surf, snow, typing, cursor).

World sprites use small `z_index` values; UI layers use 700–1002 so the fade
and captions cannot be pierced by the scene.

---

## 3. Ending A — Pingu in Puerto Escondido

**Mood:** warm, quiet, nostalgic. The reward is stillness.

**Timeline (~21 s before the title card)**

1. Fade in on a late-afternoon beach; title caption
   `PUERTO ESCONDIDO, OAXACA. / THE PACIFIC, AT LAST.`
2. Pingu walks down the sand to the water while the camera pushes in slightly.
3. He sits (new back-view `sit` / `sit_idle` animations) and the sun starts to
   descend.
4. The day layer crossfades to sunset, then the sunset crossfades to a starry
   night; the sun fades below the horizon.
5. Fade to black, then `MISSION ACCOMPLISHED / PINGU FOUND THE PLACE.` and
   `[PRESS ANY KEY]` (auto-finishes after a few seconds).

**Environment animation**

- three full-scene sky stages (`day` → `sunset` → `night`) crossfaded;
- two scrolling cloud strips and two scrolling surf strips (seamless 384 px
  tiles), plus a pulsing foam line at the shore;
- a descending sun sprite with a layered alpha glow;
- two foreground palms pivoting at the trunk base, swaying with sine motion;
- birds crossing the sky with a flapping 3-frame atlas;
- Pingu's walk → idle → sit animation;
- camera push via `_camera()`.

**Audio**

- music: existing `ending.wav` (warm, hopeful);
- ambient: `assets/audio/ambient/beach.wav` (surf + wind + distant birds);
- sfx: `ocean` on arrival.

---

## 4. Ending B — MIGGY: The Hacker's Winter

**Mood:** cozy, blue-lit, obsessive. The reward is that he never stops making.

**Timeline (~21 s before the title card)**

1. Fade in on the apartment; snow falls outside the window; CRT monitors glow.
2. Camera pushes toward the desk. MIGGY types; keyboard clatter and a blinking
   terminal cursor accompany the following messages:
   - `Initializing Mono runtime...`
   - `Godot integration: READY`
   - `Hack compilation: 99%`
   - `Miggy's legendary hack:`
   - `SUCCESS`
3. The build completes: white flash, `BUILD SUCCESSFUL / MONO + GODOT = MAGIC`
   band, celebration pose (`sit_lean`), camera pulls back.
4. MIGGY turns toward the snowy window (`sit_idle`, flipped) and the scene
   fades to black.
5. `BUILD SUCCESSFUL / MONO + GODOT = MAGIC` title card and `[PRESS ANY KEY]`.

**Environment animation**

- three independent 4-frame CRT screen atlases (terminal, Godot-style editor,
  Mono-style runtime with a progress bar);
- additive monitor/lamp glows, subtly flickering;
- 46 snow particles drifting inside the window frame and wrapping;
- a typewriter effect on the terminal lines and a blinking cursor;
- MIGGY's new seated animations: `sit_idle`, `sit_type`, `sit_lean`;
- a CRT scanline shader overlay;
- camera push-in / pull-back.

**Audio**

- music: new `ending_miggy.wav` (slow minor arpeggio, sparse percussion);
- ambient: `assets/audio/ambient/winter.wav` (wind + fan hum + faint keys);
- sfx: `key_clack` while typing, `terminal_alert` per line, `victory` /
  `achievement` on the build.

---

## 5. Assets

Generated by `tools/art/gen_endings.py` (add `python3 gen_endings.py` in
`tools/art/`):

```
assets/environments/endings/
  pingu_beach_day.png / pingu_beach_sunset.png / pingu_beach_night.png
  pingu_sun.png        pingu_clouds.png   pingu_waves.png   pingu_foam.png
  pingu_palm.png       pingu_birds.png (+ manifest)
  miggy_room.png       miggy_lamp_glow.png                 miggy_snow.png
  miggy_monitor_terminal.png / miggy_monitor_godot.png / miggy_monitor_mono.png
```

New character animations are appended to the existing atlases:

```
assets/characters/pingu.png   -> sit, sit_idle
assets/characters/miggy.png   -> sit_idle, sit_type, sit_lean
```

Audio is generated by `tools/art/gen_audio.py`:

```
assets/audio/ambient/beach.wav        assets/audio/ambient/winter.wav
assets/audio/music/ending_miggy.wav
assets/audio/sfx/bird.wav             assets/audio/sfx/key_clack.wav
assets/audio/sfx/terminal_alert.wav
```

`AudioDirector` lists the new music/SFX explicitly so exported builds include
them. Ambient loops are loaded directly by `EndingSequence`, looped in code.

---

## 6. Tuning / extending

- **Timeline:** edit `_play()` in `PinguEnding.gd` / `MiggyEnding.gd`. Every
  beat is a plain `await _wait(seconds)`; add or remove beats freely.
- **Terminal copy:** `MiggyEnding.LINES` (first four lines); the final
  `SUCCESS` line lives in `_play()`.
- **Title cards:** `_final(title, sub)` arguments at the end of each `_play()`.
- **Skip window:** `EndingSequence._unhandled_input` (`_t > 1.0`).
- **Camera:** `_camera(target_scale, duration, pivot)`.
- **Colors / architecture:** `gen_endings.py` constants at the top; the 3×5
  font is `GLYPHS` in the same file.
- **Adding a third character:** add a `CharacterDefinition`, add a scene that
  extends `EndingSequence`, and pick it in `Main.start_ending()`.

---

## 7. QA

Automated (headless):

```bash
godot --headless --path . res://tests/Endings.tscn
```

`tests/Endings.tscn` verifies:

- every ending background, monitor, character animation, ambient and SFX asset
  exists;
- Pingu gameplay selects `PinguEnding`; Miggy gameplay selects `MiggyEnding`;
- the world is frozen and the player cannot move during the cinematic;
- starting the ending twice does not create a second sequence;
- `finished` fires exactly once and is idempotent;
- ambient audio is cleaned up;
- credits follow each ending and the title screen returns cleanly.

Screenshot QA (opens a window, writes to `/tmp/pingudot_endings`):

```bash
godot --path . res://tests/EndingsVisual.tscn
```

`tests/VisualCheck.tscn` also captures three frames of the Pingu ending in its
full run.
