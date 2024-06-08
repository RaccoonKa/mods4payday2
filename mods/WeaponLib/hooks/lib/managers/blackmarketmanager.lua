local temp_tweak_data_functions = {
	get_silencer_concealment_modifiers = {
		crafted_index = 1
	},
	_calculate_weapon_concealment = {
		crafted_index = 1
	},
	damage_addend = {
		weapon_id_index = 1,
		blueprint_index = 6
	},
	damage_multiplier = {
		weapon_id_index = 1,
		blueprint_index = 6
	}
}

local backup_tweak_data = {}

for function_name, function_info in pairs(temp_tweak_data_functions) do
	Hooks:PreHook(BlackMarketManager, function_name, "weaponlib_blackmarketmanager_" .. function_name .. "_pre", function(...)
		local arguments = {...}

		local weapon_id = nil
		local factory_id = nil
		local blueprint = nil

		if function_info.crafted_index then
			local weapon = arguments[function_info.crafted_index]

			factory_id = weapon.factory_id
			weapon_id = weapon.weapon_id or managers.weapon_factory:get_weapon_id_by_factory_id(factory_id)
			blueprint = weapon.blueprint
		else
			weapon_id = arguments[function_info.weapon_id_index]
			factory_id = function_info.factory_id_index and arguments[function_info.factory_id_index] or managers.weapon_factory:get_factory_id_by_weapon_id(weapon_id)
			blueprint = arguments[function_info.blueprint_index]
		end

		if not (weapon_id and factory_id and blueprint) then
			return
		end

		backup_tweak_data[weapon_id] = tweak_data.weapon[weapon_id]

		tweak_data.weapon[weapon_id] = managers.weapon_factory:get_weapon_tweak_data_override(weapon_id, factory_id, blueprint)		
	end)

	Hooks:PostHook(BlackMarketManager, function_name, "weaponlib_blackmarketmanager_" .. function_name .. "_post", function(...)
		local arguments = {...}

		local weapon_id = nil
		local factory_id = nil
		local blueprint = nil

		if function_info.crafted_index then
			local weapon = arguments[function_info.crafted_index]

			factory_id = weapon.factory_id
			weapon_id = weapon.weapon_id or managers.weapon_factory:get_weapon_id_by_factory_id(factory_id)
			blueprint = weapon.blueprint
		else
			weapon_id = arguments[function_info.weapon_id_index]
			factory_id = function_info.factory_id_index and arguments[function_info.factory_id_index] or managers.weapon_factory:get_factory_id_by_weapon_id(weapon_id)
			blueprint = arguments[function_info.blueprint_index]
		end

		if not (weapon_id and factory_id and blueprint) then
			return
		end

		tweak_data.weapon[weapon_id] = backup_tweak_data[weapon_id]
	end)
end
