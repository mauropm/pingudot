"""PINGUDOT data generator: items, abilities, dialogue, loot, achievements,
and the five handcrafted area maps (validated ASCII grids -> JSON).

Grid legend: # wall | . floor A | , floor B | ~ slow water | ^ hazard | E exit |
C checkpoint | V vending | A crypto ATM | H hidden chest | B boss gate |
digits 1-9 = enemy spawn markers (see spawn map below).
"""
import json, os
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
D = lambda *p: os.path.join(ROOT, "data", *p)
os.makedirs(D("levels"), exist_ok=True)
os.makedirs(D("loot"), exist_ok=True)
os.makedirs(D("dialogue"), exist_ok=True)
os.makedirs(D("achievements"), exist_ok=True)

RARITIES = ["common", "rare", "epic", "legendary"]

ITEMS = [
 ("kb_legendary", "Legendary Mechanical Keyboard", "legendary", "weapon",
  "Cherry MX switches. Sounds like angry typing at 3AM. +ATK.", {"atk": 6}),
 ("cable_10gbe", "The 10GbE Ethernet Cable of Destiny", "epic", "weapon",
  "Bends light. Never tangling. The prophecy was clear.", {"atk": 4, "crit_pct": 5}),
 ("fish_frozen", "Frozen Debugging Fish", "common", "weapon",
  "Rub on your code. Bugs evaporate out of fear.", {"atk": 2}),
 ("boot_disk", "Floppy of Power", "rare", "weapon",
  "Boots anything, solves nothing. 1.44MB of pure confidence.", {"atk": 3, "int": 2}),
 ("armor_gnu", "GNU/GPL Protective Armor", "epic", "armor",
  "Copylefted. Wearing it forces you to share your socks.", {"def": 6, "hp": 10}),
 ("kernel_unpatched", "The Unpatched Kernel", "legendary", "armor",
  "Zero day included. Do not update. Updating deletes the game.", {"def": 8, "atk": 3, "hp": -5}),
 ("gpu_cheap", "Suspiciously Cheap GPU", "rare", "hardware",
  "It works. It hums showtunes. Don't ask where it came from.", {"atk": 2, "int": 2}),
 ("ssd_boost", "SSD of Velocity", "rare", "hardware",
  "Boots your soul 300% faster. Terms of service apply.", {"spd": 3}),
 ("mouse_ergo", "Ergonomic Mouse of the Ancients", "common", "hardware",
  "Prevents carpal tunnel. Causes jealousy in coworkers.", {"crit_pct": 4}),
 ("wifi_router", "Router That Actually Works", "epic", "hardware",
  "Two bands, zero excuses. Ping of 1ms. Miracles happen.", {"int": 4, "luck": 3}),
 ("usb_sticky", "Sticky USB Pendrive", "common", "hardware",
  "Contains /etc/shadow of a company that no longer exists.", {"luck": 2}),
 ("ring_admin", "sudo Ring", "legendary", "hardware",
  "Wearing it whispers: you already have root.", {"atk": 3, "int": 3, "luck": 3}),
 ("hat_censor", "Content Moderation Beret", "rare", "hardware",
  "Silences enemies by vibe alone. Very pretentious.", {"def": 2, "int": 3}),
 ("sticker_gpl", "Sticker Bomb Laptop Decal", "common", "hardware",
  "+1 street cred. -1 resale value.", {"luck": 3}),
 ("card_honor", "Business Card: VP of Synergy", "rare", "hardware",
  "Title only. No phone number. Nobody has ever seen him.", {"def": 1, "luck": 2}),
 ("box_swag", "Mystery Swag Box", "common", "hardware",
  "90% stickers, 10% hope, 0% sustainable materials.", {"hp": 6}),
 ("monitor_curve", "Curved Trust Monitor", "epic", "hardware",
  "Displays trust levels. They are always 2%.", {"int": 5}),
 ("boots_root", "Root Access Boots", "epic", "boots",
  "Stomp bugs. Literally. They flatten when you walk.", {"spd": 4, "def": 2}),
 ("heal_small", "Overpriced Avocado Toast", "common", "consumable",
  "Heals 25 HP. Costs 18 coins. This is the Valley.", {"hp_heal": 25}),
 ("heal_big", "Family-Size Pizza (Cold)", "rare", "consumable",
  "Heals 60 HP. Tastes like a hackathon at 4AM.", {"hp_heal": 60}),
 ("en_small", "Energy Drink: Code Red Bull", "common", "consumable",
  "+30 Energy. Side effects: opinions.", {"en_gain": 30}),
 ("en_big", "Thermos of Questionable Coffee", "rare", "consumable",
  "+70 Energy. The office one. It's been there since 2019.", {"en_gain": 70}),
 ("patch_software", "Software Patch", "common", "material",
  "Officially unsupported but keeps working. Collect 10.", {"count": 1}),
 ("cookie", "Browser Cookie", "common", "consumable",
  "+12 HP. You accepted 4,000 of these. Consent is weird.", {"hp_heal": 12}),
 ("coffee", "Free Sample Cold Brew", "common", "consumable",
  "+15 HP, -5 dignity. It was expired anyway.", {"hp_heal": 15}),
 ("dodge_tonic", "LIQUID COURAGE (dev build)", "epic", "consumable",
  "Restores all cooldowns instantly. Regret delayed.", {"clear_cd": 1}),
]

def items_json():
    out = []
    for iid, name, rar, slot, desc, mods in ITEMS:
        out.append({"id": iid, "name": name, "rarity": rar, "slot": slot,
                    "desc": desc, "mods": mods})
    json.dump(out, open(D("items.json"), "w"), indent=1)

ABILITIES = [
 {"id": "kernel_panic", "owner": "pingu", "name": "Kernel Panic", "unlock_level": 2, "energy": 20,
  "cd": 6.0, "power": 2.2, "desc": "Screams internally. AoE blast damages everything nearby.",
  "icon": "res://assets/ui/ability_kernelpanic.png", "type": "aoe"},
 {"id": "fork_bomb", "owner": "pingu", "name": "Fork Bomb", "unlock_level": 3, "energy": 25,
  "cd": 9.0, "power": 1.0, "desc": "Spawn 4 mini-Pingus that attack nearby enemies. :(){ :|:& };:",
  "icon": "res://assets/ui/ability_forkbomb.png", "type": "clones"},
 {"id": "root_access", "owner": "pingu", "name": "Root Access", "unlock_level": 5, "energy": 30,
  "cd": 18.0, "power": 0, "desc": "sudo me: +50% ATK/DEF for 12s.",
  "icon": "res://assets/ui/ability_root.png", "type": "buff"},
 {"id": "segfault", "owner": "pingu", "name": "Segmentation Fault", "unlock_level": 7, "energy": 15,
  "cd": 4.5, "power": 3.0, "desc": "Throw a projectile that forgot its memory address. Pierces.",
  "icon": "res://assets/ui/ability_segfault.png", "type": "projectile"},
 # ---- MIGGY (secret character) -------------------------------------------
 {"id": "midnight_collider", "owner": "miggy", "name": "Midnight Collider", "unlock_level": 1,
  "energy": 28, "cd": 11.0, "power": 2.4,
  "desc": "Two blue panels. One very final diff.",
  "icon": "res://assets/ui/ability_midnight_collider.png", "type": "collider"},
 {"id": "gnome_shell_shock", "owner": "miggy", "name": "GNOME Shell Shock", "unlock_level": 2,
  "energy": 24, "cd": 10.0, "power": 1.4,
  "desc": "apt install lightning. Works on my machine.",
  "icon": "res://assets/ui/ability_gnome_shell_shock.png", "type": "stun_shield"},
 {"id": "mono_overdrive", "owner": "miggy", "name": "Mono Runtime Overdrive", "unlock_level": 3,
  "energy": 30, "cd": 16.0, "power": 0.0,
  "desc": "JIT so fast the bug reports arrive before the crash.",
  "icon": "res://assets/ui/ability_mono_overdrive.png", "type": "overdrive"},
 {"id": "bonobo_interface", "owner": "miggy", "name": "Bonobo Interface", "unlock_level": 4,
  "energy": 26, "cd": 12.0, "power": 1.0,
  "desc": "Components snap together. So do your ribs.",
  "icon": "res://assets/ui/ability_bonobo_interface.png", "type": "shield"},
 {"id": "gobject_factory", "owner": "miggy", "name": "GObject Factory", "unlock_level": 5,
  "energy": 30, "cd": 14.0, "power": 1.2,
  "desc": "g_object_new(MIGGY). Each clone gets different compiler flags.",
  "icon": "res://assets/ui/ability_gobject_factory.png", "type": "factory"},
 {"id": "dual_wield", "owner": "miggy", "name": "MC: Dual Wield", "unlock_level": 6,
  "energy": 28, "cd": 14.0, "power": 1.0,
  "desc": "Left panel: files. Right panel: folders. Zero mercy.",
  "icon": "res://assets/ui/ability_dual_wield.png", "type": "dual_wield"},
 {"id": "final_recursion", "owner": "miggy", "name": "The Final Recursion", "unlock_level": 1,
  "energy": 0, "cd": 0.0, "power": 0.0, "ultimate": True,
  "desc": "sudo rm -rf / --no-preserve-root. (Fictional. Please don't.)",
  "icon": "res://assets/ui/ability_final_recursion.png", "type": "ultimate"},
]

ACHIEVEMENTS = [
 ("kernel_survivor", "Kernel Survivor", "Defeat your first BSDemon."),
 ("sub_cancelled", "Subscription Cancelled", "Defeat Little Bill."),
 ("smells_like_gpl", "Smells Like GPL", "Defeat a GPL Hipster."),
 ("zero_trust", "Zero Trust", "Survive a boss phase without damage."),
 ("oss_hero", "Open Source Hero", "Collect 10 software patches."),
 ("unicorn_hunter", "Unicorn Hunter", "Reach the boss arena in Area 5."),
 ("root_unlocked", "Root Access", "Unlock all four abilities."),
 ("no_meetings", "No More Meetings", "Defeat the CTO of Everything."),
 ("oaxaca_express", "Oaxaca Express", "Complete the mission."),
 ("found_404", "404", "Find a hidden room."),
 ("legacy_hw", "Legacy Hardware", "Equip 3 hardware items at once."),
 ("exit_strategy", "Exit Strategy", "Escape Silicon Valley by plane."),
]

CHARACTERS = [
 {"id": "pingu", "name": "PINGU", "title": "THE SYSADMIN", "specialty": "LINUX / KERNEL / SARCASM",
  "status": "USER", "atlas": "res://assets/characters/pingu.png",
  "tagline": "Your dream has a 98% failure rate.",
  "stats": {"hp": 45, "en": 30, "atk": 6, "def": 3, "spd": 4, "int": 4, "luck": 2},
  "abilities": ["kernel_panic", "fork_bomb", "root_access", "segfault"], "ultimate": "",
  "start_item": "fish_frozen", "unlocked": True},
 {"id": "miggy", "name": "MIGGY", "title": "LEGENDARY OPEN SOURCE HACKER",
  "specialty": "GNOME / MONO / MIDNIGHT", "status": "ROOT",
  "atlas": "res://assets/characters/miggy.png",
  "tagline": "Why click when you can compile?",
  "stats": {"hp": 40, "en": 45, "atk": 7, "def": 2, "spd": 6, "int": 9, "luck": 3},
  "abilities": ["midnight_collider", "gnome_shell_shock", "mono_overdrive",
                "bonobo_interface", "gobject_factory", "dual_wield"],
  "ultimate": "final_recursion", "start_item": "boot_disk", "unlocked": False},
]


def characters_json():
    json.dump(CHARACTERS, open(D("characters.json"), "w"), indent=1)


def achievements_json():
    json.dump([{"id": a, "name": n, "desc": d} for a, n, d in ACHIEVEMENTS],
              open(D("achievements/achievements.json"), "w"), indent=1)

LOOT = {
 "drop_chance": 0.55,
 "pools": {
   "common": ["heal_small", "en_small", "cookie", "coffee", "sticker_gpl", "fish_frozen", "box_swag", "usb_sticky", "patch_software"],
   "rare": ["heal_big", "en_big", "boots_root", "gpu_cheap", "ssd_boost", "cable_10gbe", "card_honor", "hat_censor", "patch_software"],
   "epic": ["armor_gnu", "wifi_router", "monitor_curve", "dodge_tonic", "patch_software"],
   "legendary": ["kb_legendary", "kernel_unpatched", "ring_admin"],
 },
 "weights_base": {"common": 62, "rare": 25, "epic": 10, "legendary": 3},
 "area_weight_shift": 6,   # per area: shifts weight from common toward higher rarities
}

def loot_json():
    json.dump(LOOT, open(D("loot/tables.json"), "w"), indent=1)

DIALOGUE = {
 # intro & story
 "intro_1": {"speaker": "", "text": "1994. A slim penguin washes ashore in Silicon Valley. He has one goal: get out."},
 "intro_2": {"speaker": "PINGU", "text": "Let me get this straight. The ocean had everything, and humanity chose... venture capital."},
 "intro_3": {"speaker": "NARRATOR", "text": "Legend says a black airplane waits in Oakland. Two blue lines on its hull. The only honest thing left: trust."},
 "controls_card": {"speaker": "HOW TO PENGUIN", "text": "MOVE: WASD/ARROWS   RUN: HOLD MOVE   J: WING ATTACK   L: THROW DISK   K: SPECIAL   SPACE: DODGE   E: INTERACT   I: BAG   C: STATS   ESC: PAUSE"},
 "area1_intro": {"speaker": "SIGN", "text": "Welcome to Silicon Valley. Your dream has a 98% failure rate."},
 "area1_tip": {"speaker": "PINGU", "text": "Move with WASD or the arrows. J to whack something. SPACE to tumble out of trouble."},
 "area2_intro": {"speaker": "SIGN", "text": "We are not bankrupt. We are pre-revenue."},
 "area2_tip": {"speaker": "PINGU", "text": "K is for special abilities. They cost energy. L throws whatever is in your paw."},
 "area3_intro": {"speaker": "SIGN", "text": "Your code is not free until you understand the license."},
 "area3_tip": {"speaker": "PINGU", "text": "The terminals here still work. Save often. Trust nothing with a Terms of Service."},
 "area4_intro": {"speaker": "SIGN", "text": "Congratulations! Your company is now worth zero dollars, but your valuation is up 300%."},
 "area4_tip": {"speaker": "PINGU", "text": "Elite corporate guards. My favorite kind of problem: expensive and wrong."},
 "area5_intro": {"speaker": "SIGN", "text": "FINAL BOARDING CALL. ALL EXIT STRATEGIES REQUIRE BOARD APPROVAL."},
 "area5_warn": {"speaker": "PINGU", "text": "That's the gate. Whatever's behind it has a corner office. I hate corner offices."},
 # bosses / enemies
 "cto_intro": {"speaker": "CTO", "text": "YOU CANNOT LEAVE! YOUR EXIT STRATEGY HAS NOT BEEN APPROVED BY THE BOARD!"},
 "cto_p1": {"speaker": "CTO", "text": "Behold: SYNERGY. Phase one of a seventeen-phase roadmap."},
 "cto_p2": {"speaker": "CTO", "text": "Let me run it through my AI... it hallucinated a competitor. FICTIONAL. But aggressive."},
 "cto_p3": {"speaker": "CTO", "text": "ACTIVATING PREMIUM MODE. Every action now requires a subscription!"},
 "cto_die": {"speaker": "CTO", "text": "No... you cannot just... LEAVE... that's a violation of section 14.2(b)..."},
 "cto_outro": {"speaker": "PINGU", "text": "That's okay. I'm using Linux."},
 "bsdemon_1": {"speaker": "BSDemon", "text": "Have you tried compiling it yourself?"},
 "bsdemon_2": {"speaker": "BSDemon", "text": "YOUR LAYOUT IS NOT THE CORRECT LAYOUT!"},
 "bill_1": {"speaker": "Little Bill", "text": "Your freedom is currently available as a premium feature."},
 "bill_2": {"speaker": "Little Bill", "text": "I'm not buying you. I'm ACQUIRING your potential."},
 "hipster_1": {"speaker": "GPL Hipster", "text": "Actually, I wrote something similar in 1998."},
 "hipster_2": {"speaker": "GPL Hipster", "text": "That's a fork of a fork of a fork of MY code."},
 "bot_1": {"speaker": "Security Bot", "text": "THIS CARD IS NOT A VALID BADGE OF HONOR."},
 # endings
 "plane_1": {"speaker": "PINGU", "text": "Two blue lines. Trust, version controlled. I like it."},
 "plane_2": {"speaker": "NARRATOR", "text": "Destination: Oaxaca City. Altitude: finally above it all."},
 "plane_3": {"speaker": "", "text": "Trust is not a feature. It is the flight plan."},
 "gameover_1": {"speaker": "NARRATOR", "text": "PINGU has stopped responding. (It was never a kernel problem.)"},
 "gameover_2": {"speaker": "PINGU", "text": "I'll be back. I always reboots."},
 # ---- MIGGY (secret) ------------------------------------------------------
 "miggy_intro": {"speaker": "MIGGY", "text": "So this is the legacy codebase. I brought a compiler and zero patience."},
 "miggy_area2": {"speaker": "MIGGY", "text": "Pre-revenue? I've seen worse. I've compiled worse."},
 "miggy_area3": {"speaker": "MIGGY", "text": "Finally, a place where the license is the weapon."},
 "miggy_area4": {"speaker": "MIGGY", "text": "Unicorns. Cute. I prefer a shell prompt."},
 "miggy_area5": {"speaker": "MIGGY", "text": "Board approval? I am the board now."},
 "miggy_idle_1": {"speaker": "MIGGY", "text": "It works on my machine."},
 "miggy_idle_2": {"speaker": "MIGGY", "text": "sudo make me a sandwich --dry-run"},
 "miggy_idle_3": {"speaker": "MIGGY", "text": "There is no problem a new abstraction layer can't postpone."},
 "miggy_idle_4": {"speaker": "MIGGY", "text": "The command line is a perfectly reasonable UI. For everything."},
 "miggy_ult": {"speaker": "MIGGY", "text": "Hold my terminal."},
 "miggy_win": {"speaker": "MIGGY", "text": "Runtime optimized. CTO deprecated."},
 # checkpoints
 "cp_save": {"speaker": "TERMINAL", "text": "Checkpoint saved. Your secrets are stored in /tmp. You're welcome."},
 "cp_full": {"speaker": "TERMINAL", "text": "HP and energy restored. The terminal charged you 0 coins and 0 dignity."},
 # jokes (environmental)
 "joke_1": {"speaker": "PLAQUE", "text": "Employee of the month: a vending machine. Nobody challenged it."},
 "joke_2": {"speaker": "PLAQUE", "text": "This office is 'mission-driven'. The mission is rent."},
 "joke_3": {"speaker": "PLAQUE", "text": "Free hugs. Also free NDAs. Choose carefully."},
 "joke_4": {"speaker": "PLAQUE", "text": "WiFi: guest_5G. Password: in a PDF that needs another PDF."},
 "joke_5": {"speaker": "PLAQUE", "text": "The coffee machine has a roadmap. It is v0.3 'liquid, maybe'."},
 "joke_6": {"speaker": "PLAQUE", "text": "Sandbox: where your code pretends to be production."},
 "joke_7": {"speaker": "PLAQUE", "text": "We don't fire people. We give them a 'growth opportunity' downtown."},
 "joke_8": {"speaker": "PLAQUE", "text": "Trust levels painted on the wall. Last updated: before the IPO."},
 "joke_9": {"speaker": "PLAQUE", "text": "There is a 404 behind this wall. Please knock."},
 "joke_10": {"speaker": "PLAQUE", "text": "Open source, closed minds. Thanks for migrating."},
 "joke_11": {"speaker": "PLAQUE", "text": "The servers are warm. Like the community. Like a burning building."},
 "joke_12": {"speaker": "PLAQUE", "text": "Sharks hired here. Legal reclassified them as 'independent contractors'."},
 "joke_13": {"speaker": "PLAQUE", "text": "Please exit through the gift shop. The gift is leaving with no equity."},
 "joke_14": {"speaker": "PLAQUE", "text": "Baggage claim: where promises go to be delayed 4-6 business quarters."},
 "joke_15": {"speaker": "PLAQUE", "text": "Boarding requires: ticket, ID, and a signed waiver of curiosity."},
 # random event outcomes
 "ev_pitch": {"speaker": "FOUNDER", "text": "It's like a penguin, but for your router. We raised $40M. Want in?"},
 "ev_pitch_win": {"speaker": "PINGU", "text": "Brilliant. Terrible. Here's a coin for your trouble."},
 "ev_atm": {"speaker": "CRYPTO ATM", "text": "YOUR $PINGU COIN IS WORTH LESS THAN THIS BOOTH."},
 "ev_vend": {"speaker": "VENDING", "text": "This machine accepts equity instead of coins. It gives you snacks."},
 "ev_hack": {"speaker": "PINGU", "text": "A free public terminal. Risky. Worth it. I feel alive and litigious."},
 "ev_intern": {"speaker": "INTERN", "text": "I worked here for 8 months. They gave me a t-shirt and existential dread."},
 "ev_elevator": {"speaker": "ELEVATOR", "text": "Going up? Too late. You went down three floors of scope."},
 "ev_meme": {"speaker": "MEME SHRINE", "text": "A tribute to a campaign that trended for 15 minutes. It heals something in you."},
 "ev_drone": {"speaker": "DELIVERY DRONE", "text": "YOUR PACKAGE HAS ARRIVED AT THE WRONG ADDRESS. IT IS A WEAPON."},
 "ev_shark": {"speaker": "SHARK", "text": "I invest in failures. Specifically yours. Here's $20. Say 'synergy'."},
}

def dialogue_json():
    json.dump(DIALOGUE, open(D("dialogue/lines.json"), "w"), indent=1)

# ---------------------------------------------------------------------------
# Area maps (handcrafted)
# ---------------------------------------------------------------------------
def parse(name, rows, spawns, w, h, pool, music, props, jokes, events):
    norm = []
    for y, r in enumerate(rows):
        r = (r + "." * w)[:w]
        if y == 0 or y == len(rows) - 1:
            r = "#" * w
        else:
            r = "#" + r[1:-1] + "#"
        norm.append(r)
    rows = norm
    h = len(rows)
    grid = []
    ents = []
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == "#":
                grid.append(3)
            elif ch == ".":
                grid.append(0)
            elif ch == ",":
                grid.append(1)
            elif ch == "~":
                grid.append(9)   # water: slow zone marker -> entity
            elif ch == "^":
                grid.append(8)   # hazard
            elif ch == "E":
                grid.append(0); ents.append({"kind": "exit", "x": x, "y": y})
            elif ch == "C":
                grid.append(0); ents.append({"kind": "checkpoint", "x": x, "y": y})
            elif ch == "V":
                grid.append(0); ents.append({"kind": "vendor", "x": x, "y": y})
            elif ch == "A":
                grid.append(0); ents.append({"kind": "atm", "x": x, "y": y})
            elif ch == "H":
                grid.append(0); ents.append({"kind": "hidden", "x": x, "y": y})
            elif ch == "B":
                grid.append(0); ents.append({"kind": "bossgate", "x": x, "y": y})
            elif ch == "J":
                grid.append(0); ents.append({"kind": "joke", "x": x, "y": y})
            elif ch == "p":
                grid.append(0); ents.append({"kind": "prop", "x": x, "y": y})
            elif ch == "d":
                grid.append(0); ents.append({"kind": "loot", "x": x, "y": y})
            elif ch.isdigit():
                grid.append(0)
                ents.append({"kind": "enemy", "x": x, "y": y, "tier": int(ch)})
            else:
                grid.append(0)
    for s in spawns:
        ents.append(s)
    out = {"name": name, "w": w, "h": h, "grid": grid, "entities": ents,
           "music": music, "enemy_pool": pool, "props": props, "jokes": jokes,
           "events": events}
    json.dump(out, open(D("levels", name + ".json"), "w"))
    return out

def build_maps():
    # AREA 1 — Beach of Broken Promises (easy). 60x38
    r = ["#" * 60]
    def row(*parts):
        s = ""
        for ch, n in parts:
            s += ch * n
        return s
    def border_row(inner):
        return "#" + inner + "#"
    body = []
    body.append(border_row("." * 58))
    body.append(border_row("." * 18 + "~" * 8 + "." * 32))
    body.append(border_row("." * 18 + "~" * 8 + "." * 32))
    body.append(border_row("." * 8 + "1" + "." * 9 + "~" * 8 + "." * 6 + "p" + "." * 5 + "1" + "." * 15))
    body.append(border_row("." * 8 + "2" + "." * 10 + "~" * 8 + "." * 22))
    body.append(border_row("." * 26 + "~" * 8 + "." * 6 + "A" + "." * 14))
    body.append(border_row("." * 26 + "~" * 8 + "." * 22))
    body.append(border_row("." * 6 + "C" + "." * 51))
    body.append(border_row("." * 20 + "J" + "." * 37))
    body.append(border_row("." * 58))
    body.append(border_row("d" + "." * 20 + "#" * 10 + "." * 26))
    body.append(border_row("." * 20 + "#" * 10 + "1" + "." + "2" + "." * 15))
    body.append(border_row("." * 30 + "#" * 10 + "p" + "." * 17))
    body.append(border_row("." * 40 + "#" * 10 + "." * 7))
    body.append("#" * 24 + "." * 4 + "#" * 32)  # dune wall with a path through
    while len(body) < 36:
        body.append(border_row("." * 58))
    rows = ["#" * 60] + body + ["#" * 60]
    # carve exit on east edge
    rows = [list(x) for x in rows]
    rows[19] = list("#" + "." * 14 + "1" + "." * 18 + "2" + "." * 22 + "#")
    rows[20] = list("#" + "." * 40 + "d" + "." * 17 + "#")
    rows[35] = list("#" + "." * 30 + "#" * 8 + "." * 19 + "#")
    rows[33] = list("#" + "." * 40 + "E" + "." * 18 + "#")
    rows = ["".join(x) for x in rows]
    parse("area1", rows, [], 60, 38, ["bsdemon"], "area1",
          ["palm", "atm"], ["joke_1"], ["ev_pitch", "ev_atm"])

    # AREA 2 — Startup Graveyard (medium). 62x40
    a2 = []
    a2.append("#" * 62)
    a2.append("#E" + "." * 12 + "d" + "." * 46 + "#")
    a2.append("#" + "." * 8 + "C" + "." * 3 + "#" * 6 + "." * 6 + "#" * 12 + "." * 2 + "J" + "." * 12 + "#")
    a2.append("#" + "." * 8 + "#" * 6 + "." * 2 + "p" + "." * 3 + "#" * 12 + "." * 4 + "#" * 6 + "." * 18 + "#")
    a2.append("#" + "." * 8 + "#" * 6 + "1" + "." * 5 + "#" * 12 + "." * 4 + "#" * 6 + "2" + "." * 5 + "#" * 6 + "#")
    a2.append("#" + "." * 8 + "......" + "." * 5 + "2" + "......" + "." * 4 + "......" + "1" + "." * 5 + "#")
    a2.append("#" + "." * 5 + "3" + "." * 30 + "3" + "." * 16 + "#")
    a2.append("#" + "#" * 10 + "." * 8 + "V" + "." * 12 + "#" * 6 + "." * 8 + "#" * 8 + "#")
    a2.append("#" + "#" * 10 + "." * 30 + "#" * 6 + "." * 8 + "#" * 8 + "#")
    a2.append("#" + "." * 6 + "1" + "." * 12 + "#" * 8 + "." * 10 + "2" + "#" * 6 + "." + "A" + "......" + "#")
    a2.append("#" + "." * 6 + "#" * 1 + "." * 12 + "#" * 8 + "." * 12 + "#" * 6 + "." * 8 + "#")
    a2.append("#" + "." * 6 + "." * 12 + "#" * 8 + "." + "H" + "." * 10 + "#" * 6 + "." * 8 + "#")
    a2.append("#" + "." * 46 + "^" * 4 + "." * 8 + "#")
    a2.append("#" + "1" + "." * 30 + "2" + "." * 28 + "#")
    a2.append("#" + "." * 62 if False else "#" + "." * 60 + "#")
    while len(a2) < 38:
        a2.append("#" + "." * 60 + "#")
    a2.append("#" * 62)
    parse("area2", a2, [], 62, len(a2), ["littlebill", "bsdemon", "secbot"], "area2",
          ["desk", "vendor"], ["joke_2", "joke_3", "joke_5"], ["ev_vend", "ev_pitch", "ev_intern"])

    # AREA 3 — Open Source Warzone (med/hard). 64x42 — server corridors + kernel panics
    a3 = ["#" * 64]
    a3.append("#E" + "." * 10 + "J" + "." * 51 + "#")
    a3.append("#" + "." * 10 + "#" * 10 + "." * 8 + "#" * 8 + "." * 26 + "#")
    a3.append("#" + "1" + "." * 9 + "#" * 10 + "." + "2" + "." * 6 + "#" * 8 + "." + "p" + "." * 24 + "#")
    a3.append("#" + "." * 10 + "#" * 10 + "." * 8 + "#" * 8 + "." * 8 + "#" * 8 + "1" + "." + "#")
    a3.append("#" + "." * 4 + "C" + "." * 5 + "#" * 10 + "^" * 4 + "." * 4 + "2" + "#" * 8 + "." * 8 + "#" * 8 + "." * 5 + "#")
    a3.append("#" + "." * 26 + "^" * 4 + "." * 4 + "#" * 20 + "." * 4 + "#")
    a3.append("#" + "2" + "." * 24 + "^" * 4 + "." * 4 + "#" * 20 + "." * 4 + "#")
    a3.append("#" + "#" * 12 + "." * 16 + "#" * 4 + "d" + "#" * 17 + "." * 4 + "#")
    a3.append("#" + "#" * 12 + "." + "H" + "." * 13 + "#" * 4 + "." * "1".__len__() + "#" * 17 + "." * 4 + "#")
    a3.append("#" + "." * 6 + "3" + "." * 5 + "#" * 12 + "." * 16 + "#" * 12 + "1" + "." * 6 + "#")
    a3.append("#" + "." * 6 + "#" * 12 + "." * 16 + "#" * 12 + "." * 6 + "#")
    a3.append("#" + "." * 6 + "#" * 12 + "V" + "." * 14 + "#" * 12 + "2" + "." * 5 + "#")
    a3.append("#" + "." * 6 + "#" * 12 + "." * 16 + "#" * 12 + "." * 6 + "#")
    a3.append("#" + "." * 60 + "#")
    a3.append("#" + "." * 8 + "3" + "." * 10 + "2" + "." * 8 + "^" * 3 + "." * 9 + "J" + "." * 16 + "#")
    a3.append("#" + "." * 60 + "#")
    a3.append("#" + "d" + "." * 58 + "#")
    a3.append("#" + "." * 60 + "#")
    a3.append("#" + "." * 30 + "#" * 6 + "." * 24 + "#")
    a3.append("#" + "." * 30 + "#" * 6 + "E" if False else "#" + "." * 30 + "#" * 6 + "." * 24 + "#")
    a3.append("#" + "." * 30 + "#" * 6 + "." * 24 + "#")
    a3[-3] = "#" + "." * 24 + "1" + "." * 35 + "#"
    a3[-4] = "#" + "." * 60 + "#"
    a3.append("#" + "." * 60 + "#")
    while len(a3) < 40:
        a3.append("#" + "." * 60 + "#")
    a3.append("#" * 64)
    # exit at east
    a3[35] = "#" + "." * 61 if False else "#" + "." * 60 + "#"
    a3[35] = "#" + "." * 33 + "E" + "." * 29 + "#"
    parse("area3", a3, [], 64, len(a3), ["bsdemon", "gplhipster"], "area3",
          ["rack", "vendor"], ["joke_4", "joke_6", "joke_10", "joke_11"], ["ev_hack", "ev_meme", "ev_elevator"])

    # AREA 4 — Valley of Unicorns (hard). 66x40 glass towers + billboards
    a4 = ["#" * 66]
    a4.append("#E" + "." * 14 + "d" + "." * 48 + "#")
    a4.append("#" + "." * 14 + "#" * 6 + "." * 10 + "#" * 4 + "." * 28 + "#")
    a4.append("#" + "C" + "." + "4" + "." * 11 + "#" * 6 + "." + "J" + "." * 8 + "#" * 4 + "." * 28 + "#")
    a4.append("#" + "." * 14 + "#" * 6 + "." * 10 + "#" * 4 + "#" * 8 + "." * 17 + "#")
    a4.append("#" + "." * 4 + "5" + "." * 9 + "#" * 6 + "4" + "." * 8 + "#" * 4 + "." * 10 + "p" + "#" * 6 + "." * 14 + "#")
    a4.append("#" + "." * 14 + "#" * 6 + "." * 10 + "#" * 4 + "." * 8 + "4" + "#" * 16 + "#")
    a4.append("#" + "#" * 6 + "." * 12 + "#" * 6 + "." * 22 + "#" * 4 + "." * 12 + "#")
    a4.append("#" + "#" * 6 + "." + "H" + "." * 10 + "#" * 6 + "5" + "." * 4 + "^" * 4 + "." * 12 + "#" * 4 + "." * 6 + "3" + "..." + "#")
    a4.append("#" + "#" * 6 + "." * 12 + "#" * 6 + "." * 4 + "^" * 4 + "." * 12 + "#" * 4 + "." * 12 + "#")
    a4.append("#" + "." * 20 + "#" * 4 + "." * 4 + "^" * 4 + "." * 30 + "#")
    a4.append("#" + "." * 20 + "#" * 4 + "V" + "." * 3 + "^" * 4 + "." * 26 + "5" + "#" + "." + "#")
    a4.append("#" + "." * 60 + "#")
    a4.append("#" + "4" + "." * 10 + "#" * 10 + "." * 6 + "#" * 10 + "." * 26 + "#")
    a4.append("#" + "." * 6 + "5" + "." * 3 + "#" * 10 + "." + "d" + "." * 5 + "#" * 10 + "." * 4 + "J" + "." * 18 + "#")
    a4.append("#" + "." * 10 + "#" * 10 + "." * 6 + "#" * 10 + "." * 26 + "#")
    a4.append("#" + "." * 10 + "#" * 10 + "." * 6 + "#" * 10 + "." * 26 + "#")
    a4.append("#" + "." * 64 + "#")
    a4.append("#" + "." * 64 + "#")
    while len(a4) < 38:
        a4.append("#" + "." * 64 + "#")
    a4.append("#" * 66)
    a4[-2] = "#" + "." * 40 + "B" + "." * 23 + "#"
    parse("area4", a4, [], 66, len(a4), ["littlebill_elite", "bsdemon_elite", "gplhipster_elite", "secbot"], "area4",
          ["billboard", "vendor"], ["joke_7", "joke_8"], ["ev_shark", "ev_drone", "ev_pitch"])

    # AREA 5 — Oakland Escape Terminal (very hard). 60x44, boss arena at top
    a5 = ["#" * 60]
    for y in range(1, 6):
        if y == 1:
            a5.append("#E" + "." * 57 + "#")
        else:
            a5.append("#" + "." * 58 + "#")
    a5.append("#" + "." * 5 + "C" + "." * 50 + "#")
    a5.append("#" + "." * 58 + "#")
    # corridor into arena
    row = "#" * 20 + "." * 20 + "#" * 19 + "#"
    a5.append("#" + "#" * 18 + "." * 20 + "#" * 19 + "#")
    # boss arena rows
    arena = []
    arena.append("#" * 60)
    for i in range(14):
        if i == 0:
            arena.append("#" + "#" * 19 + "." * 20 + "#" * 19 + "#")
        elif i == 13:
            arena.append("#" * 60)
        else:
            inner = "." * 58
            arena.append("#" + inner + "#")
    a5[0] = "#" * 60
    a5[1] = "#E" + "." * 57 + "#"
    # build arena rows 0..14 at top, rest of level below
    final = []
    final.append("#" * 60)
    final.append("#" + "." * 18 + "B" + "." * 19 + "#")  # gate line
    for i in range(1, 13):
        final.append("#" + "." * 58 + "#")
    final.append("#" * 20 + "." * 16 + "#" * 23)  # wall with corridor gap
    final.append("#" * 20 + "." * 16 + "#" * 23)
    final.append("#" * 20 + "." * 16 + "#" * 23)
    final.append("#" * 19 + "d" + "." * 15 + "#" * 23)
    final.append("#" * 19 + "." * 15 + "#" * 24)
    final.append("#" + "." * 58 + "#")
    final.append("#" + "." * 5 + "C" + "." * 12 + "5" + "." * 3 + "6" + "." * 30 + "#")
    final.append("#" + "." * 44 + "^" * 4 + "." * 9 + "#")
    final.append("#" + "6" + "." * 12 + "#" * 8 + "d" + "." * 20 + "#" * 6 + "." * 6 + "#")
    final.append("#" + "." * 12 + "#" * 8 + "." * 20 + "#" * 6 + "." + "J" + "." * 4 + "#")
    final.append("#" + "." * 6 + "V" + "." * 5 + "#" * 8 + "." + "5" + "." * 17 + "#" * 6 + "." * 6 + "#")
    final.append("#" + "." * 30 + "^" * 3 + "." * 23 + "#")
    final.append("#" + "." * 30 + "#" * 10 + "." + "H" + "#" * 17 + "#")
    final.append("#" + "." * 30 + "#" * 10 + "." * 17 + "#")
    final.append("#" + "." * 30 + "." * 26 + "#")
    final.append("#" + "." * 58 + "#")
    final.append("#" + "." * 10 + "6" + "." * 4 + "5" + "." * 40 + "#")
    final.append("#" + "." * 58 + "#")
    final.append("#E" + "." * 57 + "#")
    final.append("#" * 60)
    # boss spawns are deterministic entities added by code, not markers
    parse("area5", final, [], 60, len(final), ["littlebill_elite", "bsdemon_elite", "gplhipster_elite", "secbot_elite"], "area5",
          ["gate", "vendor"], ["joke_13", "joke_14", "joke_15"], ["ev_drone", "ev_atm"])

if __name__ == "__main__":
    items_json()
    characters_json()
    json.dump(ABILITIES, open(D("abilities.json"), "w"), indent=1)
    achievements_json()
    loot_json()
    dialogue_json()
    build_maps()
    for n in ["area1", "area2", "area3", "area4", "area5"]:
        d = json.load(open(D("levels", n + ".json")))
        w, h = d["w"], d["h"]
        assert len(d["grid"]) == w * h, f"{n}: grid {len(d['grid'])} != {w*h}"
        # every entity on a non-wall tile
        for e in d["entities"]:
            t = d["grid"][e["y"] * w + e["x"]]
            assert t == 0, f"{n}: entity {e} on tile {t}"
        print(n, "OK", w, "x", h, "entities:", len(d["entities"]))
