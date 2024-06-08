Hooks:PostHook(PlayerInventoryGui, "_update_info_weapon_mod", "weaponlib_playerinventorygui_update_info_weapon_mod", function(self, box)
	local mod_data = box.params.mod_data
	local crafted = managers.blackmarket:get_crafted_category_slot(mod_data.category, mod_data.slot)
	local part_id = managers.weapon_factory:get_part_id_from_weapon_by_type(mod_data.selected_tab, crafted.blueprint)

	if not part_id or managers.weapon_factory:is_part_standard_issue_by_weapon_id(mod_data.name, part_id) then
		return
	end
	
	local mod_stats = WeaponDescription.get_stats_for_mod(part_id, mod_data.name, mod_data.category, mod_data.slot)

	for _, stat in ipairs(self._stats_shown) do
		local value = mod_stats.chosen[stat.name]
		local stat_changed = value ~= 0 and 1 or 0.5

		for name, column in pairs(self._stats_texts[stat.name]) do
			column:set_alpha(stat_changed)
		end
	end
end)
