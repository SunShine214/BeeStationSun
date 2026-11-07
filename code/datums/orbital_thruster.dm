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
		if(current_turf.is_blocked_turf())
			break
		current_turf = get_step(current_turf, direction)
		if(!current_turf)
			break // TODO - Fix

