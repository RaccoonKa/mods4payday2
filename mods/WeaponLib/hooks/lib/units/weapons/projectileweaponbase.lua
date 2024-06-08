function ProjectileWeaponBase:_update_stats_values(...)
	ProjectileWeaponBase.super._update_stats_values(self, ...)

	if self._ammo_data and self._ammo_data.projectile_type_index ~= nil then
		self._projectile_type_index = self._ammo_data.projectile_type_index
	end
end