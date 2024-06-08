function WeaponUnderbarrelRaycast:setup_data(setup_data, damage_multiplier, ammo_data, parent_base)
	WeaponUnderbarrel.setup_data(self, setup_data, damage_multiplier, ammo_data, parent_base)

	self._base_stats_modifiers = ammo_data and ammo_data.base_stats_modifiers or {}
	self._blueprint = {}
	self._parts = {}

	self:_update_stats_values(false, ammo_data)
	RaycastWeaponBase.setup(self, setup_data, damage_multiplier)
end

function WeaponUnderbarrelRaycast:_spawn_muzzle_effect()
	return WeaponUnderbarrel._spawn_muzzle_effect(self)
end

function WeaponUnderbarrelRaycast:_spawn_shell_eject_effect()
	return WeaponUnderbarrel._spawn_shell_eject_effect(self)
end

function WeaponUnderbarrelRaycast:get_name_id()
	return self.name_id
end

Hooks:PostHook(WeaponUnderbarrelShotgunRaycast, "init", "weaponlib_weaponunderbarrelshotgunraycast_init", function(self, unit)
	self._use_shotgun_reload = tweak_data.weapon[self._name_id].use_shotgun_reload or false
end)

function WeaponUnderbarrelShotgunRaycast:_get_sound_event(weapon, event, alternative_event)
	return WeaponUnderbarrel._get_sound_event(self, weapon, event, alternative_event)
end

function WeaponUnderbarrelShotgunRaycast:_spawn_muzzle_effect()
	return WeaponUnderbarrel._spawn_muzzle_effect(self)
end

function WeaponUnderbarrelShotgunRaycast:_spawn_shell_eject_effect()
	return WeaponUnderbarrel._spawn_shell_eject_effect(self)
end