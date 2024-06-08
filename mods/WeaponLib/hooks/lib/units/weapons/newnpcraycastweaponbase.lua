NewNPCRaycastWeaponBase._pre_weaponlib_sound_autofire_start = NewNPCRaycastWeaponBase._pre_weaponlib_sound_autofire_start or NewNPCRaycastWeaponBase._sound_autofire_start
function NewNPCRaycastWeaponBase:_sound_autofire_start(nr_shots)
	local tweak_sound = self:weapon_tweak_data().sounds
	if tweak_sound.use_fix then return end

	self:_pre_weaponlib_sound_autofire_start(nr_shots)
end

Hooks:PostHook(NewNPCRaycastWeaponBase, "auto_fire_blank", "weaponlib_newnpcraycastweaponbase_auto_fire_blank", function(self, direction, impact, sub_ids, override_direction)
	local tweak_sound = self:weapon_tweak_data().sounds
	if not tweak_sound.use_fix then return end

	self:_sound_singleshot()
end)

function NewNPCRaycastWeaponBase:_sound_singleshot()
	local tweak_sound = self:weapon_tweak_data().sounds
	local forced_sound_name = tweak_sound.fire or tweak_sound.fire_single

	if forced_sound_name then
		local suppressed_switch = managers.weapon_factory:get_sound_switch("suppressed", self._factory_id, self._blueprint)
		self._sound_fire:set_switch("suppressed", suppressed_switch or "regular")
		self._sound_fire:post_event(forced_sound_name)
	else
		local sound_name = tweak_sound.prefix .. self._setup.user_sound_variant .. self._voice .. "_1shot"
		local sound = self._sound_fire:post_event(sound_name)

		if not sound then
			sound_name = tweak_sound.prefix .. "1" .. self._voice .. "_1shot"
			sound = self._sound_fire:post_event(sound_name)
		end
	end
end