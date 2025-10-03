#define ICAFR_MOLS_PER_NANOGRAM 0.01
#define ICAFR_MAX_STABILITY 100
#define ICAFR_NANOGRAM_TO_ENERGY 180000
#define ICAFR_FUEL_TO_ENERGY 1000 //one unit of fuel is equal to 1 KW

/obj/machinery/multitile/icafr
	name = "Inertially Confined Antimatter-Fusion Reactor"
	desc = "Using exotic gases and high power lasers it generates an anti-proton fusion reaction that can produce more energy then it consumes."
	density = TRUE
	var/laser_recievers = list()
	var/obj/machinery/atmospherics/components/unary/icafr_gas_input/fuel_input
	var/obj/machinery/atmospherics/components/unary/icafr_gas_input/annihilation_input
	var/antimatter_production = 0
	var/throttle = 1
	var/stability = ICAFR_MAX_STABILITY
	var/reaction_energy = 0
	var/reaction_harvesting = 0
	var/reaction_harvesting_efficiency = 0.5
	var/annihilation_input_rate = 50
	var/fuel_input_rate = 50

	var/display_output_power = 0
	///input setting, makes it easier to balance, but produce less power overall, min is 0.1, max is 1
	var/parabolic_setting = 0.5


/obj/machinery/multitile/icafr/Initialize(mapload)
	. = ..()
	SSair.start_processing_machine(src)

/obj/machinery/multitile/icafr/process_atmos()
	var/laser_power = 0
	for(var/obj/structure/lens in laser_recievers)
		if(!laser_power)
			laser_power = laser_recievers[lens]
		else
			laser_power += laser_recievers[lens]
	antimatter_production = (laser_power * 0.5 / ICAFR_NANOGRAM_TO_ENERGY) * throttle //half the laser energy goes into making antimatter
	reaction_energy += annihilate_gas(annihilation_input.airs[1], antimatter_production)
	var/power_to_output = reaction_energy * reaction_harvesting
	reaction_energy -= power_to_output
	output_power(power_to_output * reaction_harvesting_efficiency)



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

/obj/machinery/multitile/icafr/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AtmosIcafr")
		ui.open()
		ui.set_autoupdate(TRUE)


/obj/machinery/multitile/icafr/ui_data(mob/user)
	var/list/data = list()
	data["reaction_energy"] = reaction_energy
	data["display_power"] = display_output_power
	data["reaction_harvesting"] = reaction_harvesting
	return data

/obj/machinery/multitile/icafr/ui_act(action, params)
	. = ..()
	switch(action)
		if("change_harvesting")
			reaction_harvesting = text2num(params["change_harvesting"])

/obj/machinery/multitile/icafr/proc/get_fuel_value(datum/gas_mixture/input_mixture)
	return GET_MOLES(/datum/gas/plasma, input_mixture) + (GET_MOLES(/datum/gas/bz, input_mixture)*8) + (GET_MOLES(/datum/gas/tritium, input_mixture)*32)

/obj/machinery/multitile/icafr/proc/annihilate_gas(datum/gas_mixture/input_mixture, input_antimatter)
	var/datum/gas_mixture/temp_mix = input_mixture.remove_ratio(annihilation_input_rate / input_mixture.volume) //todo replace with volume pump
	if(!temp_mix)
		return
	var/mols = temp_mix.total_moles()
	if(mols <= input_antimatter * ICAFR_MOLS_PER_NANOGRAM)
		reduce_stability(-5) //todo maybe make this dynamic, rather then just 5
	if(mols <= 0)
		return 0
	var/parabolic_upper_limit = 4 //todo make this respect ann gases rarity
	var/ratio = input_antimatter / (temp_mix.total_moles() * ICAFR_MOLS_PER_NANOGRAM)
	var/production_metric = -1 * ((ratio * parabolic_setting) - sqrt(parabolic_upper_limit * parabolic_setting))**2 + (parabolic_upper_limit * parabolic_setting)
	return input_antimatter * ICAFR_NANOGRAM_TO_ENERGY * production_metric


/obj/machinery/multitile/icafr/proc/reduce_stability(change_amount)
	stability = clamp(stability + change_amount, 0, ICAFR_MAX_STABILITY)

/obj/machinery/multitile/icafr/proc/get_stability_value(datum/gas_mixture/input_mixture)
	if(input_mixture.total_moles() <= 0)
		return 0
	var/co2_percent = GET_MOLES(/datum/gas/carbon_dioxide, input_mixture) / input_mixture.total_moles()
	var/pluox_percent = GET_MOLES(/datum/gas/pluoxium, input_mixture) / input_mixture.total_moles()
	return max(co2_percent, pluox_percent * 4)

/obj/machinery/multitile/icafr/proc/output_power(power_to_output)
	display_output_power = power_to_output

/obj/machinery/multitile/icafr/proc/laser_hit(obj/structure/icafr_laser_lens/reciever, laser_strength)
	laser_recievers[reciever] = laser_strength


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
