-- Ammo Usage & Jamming
	function RaycastWeaponBase:jam_chance(is_not_empty)
		local w_td = self:weapon_tweak_data()
		local chance_not_empty = w_td.jam_chance and w_td.jam_chance.not_empty or 0.0
		local chance_empty = w_td.jam_chance and w_td.jam_chance.empty or 0.0

		return is_not_empty and chance_not_empty or chance_empty
	end

	function RaycastWeaponBase:unjam_expire_t()
		local w_td = self:weapon_tweak_data()

		return w_td.timers and w_td.timers.unjam or 1.0
	end

	function RaycastWeaponBase:set_jammed(state)
		self._jammed = state
	end

	function RaycastWeaponBase:jammed()
		return not not self._jammed
	end

	function RaycastWeaponBase:unjam_name_id()
		local initial_td = self:weapon_tweak_data()
		if initial_td.animations and initial_td.animations.unjam_name_id then
			return initial_td.animations.unjam_name_id
		end

		return self._name_id
	end

	function RaycastWeaponBase:out_of_ammo()
		return self._jammed or self:ammo_base():get_ammo_total() == 0
	end

	Hooks:PostHook(RaycastWeaponBase, "on_enabled", "weaponlib_raycastweaponbase_on_enabled", function(self, ...)
		if self:jammed() then
			self:tweak_data_anim_play_at_end("jam")
		end
	end)

	function RaycastWeaponBase:fire(from_pos, direction, dmg_mul, shoot_player, spread_mul, autohit_mul, suppr_mul, target_unit)
		-- Functionality:
		if managers.player:has_activate_temporary_upgrade("temporary", "no_ammo_cost_buff") then
			managers.player:deactivate_temporary_upgrade("temporary", "no_ammo_cost_buff")

			if managers.player:has_category_upgrade("temporary", "no_ammo_cost") then
				managers.player:activate_temporary_upgrade("temporary", "no_ammo_cost")
			end
		end

		local w_td = self:weapon_tweak_data()

		if self._bullets_fired then
			if self._bullets_fired == 1 and w_td.sounds.fire_single then
				self:play_tweak_data_sound("stop_fire")
				self:play_tweak_data_sound("fire_auto", "fire")
			end

			self._bullets_fired = self._bullets_fired + 1
		end

		local user_unit = self._setup.user_unit
		local is_player = user_unit == managers.player:player_unit()
		local consume_ammo = not managers.player:has_active_temporary_property("bullet_storm") and (not managers.player:has_activate_temporary_upgrade("temporary", "berserker_damage_multiplier") or not managers.player:has_category_upgrade("player", "berserker_no_ammo_cost")) or not is_player
		
		local ammo_usage = self:ammo_usage()
		local base = self:ammo_base()

		local ammo_in_clip = base:get_ammo_remaining_in_clip()

		local is_empty = false
		if consume_ammo and (is_player or Network:is_server()) then
			if ammo_in_clip == 0 then
				return
			end

			if is_player then
				for _, category in ipairs(self:weapon_tweak_data().categories) do
					if managers.player:has_category_upgrade(category, "consume_no_ammo_chance") then
						local roll = math.rand(1)
						local chance = managers.player:upgrade_value(category, "consume_no_ammo_chance", 0)

						if roll < chance then
							ammo_usage = 0
						end
					end
				end
			end

			local remaining_ammo = ammo_in_clip - ammo_usage
			if ammo_in_clip < ammo_usage then
				ammo_usage = ammo_usage + remaining_ammo
				remaining_ammo = 0

				if self._fire_mode ~= Idstring("volley") then
					return -- Volley is weird and lets you fire a bunch of ammo at once no matter what or something.
				end
			end

			-- Flip the execution order here so that total ammo gets accurately updated.
			self:use_ammo(base, ammo_usage)
			base:set_ammo_remaining_in_clip(base:get_ammo_remaining_in_clip() - ammo_usage)

			is_empty =  ammo_in_clip > 0 and remaining_ammo <= (self.AKIMBO and 1 or 0)
		end

		local ray_res = self:_fire_raycast(user_unit, from_pos, direction, dmg_mul, shoot_player, spread_mul, autohit_mul, suppr_mul, target_unit, ammo_usage)

		if self._alert_events and ray_res.rays then
			self:_check_alert(ray_res.rays, from_pos, direction, user_unit)
		end

		self:_build_suppression(ray_res.enemies_in_cone, suppr_mul)
		managers.player:send_message(Message.OnWeaponFired, nil, self._unit, ray_res)

		local bullets_fired = self.parent_weapon and self.parent_weapon:base() and self.parent_weapon:base()._bullets_fired or self._bullets_fired or 1

		local is_jammed = math.random() < self:jam_chance(not self:clip_empty())
		self:set_jammed(is_jammed)

		-- Animation & Sounds:
		self:tweak_data_anim_stop("unequip")
		self:tweak_data_anim_stop("equip")

		local function attempt_tweak_data_function(tweak_data_function, attempt_data_list, ...)
			for _, attempt_data in pairs(attempt_data_list) do
				local attempt_name = attempt_data[1]
				local attempt_conditional = attempt_data[2]

				if attempt_conditional and tweak_data_function(self, attempt_name, ...) then
					return
				end
			end
		end

		local current_state = user_unit and user_unit:movement() and user_unit:movement()._current_state
		local in_steelsight = current_state and current_state:in_steelsight()

		local attempts = {
			{ "jam",             is_jammed     },
			{ "magazine_empty",  is_empty      },
			{ "fire_steelsight", in_steelsight },
			{ "fire",            true          }
		}

		local anim_multiplier = is_player and self:fire_rate_multiplier() or 1
		attempt_tweak_data_function(self.tweak_data_anim_play,    attempts, anim_multiplier)
		attempt_tweak_data_function(self.spawn_tweak_data_effect, attempts)

		if is_jammed then
			self:play_tweak_data_sound("jam")
		end

		if is_empty then
			self:play_tweak_data_sound("magazine_empty")
		end

		-- Play the out of ammo voiceline if we're empty. (g81x_plu)
		self:_check_ammo_total(user_unit)

		if alive(self._obj_fire) then
			self:_spawn_muzzle_effect(from_pos, direction)
		end

		if self._fire_mode == Idstring("burst") and bullets_fired > 1 and not self:weapon_tweak_data().sounds.fire_single then
			self:_fire_sound()
		end

		local shell_eject_effect_wanted = false

		if is_empty then
			shell_eject_effect_wanted = not w_td.disable_empty_shell_eject
		else
			shell_eject_effect_wanted = not w_td.disable_not_empty_shell_eject
		end

		if self:jammed() then
			shell_eject_effect_wanted = not not w_td.jammed_shell_eject
		end

		if shell_eject_effect_wanted then
			self:_spawn_shell_eject_effect()
		end

		return ray_res
	end

	function RaycastWeaponBase:_get_tweak_data_weapon_effect(effect_id)
		if self:gadget_overrides_weapon_functions() then
			return self:gadget_function_override("_get_tweak_data_weapon_effect", effect_id)
		end

		local effects = self:weapon_tweak_data().effects

		return effects and effects[anim]
	end

	function RaycastWeaponBase:play_tweak_data_sound(event, alternative_event)
		local w_td = self:weapon_tweak_data()

		if not w_td.sounds then return end
		if not (w_td.sounds[event] or w_td.sounds[alternative_event]) then return end

		local event = self:_get_sound_event(event, alternative_event)

		if event then
			self:play_sound(event)

			return true
		end

		return false
	end

	function RaycastWeaponBase:spawn_tweak_data_effect(effect_id)
		local effect_data = self:_get_tweak_data_weapon_effect(effect_id)

		if effect_data then
			self:_spawn_tweak_data_effect(effect_id)

			return true
		end

		return false
	end