-- This isn't on the menu one for some reason.
function NewRaycastWeaponBase:weapon_tweak_data()
	return tweak_data.weapon[self._name_id] or tweak_data.weapon.amcar
end

function NewRaycastWeaponBase:_legacy_weaponlib_part_attachment_stuff()
	local parts_tweak = tweak_data.weapon.factory.parts

	-- We need these to do anything no point in continuing if we don't have either of them.
	if (not parts_tweak) then return end
	if (not self.part_attach_data) then return end

	for part_id, part in pairs(self._parts) do
		-- Unlikely to not exist but better to be safe!
		if part.unit then
			-- Get our parts attachment object and check if it exists. We need this as well so we stop if we don't have it.
			local part_a_obj = parts_tweak[part_id] and managers.weapon_factory:get_part_data_by_part_id_from_weapon(part_id, self._factory_id, self._blueprint).a_obj
			if part_a_obj then
				-- Get attachment data relevant to that attachment point. If it doesn't exist we don't bother continuing.
				local part_attachment_data = self.part_attach_data[part_a_obj]
				if part_attachment_data then
					local attach_parts = part_attachment_data[1] -- First part of data is a list of weapon parts which we attach to.
					local attach_obj = part_attachment_data[2] -- Second is a string of the object on the weapon_part we want to attach to.

					-- Find the first part from attach_parts. If it's not on here don't bother!
					local attach_part = nil
					local attach_part_id = nil
					for index, part_id in ipairs(attach_parts) do
						if (self._parts[part_id] and self._parts[part_id].unit) then
							attach_part = self._parts[part_id].unit
							attach_part_id = part_id
							break
						end
					end

					if attach_part then
						local a_obj = Idstring(attach_obj)
						local attachment_object = attach_part:get_object(a_obj)

						local base_attachment_position = Vector3(0,0,0)
						local base_attachment_rotation = Rotation(0,0,0)

						--Not gonna lie I don't really know why this works.
						local base_a_obj = part_attachment_data.base_a_obj
						if base_a_obj then
							local base_a_obj_idstring = Idstring(base_a_obj)
							local base_a_obj_object = self._unit:get_object(base_a_obj_idstring)

							if base_a_obj_object then
								local cap_offset_check = self:_legacy_weaponlib_check_cap_offset(attach_part_id)

								local base_a_obj_position = base_a_obj_object:local_position() or Vector3(0,0,0)
								base_attachment_position = base_a_obj_position - cap_offset_check.position

								local base_a_obj_rotation = base_a_obj_object:local_rotation() or Vector3(0,0,0)
								base_attachment_rotation = Rotation(
									base_a_obj_rotation:yaw() - cap_offset_check.rotation:yaw(),
									base_a_obj_rotation:pitch() - cap_offset_check.rotation:pitch(),
									base_a_obj_rotation:roll() - cap_offset_check.rotation:roll()
								)
							else
								log( "Custom Attachment Points Error: Base Not Found on Weapon" )
							end
						end

						local offset_position = part_attachment_data.position
						local offset_rotation = part_attachment_data.rotation

						-- Link the object to the part!
						local res = attach_part:link(a_obj, part.unit, part.unit:orientation_object():name())

						-- Calculate the new position and rotation! ( With some defaults just in case. )
						local new_position = ( base_attachment_position + offset_position ) or Vector3(0,0,0)
						local new_rotation = Rotation(
							base_attachment_rotation:yaw() + offset_rotation:yaw(),
							base_attachment_rotation:pitch() + offset_rotation:pitch(),
							base_attachment_rotation:roll() + offset_rotation:roll()
						) or Rotation(0,0,0)

						-- Set the new position and rotation!
						part.unit:set_position(new_position)
						part.unit:set_rotation(new_rotation)
					end
				end
			end
		end
	end
end

-- Shit to sort of fix when the part your attaching to has been CAP edited aswell.
function NewRaycastWeaponBase:_legacy_weaponlib_check_cap_offset(part_id)
	local position_offset = Vector3(0,0,0)
	local rotation_offset = RotationCAP(0,0,0)

	local parts_tweak = tweak_data.weapon.factory.parts

	if parts_tweak then
		local part_a_obj_name = parts_tweak[part_id] and managers.weapon_factory:get_part_data_by_part_id_from_weapon(part_id, self._factory_id, self._blueprint).a_obj
		
		if part_a_obj_name then
			local part_a_obj = self._unit:get_object(Idstring(part_a_obj_name))
			
			if part_a_obj then
				position_offset = position_offset + part_a_obj:local_position()
				rotation_offset = RotationCAP(
					rotation_offset:yaw() + part_a_obj:local_rotation():yaw(),
					rotation_offset:pitch() + part_a_obj:local_rotation():pitch(),
					rotation_offset:roll() + part_a_obj:local_rotation():roll()
				)
			end

			local weapons_tweak = tweak_data.weapon

			if weapons_tweak then
				local weapon_tweak_data = weapons_tweak[self._name_id]

				if weapon_tweak_data then
					local attachment_points = weapon_tweak_data.attachment_points

					if attachment_points then
						for index, value in ipairs(attachment_points) do
							if (value.name) and (value.name == part_a_obj_name) then
								position_offset = position_offset + (value.position or Vector3(0,0,0))
								rotation_offset = RotationCAP(
									rotation_offset:yaw() + (value.rotation and value.rotation:yaw() or 0),
									rotation_offset:pitch() + (value.rotation and value.rotation:pitch() or 0),
									rotation_offset:roll() + (value.rotation and value.rotation:roll() or 0)
								)
							end
						end
					end
				end
			end
		end
	end

	return {
		position = position_offset,
		rotation = rotation_offset
	}
end

Hooks:PostHook(NewRaycastWeaponBase, "_assemble_completed", "weaponlib_legacy_newraycastweaponbase_assemble_completed", function( self )
	self:_legacy_weaponlib_part_attachment_stuff()
end)
