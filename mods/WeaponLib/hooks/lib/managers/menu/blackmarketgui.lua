Hooks:PostHook(BlackMarketGui, "show_stats", "weaponlib_blackmarketgui_show_stats", function(self, box)
	if not self._stats_panel or not self._rweapon_stats_panel or not self._armor_stats_panel or not self._mweapon_stats_panel then
		return
	end

	if not self._slot_data then
		return
	end

	if not self._slot_data.comparision_data then
		return
	end

	if self._slot_data.dont_compare_stats or (tweak_data.weapon[self._slot_data.name] or self._slot_data.default_blueprint) or tweak_data.blackmarket.armors[self._slot_data.name] or tweak_data.economy.armor_skins[self._slot_data.name] or tweak_data.blackmarket.melee_weapons[self._slot_data.name] then
		return
	end

	local weapon = managers.blackmarket:get_crafted_category_slot(self._slot_data.category, self._slot_data.slot)
	local name = weapon and weapon.weapon_id or self._slot_data.name
	local category = self._slot_data.category
	local slot = self._slot_data.slot

	local mod_stats = WeaponDescription.get_stats_for_mod(self._slot_data.name, name, category, slot)

	local value, stat_changed = nil

	for _, stat in ipairs(self._stats_shown) do
		if stat.name ~= "optimal_range" then
			value = mod_stats.chosen[stat.name]
			stat_changed = value ~= 0

			for name, column in pairs(self._stats_texts[stat.name]) do
				column:set_alpha(stat_changed and 1 or 0.5)
			end
		end
	end
end)

local function get_forbids(weapon_id, part_id)
	local weapon_data = tweak_data.weapon.factory[weapon_id]

	if not weapon_data then
		return {}
	end

	local default_parts = {}
	for _, part in ipairs(weapon_data.default_blueprint) do
		default_parts[part] = true

		local part_data = tweak_data.weapon.factory.parts[part]
		if part_data and part_data.adds then
			for _, adds_part in ipairs(part_data.adds) do
				default_parts[adds_part] = true
			end
		end
	end

	local weapon_mods = {}
	for _, part in ipairs(weapon_data.uses_parts) do
		if not default_parts[part] then
			local part_data = tweak_data.weapon.factory.parts[part]

			if part_data and not part_data.unatainable then
				weapon_mods[part] = {}
			end
		end
	end

	for part, _ in pairs(weapon_mods) do
		local part_data = tweak_data.weapon.factory.parts[part]

		if part_data.forbids then
			for other_part, _ in pairs(weapon_mods) do
				local other_part_data = tweak_data.weapon.factory.parts[part]

				if table.contains(part_data.forbids, other_part) then
					if not table.contains(weapon_mods[part], other_part) then
						table.insert(weapon_mods[part], other_part)
					end


					if not table.contains(weapon_mods[other_part], part) then
						table.insert(weapon_mods[other_part], part)
					end
				end
			end
		end
	end

	return weapon_mods[part_id]
end

local function list_items(header, items)
	for _, item in pairs(items) do
		header = header .. "\n    " .. item
	end

	return header
end

Hooks:PostHook(BlackMarketGui, "update_info_text", "weaponlib_blackmarketgui_update_info_text", function(self)
	local slot_data = self._slot_data
	local tab_data = self._tabs[self._selected]._data
	local prev_data = tab_data.prev_node_data
	local identifier = tab_data.identifier

	if identifier == self.identifiers.weapon_mod then
		local current_part_id = slot_data.name
		local current_part_category = tweak_data.weapon.factory.parts[current_part_id].type
		local weapon_id = managers.weapon_factory:get_factory_id_by_weapon_id(prev_data.name)
		local weapon_data = tweak_data.weapon.factory[weapon_id]

		local requires_text = nil
		if slot_data.conflict then
			local forbid = managers.blackmarket:can_modify_weapon(slot_data.category, slot_data.slot, current_part_id)
			local localised_items = {}

			if type(forbid) == "table" then
				local type = ""
				for _, part_id in ipairs(forbid) do
					if table.contains(weapon_data.uses_parts or {}, part_id) then
						type = managers.localization:to_upper_text("bm_menu_" .. tostring(tweak_data.weapon.factory.parts[part_id].type))
						break
					end
				end

				self:set_info_text(3, "     " .. managers.localization:to_upper_text("bm_menu_conflict", {
					conflict = type
				}))
				local info_text = self._info_texts[3]
				local _, _, _, th = info_text:text_rect()
				info_text:set_h(th)
			end

			if type(forbid) == "table" then
				local forbid_count = #forbid
				for _, part_id in ipairs(forbid) do
					if table.contains(weapon_data.uses_parts or {}, part_id) then
						local name_id = tweak_data.weapon.factory.parts[part_id].name_id or "fail"
						table.insert(localised_items, managers.localization:to_upper_text(name_id))
					end
				end
			else
				if not tweak_data.weapon.factory.parts[forbid] then
					local name_id = "bm_menu_" .. tostring(forbid)
					table.insert(localised_items, managers.localization:to_upper_text(name_id))
				end
			end

			if #localised_items > 0 then
				requires_text = list_items(managers.localization:to_upper_text("bm_menu_requires"), localised_items)
			end
		end

		local incompatibility_text = nil
		if not ( slot_data.removes and #slot_data.removes > 0 ) then
			local forbidden_parts = get_forbids(weapon_id, current_part_id)
			local droppable_mods = managers.blackmarket:get_dropable_mods_by_weapon_id(prev_data.name)

			if forbidden_parts and #forbidden_parts > 0 then
				local free_spaces = 3
				local forbids = {}

				for i, forbidden_part in ipairs(forbidden_parts) do
					local data = tweak_data.weapon.factory.parts[forbidden_part]

					if data then
						forbids[data.type] = (forbids[data.type] or 0) + 1
					end
				end

				for category, _ in pairs(forbids) do
					if not droppable_mods[category] then
						forbids[category] = nil
					end
				end

				local size = table.size(forbids)
				local localised_categories = {}
				local localised_parts = {}

				for category, amount in pairs(forbids) do
					local category_count = 0

					local default_parts = table.list_to_set(weapon_data.default_blueprint)
					for _, part_id in ipairs(weapon_data.uses_parts) do
						local part_data = tweak_data.weapon.factory.parts[part_id]
						if part_data and not part_data.unatainable and part_data.type == category and not default_parts[part_id] then
							category_count = category_count + 1
						end
					end

					if ( amount > free_spaces ) or ( size > free_spaces ) then
						local percent_forbidden = amount / category_count
						local localised_category = managers.localization:to_upper_text("bm_menu_" .. tostring(category) .. "_plural")
						local quantifier = percent_forbidden == 1 and "all" or percent_forbidden > 0.66 and "most" or "some"
						quantifier = managers.localization:to_upper_text("bm_mod_incompatibility_" .. tostring(quantifier))

						table.insert(localised_categories, managers.localization:to_upper_text("bm_menu_category_quantity", {
							quantifier = quantifier, category = localised_category
						}))

						free_spaces = free_spaces - 1
					else
						for _, part_id in ipairs(forbidden_parts) do
							local part_category = tweak_data.weapon.factory.parts[part_id].type
							if part_category ~= current_part_category and part_category == category then
								table.insert(localised_parts, managers.localization:to_upper_text(tweak_data.weapon.factory.parts[part_id].name_id or "bm_w_" .. part_id))
							end
						end

						free_spaces = free_spaces - 1
					end
				end

				local localised_items = {}
				for _, localised_part in pairs(localised_parts) do
					table.insert(localised_items, localised_part)
				end
				for _, localised_category in pairs(localised_categories) do
					table.insert(localised_items, localised_category)
				end

				if #localised_items > 0 then
					incompatibility_text = list_items(managers.localization:to_upper_text("bm_menu_incompatiblity"), localised_items)
				end
			end
		end

		if requires_text or incompatibility_text then
			local output = requires_text or incompatibility_text
			if requires_text and incompatibility_text then
				output = requires_text .. "\n\n" .. incompatibility_text
			end

			if self._info_texts[4]:text() ~= "" then
				output = "\n" .. output
			end

			self:set_info_text(5, output)
			local info_text = self._info_texts[5]
			local _, _, _, th = info_text:text_rect()
			info_text:set_h(th)
		end
	end
end)
