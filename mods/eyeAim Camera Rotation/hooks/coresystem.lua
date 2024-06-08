EYE_AIM_MODDED_ANIMATION_FILES = {}
EYE_AIM_MODDED = false

local function add_modded_animation_file(path)
	EYE_AIM_MODDED_ANIMATION_FILES[tostring(path)] = true
	EYE_AIM_MODDED = true
end

local ids_animation = Idstring("animation")
Hooks:PostHook(BLTAssetManager, "CreateEntry", "eyeAimGrabModdedAnimations", function(self, path, ext, file, options)
	if ext == ids_animation then
		add_modded_animation_file(path)
	end
end)

for _, mod_data in pairs(DB:mods()) do
	for _, file in ipairs(mod_data.files or {}) do
		if string.sub(file, -9) == "animation" then
			local path = Idstring(string.sub(file, 1, -11))
			add_modded_animation_file(path)
		end
	end
end