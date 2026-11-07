# MIGGY — the secret playable character

> **Spoiler warning:** this document is for developers/QA. The secret is not
> advertised anywhere in-game.

MIGGY is a hidden second playable character in PINGUDOT. He is an original
character (not a likeness of any real person) inspired by early-2000s
open-source culture: GNOME, Mono and Midnight Commander.

---

## 1. Activation

1. Launch the game and stay on the **title screen** (no modal open).
2. Type the word **`root`** (case-insensitive) anywhere on the title screen.
   Do **not** click the seed field first — while that text field has focus the
   secret listener stands down so normal text entry is never hijacked.
3. A full-screen terminal animation plays:

```
root@pingudot:~$ ./unlock_miggy

Checking permissions...
Loading GNOME modules...
Initializing Mono runtime...
Mounting /midnight/commander...
Privilege escalation successful.

WELCOME, MIGGY.
```

4. The **MIGGY** character card appears:
   `[ ENTER THE SHELL ]` starts a MIGGY run, `BACK [ESC]` returns.
5. The unlock is stored in the cross-save profile (`unlocks.miggy`). After the
   first unlock, typing `root` shows the card immediately and a discreet
   `root@pingudot:~$_` prompt appears at the bottom-left of the title screen
   (only after unlocking).

**Rules / safety**

- The listener only exists while the main menu scene is alive; typing `root`
  during gameplay or in a shop does nothing.
- Invalid input resets/rolls the 4-character buffer; the modifiers
  (Shift/Ctrl/Alt/Cmd, caps/num/scroll lock) are ignored.
- Typing in the seed `LineEdit` or while an achievements/settings modal is
  open cannot trigger the secret.
- The terminal command is **purely cosmetic text**. No shell, filesystem or
  OS command is ever executed.

---

## 2. Character architecture

MIGGY is deliberately implemented through the existing systems instead of a
forked player class.

| Layer | File | Role |
|---|---|---|
| Character data | `data/characters.json` | id, name, title, stats, ability list, ultimate, atlas, starter item |
| Character resource | `scripts/inventory/CharacterDefinition.gd` | typed resource |
| Character registry | `scripts/systems/CharacterRegistry.gd` (autoload) | loads definitions |
| Run state | `scripts/systems/GameState.gd` | `character_id`, `ultimate_charge`, per-character ability unlocks, save/load |
| Abilities | `data/abilities.json`, `AbilityResource.owner_id` | ownership + `ultimate` flag |
| Gameplay | `scripts/player/Player.gd` | character-aware atlas, 6 slots, powers, shields, ultimate |
| HUD | `scripts/ui/HUD.gd` | dynamic portrait, 6 ability slots, ultimate meter |
| Secret UI | `scripts/ui/TerminalUnlock.gd`, `MiggyCard.gd` | unlock sequence + card |
| Ultimate | `scripts/cinematics/MiggyUltimate.gd` + `scenes/cinematics/MiggyUltimate.tscn` | terminal cinematic |
| Dual-wield weapon | `scripts/combat/DualPanelWield.gd` | orbiting panels |
| Art | `tools/art/gen_miggy.py` | original sprites, icons, effects |
| Audio | `tools/art/gen_audio.py` | 12 character SFX |

Pingu remains the default character and all existing systems keep working.

### Base stats (balanced against Pingu)

| Character | HP | EN | ATK | DEF | SPD | INT | LUCK | Starter item |
|---|---|---|---|---|---|---|---|---|
| PINGU | 45 | 30 | 6 | 3 | 4 | 4 | 2 | Frozen Debugging Fish |
| MIGGY | 40 | 45 | 7 | 2 | 6 | 9 | 3 | Floppy of Power |

MIGGY has high INT/energy/speed but low defense; the ultimate is a meter, not a
free win. Bosses take 30% max HP from it.

### Animations

`assets/characters/miggy.png` + `miggy_manifest.json` contain: idle, walk, run,
jump, fall, attack, ranged, special, dodge, hurt, death, victory, interact,
spawn, ultimate, portrait, idle_back, walk_back.

A unique **spawn glitch** plays on area load. A **victory** pose plays when the
final boss dies.

---

## 3. Powers

All six powers are data-driven (`data/abilities.json`) and unlocked with level:
1, 2, 3, 4, 5, 6. Hotkeys **1–6** select+cast; **K** casts the selected power.
Every power has an energy cost, cooldown, icon, VFX and SFX.

| # | Power | Type | EN | CD | Effect |
|---|---|---|---|---|---|
| 1 | **Midnight Collider** | `collider` | 28 | 11s | Two terminal panels fly together; enemies within 150px are pulled to the collision point, then take heavy AoE damage (ATK×2.4 + INT×2) inside 86px. |
| 2 | **GNOME Shell Shock** | `stun_shield` | 24 | 10s | Desktop windows materialize, a wave expands; enemies within 140px are stunned 2.6s and take damage; grants a 9s damage shield (18 + INT×2). |
| 3 | **Mono Runtime Overdrive** | `overdrive` | 30 | 16s | 9s of +55% movement, 1.6× attack rate, 2× cooldown recovery, purple aura and afterimages. |
| 4 | **Bonobo Interface** | `shield` | 26 | 12s | 9s shield (30 + INT×2 HP) that absorbs damage and has a 35% chance to **reflect enemy projectiles** back at 120% damage. |
| 5 | **GObject Factory** | `factory` | 30 | 14s | Spawns 3 mini-MIGGY helpers that seek and attack nearby enemies for 8s. |
| 6 | **MC: Dual Wield** | `dual_wield` | 28 | 14s | 8s: two orbiting panels. Left panel fires fast **file** projectiles; right panel lobs **folders** that explode (34px splash for 70% damage). |

Temporary nodes (panels, clones, shields, afterimages) all self-clean; the
test suite asserts this.

### Ultimate — THE FINAL RECURSION

- Meter: `GameState.ultimate_charge` (0–100). Damage dealt with MIGGY's melee,
  ranged, powers or helpers charges it (2–8 per hit). HUD shows `R: ULT n%`.
- Activate with **R** at 100%. The game pauses, the screen turns black and a
  terminal cinematic plays:
  - `miggy@pingudot:~$ sudo rm -rf /`
  - `WARNING: THIS OPERATION CANNOT BE UNDONE.`
  - `MIGGY: "Hold my terminal."`
  - `EXECUTING...`, vortex, `SEGMENTATION FAULT`.
  - Any key skips after 0.5s.
- Effect: all ordinary enemies on the screen are destroyed; a **CTO boss loses
  30% of max HP** (never auto-defeated from full); all enemy projectiles are
  cleared; MIGGY is unharmed.
- The command is **fictional**. No code path invokes a shell or touches disk.

---

## 4. Assets

```
assets/characters/miggy.png            # atlas + manifest
assets/ui/ability_*.png                # 7 secret ability icons
assets/effects/collider_panel.png      # Midnight Collider panels
assets/effects/collider_boom.png
assets/effects/gnome_windows.png
assets/effects/gnome_wave.png
assets/effects/mono_aura.png
assets/effects/bonobo_shield.png
assets/effects/gobject_clone.png
assets/effects/file_proj.png
assets/effects/folder_proj.png
assets/effects/dual_panel.png
assets/effects/vortex.png
assets/effects/code_frag.png
assets/audio/sfx/{collider,gnome_shock,mono_overdrive,bonobo_shield,
  gobject_factory,dual_wield,ultimate_rmrf,miggy_unlock,miggy_spawn,
  miggy_shoot,miggy_ult,terminal_type}.wav
```

Regenerate with `python3 tools/art/gen_miggy.py` and `python3 gen_audio.py`
(inside `tools/art/`), then reimport in Godot.

---

## 5. Configuration & extension

- **Stats / starter item / ability order:** `data/characters.json`.
- **Power costs/cooldowns/descriptions/icons:** `data/abilities.json`.
- **Power behaviour:** `Player._trigger_ability()` dispatches new
  `ability_type` strings to `_cast_*` methods. Add a type + icon and a branch.
- **Shield / overdrive tuning:** `_grant_shield()` call sites, `_overdrive_t`
  and the multipliers in `_attack_speed()` / `_do_movement()`.
- **Ultimate damage:** `Player.apply_ultimate()` (30% boss, 99999 mobs).
  Cinematic text/timing: `scripts/cinematics/MiggyUltimate.gd`.
- **Secret unlock:** `MainMenuScreen._unhandled_input` + `_start_secret`;
  unlock persistence: `GameState.unlock_character()` / `SaveSystem` profile.
  Reset it by deleting `user://profile.json` (or **Settings → DELETE SAVE**).
- **Secret prompt:** `MainMenuScreen._add_root_prompt()` (post-unlock only).

To add another secret character: add an entry to `characters.json`, generate an
atlas with the same animation names, add abilities with `owner` set to the new
id, and reuse the card/terminal with a different unlock word.

---

## 6. QA

Automated (headless):

```bash
godot --headless --path . res://tests/Miggy.tscn
godot --headless --path . res://tests/Test.tscn
godot --headless --path . res://tests/Smoke.tscn
godot --headless --path . res://tests/Input.tscn
godot --headless --path . res://tests/Combat.tscn
godot --headless --path . res://tests/FirstLife.tscn
```

`tests/Miggy.tscn` covers: invalid sequences, seed-field isolation, `root`
unlock, persistence, card, starting a run, all 6 powers (energy/cooldown),
temporary-effect cleanup, shield absorption + reflection, ultimate
(cinematic, pause, ordinary kills, boss damage without auto-defeat), save/load
of the character, and Pingu regression. `tests/MiggyVisual.tscn` captures
screenshots to `/tmp/miggy_shots`.

Manual QA:

1. Fresh profile → title screen → type `roox` (nothing) → type `root`.
2. Watch the terminal type, skip it, confirm the card and `[ENTER THE SHELL]`.
3. In-game: verify 6 icons, `R: ULT` meter, HUD portrait, MIGGY sprite.
4. Level to 6 (or use Debugger) and cast 1–6; observe VFX/cooldowns and that
   effects disappear.
5. Take damage: shield absorbs (pink `BLOCK`), with Bonobo some projectiles
   reflect.
6. Charge ultimate, press R, skip cinematic, confirm ordinary enemies vanish
   and the boss only loses ~30%.
7. Restart → `root` → card appears; quit/reopen → unlock persists.
8. Start a normal NEW GAME → Pingu still has 4 powers.

---

## 7. Known limitations

- MIGGY shares the existing mission, areas, loot and ending cinematic (the
  ending uses his atlas for the runner) — no bespoke campaign.
- The ultimate is intentionally a spectacular screen-clear with a boss cap; it
  is not a guaranteed boss kill.
- No gamepad-specific secret input (keyboard only), consistent with the rest of
  the game.
