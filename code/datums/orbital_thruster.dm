/datum/orbital_thruster
	var/throttle = 0 // Between 0 and 1
	///The thrust of this thruster in Mega Newtons
	var/maximum_thrust = 0
	var/active = TRUE
	var/throttleable = TRUE
	var/datum/weakref/parent

/datum/orbital_thruster/New(starting_parent, starting_active = TRUE, starting_throttleable = TRUE)
	parent = WEAKREF(starting_parent)
	active = starting_active
	throttleable = starting_throttleable
	SSorbital_altitude.orbital_thrusters += src

/datum/orbital_thruster/Destroy()
	SSorbital_altitude.orbital_thrusters -= src
	QDEL_NULL(parent)
	. = ..()

/datum/orbital_thruster/proc/set_active(to_set)
	if(active == to_set)
		return
	active = to_set
	SEND_SIGNAL(src, COMSIG_THRUSTER_ACTIVE_CHANGE, active)

/datum/orbital_thruster/proc/set_throttle(to_set)
	throttle = clamp(to_set, 0, 1)

/datum/orbital_thruster/proc/get_thrust()
	if(!active)
		return 0
	if(!throttleable)
		return maximum_thrust
	return maximum_thrust * throttle
