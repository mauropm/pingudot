# PINGUDOT

A complete 16-bit action RPG / roguelite dungeon crawler about a slim, sarcastic
penguin trying to escape Silicon Valley before it monetizes his soul.

Built natively with **Godot 4.7** and **GDScript**, at a 384×216 internal
resolution with nearest-neighbor, integer-scaled pixel rendering.

> "Trust is not a feature. It is the flight plan."

---

## Requirements

- **Godot 4.7+** (developed and verified against `4.7.2.stable`). Older 4.x
  versions may work but are not supported.
- macOS, Linux or Windows with a working GPU/OpenGL 3.3 (the project uses the
  `gl_compatibility` renderer for maximum compatibility).
- No external libraries or plugins are required to run the game.
- Python 3.9+ with Pillow + NumPy is only needed to **regenerate** art/audio
  from source (`tools/`), not to play.

## Running the game

```bash
git clone <this repo>
cd pingutot
godot --path .          # or open project.godot in the Godot editor and press F5
```

The game boots straight into the title screen. Sound is on by default; adjust
the volumes in **Settings** (from the main menu or the pause screen).

## Controls

| Input | Action |
| --- | --- |
| WASD / Arrow keys | Move (hold to break into a run) and navigate menus |
| ENTER / SPACE | Confirm a focused menu button |
| J | Wing attack (melee) |
| L | Throw a floppy disc (ranged, free — 0.45s cooldown) |
| K | Special ability (the selected one) |
| 1–4 | Select + cast a specific ability |
| SPACE | Dodge roll (invulnerability frames) |
| E | Interact / advance dialogue |
| I | Inventory & equipment |
| C | Character statistics |
| ESC | Pause menu / close UI |

All controls are visible in the intro cinematic before gameplay begins.

## The mission

Silicon Valley is a dungeon wearing a startup hoodie. Travel from the seaside
to Oakland through five areas, growing stronger, then defeat **The Chief
Technology Officer of Everything** and board the black airplane to Oaxaca City.

1. **Beach of Broken Promises** — easy. Tides, dead crypto ATMs, palms.
2. **Startup Graveyard** — medium. Little Bill clones, office loot, vending
   machines that accept equity.
3. **Open Source Warzone** — medium/hard. Kernel-panic vents, BSDemons, GPL
   Hipsters, licensing traps.
4. **Valley of Unicorns** — hard. Elite enemies, marble towers, stock crashes.
5. **Oakland Escape Terminal** — very hard. Security bots, a locked airfield,
   and the final boss.

Progress is continuous and saved at every public terminal (checkpoint) and on
entering a new area. Dying respawns you at your last checkpoint with a 20% coin
"resurrection licensing fee" — not a full restart.

## Systems

### Character progression
HP, Energy, ATK, DEF, SPD, INT, LUCK, XP, levels, crit chance, and item-driven
stat modifiers. Level-ups fully restore HP/energy and grant stat increases.
Four abilities unlock with levels (2/3/5/7): **Kernel Panic**, **Fork Bomb**,
**Root Access**, **Segmentation Fault** — each with its own icon, cooldown,
energy cost, VFX and SFX.

### Combat
Real-time 8-way action combat: melee arc, thrown projectiles, AoE, summons,
buffs, dodge i-frames, knockback, hit flashes, screen shake, damage numbers,
enemy HP bars, status effects (Blue Screen control loss, Port Conflict slow,
GPL stink damage-over-time, License Violation equipment lock).

### Enemies
- **BSDemon** — fireballs, fork-bomb spreads, port-conflict melee.
- **Little Bill** — kites, throws forced updates, BSODs, steals coins.
- **GPL Hipster** — stink aura, rant waves, license-violation hexes.
- **Corporate Security Bot** — charges and zaps.
- **Elite variants** for Area 4/5 with palette swaps and stronger stats.

### Loot, items and inventory
26 items across six rarities/slots (weapons, armor, boots, hardware, consumables,
materials) with humorous descriptions, randomized affix rolls (±20%), a seeded
rarity table influenced by area depth and LUCK, auto-stacking consumables, a
24-slot inventory, 4 hardware slots, and live comparison against equipped gear.

### Roguelite randomization
Enemy composition/counts, elite rolls, loot drops and affixes, prop placement
and two random scripted encounters per area all derive from a per-run seed.
Area layouts themselves are handcrafted (ASCII grids in `data/levels/*.json`).
Enter a seed on the title screen to reproduce a run. The boss fight is
deterministic and separately seeded.

### Boss
Three phases — Corporate Strategy (slides + security bot summons), AI
Transformation (hallucinated enemies + chaotic volleys), Subscription
Apocalypse (pay-per-hit, paywalls, traps) — with phase dialogue and a
multi-stage defeat sequence.

### Ending
Security collapse, a run to the black triangle plane with its two trust-blue
lines, engine start, takeoff, a Pacific sunset, destination Oaxaca City,
"MISSION ACCOMPLISHED", and scrolling credits.

### Meta
- 12 achievements (persisted separately from run saves), with toasts.
- Save/load with version stamping, magic validation and automatic `.bak`
  corruption recovery; manual save from the pause menu.
- Settings (master/music/SFX volume, mute) persisted to `user://`.
- 60+ dialogue lines, 15 environmental jokes, 10 random encounters.

## Architecture

```
project.godot              # 384x216, nearest filtering, integer scaling, InputMap
assets/                    # generated PNG atlases, WAV chiptunes, BMFont
  characters/ enemies/ environments/ effects/ ui/ audio/ fonts/
data/
  items.json abilities.json characters.json dialogue/lines.json loot/tables.json
  achievements/achievements.json levels/area1..5.json
scenes/
  main/Main.tscn           # boot scene (autoload Main runs the show)
  player/Player.tscn
  enemies/{BSDemon,LittleBill,GPLHipster,SecurityBot}.tscn
  bosses/CTOTechBoss.tscn
scripts/
  systems/                 # autoloads: EventBus, Main, GameState, SaveSystem,
                           # AudioDirector, ItemRegistry, AbilityRegistry,
                           # AchievementManager, DialogueDB, FX, SpriteLib, UISkin
  player/Player.gd         # movement, state machine, attacks, abilities, status
  enemies/                 # EnemyBase AI + the three families + bot + boss
  combat/                  # CombatMath, CharacterStats, Projectile, clones
  inventory/               # item/ability resources, LootSystem, pickups
  levels/                  # LevelDirector, interactables, checkpoints, exits
  ui/                      # HUD, dialogue, menu, inventory, stats, settings...
  cinematics/              # intro, ending, credits
tools/                     # Python asset/data generators (art, audio, maps)
tests/                     # headless test suite + runtime smoke + visual capture
```

Key design decisions:

- **Signals over coupling**: `EventBus` fans out HP/XP/dialogue/achievement
  events; the HUD, achievements and audio subscribe.
- **Resource-based items**: `ItemResource`/`AbilityResource` are custom
  `Resource` classes instantiated and randomized by registries.
- **Atlas + manifest sprites**: the Python art tools emit packed atlases with
  JSON manifests; `SpriteLib` slices them into `SpriteFrames` at runtime.
- **Code-built nodes** (player/enemies/UI) keep `.tscn` files thin, so scene
  files stay readable and the gameplay logic stays testable.
- **Native-resolution UI text**: the game renders through the `viewport` stretch
  mode at exactly 384×216 (integer-scaled to the window) and uses a binary
  BMFont at only its native 8 px size (or the exact 16 px double), so glyphs
  stay pixel-perfect with no fractional scaling or sampling artifacts.
- **TileMapLayer visuals + merged static collision**: area grids render through
  a `TileMapLayer` backed by a generated `TileSetAtlasSource`; wall runs merge
  into `StaticBody2D` rectangles for cheap, precise collision.
- **Seeded RNG** (`GameState.roll_rng()`) makes drops and spawns reproducible.
- **Character registry**: `data/characters.json` + `CharacterDefinition` drive
  playable characters (stats, ability sets, atlas, starter item). The Player,
  HUD and save system are character-agnostic; the default is Pingu. A
  developer-facing design/QA document for the hidden character lives in
  `MIGGY_EASTER_EGG.md`. The victory flow is character-aware: Pingu gets the
  Puerto Escondido sunset, MIGGY gets the winter hacker apartment
  (`ENDINGS.md`).

## Asset production note

The environment did not provide a working image-generation tool (the image API
returned "insufficient account funds"). As the master prompt allows, all art was
therefore created with **local tools**: original parametric pixel art authored in
Python/Pillow (`tools/art/*.py`) — auto-outlined, auto-shaded sprites, tilesets,
parallax backgrounds, UI chrome, item icons, a BMFont (binary AngelCode) and
16-bit-style effects — plus chip-tune-style music and SFX synthesized in NumPy
(`tools/art/gen_audio.py`). Everything is original, sliced, correctly scaled and
imported by Godot; nothing is a placeholder rectangle.

Regenerate assets/data at any time:

```bash
cd tools/art && python3 gen_pingu.py && python3 gen_enemies.py \
  && python3 gen_world.py && python3 gen_ui.py && python3 gen_audio.py
cd .. && python3 gen_data.py
godot --headless --path . --editor --quit   # reimport
```

## Testing

```bash
# 1) Editor/import validation — must end with no parse errors
godot --headless --path . --editor --quit

# 2) Logic + data integrity suite (349 assertions)
godot --headless --path . res://tests/Test.tscn

# 3) Full runtime smoke test (boots the game, walks all areas, kills an enemy,
#    uses checkpoints, saves/reloads, runs the 3-phase boss, triggers the ending)
godot --headless --path . res://tests/Smoke.tscn

# 3b) Keyboard/menu navigation (arrows + WASD + Enter, no mouse)
godot --headless --path . res://tests/Input.tscn

# 3c) Combat/input integration (WASD move, J melee, L ranged, K special,
#     enemy contact + projectile damage, I/C screens)
godot --headless --path . res://tests/Combat.tscn

# 3d) First-life flow (intro -> dialogue dismissible with J -> attack works,
#     movement locked while frozen, unlocked after)
godot --headless --path . res://tests/FirstLife.tscn

# 3e) Hidden character: unlock sequence, six powers, ultimate, save/load,
#     effect cleanup and Pingu regression (see MIGGY_EASTER_EGG.md)
godot --headless --path . res://tests/Miggy.tscn

# 3f) Inventory UI detail-panel replacement (selecting items must not stack text)
godot --headless --path . res://tests/Inventory.tscn

# 3g) Settings layout (mute toggle must not overlap the save buttons)
godot --headless --path . res://tests/Settings.tscn

# 3h) Character-specific endings (Pingu beach / Miggy winter; see ENDINGS.md)
godot --headless --path . res://tests/Endings.tscn

# 4) Visual capture (opens a window, writes PNGs to /tmp/pingudot_shots)
godot --path . res://tests/VisualCheck.tscn
#    Ending screenshots -> /tmp/pingudot_endings
godot --path . res://tests/EndingsVisual.tscn
```

The unit suite covers damage math, XP curves, stat aggregation, inventory
stacking/equipping, save/load round-trips, seeded loot reproducibility, all item
definitions/icons, dialogue/achievement counts, area-map dimensions, wall and
reachability checks and sprite-atlas integrity. The smoke test verifies no
runtime errors in the full mission loop.

## Exporting

Install the matching export templates for your Godot version, then:

```bash
# macOS
godot --headless --path . --export-release "macOS" build/PINGUDOT.zip
# Linux
godot --headless --path . --export-release "Linux/X11" build/PINGUDOT.x86_64
```

Or use **Project → Export…** in the editor. The project uses only core Godot
features, so no native plugins are needed.

### Web preview (build/web)

The web preset is committed (`export_presets.cfg`) and targets
`build/web/index.html`; `build/` is gitignored. Install the **Web** export
templates for your Godot version, then:

```bash
./tools/export_web.sh
# or manually:
#   mkdir -p build/web && godot --headless --path . --export-release "Web" build/web/index.html
```

Serve it over HTTP (browsers block wasm over `file://`):

```bash
cd build/web && python3 -m http.server 8000
# open http://localhost:8000
```

The preset builds a **single-threaded WebGL2** export
(`variant/thread_support=false`), so it runs on any static host — no
`Cross-Origin-Opener-Policy`/`Cross-Origin-Embedder-Policy` headers required.
All gameplay JSON (items, dialogue, levels, sprite manifests) is bundled via
`include_filter="*.json"`, and the development `tests/`/`docs/` folders are
excluded from the package. Verified booting in Chromium (WebGL 2.0, 36 SFX /
10 music tracks loaded, all five areas and the intro playable).

## Known limitations

- The game is keyboard-only (as specified); no gamepad bindings are shipped.
- Music/SFX are generated loops rather than studio recordings (deliberate
  16-bit aesthetic).
- Export templates were not installed in the build environment, so binaries
  were not produced there; running from source is fully verified.
- Optional temperature/exposure mechanics were intentionally skipped to keep
  resource management fair; HP/energy/loot/coins carry the survival loop.

---

**PINGUDOT — MISSION ACCOMPLISHED.**
