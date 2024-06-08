Hooks:PostHook(WeaponTweakData, "_init_stats", "weaponlib_weapontweakdata_init_stats", function(self)
	self.stats.damage = {}
	for i = 1, 100000, 1 do
		table.insert(self.stats.damage, i/10)
	end

	self.stats.extra_ammo = {}
	local ea_index = 1
	for i = -100, 100000, 1 do
		self.stats.extra_ammo[ea_index] = i
		ea_index = ea_index + 0.5
	end

	self.stats.total_ammo_mod = {}
	for i = -100, 100000, 5 do
		table.insert(self.stats.total_ammo_mod, i / 100)
	end

	self.stats.reload = {}
	for i = 5, 100000, 0.5 do
		if i <= 10 or i == math.floor(i) then
			table.insert(self.stats.reload, i / 10)
		end
	end
end)

local function log_suggestion(old, new)
	log("                                                        '" .. old .. "' is deprecated, consider using '" .. new .. "'!")
end

local function weapon_needs_conversion(weapon_data)
	if weapon_data.tactical_reload or weapon_data.full_capacity then
		return true
	end

	return false
end

local function weapon_backwards_compatibility_conversion(weapon_id_for_warning, weapon_data)
	local did_conversion = false

	if weapon_needs_conversion(weapon_data) then
		log("")
		log("[WeaponLib] [Backwards Compatibility] WARNING: '" .. weapon_id_for_warning .. "' is using outdated/deprecated tweak data!")

		if weapon_data.tactical_reload then
			if weapon_data.tactical_reload > 2 then
				weapon_data.reload_num = weapon_data.tactical_reload

				log_suggestion("tactical_reload", "reload_num")
			else
				weapon_data.chamber_size = weapon_data.tactical_reload

				log_suggestion("tactical_reload", "chamber_size")
			end
		end

		if weapon_data.full_capacity then
			weapon_data.chamber_size = weapon_data.full_capacity - (weapon_data.CLIP_AMMO_MAX or 0)

			log_suggestion("full_capacity", "chamber_size")
		end

		did_conversion = true
	end

	return did_conversion
end

local function factory_needs_conversion(part_data)
	if part_data.stats and ( part_data.stats.extra_ammo_new or part_data.stats.total_ammo_mod_new ) then
		return true
	end

	if part_data.custom_stats and ( part_data.custom_stats.rof_mult ) then
		return true
	end

	if part_data.weapon_reload_override or part_data.weapon_hold_override or part_data.weapon_stance_override or part_data.timer_multiplier or part_data.timer_adder then
		return true
	end

	if part_data.scope_overlay_hide_weapon then
		return true
	end

	if part_data.override_weapon then
		return weapon_needs_conversion(part_data.override_weapon)
	end

	return false
end

local function factory_backwards_compatibility_conversion(part_id_for_warning, part_data)
	local did_conversion = false

	if factory_needs_conversion(part_data) then
		log("")
		log("[WeaponLib] [Backwards Compatibility] WARNING: '" .. part_id_for_warning .. "' is using outdated/deprecated tweak data!")

		part_data.stats = part_data.stats or {}
		part_data.custom_stats = part_data.custom_stats or {}
		part_data.override_weapon = part_data.override_weapon or {}
		part_data.override_weapon_add = part_data.override_weapon_add or {}
		part_data.override_weapon_multiply = part_data.override_weapon_multiply or {}

		if part_data.stats.extra_ammo_new then
			part_data.custom_stats.ammo_offset = part_data.stats.extra_ammo_new
			log_suggestion("stats.extra_ammo_new", "custom_stats.ammo_offset")
		end

		if part_data.stats.total_ammo_mod_new then
			part_data.override_weapon_add["AMMO_MAX"] = part_data.stats.total_ammo_mod_new
			log_suggestion("stats.total_ammo_mod_new", "override_weapon_add[\"AMMO_MAX\"]")
		end

		if part_data.weapon_reload_override then
			for name_id, value in pairs(part_data.weapon_reload_override) do
				part_data.override_weapon["animations"] = part_data.override_weapon["animations"] or {}
				part_data.override_weapon["animations"]["reload_name_id"] = value
			end

			log_suggestion("weapon_reload_override", "override_weapon[\"animations\"][\"reload_name_id\"]")
		end

		if part_data.weapon_hold_override then
			for name_id, value in pairs(part_data.weapon_hold_override) do
				part_data.override_weapon["weapon_hold"] = value
			end

			log_suggestion("weapon_hold_override", "override_weapon[\"weapon_hold\"]")
		end

		if part_data.weapon_stance_override then
			for name_id, value in pairs(part_data.weapon_stance_override) do
				part_data.override_weapon["use_stance"] = value
			end

			log_suggestion("weapon_stance_override", "override_weapon[\"use_stance\"]")
		end

		if part_data.timer_multiplier then
			part_data.override_weapon_multiply["timers"] = part_data.override_weapon_multiply["timers"] or {}

			for timer_name, value in pairs(part_data.timer_multiplier) do
				part_data.override_weapon_multiply["timers"][timer_name] = value
			end

			log_suggestion("timer_multiplier", "override_weapon_multiply[\"timers\"]")
		end

		if part_data.timer_adder then
			part_data.override_weapon_add["timers"] = part_data.override_weapon_add["timers"] or {}

			for timer_name, value in pairs(part_data.timer_adder) do
				part_data.override_weapon_add["timers"][timer_name] = value
			end

			log_suggestion("timer_adder", "override_weapon_add[\"timers\"]")
		end

		if part_data.custom_stats.rof_mult then
			part_data.custom_stats.fire_rate_multiplier = part_data.custom_stats.rof_mult

			log_suggestion("custom_stats.rof_mult", "custom_states.fire_rate_multiplier")
		end

		if part_data.scope_overlay_hide_weapon ~= nil then
			part_data.steelsight_weapon_visible = not part_data.scope_overlay_hide_weapon

			log_suggestion("scope_overlay_hide_weapon", "steelsight_weapon_visible")
		end

		if part_data.override_weapon then
			weapon_backwards_compatibility_conversion(part_id_for_warning .. ".override_weapon", part_data.override_weapon)
		end

		did_conversion = true
	end

	-- Check Overrides
	if part_data.override then
		for part_id, part_data in pairs(part_data.override) do
			if factory_backwards_compatibility_conversion(part_id_for_warning .. ".override." .. part_id, part_data) then
				did_conversion = true
			end
		end
	end

	return did_conversion
end

Hooks:PostHook(WeaponTweakData, "_init_data_player_weapons", "weaponlib_weapontweakdata_init_data_player_weapons", function(self)
	local did_conversion = false

	for weapon_id, weapon_data in pairs(self) do
		if type(weapon_data) == "table" and weapon_data.use_data and weapon_backwards_compatibility_conversion(weapon_id, weapon_data) then
			did_conversion = true
		end
	end

	for part_id, part_data in pairs(self.factory.parts) do
		if factory_backwards_compatibility_conversion(part_id, part_data) then
			did_conversion = true
		end
	end

	if did_conversion then log("") end
end)

