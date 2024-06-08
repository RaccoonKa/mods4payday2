_G.SimpleCompass = _G.SimpleCompass or {}
SimpleCompass.path = ModPath
SimpleCompass.data_path = SavePath .. "simple_compass.txt"
SimpleCompass.settings = {
	HUDOffsetY = 0,
	TeammateVisible = true
}

function SimpleCompass:Load()
	local file = io.open(self.data_path, "r")
	if file then
		local options = json.decode(file:read("*all"))
		for key, ops in pairs(options) do
			self.settings[key] = ops
		end
		file:close()
	end
end

Hooks:Add("MenuManagerInitialize", "MenuManagerInitialize_SimpleCompass", function(menu_manager)
	MenuCallbackHandler.SimpleCompass_OptionsSave = function(this, item)
		io.save_as_json(SimpleCompass.settings, SimpleCompass.data_path)
	end
	
	MenuCallbackHandler.SimpleCompassSlider_MenuCallback = function(this, item)
		SimpleCompass.settings[item:name()] = item:value()
		
		if SimpleCompass._panel then
			SimpleCompass:set_offset_y(item:value())
		end
	end
	
	MenuCallbackHandler.SimpleCompassCheckbox_MenuCallback = function(this, item)
		local name = item:name()
		local value = item:value() == "on"
		
		SimpleCompass.settings[name] = value
		
		if SimpleCompass._panel then
			if name == "TeammateVisible" then
				SimpleCompass:set_teammate_panel_visible(value)
			end
		end
	end
	
	SimpleCompass:Load()
	MenuHelper:LoadFromJsonFile(SimpleCompass.path .. "menu/options.txt", SimpleCompass, SimpleCompass.settings)
end)

