/obj/machinery/multitile
	name = "multi-tile machine"
	desc = "It is made of multiple tiles."
	icon = 'icons/obj/power.dmi'
	icon_state = "ccharger"
	var/list/datum/multitile_component/component_types
	var/list/obj/components

/obj/machinery/multitile/Initialize(mapload)
	. = ..()
	setup_objects()
	components = list()
	for(var/datum/multitile_component/comp in component_types)
		components += comp.return_object()

/obj/machinery/multitile/proc/setup_objects()
	return

/obj/machinery/multitile/debug/setup_objects()
	component_types = list(new /datum/multitile_component(/obj/structure/filler, get_turf(src)))

/datum/multitile_component
	var/obj/component_obj
	var/turf/location
	var/icon_state

/datum/multitile_component/New(obj/component, turf/loca)
	component_obj = component
	location = loca
	RegisterSignal(src, COMSIG_QDELETING, PROC_REF(delete_children))

/datum/multitile_component/New(obj/component, turf/loca, state)
	component_obj = component
	location = loca
	icon_state = state

/datum/multitile_component/proc/delete_children()
	return

/datum/multitile_component/proc/return_object()
	var/obj/tmp_obj = new component_obj(location)
	if(icon_state)
		tmp_obj.icon_state = icon_state
	return tmp_obj

/obj/structure/filler
	name = "big machinery part"
	density = TRUE
	anchored = TRUE
	invisibility = INVISIBILITY_ABSTRACT
	var/obj/machinery/multitile/parent

/obj/structure/filler/ex_act()
	return
