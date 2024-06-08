function WeaponUnderbarrel:setup_data(setup_data, damage_multiplier, ammo_data, parent_base)
	self._alert_events = setup_data.alert_AI and {} or nil
	self._alert_fires = {}
	self._autoaim = setup_data.autoaim
	self._setup = setup_data

	self._ammo_data = ammo_data or {}
	self._ammo:set_ammo_data(self._ammo_data)

	local function get_object_this_or_parent(object_name)
		local ids_object_name = Idstring(object_name)
		return self._unit:get_object(ids_object_name) or parent_base and parent_base._unit:get_object(ids_object_name)
	end

	local muzzle_effect = self._tweak_data.muzzleflash or self._ammo_data.muzzleflash
	self._muzzle_effect = muzzle_effect and Idstring(muzzle_effect)
	self._obj_fire = get_object_this_or_parent("fire")

	if self._muzzle_effect and self._obj_fire then
		self._muzzle_effect_table = {
			force_synch = true,
			effect = self._muzzle_effect,
			parent = self._obj_fire
		}
	end

	local shell_ejection_effect = self._tweak_data.shell_ejection
	self._shell_ejection_effect = shell_ejection_effect and Idstring(shell_ejection_effect)
	self._obj_shell_ejection = get_object_this_or_parent("a_shell")

	if self._shell_ejection_effect and self._obj_shell_ejection then
		self._shell_ejection_effect_table = {
			effect = self._shell_ejection_effect,
			parent = self._obj_shell_ejection
		}
	end

	self._parent_base = parent_base
end

function WeaponUnderbarrel:_get_sound_event(weapon, event, alternative_event)
	local sounds = self._tweak_data.sounds
	local sound_event = sounds and (sounds[event] or sounds[alternative_event])

	if self._ammo_data and self._ammo_data.sounds then
		sound_event = self._ammo_data.sounds[event] or self._ammo_data.sounds[alternative_event]
	end

	return sound_event
end

function WeaponUnderbarrel:get_name_id()
	return self.name_id
end

function WeaponUnderbarrel:_spawn_muzzle_effect()
	if self._muzzle_effect_table then
		World:effect_manager():spawn(self._muzzle_effect_table)

		return false
	end

	return true
end

function WeaponUnderbarrel:_spawn_shell_eject_effect()
	if self._shell_ejection_effect_table then
		World:effect_manager():spawn(self._shell_ejection_effect_table)

		return false
	end

	return true
end