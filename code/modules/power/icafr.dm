#define ICAFR_MOLS_PER_NANOGRAM 1
#define ICAFR_MAX_STABILITY 100
#define ICAFR_NANOGRAM_TO_ENERGY 180000
#define ICAFR_FUEL_TO_ENERGY 1000 //one unit of fuel is equal to 1 KW
#define ICAFR_REACTION_ENERGY_LOG 100000 // needs 1 MW reaction energy to be strongly net positive
#define ICAFR_RATIO_ENERGY_LOG 100 //amount reaction energy boosts mols
#define ICAFR_MAX_CONTAINMENT_DECAY 0.75 //what percent of containment energy is lost each process tick when there are no stability increasing gases in the fuel mix
#define ICAFR_MIN_CONTAINMENT_DECAY 0.1 //minimum percent of containment energy lost each process tick
#define ICAFR_HEALING_THRESHOLD 1.5 //multiples reaction energy to get the minimium containment energy to self-heal
/obj/machinery/multitile/icafr
	name = "Inertially Confined Antimatter-Fusion Reactor"
	desc = "Using exotic gases and high power lasers it generates an anti-proton fusion reaction that can produce more energy then it consumes."
	density = TRUE
	var/laser_recievers = list()
	var/list/turf/components_locs = list()
	var/obj/machinery/atmospherics/components/unary/icafr_gas_input/fuel_input
	var/obj/machinery/atmospherics/components/unary/icafr_gas_input/annihilation_input
	var/datum/gas_mixture/annihilation_input_mix
	var/antimatter = 0
	var/throttle = 1
	var/stability = ICAFR_MAX_STABILITY
	var/deployed = FALSE
	var/containment_energy = 0
	var/reaction_energy = 0
	var/reaction_harvesting = 0
	var/reaction_harvesting_efficiency = 0
	var/annihilation_input_rate = 50
	var/fuel_input_rate = 50

	//for autoholding
	var/parabolic_hold_setting = 0
	var/parabolic_middle = 0
	var/parabolic_hold_gain = 0.1

	var/datum/powernet/powernet = null
	var/display_output_power = 0

	var/parabolic_production_metric = 0
	var/parabolic_ratio = 0

	var/obj/machinery/power/dummy_power_node/dummy
	///input setting, makes it easier to balance, but produce less power overall, min is 0.1, max is 1
	var/parabolic_setting = 0.5


/obj/machinery/multitile/icafr/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(move_self))
	annihilation_input_mix = new
	dummy = new (get_turf(src))
	dummy.connect_to_network()

/obj/machinery/multitile/icafr/process(delta_time)
	if(!deployed)
		return
	get_fuel_value(fuel_input.airs[1], delta_time)
	annihilation_input.airs[1].pump_gas_volume(annihilation_input_mix, annihilation_input_rate * delta_time)
	reaction_energy += annihilate_gas(antimatter)
	antimatter = 0
	var/power_to_output = reaction_energy * reaction_harvesting
	reaction_energy -= power_to_output
	hold_value()
	output_power(power_to_output * reaction_harvesting_efficiency)

/obj/machinery/multitile/icafr/setup_objects()
	fuel_input = new (src, src)
	annihilation_input = new (src, src)

	fuel_input.dir = NORTH
	fuel_input.set_init_directions()
	fuel_input.update_parents()
	annihilation_input.dir = SOUTH
	annihilation_input.set_init_directions()
	annihilation_input.update_parents()

	var/obj/structure/icafr_laser_lens/lens_east = new (src, src)
	var/obj/structure/icafr_laser_lens/lens_west = new (src, src)
	laser_recievers[lens_east] = 0
	laser_recievers[lens_west] = 0

	components_locs[fuel_input] = get_step(get_turf(src), NORTH)
	components_locs[annihilation_input] = get_step(get_turf(src), SOUTH)
	components_locs[lens_east] = get_step(get_turf(src), EAST)
	components_locs[lens_west] = get_step(get_turf(src), WEST)

/obj/machinery/multitile/icafr/wrench_act(mob/living/user, obj/item/item)
	if(reaction_energy > 1000)
		balloon_alert(user, "Reaction energy too high")
		return TRUE
	for(var/obj/comp_loc in components_locs)
		var/x_offset = components_locs[comp_loc].x - x
		var/y_offset = components_locs[comp_loc].y - y
		var/vector/vect = vector(x_offset, y_offset)
		vect.Turn(90)
		components_locs[comp_loc] = locate(vect.x + x, vect.y + y, z)
		if(deployed)
			comp_loc.forceMove(locate(vect.x + x, vect.y + y, z))
		comp_loc.setDir(turn(comp_loc.dir, 90))
		if(istype(comp_loc, /obj/machinery/atmospherics/components/unary/icafr_gas_input))
			var/obj/machinery/atmospherics/components/unary/icafr_gas_input/temp_input = comp_loc
			temp_input.set_init_directions()
			temp_input.reconnect_nodes()
			temp_input.update_parents()
	return TRUE

/obj/machinery/multitile/icafr/multitool_act(mob/living/user, obj/item/multitool)
	if(deployed)
		if(can_undeploy(user))
			undeploy()
		return TRUE
	else
		if(can_deploy(user))
			deploy()
		return TRUE

/obj/machinery/multitile/icafr/return_analyzable_air()
	return annihilation_input_mix

/obj/machinery/multitile/icafr/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AtmosIcafr")
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/multitile/icafr/ui_static_data(mob/user)
	. = ..()
	.["max_stability"] = ICAFR_MAX_STABILITY

/obj/machinery/multitile/icafr/ui_data(mob/user)
	. = ..()
	.["reaction_energy"] = reaction_energy
	.["display_power"] = display_output_power
	.["reaction_harvesting"] = reaction_harvesting
	.["reaction_harvesting_efficiency"] = reaction_harvesting_efficiency
	.["display_parabolic_production"] = parabolic_production_metric
	.["annihilation_input_rate"] = annihilation_input_rate
	.["fuel_input_rate"] = fuel_input_rate
	.["containment_energy"] = containment_energy
	.["stability"] = stability
	.["parabolic_ratio"] = parabolic_ratio
	.["parabolic_hold_setting"] = parabolic_hold_setting
	.["parabolic_hold_gain"] = parabolic_hold_gain

/obj/machinery/multitile/icafr/ui_act(action, params)
	. = ..()
	switch(action)
		if("change_annihilation")
			adjust_annihilation_rate(text2num(params["change_annihilation"]))
		if("change_fuel")
			adjust_fuel_rate(text2num(params["change_fuel"]))
		if("change_hold_gain")
			parabolic_hold_gain = clamp(text2num(params["change_hold_gain"]), 0, 1)
		if("hold_value")
			parabolic_hold_setting = max(text2num(params["hold_value"]), 0)

/obj/machinery/multitile/icafr/proc/move_self()
	dummy.forceMove(get_turf(src))

/obj/machinery/multitile/icafr/proc/adjust_annihilation_rate(to_change)
	annihilation_input_rate = clamp(to_change, 0, 200)

/obj/machinery/multitile/icafr/proc/adjust_fuel_rate(to_change)
	fuel_input_rate = clamp(to_change, 0, 200)

/obj/machinery/multitile/icafr/proc/can_deploy(mob/user)
	for(var/obj/nearby_turf as anything in components_locs)
		if(!isopenturf(components_locs[nearby_turf]))
			balloon_alert(user, "Invalid placement for ICAFR")
			return FALSE
	return TRUE

/obj/machinery/multitile/icafr/proc/can_undeploy(mob/user)
	if(reaction_energy > 1000)
		balloon_alert(user, "Can not undeploy an active reactor")
		return FALSE
	return TRUE

/obj/machinery/multitile/icafr/proc/deploy()
	for(var/obj/comp_loc in components_locs)
		comp_loc.dir = get_dir(get_turf(src), components_locs[comp_loc])
		comp_loc.forceMove(components_locs[comp_loc])
		if(istype(comp_loc, /obj/machinery/atmospherics/components/unary/icafr_gas_input))
			var/obj/machinery/atmospherics/components/unary/icafr_gas_input/temp_input = comp_loc
			temp_input.update_parents()
			temp_input.reconnect_nodes()
	deployed = TRUE

/obj/machinery/multitile/icafr/proc/undeploy()
	for(var/obj/comp_loc in components_locs)
		comp_loc.forceMove(src)
		if(istype(comp_loc, /obj/machinery/atmospherics/components/unary/icafr_gas_input))
			var/obj/machinery/atmospherics/components/unary/icafr_gas_input/temp_input = comp_loc
			temp_input.update_parents()
			temp_input.disconnect_nodes()
	deployed = FALSE

/obj/machinery/multitile/icafr/proc/get_fuel_value(datum/gas_mixture/input_mixture, delta_time)
	var/datum/gas_mixture/temp_mix = input_mixture.remove_ratio((fuel_input_rate / input_mixture.volume) * delta_time)

	reaction_harvesting_efficiency = (-1 / (0.15 * GET_MOLES(/datum/gas/oxygen, temp_mix) + 1) + 1) + 0.025 * GET_MOLES(/datum/gas/pluoxium, temp_mix)

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
	process_containment(get_stability_value(temp_mix))

/obj/machinery/multitile/icafr/proc/annihilate_gas(input_antimatter)
	parabolic_production_metric = 0
	parabolic_ratio = 0

	if(!input_antimatter)
		return 0
	if(!annihilation_input_mix)
		return 0

	var/mols = annihilation_input_mix.total_moles()

	if(mols <= 0)
		return 0

	if(mols <= input_antimatter * ICAFR_MOLS_PER_NANOGRAM)
		change_stability(-5) //todo maybe make this dynamic, rather then just 5

	var/parabolic_upper_limit = get_annihilation_power(annihilation_input_mix) + log(10, (reaction_energy / ICAFR_REACTION_ENERGY_LOG) + 1)

	parabolic_ratio = input_antimatter / ((mols * ICAFR_MOLS_PER_NANOGRAM) * (reaction_energy != 0 ? max(log(ICAFR_RATIO_ENERGY_LOG, reaction_energy), 1) : 1))

	parabolic_middle = sqrt(parabolic_upper_limit * parabolic_setting)

	if(mols > 0.001)
		parabolic_production_metric = -1 * ((parabolic_ratio * parabolic_setting) - sqrt(parabolic_upper_limit * parabolic_setting))**2 + (parabolic_upper_limit * parabolic_setting) // todo, expand on this idea, reduce requirement for gases, make it hard to stay stable instead. Numbers are not big enough

	annihilation_input_mix = new

	return max(input_antimatter * ICAFR_NANOGRAM_TO_ENERGY * parabolic_production_metric, 0)

/obj/machinery/multitile/icafr/proc/get_annihilation_power(datum/gas_mixture/input_mixture)
	var/gas_power = 0
	var/gas_count = 0
	for (var/datum/gas/gas_id as anything in input_mixture.gases)
		gas_power += initial(gas_id.gasrig_shielding_power) //todo make this better
		gas_count += 1
	return log(2, (gas_power / gas_count) + 1)

/obj/machinery/multitile/icafr/proc/change_stability(change_amount)
	stability = clamp(stability + change_amount, 0, ICAFR_MAX_STABILITY)

/obj/machinery/multitile/icafr/proc/get_stability_value(datum/gas_mixture/input_mixture)
	if(input_mixture.total_moles() <= 0)
		return ICAFR_MAX_CONTAINMENT_DECAY
	var/co2_percent = GET_MOLES(/datum/gas/carbon_dioxide, input_mixture) / input_mixture.total_moles()
	var/pluox_percent = GET_MOLES(/datum/gas/pluoxium, input_mixture) / input_mixture.total_moles()
	return clamp(ICAFR_MAX_CONTAINMENT_DECAY - ((co2_percent * 0.5) + (pluox_percent * 0.25)), ICAFR_MIN_CONTAINMENT_DECAY, ICAFR_MAX_CONTAINMENT_DECAY)

/obj/machinery/multitile/icafr/proc/process_containment(stability_value)
	containment_energy -= containment_energy * stability_value
	if((containment_energy < reaction_energy) && containment_energy != 0)
		change_stability(-(reaction_energy / containment_energy) * 10)
	if((containment_energy > ICAFR_HEALING_THRESHOLD * reaction_energy) && reaction_energy != 0)
		change_stability(containment_energy / reaction_energy)

/obj/machinery/multitile/icafr/proc/hold_value()
	if(!parabolic_hold_setting)
		return

	var/annihilation_rate_delta = 0
	if(parabolic_ratio > parabolic_middle)
		annihilation_rate_delta = -1 * parabolic_production_metric - parabolic_hold_setting * parabolic_hold_gain
	else
		annihilation_rate_delta = parabolic_production_metric - parabolic_hold_setting * parabolic_hold_gain

	adjust_annihilation_rate(annihilation_input_rate + annihilation_rate_delta)

/obj/machinery/multitile/icafr/proc/output_power(power_to_output)
	display_output_power = power_to_output
	dummy.add_avail(power_to_output)

/obj/machinery/multitile/icafr/proc/laser_hit(obj/structure/icafr_laser_lens/reciever, laser_strength)
	antimatter += (laser_strength / ICAFR_NANOGRAM_TO_ENERGY)
	containment_energy += laser_strength

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
