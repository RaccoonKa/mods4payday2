-- WTD Override

local function _var_types_invalid(var1, var2, operator, valid_type_string, valid_types, must_match)
	local var1_type = type(var1)
	local var2_type = type(var2)

	local failed = false

	if not valid_types[var1_type] then
		failed = true
		log("[WeaponLib] [WeaponTweakData Override] WARNING: Tried to perform merge operator '" .. operator .. "' on a [" .. var1_type .. "] tweak data value.")
		log("\t Valid Types are: [" .. valid_type_string .. "]")
	end

	if not valid_types[var2_type] then
		failed = true
		log("[WeaponLib] [WeaponTweakData Override] WARNING: Tried to perform merge operator '" .. operator .. "' with a [" .. var2_type .. "] override value.")
		log("\t Valid Types are: [" .. valid_type_string .. "]")
	end

	if not failed and must_match and (var1_type ~= var2_type) then
		failed = true
		log("[WeaponLib] [WeaponTweakData Override] WARNING: Tried to perform merge operator '" .. operator .. "' with a [" .. var1_type .. "] and a [" .. var2_type .. "]")
	end

	return failed
end

local function none(var1, var2)
	-- Allow falsey overrides.
	if var2 == false then return false end

	return ( var2 or var1 or 0 )
end

local add_valid_type_string = "nil, table, string, number"
local add_valid_types = table.set("nil", "table", "string", "number")
local function add(var1, var2)
	if _var_types_invalid(var1, var2, "add", add_valid_type_string, add_valid_types, false) then return var1 or var2 end

	if (type(var1) == "string") or (type(var2) == "string") then
		return tostring(var1) .. tostring(var2)
	end

	if (type(var1) == "table") then
		return table.insert(var1, var2)
	end

	-- Something has gone awry if var2 is a table and var1 is not. Probably an NPC weapon or something.
	if (type(var2) == "table") then return var1 end

	return (var1 or 0) + (var2 or 0)
end

local multiply_valid_type_string = "nil, number"
local multiply_valid_types = table.set("nil", "number")
local function multiply(var1, var2)
	if _var_types_invalid(var1, var2, "multiply", multiply_valid_type_string, multiply_valid_types, false) then return var1 or var2 end

	return (var1 or 0) * (var2 or 0)
end

local function merge_operator(og_table, new_table, operator)
	og_table = og_table or {}

	if not new_table then
		return og_table
	end

	for i, data in pairs(new_table) do
		if string.sub(tostring(i), 1, 1) ~= "_" then
			i = type(data) == "table" and data.index or i

			if type(data) == "table" and type(og_table[i]) == "table" then
				og_table[i] = merge_operator(og_table[i], data, operator)
			else
				og_table[i] = operator(og_table[i], data)
			end
		end
	end

	return og_table
end

function WeaponFactoryManager:get_weapon_tweak_data_override(weapon_id, factory_id, blueprint)
	if not tweak_data.weapon[weapon_id] then return {} end

	local weapon_tweak_data_override = deep_clone(tweak_data.weapon[weapon_id])

	for index, part_id in ipairs(blueprint) do
		local part_data = managers.weapon_factory:get_part_data_by_part_id_from_weapon(part_id, factory_id, blueprint)
		if part_data.override_weapon then
			weapon_tweak_data_override = merge_operator(weapon_tweak_data_override, part_data.override_weapon, none)
		end
		if part_data.override_weapon_add then
			weapon_tweak_data_override = merge_operator(weapon_tweak_data_override, part_data.override_weapon_add, add)
		end
		if part_data.override_weapon_multiply then
			weapon_tweak_data_override = merge_operator(weapon_tweak_data_override, part_data.override_weapon_multiply, multiply)
		end
	end

	return weapon_tweak_data_override
end

-- Requires
function WeaponFactoryManager:_get_forbidden_parts(factory_id, blueprint)
	local factory = tweak_data.weapon.factory
	local forbidden = {}
	local override = self:_get_override_parts(factory_id, blueprint)

	for _, part_id in ipairs(blueprint) do
		if self:is_part_valid(part_id) then
			local part = self:_part_data(part_id, factory_id, override)

			local filtered_requires = {}

			if part.requires then
				for _, part_id in pairs(part.requires) do
					if table.contains(factory[factory_id].uses_parts, part_id) then
						table.insert(filtered_requires, part_id)
					end
				end
			end

			if part.depends_on or #filtered_requires > 0 then
				local part_forbidden = true

				for _, other_part_id in ipairs(blueprint) do
					local other_part = self:_part_data(other_part_id, factory_id, override)

					if part.depends_on and (part.depends_on == other_part.type) then
						part_forbidden = false

						break
					end

					if #filtered_requires > 0 and table.contains(filtered_requires, other_part_id) then
						part_forbidden = false

						break
					end
				end

				if part_forbidden == false then
					for _, other_part_id in ipairs(blueprint) do
						local other_part = self:_part_data(other_part_id, factory_id, override)

						if other_part.forbids and table.contains( other_part.forbids, part_id ) then part_forbidden = true break end
					end
				end

				if part_forbidden then
					forbidden[part_id] = part.depends_on or filtered_requires	
				end
			end

			if part.forbids then
				for _, forbidden_id in ipairs(part.forbids) do
					forbidden[forbidden_id] = forbidden[forbidden_id] or part_id
				end
			end

			if part.adds then
				local add_forbidden = self:_get_forbidden_parts(factory_id, part.adds)

				for forbidden_id, part_id in pairs(add_forbidden) do
					forbidden[forbidden_id] = forbidden[forbidden_id] or part_id
				end
			end
		end
	end

	return forbidden
end

-- Readd Non-Removable Default Parts
function WeaponFactoryManager:check_for_default_replacement(factory_id, blueprint)
	local factory = tweak_data.weapon.factory

	local default_blueprint = self:get_default_blueprint_by_factory_id(factory_id) or {}
	local forbidden = self:_get_forbidden_parts(factory_id, blueprint) or {}

	-- Generate a list of all types that exist in the blueprint.
	local type_set = {}
	for _, part_id in ipairs(blueprint) do
		local type = factory.parts[part_id].type
		if type then
			type_set[type] = true
		end
	end

	-- Get a list of all the types that should exist by default.
	local default_type_parts = {}
	for _, part_id in ipairs(default_blueprint) do
		local type = factory.parts[part_id].type
		if type then
			default_type_parts[type] = default_type_parts[type] or {}
			table.insert(default_type_parts[type], part_id)
		end
	end

	-- Check for missing default types and then add them.
	for default_type, default_parts in pairs(default_type_parts) do
		if not type_set[default_type] then
			for _, part_id in ipairs(default_parts) do
				table.insert(blueprint, part_id)
			end
		end
	end
end

WeaponFactoryManager._weaponlib_base_change_part_blueprint_only = WeaponFactoryManager.change_part_blueprint_only
function WeaponFactoryManager:change_part_blueprint_only(factory_id, part_id, blueprint, remove_part)
	if remove_part then
		self:check_for_default_replacement(factory_id, blueprint)
	end

	return self:_weaponlib_base_change_part_blueprint_only(factory_id, part_id, blueprint, remove_part)
end

function WeaponFactoryManager:get_stance_mod_scope_part_id(factory_id, blueprint, scope_part_id)
	local factory = tweak_data.weapon.factory
	local assembled_blueprint = self:get_assembled_blueprint(factory_id, blueprint)
	local forbidden = self:_get_forbidden_parts(factory_id, assembled_blueprint)
	local override = self:_get_override_parts(factory_id, assembled_blueprint)
	local part = nil
	local translation = Vector3()
	local rotation = Rotation()

	for _, part_id in ipairs(assembled_blueprint) do
		if not forbidden[part_id] then
			part = self:_part_data(part_id, factory_id, override)

			if part.stance_mod and (part.type ~= "sight" and part.sub_type ~= "second_sight" or part_id == scope_part_id) and part.stance_mod[factory_id] then
				local part_translation = part.stance_mod[factory_id].translation

				if part_translation then
					mvector3.add(translation, part_translation)
				end

				local part_rotation = part.stance_mod[factory_id].rotation

				if part_rotation then
					mrotation.multiply(rotation, part_rotation)
				end
			end
		end
	end

	return {
		translation = translation,
		rotation = rotation
	}
end

--[[
	Fancy caching shite, leave this at the end!!!
]]

local tsort = table.sort
local tconcat = table.concat

function WeaponFactoryManager:_cleanup_blueprint(blueprint)
	local cleaned = {}

	for _, part_id in ipairs(blueprint) do
		if ( part_id ~= nil ) then
			table.insert(cleaned, part_id)
		end
	end

	tsort(cleaned)
	return cleaned
end

function WeaponFactoryManager:_get_cache_key(argument_table, argument_types)
	local clean_table = {}

	for i, arg_type in pairs(argument_types) do
		arg = argument_table[i]

		if arg_type == "blueprint" then
			table.insert(clean_table, "(" .. tconcat(self:_cleanup_blueprint(arg), "-!-") .. ")")
		else
			table.insert(clean_table, tostring(arg))
		end
	end

	return tconcat(clean_table, "-!-")
end

-- Making this stuff super generalised should allow me to cache a load more shit.
WeaponFactoryManager._method_caches = {}

local methods_to_cache = {
	-- String
	get_factory_id_by_weapon_id	= {"string"},
	_indexed_parts = {"string"},
	get_perks_from_part_id = {"string"},

	-- String, Blueprint
	get_assembled_blueprint = {"string", "blueprint"},
	_get_forbidden_parts = {"string", "blueprint"},
	_get_override_parts = {"string", "blueprint"},
	get_custom_stats_from_weapon = {"string", "blueprint"},
	get_ammo_data_from_weapon = {"string", "blueprint"},
	get_part_id_from_weapon_by_type = {"string", "blueprint"},
	is_weapon_unmodded = {"string", "blueprint"},
	blueprint_to_string = {"string", "blueprint"},
	get_perks = {"string", "blueprint"},

	-- String, Blueprint, String
	get_stance_mod_scope_part_id = {"string", "blueprint", "string"},

	-- String, Blueprint, Boolean
	get_stance_mod = {"string", "blueprint", "boolean"},

	-- String, String
	unpack_blueprint_from_string = {"string", "string"},

	-- String, String, Blueprint
	get_parts_from_weapon_by_type_or_perk = {"string", "string", "blueprint"},
	has_perk = {"string", "string", "blueprint"},
	get_perk_stats = {"string", "string", "blueprint"},
	get_sound_switch = {"string", "string", "blueprint"},
	get_weapon_tweak_data_override = {"string", "string", "blueprint"},

	-- String, String, Table Pointer
	_part_data = {"string", "string", "table_pointer"}, -- Using the table pointer here should work most of the time, if it gives me problems I might have to kill it.

	-- String, String, Blueprint, Boolean
	get_replaces_parts = {"string", "string", "blueprint", "boolean"},

	-- Blueprint
	get_duplicate_parts_by_type = {"blueprint"}
}

for function_name, argument_types in pairs(methods_to_cache) do
	WeaponFactoryManager._method_caches[function_name] = {}
	WeaponFactoryManager["_weaponlib_cache_old_" .. function_name] = WeaponFactoryManager["_weaponlib_cache_old_" .. function_name] or WeaponFactoryManager[function_name]

	WeaponFactoryManager[function_name] = function(self, ...)
		local cache_key = self:_get_cache_key({...}, argument_types)

		if self._method_caches[function_name][cache_key] then
			local return_output = self._method_caches[function_name][cache_key]

			-- If we're a table clone us because editing cached data bad.
			if type(return_output) == "table" then
				return_output = deep_clone(return_output)
			end

			return return_output
		end

		local new_output = WeaponFactoryManager["_weaponlib_cache_old_" .. function_name](self, ...)
		self._method_caches[function_name][cache_key] = new_output

		-- If we're a table clone us because editing cached data bad.
		if type(new_output) == "table" then
			new_output = deep_clone(new_output)
		end		

		return new_output
	end
end
