/obj/machinery/atmospherics/components/binary/ionizer
	name = "Gas Ionizer"
	desc = "Ionizes gas mixtures to create ionic fuel suitable for orbital thrusters."
	icon = 'icons/obj/atmospherics/components/ionizer.dmi'
	icon_state = "ionizer"
	density = TRUE
	layer = OBJ_LAYER

	var/reaction_gas
	var/ion_agent_gas
	var/efficiency

	var/active = FALSE
	var/part_multiplier = 1

	/// Ratio of ionizer gas to reaction gas. 1 is equal to no reaction gas, 0.25 is 75% reaction gas.
	var/reactor_ionizer_ratio = 0.1
	var/input_rate = 50
	var/output_rate = 50
	var/datum/gas_mixture/internal

/obj/machinery/atmospherics/components/binary/ionizer/Initialize(mapload)
	. = ..()
	internal = new()
	if(!switch_mix(/datum/gas/nitrogen, /datum/gas/plasma))
		stack_trace("Ionizer Initialize mix invalid! This needs fixing.")

/obj/machinery/atmospherics/components/binary/ionizer/RefreshParts()
	. = ..()
	var/total_tier = 0
	var/total_parts = 0
	for(var/datum/stock_part/part in component_parts)
		total_tier += part.tier
		total_parts ++
	part_multiplier = total_parts ? total_tier / total_parts : 1 // TODO - look at

/obj/machinery/atmospherics/components/binary/ionizer/wrench_act(mob/living/user, obj/item/tool)
	return default_change_direction_wrench(user, tool) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING

/obj/machinery/atmospherics/components/binary/ionizer/screwdriver_act(mob/living/user, obj/item/tool)
	return default_deconstruction_screwdriver(user, "ionizer-open", "ionizer", tool) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING

/obj/machinery/atmospherics/components/binary/ionizer/process_atmos()
	var/datum/gas_mixture/input = airs[1]
	input.pump_gas_volume(internal, input_rate) // TODO - add pressure cap

	if(active)
		process_internal()

	var/datum/gas_mixture/output = airs[2]
	internal.pump_gas_volume(output, output_rate)

	update_parents()

/obj/machinery/atmospherics/components/binary/ionizer/proc/process_interal()
	internal.assert_gases(reaction_gas, ion_agent_gas)
	var/reaction_amount = internal.moles[reaction_gas]
	var/ion_agent_amount = internal.moles[ion_agent_gas]

	var/converted_portion = clamp(efficiency ** 2 / internal.volume, 0, 1)
	var/total_converted = (reaction_amount + ion_agent_amount) * converted_portion
	var/ion_agent_converted = min(reaction_amount * converted_portion * reactor_ionizer_ratio, ion_agent_amount * converted_portion)

	if(!converted_amount)
		return
	// Not using a built in proc here, since we have to run two distinct conversions. Doing it this way avoids excess garbage collections and assertions.
	internal.assert_gas(/datum/gas/ionic_fuel)
	var/list/cached_moles = internal.moles
	cached_moles[reaction_gas] -= QUANTIZE(ion_agent_converted / reactor_ionizer_ratio)
	cached_moles[ion_agent_gas] -= QUANTIZE(ion_agent_converted)
	cached_moles[/datum/gas/ionic_fuel] += QUANTIZE(total_converted)
	internal.garbage_collect()

/obj/machinery/atmospherics/components/binary/ionizer/ui_data(mob/user)
	var/list/data = list()

	data["reaction_gas"] = reaction_gas
	data["ion_agent_gas"] = ion_agent_gas
	data["efficiency"] = efficiency

	return data

/obj/machinery/atmospherics/components/binary/ionizer/ui_static_data(mob/user)
	var/list/data = list()

	data["ionizers_gases"] = GLOB.ionizer_gases

	return data

/obj/machinery/atmospherics/components/binary/ionizer/proc/switch_mix(reactor, ion_agent)
	if(!is_possible_mix(reactor, ion_agent))
		return FALSE
	reaction_gas = reactor
	ion_agent_gas = ion_agent
	refresh_efficiency()
	return TRUE

/obj/machinery/atmospherics/components/binary/ionizer/proc/is_possible_mix(reactor, ion_agent)
	var/datum/ionizer_gas/reactor_behavior = GLOB.ionizer_gases[reactor]
	if(!reactor_behavior && !reactor_behavior.ionizers)
		return FALSE
	return ion_agent in reactor_behavior.ionizers

/// Does not check if this mix is valid. Do that before calling this.
/obj/machinery/atmospherics/components/binary/ionizer/proc/refresh_efficiency()
	var/datum/ionizer_gas/reactor_behavior = GLOB.ionizer_gases[reaction_gas]
	var/datum/ionizer_gas/ion_behavior = GLOB.ionizer_gases[ion_agent_gas]
	efficiency = ((ion_behavior ? ion_behavior.efficiency : 1) + (reactor_behavior ? reactor_behavior.efficiency : 1)) / 2
