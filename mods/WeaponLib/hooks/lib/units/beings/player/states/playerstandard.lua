function PlayerStandard:_check_action_deploy_underbarrel(t, input)
	if _G.IS_VR then
		if not input.btn_weapon_firemode_press and not self._toggle_underbarrel_wanted then
			return
		end
	elseif not input.btn_deploy_bipod and not self._toggle_underbarrel_wanted then
		return
	end

	local weapon = self._equipped_unit:base()

	if self._running and not weapon:run_and_shoot_allowed() and not self._end_running_expire_t then
		self:_interupt_action_running(t)

		self._toggle_underbarrel_wanted = true

		return
	end

	local new_action = nil
	local action_forbidden = self:in_steelsight() or self:_is_throwing_projectile() or self:_is_meleeing() or self:is_equipping() or self:_changing_weapon() or self:shooting() or self:_is_reloading() or self:is_switching_stances() or self:_interacting() or self:running() and not weapon:run_and_shoot_allowed()
	if not action_forbidden then
		self._toggle_underbarrel_wanted = false

		if weapon.record_fire_mode then
			weapon:record_fire_mode()
		end

		local underbarrel_state = weapon:underbarrel_toggle()

		if underbarrel_state ~= nil then
			local underbarrel_name_id = weapon:underbarrel_name_id()
			local underbarrel_tweak = tweak_data.weapon[underbarrel_name_id]
			new_action = true

			if weapon.reset_cached_gadget then
				weapon:reset_cached_gadget()
			end

			if weapon._update_stats_values then
				weapon:_update_stats_values(true)
			end

			local anim_name_id = nil
			local anim_redirect = nil
			local switch_delay = 1

			local weapon_tweak_data = weapon:weapon_tweak_data()

			if weapon_tweak_data.animations then
				if underbarrel_state then
					anim_name_id = weapon_tweak_data.animations.underbarrel_enter_name_id
				else
					anim_name_id = weapon_tweak_data.animations.underbarrel_exit_name_id
				end
			end

			if not anim_name_id then
				anim_name_id = underbarrel_tweak.weapon_hold and underbarrel_tweak.weapon_hold or weapon:weapon_tweak_data().weapon_hold or weapon.name_id
			end

			local function try_redirect(redirect)
				return self._ext_camera:play_redirect(Idstring(redirect), 1)
			end

			if underbarrel_state then
				anim_redirect = "underbarrel_enter_" .. anim_name_id
				switch_delay = underbarrel_tweak.timers.equip_underbarrel

				self:set_animation_state("underbarrel")
			else
				anim_redirect = "underbarrel_exit_" .. anim_name_id
				switch_delay = underbarrel_tweak.timers.unequip_underbarrel

				self:set_animation_state("standard")
			end

			if anim_redirect then
				self._ext_camera:play_redirect(Idstring(anim_redirect), 1)
			end

			self:set_animation_weapon_hold(nil)
			self:set_stance_switch_delay(switch_delay)
			self:_stance_entered()

			managers.hud:set_ammo_amount(weapon:selection_index(), weapon:ammo_info())
			managers.hud:set_teammate_weapon_firemode(HUDManager.PLAYER_PANEL, self._unit:inventory():equipped_selection(), weapon:fire_mode(), weapon:alt_fire_active())

			if underbarrel_tweak.custom then
				if underbarrel_tweak.based_on then
					underbarrel_name_id = underbarrel_tweak.based_on
				else
					local is_npc = string.ends(underbarrel_name_id, "_npc")
					underbarrel_name_id = "contraband_m203" .. ( is_npc and "_npc" or "" )
				end
			end

			local clip_empty = weapon.clip_empty and weapon:clip_empty()
			self._camera_unit:anim_state_machine():set_global("is_empty", clip_empty and 1 or 0)

			managers.network:session():send_to_peers_synched("sync_underbarrel_switch", self._equipped_unit:base():selection_index(), underbarrel_name_id, underbarrel_state)
		end
	end

	return new_action
end

function PlayerStandard:_start_action_reload_enter(t)
	local weapon = self._equipped_unit:base()

	if weapon and weapon:can_reload() then
		if weapon.enter_reload then
			weapon:enter_reload()
		end

		weapon:tweak_data_anim_stop("fire")

		managers.player:send_message_now(Message.OnPlayerReload, nil, self._equipped_unit)
		self:_interupt_action_steelsight(t)

		if not self.RUN_AND_RELOAD then
			self:_interupt_action_running(t)
		end

		self:_interupt_action_charging_weapon(t)

		local should_do_empty_reload = weapon:should_do_empty_reload()
		local base_reload_enter_expire_t = weapon:reload_enter_expire_t(not should_do_empty_reload)

		if base_reload_enter_expire_t and base_reload_enter_expire_t > 0 then
			weapon:cache_reload_speed_multiplier()

			local speed_multiplier = weapon:reload_speed_multiplier()

			local reload_bipod_prefix = self:_is_using_bipod() and "bipod_" or ""
			local reload_prefix = reload_bipod_prefix .. (weapon:reload_prefix() or "")
			local reload_name_id = weapon:reload_name_id()

			local reload_redirect = Idstring(reload_prefix .. "reload_enter_" .. reload_name_id)

			self._ext_camera:play_redirect(reload_redirect, speed_multiplier)

			self._state_data.reload_enter_expire_t = t + base_reload_enter_expire_t / speed_multiplier

			weapon:tweak_data_anim_play("reload_enter", speed_multiplier)

			return
		end

		self:_start_action_reload(t)
	end
end

function PlayerStandard:_start_action_reload(t)
	local weapon = self._equipped_unit:base()

	if weapon and weapon:can_reload() then
		local should_do_empty_reload = weapon:should_do_empty_reload()

		local speed_multiplier = weapon:reload_speed_multiplier()

		local tweak_data = weapon:weapon_tweak_data()
		local reload_anim = "reload_not_empty"
		local reload_bipod_prefix = self:_is_using_bipod() and "bipod_" or ""
		local reload_prefix = reload_bipod_prefix .. (weapon:reload_prefix() or "")
		local reload_name_id = weapon:reload_name_id()
		local reload_default_expire_t = 2.2
		local reload_tweak = tweak_data.timers.reload_not_empty
		local reload_steelsight_expire_t = tweak_data.timers.reload_steelsight

		if should_do_empty_reload then
			reload_anim = "reload"
			reload_default_expire_t = 2.6
			reload_tweak = tweak_data.timers.reload_empty
			reload_steelsight_expire_t = tweak_data.timers.reload_steelsight_not_empty
		end

		local empty_reload = should_do_empty_reload and 1 or 0
		if weapon:use_shotgun_reload() then
			empty_reload = weapon:get_ammo_max_per_clip() - weapon:get_ammo_remaining_in_clip()
			reload_tweak = weapon:reload_expire_t(not should_do_empty_reload)
		end

		local reload_ids = Idstring(string.format("%s%s_%s", reload_prefix, reload_anim, reload_name_id))
		local result = self._ext_camera:play_redirect(reload_ids, speed_multiplier)

		self._state_data.reload_expire_t = t + (reload_tweak or reload_default_expire_t) / speed_multiplier
		if reload_steelsight_expire_t then
			self._state_data.reload_steelsight_expire_t = t + reload_steelsight_expire_t / speed_multiplier
		end

		weapon:start_reload()

		if not weapon:tweak_data_anim_play(reload_anim, speed_multiplier) then
			weapon:tweak_data_anim_play("reload", speed_multiplier)
		end

		self._ext_network:send("reload_weapon", empty_reload, speed_multiplier)
	end
end

Hooks:PostHook(PlayerStandard, "_update_reload_timers", "weaponlib_playerstandard_update_reload_timers", function(self, t, dt, input)
	if self._equipped_unit and alive(self._equipped_unit) then
		local weap_base = self._equipped_unit:base()
		local clip_empty = weap_base.clip_empty and weap_base:clip_empty()
		self._camera_unit:anim_state_machine():set_global("is_empty", clip_empty and 1 or 0)
	end

	self:_update_unjam_timers(t, dt, input)
end)

function PlayerStandard:_update_unjam_timers(t, dt, input)
	if self._equipped_unit then
		local equipped_base = self._equipped_unit:base()

		if equipped_base.jammed then
			if not self._state_data.equipped_jammed and equipped_base:jammed() then
				self._state_data.equipped_jammed = true
			elseif self._state_data.equipped_jammed and not equipped_base:jammed() then
				self._state_data.equipped_jammed = false
			end

		elseif self._state_data.equipped_jammed then
			self._state_data.equipped_jammed = false
		end
	end

	self._camera_unit:anim_state_machine():set_global("is_jammed", self._state_data.equipped_jammed and 1 or 0)

	if self._state_data.unjam_expire_t then
		local interupt = nil

		if self._queue_unjam_interupt then
			self._queue_unjam_interupt = nil
			interupt = true
		end

		if self._state_data.unjam_expire_t <= t or interupt then
			self._state_data.unjam_expire_t = nil

			if self._equipped_unit then
				if not interupt then
					self._equipped_unit:base():set_jammed(false)
				end

				if input.btn_steelsight_state then
					self._steelsight_wanted = true
				elseif self.RUN_AND_RELOAD and self._running and not self._end_running_expire_t and not self._equipped_unit:base():run_and_shoot_allowed() then
					self._ext_camera:play_redirect(self:get_animation("start_running"))
				end
			end
		end
	end
end

PlayerStandard._pre_weaponlib_check_action_reload = PlayerStandard._pre_weaponlib_check_action_reload or PlayerStandard._check_action_reload
function PlayerStandard:_check_action_reload(t, input)
	local new_action = nil
	local action_wanted = input.btn_reload_press

	if action_wanted then
		local weapon = self._equipped_unit:base()
		local weapon_tweak_data = weapon:weapon_tweak_data()
		local action_forbidden =
			self:_is_reloading() or
			self:_changing_weapon() or
			self:_is_meleeing() or
			self._use_item_expire_t or
			self:_interacting() or
			self:_is_throwing_projectile() or
			weapon_tweak_data.bipod_reload_only and not self:_is_using_bipod()

		if weapon and weapon:jammed() and not action_forbidden then
			self:_start_action_unjam(t)
			new_action = true
		else
			new_action = self:_pre_weaponlib_check_action_reload(t, input)
		end
	end

	return new_action
end

function PlayerStandard:_start_action_unjam(t)
	local weapon = self._equipped_unit:base()

	if weapon and weapon:jammed() then
		self:_interupt_action_steelsight(t)

		if not self.RUN_AND_RELOAD then
			self:_interupt_action_running(t)
		end

		local is_reload_not_empty = weapon:clip_not_empty()

		weapon:tweak_data_anim_stop("fire")

		local speed_multiplier = weapon:reload_speed_multiplier()

		local tweak_data = weapon:weapon_tweak_data()
		local unjam_anim = "unjam"
		local reload_bipod_prefix = self:_is_using_bipod() and "bipod_" or ""
		local reload_prefix = reload_bipod_prefix .. (weapon:reload_prefix() or "")
		local unjam_name_id = weapon:unjam_name_id()

		local unjam_ids = Idstring(string.format("%s%s_%s", reload_prefix, unjam_anim, unjam_name_id))
		local result = self._ext_camera:play_redirect(unjam_ids, speed_multiplier)

		self._state_data.unjam_expire_t = t + weapon:unjam_expire_t() / speed_multiplier

		weapon:tweak_data_anim_play(unjam_anim, speed_multiplier)
	end
end

Hooks:PostHook(PlayerStandard, "_interupt_action_reload", "weaponlib_playerstandard_interupt_action_reload", function(self, t)
	self:_interupt_action_unjam(t)
end)

function PlayerStandard:_interupt_action_unjam(t)
	if self:_is_unjamming() then
		self._equipped_unit:base():tweak_data_anim_stop("unjam")
		self._equipped_unit:base():tweak_data_anim_play_at_end("jam")
	end

	self._state_data.unjam_expire_t = nil
end

function PlayerStandard:_is_unjamming()
	return self._state_data.unjam_expire_t
end

PlayerStandard._pre_weaponlib_is_reloading = PlayerStandard._pre_weaponlib_is_reloading or PlayerStandard._is_reloading
function PlayerStandard:_is_reloading()
	return self:_is_unjamming() or self:_pre_weaponlib_is_reloading()
end

function PlayerStandard:_check_action_primary_attack(t, input)
	if not self._equipped_unit then return false end

	local new_action = nil
	local action_wanted = input.btn_primary_attack_state or input.btn_primary_attack_release
	action_wanted = action_wanted or self:is_shooting_count()
	action_wanted = action_wanted or self:_is_charging_weapon()

	if action_wanted then
		local weap_base = self._equipped_unit:base()
		local weapon_tweak_data = weap_base:weapon_tweak_data()

		local action_forbidden =
			self:_is_reloading() or
			self:_changing_weapon() or
			self:_is_meleeing() or
			self._use_item_expire_t or
			self:_interacting() or
			self:_is_throwing_projectile() or
			self:_is_deploying_bipod() or
			self._menu_closed_fire_cooldown > 0 or
			self:is_switching_stances() or
			weapon_tweak_data.bipod_fire_only and not self:_is_using_bipod()

		if not action_forbidden then
			self._queue_reload_interupt = nil
			local start_shooting = false

			self._ext_inventory:equip_selected_primary(false)

			local fire_mode = weap_base:fire_mode()
			local animation_firemode = fire_mode == "auto" and "auto" or "single"
			if fire_mode ~= "auto" and weapon_tweak_data.fake_singlefire_anim then
				animation_firemode = "auto"
			elseif fire_mode == "auto" and weapon_tweak_data.fake_autofire_anim then
				animation_firemode = "single"
			end

			local fire_on_release = weap_base:fire_on_release()

			if weap_base:out_of_ammo() then
				if input.btn_primary_attack_press then
					weap_base:dryfire()
				end
			elseif weap_base.clip_empty and weap_base:clip_empty() then
				if self:_is_using_bipod() then
					if input.btn_primary_attack_press then
						weap_base:dryfire()
					end

					self._equipped_unit:base():tweak_data_anim_stop("fire")
				elseif fire_mode == "single" then
					if input.btn_primary_attack_press or self._equipped_unit:base().should_reload_immediately and self._equipped_unit:base():should_reload_immediately() then
						self:_start_action_reload_enter(t)
					end
				else
					new_action = true

					self:_start_action_reload_enter(t)
				end
			elseif self._running and not self._equipped_unit:base():run_and_shoot_allowed() then
				self:_interupt_action_running(t)
			else
				local firing_animation_state = nil

				if not self._shooting then
					if weap_base:start_shooting_allowed() then
						local start = fire_mode == "single" and input.btn_primary_attack_press
						start = start or fire_mode == "auto" and input.btn_primary_attack_state
						start = start or fire_mode == "burst" and input.btn_primary_attack_press
						start = start or fire_mode == "volley" and input.btn_primary_attack_press
						start = start and not fire_on_release
						start = start or fire_on_release and input.btn_primary_attack_release

						if start then
							weap_base:start_shooting()
							self._camera_unit:base():start_shooting()

							self._shooting = true
							self._shooting_t = t
							start_shooting = true

							if animation_firemode == "auto" then
								self._recoil_enter = true
								self._recoil_end_t = self._shooting_t + (weapon_tweak_data.timers and weapon_tweak_data.timers.fake_singlefire or 0.1)

								firing_animation_state = self._unit:camera():play_redirect(self:get_animation("recoil_enter"))
							end

							if fire_mode == "auto" then
								if (not weap_base.akimbo or weapon_tweak_data.allow_akimbo_autofire) and (not weap_base.third_person_important or weap_base.third_person_important and not weap_base:third_person_important()) then
									self._ext_network:send("sync_start_auto_fire_sound", 0)
								end
							end
						end
					else
						self:_check_stop_shooting()

						return false
					end
				end

				local suppression_ratio = self._unit:character_damage():effective_suppression_ratio()
				local spread_mul = math.lerp(1, tweak_data.player.suppression.spread_mul, suppression_ratio)
				local autohit_mul = math.lerp(1, tweak_data.player.suppression.autohit_chance_mul, suppression_ratio)
				local suppression_mul = managers.blackmarket:threat_multiplier()
				local dmg_mul = 1
				local primary_category = weapon_tweak_data.categories[1]

				if not weapon_tweak_data.ignore_damage_multipliers then
					dmg_mul = dmg_mul * managers.player:temporary_upgrade_value("temporary", "dmg_multiplier_outnumbered", 1)

					if managers.player:has_category_upgrade("player", "overkill_all_weapons") or weap_base:is_category("shotgun", "saw") then
						dmg_mul = dmg_mul * managers.player:temporary_upgrade_value("temporary", "overkill_damage_multiplier", 1)
					end

					local health_ratio = self._ext_damage:health_ratio()
					local damage_health_ratio = managers.player:get_damage_health_ratio(health_ratio, primary_category)

					if damage_health_ratio > 0 then
						local upgrade_name = weap_base:is_category("saw") and "melee_damage_health_ratio_multiplier" or "damage_health_ratio_multiplier"
						local damage_ratio = damage_health_ratio
						dmg_mul = dmg_mul * (1 + managers.player:upgrade_value("player", upgrade_name, 0) * damage_ratio)
					end

					dmg_mul = dmg_mul * managers.player:temporary_upgrade_value("temporary", "berserker_damage_multiplier", 1)
					dmg_mul = dmg_mul * managers.player:get_property("trigger_happy", 1)
				end

				local fired = nil

				if fire_mode == "single" then
					if input.btn_primary_attack_press and start_shooting then
						fired = weap_base:trigger_pressed(self:get_fire_weapon_position(), self:get_fire_weapon_direction(), dmg_mul, nil, spread_mul, autohit_mul, suppression_mul)
					elseif fire_on_release then
						if input.btn_primary_attack_release then
							fired = weap_base:trigger_released(self:get_fire_weapon_position(), self:get_fire_weapon_direction(), dmg_mul, nil, spread_mul, autohit_mul, suppression_mul)
						elseif input.btn_primary_attack_state then
							weap_base:trigger_held(self:get_fire_weapon_position(), self:get_fire_weapon_direction(), dmg_mul, nil, spread_mul, autohit_mul, suppression_mul)
						end
					end
				elseif fire_mode == "burst" then
					fired = weap_base:trigger_held(self:get_fire_weapon_position(), self:get_fire_weapon_direction(), dmg_mul, nil, spread_mul, autohit_mul, suppression_mul)
				elseif fire_mode == "volley" then
					if self._shooting then
						fired = weap_base:trigger_held(self:get_fire_weapon_position(), self:get_fire_weapon_direction(), dmg_mul, nil, spread_mul, autohit_mul, suppression_mul)
					end
				elseif input.btn_primary_attack_state then
					fired = weap_base:trigger_held(self:get_fire_weapon_position(), self:get_fire_weapon_direction(), dmg_mul, nil, spread_mul, autohit_mul, suppression_mul)
				end

				if weap_base.manages_steelsight and weap_base:manages_steelsight() then
					if weap_base:wants_steelsight() and not self._state_data.in_steelsight then
						self:_start_action_steelsight(t)
					elseif not weap_base:wants_steelsight() and self._state_data.in_steelsight then
						self:_end_action_steelsight(t)
					end
				end

				local charging_weapon = weap_base:charging()

				if not self._state_data.charging_weapon and charging_weapon then
					self:_start_action_charging_weapon(t)
				elseif self._state_data.charging_weapon and not charging_weapon then
					self:_end_action_charging_weapon(t)
				end

				new_action = true

				if fired then
					managers.rumble:play("weapon_fire")

					local clip_empty = weap_base:ammo_base():get_ammo_remaining_in_clip() <= (weap_base.AKIMBO and 1 or 0)
					self._camera_unit:anim_state_machine():set_global("is_empty", clip_empty and 1 or 0)

					local weap_tweak_data = weap_base:weapon_tweak_data()
					local shake_tweak_data = weap_tweak_data.shake[fire_mode] or weap_tweak_data.shake
					local shake_multiplier = shake_tweak_data[self._state_data.in_steelsight and "fire_steelsight_multiplier" or "fire_multiplier"]

					self._ext_camera:play_shaker("fire_weapon_rot", 1 * shake_multiplier)
					self._ext_camera:play_shaker("fire_weapon_kick", 1 * shake_multiplier, 1, 0.15)

					if animation_firemode == "single" and weap_base:get_name_id() ~= "saw" then
						local redirect = self:get_animation("recoil")
						if self._state_data.in_steelsight and weap_tweak_data.animations.recoil_steelsight and not weap_base:is_second_sight_on() then
							redirect = self:get_animation("recoil_steelsight")
						end

						firing_animation_state = self._ext_camera:play_redirect(redirect, weap_base:fire_rate_multiplier())
					end

					local recoil_multiplier = (weap_base:recoil() + weap_base:recoil_addend()) * weap_base:recoil_multiplier()

					local kick_tweak_data = weap_tweak_data.kick[fire_mode] or weap_tweak_data.kick
					local up, down, left, right = unpack(kick_tweak_data[self._state_data.in_steelsight and "steelsight" or self._state_data.ducking and "crouching" or "standing"])

					self._camera_unit:base():recoil_kick(up * recoil_multiplier, down * recoil_multiplier, left * recoil_multiplier, right * recoil_multiplier)

					if self._shooting_t then
						local time_shooting = t - self._shooting_t
						local achievement_data = tweak_data.achievement.never_let_you_go

						if achievement_data and weap_base:get_name_id() == achievement_data.weapon_id and achievement_data.timer <= time_shooting then
							managers.achievment:award(achievement_data.award)

							self._shooting_t = nil
						end
					end

					if managers.player:has_category_upgrade(primary_category, "stacking_hit_damage_multiplier") then
						self._state_data.stacking_dmg_mul = self._state_data.stacking_dmg_mul or {}
						self._state_data.stacking_dmg_mul[primary_category] = self._state_data.stacking_dmg_mul[primary_category] or {
							nil,
							0
						}
						local stack = self._state_data.stacking_dmg_mul[primary_category]

						if fired.hit_enemy then
							stack[1] = t + managers.player:upgrade_value(primary_category, "stacking_hit_expire_t", 1)
							stack[2] = math.min(stack[2] + 1, tweak_data.upgrades.max_weapon_dmg_mul_stacks or 5)
						else
							stack[1] = nil
							stack[2] = 0
						end
					end

					if weap_base.set_recharge_clbk then
						weap_base:set_recharge_clbk(callback(self, self, "weapon_recharge_clbk_listener"))
					end

					managers.hud:set_ammo_amount(weap_base:selection_index(), weap_base:ammo_info())

					local impact = not fired.hit_enemy

					if weap_base.third_person_important and weap_base:third_person_important() then
						self._ext_network:send("shot_blank_reliable", impact, 0)
					elseif fire_mode ~= "auto" or weap_base.akimbo and not weapon_tweak_data.allow_akimbo_autofire then
						self._ext_network:send("shot_blank", impact, 0)
					end

					if fire_mode == "volley" then
						self:_check_stop_shooting()
					end
				elseif fire_mode == "single" then
					new_action = false
				elseif fire_mode == "burst" then
					if weap_base:shooting_count() == 0 then
						new_action = false
					end
				elseif fire_mode == "volley" then
					new_action = self:_is_charging_weapon()
				end

				if firing_animation_state then
					self._camera_unit:anim_state_machine():set_parameter(firing_animation_state, "alt_weight", self._equipped_unit:base():alt_fire_active() and 1 or 0)
				end
			end
		elseif self:_is_reloading() and self._equipped_unit:base():reload_interuptable() and input.btn_primary_attack_press then
			self._queue_reload_interupt = true
		end
	end

	if not new_action then
		self:_check_stop_shooting()
	end

	return new_action
end

function PlayerStandard:_check_stop_shooting()
	if self._shooting then
		self._equipped_unit:base():stop_shooting()
		self._camera_unit:base():stop_shooting(self._equipped_unit:base():recoil_wait())

		local weap_base = self._equipped_unit:base()
		local weapon_tweak_data = weap_base:weapon_tweak_data()

		local fire_mode = weap_base:fire_mode()
		local animation_firemode = fire_mode == "auto" and "auto" or "single"
		if fire_mode ~= "auto" and weapon_tweak_data.fake_singlefire_anim then
			animation_firemode = "auto"
		elseif fire_mode == "auto" and weapon_tweak_data.fake_autofire_anim then
			animation_firemode = "single"
		end

		local is_auto_fire_mode = fire_mode == "auto"
		if is_auto_fire_mode and (not weap_base.akimbo or weapon_tweak_data.allow_akimbo_autofire) then
			self._ext_network:send("sync_stop_auto_fire_sound", 0)
		end

		if is_auto_fire_mode and animation_firemode == "auto" and not self:_is_reloading() and not self:_is_meleeing() then
			self._unit:camera():play_redirect(self:get_animation("recoil_exit"))
		end

		self._shooting = false
		self._shooting_t = nil
	end

	if self._recoil_enter then
		if Application:time() >= self._recoil_end_t then
			self._recoil_enter = false
			self._recoil_end_t = nil

			if not self:_is_reloading() and not self:_is_meleeing() then
				self._unit:camera():play_redirect(self:get_animation("recoil_exit"))
			end
		end
	end
end

Hooks:PostHook(PlayerStandard, "_start_action_equip_weapon", "weaopnlib_playerstandard_start_action_equip_weapon", function(self, t)
	if self._camera_unit then
		local weap_base = self._equipped_unit:base()
		local clip_empty = weap_base.clip_empty and weap_base:clip_empty()
		self._camera_unit:anim_state_machine():set_global("is_empty", clip_empty and 1 or 0)
	end

	if self._equipped_unit:base().run_and_reload_allowed and self._equipped_unit:base():run_and_reload_allowed() then
		self.RUN_AND_RELOAD = true
	else
		self.RUN_AND_RELOAD = managers.player:has_category_upgrade("player", "run_and_reload")
	end
end)