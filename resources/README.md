# Custom Resources

The game's data model is built on custom Godot `Resource` classes:

- `scripts/inventory/ItemResource.gd` — items (name, rarity, slot, mods, icon)
- `scripts/inventory/AbilityResource.gd` — abilities (level, cost, cooldown, type)
- `scripts/combat/CharacterStats.gd` — the player stat block

Authoring lives in `data/*.json` (human-editable, easily balanced/tested), and
`ItemRegistry` / `AbilityRegistry` instantiate typed Resources from it at boot.
Each dropped item is a duplicated Resource instance so randomized affixes and
quantity stay independent — the same pattern a `.tres` per item would use,
without shipping hundreds of nearly-identical resource files.

`resources/items` and `resources/abilities` are reserved for hand-authored
`.tres` overrides if you want to design specific uniques in the editor and add
them to the registries.
