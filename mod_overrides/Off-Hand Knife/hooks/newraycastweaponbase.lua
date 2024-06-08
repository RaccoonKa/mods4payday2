local old_weapon_tweak_data = NewRaycastWeaponBase.weapon_tweak_data
function NewRaycastWeaponBase:weapon_tweak_data(...)
	local weapon_tweak_data = old_weapon_tweak_data(self, ...)

	if not self._parts then
		return weapon_tweak_data 
	end

	if self._parts.wpn_fps_pis_usp_knife_rambo then 

		if self._name_id == "usp" or self._name_id == "colt_1911" or self._name_id == "p226" or self._name_id == "hs2000" then
			weapon_tweak_data.animations.reload_name_id = "pistolknife"
		elseif self._name_id == "deagle" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifedeagle"
		elseif self._name_id == "pl14" or  self._name_id == "m1911" or  self._name_id == "sparrow" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifesparrow"
		else
			weapon_tweak_data.animations.reload_name_id = "pistolknifeglock"
		end
	
		weapon_tweak_data.weapon_hold = "pistolknife"
		weapon_tweak_data.animations.reload_knife_shell_data = {
			align = "left",
			unit_name = "units/pd2_dlc_gage_lmg/weapons/wpn_fps_mel_rambo/wpn_fps_mel_rambo"
		}
	end

	if self._parts.wpn_fps_pis_usp_knife_bayonet then 

		if self._name_id == "usp" or self._name_id == "colt_1911" or self._name_id == "p226" or self._name_id == "hs2000" then
			weapon_tweak_data.animations.reload_name_id = "pistolknife"
		elseif self._name_id == "deagle" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifedeagle"
		elseif self._name_id == "pl14" or  self._name_id == "m1911" or  self._name_id == "sparrow" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifesparrow"
		else
			weapon_tweak_data.animations.reload_name_id = "pistolknifeglock"
		end
	
		weapon_tweak_data.weapon_hold = "pistolknife"
		weapon_tweak_data.animations.reload_knife_shell_data = {
			align = "left",
			unit_name = "units/pd2_dlc_gage_assault/weapons/wpn_fps_mel_bayonet/wpn_fps_mel_bayonet"
		}
	end

	if self._parts.wpn_fps_pis_usp_knife_sword then 

		if self._name_id == "usp" or self._name_id == "colt_1911" or self._name_id == "p226" or self._name_id == "hs2000" then
			weapon_tweak_data.animations.reload_name_id = "pistolknife"
		elseif self._name_id == "deagle" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifedeagle"
		elseif self._name_id == "pl14" or  self._name_id == "m1911" or  self._name_id == "sparrow" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifesparrow"
		else
			weapon_tweak_data.animations.reload_name_id = "pistolknifeglock"
		end
	
		weapon_tweak_data.weapon_hold = "pistolknife"
		weapon_tweak_data.animations.reload_knife_shell_data = {
			align = "left",
			unit_name = "units/pd2_dlc_pn2/weapons/wpn_fps_mel_sword/wpn_fps_mel_sword"
		}
	end

	if self._parts.wpn_fps_pis_usp_knife_oxide then 

		if self._name_id == "usp" or self._name_id == "colt_1911" or self._name_id == "p226" or self._name_id == "hs2000" then
			weapon_tweak_data.animations.reload_name_id = "pistolknife"
		elseif self._name_id == "deagle" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifedeagle"
		elseif self._name_id == "pl14" or  self._name_id == "m1911" or  self._name_id == "sparrow" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifesparrow"
		else
			weapon_tweak_data.animations.reload_name_id = "pistolknifeglock"
		end
	
		weapon_tweak_data.weapon_hold = "pistolknife"
		weapon_tweak_data.animations.reload_knife_shell_data = {
			align = "left",
			unit_name = "units/pd2_dlc_grv/weapons/wpn_fps_mel_oxide/wpn_fps_mel_oxide"
		}
	end
	
	if self._parts.wpn_fps_pis_usp_knife_freedom then 

		if self._name_id == "usp" or self._name_id == "colt_1911" or self._name_id == "p226" or self._name_id == "hs2000" then
			weapon_tweak_data.animations.reload_name_id = "pistolknife"
		elseif self._name_id == "deagle" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifedeagle"
		elseif self._name_id == "pl14" or  self._name_id == "m1911" or  self._name_id == "sparrow" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifesparrow"
		else
			weapon_tweak_data.animations.reload_name_id = "pistolknifeglock"
		end
	
		weapon_tweak_data.weapon_hold = "pistolknife"
		weapon_tweak_data.animations.reload_knife_shell_data = {
			align = "left",
			unit_name = "units/pd2_dlc_gage_historical/weapons/wpn_fps_mel_freedom/wpn_fps_mel_freedom"
		}
	end
	
	if self._parts.wpn_fps_pis_usp_knife_kabar_tanto then 

		if self._name_id == "usp" or self._name_id == "colt_1911" or self._name_id == "p226" or self._name_id == "hs2000" then
			weapon_tweak_data.animations.reload_name_id = "pistolknife"
		elseif self._name_id == "deagle" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifedeagle"
		elseif self._name_id == "pl14" or  self._name_id == "m1911" or  self._name_id == "sparrow" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifesparrow"
		else
			weapon_tweak_data.animations.reload_name_id = "pistolknifeglock"
		end
	
		weapon_tweak_data.weapon_hold = "pistolknife"
		weapon_tweak_data.animations.reload_knife_shell_data = {
			align = "left",
			unit_name = "units/pd2_crimefest_2014/oct22/weapons/wpn_fps_mel_kabar_tanto/wpn_fps_mel_kabar_tanto"
		}
	end
	
	if self._parts.wpn_fps_pis_usp_knife_kabar then 

		if self._name_id == "usp" or self._name_id == "colt_1911" or self._name_id == "p226" or self._name_id == "hs2000" then
			weapon_tweak_data.animations.reload_name_id = "pistolknife"
		elseif self._name_id == "deagle" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifedeagle"
		elseif self._name_id == "pl14" or  self._name_id == "m1911" or  self._name_id == "sparrow" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifesparrow"
		else
			weapon_tweak_data.animations.reload_name_id = "pistolknifeglock"
		end
	
		weapon_tweak_data.weapon_hold = "pistolknife"
		weapon_tweak_data.animations.reload_knife_shell_data = {
			align = "left",
			unit_name = "units/pd2_dlc_gage_lmg/weapons/wpn_fps_mel_kabar/wpn_fps_mel_kabar"
		}
	end
	
	if self._parts.wpn_fps_pis_usp_knife_wing then 

		if self._name_id == "usp" or self._name_id == "colt_1911" or self._name_id == "p226" or self._name_id == "hs2000" then
			weapon_tweak_data.animations.reload_name_id = "pistolknife"
		elseif self._name_id == "deagle" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifedeagle"
		elseif self._name_id == "pl14" or  self._name_id == "m1911" or  self._name_id == "sparrow" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifesparrow"
		else
			weapon_tweak_data.animations.reload_name_id = "pistolknifeglock"
		end
	
		weapon_tweak_data.weapon_hold = "pistolknife"
		weapon_tweak_data.animations.reload_knife_shell_data = {
			align = "left",
			unit_name = "units/pd2_dlc_opera/weapons/wpn_fps_mel_wing/wpn_fps_mel_wing"
		}
	end
	
	if self._parts.wpn_fps_pis_usp_knife_km2000 then 

		if self._name_id == "usp" or self._name_id == "colt_1911" or self._name_id == "p226" or self._name_id == "hs2000" then
			weapon_tweak_data.animations.reload_name_id = "pistolknife"
		elseif self._name_id == "deagle" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifedeagle"
		elseif self._name_id == "pl14" or  self._name_id == "m1911" or  self._name_id == "sparrow" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifesparrow"
		else
			weapon_tweak_data.animations.reload_name_id = "pistolknifeglock"
		end
	
		weapon_tweak_data.weapon_hold = "pistolknife"
		weapon_tweak_data.animations.reload_knife_shell_data = {
			align = "left",
			unit_name = "units/pd2_dlc_gage_lmg/weapons/wpn_fps_mel_km2000/wpn_fps_mel_km2000"
		}
	end
	
	if self._parts.wpn_fps_pis_usp_knife_ballistic then 

		if self._name_id == "usp" or self._name_id == "colt_1911" or self._name_id == "p226" or self._name_id == "hs2000" then
			weapon_tweak_data.animations.reload_name_id = "pistolknife"
		elseif self._name_id == "deagle" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifedeagle"
		elseif self._name_id == "pl14" or  self._name_id == "m1911" or  self._name_id == "sparrow" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifesparrow"
		else
			weapon_tweak_data.animations.reload_name_id = "pistolknifeglock"
		end
	
		weapon_tweak_data.weapon_hold = "pistolknife"
		weapon_tweak_data.animations.reload_knife_shell_data = {
			align = "left",
			unit_name = "units/pd2_dlc_coco/weapons/wpn_fps_mel_ballistic/wpn_fps_mel_ballistic"
		}
	end
	
	if self._parts.wpn_fps_pis_usp_knife_switchblade then 

		if self._name_id == "usp" or self._name_id == "colt_1911" or self._name_id == "p226" or self._name_id == "hs2000" then
			weapon_tweak_data.animations.reload_name_id = "pistolknife"
		elseif self._name_id == "deagle" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifedeagle"
		elseif self._name_id == "pl14" or  self._name_id == "m1911" or  self._name_id == "sparrow" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifesparrow"
		else
			weapon_tweak_data.animations.reload_name_id = "pistolknifeglock"
		end
	
		weapon_tweak_data.weapon_hold = "pistolknife"
		weapon_tweak_data.animations.reload_knife_shell_data = {
			align = "left",
			unit_name = "units/pd2_dlc_casino/weapons/wpn_fps_mel_switchblade/wpn_fps_mel_switchblade"
		}
	end
	
	if self._parts.wpn_fps_pis_usp_knife_x46 then 

		if self._name_id == "usp" or self._name_id == "colt_1911" or self._name_id == "p226" or self._name_id == "hs2000" then
			weapon_tweak_data.animations.reload_name_id = "pistolknife"
		elseif self._name_id == "deagle" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifedeagle"
		elseif self._name_id == "pl14" or  self._name_id == "m1911" or  self._name_id == "sparrow" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifesparrow"
		else
			weapon_tweak_data.animations.reload_name_id = "pistolknifeglock"
		end
	
		weapon_tweak_data.weapon_hold = "pistolknife"
		weapon_tweak_data.animations.reload_knife_shell_data = {
			align = "left",
			unit_name = "units/pd2_dlc_gage_assault/weapons/wpn_fps_mel_x46/wpn_fps_mel_x46"
		}
	end
	
	if self._parts.wpn_fps_pis_usp_knife_chef then 

		if self._name_id == "usp" or self._name_id == "colt_1911" or self._name_id == "p226" or self._name_id == "hs2000" then
			weapon_tweak_data.animations.reload_name_id = "pistolknife"
		elseif self._name_id == "deagle" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifedeagle"
		elseif self._name_id == "pl14" or  self._name_id == "m1911" or  self._name_id == "sparrow" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifesparrow"
		else
			weapon_tweak_data.animations.reload_name_id = "pistolknifeglock"
		end
	
		weapon_tweak_data.weapon_hold = "pistolknife"
		weapon_tweak_data.animations.reload_knife_shell_data = {
			align = "left",
			unit_name = "units/pd2_halloween/weapons/wpn_fps_mel_chef/wpn_fps_mel_chef"
		}
	end
	
	if self._parts.wpn_fps_pis_usp_knife_fairbair then 

		if self._name_id == "usp" or self._name_id == "colt_1911" or self._name_id == "p226" or self._name_id == "hs2000" then
			weapon_tweak_data.animations.reload_name_id = "pistolknife"
		elseif self._name_id == "deagle" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifedeagle"
		elseif self._name_id == "pl14" or  self._name_id == "m1911" or  self._name_id == "sparrow" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifesparrow"
		else
			weapon_tweak_data.animations.reload_name_id = "pistolknifeglock"
		end
	
		weapon_tweak_data.weapon_hold = "pistolknife"
		weapon_tweak_data.animations.reload_knife_shell_data = {
			align = "left",
			unit_name = "units/pd2_dlc_gage_historical/weapons/wpn_fps_mel_fairbair/wpn_fps_mel_fairbair"
		}
	end
	
	if self._parts.wpn_fps_pis_usp_knife_aziz then 

		if self._name_id == "usp" or self._name_id == "colt_1911" or self._name_id == "p226" or self._name_id == "hs2000" then
			weapon_tweak_data.animations.reload_name_id = "pistolknife"
		elseif self._name_id == "deagle" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifedeagle"
		elseif self._name_id == "pl14" or  self._name_id == "m1911" or  self._name_id == "sparrow" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifesparrow"
		else
			weapon_tweak_data.animations.reload_name_id = "pistolknifeglock"
		end
	
		weapon_tweak_data.weapon_hold = "pistolknife"
		weapon_tweak_data.animations.reload_knife_shell_data = {
			align = "left",
			unit_name = "units/pd2_dlc_flm/weapons/wpn_fps_mel_aziz/wpn_fps_mel_aziz"
		}
	end
	
	if self._parts.wpn_fps_pis_usp_knife_toothbrush_shiv then 

		if self._name_id == "usp" or self._name_id == "colt_1911" or self._name_id == "p226" or self._name_id == "hs2000" then
			weapon_tweak_data.animations.reload_name_id = "pistolknife"
		elseif self._name_id == "deagle" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifedeagle"
		elseif self._name_id == "pl14" or  self._name_id == "m1911" or  self._name_id == "sparrow" then
			weapon_tweak_data.animations.reload_name_id = "pistolknifesparrow"
		else
			weapon_tweak_data.animations.reload_name_id = "pistolknifeglock"
		end
		
		weapon_tweak_data.weapon_hold = "pistolknife"
		weapon_tweak_data.animations.reload_knife_shell_data = {
			align = "left",
			unit_name = "units/pd2_crimefest_2014/oct27/weapons/wpn_fps_mel_toothbrush_shiv/wpn_fps_mel_toothbrush_shiv"
		}
	end

	return weapon_tweak_data
end

-- log("USP NewRaycastWeaponBase initialized")
 
function NewRaycastWeaponBase:knife_shell_data()

-- log("USP knife_shell_data called")
 
		local reload_knife_shell_data = self:weapon_tweak_data().animations.reload_knife_shell_data
			
		if reload_knife_shell_data then
			local unit_name = "units/payday2/weapons/wpn_fps_shell/wpn_fps_shell"

			if reload_knife_shell_data.unit_name then
				unit_name = reload_knife_shell_data.unit_name
			end


			local align = reload_knife_shell_data and reload_knife_shell_data.align or nil

			return {
				unit_name = unit_name,
				align = align
			}
			
		end
		
		return nil

end 
