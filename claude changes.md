# Claude Changes

A log of all modifications made by Claude this session, grouped by feature. Values
reflect the **final** state (some were tuned across iterations). Only Claude's own
changes are listed — your manual edits (e.g. the greedy collider meshing, the
`calculate_direction` spread) are not included.

---

## 1. Realistic zombie combat — brain/spine only kills

Zombies can no longer be killed by body damage; only the brain/spine is lethal,
otherwise they are crippled into a slow but still-dangerous crawler. Where a hit
lands is decided by where you aim relative to the zombie: aim **past/behind** it →
head/spine (kill), aim **short/in front** → legs (cripple), center → torso.

- **`Scripts/Gamedata/DMob.gd`**, **`Scripts/Runtimedata/RMob.gd`** — added optional
  mob fields: `undead`, `brain_health`, `body_health`, `legs_health`, `crawl_speed`
  (parsing, `get_data`, and `overwrite_from_dmob`).
- **`Scripts/Mob/Mob.gd`** — when `undead`:
  - `get_hit()` routes damage via `_apply_undead_hit()` and `_resolve_hit_region()`
    (positional aim → head/legs/torso).
  - `become_crippled()` (slows to `crawl_speed`, keeps attacking), `show_floating_label()`
    (refactored from the miss indicator; shows "Headshot!"/"Crippled!").
  - Pools persist via `get_data()` / `_restore_undead_state_from_json()`.
  - Non-undead mobs keep the original single-health behaviour.
- **`Scripts/EquippedItem.gd`** — melee and ranged attacks now pass `aim_point` +
  `source_position` so mobs can resolve the hit region; ranged damage now comes from
  the loaded ammo instead of a hardcoded `10`.

## 2. New content — weapons, ammo, zombies

- **`Mods/Dimensionfall/Items/Items.json`** — new weapons: **combat knife**, **fire axe**,
  **pump shotgun**, **bolt-action hunting rifle**; upgraded the existing **crowbar** into a
  melee weapon. New ammo (`shell_12gauge`, `round_308`) and magazines (`shotgun_tube`,
  `hunting_rifle_magazine`).
- **`Mods/Dimensionfall/Mobs/Mobs.json`** — converted all existing zombies to the undead
  model (added pools) and added 5 new zombies: **brute, feral, armored, fresh, decayed**.
- **Wiring / references:** `Mobgroups/Mobgroups.json` (new zombies in `basic_zombies`),
  `Mobfaction/Mobfactions.json` (robots hostile to new zombies), `Itemgroups/Itemgroups.json`
  (weapons/ammo into loot), and the matching `references.json` files for mobs and items.

## 3. Weapon attack animations

- **`Scripts/EquippedItem.gd`** — rewrote `animate_attack()` with weapon-type-specific,
  clearly visible motion:
  - **swing** (axe/club/blade): wind-up → wide ~140° arc → recover.
  - **stab** (spear/knife): forward thrust → recover.
  - Uses a stored `_attack_tween` so rapid attacks restart cleanly.
- **`Scripts/Gamedata/DItem.gd`**, **`Scripts/Runtimedata/RItem.gd`** — added an
  `attack_motion` field (`"swing"` default / `"stab"`) to melee items.
- **`Mods/Dimensionfall/Items/Items.json`** — `attack_motion: "stab"` on `stone_spear`
  and `combat_knife`; the rest default to `"swing"`.

## 4. Held weapon display

The player now visibly holds the actual equipped weapon (previously a generic image).

- **`Scripts/EquippedItem.gd`** — `_apply_held_sprite()` sets the held Sprite3D's texture
  to the equipped item's sprite, scales it to a realistic size via
  `HELD_WEAPON_WORLD_SIZE = 0.4` (normalized by the sprite's longest side), and mirrors the
  fire axe with `flip_h` so its handle/blade sit correctly in hand.
- **`Scenes/player.tscn`** — moved both hands' `default_hand_position` / resting transform
  closer to the player (x ≈ -0.19 → -0.1).
- **`Mods/Dimensionfall/Items/fire_axe_32.png`** (+ `.import`) — new 32×32 fire-axe sprite
  matching the existing pixel-art style (red handle, steel head); `Items.json` points the
  `fire_axe` item at it.

## 5. Breaking windows & fences (melee)

Windows/fences are transparent furniture on collision **layer 8**, which the melee hitbox
didn't scan — so they couldn't be meleed (only shot).

- **`Scenes/player.tscn`** — both melee hitboxes' `collision_mask` `14 → 142` (added layer 8),
  so melee now hits and destroys windows/fences (they already had destruction data).

## 6. Climbing mechanic (new)

Press **Space** while pushing into a low obstacle to climb onto it if its top is within
step-up reach and has room to stand; chain climbs off intermediate surfaces for higher
walls. Costs stamina and scales with the Athletics skill (like running).

- **`project.godot`** — new `climb` input action (Space).
- **`Scripts/Helper/SignalBroker/player_input_signal_broker.gd`** — `climb()` signal.
- **`Scripts/input_manager.gd`** — emits the climb signal on key press.
- **`Scripts/player.gd`** — climb constants + `is_climbing`, signal hookup,
  `_physics_process` early-return while climbing, and `_on_climb` / `_find_climb_target` /
  `_probe_surface_y` / `_climb_blocked` / `_execute_climb` (raycast probes + a tween that
  moves the player up onto the surface).

## 7. Bug fixes

- **`Scripts/Chunk.gd`** — guarded the three `chunk_mesh_body.add_child.call_deferred(...)`
  sites with a new `_add_collider_to_mesh_body()` helper (`is_instance_valid` check), fixing
  `"add_child on a previously freed"` errors when a chunk is unloaded mid-generation.
- **`Tests/Unit/test_mob.gd`** — made the mob tests wait (`wait_until`) for the staggered
  2nd mob to spawn and for navigation to be ready, instead of asserting instantly after
  `chunk_generated` (fixes flaky "1 of 2 mobs" / "mob not moving" failures).

## 8. Performance — post-load chunk stutter

Bounded the per-chunk main-thread spikes during chunk streaming:

- **`Scripts/Chunk.gd`** — navigation `cell_size` `0.1 → 0.2` (≈4× fewer navmesh cells →
  cheaper bake + apply); itemgroup/loot spawn batched at a small fixed size.
- **`Scripts/FurnitureStaticSpawner.gd`** — furniture spawn batch capped at a small fixed
  size (was proportional to chunk density, so dense chunks spiked hardest).

## 9. Tests

- **`Tests/Unit/test_mob_undead.gd`** (new) — head hit kills an undead mob; torso/leg damage
  cripples but never kills; positional region resolution; non-undead mobs still die normally.
- **`Mods/Test/Mobs/Mobs.json`** — added a `generic_undead_mob` fixture for the tests.

---

## Verification

- All GDScript run through `gdformat`.
- GUT unit suite passes (68 existing + the new undead tests); project boots headless cleanly.
- Note: visual/feel items (held sprite orientation & size, climb feel, the post-load lag)
  can only be fully confirmed by playing in-game.

## Notes & follow-ups

- A separate pre-existing bug was flagged (not fixed here): a saved mob's `current_health`
  is written on save but never restored on load, so wounded non-undead mobs heal to full
  after a save/load.
- If the post-load stutter persists, the next (gameplay-affecting) lever is lowering
  `creation_radius` `2 → 1` in `LevelGenerator.gd` (loads 9 chunks after spawn instead of 25,
  at the cost of more chunk pop-in).
- A `local-toolchain` note was saved to Claude's memory (Godot exe path, how to run GUT /
  gdformat) — outside this repo.
