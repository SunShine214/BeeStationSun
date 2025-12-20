/obj/machinery/launch_silo
	name = "Drone Launch Silo"
	desc = "Launches and retrieves exploration drones into and from the depths of space, and even can launch... other items."
	icon = 'icons/obj/exploration_drone.dmi'
	icon_state = "launch_closed"
	var/opened = FALSE
	var/obj/item/stored_item = null
	var/list/obj/item/exploration_drone/launched_drones = list()


/obj/machinery/launch_silo/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	toggle_open()

/obj/machinery/launch_silo/update_appearance(updates)
	if(opened)
		icon_state = "launch_opened"
	else
		icon_state = "launch_closed"
	. = ..()


/obj/machinery/launch_silo/proc/toggle_open()
	if(opened)
		opened = FALSE
		insert()
	else
		opened = TRUE
		extract()
	update_appearance()

/obj/machinery/launch_silo/proc/start_expedition(obj/item/exploration_drone/to_start)
	return

/obj/machinery/launch_silo/proc/launch()
	if(istype(stored_item, /obj/item/exploration_drone))
		start_expedition(stored_item)
		return
	//do future logic for special items



/obj/machinery/launch_silo/proc/extract()
	if(stored_item)
		stored_item.forceMove(get_turf(src))
	stored_item = null

/obj/machinery/launch_silo/proc/insert()
	var/turf/launch_turf = get_turf(src)
	if(!launch_turf)
		return
	for(var/obj/item/to_insert in launch_turf.contents)
		stored_item = to_insert
		to_insert.forceMove(src)
		break
