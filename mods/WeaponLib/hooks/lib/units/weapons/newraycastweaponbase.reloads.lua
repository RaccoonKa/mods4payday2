-- Reloading

function RaycastWeaponBase:can_reload()
	local ammo_remaining_in_clip = self:ammo_base():get_ammo_remaining_in_clip()
	return ammo_remaining_in_clip < self:ammo_base():get_ammo_total() and ammo_remaining_in_clip <= self:get_reload_threshold(true)
end

function NewRaycastWeaponBase:should_do_empty_reload()
	return self:ammo_base():get_ammo_remaining_in_clip() <= self:get_reload_threshold(false)
end

function NewRaycastWeaponBase:get_reload_threshold(is_not_empty)
	if is_not_empty then
		return self:weapon_tweak_data().reload_threshold or (self:ammo_base():get_ammo_max_per_clip() - 1)
	else
		return self:weapon_tweak_data().empty_reload_threshold or 0
	end
end

function NewRaycastWeaponBase:get_chamber_size()
	return self:weapon_tweak_data().chamber_size or 0
end

function NewRaycastWeaponBase:get_reload_nums(is_not_empty)
	local weapon_tweak_data = self:weapon_tweak_data()

	local default = self:use_shotgun_reload() and 1 or (self:ammo_base():get_ammo_max_per_clip() - self:get_chamber_size())

	local reload_nums = { weapon_tweak_data.reload_num or default }
	if not is_not_empty then
		reload_nums = { (weapon_tweak_data.empty_reload_num or weapon_tweak_data.reload_num) or default }
	end

	local shotgun_reload_tweak = self:_get_shotgun_reload_tweak_data(is_not_empty)
	if shotgun_reload_tweak then
		if shotgun_reload_tweak.reload_queue then
			for index, queue_data in pairs(shotgun_reload_tweak.reload_queue) do
				reload_nums[index] = queue_data.reload_num
			end
		elseif shotgun_reload_tweak.reload_num then
			reload_nums = { shotgun_reload_tweak.reload_num }
		end
	end

	return reload_nums
end

function NewRaycastWeaponBase:reload_expire_t(is_not_empty)
	if self:use_shotgun_reload() then
		local ammo_total = self:ammo_base():get_ammo_total()
		local ammo_max_per_clip = self:ammo_base():get_ammo_max_per_clip()
		if not is_not_empty then
			ammo_max_per_clip = ammo_max_per_clip - self:get_chamber_size()
		end

		local ammo_remaining_in_clip = self:ammo_base():get_ammo_remaining_in_clip()
		local ammo_to_reload = math.min(ammo_total - ammo_remaining_in_clip, ammo_max_per_clip - ammo_remaining_in_clip)

		local shotgun_reload_tweak = self:_get_shotgun_reload_tweak_data(is_not_empty)

		if shotgun_reload_tweak and shotgun_reload_tweak.reload_queue then
			local reload_num_table = self:get_reload_nums(is_not_empty)

			local reload_expire_t = 0
			local queue_index = 0
			local queue_data = nil
			local queue_num = #shotgun_reload_tweak.reload_queue

			while ammo_to_reload > 0 do
				if queue_index == queue_num then
					reload_expire_t = reload_expire_t + (shotgun_reload_tweak.reload_queue_wrap or 0)
				end

				queue_index = queue_index % queue_num + 1
				queue_data = shotgun_reload_tweak.reload_queue[queue_index]
				reload_expire_t = reload_expire_t + queue_data.expire_t or 0.5666666666666667

				ammo_to_reload = ammo_to_reload - (reload_num_table and reload_num_table[queue_index] or 1)
			end

			return reload_expire_t
		end

		local reload_shell_expire_t = self:reload_shell_expire_t(is_not_empty)
		local reload_num = self:get_clamped_reload_num()

		return math.ceil(ammo_to_reload / reload_num) * reload_shell_expire_t
	end

	return nil
end

function NewRaycastWeaponBase:reload_enter_expire_t(is_not_empty)
	if self:use_shotgun_reload() then
		local shotgun_reload_tweak = self:_get_shotgun_reload_tweak_data(is_not_empty)

		return shotgun_reload_tweak and shotgun_reload_tweak.reload_enter or self:weapon_tweak_data().timers.shotgun_reload_enter or 0.3
	end

	return nil
end

function NewRaycastWeaponBase:reload_exit_expire_t(is_not_empty)
	if self:use_shotgun_reload() then
		local shotgun_reload_tweak = self:_get_shotgun_reload_tweak_data(is_not_empty)

		if shotgun_reload_tweak then
			return shotgun_reload_tweak.reload_exit
		end

		if is_not_empty then
			return self:weapon_tweak_data().timers.shotgun_reload_exit_not_empty or 0.3
		end

		return self:weapon_tweak_data().timers.shotgun_reload_exit_empty or 0.7
	end

	return nil
end

function NewRaycastWeaponBase:reload_shell_expire_t(is_not_empty)
	if self:use_shotgun_reload() then
		local shotgun_reload_tweak = self:_get_shotgun_reload_tweak_data(is_not_empty)

		return shotgun_reload_tweak and shotgun_reload_tweak.reload_shell or self:weapon_tweak_data().timers.shotgun_reload_shell or 0.5666666666666667
	end

	return nil
end

function NewRaycastWeaponBase:_first_shell_reload_expire_t(is_not_empty)
	if self:use_shotgun_reload() then
		local shotgun_reload_tweak = self:_get_shotgun_reload_tweak_data(is_not_empty)
		local first_shell_offset = shotgun_reload_tweak and shotgun_reload_tweak.reload_first_shell_offset or self:weapon_tweak_data().timers.shotgun_reload_first_shell_offset or 0.33

		return self:reload_shell_expire_t(is_not_empty) - first_shell_offset
	end

	return nil
end

-- Thanks overkill, :c
function NewRaycastWeaponBase:update_ammo_objects()
	local clamped_reload_num = self:get_clamped_reload_num()

	local custom_object_check = nil
	local shotgun_reload_tweak = self:_get_shotgun_reload_tweak_data(not self:started_reload_empty())
	if shotgun_reload_tweak and shotgun_reload_tweak.reload_queue then
		custom_object_check = function(data)
			local ammo_remaining_in_clip = self:ammo_base():get_ammo_remaining_in_clip()
			local ammo_available = math.min(self:ammo_base():get_ammo_total() - ammo_remaining_in_clip, self:ammo_base():get_ammo_max_per_clip() - ammo_remaining_in_clip)

			local queue_num = #shotgun_reload_tweak.reload_queue
			local queue_index = self._shotgun_queue_index % queue_num + 1
			local queue_data = shotgun_reload_tweak.reload_queue[queue_index]
			local queue_shell_order = queue_data and queue_data.shell_order
			local ammo_to_reload = 0

			repeat
				ammo_to_reload = ammo_to_reload + math.min(ammo_available, clamped_reload_num)
				ammo_available = ammo_available - clamped_reload_num
			until ammo_available <= 0 or queue_data and queue_data.stop_update_ammo

			local object_i = nil

			for object_amount_level, objects in pairs(data.objects) do
				for _, object in pairs(objects) do
					if queue_shell_order then
						object_i = table.get_vector_index(queue_shell_order, object_amount_level)
					else
						object_i = object_amount_level
					end

					object:set_visibility(object_i and object_i <= ammo_to_reload)
				end
			end
		end
	end

	self:_update_objects(self._ammo_parts, clamped_reload_num, custom_object_check)
end

function NewRaycastWeaponBase:enter_reload()
	self._started_reload_empty = self:should_do_empty_reload()
end

function NewRaycastWeaponBase:start_reload(...)
	NewRaycastWeaponBase.super.start_reload(self, ...)

	if self:use_shotgun_reload() then
		local speed_multiplier = self:reload_speed_multiplier()
		local shotgun_reload_tweak = self:_get_shotgun_reload_tweak_data(not self:started_reload_empty())
		local t = managers.player:player_timer():time()

		self._shotgun_queue_index = nil
		if shotgun_reload_tweak and shotgun_reload_tweak.reload_queue then
			self._shotgun_queue_index = 0
			local next_queue_data = shotgun_reload_tweak.reload_queue[1]
			self._next_shell_reloded_t = t + next_queue_data.expire_t / speed_multiplier

			if not next_queue_data.skip_update_ammo then
				self:update_ammo_objects()
			end
		else
			self._next_shell_reloded_t = t + self:_first_shell_reload_expire_t(not self._started_reload_empty) / speed_multiplier

			self:update_ammo_objects()
		end

		self._current_reload_speed_multiplier = speed_multiplier
	else
		self:update_ammo_objects()
	end
end

function NewRaycastWeaponBase:started_reload_empty()
	return self._started_reload_empty
end

function NewRaycastWeaponBase:get_highest_reload_num()
	local highest = 0

	for _, num in pairs(self:get_reload_nums(false)) do
		if num > highest then highest = num end
	end

	for _, num in pairs(self:get_reload_nums(true)) do
		if num > highest then highest = num end
	end

	return highest
end

function NewRaycastWeaponBase:get_reload_num()
	-- Beardlib doesn't check all it's shit properly so I can't use `self:started_reload_empty()` here.
	local reload_num_table = self:get_reload_nums(not self._started_reload_empty)

	local default = self:use_shotgun_reload() and 1 or (self:ammo_base():get_ammo_max_per_clip() - self:get_chamber_size())
	local reload_num = reload_num_table and reload_num_table[self._shotgun_queue_index or 1] or default

	return reload_num
end

function NewRaycastWeaponBase:get_clamped_reload_num(forced_reload_num)
	local reload_num = forced_reload_num or self:get_reload_num()

	if self._setup.expend_ammo then
		local ammo_remaining_in_clip = self:ammo_base():get_ammo_remaining_in_clip()

		local space_left = self:ammo_base():get_ammo_max_per_clip() - ammo_remaining_in_clip
		local ammo_left = self:ammo_base():get_ammo_total() - ammo_remaining_in_clip

		return math.min(math.min(space_left, reload_num), ammo_left)
	else
		return reload_num
	end
end

function NewRaycastWeaponBase:update_reloading(t, dt, time_left)
	if self:use_shotgun_reload() and self._next_shell_reloded_t and self._next_shell_reloded_t < t then
		local speed_multiplier = self:reload_speed_multiplier()
		local shotgun_reload_tweak = self:_get_shotgun_reload_tweak_data(not self:started_reload_empty())
		local next_queue_data = nil

		if shotgun_reload_tweak and shotgun_reload_tweak.reload_queue then
			self._shotgun_queue_index = self._shotgun_queue_index % #shotgun_reload_tweak.reload_queue + 1

			if self._shotgun_queue_index == #shotgun_reload_tweak.reload_queue then
				self._next_shell_reloded_t = self._next_shell_reloded_t + (shotgun_reload_tweak.reload_queue_wrap or 0)
			end

			next_queue_data = shotgun_reload_tweak.reload_queue[self._shotgun_queue_index + 1]
			self._next_shell_reloded_t = self._next_shell_reloded_t + (next_queue_data and next_queue_data.expire_t or 0.5666666666666667) / speed_multiplier
		else
			self._next_shell_reloded_t = self._next_shell_reloded_t + self:reload_shell_expire_t(not self._started_reload_empty) / speed_multiplier
		end

		local ammo_to_reload = self:get_clamped_reload_num()

		self:ammo_base():set_ammo_remaining_in_clip(math.min(self:ammo_base():get_ammo_total(), self:ammo_base():get_ammo_max_per_clip(), self:ammo_base():get_ammo_remaining_in_clip() + ammo_to_reload))
		managers.job:set_memory("kill_count_no_reload_" .. tostring(self._name_id), nil, true)

		if not next_queue_data or not next_queue_data.skip_update_ammo then
			self:update_ammo_objects()
		end

		return true
	end
end

function NewRaycastWeaponBase:on_reload(amount)
	self._shotgun_queue_index = nil

	forced_reload_num = nil
	if self:use_shotgun_reload() then
		forced_reload_num = self:ammo_base():get_ammo_max_per_clip() - self:get_chamber_size()
	end

	amount = amount or (self:ammo_base():get_ammo_remaining_in_clip() + self:get_clamped_reload_num(forced_reload_num))

	if self._setup.expend_ammo then
		self:ammo_base():set_ammo_remaining_in_clip(math.min(self:ammo_base():get_ammo_total(), amount))
	else
		self:ammo_base():set_ammo_remaining_in_clip(amount)
		self:ammo_base():set_ammo_total(amount)
	end

	managers.job:set_memory("kill_count_no_reload_" .. tostring(self._name_id), nil, true)

	local user_unit = managers.player:player_unit()
	if user_unit then
		user_unit:movement():current_state():send_reload_interupt()
	end

	self:set_reload_objects_visible(false)

	self._reload_objects = {}
end

function NewRaycastWeaponBase:reload_interuptable()
	return not not self:use_shotgun_reload()
end

function NewRaycastWeaponBase:shotgun_shell_data()
	if self:use_shotgun_reload() and not self._skip_reload_shotgun_shell then
		local reload_shell_data = self:weapon_tweak_data().animations.reload_shell_data
		local unit_name = reload_shell_data and reload_shell_data.unit_name or "units/payday2/weapons/wpn_fps_shell/wpn_fps_shell"
		local align = reload_shell_data and reload_shell_data.align or nil

		if reload_shell_data then
			if reload_shell_data.ammo_units then
				local ammo_remaining_in_clip = self:get_ammo_remaining_in_clip()
				local ammo_available = math.min(self:get_ammo_total() - ammo_remaining_in_clip, self:get_ammo_max_per_clip() - ammo_remaining_in_clip)
				unit_name = reload_shell_data.ammo_units[math.clamp(ammo_available, 1, #reload_shell_data.ammo_units)]
			elseif reload_shell_data.unit_name then
				unit_name = reload_shell_data.unit_name
			end
		end

		return {
			unit_name = unit_name,
			align = align
		}
	end

	return nil
end

function NewRaycastWeaponBase:use_shotgun_reload()
	if self:gadget_overrides_weapon_functions() then
		return self:gadget_function_override("use_shotgun_reload")
	end

	local weapon_tweak_data = self:weapon_tweak_data()
	local empty = self:should_do_empty_reload() or self._started_reload_empty

	local use_shotgun_reload_on_empty = weapon_tweak_data.use_shotgun_reload_on_empty
	local use_shotgun_reload_on_not_empty = weapon_tweak_data.use_shotgun_reload_on_not_empty

	if (use_shotgun_reload_on_empty and empty) or (use_shotgun_reload_on_not_empty and not empty) then
		return true
	end

	return not not self._use_shotgun_reload -- Cleanup potential nil conditional.
end