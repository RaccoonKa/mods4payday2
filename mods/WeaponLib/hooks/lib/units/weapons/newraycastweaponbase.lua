WeaponLibNRWBRegistrators = {}
WeaponLibNRWBRegistrators.init_registrators = WeaponLibNRWBRegistrators.init_registrators or {}
WeaponLibNRWBRegistrators.weapon_registrators = WeaponLibNRWBRegistrators.weapon_registrators or {}
WeaponLibNRWBRegistrators.part_registrators = WeaponLibNRWBRegistrators.part_registrators or {}

Hooks:PostHook(NewRaycastWeaponBase, "init", "weaponlib_newraycastweaponbase_init", function(self, unit)
	for _, registrator in pairs(WeaponLibNRWBRegistrators.init_registrators) do
		registrator(self, unit)
	end
end)

Hooks:PostHook(NewRaycastWeaponBase, "clbk_assembly_complete", "weaponlib_newraycastweaponbase_clbk_assembly_complete", function(self, clbk, parts, blueprint)
	local weapon_data = self:weapon_tweak_data()
	local weapon_factory_data = tweak_data.weapon.factory[self._factory_id]

	tweak_data.weapon.factory[self._factory_id].animations = tweak_data.weapon.factory[self._factory_id].animations or {}

	for _, registrator in pairs(WeaponLibNRWBRegistrators.weapon_registrators) do
		registrator(self, self:_weapon_tweak_data_id(), weapon_data, self._factory_id, weapon_factory_data)
	end

	for part_id, part in pairs(self._parts) do
		local part_data = managers.weapon_factory:get_part_data_by_part_id_from_weapon(part_id, self._factory_id, self._blueprint)

		for _, registrator in pairs(WeaponLibNRWBRegistrators.part_registrators) do
			registrator(self, part, part_id, part_data)
		end
	end
end)

local partial_class_folder = ModPath .. "hooks/lib/units/weapons/"
function partial(name)
	local lua_file = partial_class_folder .. name .. ".lua"
	dofile(lua_file)
end

partial("newraycastweaponbase.misc")
partial("newraycastweaponbase.visual_objects")
partial("newraycastweaponbase.raycast")
partial("newraycastweaponbase.reloads")
partial("newraycastweaponbase.sights")
partial("newraycastweaponbase.firemodes")
partial("newraycastweaponbase.animations")