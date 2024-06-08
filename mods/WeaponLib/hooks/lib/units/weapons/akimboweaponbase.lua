function AkimboWeaponBase:_update_bullet_objects(...)
	AkimboWeaponBase.super._update_bullet_objects(self, ...)

	if alive(self._second_gun) then
		AkimboWeaponBase.super._update_bullet_objects(self._second_gun:base(), ...)
	end
end

function AkimboWeaponBase:fire(...)
	if not self._manual_fire_second_gun then
		local result = AkimboWeaponBase.super.fire(self, ...)

		if alive(self._second_gun) then
			table.insert(self._fire_callbacks, {
				t = self:get_fire_time(),
				callback = callback(self, self, "_fire_second", {
					...
				})
			})
		end

		return result
	end

	local result = nil
	if self._fire_second_gun_next then
		self:_fire_second(...)

		self._fire_second_gun_next = false
	else
		result = AkimboWeaponBase.super.fire(self, ...)

		self._fire_second_gun_next = true
	end

	return result
end

local individual_anims = table.set(
	"fire",
	"fire_steelsight",
	"magazine_empty"
)
function AkimboWeaponBase:tweak_data_anim_play(anim, ...)
	if alive(self._second_gun) and not individual_anims[anim] then
		local second_gun_anim = self:_second_gun_tweak_data_anim_version(anim)

		self._second_gun:base():tweak_data_anim_play(second_gun_anim, ...)
	end

	return AkimboWeaponBase.super.tweak_data_anim_play(self, anim, ...)
end

local ids_burst = Idstring("burst")
function AkimboWeaponBase:_fire_second(params)
	if alive(self._second_gun) and self._setup and alive(self._setup.user_unit) then
		self._second_gun:base()._bullets_fired = 0
		local fired = self._second_gun:base().super.fire(self._second_gun:base(), unpack(params))

		if fired then
			if self._fire_mode == ids_burst and self._bullets_fired and self._bullets_fired > 0 and not self:weapon_tweak_data().sounds.fire_single then
				self._second_gun:base():_fire_sound()
			elseif self._fire_second_sound then
				self._fire_second_sound = false

				self._second_gun:base():_fire_sound()
			end

			managers.hud:set_ammo_amount(self:selection_index(), self:ammo_info())
		end

		return fired
	end
end