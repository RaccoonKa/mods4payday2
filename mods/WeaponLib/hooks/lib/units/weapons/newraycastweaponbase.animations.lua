-- More potential animations
table.insert(WeaponLibNRWBRegistrators.init_registrators, function(self, unit)
	self._available_redirect_passthroughs = {}
	self._weapon_animation_redirects = {}
	self._part_animation_redirects = {}
end)

-- Ignore animations that are already called in vanilla ways. 
-- Some of these won't be called as a redirect, but I'm being safe.
local blacklisted_animations = table.set(
	"charge",
	"deploy",
	"equip",
	"fire",
	"fire_steelsight",
	"magazine_empty",
	"reload",
	"reload_enter",
	"reload_exit",
	"reload_not_empty",
	"reload_not_empty_exit",
	"undeploy",
	"unequip"
)

table.insert(WeaponLibNRWBRegistrators.weapon_registrators, function(self, weapon_id, weapon_data, weapon_factory_id, weapon_factory_data)
	self._available_redirect_passthroughs = {}
	if weapon_factory_data.animations then
		for internal_id, animation_id in pairs(weapon_factory_data.animations) do
			if not blacklisted_animations[internal_id] and type(animation_id) == "string" then
				self._available_redirect_passthroughs[tostring(Idstring(internal_id))] = internal_id
			end
		end
	end

	self._weapon_animation_redirects = {}
	if weapon_factory_data.animation_redirects then
		self._weapon_animation_redirects = weapon_factory_data.animation_redirects
	end

	self._part_animation_redirects = {}
end)

table.insert(WeaponLibNRWBRegistrators.part_registrators, function(self, part, part_id, part_data)
	if part_data.animations then
		for internal_id, animation_id in pairs(part_data.animations) do
			if not blacklisted_animations[internal_id] and type(animation_id) == "string" then
				self._available_redirect_passthroughs[tostring(Idstring(internal_id))] = internal_id
			end
		end
	end

	if part_data.animation_redirects then
		self._part_animation_redirects[part_id] = part_data.animation_redirects
	end
end)

function NewRaycastWeaponBase:arm_redirect_passthrough(redirect_name, speed)
	if self._last_redirect_passthrough then
		self:tweak_data_anim_stop(self._available_redirect_passthroughs[tostring(self._last_redirect_passthrough)])
	end

	local potential_tweak_data_anim = self._available_redirect_passthroughs[tostring(redirect_name)]
	if potential_tweak_data_anim then
		self._last_redirect_passthrough = redirect_name
		self:tweak_data_anim_play(potential_tweak_data_anim, speed)
	end
end

local empty_ids = Idstring("")
function NewRaycastWeaponBase:tweak_data_anim_play_redirect(anim, speed_multiplier)
	local played = false

	if self._weapon_animation_redirects[anim] then
		local anim_name = self._weapon_animation_redirects[anim]
		local ids_anim_name = Idstring(anim_name)

		local offset = self:_get_anim_start_offset(anim_name)
		local result = self._unit:play_redirect(ids_anim_name, offset)

		if result ~= empty_ids and speed_multiplier then
			self._unit:anim_state_machine():set_speed(result, speed_multiplier)
			played = true
		end
	end

	for part_id, part_redirects in pairs(self._part_animation_redirects) do
		local unit = self._parts[part_id].unit

		if unit and part_redirects[anim] then
			local anim_name = part_redirects[anim]
			local ids_anim_name = Idstring(anim_name)

			local offset = self:_get_anim_start_offset(anim_name)
			local result = unit:play_redirect(ids_anim_name, offset)

			if result ~= empty_ids and speed_multiplier then
				unit:anim_state_machine():set_speed(result, speed_multiplier)
				played = true
			end
		end
	end

	return played
end

function NewRaycastWeaponBase:set_state_machine_global(global, value)
	if self._unit.anim_state_machine and self._unit:anim_state_machine() then
		self._unit:anim_state_machine():set_global(global, value)
	end

	for part_id, part_data in pairs(self._parts) do
		local unit = part_data.unit
		if unit then
			if unit.anim_state_machine and unit:anim_state_machine() then
				unit:anim_state_machine():set_global(global, value)
			end
		end
	end
end

Hooks:PostHook(NewRaycastWeaponBase, "tweak_data_anim_stop", "weaponlib_newraycastweaponbase_tweak_data_anim_play", function(self, anim)
	local orig_anim = anim
	local unit_anim = self:_get_tweak_data_weapon_animation(orig_anim)

	self:tweak_data_anim_play_redirect(unit_anim .. "_stop", speed_multiplier)
end)

function NewRaycastWeaponBase:tweak_data_anim_play(anim, speed_multiplier)
	local orig_anim = anim
	local unit_anim = self:_get_tweak_data_weapon_animation(orig_anim)

	local played = self:tweak_data_anim_play_redirect(unit_anim, speed_multiplier)

	local effect_manager = World:effect_manager()

	if self._active_animation_effects[anim] then
		for _, effect in ipairs(self._active_animation_effects[anim]) do
			World:effect_manager():kill(effect)
		end
	end

	self._active_animation_effects[anim] = {}
	local data = tweak_data.weapon.factory[self._factory_id]

	if data.animations and data.animations[unit_anim] then
		local anim_name = data.animations[unit_anim]
		if type(anim_name) == "string" then
			local ids_anim_name = Idstring(anim_name)
			local length = self._unit:anim_length(ids_anim_name)
			speed_multiplier = speed_multiplier or 1

			self._unit:anim_stop(ids_anim_name)
			self._unit:anim_play_to(ids_anim_name, length, speed_multiplier)

			local offset = self:_get_anim_start_offset(anim_name)
			if offset then
				self._unit:anim_set_time(ids_anim_name, offset)
			end

			played = true
		end
	end

	if data.animation_effects and data.animation_effects[unit_anim] then
		local effect_table = data.animation_effects[unit_anim]

		if effect_table then
			effect_table = clone(effect_table)
			effect_table.parent = effect_table.parent and self._unit:get_object(effect_table.parent)
			local effect = effect_manager:spawn(effect_table)

			table.insert(self._active_animation_effects[anim], effect)
		end
	end

	for part_id, data in pairs(self._parts) do
		if data.unit and data.animations and data.animations[unit_anim] then
			local anim_name = data.animations[unit_anim]
			if type(anim_name) == "string" then
				local ids_anim_name = Idstring(anim_name)
				local length = data.unit:anim_length(ids_anim_name)
				speed_multiplier = speed_multiplier or 1

				data.unit:anim_stop(ids_anim_name)
				data.unit:anim_play_to(ids_anim_name, length, speed_multiplier)

				local offset = self:_get_anim_start_offset(anim_name)
				if offset then
					data.unit:anim_set_time(ids_anim_name, offset)
				end

				played = true
			end
		end

		if data.unit and data.animation_effects and data.animation_effects[unit_anim] then
			local effect_table = data.animation_effects[unit_anim]

			if effect_table then
				effect_table = clone(effect_table)
				effect_table.parent = effect_table.parent and data.unit:get_object(effect_table.parent)
				local effect = effect_manager:spawn(effect_table)

				table.insert(self._active_animation_effects[anim], effect)
			end
		end
	end

	self:set_reload_objects_visible(true, anim)
	NewRaycastWeaponBase.super.tweak_data_anim_play(self, orig_anim, speed_multiplier)

	return played
end