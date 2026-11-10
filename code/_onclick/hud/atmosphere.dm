/client/var/atom/movable/screen/atmosphere_background_home/atmosphere_background

/datum/hud/proc/create_atmosphere_background(mob/to_show_to)
	var/client/mob_client = to_show_to?.client || mymob?.client
	if(!mob_client)
		return
	mob_client.atmosphere_background = new()
	mob_client.atmosphere_background.alpha = SSorbital_visuals.get_alpha_from_orbit()
	for(var/iter_x in -1 to 1)
		for(var/iter_y in -1 to 1)
			var/atom/movable/screen/atmosphere_background/background = new()
			background.pixel_w = 480 * iter_x
			background.pixel_z = 480 * iter_y
			mob_client.atmosphere_background.vis_contents += background
	mob_client.screen |= mob_client.atmosphere_background // TODO - 3x3 tiling!!

/datum/hud/proc/remove_atmosphere_background(mob/to_show_to)
	var/client/mob_client = to_show_to?.client || mymob?.client
	if(!mob_client)
		return

	mob_client.screen -= mob_client.atmosphere_background

/atom/movable/screen/atmosphere_background_home
	icon = null
	plane = PLANE_ATMOSPHERE
	screen_loc = "CENTER-7,CENTER-7"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/atmosphere_background
	icon = 'icons/effects/space_background.dmi'
	icon_state = "atmosphere"
	plane = PLANE_ATMOSPHERE
	appearance_flags = APPEARANCE_UI | KEEP_TOGETHER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
