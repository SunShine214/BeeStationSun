#define ENERGY_TO_THRUST_COEFF 100000

/obj/machinery/atmospherics/components/unary/orbital_thruster
	name = "orbital thruster"
	desc = "A massive thruster used to adjust the station's orbit."
	icon = 'icons/obj/orbital_thruster.dmi'
	icon_state = "orbital_thruster_body"
	device_type = UNARY
	anchored = TRUE
	density = TRUE
	dir = NORTH
	initialize_directions = NORTH
	pipe_flags = PIPING_ONE_PER_TURF | PIPING_DEFAULT_LAYER_ONLY

	var/obj/machinery/power/terminal/invisible/power_link
	var/datum/orbital_thruster/thruster
	var/obj/structure/orbital_thruster_nozzle/nozzle

	/// What ratio of power does this thruster consume from the power grid?
	var/power_ratio = 0.01
	/// How much power, in watts, was drawn last process()
	var/last_power = 0
	/// How many liters/second are injected into the accelerator
	var/injection_rate = 50

/obj/machinery/atmospherics/components/unary/orbital_thruster/Initialize(mapload)
	. = ..()
	nozzle = new(get_step(get_turf(src), REVERSE_DIR(dir)), src)
	RegisterSignal(nozzle, COMSIG_QDELETING, PROC_REF(nozzle_gone))
	power_link = new(get_turf(src))
	power_link.resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	power_link.invisibility = INVISIBILITY_ABSTRACT
	thruster = new(src)

/obj/machinery/atmospherics/components/unary/orbital_thruster/Destroy()
	UnregisterSignal(nozzle, COMSIG_QDELETING)
	QDEL_NULL(thruster)
	QDEL_NULL(power_link)
	if(!QDELETED(nozzle))
		QDEL_NULL(nozzle)
	. = ..()

/obj/machinery/atmospherics/components/unary/orbital_thruster/proc/nozzle_gone()
	qdel(src)

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

	nozzle.update_appearance()
	update_parents()

/obj/machinery/atmospherics/components/unary/orbital_thruster/update_overlays()
	. = ..()

// Effect Component.
/obj/structure/orbital_thruster_nozzle
	name = "orbital thruster"
	desc = "A massive thruster used to adjust the station's orbit."
	icon = 'icons/obj/orbital_thruster.dmi'
	icon_state = "orbital_thruster_nozzle"
	anchored = TRUE
	density = TRUE

	var/datum/weakref/body
	var/obj/effect/abstract/particle_holder/ion_trail

/obj/structure/orbital_thruster_nozzle/Initialize(mapload, obj/machinery/atmospherics/components/unary/orbital_thruster/parent)
	if(!parent)
		stack_trace("An orbital thruster nozzle has spawned without a parent piece!")
		return INITIALIZE_HINT_QDEL
	body = WEAKREF(parent)
	ion_trail = new(src, /particles/ion_trail)
	ion_trail.plane = ABOVE_LIGHTING_PLANE
	ion_trail.vis_flags &= ~VIS_INHERIT_PLANE
	ion_trail.alpha = 0
	. = ..()

/obj/structure/orbital_thruster_nozzle/update_overlays()
	. = ..()
	var/obj/machinery/atmospherics/components/unary/orbital_thruster/back_end_piece = body.resolve()
	if(back_end_piece.thruster)
		ion_trail.alpha = clamp(3e-5 * back_end_piece.thruster.get_thrust(), 0, 255) // Here since there is no update_particles() TODO - check if there is. Also, clean up nullable checks, since parent should never be null!
		ion_trail.set_particle_spawning(clamp(5e-6 * back_end_piece.thruster.get_thrust(), 0, 15))
		. += mutable_appearance('icons/obj/orbital_thruster.dmi', "orbital_thruster_beam", layer, alpha = clamp(5e-5 * back_end_piece.thruster.get_thrust(), 0, 255))
		. += emissive_appearance('icons/obj/orbital_thruster.dmi', "orbital_thruster_beam", layer, alpha = clamp(5e-5 * back_end_piece.thruster.get_thrust(), 0, 255))

/particles/ion_trail
	icon = 'icons/effects/particles/generic.dmi'
	icon_state = list("trail")
	velocity = list(0, -25, 0)
	color = "#2fffff"
	lifespan = 0.5 SECONDS
	fade = 0.5 SECONDS
	spawning = 0
	count = 200
	position = generator(GEN_VECTOR, list(-5, 0), list(6, 0), NORMAL_RAND)
	height = 300

#undef ENERGY_TO_THRUST_COEFF
