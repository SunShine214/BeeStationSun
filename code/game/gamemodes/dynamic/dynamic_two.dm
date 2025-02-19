/datum/game_mode/dynamic
	name = "dynamic mode"
	config_tag = "dynamic"
	report_type = "dynamic"

	announce_span = "danger"
	announce_text = "Dynamic mode!" // This needs to be changed maybe

	reroll_friendly = FALSE

	/// How many cycles have elapsed
	var/cycle_count = 1

	var/total_points = 0

	var/unused_points = 0

	var/grace_period_remaining // = define DYNAMIC_GRACE_PERIOD

	var/list/candidates = list()
	/// Rules that are processed, rule_process is called on the rules in this list.
	var/list/current_rules = list()
	/// List of executed rulesets.
	var/list/executed_rules = list()

	/// Which ruleset is dynamic saving up for?
	var/datum/dynamic_ruleset/ruleset_to_spawn
	/// How long has dynamic been saving up for?
	var/time_saving_up = 0

/// Picks a ruleset based on weight
/datum/game_mode/dynamic/proc/pick_ruleset(list/datum/dynamic_ruleset/drafted_rules, var/max_point_cost)
	var/list/drafted_rules_tmp = new list()
	for (ruleset in drafted_rules)
		var/tmp_weight = ruleset.get_weight()
		if(max_point_cost)
			if(ruleset.get_cost() > max_point_cost)
				continue
		if(!tmp_weight)
			tmp_weight = 0
		drafted_rules_tmp[ruleset] = tmp_weight
	return pick_weight_allow_zero(drafted_rules_tmp)


/// Scales points based on round duration
/datum/game_mode/dynamic/proc/scale_points(var/points)
	return null

/// Gets a list of players to further verify.
/datum/game_mode/dynamic/proc/find_candidates()
	return new list()

/// Calculates points to be gained for this period
/datum/game_mode/dynamic/proc/find_point_gain()
	if (grace_period_remaining > 0)
		return 0
	var/tmp_points = 0
	tmp_points = scale_points(tmp_points)
	return 0

/// Calls when a targeted ruleset cannot be bought in time
/datum/game_mode/dynamic/proc/fail_target()
	pick_ruleset(get_allowed_rulesets(), unused_points)

/// Actually add points (should be usable externally, useful for admins)
/datum/game_mode/dynamic/proc/add_points(var/points)
	total_points += points
	unused_points += points

/// Do stuff this cycle
/datum/game_mode/dynamic/proc/proccess()

	add_points(find_point_gain())
	if(check_target_ruleset())
		if(!target_ruleset.activate(candidates))
			CRASH()
		pick_target_ruleset()



	cycle_count = cycle_count + 1

/// Roundstart ruleset picking logic
/datum/game_mode/dynamic/proc/pull_roundstart()

/// Get a list of rulesets allowed
/datum/game_mode/dynamic/proc/get_allowed_rulesets()
	return null

/// Chooses a ruleset to now target
/datum/game_mode/dynamic/proc/pick_target_ruleset()
	//might be smarter to collapse this into pick_ruleset
	ruleset_to_spawn = pick_ruleset(candidates)

/// Returns true if the target ruleset is possible, false if otherwise
/datum/game_mode/dynamic/proc/check_target_ruleset()
	if(!ruleset_to_spawn.get_possible())
		return FALSE
	if(ruleset_to_spawn.get_cost() > unused_points)
		return FALSE
	return TRUE

/datum/game_mode/dynamic/proc/activate_ruleset(var/datum/dynamic_ruleset/ruleset)


// INIT / CONFIG //

/// Return rulesets from dynamic_ruleset
/datum/game_mode/dynamic/proc/init_rulesets(ruleset_subtype)
	var/list/rulesets = list()

	for (var/datum/dynamic_ruleset/ruleset_type as anything in subtypesof(ruleset_subtype))
		if (initial(ruleset_type.name) == "")
			continue

		if (initial(ruleset_type.weight) == 0)
			continue

		var/ruleset = new ruleset_type(src)
		configure_ruleset(ruleset)
		rulesets += ruleset

	return rulesets
