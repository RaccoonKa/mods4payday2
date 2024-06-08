table.insert(WeaponLibNRWBRegistrators.init_registrators, function(self, unit)
	-- Fuck of Tdlq, uggghhhh
	if self.fs_reset_methods then
		self.fs_reset_methods = function() end
		self.clip_empty = function()
			return self:ammo_base():get_ammo_remaining_in_clip() < (self._fire_mode == Idstring("volley") and 1 or self:ammo_usage())
		end
	end
end)

function NewRaycastWeaponBase:clip_empty()
	return self:ammo_base():get_ammo_remaining_in_clip() < (self._fire_mode == Idstring("volley") and 1 or self:ammo_usage())
end

function NewRaycastWeaponBase:ammo_usage()
	return self:weapon_tweak_data().ammo_usage or 1
end

Hooks:PreHook(NewRaycastWeaponBase, "assemble_from_blueprint", "weaponlib_newraycastweaponbase_assemble_from_blueprint", function(self, factory_id, blueprint, clbk)
	local override_weapon_class = nil

	for _, part_id in pairs(blueprint) do
		local part_data = managers.weapon_factory:get_part_data_by_part_id_from_weapon(part_id, factory_id, blueprint)

		if self:is_npc() and part_data.override_npc_weapon_class then
			override_weapon_class = part_data.override_npc_weapon_class
		elseif part_data.override_weapon_class then
			override_weapon_class = part_data.override_weapon_class
		end
	end

	if override_weapon_class then
		local class_table = _G[override_weapon_class]

		if class_table then
			setmetatable(self, __overrides[class_table] or class_table)

			if self.init then
				self.name_id = self._name_id

				self:init(self._unit)

				self.name_id = self._name_id
			end
		end
	end
end)

function NewRaycastWeaponBase:weapon_tweak_data(override_id, ignore_firemode_data)
	local weapon_id = override_id or self:_weapon_tweak_data_id()
	local factory_id = self._factory_id
	local blueprint = self._blueprint

	local weapon_tweak_data = {}

	if self:_weapon_tweak_data_id() ~= self._name_id or not (factory_id and blueprint) then
		weapon_tweak_data = tweak_data.weapon[weapon_id] or tweak_data.weapon.amcar
	else
		weapon_tweak_data = managers.weapon_factory:get_weapon_tweak_data_override(weapon_id, factory_id, blueprint)
	end

	if not ignore_firemode_data then
		local firemode_id = self:fire_mode()
		if weapon_tweak_data.fire_mode_data and weapon_tweak_data.fire_mode_data[firemode_id] then
			weapon_tweak_data = deep_clone(weapon_tweak_data)

			table.merge(weapon_tweak_data, weapon_tweak_data.fire_mode_data[firemode_id])
		end
	end

	return weapon_tweak_data
end

Hooks:PostHook(NewRaycastWeaponBase, "_update_stats_values", "weaponlib_newraycastweaponbase_update_stats_values", function(self, disallow_replenish, ammo_data)
	local weapon_tweak_data = self:weapon_tweak_data()

	self._can_shoot_through_shield = weapon_tweak_data.can_shoot_through_shield
	self._can_shoot_through_enemy = weapon_tweak_data.can_shoot_through_enemy
	self._can_shoot_through_wall = weapon_tweak_data.can_shoot_through_wall

	self._rays = weapon_tweak_data.rays or 1
	if self._ammo_data then
		if self._ammo_data and self._ammo_data.rays ~= nil then
			self._rays = self._ammo_data.rays
		end

		if self._ammo_data.can_shoot_through_shield ~= nil then
			self._can_shoot_through_shield = self._ammo_data.can_shoot_through_shield
		end

		if self._ammo_data.can_shoot_through_enemy ~= nil then
			self._can_shoot_through_enemy = self._ammo_data.can_shoot_through_enemy
		end

		if self._ammo_data.can_shoot_through_wall ~= nil then
			self._can_shoot_through_wall = self._ammo_data.can_shoot_through_wall
		end
	end

	-- Initially set in RaycastWeaponBase:init
	self._do_shotgun_push = weapon_tweak_data.do_shotgun_push or self._do_shotgun_push
	self._aim_assist_data = weapon_tweak_data.aim_assist or self._aim_assist_data

	local autohit_data = weapon_tweak_data.autohit
	if autohit_data then
		self._autohit_data = autohit_data
		self._autohit_current = self._autohit_data and self._autohit_data.INIT_RATIO
	end

	local bullet_class = weapon_tweak_data.bullet_class
	bullet_class = bullet_class and CoreSerialize.string_to_classtable(bullet_class)
	if bullet_class then
		self._bullet_class = bullet_class
		self._bullet_slotmask = self._bullet_class:bullet_slotmask()
		self._blank_slotmask = self._bullet_class:blank_slotmask()
	end

	local muzzle_effect = weapon_tweak_data.muzzleflash 
	muzzle_effect = muzzle_effect and Idstring(muzzle_effect)
	if muzzle_effect then
		self._muzzle_effect = muzzle_effect
		self._muzzle_effect_table.effect = self._muzzle_effect
	end

	local shell_ejection_effect = weapon_tweak_data.shell_ejection 
	shell_ejection_effect = shell_ejection_effect and Idstring(shell_ejection_effect)
	if shell_ejection_effect then
		self._shell_ejection_effect = shell_ejection_effect
		self._shell_ejection_effect_table.effect = self._shell_ejection_effect
	end

	local trail_effect = weapon_tweak_data.trail_effect 
	trail_effect = trail_effect and Idstring(weapon_tweak_data.trail_effect)
	if trail_effect then
		self._trail_effect = trail_effect
		self._trail_effect_table.effect = self._trail_effect
	end

	self._concussion_tweak = weapon_tweak_data.concussion_data or self._concussion_tweak
end)

Hooks:PostHook(NewRaycastWeaponBase, "replenish", "weaponlib_newraycastweaponbase_replenish", function(self)
	local original_tweak_data = tweak_data.weapon[self._name_id]
	local weapon_tweak_data = self:weapon_tweak_data()

	local ammo_max_multiplier = managers.player:upgrade_value("player", "extra_ammo_multiplier", 1)

	for _, category in ipairs(weapon_tweak_data.categories) do
		ammo_max_multiplier = ammo_max_multiplier * managers.player:upgrade_value(category, "extra_ammo_multiplier", 1)
	end

	ammo_max_multiplier = ammo_max_multiplier + ammo_max_multiplier * (self._total_ammo_mod or 0)

	if managers.player:has_category_upgrade("player", "add_armor_stat_skill_ammo_mul") then
		ammo_max_multiplier = ammo_max_multiplier * managers.player:body_armor_value("skill_ammo_mul", nil, 1)
	end

	ammo_max_multiplier = managers.modifiers:modify_value("WeaponBase:GetMaxAmmoMultiplier", ammo_max_multiplier)
	local ammo_max_per_clip = self:calculate_ammo_max_per_clip()

	local ammo_max_override_delta = weapon_tweak_data.AMMO_MAX - original_tweak_data.AMMO_MAX
	local ammo_max = math.round(((original_tweak_data.AMMO_MAX + (managers.player:upgrade_value(self._name_id, "clip_amount_increase") * ammo_max_per_clip)) * ammo_max_multiplier) + ammo_max_override_delta)
	ammo_max_per_clip = math.min(ammo_max_per_clip, ammo_max)

	self:set_ammo_max_per_clip(ammo_max_per_clip + self:get_chamber_size())
	self:set_ammo_max(ammo_max)
	self:set_ammo_total(ammo_max)
	self:set_ammo_remaining_in_clip(ammo_max_per_clip)

	self._ammo_pickup = weapon_tweak_data.AMMO_PICKUP
end)

function NewRaycastWeaponBase:calculate_ammo_max_per_clip()
	local added = 0
	local weapon_tweak_data = self:weapon_tweak_data()

	if self:is_category("shotgun") and weapon_tweak_data.has_magazine then
		added = managers.player:upgrade_value("shotgun", "magazine_capacity_inc", 0)

		if self:is_category("akimbo") then
			added = added * 2
		end
	elseif self:is_category("pistol") and not self:is_category("revolver") and managers.player:has_category_upgrade("pistol", "magazine_capacity_inc") then
		added = managers.player:upgrade_value("pistol", "magazine_capacity_inc", 0)

		if self:is_category("akimbo") then
			added = added * 2
		end
	elseif self:is_category("smg", "assault_rifle", "lmg") then
		added = managers.player:upgrade_value("player", "automatic_mag_increase", 0)

		if self:is_category("akimbo") then
			added = added * 2
		end
	end

	local ammo = weapon_tweak_data.CLIP_AMMO_MAX + added
	ammo = ammo + managers.player:upgrade_value(self._name_id, "clip_ammo_increase")

	if not self:upgrade_blocked("weapon", "clip_ammo_increase") then
		ammo = ammo + managers.player:upgrade_value("weapon", "clip_ammo_increase", 0)
	end

	for _, category in ipairs(weapon_tweak_data.categories) do
		if not self:upgrade_blocked(category, "clip_ammo_increase") then
			ammo = ammo + managers.player:upgrade_value(category, "clip_ammo_increase", 0)
		end
	end

	ammo = ammo + (self._extra_ammo or 0)

	return ammo
end

function NewRaycastWeaponBase:get_name_id()
	if self:gadget_overrides_weapon_functions() then
		return self:gadget_function_override("get_name_id")
	end

	return self._name_id
end

NewRaycastWeaponBase._pre_weaponlib_start_shooting = NewRaycastWeaponBase._pre_weaponlib_start_shooting or NewRaycastWeaponBase.start_shooting
function NewRaycastWeaponBase:start_shooting()
	-- Check this earlier because overkill decided to put the volley check before the gadget check so it will just break underbarrel support???
	if self:gadget_overrides_weapon_functions() then
		local gadget_func = self:gadget_function_override("start_shooting")

		if gadget_func then
			return gadget_func
		end
	end

	NewRaycastWeaponBase._pre_weaponlib_start_shooting(self)
end

NewRaycastWeaponBase._pre_weaponlib_stop_shooting = NewRaycastWeaponBase._pre_weaponlib_stop_shooting or NewRaycastWeaponBase.stop_shooting
function NewRaycastWeaponBase:stop_shooting()
	-- This is just straight up missing???
	if self:gadget_overrides_weapon_functions() then
		local gadget_func = self:gadget_function_override("stop_shooting")

		if gadget_func then
			return gadget_func
		end
	end

	NewRaycastWeaponBase._pre_weaponlib_stop_shooting(self)
end

function RaycastWeaponBase:get_stance_id()
	return self:weapon_tweak_data().use_stance or self:weapon_tweak_data(self._name_id).use_stance or self._name_id
end

function NewRaycastWeaponBase:weapon_hold()
	return self:weapon_tweak_data().weapon_hold or self:weapon_tweak_data(self._name_id).weapon_hold or self._name_id
end

function NewRaycastWeaponBase:reload_name_id()
	local initial_td = self:weapon_tweak_data()
	if initial_td.animations and initial_td.animations.reload_name_id then
		return initial_td.animations.reload_name_id
	end

	return self._name_id
end

-- Override Sounds
	function NewRaycastWeaponBase:_get_sound_event(event, alternative_event)
		if self:gadget_overrides_weapon_functions() then
			return self:gadget_function_override("_get_sound_event", self, event, alternative_event)
		end

		local sounds = self._ammo_data and self._ammo_data.sounds or self:weapon_tweak_data().sounds
		local sound_event = sounds and (sounds[event] or sounds[alternative_event])

		if self:alt_fire_active() then
			event = event and event .. "_alt"
			alternative_event = alternative_event and alternative_event .. "_alt"

			if sounds and (not event or not sounds[event]) and alternative_event then
				sound_event = sounds[alternative_event] or sound_event
			end
		end

		return sound_event
	end

-- Underbarrel Toggle
	function NewRaycastWeaponBase:setup_underbarrel_data()
		local underbarrel_prefix = "underbarrel_"

		for part_id, part in pairs(self._parts) do
			local part_unit = part.unit

			if part_unit and alive(part_unit) and part_unit.base and part_unit:base() and part_unit:base().GADGET_TYPE and part_unit:base().toggle then
				if string.sub(part_unit:base().GADGET_TYPE, 1, #underbarrel_prefix) == underbarrel_prefix then
					self._underbarrel_part = part
					break
				end
			end
		end

		local underbarrel_ammo_data = managers.weapon_factory:get_underbarrel_ammo_data_from_weapon(self._factory_id, self._blueprint)
		if self._underbarrel_part then
			self._underbarrel_part.unit:base():setup_data(self._setup, 1, underbarrel_ammo_data, self)
		end
	end

	function NewRaycastWeaponBase:underbarrel_toggle()
		if self._underbarrel_part then
			self._underbarrel_part.unit:base():toggle()
			return self._underbarrel_part.unit:base():is_on()
		end

		return nil
	end

	function NewRaycastWeaponBase:underbarrel_name_id()
		if self._underbarrel_part then
			if self._underbarrel_part.unit:base().get_name_id then
				return self._underbarrel_part.unit:base():get_name_id()
			end

			return self._underbarrel_part.unit:base().name_id or self._underbarrel_part.unit:base()._name_id
		end
	end
