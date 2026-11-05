/obj/structure/chem_thruster
	name = "Chemical Thruster Igniter"
	icon = 'icons/obj/orbital_thruster.dmi'
	icon_state = "chem_thruster_cap"
	density = TRUE
	dir = SOUTH
	anchored = TRUE

	var/datum/orbital_thruster/thruster
	var/datum/fuel_burner/rocket
	var/list/obj/structure/chem_thruster_body/bodies = list()
	var/obj/structure/chem_thruster_nozzle/nozzle

/obj/structure/chem_thruster/Initialize(mapload)
	. = ..()
	thruster = new(src, starting_throttleable = FALSE)
	create_reagents(200, DRAWABLE | REFILLABLE)
	rocket = new(reagents, 10)
	START_PROCESSING(SSprocessing, src)

/obj/structure/chem_thruster/Destroy()
	QDEL_NULL(thruster)
	QDEL_NULL(rocket)
	. = ..()

/obj/structure/chem_thruster/process(delta_time) // TODO - think about "queuing" thrust so missed processing cycles dont affect thrust. Also fix burn(1)
	thruster.maximum_thrust = rocket.burn(delta_time)
	nozzle?.thruster_intensity = thruster.maximum_thrust
	nozzle?.update_appearance()

	if(nozzle)
		thruster.do_plume(get_turf(nozzle), dir)

/obj/structure/chem_thruster/interact(mob/user)
	reagents.chem_temp += 50
	balloon_alert(user, "igniter sparked!")
	return TRUE

/obj/structure/chem_thruster/multitool_act(mob/living/user, obj/item/tool)
	refresh_structure()
	return TRUE

/obj/structure/chem_thruster/wrench_act(mob/living/user, obj/item/tool)
	default_unfasten_wrench(user, tool, 1 SECONDS) // TODO - signals so it "disassembles" properly, and explodes when active :trolled:

/obj/structure/chem_thruster/examine(mob/user)
	. = ..()
	. += thruster.maximum_thrust

/obj/structure/chem_thruster/proc/refresh_structure()
	bodies = list()
	nozzle = null
	find_part(get_turf(src))
	reagents.maximum_volume = length(bodies) * 200 + 200 + (nozzle ? 200 : 0)
	// TODO FIX PRETTY MUCH ALL OF THIS

/obj/structure/chem_thruster/proc/find_part(turf/base)
	var/turf/to_check = get_step(base, dir)
	for(var/content in to_check.contents)
		if(istype(content, /obj/structure/chem_thruster_body))
			bodies += content
			find_part(to_check)
		if(istype(content, /obj/structure/chem_thruster_nozzle))
			nozzle = content

/obj/structure/chem_thruster_body
	name = "Chemical Thruster Body"
	icon = 'icons/obj/orbital_thruster.dmi'
	icon_state = "chem_thruster_body"
	density = TRUE
	dir = SOUTH
	anchored = TRUE

/obj/structure/chem_thruster_nozzle
	name = "Chemical Thruster Body"
	icon = 'icons/obj/orbital_thruster.dmi'
	icon_state = "chem_thruster_nozzle"
	density = TRUE
	dir = SOUTH
	anchored = TRUE
	var/thruster_intensity = 0

/obj/structure/chem_thruster_nozzle/update_overlays()
	. = ..()
	if(thruster_intensity > 0)
		. += mutable_appearance('icons/obj/orbital_thruster.dmi', "chem_thruster_fire", layer)
		. += emissive_appearance('icons/obj/orbital_thruster.dmi', "chem_thruster_fire", layer)
