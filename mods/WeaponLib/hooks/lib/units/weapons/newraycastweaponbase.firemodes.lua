-- Recalculate this after assembly for overrides.
table.insert(WeaponLibNRWBRegistrators.weapon_registrators, function(self, weapon_id, weapon_data, weapon_factory_id, weapon_factory_data)
	self._alt_fire_data = self:weapon_tweak_data().alt_fire_data
end)

-- New Burst Fire Stuff (Store these in RaycastWeaponBase because more weapon stats does things jank :angery:)

RaycastWeaponBase.firemodes = {
	{
		id = "single",
		id_string = Idstring("single"),
		default = true,
		switch_sound_id = "wp_auto_switch_off"
	},
	{
		id = "auto",
		id_string = Idstring("auto"),
		default = true,
		switch_sound_id = "wp_auto_switch_on"
	},
	{
		id = "burst",
		id_string = Idstring("burst"),
		default = false,
		switch_sound_id = "wp_auto_switch_on"
	},
	{
		id = "volley",
		id_string = Idstring("volley"),
		default = false,
		switch_sound_id = "wp_auto_switch_off"
	}
}

RaycastWeaponBase.firemode_index_lookup = {}
for index, firemode in pairs(RaycastWeaponBase.firemodes) do
	RaycastWeaponBase.firemode_index_lookup[firemode.id_string:key()] = index
end

function NewRaycastWeaponBase:fire_mode()
	if self:gadget_overrides_weapon_functions() then
		local firemode = self:gadget_function_override("fire_mode")

		if firemode ~= nil then
			return firemode
		end
	end

	self._fire_mode = self._locked_fire_mode or self._fire_mode or Idstring(self:weapon_tweak_data(nil, true).FIRE_MODE or "single")

	return self.firemodes[self.firemode_index_lookup[self._fire_mode:key()]].id
end

function NewRaycastWeaponBase:_can_use_firemode_index(firemode_index)
	local firemode_data = self.firemodes[firemode_index]
	local default = firemode_data.default

	local weapon_tweak_data = self:weapon_tweak_data()

	local toggable_firemodes = weapon_tweak_data.fire_mode_data and weapon_tweak_data.fire_mode_data.toggable
	if toggable_firemodes then
		toggable_firemodes = table.list_to_set(toggable_firemodes)
	end

	local toggle_firemode_table = weapon_tweak_data.CAN_TOGGLE_SPECIFIC_FIREMODE or toggable_firemodes
	if not toggle_firemode_table then return default end

	local firemode_id = firemode_data.id
	local can_do = toggle_firemode_table[firemode_id]
	if can_do == nil then return false end

	return can_do
end

function NewRaycastWeaponBase:toggle_firemode(skip_post_event)
	local can_toggle = not self._locked_fire_mode and self:can_toggle_firemode()

	if can_toggle then
		local current_firemode_index = self.firemode_index_lookup[self._fire_mode:key()]
		local next_firemode_index = current_firemode_index

		repeat
			next_firemode_index = (next_firemode_index % #self.firemodes) + 1
		until self:_can_use_firemode_index(next_firemode_index) or (next_firemode_index == current_firemode_index) -- If we loop all the way around safety check to not infinite loop.

		local next_firemode_data = self.firemodes[next_firemode_index]

		self._fire_mode = next_firemode_data.id_string
		if not skip_post_event and next_firemode_data.switch_sound_id then
			self._sound_fire:post_event(next_firemode_data.switch_sound_id)
		end

		local weapon_tweak_data = self:weapon_tweak_data()

		self:call_on_digital_gui("set_firemode", self:fire_mode())
		self:update_firemode_gui_ammo()

		self._fire_mode_memory = self._fire_mode
		self:_update_stats_values(true)
		self._fire_mode = self._fire_mode_memory
		self._fire_mode_memory = nil

		return true
	elseif self._alt_fire_data then
		self._alt_fire_active = not self._alt_fire_active

		if self._alt_fire_data.shell_ejection then
			local shell_ejection_effect = self._alt_fire_active and self._alt_fire_data.shell_ejection
			self._shell_ejection_effect = shell_ejection_effect and Idstring(shell_ejection_effect) or self._shell_ejection_effect
			self._shell_ejection_effect_table = {
				effect = self._shell_ejection_effect,
				parent = self._obj_shell_ejection
			}
		end

		if not skip_post_event then
			self._sound_fire:post_event(self._alt_fire_active and "wp_auto_switch_on" or "wp_auto_switch_off")
		end

		return true
	end

	return false
end