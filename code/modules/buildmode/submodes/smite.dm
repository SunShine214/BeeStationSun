/datum/buildmode_mode/smite
	key = "smite"
	var/datum/smite/selected_smite

/datum/buildmode_mode/smite/Destroy()
	selected_smite = null
	return ..()

/datum/buildmode_mode/smite/show_help(client/user)
	to_chat(user, span_notice("***********************************************************\n\
		Right Mouse Button on buildmode button = Select smite to use.\n\
		Left Mouse Button on mob/living = Smite the mob.\n\
		***********************************************************"))

/datum/buildmode_mode/smite/change_settings(client/user)
	var/punishment = tgui_input_list(user, "Choose a punishment", "DIVINE SMITING", GLOB.smite_list)
	var/smite_path = GLOB.smite_list[punishment]
	var/datum/smite/picking_smite = new smite_path
	var/configuration_success = picking_smite.configure(user)
	if (configuration_success == FALSE)
		return
	selected_smite = picking_smite

/datum/buildmode_mode/smite/handle_click(client/user, params, object)
	var/list/modifiers = params2list(params)

	if (!check_rights(R_ADMIN | R_FUN))
		return

	if (!LAZYACCESS(modifiers, LEFT_CLICK))
		return

	if (!isliving(object))
		return

	if (selected_smite == null)
		to_chat(user, span_notice("No smite selected."))
		return

	selected_smite.effect(user, object)
