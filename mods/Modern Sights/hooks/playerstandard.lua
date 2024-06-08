Hooks:PostHook(PlayerStandard, "_stance_entered", "FancyScopeCheck", function(self, unequipped)
	local value = 0.155
	value = value / managers.player:upgrade_value("weapon", "enter_steelsight_speed_multiplier", 1)

	if not unequipped then
		if self._state_data.in_steelsight then
			DelayedCalls:Add("FancyScopeCheckDelay", value, function()
				if self._state_data.in_steelsight then
					self:set_ads_objects(true)
				end
			end)
		else
			self:set_ads_objects(false)
		end
	end
end)

function PlayerStandard:set_ads_objects(state)
	local weap_base = self._equipped_unit:base()
	if not weap_base._blueprint or not weap_base._factory_id then return end

	local object_lists = self:get_ads_objects(weap_base._factory_id, weap_base._blueprint, weap_base:is_second_sight_on() or false)

	for k,v in ipairs(object_lists.all_ads_objects) do
		local part_id = v[1]
		local object_id = v[2]
		if not part_id or not object_id then return end

		object_id = Idstring(object_id)
		if not object_id then return end

		local part = weap_base._parts[part_id]
		if not part then return end

		local part_unit = part.unit
		if not part_unit then return end

		local object = part_unit:get_object(object_id)
		if not object then return end

		object:set_visibility(true)
	end
	for k,v in ipairs(object_lists.ads_objects) do
		local part_id = v[1]
		local object_id = v[2]
		if not part_id or not object_id then return end

		object_id = Idstring(object_id)
		if not object_id then return end

		local part = weap_base._parts[part_id]
		if not part then return end

		local part_unit = part.unit
		if not part_unit then return end

		local object = part_unit:get_object(object_id)
		if not object then return end

		object:set_visibility(state)
	end
	for k,v in ipairs(object_lists.ads_objects_hide) do
		local part_id = v[1]
		local object_id = v[2]
		if not part_id or not object_id then return end

		object_id = Idstring(object_id)
		if not object_id then return end

		local part = weap_base._parts[part_id]
		if not part then return end

		local part_unit = part.unit
		if not part_unit then return end

		local object = part_unit:get_object(object_id)
		if not object then return end

		object:set_visibility(not state)
	end
end

function PlayerStandard:get_ads_objects(factory_id, blueprint, second_sight)
	local assembled_blueprint = managers.weapon_factory:get_assembled_blueprint(factory_id, blueprint)
	local forbidden = managers.weapon_factory:_get_forbidden_parts(factory_id, assembled_blueprint)
	local override = managers.weapon_factory:_get_override_parts(factory_id, assembled_blueprint)
	local part = nil
	local ads_objects = {}
	local ads_objects_hide = {}
	local all_ads_objects = {}

	for _, part_id in ipairs(assembled_blueprint) do
		if not forbidden[part_id] then
			part = managers.weapon_factory:_part_data(part_id, factory_id, override)

			if part.ads_objects then
				for index, object_id in ipairs(part.ads_objects) do
					if (second_sight and part.type == "gadget") or (not second_sight and part.type == "sight") then
						table.insert(ads_objects, {part_id, object_id})
					end

					table.insert(all_ads_objects, {part_id, object_id})
				end
			end

			if part.ads_objects_hide then
				for index, object_id in ipairs(part.ads_objects_hide) do
					if (second_sight and part.type == "gadget") or (not second_sight and part.type == "sight") then
						table.insert(ads_objects_hide, {part_id, object_id})
					end

					table.insert(all_ads_objects, {part_id, object_id})
				end
			end
		end
	end

	return {
		ads_objects = ads_objects,
		ads_objects_hide = ads_objects_hide,
		all_ads_objects = all_ads_objects
	}
end