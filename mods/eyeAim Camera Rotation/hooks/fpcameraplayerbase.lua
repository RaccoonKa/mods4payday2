if not EYE_AIM_MODDED then return end
if not EYE_AIM_MODDED_ANIMATION_FILES then return end

local math_cos = math.cos
local math_sin = math.sin
local math_acos = math.acos

local mrot_set_zero = mrotation.set_zero
local mrot_multiply = mrotation.multiply
local mrot_invert = mrotation.invert
local mrot_slerp = mrotation.slerp
local mrot_rotation_difference = mrotation.rotation_difference
local function mrot_set(rotation, set)
	mrot_set_zero(rotation)
	mrot_multiply(rotation, set)
end

-- Pre-Process Animation XML to check if using vanilla or modded anims.
	local modded_animation_ids = {}

	local animation_subset_file = DB:open("animation_subset", Idstring("anims/fps/fps_spawn"))
	local animation_subset_xml = animation_subset_file:read()
	local animation_subset_data = ScriptSerializer:from_custom_xml(animation_subset_xml)

	for _, anim_data in ipairs(animation_subset_data) do
		if anim_data._meta == "anim" and anim_data.name and anim_data.file and EYE_AIM_MODDED_ANIMATION_FILES[tostring(Idstring(anim_data.file))] then
			modded_animation_ids[anim_data.name] = true
		end
	end

	local global_values = {}

	local animation_state_machine_file = DB:open("animation_state_machine", Idstring("anims/fps/fps"))
	local animation_state_machine_xml = animation_state_machine_file:read()
	local animation_state_machine_data = ScriptSerializer:from_custom_xml(animation_state_machine_xml)

	for _, global_data in ipairs(animation_state_machine_data) do
		if global_data._meta == "global" and global_data.name then
			table.insert(global_values, global_data.name)
		end
	end

	local modded_states = {}
	local modded_state_weights = {}
	local modded_state_globals = {}
	local modded_state_parameters = {}

	local animation_states_file = DB:open("animation_states", Idstring("anims/fps/fps_spawn"))
	local animation_states_xml = animation_states_file:read()
	local animation_states_data = ScriptSerializer:from_custom_xml(animation_states_xml)

	local function run_mini_language(minilang, variables)
		variables = clone(variables)

		table.insert(variables, {"||", " or "})
		table.insert(variables, {"&&", " and "})

		table.insert(variables, {"!=", "~="})
		table.insert(variables, {"!", "not "})

		table.insert(variables, {"sin", "math.sin"})
		table.insert(variables, {"cos", "math.cos"})
		table.insert(variables, {"abs", "math.abs"})

		table.insert(variables, {"rnd", "math.random"})

		table.insert(variables, {"clamp", "math.clamp"})

		table.sort(variables, function(a,b)
			return #a[1] > #b[1]
		end)

		for _, variable_data in ipairs(variables) do
			minilang = string.gsub(minilang, variable_data[1], variable_data[2])
		end

		minilang = string.gsub(minilang, "pi", "3.14159265")

		return loadstring("return " .. minilang)()
	end

	local function extract_variables_from_mini_language(minilang, parameter_names)
		local variables = {}

		local variable_names = {}
		for _, global_value in pairs(global_values) do
			table.insert(variable_names, {global_value, true})
		end
		for _, parameter_name in pairs(parameter_names or {}) do
			table.insert(variable_names, {parameter_name, false})
		end

		table.sort(variable_names, function(a,b)
			return #a[1] > #b[1]
		end)

		for _, variable_name in ipairs(variable_names) do
			if string.find(minilang, variable_name[1]) then
				string.gsub(minilang, variable_name[1], " ")
				table.insert(variables, {variable_name[1], variable_name[2]})
			end
		end

		return variables
	end

	for _, state_data in ipairs(animation_states_data) do
		if state_data._meta == "state" and state_data.type and state_data.name then
			local mix_state = state_data.type == "mix" or state_data.type == "mixloop"

			local parameter_names = {}
			for _, param_data in ipairs(state_data) do
				if param_data._meta == "param" and param_data.name  then
					table.insert(parameter_names, param_data.name)
				end
			end

			for _, anim_data in ipairs(state_data) do
				if anim_data._meta == "anim" and anim_data.name and modded_animation_ids[anim_data.name] then
					local name_ids_string = tostring(Idstring(state_data.name))
					modded_states[name_ids_string] = true

					if mix_state and anim_data.weight then
						modded_state_weights[name_ids_string] = modded_state_weights[name_ids_string] or {}
						modded_state_weights[name_ids_string][anim_data.name] = anim_data.weight

						modded_state_globals[name_ids_string] = modded_state_globals[name_ids_string] or {}
						modded_state_parameters[name_ids_string] = modded_state_parameters[name_ids_string] or {}
						for _, variable_info in pairs(extract_variables_from_mini_language(anim_data.weight, parameter_names)) do
							if variable_info[2] then
								modded_state_globals[name_ids_string][variable_info[1]] = true
							else
								modded_state_parameters[name_ids_string][variable_info[1]] = true
							end
						end
					end
				end
			end
		end
	end

Hooks:PostHook(FPCameraPlayerBase, "init", "eyeAimFPCameraPlayerBaseInit", function(self, unit)
	self._eyeaim_object = self._unit:get_object(Idstring("eyeAim"))
end)

local function get_rotation_angle(rot)
	local yaw = rot:yaw()
	local pitch = rot:pitch()
	local roll = rot:roll()

	local cos_yaw = math_cos(yaw/2)
	local sin_yaw = math_sin(yaw/2)

	local cos_pitch = math_cos(pitch/2)
	local sin_pitch = math_sin(pitch/2)

	local cos_roll = math_cos(roll/2)
	local sin_roll = math_sin(roll/2)

	return 2 * math_acos((cos_yaw*cos_pitch*cos_roll) - (sin_yaw*sin_pitch*sin_roll))
end

local temp_delta_rot = Rotation()
local function rotate_towards(rotation, from, to, max_degrees_delta)
	mrot_rotation_difference(temp_delta_rot, from, to)
	local angle = get_rotation_angle(temp_delta_rot)

	if angle == 0 then
		mrot_set(rotation, to)
		return
	end

	mrot_slerp(rotation, from, to, math.min(1, max_degrees_delta / angle))

	return 
end

local state_blend_time = 0.2

local inverted_shoulder_rotation = Rotation()
local rotation_difference = Rotation()

local previous_eyeaim_rotation = Rotation()
local current_eyeaim_rotation = Rotation()
local target_eyeaim_rotation = Rotation()

-- Easing function defined as such easing(a, b, t)
local easing_function = Easing.inout_quad

Hooks:PostHook(FPCameraPlayerBase, "update", "eyeAimFPCameraPlayerBaseUpdate", function(self, unit, t, dt)
	local anim_state_machine = self._unit:anim_state_machine()
	local current_state = anim_state_machine:segment_state(Idstring("base"))
	local current_state_ids_string = tostring(current_state)

	local state_changed = current_state_ids_string ~= self._previous_state_ids_string
	if state_changed then
		self._previous_state_ids_string = current_state_ids_string

		mrot_set(previous_eyeaim_rotation, current_eyeaim_rotation)
		self._blend_to_next_state_start_t = t
	end

	mrot_set_zero(rotation_difference)
	if modded_states[current_state_ids_string] then
		local using_modded_anim = false

		if modded_state_weights[current_state_ids_string] then
			local minilang_variables = {}

			for global_value, _ in pairs(modded_state_globals[current_state_ids_string]) do
				table.insert(minilang_variables, {global_value, anim_state_machine:get_global(global_value)})
			end

			for parameter_name, _ in pairs(modded_state_parameters[current_state_ids_string]) do
				table.insert(minilang_variables, {parameter_name, anim_state_machine:get_parameter(current_state, parameter_name)})
			end

			for anim_id, weight_minilang in pairs(modded_state_weights[current_state_ids_string]) do
				local evaluated_weight = run_mini_language(weight_minilang, minilang_variables)

				if evaluated_weight > 0 then
					using_modded_anim = true
					break
				end
			end
		else
			using_modded_anim = true
		end

		if using_modded_anim then
			local multiplier = 1
			if eyeAimCameraRotation and eyeAimCameraRotation.Options then
				multiplier = eyeAimCameraRotation.Options:GetValue("ECRMultiplier")
			end

			local reference_object = self._unit:orientation_object()
			mrot_slerp(rotation_difference, rotation_difference, reference_object:to_local(self._eyeaim_object:rotation()), multiplier)
		end
	end

	mrot_set(inverted_shoulder_rotation, self._shoulder_stance.rotation)
	mrot_invert(inverted_shoulder_rotation)

	mrot_set(target_eyeaim_rotation, self._shoulder_stance.rotation)
	mrot_multiply(target_eyeaim_rotation, rotation_difference)
	mrot_multiply(target_eyeaim_rotation, inverted_shoulder_rotation)

	if self._blend_to_next_state_start_t then
		local interpolation_value = (t - self._blend_to_next_state_start_t) / state_blend_time
		local eased_interpolation_value = easing_function(0, 1, interpolation_value) -- Probably overly expensive but it shouldn't be too bad, and I'm lazy.

		mrot_slerp(current_eyeaim_rotation, previous_eyeaim_rotation, target_eyeaim_rotation, eased_interpolation_value)

		if interpolation_value >= 1 then
			self._blend_to_next_state_start_t = nil
		end
	else
		mrot_set(current_eyeaim_rotation, target_eyeaim_rotation)
	end

	self._parent_unit:camera():set_eyeaim_rotation(current_eyeaim_rotation)
end)