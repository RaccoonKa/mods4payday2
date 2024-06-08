local mvec_to = Vector3()
local mvec_spread_direction = Vector3()

local mvec_right_ax = Vector3()
local mvec_up_ay = Vector3()
local mvec_ax = Vector3()
local mvec_ay = Vector3()

function NewRaycastWeaponBase:_fire_raycast(user_unit, from_pos, direction, dmg_mul, shoot_player, spread_mul, autohit_mul, suppr_mul, shoot_through_data, ammo_usage)
	if self:gadget_overrides_weapon_functions() then
		return self:gadget_function_override("_fire_raycast", self, user_unit, from_pos, direction, dmg_mul, shoot_player, spread_mul, autohit_mul, suppr_mul, shoot_through_data, ammo_usage)
	end

	local rays = self._rays
	if self._fire_mode == Idstring("volley") then
		local ammo_usage_ratio = math.clamp(ammo_usage > 0 and ammo_usage / (self._volley_ammo_usage or ammo_usage) or 1, 0, 1)
		rays = math.ceil(ammo_usage_ratio * (self._volley_rays or 1))
		spread_mul = spread_mul * (self._volley_spread_mul or 1)
		dmg_mul = dmg_mul * (self._volley_damage_mul or 1)
	end

	local single_hit_per_enemy = self._fire_mode ~= Idstring("volley")

	local result = {}

	local damage = self:_get_current_damage(dmg_mul)
	local hit_anyone = false

	local autoaim_enabled = not not (self._autoaim and self._autohit_data)
	local auto_hit_candidate, enemies_to_suppress
	if autoaim_enabled then
		auto_hit_candidate, enemies_to_suppress = self:check_autoaim(from_pos, direction)
	end

	local spread_x, spread_y = self:_get_spread(user_unit)
	local ray_distance = self:weapon_range()
	local right = direction:cross(Vector3(0, 0, 1)):normalized()
	local up = direction:cross(right):normalized()

	local hit_rays = {}
	local overall_ray_hits = {}

	local all_enemies_hit = {}

	for i = 1, rays or 1 do
		local distance = math.pow(math.random(), 0.62)
		local angle = math.random() * 360
		local ax = math.sin(angle) * distance * spread_x * (spread_mul or 1)
		local ay = math.cos(angle) * distance * spread_y * (spread_mul or 1)

		mvector3.set(mvec_spread_direction, direction)
		mvector3.add(mvec_spread_direction, right * math.rad(ax))
		mvector3.add(mvec_spread_direction, up * math.rad(ay))
		mvector3.set(mvec_to, mvec_spread_direction)
		mvector3.multiply(mvec_to, ray_distance)
		mvector3.add(mvec_to, from_pos)

		local ray_hits, hit_enemy, enemies_hit = self:_collect_hits(from_pos, mvec_to)

		if autoaim_enabled then
			local weight = 0.1

			if auto_hit_candidate and not hit_enemy then
				local autohit_chance = 1 - math.clamp((self._autohit_current - self._autohit_data.MIN_RATIO) / (self._autohit_data.MAX_RATIO - self._autohit_data.MIN_RATIO), 0, 1)

				if autohit_mul then
					autohit_chance = autohit_chance * autohit_mul
				end

				if math.random() < autohit_chance then
					self._autohit_current = (self._autohit_current + weight) / (1 + weight)

					mvector3.set(mvec_spread_direction, auto_hit_candidate.ray)
					mvector3.set(mvec_to, mvec_spread_direction)
					mvector3.multiply(mvec_to, ray_distance)
					mvector3.add(mvec_to, from_pos)

					ray_hits, hit_enemy, enemies_hit = self:_collect_hits(from_pos, mvec_to)
				end
			end

			if hit_enemy then
				self._autohit_current = (self._autohit_current + weight) / (1 + weight)
			elseif auto_hit_candidate then
				self._autohit_current = self._autohit_current / (1 + weight)
			end
		end

		for index, hit in ipairs(ray_hits) do
			local visual = false

			if hit.unit:character_damage() then
				if single_hit_per_enemy and all_enemies_hit[hit.unit:key()] then
					visual = true
				else
					table.insert(hit_rays, hit)
				end
			end

			table.insert(overall_ray_hits, {
				hit = hit,
				visual = visual,
				first = index == 1
			})
		end

		if enemies_hit then
			for unit_key, enemy in ipairs(enemies_hit) do
				all_enemies_hit[unit_key] = enemy
			end
		end
	end

	local hit_count = 0
	local cop_kill_count = 0
	local hit_through_wall = false
	local hit_through_shield = false
	local hit_result = nil

	local shotgun_kill_data = {
		kills = 0,
		headshots = 0,
		civilian_kills = 0
	}

	local is_civ_f = CopDamage.is_civilian

	local extra_collisions = self.extra_collisions and self:extra_collisions() or {}

	local hit_results = {}
	for index, hit_info in ipairs(overall_ray_hits) do
		local hit = hit_info.hit

		damage = self:get_damage_falloff(damage, hit, user_unit)
		if damage > 0 then
			if hit_info.visual then
				self._bullet_class:on_collision_effects(hit, self._unit, user_unit, damage)
			else
				local hit_result = self._bullet_class:on_collision(hit, self._unit, user_unit, damage)

				if hit_result then
					table.insert(hit_results, {
						result = hit_result,
						hit = hit,
						through_wall = hit_through_wall,
						through_shield = hit_through_shield
					})
				end

				for _, extra_collision_data in ipairs(extra_collisions) do
					if alive(hit.unit) then
						extra_collision_data.bullet_class:on_collision(
							hit,
							self._unit,
							user_unit,
							damage * (extra_collision_data.dmg_mul or 1)
						)
					end
				end
			end
		end

		-- Reset the hit checks at the start of each ray.
		if hit_info.first then
			hit_through_wall = false
			hit_through_shield = false
		end

		if hit.unit:in_slot(managers.slot:get_mask("world_geometry")) then
			hit_through_wall = true
		elseif hit.unit:in_slot(managers.slot:get_mask("enemy_shield_check")) then
			hit_through_shield = hit_through_shield or alive(hit.unit:parent())
		end
	end

	managers.statistics:shot_fired({
		hit = false,
		weapon_unit = self._unit
	})

	local is_shotgun = self:is_category("shotgun")
	for _, hit_result_info in ipairs(hit_results) do
		local hit_result = hit_result_info.result
		local hit = hit_result_info.hit
		local through_wall = hit_result_info.through_wall
		local through_shield = hit_result_info.through_shield

		if is_shotgun then
			hit_result = managers.mutators:modify_value("ShotgunBase:_fire_raycast", hit_result)

			if hit_result and hit_result.type == "death" then
				shotgun_kill_data.kills = shotgun_kill_data.kills + 1

				if hit.body and hit.body:name() == Idstring("head") then
					shotgun_kill_data.headshots = shotgun_kill_data.headshots + 1
				end

				if hit.unit and hit.unit:base() and (hit.unit:base()._tweak_table == "civilian" or hit.unit:base()._tweak_table == "civilian_female") then
					shotgun_kill_data.civilian_kills = shotgun_kill_data.civilian_kills + 1
				end
			end
		end

		hit.damage_result = hit_result
		hit_anyone = true
		hit_count = hit_count + 1

		if hit_result.type == "death" then
			local unit_base = hit.unit:base()
			local unit_type = unit_base and unit_base._tweak_table
			local is_civilian = unit_type and is_civ_f(unit_type)

			self:_check_kill_achievements(cop_kill_count, unit_base, unit_type, is_civilian, hit_through_wall, hit_through_shield)
		end

		if not (self._ammo_data and self._ammo_data.ignore_statistic) then
			managers.statistics:shot_fired({
				skip_bullet_count = true,
				hit = true,
				weapon_unit = self._unit
			})
		end
	end

	self:_check_tango_achievements(cop_kill_count)
	if is_shotgun then
		ShotgunBase._check_one_shot_shotgun_achievements(self, shotgun_kill_data)
	end

	result.hit_enemy = hit_anyone

	if autoaim_enabled then
		self._shot_fired_stats_table.hit = hit_anyone
		self._shot_fired_stats_table.hit_count = hit_count
	end

	local furthest_hit = hit_rays[#hit_rays]
	local required_trail_distance = self:weapon_tweak_data().required_trail_distance or 600
	if (furthest_hit and furthest_hit.distance > required_trail_distance or not furthest_hit) and alive(self._obj_fire) then
		self._obj_fire:m_position(self._trail_effect_table.position)
		mvector3.set(self._trail_effect_table.normal, mvec_spread_direction)

		local trail = World:effect_manager():spawn(self._trail_effect_table)

		if furthest_hit then
			World:effect_manager():set_remaining_lifetime(trail, math.clamp((furthest_hit.distance - required_trail_distance) / 10000, 0, furthest_hit.distance))
		end
	end

	result.enemies_in_cone = enemies_to_suppress or false

	if self._suppression then
		if autoaim_enabled then
			result.enemies_in_cone = enemies_to_suppress or {}
			local all_enemies = managers.enemy:all_enemies()

			for unit_key, enemy in pairs(all_enemies_hit) do
				if all_enemies[u_key] then
					result.enemies_in_cone[u_key] = {
						error_mul = 1,
						unit = enemy
					}
				end
			end
		else
			result.enemies_in_cone = self:check_suppression(from_pos, direction, all_enemies_hit)
		end
	end

	if self._alert_events then
		result.rays = hit_rays
	end

	return result
end