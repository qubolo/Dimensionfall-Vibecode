# Dimensionfall Vibecoding Changes

A comprehensive log of all modifications, refactors, and feature implementations made during this entire vibecoding session. These reflect the final, verified state of the codebase, combining the efforts of both Claude and Antigravity.

---

## 1. Climbing Mechanics
You can now climb over low obstacles, fences, and crates by pushing into them and pressing `Space`.
- **Dedicated Climb Key**: Pressing `Space` (while pushing towards a climbable surface) hoists your character up onto that surface.
- **Mouse-Relative Integration**: Climbing probes respect your mouse direction, so `W + Space` will flawlessly vault you over the obstacle you're aiming at.
- **Height and Clearance Checks**: You can only climb surfaces that are low enough to step onto (up to ~1.1 units high), and only if there's enough room to actually stand on top.
- **Narrow Object Support**: Adjusted the climbing logic to probe multiple depths when finding a surface to stand on, allowing you to climb narrow objects (like stoves) even if they are pushed flat against a wall.
- **Stamina & Athletics Integration**: Climbing requires stamina. The stamina cost is reduced, and the speed of the climb is increased, the higher your `Athletics` skill is. Every climb also grants a little Athletics XP!

## 2. Realistic Zombie Combat (Brain/Spine only kills)
Zombies can no longer be killed by body damage; only the brain/spine is lethal.
- **Hit Regions**: Where a hit lands is decided by where you aim relative to the zombie: aim **past/behind** it → head/spine (kill), aim **short/in front** → legs (cripple), center → torso.
- **Crippling**: Depleting torso or legs cripples the zombie into a slow but still-dangerous crawler. A crippled undead can still bite and can only be finished off with a brain hit.
- **Visual Feedback**: A floating label indicates "Headshot!" or "Crippled!" when landing crucial hits.
- **Data Architecture**: Added `undead`, `brain_health`, `body_health`, `legs_health`, and `crawl_speed` fields to Mob architectures. Combat mechanics properly parse `aim_point` + `source_position` to resolve hits.

## 3. Melee Mechanics Overhaul
A dynamic and realistic melee system overhaul.
- **Dynamic Reach**: Weapons now thrust outwards based on their physical `reach` property (a knife will have a very short animation, while a spear reaches out significantly further).
- **Attack Animations**: Added `"swing"` (wide ~140° arc) and `"stab"` (forward thrust) attack motion profiles for melee weapons.
- **Impact Flash**: The weapon now flashes a bright, over-exposed white at the apex of the swing to make hits feel more impactful.
- **Weight-based Speed & True Cooldown Tracking**: The speed at which you can attack now scales with the weapon's `weight`. The attack animation has also been mathematically synchronized with the weapon's cooldown timer so the visual swing perfectly matches exactly when the weapon is ready to strike again!
- **Visual Cooldown Indicator**: When a weapon is swung (or a gun is fired), it turns dark grey and smoothly brightens back up as it recharges. Once it hits full brightness, it's ready to use again!

## 4. Mouse-Relative Movement Controls
The movement logic has been fully overhauled from standard world-absolute direction (W=North) to a **Twin-Stick/Cursor-Relative** control scheme!
- **W**: Move forward (towards the mouse cursor).
- **S**: Move backward (away from the mouse cursor).
- **A / D**: Strafe Left / Right relative to where you are aiming.

## 5. Held Weapon Display
The player now visibly holds the actual equipped weapon (previously a generic image).
- **Dynamic Sprite Scaling**: Sets the held Sprite3D's texture to the equipped item's sprite and scales it to a realistic size via `HELD_WEAPON_WORLD_SIZE`.
- **Positioning**: Moved both hands' resting transform closer to the player to look more natural.

## 6. New Content (Weapons, Ammo, Zombies)
- **New Weapons**: Combat knife, fire axe, pump shotgun, bolt-action hunting rifle. The existing crowbar was upgraded into a proper melee weapon.
- **New Ammo & Magazines**: 12-gauge shells, .308 rounds, shotgun tubes, hunting rifle magazines.
- **New Zombies**: Added 5 new zombies (brute, feral, armored, fresh, decayed) to the undead model, wired into generic faction and spawn tables. Added a new 32x32 fire-axe sprite matching the pixel-art style.

## 7. Interaction & Environmental Fixes
- **Breaking Windows & Fences**: Windows/fences are transparent furniture on collision layer 8. Melee hitboxes didn't scan this layer. Added layer 8 to both melee hitboxes so melee now hits and destroys windows/fences.

## 8. Gun and Running Fixes
- Fixed horizontal movement gravity overrides so player movement physics apply correctly.
- Implemented realistic circular bullet spread patterns and heavier recoil for all firearms.
- Increased overall bullet velocity.
- Stamina regeneration now functions while walking (previously you had to stand entirely still).

## 9. Performance & Lag Spike Fixes
Bounded the per-chunk main-thread spikes during chunk streaming to completely eliminate 1-2 second freezing periods.
- **Synchronous Delays Removed**: Replaced all hardcoded game freezes (`OS.delay_msec()`) with Godot's `await get_tree().process_frame`. This cleanly suspends the background loading process for a single frame, handing control back to your GPU and CPU so that your framerate never drops.
- **Forest Chunk Optimizations (Shared Meshes)**: Introduced a **static mesh cache** so identical trees and statics share the exact same mesh in memory. This drastically reduces the memory footprint and CPU load when entering dense forest chunks.
- **Navigation Bake Optimization**: Navigation `cell_size` increased from `0.1` to `0.2` (≈4× fewer navmesh cells), making navigation baking significantly cheaper.
- **Batch Capping**: Furniture, itemgroup, and loot spawn batches are now capped at a small fixed size, so dense chunks don't spike the engine.

## 10. Bug Fixes & Unit Tests
- **Chunk Unload Guard**: Guarded chunk generation sites with an `is_instance_valid` check, fixing `"add_child on a previously freed"` errors when a chunk is unloaded mid-generation.
- **Test Suite Resiliency**: Made mob tests wait securely for staggered spawns to fix flaky tests.
- **New Test Coverage**: Added `Tests/Unit/test_mob_undead.gd` to cover head hits, crippling damage, and positional region resolution. All 68+ tests pass cleanly.

## 11. Version Control
- **Git Initialization**: Initialized a local Git repository for the project.
- **Gitignore**: Created a basic `.gitignore` to exclude `.godot/` cache files, log files, and `export_presets.cfg`.
- **Initial Commit**: Committed all current project files to establish a base restoration point.
