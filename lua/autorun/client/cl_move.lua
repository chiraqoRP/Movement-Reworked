local enabled = false
local stairs = false
local viewPunch = CreateClientConVar("cl_kait_viewpunch_enabled", 0, true, false, "Viewpunch changing height, originally was an addition to stumble but looks fucking sick but very specific.", 0, 1)
local viewPunchMult = CreateClientConVar("cl_kait_viewpunch_mult", 1, true, false, "Camera move mult")

hook.Add("CalcView", "MovementRW.Viewpunch", function(ply, origin, angles, fov, zNear, zFar)
    if enabled == false then
        enabled = GetConVar("sv_kait_enabled")
    end

    if stairs == false then
        stairs = GetConVar("sv_kait_stairs_stumble_enabled")
    end

    if !enabled:GetBool() or !stairs:GetBool() or !viewPunch:GetBool() then
        return
    end

    local punchAng = pGetViewPunchAngles(ply)
    local offsetZ = ply:GetViewOffset().z
    local newOffset = offsetZ - math.abs(math.max(punchAng.x, punchAng.y, punchAng.z) * viewPunchMult:GetFloat())

    origin.z = origin.z - (offsetZ - newOffset)
end)

local blur = Material("pp/blurscreen")
local boxColor = Color(0, 0, 0, 50)

local function DrawBlurRect(x, y, w, h)
    local X, Y = 0, 0

    surface.SetDrawColor(255,255,255)
    surface.SetMaterial(blur)

    for i = 1, 2 do
        blur:SetFloat("$blur", (i / 4) * (4))
        blur:Recompute()

        render.UpdateScreenEffectTexture()

        render.SetScissorRect(x, y, x + w, y + h, true)
        surface.DrawTexturedRect(X * -1, Y * -1, ScrW(), ScrH())
        render.SetScissorRect(0, 0, 0, 0, false)
    end

    draw.RoundedBox(0, x, y, w, h, boxColor)
    surface.SetDrawColor(0, 0, 0)
end

local hEnabled = CreateClientConVar("cl_kait_hud_enabled", 0, true, false, "Should the speedometer hud be shown?", 0, 1)
local miles = CreateClientConVar("cl_kait_hud_miles", 0, true, false, "Change to miles instead of kilometers.", 0, 1)
local kmFormat = "%i km/h"
local mphFormat = "%i mp/h"

hook.Add("HUDPaint", "MovementRW.DrawSpeed", function()
    if !hEnabled:GetBool() then
        return
    end

    local scrW, scrH = ScrW(), ScrH()
    local plyVelocity = LocalPlayer():GetVelocity()

    local speedKM = math.Round((0.04 * plyVelocity:Length()) * 1.60934)
    local speedStr = string.format(kmFormat, speedKM)
 
    DrawBlurRect(scrW * 0.02, scrH * 0.8, 115, 40)

    if miles:GetBool() then
        speedStr = string.format(mphFormat, math.Round(speedKM * 0.609344))
    end

    draw.DrawText(speedStr, "CloseCaption_Bold", scrW * 0.04, scrH * 0.805, color_white, TEXT_ALIGN_CENTER)
end)