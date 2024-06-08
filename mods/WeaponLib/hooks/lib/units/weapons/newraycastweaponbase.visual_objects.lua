-- Scopes
table.insert(WeaponLibNRWBRegistrators.init_registrators, function(self, unit)
	self._chamber_parts = {}
	self._total_bullet_parts = {}
	self._bullet_parts = {}
	self._ammo_parts = {}
	self._reserve_parts = {}
end)

table.insert(WeaponLibNRWBRegistrators.weapon_registrators, function(self, weapon_id, weapon_data, weapon_factory_id, weapon_factory_data)
	self._chamber_parts = {}
	self._total_bullet_parts = {}
	self._bullet_parts = {}
	self._ammo_parts = {}
	self._reserve_parts = {}
end)

table.insert(WeaponLibNRWBRegistrators.part_registrators, function(self, part, part_id, part_data)
	local function setup_visual_objects(tweak_data_name, parts_table, max_amount)
		local function objects_for_visual_objects(object_type_prefix)
			local tweak_data_objects_type = object_type_prefix .. tweak_data_name .. "_objects"

			local td = part_data[tweak_data_objects_type]
			if td then
				parts_table[part_id] = parts_table[part_id] or {}
				parts_table[part_id][object_type_prefix .. "objects"] = {
					objects = {},
					step = td.step,
					lowest_index = 0,
					ignore_prediction = td.ignore_prediction
				}

				local offset = td.offset or 0
				local prefix = td.prefix

				local lowest_index = 0
				for object_count = 0 + offset, td.amount + offset do
					local object = part.unit:get_object(Idstring(prefix .. object_count))

					if td.negate then
						object_count = max_amount - object_count
					end

					if object_count < lowest_index then
						lowest_index = object_count
					end

					if object then
						parts_table[part_id][object_type_prefix .. "objects"].objects[object_count] = {object}
					end
				end

				parts_table[part_id][object_type_prefix .. "objects"].lowest_index = lowest_index
			end
		end

		objects_for_visual_objects("")
		objects_for_visual_objects("reverse_")
		objects_for_visual_objects("unique_")

		-- Advanced objects are quite different so handle them differently.
		local td = part_data["advanced_" .. tweak_data_name .. "_objects"]
		if td then
			parts_table[part_id] = parts_table[part_id] or {}
			parts_table[part_id].advanced_objects = {
				objects = {},
				step = td.step,
				lowest_index = 0,
				ignore_prediction = td.ignore_prediction
			}

			local lowest_index = 0
			for index, object_names in pairs(td) do
				number_index = tonumber(index)

				if number_index then
					object_count = math.floor(number_index)

					if td.negate then
						object_count = max_amount - object_count
					end

					if object_count < lowest_index then
						lowest_index = object_count
					end

					parts_table[part_id].advanced_objects.objects[object_count] = {}

					if type(object_names) == "string" then
						object_names = {object_names}
					end

					for _, object_name in pairs(object_names) do
						local object = part.unit:get_object(Idstring(object_name))

						if object then
							table.insert(parts_table[part_id].advanced_objects.objects[object_count], object)
						end
					end
				end
			end

			parts_table[part_id].advanced_objects.lowest_index = lowest_index
		end
	end

	local chamber_size = self:get_chamber_size()

	local total_bullet_size = self:ammo_base():get_ammo_max_per_clip()
	local bullet_size = total_bullet_size - chamber_size
	
	local ammo_size = self:get_highest_reload_num()

	local reserve_size = self:ammo_base():get_ammo_max() - self:ammo_base():get_ammo_max_per_clip()

	if self.AKIMBO then
		chamber_size = chamber_size / 2 

		total_bullet_size = total_bullet_size / 2
		bullet_size = bullet_size / 2

		ammo_size = ammo_size / 2

		reserve_size = reserve_size / 2
	end

	local weapon_tweak_data = self:weapon_tweak_data()
	local use_ammo_objects = weapon_tweak_data.use_ammo_objects

	setup_visual_objects("chamber", self._chamber_parts, chamber_size)

	setup_visual_objects("total_bullet", self._total_bullet_parts, total_bullet_size)
	setup_visual_objects("bullet", use_ammo_objects and self._ammo_parts or self._bullet_parts, bullet_size)

	setup_visual_objects("ammo", self._ammo_parts, ammo_size)
	
	setup_visual_objects("reserve", self._reserve_parts, reserve_size)
end)

function NewRaycastWeaponBase:_update_objects(part_table, amount, custom_object_check, is_prediction)
	if not part_table then return end

	-- Might as well check for akimbos here.
	if self.AKIMBO then
		amount = amount / 2

		if self.parent_weapon then
			amount = math.ceil(amount)
		else
			amount = math.floor(amount)
		end
	end

	-- Visibility functions.
	function default(i, count)
		return i <= count
	end

	function reverse(i, count)
		return i >= count
	end

	function unique(i, count)
		return i == count
	end

	for part_id, object_data in pairs(part_table) do
		local unit = self._parts[part_id].unit

		function check_objects(prefix, visibility_func)
			local data = object_data[prefix .. "objects"]

			if data then
				if custom_object_check then
					custom_object_check(data)
				else
					if data.ignore_prediction and is_prediction then return end

					local step = data.step or 1
					local stepped_amount = math.floor(amount/step)*step

					local lowest_index = data.lowest_index
					if stepped_amount < lowest_index then
						stepped_amount = lowest_index
					end

					local visible_objects = {}

					for object_amount_level, objects in pairs(data.objects) do
						for _, object in pairs(objects) do
							local visibility = visibility_func(object_amount_level, stepped_amount)

							if visibility then
								table.insert(visible_objects, object)
							else
								object:set_visibility(false)
							end
						end
					end

					for _, object in pairs(visible_objects) do
						object:set_visibility(true)
					end
				end
			end
		end

		check_objects("", default)
		check_objects("reverse_", reverse)
		check_objects("unique_", unique)
		check_objects("advanced_", unique)
	end
end

function NewRaycastWeaponBase:check_bullet_objects()
	self:_update_bullet_objects("get_ammo_remaining_in_clip", false)
end

function NewRaycastWeaponBase:predict_bullet_objects()
	self:_update_bullet_objects("get_ammo_total", true)
end

function NewRaycastWeaponBase:_update_bullet_objects(ammo_func, is_prediction)
	local chamber_size = self:get_chamber_size()

	local ammo_base = self:ammo_base()
	local ammo = ammo_base[ammo_func](ammo_base)
	local ammo_without_chamber = ammo

	-- Cap out the ammo total for weird mags.
	if ammo_func == "get_ammo_total" then
		local total_ammo = ammo_base:get_ammo_total()
		ammo = ammo_base:get_ammo_max_per_clip()
		ammo_without_chamber = ammo - chamber_size

		if total_ammo < ammo then
			ammo = total_ammo
			ammo_without_chamber = total_ammo
		end
	elseif ammo_func == "get_ammo_remaining_in_clip" then
		ammo_without_chamber = ammo - chamber_size
	end

	--ammo = math.max(ammo, 0) -- stop ammo going below zero. EDIT: Changed this, not really sure why there's a problem with these going negative?

	self:_update_objects(self._total_bullet_parts, ammo                             , nil, is_prediction)
	self:_update_objects(self._bullet_parts,       ammo_without_chamber             , nil, is_prediction)
	self:_update_objects(self._reserve_parts,      ammo_base:get_ammo_total() - ammo, nil, is_prediction)

	-- Update the chamber.
	self:_update_objects(self._chamber_parts,      math.min(ammo, chamber_size)     , nil, is_prediction)
end