// Circuit boards, spare parts, etc.

/datum/export/solar/assembly
	cost = 50
	unit_name = "solar panel assembly"
	export_types = list(/obj/item/solar_assembly)

/datum/export/solar/tracker_board
	cost = 100
	unit_name = "solar tracker board"
	export_types = list(/obj/item/electronics/tracker)

/datum/export/solar/control_board
	cost = 150
	unit_name = "solar panel control board"
	export_types = list(/obj/item/circuitboard/computer/solar_control)

/datum/export/swarmer
	cost = 2000
	unit_name = "deactivated alien deconstruction drone"
	export_types = list(/obj/item/deactivated_swarmer)

/datum/export/photonic_prism
	cost = 10000
	unit_name = "photonic prism"
	export_types = list(/obj/item/stock_parts/cell/photonic_prism)
	/// This is highly fucking fallible, I'll have to make another way of doing this bitch
