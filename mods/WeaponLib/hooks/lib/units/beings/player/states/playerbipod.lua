Hooks:PostHook(PlayerBipod, "exit", "weaponlib_playerbipod_exit", function(self, state_data, new_state_name)
	self:_interupt_action_reload()
end)

function PlayerBipod:_check_action_reload(t, input)
	local new_action = nil
	local action_wanted = input.btn_reload_press

	if action_wanted and self._equipped_unit and not self._equipped_unit:base():clip_full() then
		local weapon = self._equipped_unit:base()
		local weapon_tweak_data = weapon:weapon_tweak_data()
		if not (weapon_tweak_data.bipod_reload_allowed or true) then
			self:exit(nil, "standard")
			managers.player:set_player_state("standard")
		end

		self:_start_action_reload_enter(t)

		new_action = true
	end

	return new_action
end