// Functional Component.
/obj/machinery/atmospherics/components/unary/orbital_thruster
	name = "orbital thruster"
	desc = "A massive thruster used to adjust the station's orbit."
	icon = 'icons/obj/orbital_thruster.dmi'
	icon_state = "top"
	device_type = UNARY
	anchored = TRUE
	density = TRUE
	dir = NORTH
	initialize_directions = NORTH
	pipe_flags = PIPING_ONE_PER_TURF | PIPING_DEFAULT_LAYER_ONLY

	var/throttle = -1 // Between -1 and 1
	///The thrust of this thruster in Mega Newtons
	var/thrust_strength = 100 MEGANEWTON //todo fix

/obj/machinery/atmospherics/components/unary/orbital_thruster/Initialize(mapload)
	. = ..()
	SSorbital_altitude.orbital_thrusters += src
	new /obj/machinery/orbital_thruster_nozzle(get_step(get_turf(src), dir), src)

/obj/machinery/atmospherics/components/unary/orbital_thruster/Destroy()
	SSorbital_altitude.orbital_thrusters -= src
	return ..()

/obj/machinery/atmospherics/components/unary/orbital_thruster/process_atmos()
	//TODO - add gas effects
	thrust_strength = initial(thrust_strength) * throttle
	// Update the pipe network once at the end if we modified anything
	update_parents()
	update_appearance()

/obj/machinery/atmospherics/components/unary/orbital_thruster/update_overlays()
	. = ..()

/// Set target throttle level for thruster.
/obj/machinery/atmospherics/components/unary/orbital_thruster/proc/set_throttle(new_throttle)
	throttle = clamp(new_throttle, -1, 1)

// Effect Component.
/obj/machinery/orbital_thruster_nozzle
	name = "orbital thruster"
	desc = "A massive thruster used to adjust the station's orbit."
	icon = 'icons/obj/orbital_thruster.dmi'
	icon_state = "bottom"
	anchored = TRUE
	density = TRUE
	use_power = NO_POWER_USE
	idle_power_usage = 0

	/// Current visual thrust level
	var/visual_thrust = 0
	/// Sound loop for the thruster
	var/datum/looping_sound/orbital_thruster/soundloop

	/// The backend thruster piece this nozzle is linked to
	var/obj/machinery/atmospherics/components/unary/orbital_thruster/back_end_piece

/obj/machinery/orbital_thruster_nozzle/Initialize(mapload, obj/machinery/atmospherics/components/unary/orbital_thruster/parent)
	. = ..()
	if(!parent)
		CRASH("An orbital thruster nozzle has spawned without a parent piece!")
	soundloop = new(src, FALSE)

/obj/machinery/orbital_thruster_nozzle/Destroy()
	if(visual_thrust > 0)
		remove_emitter("thruster")
	QDEL_NULL(soundloop)
	return ..()

/obj/machinery/orbital_thruster_nozzle/update_overlays()
	. = ..()
	if(visual_thrust > 0)
		var/mutable_appearance/glow = mutable_appearance('icons/obj/orbital_thrust_effect.dmi', "glow")
		// Calculate alpha based on thrust level (0-40 range from subsystem)
		// Scale from 0 to 255 alpha
		glow.alpha = clamp((visual_thrust / 40) * 255, 0, 255)
		glow.pixel_x = -32
		glow.pixel_y = -8
		glow.layer = ABOVE_OBJ_LAYER
		. += glow

/obj/machinery/orbital_thruster_nozzle/proc/update_thruster_effect(thrust)
	//TODO - fix effects to use particle_holder (once merging upstream)

/obj/machinery/orbital_thruster_nozzle/proc/apply_thrust_damage()
	// Cast a ray 5 tiles in the direction of the thruster
	var/turf/current_turf = get_turf(src)
	if(!current_turf)
		return

	// Calculate base damage based on thrust level
	var/base_damage = abs(SSorbital_altitude.thrust * 2)

	// Cast ray for 5 tiles
	for(var/distance = 1 to 5)
		current_turf = get_step(current_turf, dir)
		if(!current_turf)
			break

		// Get the current turf and its adjacent turfs
		var/list/affected_turfs = list(current_turf)
		affected_turfs += get_adjacent_open_turfs(current_turf)

		// Calculate damage falloff based on distance (100% at tile 1, 20% at tile 5)
		var/distance_multiplier = 1 - ((distance - 1) * 0.2)
		var/damage = base_damage * distance_multiplier

		// Track if we played sound this tick for this turf to avoid spam
		var/played_sound = FALSE

		// Apply damage to all affected turfs
		for(var/turf/affected_turf in affected_turfs)
			// Apply damage to all mobs in the turf
			for(var/mob/living/living_mob in affected_turf)
				living_mob.adjustFireLoss(damage)
				if(!played_sound)
					playsound(affected_turf, 'sound/effects/wounds/sizzle1.ogg', 50, vary = TRUE)
					played_sound = TRUE

			// Also damage objects
			for(var/obj/damaged_obj in affected_turf)
				if(damaged_obj.resistance_flags & INDESTRUCTIBLE)
					continue
				damaged_obj.take_damage(damage / 2)
				if(!played_sound)
					playsound(affected_turf, 'sound/effects/wounds/sizzle1.ogg', 50, vary = TRUE)
					played_sound = TRUE
