--[[
	Custom Attachment Points: Legacy, Internal Stuff
]]

-- Save the original function as a backup.
WeaponFactoryManager._weaponlib__spawn_and_link_unit = WeaponFactoryManager._weaponlib__spawn_and_link_unit or WeaponFactoryManager._spawn_and_link_unit

-- Storage for stuff!
local last_name_id = ""
local temp_custom_attachment_points = {}

function WeaponFactoryManager:_spawn_and_link_unit( u_name, a_obj, third_person, link_to_unit )
	if ( link_to_unit and link_to_unit:base() and link_to_unit:base().weapon_tweak_data and link_to_unit:base()._name_id ) then
		local name_id = link_to_unit:base()._name_id
		local weapon_tweakdata = link_to_unit:base():weapon_tweak_data()

		-- Save the attachment point stuff and remember the last name id because for some reason the tweakdata or name_id doesn't always show up.
		if ( name_id ) then
			last_name_id = name_id
		end

		if ( weapon_tweakdata and weapon_tweakdata.attachment_points ) then
			temp_custom_attachment_points[name_id] = weapon_tweakdata.attachment_points
		end
	end

	if ( last_name_id and temp_custom_attachment_points[last_name_id] ) then
		for index, attach_point in ipairs( temp_custom_attachment_points[last_name_id] ) do
			-- Store values in shorter variables. ( I'm lazy. ) Also, sorts out the defaults.
			local a_name = attach_point.name or nil
			local a_base_a_obj = attach_point.base_a_obj or nil
			local a_position = attach_point.position or Vector3( 0, 0, 0 )
			local a_rotation = attach_point.rotation or Rotation( 0, 0, 0 )

			local a_part_attach_data = attach_point.part_attach_data or nil

			-- Check if the current 'attach_point' matches the one we are trying to attach to.
			if (a_name) then
				if ( Idstring( a_name ) == a_obj ) then
					-- Yes, this is the point we are looking for so spawn the unit!
					local unit = World:spawn_unit( u_name, Vector3(), Rotation() )

					-- If we are attaching to a part don't bother. We will deal with this later!
					if a_part_attach_data then
						-- Store any attachment data on the weapon for later use!
						link_to_unit:base().part_attach_data = link_to_unit:base().part_attach_data or {}
						link_to_unit:base().part_attach_data[a_name] = a_part_attach_data
						link_to_unit:base().part_attach_data[a_name].position = a_position
						link_to_unit:base().part_attach_data[a_name].rotation = a_rotation
						link_to_unit:base().part_attach_data[a_name].base_a_obj = a_base_a_obj

						-- Some occlusion code which exists in the original so probably a good idea to include it again!
						if managers.occlusion and not third_person then
							managers.occlusion:remove_occlusion(unit)
						end

						return unit
					end

					if (a_base_a_obj) then
						-- Get the attachment_object for the position and rotation.
						local base_a_obj = Idstring( a_base_a_obj )
						local attachment_object = link_to_unit:get_object( base_a_obj )

						if attachment_object then
							-- Get the original position and rotation!
							local base_attachment_position = attachment_object:position() or Vector3(0,0,0)
							local base_attachment_rotation = attachment_object:rotation() or Rotation(0,0,0)

							-- Link the object to the gun!
							local res = link_to_unit:link(base_a_obj, unit, unit:orientation_object():name())

							-- Calculate the new position and rotation! ( With some defaults just in case. )
							local new_position = ( base_attachment_position + a_position ) or Vector3(0,0,0)
							local new_rotation = Rotation(
								(base_attachment_rotation:yaw() + a_rotation:yaw() ) % 360,
								(base_attachment_rotation:pitch() + a_rotation:pitch() ) % 360,
								(base_attachment_rotation:roll() + a_rotation:roll() ) % 360
							) or Rotation(0,0,0)

							-- Set the new position and rotation!
							unit:set_position( new_position )
							unit:set_rotation( new_rotation )

							-- Some occlusion code which exists in the original so probably a good idea to include it again!
							if managers.occlusion and not third_person then
								managers.occlusion:remove_occlusion(unit)
							end

							return unit
						else
							log( "[WeaponLib] [Custom Attachment Points (Legacy)] WARNING: Base Not Found on Weapon - " .. last_name_id .. " - " .. a_name )
						end
					else
						log( "[WeaponLib] [Custom Attachment Points (Legacy)] WARNING: Missing Base - " .. last_name_id .. " - " .. a_name )
					end
				end
			else
				log( "[WeaponLib] [Custom Attachment Points (Legacy)] WARNING: Missing Name - " .. last_name_id )
			end
		end
	end

	-- If all else fails do the original function!
	return self:_weaponlib__spawn_and_link_unit( u_name, a_obj, third_person, link_to_unit )
end
