/obj/structure/chem_thruster
	name = "Chemical Thruster Igniter"
	icon = 'icons/obj/orbital_thruster.dmi'
	icon_state = "chem_thruster_cap"

	var/datum/orbital_thruster/thruster
	var/list/obj/structure/chem_thruster_body/bodies = list()
	var/obj/structure/chem_thruster_nozzle/nozzle

/obj/structure/chem_thruster/Initialize(mapload)
	. = ..()
	thruster = new(src, FALSE)

/obj/structure/chem_thruster/Destroy()
	QDEL_NULL(thruster)
	. = ..()

/obj/structure/chem_thruster/proc/refresh_structure()
	find_part(get_turf(src))

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

/obj/structure/chem_thruster_body/Initialize(mapload)
	. = ..()
	create_reagents(200, DRAWABLE | REFILLABLE)

/obj/structure/chem_thruster_nozzle
	name = "Chemical Thruster Body"
	icon = 'icons/obj/orbital_thruster.dmi'
	icon_state = "chem_thruster_body"
