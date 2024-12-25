local enabledCVar = nil
local minSpeedCVar = nil
local cf = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local delay = CreateConVar("sv_kait_footstep_delay_enabled", 1, cf, "Delay. (Disable/Enable)", 0, 1)
local delayMult = CreateConVar("sv_kait_footstep_delay_mult", 1, cf, "Footstep Delay mult (more is slower)")

hook.Add("PlayerStepSoundTime", "MovementRW.StepTime", function(ply, type, walking)
    if ply:GetMoveType() == MOVETYPE_LADDER then
        return
    end

    enabled = enabled or GetConVar("sv_kait_enabled")

    if !enabled:GetBool() or !delay:GetBool() then
        return
    end

    minSpeed = minSpeed or GetConVar("sv_kait_min_speed")

	local speed = ply:GetVelocity():LengthSqr()
	local perc = speed / minSpeed:GetFloat() ^ 2
    local newSpeed = math.Clamp(660 - (330 * perc * 0.75), 200, 1000) * delayMult:GetFloat()

    return newSpeed
end)