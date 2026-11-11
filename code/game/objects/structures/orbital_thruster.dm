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
	var/obj/machinery/orbital_thruster_nozzle/nozzle

	/// What ratio of power does this thruster consume from the power grid?
	var/power_ratio = 0.01
	/// How much power, in watts, was drawn last process()
	var/last_power = 0
	/// How many liters/second are injected into the accelerator
	var/injection_rate = 50

/obj/machinery/atmospherics/components/unary/orbital_thruster/Initialize(mapload)
	. = ..()
	nozzle = new(get_step(get_turf(src), REVERSE_DIR(dir)), src)
	power_link = new(get_turf(src))
	power_link.resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	power_link.invisibility = INVISIBILITY_ABSTRACT
	thruster = new(src)

/obj/machinery/atmospherics/components/unary/orbital_thruster/Destroy()
	QDEL_NULL(thruster)
	QDEL_NULL(power_link)
	QDEL_NULL(nozzle)
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

	nozzle.update_appearance()
	update_parents()

/obj/machinery/atmospherics/components/unary/orbital_thruster/update_overlays()
	. = ..()

// Effect Component.
/obj/machinery/orbital_thruster_nozzle
	name = "orbital thruster"
	desc = "A massive thruster used to adjust the station's orbit."
	icon = 'icons/obj/orbital_thruster.dmi'
	icon_state = "orbital_thruster_nozzle"
	anchored = TRUE
	density = TRUE
	use_power = NO_POWER_USE
	idle_power_usage = 0

	var/datum/weakref/body

/obj/machinery/orbital_thruster_nozzle/Initialize(mapload, obj/machinery/atmospherics/components/unary/orbital_thruster/parent)
	if(!parent)
		stack_trace("An orbital thruster nozzle has spawned without a parent piece!")
		return INITIALIZE_HINT_QDEL
	body = WEAKREF(parent)
	. = ..()

/obj/machinery/orbital_thruster_nozzle/Destroy()
	QDEL_NULL(body)
	return ..()

/obj/machinery/orbital_thruster_nozzle/update_overlays()
	. = ..()
	var/obj/machinery/atmospherics/components/unary/orbital_thruster/back_end_piece = body.resolve()
	if(back_end_piece.thruster?.get_thrust() > 0)
		. += mutable_appearance('icons/obj/orbital_thruster.dmi', "orbital_thruster_beam", ABOVE_OBJ_LAYER)

#undef ENERGY_TO_THRUST_COEFF
