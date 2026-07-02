return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`PartyFinderFilters` encountered an error loading the Darktide Mod Framework.")

		new_mod("PartyFinderFilters", {
			mod_script       = "PartyFinderFilters/scripts/mods/PartyFinderFilters/PartyFinderFilters",
			mod_data         = "PartyFinderFilters/scripts/mods/PartyFinderFilters/PartyFinderFilters_data",
			mod_localization = "PartyFinderFilters/scripts/mods/PartyFinderFilters/PartyFinderFilters_localization",
		})
	end,
	packages = {},
}
