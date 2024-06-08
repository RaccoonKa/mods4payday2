function SimpleCompass:init(panel)
	self._panel = panel:panel({
		layer = 100,
		w = 500,
		h = 50
	})
	
	self._center_x = self._panel:w() / 2
	self._center_y = self._panel:h() / 2

	local indicator = self._panel:rect({
		color = Color.white,
		w = 1,
		h = 5
	})
	
	self._spacing = 35
	self._num = 15
	self._right_shift = 24 * self._spacing
	
	self._panel:set_center(panel:center_x(), panel:top() + 60 + self.settings.HUDOffsetY)
	indicator:set_center_x(self._panel:w() / 2)
	indicator:set_bottom(self._panel:h())
	self._teammate = {}
	self.criminals_num = 0
	
	for i = 0, 23 do
		local compass = self._panel:panel({
			name = "compass" .. tostring(i),
			w = self._spacing,
			h = self._panel:h()
		})
		
		compass:set_center(self._center_x, self._center_y)
		
		if i == 0 then
			self:set_direction_text(compass, "N")
		elseif i == 6 then
			self:set_direction_text(compass, "E")
		elseif i == 12 then
			self:set_direction_text(compass, "S")
		elseif i == 18 then
			self:set_direction_text(compass, "W")
		else
			local rect = compass:rect({
				color = Color.white,
				w = 1,
				h = 4
			})
			
			local text = compass:text({
				vertical = "center",
				valign = "center",
				align = "center",
				halign = "center",
				font = tweak_data.hud_players.ammo_font,
				text = tostring(i*self._num),
				font_size = 10
			})
	
			rect:set_center_x(compass:w() / 2)
			rect:set_top(compass:center_y())
			text:set_center(rect:center_x(), rect:bottom()+10)
		end
	end
end

function SimpleCompass:set_direction_text(panel, text)
	local text_panel = panel:text({
		valign = "center",
		align = "center",
		halign = "center",
		font = tweak_data.hud_players.ammo_font,
		color = Color.yellow,
		text = text,
		font_size = 15
	})
	text_panel:set_center_x(panel:w() / 2)
	text_panel:set_top(panel:h() / 2)
end

function SimpleCompass:update(t, dt)
	local current_camera = managers.viewport:get_current_camera()
	if current_camera then
		local camera = current_camera
		local yaw = camera:rotation():yaw()
		local camera_rot_x = yaw < 0 and yaw or yaw - 360
		
		for i = 0, 23 do
			local pos_x = self._spacing / self._num * camera_rot_x + i * self._spacing + self._center_x
			if pos_x > self._right_shift  - 10 then
				pos_x = pos_x - self._right_shift 
			elseif pos_x < -340 then
				pos_x = pos_x + 340 + self._panel:w()
			end
			
			local left_shift = -math.abs(self._center_x - pos_x)
			local pos_y = (left_shift < -self._spacing*2 and (left_shift + self._spacing*2) / 50 or 0) + self._center_y
			local compass_hud = self._panel:child("compass" .. tostring(i))
			compass_hud:set_center_x(pos_x)
			compass_hud:set_center_y(pos_y)
		end
		
		if self.settings.TeammateVisible then
			for _, data in pairs(self._teammate) do
				local look_at_x = camera_rot_x - Rotation:look_at(camera:position(), data.unit:position(), Vector3(0, 0, 1)):yaw()
				local team_pos_x = self._spacing / self._num * look_at_x + self._center_x
				
				if team_pos_x > self._right_shift - 10 then
					team_pos_x = team_pos_x - self._right_shift
				elseif team_pos_x < -340 then
					team_pos_x = team_pos_x + 340 + self._panel:w()
				end
				
				local left_shift = -math.abs(self._center_x - team_pos_x)
				local team_pos_y = (left_shift < -self._spacing*2 and (left_shift + self._spacing*2) / 50 or 0) + self._center_y
				data.panel:set_center_x(team_pos_x)
				data.panel:set_center_y(team_pos_y)
			end
		end
	end
end

function SimpleCompass:set_teammate_panel_visible(value)
	for _, data in pairs(self._teammate) do
		data.panel:set_visible(value)
	end
end

function SimpleCompass:set_offset_y(value)
	local hud_panel = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2).panel
	self._panel:set_center(hud_panel:center_x(), hud_panel:top() + 60 + value)
end

Hooks:PostHook(HUDManager, "_setup_player_info_hud_pd2","GTFO_Compass_Setup", function(self)
	local hud_script = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
	local panel = hud_script and hud_script.panel
	
	if alive(panel) then
		SimpleCompass:init(panel)
	end
end)

Hooks:PostHook(HUDManager, "update","GTFO_Compass_Update", function(self, t, dt)
	SimpleCompass:update(t, dt)
end)

Hooks:PostHook(HUDManager, "_add_name_label","GTFO_Compass_Set_Name_Color", function(self, data)
	local key = data.unit:key()
	local panel = SimpleCompass._teammate[key] and SimpleCompass._teammate[key].panel
	
	if panel then
		local color_id = managers.criminals:character_color_id_by_unit(data.unit)
		local crim_color = tweak_data.chat_colors[color_id] or tweak_data.chat_colors[#tweak_data.chat_colors]
		panel:child("compass_teammate_rect"):set_color(crim_color)
	end
end)