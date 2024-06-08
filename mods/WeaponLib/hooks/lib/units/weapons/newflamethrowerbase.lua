function NewFlamethrowerBase:_update_stats_values(...)
	self._bullet_class = nil

	NewFlamethrowerBase.super._update_stats_values(self, ...)
	self:setup_default()

	local ammo_data = self._ammo_data

	if ammo_data then
		local rays = ammo_data.rays

		if rays ~= nil then
			self._rays = rays
		end

		local bullet_class = ammo_data.bullet_class

		if bullet_class ~= nil then
			bullet_class = CoreSerialize.string_to_classtable(bullet_class)

			if bullet_class then
				self._bullet_class = bullet_class
				self._bullet_slotmask = bullet_class:bullet_slotmask()
				self._blank_slotmask = bullet_class:blank_slotmask()
			end
		end
	end
end