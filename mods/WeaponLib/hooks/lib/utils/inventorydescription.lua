local backup_tweak_data = {}

local function override_tweak_data(weapon_id, blueprint)
	backup_tweak_data[weapon_id] = backup_tweak_data[weapon_id] or tweak_data.weapon[weapon_id]
	tweak_data.weapon[weapon_id] = managers.weapon_factory:get_weapon_tweak_data_override(weapon_id, managers.weapon_factory:get_factory_id_by_weapon_id(weapon_id), blueprint)
end

local function restore_tweak_data(weapon_id)
	tweak_data.weapon[weapon_id] = backup_tweak_data[weapon_id] or tweak_data.weapon[weapon_id]
end

function WeaponDescription._get_weapon_override_stats(weapon_id, blueprint)
	local base_stats = WeaponDescription._get_base_stats(weapon_id)
	override_tweak_data(weapon_id, blueprint)

	local base_override_stats = WeaponDescription._get_base_stats(weapon_id)
	restore_tweak_data(weapon_id)

	local weapon_override_stats = {}
	for _, stat in pairs(WeaponDescription._stats_shown) do
		weapon_override_stats[stat.name] = {}

		if base_stats[stat.name].value then
			weapon_override_stats[stat.name].value = base_override_stats[stat.name].value - base_stats[stat.name].value
		end
	end

	return weapon_override_stats
end

WeaponDescription._weaponlib_pre_get_skill_stats = WeaponDescription._weaponlib_pre_get_skill_stats or WeaponDescription._get_skill_stats
function WeaponDescription._get_skill_stats(weapon_id, category, slot, base_stats, mods_stats, silencer, single_mod, auto_mod, blueprint)
	override_tweak_data(weapon_id, blueprint)
	local return_data = WeaponDescription._weaponlib_pre_get_skill_stats(weapon_id, category, slot, base_stats, mods_stats, silencer, single_mod, auto_mod, blueprint)
	restore_tweak_data(weapon_id)
	return return_data
end

function WeaponDescription._get_overriden_stats_modifiers(weapon_id, blueprint)
	local factory_id = managers.weapon_factory:get_factory_id_by_weapon_id(weapon_id)
	local modifier_stats = managers.weapon_factory:get_weapon_tweak_data_override(weapon_id, factory_id, blueprint).stats_modifiers

	return modifier_stats
end

WeaponDescription._weaponlib_pre_get_mods_stats = WeaponDescription._weaponlib_pre_get_mods_stats or WeaponDescription._get_mods_stats
function WeaponDescription._get_mods_stats(name, base_stats, equipped_mods, bonus_stats)
	local mods_stats = WeaponDescription._weaponlib_pre_get_mods_stats(name, base_stats, equipped_mods, bonus_stats)

	if equipped_mods then
		local weapon_override_stats = WeaponDescription._get_weapon_override_stats(name, equipped_mods)

		local original_modifier_stats = tweak_data.weapon[name].stats_modifiers
		local modifier_stats = WeaponDescription._get_overriden_stats_modifiers(name, equipped_mods)

		for _, stat in pairs(WeaponDescription._stats_shown) do
			if mods_stats[stat.name].value then
				mods_stats[stat.name].value = mods_stats[stat.name].value + weapon_override_stats[stat.name].value

				if modifier_stats and modifier_stats[stat.name] and modifier_stats[stat.name] ~= original_modifier_stats[stat.name] then
					if original_modifier_stats[stat.name] then
						mods_stats[stat.name].value = mods_stats[stat.name].value / original_modifier_stats[stat.name]
					end

					mods_stats[stat.name].value = mods_stats[stat.name].value * modifier_stats[stat.name]
				end
			end
		end
	end

	return mods_stats
end

WeaponDescription._weaponlib_pre_get_weapon_mod_stats = WeaponDescription._weaponlib_pre_get_weapon_mod_stats or WeaponDescription._get_weapon_mod_stats
function WeaponDescription._get_weapon_mod_stats(mod_name, weapon_name, base_stats, mods_stats, equipped_mods)
	local mod_stats = WeaponDescription._weaponlib_pre_get_weapon_mod_stats(mod_name, weapon_name, base_stats, mods_stats, equipped_mods)

	local factory_id = managers.weapon_factory:get_factory_id_by_weapon_id(weapon_name)
	local default_blueprint = managers.weapon_factory:get_default_blueprint_by_factory_id(factory_id)
	local part_data = nil

	for _, mod in pairs(mod_stats) do
		part_data = nil

		if mod.name then
			local new_blueprint = deep_clone(default_blueprint)
			table.insert(new_blueprint, mod.name)

			local weapon_override_stats = WeaponDescription._get_weapon_override_stats(weapon_name, new_blueprint)

			local original_modifier_stats = tweak_data.weapon[weapon_name].stats_modifiers
			local modifier_stats = WeaponDescription._get_overriden_stats_modifiers(weapon_name, new_blueprint)

			for _, stat in pairs(WeaponDescription._stats_shown) do
				if mod[stat.name] then
					mod[stat.name] = mod[stat.name] + weapon_override_stats[stat.name].value

					if modifier_stats and modifier_stats[stat.name] and modifier_stats[stat.name] ~= original_modifier_stats[stat.name] then
						if original_modifier_stats[stat.name] then
							mod[stat.name] = mod[stat.name] / original_modifier_stats[stat.name]
						end

						mod[stat.name] = mod[stat.name] * modifier_stats[stat.name]
					end
				end
			end
		end
	end

	return mod_stats
end

WeaponDescription._weaponlib_pre_get_stats = WeaponDescription._weaponlib_pre_get_stats or WeaponDescription._get_stats
function WeaponDescription._get_stats(name, category, slot, blueprint)
	local base_stats, mods_stats, skill_stats = WeaponDescription._weaponlib_pre_get_stats(name, category, slot, blueprint)
	local factory_id = managers.weapon_factory:get_factory_id_by_weapon_id(name)
	local blueprint = blueprint or slot and managers.blackmarket:get_weapon_blueprint(category, slot) or managers.weapon_factory:get_default_blueprint_by_factory_id(factory_id)

	if blueprint then
		local cosmetics = managers.blackmarket:get_weapon_cosmetics(category, slot)
		local bonus_stats = {}
		if cosmetics and cosmetics.id and cosmetics.bonus and not managers.job:is_current_job_competitive() and not managers.weapon_factory:has_perk("bonus", factory_id, blueprint) then
			bonus_stats = tweak_data:get_raw_value("economy", "bonuses", tweak_data.blackmarket.weapon_skins[cosmetics.id].bonus, "stats") or {}
		end

		local original_base_stats = WeaponDescription._get_base_stats(name)
		local original_mods_stats = WeaponDescription._get_mods_stats(name, original_base_stats, deep_clone(blueprint), bonus_stats) 

		local weapon_override_stats = WeaponDescription._get_weapon_override_stats(name, blueprint)
		local clip_ammo, max_ammo, ammo_data = WeaponDescription.get_weapon_ammo_info(name, tweak_data.weapon[name].stats.extra_ammo, base_stats.totalammo.index + mods_stats.totalammo.index)

		override_tweak_data(name, blueprint)
		local overriden_clip_ammo, overriden_max_ammo, overriden_ammo_data = WeaponDescription.get_weapon_ammo_info(name, tweak_data.weapon[name].stats.extra_ammo, base_stats.totalammo.index + mods_stats.totalammo.index)
		restore_tweak_data(name)

		mods_stats.totalammo.value = weapon_override_stats.totalammo.value + ammo_data.mod
		mods_stats.magazine.value = original_mods_stats.magazine.value

		local my_clip = base_stats.magazine.value + mods_stats.magazine.value + skill_stats.magazine.value
		if overriden_max_ammo < my_clip then
			mods_stats.magazine.value = mods_stats.magazine.value + overriden_max_ammo - my_clip
		end
	end

	return base_stats, mods_stats, skill_stats
end
