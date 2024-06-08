if not EYE_AIM_MODDED then return end
if not EYE_AIM_MODDED_ANIMATION_FILES then return end

local mrot_set_yaw_pitch_roll = mrotation.set_yaw_pitch_roll
local mrot_multiply = mrotation.multiply
local mrot_y = mrotation.y
local mrot_z = mrotation.z

local mvec_multiply = mvector3.multiply
local mvec_add = mvector3.add

local math_floor = math.floor
local math_clamp = math.clamp
local math_abs = math.abs

Hooks:PostHook(PlayerCamera, "init", "eyeAimPlayerCameraInit", function(self, unit)
	self._eyeaim_rotation = Rotation()
end)

function PlayerCamera:set_eyeaim_rotation(eyeaim_rot)
	mrot_set_yaw_pitch_roll(self._eyeaim_rotation, eyeaim_rot:yaw(), eyeaim_rot:pitch(), eyeaim_rot:roll())
end

local mvec1 = Vector3()
local eyeaim_rot = Rotation()

Hooks:PostHook(PlayerCamera, "set_rotation", "eyeAimPlayercameraSetRotation", function(self, rot)
	if not _G.IS_VR then
		mrot_set_yaw_pitch_roll(eyeaim_rot, rot:yaw(), rot:pitch(), rot:roll())
		mrot_multiply(eyeaim_rot, self._eyeaim_rotation)

		mrot_y(eyeaim_rot, mvec1)
		mvec_multiply(mvec1, 100000)
		mvec_add(mvec1, self._m_cam_pos)

		self._camera_controller:set_target(mvec1)

		mrot_z(eyeaim_rot, mvec1)

		self._camera_controller:set_default_up(mvec1)
	end
end)