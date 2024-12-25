local ENTITY = FindMetaTable("Entity")
local PLAYER = FindMetaTable("Player")
local eGetNW2Bool, eSetNW2Bool = ENTITY.GetNW2Bool, ENTITY.SetNW2Bool
local eGetNW2Float, eSetNW2Float = ENTITY.GetNW2Float, ENTITY.SetNW2Float

function PLAYER:GetNewSpeed()
    return eGetNW2Float(self, "kait_new_speed")
end

function PLAYER:GetNewSpeedLerp()
    return eGetNW2Float(self, "kait_new_speed_lerp")
end

function PLAYER:GetLerpTime()
    return eGetNW2Float(self, "kait_lerptime")
end

function PLAYER:GetCrouchSpeed()
    return eGetNW2Float(self, "kait_crouch_speed")
end

function PLAYER:GetCrouchSpeedLerp()
    return eGetNW2Float(self, "kait_crouch_speed_lerp")
end

function PLAYER:GetOldZ()
    return eGetNW2Float(self, "kait_old_z")
end

function PLAYER:GetInAir()
    return eGetNW2Bool(self, "kait_in_air")
end

hook.Add("PlayerSpawn", "MovementReworked_Initialize", function(ply)
    if !IsValid(ply) then
        return
    end

    eSetNW2Float(ply, "kait_new_speed", 170)
    eSetNW2Float(ply, "kait_new_speed_lerp", 170)
    eSetNW2Float(ply, "kait_lerptime", 0.1)
    eSetNW2Float(ply, "kait_crouch_speed", 0.3)
    eSetNW2Float(ply, "kait_crouch_speed_lerp", 0.3)
    eSetNW2Float(ply, "kait_old_z", 0)
    eSetNW2Bool(ply, "kait_in_air", 0)

    -- Completely static, no need to constantly set in SetupMove
    ply:SetLadderClimbSpeed(100)
end)

local pGetWalkSpeed = PLAYER.GetWalkSpeed
local pGetSlowWalkSpeed = PLAYER.GetSlowWalkSpeed
local eIsFlagSet = ENTITY.IsFlagSet
local pSetCrouchedWalkSpeed = PLAYER.SetCrouchedWalkSpeed
local pSetDuckSpeed = PLAYER.SetDuckSpeed
local pSetUnDuckSpeed = PLAYER.SetUnDuckSpeed
local pSetSlowWalkSpeed = PLAYER.SetSlowWalkSpeed
local pSetWalkSpeed = PLAYER.SetWalkSpeed
local pSetRunSpeed = PLAYER.SetRunSpeed
local eWaterLevel = ENTITY.WaterLevel
local pIsSprinting = PLAYER.IsSprinting
local eGetMoveType = ENTITY.GetMoveType
local pGetViewPunchAngles = PLAYER.GetViewPunchAngles
local pSetJumpPower = PLAYER.SetJumpPower
local cf = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local enabled = CreateConVar("sv_kait_enabled", 1, cf, "Movement. (Disable/Enable)")
local minSpeed = CreateConVar("sv_kait_min_speed", 160, cf, "Minimum speed - default walk.")
local maxSpeed = CreateConVar("sv_kait_max_speed", 300, cf, "Maximum sprint speed.")
local minSpeedMult = CreateConVar("sv_kait_min_speed_mult", 0.6, cf, "Slow walk multiplier from minimum speed.")
local minSpeedSideMult = CreateConVar("sv_kait_min_speed_side_mult", 1, cf, "Walk speed multiplier from minimum speed while you are in side movement or backwards.")
local crouchSpeed = CreateConVar("sv_kait_crouching_speed", 0.7, cf, "Crouching speed (0-1)", 0, 1)
local jumpEnabled = CreateConVar("sv_kait_jump_enabled", 1, cf, "Enable the jump system.", 0, 1)
local jumpHeight = CreateConVar("sv_kait_jump_height", 150, cf, "Jump height, essentially.")
local jumpPower = CreateConVar("sv_kait_jump_power", 3, cf, "Jump power that is added with holding space while jumping, 2 or 3 recommended", 0, 5)
local speedLerp = CreateConVar("sv_kait_speed_change", 1, cf, "Time mult it takes to get to maximum speed.")
local swimming = CreateConVar("sv_kait_swimming", 1, cf, "Water slowdown and swimming. (Disable/Enable)", 0, 1)
local antiBhop = CreateConVar("sv_kait_antibhop", 1, cf, "Kill or give mercy to bhop and jump strafing")
local matSpeed = CreateConVar("sv_kait_material_speed_enabled", 1, cf, "Material speed mult. (Disable/Enable)", 0, 1)
local matChange = CreateConVar("sv_kait_material_speed_change_enabled", 1, cf, "Material speed change mult. (Disable/Enable)")
local stairs = CreateConVar("sv_kait_stairs_stumble_enabled", 0, cf, "Stumble on fucking stairs while running (COF style).", 0, 1)
local stairsHeight = CreateConVar("sv_kait_stairs_stumble_height", 6, cf, "How tall should a ledge be to stumble?")
local stairsChance = CreateConVar("sv_kait_stairs_stumble_chance", 100, cf, "Chance of stumbling.", 0, 100)
local cStamina = nil
local endAddPos = Vector(0, 0, -20)
local stumbleFormat = "movement/stumble_0%i.ogg"
local materialSpeeds = {
    [MAT_DIRT] = 0.8,
    [MAT_FLESH] = 0.8,
    [MAT_SNOW] = 0.7,
    [MAT_SAND] = 0.8,
    [MAT_SLOSH] = 0.7,
    [MAT_GRASS] = 0.9,
}

hook.Add("SetupMove", "MovementRW.DoMove", function(ply, mv, cmd)
    if !enabled:GetBool() or (prone and ply:IsProne()) then
        return
    end

    local originalSpeed = cmd:KeyDown(IN_SPEED) and maxSpeed:GetFloat() * 1.5
                          or cmd:KeyDown(IN_WALK) and pGetSlowWalkSpeed(ply)
                          or pGetWalkSpeed(ply)

    local speedMul = math.Round(mv:GetMaxClientSpeed() / originalSpeed, 4)
    local onGround = eIsFlagSet(ply, FL_ONGROUND)
    local velocity = mv:GetVelocity()
    local velLength = velocity:Length()

    if onGround and eGetNW2Bool(ply, "kait_in_air") then
        eSetNW2Bool(ply, "kait_in_air", false)
        eSetNW2Float(ply, "kait_new_speed_lerp", eGetNW2Float(ply, "kait_new_speed_lerp") + velLength / 3)
    end

    local plyPos = mv:GetOrigin()
    local tr = util.TraceLine({
        start = plyPos,
        endpos = plyPos + endAddPos,
        mask = MASK_PLAYERSOLID_BRUSHONLY
    })

    --- Set speeds
    local newSpeedLerp = eGetNW2Float(ply, "kait_new_speed_lerp")

    mv:SetMaxClientSpeed(newSpeedLerp * speedMul)
    mv:SetMaxSpeed(newSpeedLerp * speedMul)
    pSetCrouchedWalkSpeed(ply, eGetNW2Float(ply, "kait_crouch_speed_lerp"))

    if cStamina == false then
        cStamina = GetConVar("sv_crouch_stamina")
    end

    if !cStamina or !cStamina:GetBool() then
        pSetDuckSpeed(ply, crouchSpeed:GetFloat())
        pSetUnDuckSpeed(ply, crouchSpeed:GetFloat())
    end

    pSetSlowWalkSpeed(ply, minSpeed:GetFloat() * minSpeedMult:GetFloat())
    pSetWalkSpeed(ply, minSpeed:GetFloat())
    pSetRunSpeed(ply, maxSpeed:GetFloat() * 1.5)

    --- Modify speed
    local waterLevel = eWaterLevel(ply)
    local isSprinting = pIsSprinting(ply)
    local inWater = waterLevel >= 1
    local isWalking, isCrouching = cmd:KeyDown(IN_WALK), cmd:KeyDown(IN_DUCK)

    if !isCrouching then
        if isSprinting and cmd:GetForwardMove() > 0 and (onGround or inWater) then
            eSetNW2Float(ply, "kait_new_speed", maxSpeed:GetFloat())
            eSetNW2Float(ply, "kait_lerptime", 0.003 * speedLerp:GetFloat())
        elseif !isWalking and (cmd:GetForwardMove() > 0) and (onGround or inWater) then
            eSetNW2Float(ply, "kait_new_speed", minSpeed:GetFloat())
            eSetNW2Float(ply, "kait_lerptime", 0.01)
        elseif !isWalking and (!(cmd:GetSideMove() == 0) or (cmd:GetForwardMove() < 0)) and (onGround or inWater) then
            eSetNW2Float(ply, "kait_new_speed", minSpeed:GetFloat() * minSpeedSideMult:GetFloat())
            eSetNW2Float(ply, "kait_lerptime", 0.01)
        elseif isWalking and (onGround or inWater) and (!(cmd:GetForwardMove() == 0) or cmd:GetSideMove() != 0) then
            eSetNW2Float(ply, "kait_new_speed", minSpeed:GetFloat() * minSpeedMult:GetFloat())
            eSetNW2Float(ply, "kait_lerptime", 0.02)
        elseif !antiBhop:GetBool() then
            eSetNW2Float(ply, "kait_new_speed", minSpeed:GetFloat())
            eSetNW2Float(ply, "kait_lerptime", 0.05)
        else
            eSetNW2Float(ply, "kait_new_speed", 30)
            eSetNW2Float(ply, "kait_lerptime", 0.05)
        end
    end

    ----------------------- fucking stairs system
    local oldZ = eGetNW2Float(ply, "kait_old_z")
    local stairRoll = util.SharedRandom("StairStumble", 0, 100)

    if stairs:GetBool() and onGround and isSprinting and stairRoll < stairsChance:GetFloat() and ((plyPos.z - oldZ) > stairsHeight:GetFloat()) and eGetMoveType(ply) != MOVETYPE_NOCLIP then
        eSetNW2Float(ply, "kait_new_speed_lerp", 0)

        local punchRoll = util.SharedRandom("StumblePunch", -2, 2)

        ply:ViewPunch(Angle(velLength * 0.02, 0, punchRoll))

        if SERVER then
            local soundRoll = math.random(1, 5)

            ply:EmitSound(string.format(stumbleFormat, soundRoll), 75, math.random(90, 110), 1, CHAN_AUTO)
        end
    end

    -- Slope system
    if plyPos.z > oldZ then
        eSetNW2Float(ply, "kait_new_speed", eGetNW2Float(ply, "kait_new_speed") * (1.1 - math.max(math.abs(tr.HitNormal.x), math.abs(tr.HitNormal.y))))
    elseif plyPos.z < oldZ then
        eSetNW2Float(ply, "kait_new_speed", eGetNW2Float(ply, "kait_new_speed") * (0.9 + math.max(math.abs(tr.HitNormal.x), math.abs(tr.HitNormal.y))))
        eSetNW2Float(ply, "kait_new_speed_lerp", eGetNW2Float(ply, "kait_new_speed_lerp") + (velLength / 300) * math.max(math.abs(tr.HitNormal.x), math.abs(tr.HitNormal.y)))
    end

    ----------------------- water system
    if inWater and swimming:GetBool() then
        mv:SetUpSpeed(-5)
        cmd:SetUpMove(-5)

        eSetNW2Float(ply, "kait_new_speed", eGetNW2Float(ply, "kait_new_speed") * (10 - waterLevel * 1.5) * 0.1)
    end

    ----------------------- ducking speed
    if isCrouching then
        if cmd:KeyDown(IN_SPEED) and cmd:KeyDown(IN_FORWARD) and onGround and velLength >= 30 then
            eSetNW2Float(ply, "kait_new_speed", minSpeed:GetFloat() * 0.7)
            eSetNW2Float(ply, "kait_crouch_speed", 0.7)
            eSetNW2Float(ply, "kait_lerptime", 0.005)
        else
            eSetNW2Float(ply, "kait_new_speed", minSpeed:GetFloat() * 0.5)
            eSetNW2Float(ply, "kait_crouch_speed", 0.5)
            eSetNW2Float(ply, "kait_lerptime", 0.05)
        end
    end

    if waterLevel > 0 and waterLevel <= 2 and !onGround then
        local newButtons = bit.band(mv:GetButtons(), bit.bnot(IN_JUMP))

        mv:SetButtons(newButtons)
    end

    ----------------------- material speeds
    if matChange:GetBool() then
        local mSpeedMul = materialSpeeds[tr.MatType] or 1

        eSetNW2Float(ply, "kait_new_speed", eGetNW2Float(ply, "kait_new_speed") * (mSpeedMul or 1))

        if matSpeed:GetBool() then
            eSetNW2Float(ply, "kait_lerptime", eGetNW2Float(ply, "kait_lerptime") * (mSpeedMul or 1))
        end
    end

    -----------------------lerps
    local flCrouchSpeed = eGetNW2Float(ply, "kait_crouch_speed")

    eSetNW2Float(ply, "kait_crouch_speed_lerp", Lerp(math.ease.OutExpo(0.002 / flCrouchSpeed), eGetNW2Float(ply, "kait_crouch_speed_lerp"), flCrouchSpeed))
    eSetNW2Float(ply, "kait_new_speed_lerp", Lerp(math.ease.OutExpo(eGetNW2Float(ply, "kait_lerptime")), eGetNW2Float(ply, "kait_new_speed_lerp"), eGetNW2Float(ply, "kait_new_speed")))

    -----------------------old z 
    eSetNW2Float(ply, "kait_old_z", plyPos.z)

    if !onGround then
        eSetNW2Bool(ply, "kait_in_air", true)
    end

    if jumpEnabled:GetBool() then
        pSetJumpPower(ply, jumpHeight:GetFloat())

        if cmd:KeyDown(IN_JUMP) and !onGround and velocity.z > 0 then
            local jumpVel = mv:GetVelocity()
            jumpVel.z = jumpVel.z + jumpPower:GetFloat()

            mv:SetVelocity(jumpVel)
        end
    end
end)