SUBSYSTEM_DEF(superstructure)
	name = "Superstructure"
	flags = SS_NO_FIRE

	/// What health is the station at?
	var/hull_integrity = 1000
	/// Maximum integrity
	var/max_integrity = 1000
	/// What reentry resistant shielding is remaining for the station?
	var/shielding_integrity = 1000
	/// Maximum shielding
	var/max_shielding = 1000

	COOLDOWN_DECLARE(hull_cooldown)
	COOLDOWN_DECLARE(shielding_cooldown)

/datum/controller/subsystem/superstructure/proc/damage_structure(amount)
	// TODO

/datum/controller/subsystem/superstructure/proc/adjust_hull(amount)
	hull_integrity = clamp(hull_integrity + amount, 0, max_integrity)
	if(!COOLDOWN_FINISHED(src, hull_cooldown) && amount < 0)
		return
	play_global(pick('sound/effects/creak1.ogg', 'sound/effects/creak2.ogg', 'sound/effects/creak3.ogg'))
	COOLDOWN_START(src, hull_cooldown, rand(5, 9) SECONDS)

/datum/controller/subsystem/superstructure/proc/adjust_shielding(amount)
	shielding_integrity = clamp(shielding_integrity + amount, 0, max_shielding)
	if(!COOLDOWN_FINISHED(src, shielding_cooldown) && amount < 0)
		return
	play_global(pick('sound/effects/creak1.ogg', 'sound/effects/creak2.ogg', 'sound/effects/creak3.ogg')) // TODO - REPLACE THESE with more appropriate "low damage" sounds.
	COOLDOWN_START(src, shielding_cooldown, rand(5, 9) SECONDS)

/datum/controller/subsystem/superstructure/proc/play_global(sound)
	for(var/mob/player_mob in GLOB.player_list)
		if(is_station_level(get_turf(player_mob)))
			SEND_SOUND(player_mob, sound)
