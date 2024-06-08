FPCameraPlayerBase._weaponlib_base_play_sound = FPCameraPlayerBase.play_sound
function FPCameraPlayerBase:play_sound(unit, event)
	if alive(self._parent_unit) then
		local weapon = self._parent_unit:inventory():equipped_unit()

		if weapon then
			local weapon_tweak_data = weapon:base():weapon_tweak_data()

			if weapon_tweak_data.sounds and ( weapon_tweak_data.sounds.replacements or weapon_tweak_data.sounds.reload ) then
				local sound_replacements = weapon_tweak_data.sounds.replacements or weapon_tweak_data.sounds.reload
				event = sound_replacements[event] or event
			end
		end
	end

	self:_weaponlib_base_play_sound(unit, event)
end

Hooks:PostHook(FPCameraPlayerBase, "init", "weaponlib_fpcameraplayerbase_init", function(self, unit)
	self:_set_scope_index(0)

	self._workspace = managers.hud:workspace("workspace")
	self._panel = self._workspace:panel():child("scope_overlay_panel") or self._workspace:panel():panel({
		name = "scope_overlay_panel",
		layer = -10
	})
	self._scope_bitmap = self._panel:bitmap({
		name = "scope_bitmap",
		visible = true,
		valign = "center",
		layer = 0,
		color = Color.white
	})

	self._top_black = self._panel:rect({
		name = "top_black",
		visible = true,
		valign = "center",
		layer = 0,
		color = Color.black
	})
	self._right_black = self._panel:rect({
		name = "right_black",
		visible = true,
		valign = "center",
		layer = 0,
		color = Color.black
	})
	self._bottom_black = self._panel:rect({
		name = "bottom_black",
		visible = true,
		valign = "center",
		layer = 0,
		color = Color.black
	})
	self._left_black = self._panel:rect({
		name = "left_black",
		visible = true,
		valign = "center",
		layer = 0,
		color = Color.black
	})

	self._panel:set_visible(false)

	self._resolution_changed_callback = callback(self, self, "resolution_changed")
	managers.viewport:add_resolution_changed_func(self._resolution_changed_callback)
end)

local scope_effect_ids = Idstring("scope_effect_post")
local color_off_ids = Idstring("color_off")
function FPCameraPlayerBase:_set_scope_index(scope_index)
	local last_scope_index = self._current_scope_index
	self._current_scope_index = scope_index

	if not (self._parent_unit) then return end
	if not (self._parent_unit.inventory and self._parent_unit:inventory()) then return end
	if not (self._parent_unit:inventory().equipped_unit and self._parent_unit:inventory():equipped_unit()) then return end

	local equipped_weapon = self._parent_unit:inventory():equipped_unit()
	local weapon_base = equipped_weapon:base()

	if not weapon_base then return end

	weapon_base:set_visual_scope_index(scope_index)
	weapon_base:update_visibility_state()

	if scope_index == 0 then
		self._unit:set_visible(true)
		for unit_id, unit_entry in pairs(self._unit:spawn_manager():spawned_units()) do
			if alive(unit_entry.unit) then
				unit_entry.unit:set_visible(true)
			end
		end

		self._parent_unit:camera():viewport():vp():set_post_processor_effect("World", scope_effect_ids, color_off_ids)
	else
		local visible = weapon_base:get_scope_steelsight_weapon_visible(scope_index)
		self._unit:set_visible(visible)
		for unit_id, unit_entry in pairs(self._unit:spawn_manager():spawned_units()) do
			if alive(unit_entry.unit) then
				unit_entry.unit:set_visible(visible)
			end
		end

		local scope_overlay = weapon_base:get_scope_overlay(scope_index)
		local scope_overlay_border_color = weapon_base:get_scope_overlay_border_color(scope_index)
		if scope_overlay and scope_overlay_border_color then
			self._scope_bitmap:set_image(scope_overlay)

			local scope_width = self._scope_bitmap:texture_width()
			local scope_height = self._scope_bitmap:texture_height()
			local scope_aspect_ratio = scope_width/scope_height

			local width = self._panel:w()
			local height = self._panel:h()
			local aspect_ratio = width/height

			if aspect_ratio < scope_aspect_ratio then
				scope_width = width
				scope_height = width / scope_aspect_ratio
			else
				scope_height = height
				scope_width = height * scope_aspect_ratio
			end

			self._scope_bitmap:set_size(scope_width, scope_height)
			self._scope_bitmap:set_center(width/2, height/2)

			local vertical_bar_height = (height - scope_height)/2
			local horizontal_bar_width = (width - scope_width)/2

			self._top_black:set_size(width,vertical_bar_height)
			self._top_black:set_lefttop(0, 0)
			self._top_black:set_color(scope_overlay_border_color)

			self._right_black:set_size(horizontal_bar_width, height)
			self._right_black:set_rightbottom(width, height)
			self._right_black:set_color(scope_overlay_border_color)

			self._bottom_black:set_size(width, vertical_bar_height)
			self._bottom_black:set_rightbottom(width, height)
			self._bottom_black:set_color(scope_overlay_border_color)

			self._left_black:set_size(horizontal_bar_width, height)
			self._left_black:set_lefttop(0, 0)
			self._left_black:set_color(scope_overlay_border_color)
		end

		self._parent_unit:camera():viewport():vp():set_post_processor_effect("World", scope_effect_ids, Idstring(weapon_base:get_scope_effect(scope_index)))
	end
end

function FPCameraPlayerBase:resolution_changed()
	self._panel:set_size(self._workspace:width(), self._workspace:height())

	self:_set_scope_index(self._current_scope_index)
end

Hooks:PreHook(FPCameraPlayerBase, "_update_stance", "weaponlib_fpcameraplayerbase_update_stance", function(self, t, dt)
	if self._workspace then
		if self._last_workspace_width ~= self._workspace:width() or self._last_workspace_height ~= self._workspace:height() then
			self:resolution_changed()

			self._last_workspace_width = self._workspace:width()
			self._last_workspace_height = self._workspace:height()
		end
	end

	if not (self._parent_unit) then return end
	if not (self._parent_unit.inventory and self._parent_unit:inventory()) then return end
	if not (self._parent_unit:inventory().equipped_unit and self._parent_unit:inventory():equipped_unit()) then return end

	local equipped_weapon = self._parent_unit:inventory():equipped_unit()
	local weapon_base = equipped_weapon:base()

	local in_steelsight = self._parent_movement_ext._current_state:in_steelsight()

	local last_scope_index = self._current_scope_index
	local new_scope_index = 0

	if in_steelsight then
		new_scope_index = weapon_base:is_second_sight_on() and 2 or 1
	end

	local scope_changed = last_scope_index ~= new_scope_index

	if scope_changed and self._shoulder_stance.transition then
		local trans_data = self._shoulder_stance.transition
		local elapsed_t = t - trans_data.start_t

		if trans_data.duration < elapsed_t then
			self:_set_scope_index(new_scope_index)
		else
			local progress_smooth = elapsed_t / trans_data.duration

			if last_scope_index == 0 and progress_smooth >= trans_data.steelsight_swap_progress_trigger then
				self:_set_scope_index(new_scope_index)
			elseif last_scope_index ~= 0 and progress_smooth >= (1 - trans_data.steelsight_swap_progress_trigger) then
				self:_set_scope_index(0)
			end
		end
	end

	if last_scope_index == 0 or self._parent_unit:camera():viewport() ~= managers.viewport:first_active_viewport() then
		self._panel:set_visible(false)
	elseif last_scope_index ~= 0 and weapon_base:get_scope_overlay(last_scope_index) then
		self._panel:set_visible(true)
	end
end)

Hooks:PostHook(FPCameraPlayerBase, "destroy", "weaponlib_fpcameraplayerbase_destroy", function(self, unit)
	managers.viewport:remove_resolution_changed_func(self._resolution_changed_callback)

	self:_set_scope_index(0)
	self._panel:set_visible(false)
end)

function FPCameraPlayerBase:anim_clbk_stop_weapon_jam()
	if alive(self._parent_unit) then
		local weapon = self._parent_unit:inventory():equipped_unit()

		if alive(weapon) then
			weapon:base():tweak_data_anim_stop("jam")
		end
	end
end

Hooks:PostHook(FPCameraPlayerBase, "play_redirect", "weaponlib_fpcameraplayerbase_play_redirect", function(self, redirect_name, speed, offset_time)
	if alive(self._parent_unit) then
		local weapon = self._parent_unit:inventory():equipped_unit()

		if alive(weapon) then
			weapon:base():arm_redirect_passthrough(redirect_name, speed)
		end
	end
end)