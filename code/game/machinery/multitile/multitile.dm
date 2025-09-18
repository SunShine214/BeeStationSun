/obj/machinery/multitile
	name = "multi-tile machine"
	desc = "It is made of multiple tiles."
	icon = 'icons/obj/power.dmi'
	icon_state = "ccharger"
	var/list/datum/multitile_component/components

/obj/machinery/multitile/Initialize(mapload)
	. = ..()
	setup_objects()

/obj/machinery/multitile/proc/setup_objects()
	return

/datum/multitile_component
	var/obj/component_obj

/datum/multitile_component/New(obj/component, state)
	..()
	component_obj = component
	if(state)
		component_obj.icon_state = state

/datum/multitile_component/Destroy()
	qdel(component_obj)
	. = ..()


/obj/structure/filler
	name = "big machinery part"
	density = TRUE
	anchored = TRUE
	invisibility = INVISIBILITY_ABSTRACT
	var/obj/machinery/multitile/parent

/obj/structure/filler/ex_act()
	return
