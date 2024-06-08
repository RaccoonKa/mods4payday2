if Holo:ShouldModify("Menu", "BlackScreen") then
	Holo:Post(HUDBlackScreen, "init", function(self, hud)
		self:HoloInit()
	end)
	function HUDBlackScreen:HoloInit()
		self._blackscreen_panel:rect({
			name = "bg",
			color = Holo:GetColor("Colors/Menu"),
			visible = Holo.Options:GetValue("ColoredBackground"),
			layer = -1,
		})
	    self._skip_circle._circle:hide()
	    self._progress = self._blackscreen_panel:rect({
	        name = "line",
			color = Holo:GetColor("Colors/Marker"),
	        h = 2,
	    })
	end
	Holo:Post(HUDBlackScreen, "set_loading_text_status", function(self, status)
		if status then
			if not alive(self._progress) then
				if alive(self._blackscreen_panel) then
					self:HoloInit()
				else
					return 
				end
			end
			local loading_text = self._blackscreen_panel:child("loading_text")
			local skip_text = self._blackscreen_panel:child("skip_text")
			managers.hud:make_fine_text(skip_text)
			managers.hud:make_fine_text(loading_text)
			local w = (skip_text:visible() and skip_text:w() or loading_text:w()) + 8
			if status == "wait_for_peers" then
				local _, peer_status = managers.network:session():peer_streaming_status()
	            self._progress:set_w(w * (peer_status / 100))
			elseif type(tonumber(status)) == "number" then
				self._progress:set_w(w * (tonumber(status) / 100))
			else
				self._progress:set_w(w)
			end
			self._progress:set_rightbottom(self._blackscreen_panel:w()- 4, self._blackscreen_panel:h() - 4)
			local x,y = self._progress:right() - 4, self._progress:bottom() - 4
			skip_text:set_rightbottom(x,y)
			loading_text:set_rightbottom(x,y)
		end
	end)
	function HUDBlackScreen:skip_circle_done()
		local bottom = self._progress:bottom()		
		local speed = 4
		play_anim(self._blackscreen_panel:child("loading_text"), {set = {y = bottom, h = 0}})
		play_anim(self._blackscreen_panel:child("skip_text"), {set = {y = bottom, h = 0}, callback = function()
			play_value(self._progress, "w", 0)
		end})
	end
end