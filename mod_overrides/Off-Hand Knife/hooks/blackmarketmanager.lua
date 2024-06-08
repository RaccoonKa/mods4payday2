function BlackMarketManager:equipped_melee_weapon_damage_info(lerp_value)
	lerp_value = lerp_value or 0
	local melee_entry = self:equipped_melee_weapon()
	local stats = tweak_data.blackmarket.melee_weapons[melee_entry].stats
	local primary = self:equipped_primary()
	local secondary = self:equipped_secondary()
	local bayonet_id = self:equipped_bayonet(primary.weapon_id)
	local bayonet_sec_id = self:equipped_bayonet(secondary.weapon_id)
	local player = managers.player:player_unit()

	if bayonet_id and player:movement():current_state()._equipped_unit:base():selection_index() == 2 and melee_entry == "weapon" then
		stats = tweak_data.weapon.factory.parts[bayonet_id].stats
--		log("bayonet used")
	end

	if bayonet_sec_id and player:movement():current_state()._equipped_unit:base():selection_index() == 1 and melee_entry == "weapon" then
		stats = {
			min_damage = 10,
			min_damage_effect = 1.75,
			max_damage_effect = 1.75,
			max_damage = 10
		}
--		log("bayonet_sec used")
	end

	local dmg = math.lerp(stats.min_damage, stats.max_damage, lerp_value)
	local dmg_effect = dmg * math.lerp(stats.min_damage_effect, stats.max_damage_effect, lerp_value)
	
--	log("Damage value:")
--	log(dmg)

	return dmg, dmg_effect
end

function BlackMarketManager:equipped_bayonet(weapon_id)
	local available_weapon_mods = managers.weapon_factory:get_parts_from_weapon_id(weapon_id)
	local equipped_weapon_mods = managers.blackmarket:equipped_item("primaries").blueprint
	local equipped_weapon_mods_sec = managers.blackmarket:equipped_item("secondaries").blueprint

	if available_weapon_mods and available_weapon_mods.bayonet then
		for _, mod in ipairs(equipped_weapon_mods) do
			for _, bayonet in ipairs(available_weapon_mods.bayonet) do
				if mod == bayonet then
--					log("bayonet_Set")
					return bayonet
				end
			end
		end
	end
	if available_weapon_mods and available_weapon_mods.knife_addon then
		for _, mod in ipairs(equipped_weapon_mods_sec) do
			for _, knife_addon in ipairs(available_weapon_mods.knife_addon) do
				if mod == knife_addon then
--					log("knife_addon_Set")
					return knife_addon
				end
			end
		end
	end

	return nil
end