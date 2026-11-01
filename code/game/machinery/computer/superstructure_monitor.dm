/obj/machinery/computer/superstructure_monitor
	name = "superstructure monitoring console"
	desc = "A console used to monitor the station's superstructure."
	icon_screen = "comm_logs"
	icon_keyboard = "tech_key"
	circuit = /obj/item/circuitboard/computer/orbital_height_control
	light_color = LIGHT_COLOR_RED

/obj/machinery/computer/superstructure_monitor/ui_data(mob/user)
	var/list/data = list()
	data["hull"] = SSsuperstructure.hull_integrity
	data["max_hull"] = SSsuperstructure.max_integrity
	data["shielding"] = SSsuperstructure.shielding_integrity
	data["max_shielding"] = SSsuperstructure.max_shielding
	return data

/obj/machinery/computer/superstructure_monitor/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SuperstructureMonitor", name)
		ui.open()
		ui.set_autoupdate(TRUE)


