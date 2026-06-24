# Antigravity Changes

This document contains a comprehensive log of all the modifications, refactors, and feature implementations made to the Dimensionfall project over the course of this development session.

## Version Control
- **Git Initialization**: Initialized a local Git repository for the project.
- **Gitignore**: Created a basic `.gitignore` to exclude `.godot/` cache files, log files, and `export_presets.cfg`.
- **Initial Commit**: Committed all current project files to establish a base restoration point.

## Lag Spike Fix
The massive freezing/lag spikes that occurred every few seconds (particularly noticeable when walking into cities) have been completely eliminated.
- **Synchronous Delays Removed**: Previous attempts to prevent chunks from loading too fast relied on `OS.delay_msec()`. This completely froze the game thread.
- **Asynchronous Yielding**: All hardcoded game freezes have been rewritten to use Godot's `await get_tree().process_frame`. This cleanly suspends the background loading process for a single frame, handing control back to your GPU and CPU so that your framerate never drops while walking around.

## Mouse-Relative Movement Controls
The movement logic has been fully overhauled from standard world-absolute direction (W=North) to a **Twin-Stick/Cursor-Relative** control scheme!
- **W**: Move forward (towards the mouse cursor).
- **S**: Move backward (away from the mouse cursor).
- **A / D**: Strafe Left / Right relative to where you are aiming.
- **Climbing**: Climbing probes have also been updated to respect your mouse direction, so `W + Space` will flawlessly vault you over the obstacle you're aiming at!

## Climbing Mechanics
Verified and expanded upon the brand new climbing implementation! You can now climb over low obstacles, fences, and crates.
- **Dedicated Climb Key**: Pressing `Space` (while pushing towards a climbable surface) will now hoist your character up onto that surface.
- **Height and Clearance Checks**: You can only climb surfaces that are low enough to step onto (up to ~1.1 units high), and only if there's enough room to actually stand on top.
- **Narrow Object Support**: Adjusted the climbing logic to probe multiple depths when finding a surface to stand on, allowing you to climb narrow objects (like stoves) even if they are pushed flat against a wall.
- **Stamina & Athletics Integration**: Climbing requires stamina. The stamina cost is reduced, and the speed of the climb is increased, the higher your `Athletics` skill is. Every climb also grants a little Athletics XP!

## Melee Mechanics Overhaul
Fully implemented a dynamic and realistic melee system overhaul.
- **Dynamic Reach**: Weapons now thrust outwards based on their physical `reach` property (a knife will have a very short animation, while a spear reaches out significantly further).
- **Impact Flash**: The weapon now flashes a bright, over-exposed white at the apex of the swing to make hits feel more impactful.
- **Weight-based Speed & True Cooldown Tracking**: The speed at which you can attack now scales with the weapon's `weight`. Heavy axes will swing slow, whereas light knives can attack very rapidly. The attack animation has also been mathematically synchronized with the weapon's cooldown timer so the visual swing perfectly matches exactly when the weapon is ready to strike again!
- **Visual Cooldown Indicator**: When a weapon is swung (or a gun is fired), it turns dark grey and smoothly brightens back up as it recharges. Once it hits full brightness, it's ready to use again!

## Forest Chunk Optimizations
- **Shared Meshes**: Previously, every single tree or piece of static furniture spawned in a chunk generated its own unique 3D mesh resource (like a `PlaneMesh` or `BoxMesh`). In dense forest chunks, this meant thousands of identical resources were being created instantly, causing the game to lag heavily while building the rendering tree. I've introduced a **static mesh cache**, meaning that identical trees now share the exact same mesh in memory. This drastically reduces the memory footprint and CPU load when entering dense forest chunks.

## Gun and Running Fixes
- Fixed horizontal movement gravity overrides so player movement physics apply correctly.
- Implemented realistic circular bullet spread patterns and heavier recoil for all firearms.
- Increased overall bullet velocity.
- Stamina regeneration now functions while walking (previously you had to stand entirely still).
