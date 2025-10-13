#define ICAFR_MOLS_PER_NANOGRAM 0.01
#define ICAFR_MAX_STABILITY 100
#define ICAFR_NANOGRAM_TO_ENERGY 180000
#define ICAFR_FUEL_TO_ENERGY 1000 //one unit of fuel is equal to 1 KW
#define ICAFR_REACTION_ENERGY_LOG 100000 // needs 1 MW reaction energy to be strongly net positive

/obj/machinery/multitile/icafr
	name = "Inertially Confined Antimatter-Fusion Reactor"
	desc = "Using exotic gases and high power lasers it generates an anti-proton fusion reaction that can produce more energy then it consumes."
	density = TRUE
	var/laser_recievers = list()
	var/obj/machinery/atmospherics/components/unary/icafr_gas_input/fuel_input
	var/obj/machinery/atmospherics/components/unary/icafr_gas_input/annihilation_input
	var/datum/gas_mixture/annihilation_input_mix
	var/antimatter = 0
	var/throttle = 1
	var/stability = ICAFR_MAX_STABILITY
	var/deployed = FALSE
	var/reaction_energy = 0
	var/reaction_harvesting = 0
	var/reaction_harvesting_efficiency = 0
	var/annihilation_input_rate = 50
	var/fuel_input_rate = 50
	var/datum/powernet/powernet = null
	var/display_output_power = 0
	var/display_parabolic_production = 0
	var/obj/machinery/power/dummy_power_node/dummy
	///input setting, makes it easier to balance, but produce less power overall, min is 0.1, max is 1
	var/parabolic_setting = 0.5


/obj/machinery/multitile/icafr/Initialize(mapload)
	. = ..()
	annihilation_input_mix = new
	dummy = new (get_turf(src))
	dummy.connect_to_network()

/obj/machinery/multitile/icafr/process(delta_time)
	get_fuel_value(fuel_input.airs[1])
	annihilation_input.airs[1].pump_gas_volume(annihilation_input_mix, annihilation_input_rate * delta_time)
	reaction_energy += annihilate_gas(antimatter)
	antimatter = 0
	var/power_to_output = reaction_energy * reaction_harvesting
	reaction_energy -= power_to_output
	output_power(power_to_output * reaction_harvesting_efficiency)

/obj/machinery/multitile/icafr/setup_objects()
	fuel_input = new (get_step(get_turf(src), NORTH), src)
	annihilation_input = new (get_step(get_turf(src), SOUTH), src)

	fuel_input.dir = NORTH
	fuel_input.set_init_directions()
	fuel_input.update_parents()
	annihilation_input.dir = SOUTH
	annihilation_input.set_init_directions()
	annihilation_input.update_parents()

	var/obj/structure/icafr_laser_lens/lens_east = new (get_step(get_turf(src), EAST), src)
	var/obj/structure/icafr_laser_lens/lens_west = new (get_step(get_turf(src), WEST), src)
	laser_recievers[lens_east] = 0
	laser_recievers[lens_west] = 0

	components = list(fuel_input, annihilation_input, lens_east, lens_west)

/obj/machinery/multitile/icafr/return_analyzable_air()
	return annihilation_input_mix

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
	data["reaction_harvesting_efficiency"] = reaction_harvesting_efficiency
	data["display_parabolic_production"] = display_parabolic_production
	return data

/obj/machinery/multitile/icafr/ui_act(action, params)
	. = ..()
	switch(action)
		if("change_harvesting")
			reaction_harvesting = text2num(params["change_harvesting"])

/obj/machinery/multitile/icafr/proc/get_fuel_value(datum/gas_mixture/input_mixture, delta_time)
	var/datum/gas_mixture/temp_mix = input_mixture.remove_ratio(fuel_input_rate / input_mixture.volume)

	reaction_harvesting_efficiency = (-1 / (0.05 * GET_MOLES(/datum/gas/oxygen, temp_mix) + 1) + 1) + 0.01 * GET_MOLES(/datum/gas/pluoxium, temp_mix)


	var/mols_plas = min(GET_MOLES(/datum/gas/plasma, temp_mix), 100)
	var/mols_bz = min(GET_MOLES(/datum/gas/bz, temp_mix), 80)
	var/mols_trit = min(GET_MOLES(/datum/gas/tritium, temp_mix), 60)

	var/total_moles = mols_plas + mols_bz + mols_trit

	if(mols_plas || mols_bz || mols_trit)
		var/plas_ratio = mols_plas / total_moles
		var/bz_ratio = mols_bz / total_moles
		var/trit_ratio = mols_trit / total_moles
		reaction_harvesting = min((mols_plas * plas_ratio / 400) + (mols_bz * bz_ratio / 160) + (mols_trit * trit_ratio / 80), 1)
	else
		reaction_harvesting = 0

/obj/machinery/multitile/icafr/proc/annihilate_gas(input_antimatter)
	if(!input_antimatter)
		return
	if(!annihilation_input_mix)
		return
	var/mols = annihilation_input_mix.total_moles()
	if(mols <= input_antimatter * ICAFR_MOLS_PER_NANOGRAM)
		reduce_stability(-5) //todo maybe make this dynamic, rather then just 5
	if(mols <= 0)
		return 0
	var/parabolic_upper_limit = get_annihilation_power(annihilation_input_mix) + log(10, (reaction_energy / ICAFR_REACTION_ENERGY_LOG) + 1) //todo make this respect ann gases rarity
	var/ratio = input_antimatter / (mols * ICAFR_MOLS_PER_NANOGRAM)
	var/production_metric = 0
	if(mols > 0.001)
		production_metric = -1 * ((ratio * parabolic_setting) - sqrt(parabolic_upper_limit * parabolic_setting))**2 + (parabolic_upper_limit * parabolic_setting)
	display_parabolic_production = production_metric //todo fix this not updating when no input gas or antimatter (since early returns)
	annihilation_input_mix = new
	return max(input_antimatter * ICAFR_NANOGRAM_TO_ENERGY * production_metric, 0)

/obj/machinery/multitile/icafr/proc/get_annihilation_power(datum/gas_mixture/input_mixture)
	var/gas_power = 0
	for (var/datum/gas/gas_id as anything in input_mixture.gases)
		gas_power += initial(gas_id.gasrig_shielding_power)
	return log(2, gas_power + 1)

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
	dummy.add_avail(power_to_output)

/obj/machinery/multitile/icafr/proc/laser_hit(obj/structure/icafr_laser_lens/reciever, laser_strength)
	antimatter += (laser_strength / ICAFR_NANOGRAM_TO_ENERGY)

/obj/machinery/atmospherics/components/unary/icafr_gas_input
	name = "ICAFR gas input"
	desc = "A input port to input gases into the ICAFR."
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
