/obj/machinery/atmospherics/components/unary/ionizer
	name = "Gas Ionizer"
	desc = "Ionizes gas mixtures to create ionic fuel suitable for orbital thrusters."
	density = TRUE
	layer = OBJ_LAYER

	var/reaction_gas
	var/ion_agent_gas
	var/efficiency
	var/input_rate = 50
	var/output_rate = 50


/obj/machinery/atmospherics/components/unary/ionizer/Initialize(mapload)
	. = ..()
	if(!switch_mix(/datum/gas/nitrogen, /datum/gas/plasma))
		stack_trace("Ionizer Initialize mix invalid! This needs fixing.")

/obj/machinery/atmospherics/components/unary/ionizer/process_atmos()


/obj/machinery/atmospherics/components/unary/ionizer/ui_data(mob/user)
	var/list/data = list()

	data["reaction_gas"] = reaction_gas
	data["ion_agent_gas"] = ion_agent_gas
	data["efficiency"] = efficiency

	return data

/obj/machinery/atmospherics/components/unary/ionizer/ui_static_data(mob/user)
	var/list/data = list()

	data["ionizers_gases"] = GLOB.ionizer_gases

	return data

/obj/machinery/atmospherics/components/unary/ionizer/proc/switch_mix(reactor, ion_agent)
	if(!is_possible_mix(reactor, ion_agent))
		return FALSE
	reaction_gas = reactor
	ion_agent_gas = ion_agent
	efficiency = get_efficiency(reactor, ion_agent)
	return TRUE

/obj/machinery/atmospherics/components/unary/ionizer/proc/is_possible_mix(reactor, ion_agent)
	var/reactor_behavior = GLOB.ionizer_gases[reactor]
	if(!reactor_behavior && !reactor_behavior.ionizers)
		return FALSE
	return ion_agent in reactor_behavior.ionizers

/// Does not check if this mix is valid. Do that before calling this.
/obj/machinery/atmospherics/components/unary/ionizer/proc/get_efficiency(reactor, ion_agent)
	var/reactor_behavior = GLOB.ionizer_gases[reactor]
	var/ion_behavior = GLOB.ionizer_gases[ion_agent]
	return ion_behavior ? ion_behavior.efficiency : 1 + reactor_behavior ? reactor_behavior.efficiency : 1
