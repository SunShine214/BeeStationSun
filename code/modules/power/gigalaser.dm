#define GIGALASER_SPECIFIC_HEAT 1000

/obj/machinery/atmospherics/components/trinary/gigalaser
	name = "Pulsed  laser"
	desc = "A gigawatt industrial laser, for use in antimatter production and power generation."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "emitter"
	base_icon_state = "emitter"

	density = TRUE
//	circuit = /obj/item/circuitboard/machine/emitter

	use_power = NO_POWER_USE
	idle_power_usage = 500 WATT
	active_power_usage = 5 KILOWATT

	var/active = FALSE
	var/energy_to_laser_ratio = 0.99
	var/laser_output = 0
	var/internal_temp = 300


/obj/machinery/atmospherics/components/trinary/gigalaser/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/simple_rotation)
	update_appearance()

/obj/machinery/atmospherics/components/trinary/gigalaser/set_init_directions()
	switch(dir)
		if(NORTH)
			initialize_directions = EAST|WEST|SOUTH
		if(SOUTH)
			initialize_directions = EAST|WEST|NORTH
		if(EAST)
			initialize_directions = NORTH|WEST|SOUTH
		if(WEST)
			initialize_directions = SOUTH|NORTH|EAST

/obj/machinery/atmospherics/components/trinary/gigalaser/process_atmos()
	handle_cooling()
	fire_laser()

/obj/machinery/atmospherics/components/trinary/gigalaser/wrench_act(mob/living/user, obj/item/item)
	. = ..()
	default_unfasten_wrench(user, item, 15)
	return TRUE

/obj/machinery/atmospherics/components/trinary/gigalaser/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(!anchored)
		balloon_alert(user, "Anchor before activating!")
		return
	active = !active
	update_appearance()
	balloon_alert(user, active ? "You turn it on." : "You turn it off.")

/obj/machinery/atmospherics/components/trinary/gigalaser/get_node_connects()

	//1 and 2 is input
	//Node 3 is output
	//If we flip the laser, 1 and 2 shall exchange positions

	var/node1_connect = turn(dir, 90)
	var/node2_connect = turn(dir, 180)
	var/node3_connect = turn(dir, -90)

	if(flipped)
		node1_connect = turn(node1_connect, 180)
		node3_connect = turn(node3_connect, 180)

	return list(node1_connect, node2_connect, node3_connect)

/obj/machinery/atmospherics/components/trinary/gigalaser/AltClick(mob/living/living)
	. = ..()
	if(anchored)
		return
	setDir(turn(dir, -90))
	change_dir()

/obj/machinery/atmospherics/components/trinary/gigalaser/proc/change_dir()
	set_init_directions()
	reconnect_nodes()

/obj/machinery/atmospherics/components/trinary/gigalaser/proc/fire_laser()
	if(!active && !anchored)
		return
	var/obj/projectile/beam/emitter/gigalaser/projectile = new (get_turf(src))
	playsound(src, 'sound/weapons/emitter.ogg', 50, TRUE)
	projectile.firer = src
	projectile.fired_from = src
	projectile.laser_strength = energy_to_laser_ratio * active_power_usage
	projectile.fire(dir2angle(dir))

//airs[1] is cooling input
//airs[2] is moderator (lensing) gas input
//airs[3] is cooling output

/obj/machinery/atmospherics/components/trinary/gigalaser/proc/handle_cooling()
	var/datum/gas_mixture/input_gas = airs[1]
	var/datum/gas_mixture/moderator_gas = airs[2]
	var/datum/gas_mixture/output_gas = airs[3]

	var/datum/gas_mixture/removed = input_gas.remove_ratio(0.5) //todo: make these better? I feel remove_ratio may not be good here
	var/datum/gas_mixture/moved_moderator = moderator_gas.remove_ratio(0.25) //may want to come back to this

	var/lensing_average = 0
	var/gas_count = 0
	if(moved_moderator)
		for (var/datum/gas/gas_id as anything in moved_moderator.gases)
			lensing_average += get_lensing_power(gas_id)
			gas_count += 1
		if(gas_count)
			energy_to_laser_ratio = lensing_average / gas_count
	else
		energy_to_laser_ratio = 0.1

	removed.merge(moved_moderator)
	var/removed_heat_cap = removed.heat_capacity()
	var/combined_heat_capacity = GIGALASER_SPECIFIC_HEAT + removed_heat_cap
	if(combined_heat_capacity > 0)
		var/combined_energy = internal_temp * GIGALASER_SPECIFIC_HEAT + removed_heat_cap * removed.return_temperature() + handle_heating()
		var/new_temperature = combined_energy / combined_heat_capacity
		internal_temp = new_temperature
		removed.temperature = new_temperature

	output_gas.merge(removed)
	update_parents()

/obj/machinery/atmospherics/components/trinary/gigalaser/proc/handle_heating()
	return (active_power_usage) * (1 - energy_to_laser_ratio)

/obj/machinery/atmospherics/components/trinary/gigalaser/proc/get_lensing_power(/datum/gas/gas_to_check)
	return 0.99 //todo
