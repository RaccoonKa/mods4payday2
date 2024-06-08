

-- log("USP fpcameraplayerbase initialized")
 
 local _knife_shell = nil
 
function FPCameraPlayerBase:anim_clbk_spawn_knife_shell()

-- log("USP anim_clbk_spawn_knife_shell called")

		if alive(self._parent_unit) then
			local weapon = self._parent_unit:inventory():equipped_unit()

			if alive(weapon) and weapon:base().knife_shell_data then
				local knife_shell_data = weapon:base():knife_shell_data()

				if not knife_shell_data then
					return
				end

				local knife_align_obj_l_name = Idstring("a_weapon_left")
				local knife_align_obj_r_name = Idstring("a_weapon_right")
				local knife_align_obj_l = self._unit:get_object(knife_align_obj_l_name)
				local knife_align_obj_r = self._unit:get_object(knife_align_obj_r_name)
				local knife_align_obj = knife_align_obj_l

				if knife_shell_data.align and knife_shell_data.align == "right" then
					knife_align_obj = knife_align_obj_r
				end
				
				
				self._unspawn_knife_shell()

				_knife_shell = World:spawn_unit(Idstring(knife_shell_data.unit_name), knife_align_obj:position(), knife_align_obj:rotation())

				self._unit:link(knife_align_obj:name(), _knife_shell, _knife_shell:orientation_object():name())
			end
		end


end

function FPCameraPlayerBase:_unspawn_knife_shell()

--	log("USP _unspawn_knife_shell called")

		if not alive(_knife_shell) then
			return
		end

		_knife_shell:unlink()
		World:delete_unit(_knife_shell)

		_knife_shell = nil

end

function FPCameraPlayerBase:anim_clbk_unspawn_knife_shell()

--	log("USP anim_clbk_spawn_knife_shell called")

	self._unspawn_knife_shell()

end

Hooks:PostHook( FPCameraPlayerBase, "destroy", "destroyknife", function(self)
	
-- log("USP destroyknife called")
	
    self._unspawn_knife_shell()

end )