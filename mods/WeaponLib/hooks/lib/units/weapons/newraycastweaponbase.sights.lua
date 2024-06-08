-- Scopes
table.insert(WeaponLibNRWBRegistrators.init_registrators, function(self, unit)
	self._scope_index_lookup = {}
	self._scope_part_ids = {}
	self._scope_steelsight_weapon_visible = {}
	self._scope_effects = {}
	self._scope_overlays = {}
	self._scope_overlay_border_colors = {}
end)

table.insert(WeaponLibNRWBRegistrators.weapon_registrators, function(self, weapon_id, weapon_data, weapon_factory_id, weapon_factory_data)
	self._scope_index_lookup = {}
	self._scope_part_ids = {}
	self._scope_steelsight_weapon_visible = {}
	self._scope_effects = {}
	self._scope_overlays = {}
	self._scope_overlay_border_colors = {}

	self._scope_second_sight_setup_index = 2
end)

table.insert(WeaponLibNRWBRegistrators.part_registrators, function(self, part, part_id, part_data)
	local is_sight = part_data.type == "sight"
	local is_second_sight = part_data.perks and table.contains(part_data.perks, "second_sight")

	if is_sight or is_second_sight then
		local index = 1
		if not is_sight then
			index = self._scope_second_sight_setup_index
			self._scope_second_sight_setup_index = self._scope_second_sight_setup_index + 1
		end

		self._scope_index_lookup[part_id] = index
		self._scope_part_ids[index] = part_id
		self._scope_steelsight_weapon_visible[index] = part_data.steelsight_weapon_visible == nil and true or part_data.steelsight_weapon_visible
		self._scope_effects[index] = part_data.scope_effect or "payday_off"
		self._scope_overlays[index] = part_data.scope_overlay

		-- TODO: Generalise this normalization across all tweak data so you can use this stuff anywhere.
		self._scope_overlay_border_colors[index] = type(part_data.scope_overlay_border_color) == "string" and BeardLib.Utils:normalize_string_value(part_data.scope_overlay_border_color) or part_data.scope_overlay_border_color
	end
end)

function NewRaycastWeaponBase:zoom()
	local scope_index = self:get_active_scope_index()

	if self._scope_part_ids and scope_index > 1 then
		local part_id = self._scope_part_ids[scope_index]
		local part_data = managers.weapon_factory:get_part_data_by_part_id_from_weapon(part_id, self._factory_id, self._blueprint)

		local gadget_zoom_stat = part_data.stats and part_data.stats.gadget_zoom or NewRaycastWeaponBase.super.zoom(self)
		local gadget_zoom_add_stat = part_data.stats and part_data.stats.gadget_zoom_add or 0

		local zoom_index = math.min(gadget_zoom_stat + gadget_zoom_add_stat, #tweak_data.weapon.stats.zoom)

		return tweak_data.weapon.stats.zoom[zoom_index]
	end

	return NewRaycastWeaponBase.super.zoom(self)
end

function NewRaycastWeaponBase:get_active_scope_index()
	return (self:current_second_sight_index() or 0) + 1
end

function NewRaycastWeaponBase:set_visual_scope_index(scope_index)
	self._visual_scope_index = scope_index
end

function NewRaycastWeaponBase:_set_parts_visible(visible)
	if self._parts then
		local hide_weapon_base = visible == false
		local hide_all_parts = hide_weapon_base

		if not hide_all_parts then
			hide_all_parts = not self:get_scope_steelsight_weapon_visible(self._visual_scope_index)

			if not hide_all_parts then
				for part_id, data in pairs(self._parts) do
					local parent = data.parent and managers.weapon_factory:get_part_id_from_weapon_by_type(data.parent, self._blueprint)
					local scope_index = self._scope_index_lookup and (self._scope_index_lookup[part_id] or (parent and self._scope_index_lookup[parent])) or 1

					local unit = data.unit or data.link_to_unit
					local steelsight_swap_state = scope_index == self._visual_scope_index

					if alive(unit) then
						local is_visible = self._parts[part_id].steelsight_visible == nil or self._parts[part_id].steelsight_visible == steelsight_swap_state

						unit:set_visible(is_visible)
						self:_set_digital_gui_visibility(unit, is_visible)
					end
				end
			end
		end

		if hide_all_parts then
			for part_id, data in pairs(self._parts) do
				local unit = data.unit or data.link_to_unit

				if alive(unit) then
					unit:set_visible(false)
					self:_set_digital_gui_visibility(unit, false)
				end
			end
		end

		if hide_weapon_base then
			self._unit:set_visible(false)
		else
			self._unit:set_visible(true)
		end
	end

	self:_chk_charm_upd_state()
end

function NewRaycastWeaponBase:_set_digital_gui_visibility(unit, visible)
	if unit:digital_gui() then
		unit:digital_gui():set_visible(visible)
	end

	if unit:digital_gui_upper() then
		unit:digital_gui_upper():set_visible(visible)
	end

	if unit:digital_gui_thd() then
		unit:digital_gui_thd():set_visible(visible)
	end
end

function NewRaycastWeaponBase:get_scope_steelsight_weapon_visible(scope_index)
	return self._scope_steelsight_weapon_visible and (self._scope_steelsight_weapon_visible[scope_index] == nil and true or self._scope_steelsight_weapon_visible[scope_index])
end

function NewRaycastWeaponBase:get_scope_effect(scope_index)
	return self._scope_effects and self._scope_effects[scope_index] or "payday_off"
end

function NewRaycastWeaponBase:get_scope_overlay(scope_index)
	return self._scope_overlays and self._scope_overlays[scope_index] or nil
end

function NewRaycastWeaponBase:get_scope_overlay_border_color(scope_index)
	return self._scope_overlay_border_colors and self._scope_overlay_border_colors[scope_index] or Color.black
end