local sc = SimpleCompass

Hooks:PostHook(GroupAIStateBase, "register_criminal","GTFO_Compass_Teammate_Panel_Setup", function(self, unit)
	if unit:base().is_local_player then
		return
	end
	
	local key = unit:key()
	sc._teammate[key] = {
		unit = unit,
		panel = sc._panel:panel({
			visible = sc.settings.TeammateVisible,
			w = sc._spacing,
			h = sc._panel:h()
		})
	}
	
	local teammate_panel = sc._teammate[key].panel
	teammate_panel:set_center(sc._center_x, sc._center_y)
	
	local teammate_rect = teammate_panel:rect({
		name = "compass_teammate_rect",
		w = 2,
		h = 5
	})
	
	teammate_rect:set_center_x(teammate_panel:w() / 2)
	teammate_rect:set_bottom(teammate_panel:center_y())
end)

Hooks:PostHook(GroupAIStateBase, "unregister_criminal","GTFO_Compass_Teammate_Panel_Unsetup", function(self, unit)
	if unit:base().is_local_player then
		return
	end
	
	local key = unit:key()
	local hud_panel = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2).panel
	local data = sc._teammate[key]
	
	data.panel:set_visible(false)
	hud_panel:remove(data.panel)
	sc._teammate[key] = nil
end)