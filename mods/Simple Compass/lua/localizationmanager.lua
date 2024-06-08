local mpath = ModPath

Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_SimpleCompass", function(loc)
	local lang, path = SystemInfo and SystemInfo:language(), "loc/english.txt"
	loc:load_localization_file(mpath .. path)
end)