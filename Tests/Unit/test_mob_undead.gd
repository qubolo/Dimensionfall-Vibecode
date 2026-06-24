extends GutTest

# Tests for the undead hit-region combat model on Mob (see Scripts/Mob/Mob.gd).
# Zombies (undead mobs) can only be killed by destroying the brain/spine. Damage to
# the torso or legs cripples them into a slow crawler but never kills them. Which
# region is struck is decided by where the attacker aimed relative to the mob:
# aiming past/behind the mob hits the head, aiming short/in front hits the legs.
#
# These use the Test mod's "generic_undead_mob" (brain 30, body 100, legs 40) and
# do not rely on chunk generation, so they have their own lifecycle.

const UNDEAD_ID := "generic_undead_mob"
const PLAIN_ID := "generic_test_mob"

# Geometry for the tests: attacker south of the mob, mob 10m to the north.
var attacker_pos := Vector3(10, 1, 0)
var mob_pos := Vector3(10, 1, 10)


func before_all():
	var custom_mods: Array[DMod] = [Gamedata.mods.by_id("Core"), Gamedata.mods.by_id("Test")]
	Runtimedata.reconstruct(custom_mods)
	await get_tree().process_frame


func after_all():
	Runtimedata.reset()


# Free any mobs/corpses left behind so tests stay isolated.
func after_each():
	for mob in get_tree().get_nodes_in_group("mobs"):
		mob.queue_free()
	for item in get_tree().get_nodes_in_group("mapitems"):
		item.queue_free()
	await get_tree().process_frame


# Helper: aim data for a point a given depth beyond the mob center (positive =
# behind the mob, negative = in front of it).
func _attack(damage: float, depth: float) -> Dictionary:
	return {
		"damage": damage,
		"hit_chance": 100.0,
		"source_position": attacker_pos,
		"aim_point": mob_pos + Vector3(0, 0, depth),
	}


# Spawns an undead mob in the scene tree and returns it once ready.
func _spawn_undead() -> Mob:
	var mob := Mob.new(mob_pos, {"id": UNDEAD_ID})
	add_child(mob)
	await wait_frames(2)
	return mob


# The aim point's depth relative to the mob decides the struck region.
func test_resolve_hit_region_from_aim():
	# A CharacterBody3D only resolves its global_position once in the tree, so spawn
	# it rather than using an orphan node.
	var mob := await _spawn_undead()

	assert_eq(
		mob._resolve_hit_region(_attack(10, 3.0)),
		"head",
		"Aiming behind the mob should strike the head/spine."
	)
	assert_eq(
		mob._resolve_hit_region(_attack(10, -3.0)),
		"legs",
		"Aiming in front of the mob should strike the legs."
	)
	assert_eq(
		mob._resolve_hit_region(_attack(10, 0.0)),
		"torso",
		"Aiming at the mob center should strike the torso."
	)
	# No aim data must never resolve to the lethal head region.
	assert_eq(
		mob._resolve_hit_region({"damage": 10}),
		"torso",
		"Without aim data the hit should default to the (non-lethal) torso."
	)


# Destroying the brain (aiming behind the mob) kills an undead mob.
func test_brain_hit_kills_undead():
	var mob := await _spawn_undead()
	# 50 damage > brain_health (30) -> lethal head shot.
	mob.get_hit(_attack(50.0, 3.0))
	await wait_frames(2)
	assert_false(is_instance_valid(mob), "A brain/spine hit should kill an undead mob.")


# Emptying damage into the torso never kills; it only cripples.
func test_torso_damage_cripples_but_does_not_kill():
	var mob := await _spawn_undead()
	# 150 damage > body_health (100) but aimed at the torso -> cripple, not death.
	mob.get_hit(_attack(150.0, 0.0))
	await wait_frames(2)
	assert_true(is_instance_valid(mob), "Torso damage must not kill an undead mob.")
	assert_true(mob.is_crippled, "Destroying the torso should cripple the mob.")
	assert_eq(mob.current_brain_health, 30.0, "Torso damage must not touch the brain pool.")


# Destroying the legs cripples the mob into a slow crawler but keeps it alive.
func test_leg_damage_cripples_into_crawler():
	var mob := await _spawn_undead()
	# 60 damage > legs_health (40), aimed in front -> legs destroyed.
	mob.get_hit(_attack(60.0, -3.0))
	await wait_frames(2)
	assert_true(is_instance_valid(mob), "Leg damage must not kill an undead mob.")
	assert_true(mob.is_crippled, "Destroying the legs should cripple the mob.")
	assert_eq(
		mob.current_move_speed, mob.crawl_speed, "A crippled mob should move at its crawl speed."
	)


# A normal (non-undead) mob still dies from a single health pool as before.
func test_non_undead_mob_dies_from_plain_damage():
	var mob := Mob.new(mob_pos, {"id": PLAIN_ID})
	add_child(mob)
	await wait_frames(2)
	assert_false(mob.undead, "The generic test mob should not be undead.")
	# 200 damage > health (100) -> dead, regardless of where it was aimed.
	mob.get_hit(_attack(200.0, 0.0))
	await wait_frames(2)
	assert_false(is_instance_valid(mob), "A non-undead mob should die when its health hits 0.")
