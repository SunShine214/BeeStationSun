#define ENERGY_TO_THRUST_COEFF 100000

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

	var/obj/machinery/power/terminal/invisible/power_link
	var/datum/orbital_thruster/thruster

	/// What ratio of power does this thruster consume from the power grid?
	var/power_ratio = 0.01
	/// How much power, in watts, was drawn last process()
	var/last_power = 0
	/// How many liters/second are injected into the accelerator
	var/injection_rate = 50

/obj/machinery/atmospherics/components/unary/orbital_thruster/Initialize(mapload)
	. = ..()
	power_link = new(get_turf(src))
	power_link.resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	power_link.invisibility = INVISIBILITY_ABSTRACT
	thruster = new(src)

/obj/machinery/atmospherics/components/unary/orbital_thruster/Destroy()
	QDEL_NULL(thruster)
	QDEL_NULL(power_link)
	. = ..()

/obj/machinery/atmospherics/components/unary/orbital_thruster/process(delta_time)
	var/usage = power_link.avail() * power_ratio * thruster.throttle
	var/surplus = power_link.surplus()

	if(surplus < usage)
		usage = surplus

	last_power = usage
	power_link.add_load(usage)


/obj/machinery/atmospherics/components/unary/orbital_thruster/process_atmos()

	var/datum/gas_mixture/input = airs[1]
	var/datum/gas_mixture/amount_pumped = input.remove_specific_ratio(/datum/gas/ionic_fuel, (injection_rate / input.volume) * thruster.throttle)

	var/power_mult = last_power + 1 ? log(last_power + 1) : 0 // More thrusters means higher power efficiency

	thruster.thrust = power_mult * amount_pumped?.total_moles() * ENERGY_TO_THRUST_COEFF

	update_parents()
	update_appearance()

/obj/machinery/atmospherics/components/unary/orbital_thruster/update_overlays()
	. = ..()

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

#undef ENERGY_TO_THRUST_COEFF
