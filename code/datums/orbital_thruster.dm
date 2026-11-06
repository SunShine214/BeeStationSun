#define ORBITAL_THRUSTER_MAX_PLUME 50

/datum/orbital_thruster
	/// Throttle; not used internally, and is meant only for external thrust management. Between 0 and 1
	var/throttle = 0
	/// The thrust of this thruster in Newtons
	var/thrust = 0
	var/throttleable = TRUE
	var/datum/weakref/parent

/datum/orbital_thruster/New(starting_parent, starting_throttleable = TRUE)
	parent = WEAKREF(starting_parent)
	throttleable = starting_throttleable
	SSorbital_altitude.orbital_thrusters += src

/datum/orbital_thruster/Destroy()
	SSorbital_altitude.orbital_thrusters -= src
	QDEL_NULL(parent)
	. = ..()

/datum/orbital_thruster/proc/set_throttle(to_set)
	throttle = clamp(to_set, 0, 1)

/datum/orbital_thruster/proc/get_thrust()
	return thrust

/datum/orbital_thruster/proc/do_plume(turf/starting, direction)
	var/thrust = get_thrust()
	if(!thrust)
		return

	var/tile_damage = 10 * log(10, thrust)
	var/obj_damage = 3 * log(10, thrust)
	var/mob_damage = 1 * log(10, thrust)

	var/turf/current_turf = get_step(starting, direction)
	for(var/i in 1 to ORBITAL_THRUSTER_MAX_PLUME)
		var/dense = FALSE
		for (var/atom/thing in current_turf)

			if(QDELETED(thing))
				continue

			// Objects
			if (isobj(thing))
				if (iseffect(thing))
					continue

				var/obj/obj_thing = thing
				obj_thing.newtonian_move(REVERSE_DIR(direction))

				if (obj_thing.density)
					dense = TRUE
				// Apply object damage
				obj_thing.take_damage(obj_damage, BURN, FIRE)

			// Mobs
			if (ismob(thing))
				if (isobserver(thing))
					continue

				var/mob/mob_thing = thing
				mob_thing.newtonian_move(REVERSE_DIR(direction))

				mob_thing.take_damage(mob_damage, BURN)

				if (isliving(mob_thing))
					var/mob/living/living_thing = mob_thing
					living_thing.adjustFireLoss(mob_damage)

		// Apply damage to turf if not blocked
		if (!dense)
			current_turf.take_damage(tile_damage, BURN, FIRE, TRUE, direction)
		else
			return
		current_turf = get_step(current_turf, direction)
		if(!current_turf)
			return

