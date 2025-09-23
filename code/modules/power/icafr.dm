#define ICAFR_MOLS_PER_NANOGRAM 0.01
#define ICAFR_MAX_STABILITY 100
#define ICAFR_NANOGRAM_TO_ENERGY 180000

/obj/machinery/multitile/icafr
	name = "Inertially Confined Antimatter-Fusion Reactor"
	desc = "Using exotic gases and high power lasers it generates an anti-proton fusion reaction that can produce more energy then it consumes."
	var/laser_recievers = list()
	var/obj/machinery/atmospherics/components/unary/icafr_gas_input/fuel_input
	var/obj/machinery/atmospherics/components/unary/icafr_gas_input/annihilation_input
	var/antimatter_production = 0
	var/throttle = 0
	var/stability = ICAFR_MAX_STABILITY

/obj/machinery/multitile/icafr/Initialize(mapload)
	. = ..()

/obj/machinery/multitile/icafr/process_atmos()
	var/laser_power = 0
	for(var/power in laser_recievers)
		laser_power = min(laser_power, power)
	antimatter_production = (laser_power * 0.5 / ICAFR_NANOGRAM_TO_ENERGY) * throttle //half the laser energy goes into making antimatter


/obj/machinery/multitile/icafr/setup_objects()
	fuel_input = new (get_step(get_turf(src), NORTH), src)
	annihilation_input = new (get_step(get_turf(src), SOUTH), src)

	fuel_input.dir = NORTH
	fuel_input.set_init_directions()
	annihilation_input.dir = SOUTH
	annihilation_input.set_init_directions()

	var/obj/structure/icafr_laser_lens/lens_east = new (get_step(get_turf(src), EAST), src)
	var/obj/structure/icafr_laser_lens/lens_west = new (get_step(get_turf(src), WEST), src)
	laser_recievers[lens_east] = 0
	laser_recievers[lens_west] = 0

	components = list(fuel_input, annihilation_input, lens_east, lens_west)

/obj/machinery/multitile/icafr/proc/get_fuel_value(/datum/gas_mixture/input_mix)
	return GET_MOLES(/datum/gas/plasma, input_mix) + (GET_MOLES(/datum/gas/bz, input_mix)*8) + (GET_MOLES(/datum/gas/tritium, input_mix)*32)

/obj/machinery/multitile/icafr/proc/annihilate_gas(/datum/gas_mixture/input_mix, input_antimatter)
	var/datum/gas_mixture/temp_mix = input_mix.remove(input_antimatter * ICAFR_MOLS_PER_NANOGRAM)
	var/annihilated = (temp_mix.total_moles() * ICAFR_MOLS_PER_NANOGRAM)
	if(annihilated < input_antimatter + 10) //+ 10 is for a safety net for imperfect calculations
		reduce_stability(-((input_antimatter + 10) - annihilated))
	var/production_metric = 1
	return annihilated * ICAFR_NANOGRAM_TO_ENERGY * production_metric


/obj/machinery/multitile/icafr/proc/reduce_stability(change_amount)
	stability = clamp(stability + change_amount, 0, ICAFR_MAX_STABILITY)

/obj/machinery/multitile/icafr/proc/get_stability_value(/datum/gas_mixture/input_mix)
	if(input_mix.total_moles() <= 0)
		return 0
	var/co2_percent = GET_MOLES(/datum/gas/carbon_dioxide, input_mix) / input_mix.total_moles()
	var/pluox_percent = GET_MOLES(/datum/gas/pluoxium, input_mix) / input_mix.total_moles()

/obj/machinery/multitile/icafr/proc/output_power(power_to_output)
	return

/obj/machinery/multitile/icafr/proc/laser_hit(obj/structure/icafr_laser_lens/reciever, laser_strength)
	if(!laser_recievers[reciever])
		CRASH("ICAFR recieving laser from unrecognized laser lens")
	laser_recievers[reciever] += laser_strength


/obj/machinery/atmospherics/components/unary/icafr_gas_input
	density = TRUE
	anchored = TRUE
	var/obj/machinery/atmospherics/gasrig/core/parent

/obj/structure/icafr_laser_lens
	name = "ICAFR laser focus"
	desc = "A highly advanced lens for focusing anything from a Gigawatt laser to a Petawatt laser, or maybe even beyond."
	var/obj/machinery/multitile/icafr/parent
	density = TRUE
	anchored = TRUE
	icon = 'icons/obj/power.dmi'
	icon_state = "ccharger"

/obj/structure/icafr_laser_lens/Initialize(mapload, obj/machinery/multitile/icafr/new_parent)
	. = ..()
	parent = new_parent


/obj/structure/icafr_laser_lens/bullet_act(obj/projectile/P)
	if(!istype(P, /obj/projectile/beam/emitter/gigalaser))
		return ..()
	var/obj/projectile/beam/emitter/gigalaser/lazer = P
	parent.laser_hit(src, lazer.laser_strength)
