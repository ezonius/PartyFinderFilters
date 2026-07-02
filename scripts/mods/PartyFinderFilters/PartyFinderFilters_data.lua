local mod = get_mod("PartyFinderFilters")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "default_excludes_group",
				type = "group",
				sub_widgets = {
					{
						setting_id = "auto_check_class",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "default_exclude_veteran",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "default_exclude_zealot",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "default_exclude_psyker",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "default_exclude_ogryn",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "default_exclude_broker",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "default_exclude_adamant",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "default_exclude_cryptic",
						type = "checkbox",
						default_value = false,
					},
				}
			},
			{
				setting_id = "default_exclude_havoc_group",
				type = "group",
				sub_widgets = {
					{
						setting_id = "default_exclude_mutator_havoc_enemies_parasite_headshot",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "default_exclude_mutator_havoc_rotten_armor",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "default_exclude_mutator_havoc_tougher_skin",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "default_exclude_mutator_havoc_enemies_corrupted",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "default_exclude_mutator_encroaching_garden",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "default_exclude_mutator_havoc_enraged",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "default_exclude_mutator_bolstering_minions",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "default_exclude_mutator_monster_spawner",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "default_exclude_mutator_common_minions_on_fire",
						type = "checkbox",
						default_value = false,
					},
				}
			},
			{
				setting_id = "default_exclude_havoc_rank_group",
				type = "group",
				sub_widgets = {
					{
						setting_id = "default_exclude_havoc_rank_1_19",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "default_exclude_havoc_rank_20_29",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "default_exclude_havoc_rank_30_40",
						type = "checkbox",
						default_value = false,
					},
				}
			},
		}
	}
}
