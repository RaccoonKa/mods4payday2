--[[
	Custom Attachment Points: Legacy, Tweak Data Stuff
]]

-- This exists because the default Rotation object has some funky shit going on with it.
function RotationCAP( yaw, pitch, roll )
	local rotation_object = {
		values = {
			yaw = yaw,
			pitch = pitch,
			roll = roll
		},

		yaw = function(self) return self.values.yaw end,
		pitch = function(self) return self.values.pitch end,
		roll = function(self) return self.values.roll end
	}

	return rotation_object
end

-- Helper function for dudes.
function WeaponTweakData:SetupAttachmentPoint( id, attachment_table )
	if not ( self[id] ) then return end

	if not ( self[id].attachment_points ) then
		self[id].attachment_points = {}
	end

	table.insert( self[id].attachment_points, attachment_table )

	if self[id .. "_crew"] and ( not self[id .. "_crew"].attachment_points ) then
		self[id .. "_crew"].attachment_points = self[id].attachment_points
	end
end
