/obj/machinery/atmospherics/components/trinary/gigalaser
	name = "gigawatt laser"
	desc = "A gigawatt industrial laser, for use in antimatter production and power generation."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "emitter"
	base_icon_state = "emitter"

	density = TRUE
//	circuit = /obj/item/circuitboard/machine/emitter

	use_power = NO_POWER_USE
	idle_power_usage = 500 WATT
	active_power_usage = 5 KILOWATT

	var/laser_output = 0


/obj/machinery/atmospherics/components/trinary/gigalaser/process_atmos()
	. = ..()

