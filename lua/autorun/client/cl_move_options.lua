local function MovementSettings(pnl)
    pnl:Help("Movement Basics")

    pnl:CheckBox("Pure Jumping Enabled", "sv_kait_jump_enabled")    
    pnl:ControlHelp("pure jumping, kills bhop, strafing midair. Disable/Enable (default: enabled)")

    pnl:CheckBox("Movement Enabled", "sv_kait_enabled")
    pnl:ControlHelp("Enable or disable movement systems (default: enabled)")

    pnl:CheckBox("Water slowdown Enabled", "sv_kait_swimming")
    pnl:ControlHelp("Water slowdown and swimming Disable/Enable (default: enabled)")

    pnl:NumSlider("Running speed", "sv_kait_max_speed", 0, 1000, 0)
    pnl:ControlHelp("(default: 300)")
    pnl:NumSlider("Walking speed", "sv_kait_min_speed", 0, 1000, 0)
    pnl:ControlHelp("(default: 160)")
    pnl:NumSlider("Slow Walking speed mult", "sv_kait_min_speed_mult", 0, 1, 1)
    pnl:ControlHelp("(default: 0.6)")
    pnl:NumSlider("Side Walking speed mult", "sv_kait_min_speed_side_mult", 0, 1, 1)
    pnl:ControlHelp("(default: 1)")    
    
    pnl:NumSlider("Speed Change mult", "sv_kait_speed_change", 0, 3, 1)
    pnl:ControlHelp("Time mult it takes to get to maximum speed (default: 1)")

    pnl:Help("")
    pnl:Help("Footstep System")

    pnl:CheckBox("Footstep delay Enabled", "sv_kait_footstep_delay")
    pnl:ControlHelp("Enable or disable footstep sync (default: enabled)")

    pnl:NumSlider("Footstep delay Mult", "sv_kait_footstep_delay_mult", 0, 3, 1)
    pnl:ControlHelp("Time mult for footsteps, lower values result less time between footsteps (default: 1)")

    pnl:Help("")
    pnl:Help("Material System")

    pnl:CheckBox("Material speed Enabled", "sv_kait_material_speed_enabled")
    pnl:ControlHelp("speed mult Disable/Enable (default: enabled)")

    pnl:CheckBox("Materials speed gain Enabled", "sv_kait_material_speed_change_enabled")
    pnl:ControlHelp("speed change mult Disable/Enable (default: enabled)")

    pnl:Help("")
    pnl:Help("Jumping System")
    
    pnl:CheckBox("Jump holding Enabled", "sv_kait_jump_enabled")
    pnl:ControlHelp("Enable or disable jump system (default: enabled)")

    pnl:NumSlider("Jump Power", "sv_kait_jump_power", 0, 10, 1)
    pnl:ControlHelp("Jump power that is added with holding space while jumping, 2 or 3 recommended (default: 3)")

    pnl:NumSlider("Jump Height", "sv_kait_jump_height", 0, 500, 0)
    pnl:ControlHelp("Jump height essentially (default: 150)")

    pnl:Help("")
    pnl:Help("Ledge Stumbling")

    pnl:CheckBox("Ledge stumble Enabled", "sv_kait_stairs_stumble_enabled")
    pnl:ControlHelp("Enable or disable stumbling on ledges (default: enabled)")

    pnl:NumSlider("Ledge stumble height", "sv_kait_stairs_stumble_height", 0, 18, 1)
    pnl:ControlHelp("How tall should a ledge be to initiate stumble (default: 6 - recommended)")

    pnl:NumSlider("Ledge stumble Chance", "sv_kait_stairs_stumble_chance", 0, 100, 0)
    pnl:ControlHelp("Chance of stumbling on ledges (default: 100)")

    pnl:CheckBox("Viewpunch height Enabled", "sv_kait_viewpunch_enabled")
    pnl:ControlHelp("Enable or disable very cool but experimental connection with viewpunch and height (default: enabled)")

    pnl:NumSlider("Viewpunch Camera Mult", "sv_kait_viewpunch_mult", 0, 3, 1)
    pnl:ControlHelp("Camera move Mult (default: 1)")

    pnl:Help("")
    pnl:Help("Misc")

    pnl:NumSlider("Crouching Speed", "sv_kait_crouching_speed", 0, 1, 1)
    pnl:ControlHelp("Crouching speed, between 0 and 1 (default: 0.7)")
end

hook.Add("PopulateToolMenu", "MovementMenuAdd", function() 
    spawnmenu.AddToolMenuOption("Options", "Movement", "MovementSettings", "Settings", "", "", function(pnl)
        pnl:ClearControls()
        MovementSettings(pnl)
    end)

    spawnmenu.AddToolMenuOption("Options", "Movement", "MovementSettingsClient", "Client Settings", "", "", function(pnl)
        pnl:ClearControls()

        pnl:CheckBox("Speed HUD Enabled", "cl_kait_hud_enabled")
        pnl:ControlHelp("(default: enabled)")

        pnl:CheckBox("Switch from km/h to mp/h", "cl_kait_hud_miles")
        pnl:ControlHelp("(default: disabled)")
    end)
end)
