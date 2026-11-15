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
	refresh_structure()

/obj/structure/chem_thruster/Destroy()
	QDEL_NULL(thruster)
	QDEL_NULL(rocket)
	. = ..()

/obj/structure/chem_thruster/process(delta_time) // TODO - think about "queuing" thrust so missed processing cycles dont affect thrust. Also fix burn(1)
	thruster.thrust = rocket.burn(delta_time)
	nozzle?.thruster_intensity = thruster.get_thrust()
	nozzle?.update_appearance()
	nozzle?.fire_trail.set_particle_spawning(clamp(thruster.get_thrust() * 1e-6, 0, 15)) // TODO - move into proc on nozzle?
	nozzle?.smoke_trail.alpha = clamp(thruster.get_thrust() * 5e-5, 0, 255)

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
	. += thruster.thrust

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
	var/obj/effect/abstract/particle_holder/fire_trail
	var/obj/effect/abstract/particle_holder/smoke_trail

/obj/structure/chem_thruster_nozzle/Initialize(mapload)
	. = ..()
	smoke_trail = new(src, /particles/flame_trail/smoke) // TODO - review this
	smoke_trail.layer = ABOVE_OBJ_LAYER
	fire_trail = new(src, /particles/flame_trail)
	fire_trail.plane = ABOVE_LIGHTING_PLANE
	fire_trail.vis_flags &= ~VIS_INHERIT_PLANE

	smoke_trail.alpha = 0

/obj/structure/chem_thruster_nozzle/update_overlays()
	. = ..()
	if(thruster_intensity > 0)
		. += mutable_appearance('icons/obj/orbital_thruster.dmi', "chem_thruster_fire", layer, alpha = clamp(thruster_intensity * 5e-5, 0, 255))
		. += emissive_appearance('icons/obj/orbital_thruster.dmi', "chem_thruster_fire", layer, alpha = clamp(thruster_intensity * 5e-5, 0, 255))

/particles/flame_trail
	icon = 'icons/effects/particles/generic.dmi'
	icon_state = list("trail")
	drift = generator(GEN_VECTOR, list(-10, 0), list(10, 0), NORMAL_RAND)
	velocity = list(0, -25, 0)
	color = generator("color", "#fff241", "#ff7011")
	lifespan = 0.5 SECONDS
	fade = 0.5 SECONDS
	spawning = 0
	count = 500
	position = generator(GEN_VECTOR, list(-7, -6), list(8, -6), NORMAL_RAND)
	height = 300

/particles/flame_trail/smoke
	icon = 'icons/effects/particles/smoke.dmi'
	icon_state = list("smoke_3")
	spawning = 2
	scale = 2
