local Evade = getgenv().Evade
local Library = Evade.Library
local Services = Evade.Services
local Sense = Evade.Sense
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera
local Mouse = Evade.Mouse

local Window = Library:CreateWindow({
    Title = "Evade | Arsenal",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Game = Window:AddTab("Arsenal"),
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Movement = Window:AddTab("Movement"),
    Settings = Window:AddTab("Settings")
}

local WepMods = Tabs.Game:AddLeftGroupbox("Weapon Mods")
WepMods:AddToggle("Ars_NoRecoil", { Text = "No Recoil", Default = false })
WepMods:AddToggle("Ars_NoSpread", { Text = "No Spread", Default = false })
WepMods:AddToggle("Ars_RapidFire", { Text = "Rapid Fire", Default = false })
WepMods:AddToggle("Ars_InfAmmo", { Text = "Infinite Ammo", Default = false })
WepMods:AddToggle("Ars_Rainbow", { Text = "Rainbow Gun", Default = false })

local HitboxMods = Tabs.Game:AddRightGroupbox("Hitbox Expander")
HitboxMods:AddToggle("Ars_Hitbox", { Text = "Expand Hitboxes", Default = false })
HitboxMods:AddSlider("Ars_HitboxSize", { Text = "Size", Default = 13, Min = 2, Max = 25, Rounding = 1 })
HitboxMods:AddSlider("Ars_HitboxTrans", { Text = "Transparency", Default = 0.5, Min = 0, Max = 1, Rounding = 1 })

local AimbotGroup = Tabs.Combat:AddLeftGroupbox("Aimbot Engine")
AimbotGroup:AddToggle("AimbotEnabled", { Text = "Enabled", Default = false })
AimbotGroup:AddLabel("Keybind"):AddKeyPicker("AimbotKey", { Default = "MB2", Mode = "Hold", Text = "Aim Key" })
AimbotGroup:AddDropdown("AimbotMethod", { Values = {"Camera", "Mouse", "Silent"}, Default = 1, Multi = false, Text = "Method" })
AimbotGroup:AddDropdown("TargetPart", { Values = {"Head", "HumanoidRootPart", "Torso"}, Default = 1, Multi = false, Text = "Target Part" })
AimbotGroup:AddSlider("Smoothing", { Text = "Smoothing", Default = 0.5, Min = 0.01, Max = 1, Rounding = 2 })
AimbotGroup:AddToggle("StickyAim", { Text = "Sticky Aim", Default = false })

local ChecksGroup = Tabs.Combat:AddRightGroupbox("Checks & Visuals")
ChecksGroup:AddToggle("TeamCheck", { Text = "Team Check", Default = true })
ChecksGroup:AddToggle("WallCheck", { Text = "Wall Check", Default = false })
ChecksGroup:AddToggle("DrawFOV", { Text = "Draw FOV", Default = true }):AddColorPicker("FOVColor", { Default = Color3.fromRGB(255, 255, 255) })
ChecksGroup:AddSlider("FOVRadius", { Text = "Radius", Default = 100, Min = 10, Max = 800, Rounding = 0 })

local ESPGroup = Tabs.Visuals:AddLeftGroupbox("Sense ESP")
ESPGroup:AddToggle("MasterESP", { Text = "Master Switch", Default = false }):OnChanged(function(v)
    Sense.teamSettings.enemy.enabled = v
    Sense.teamSettings.friendly.enabled = false 
    Sense.Load()
end)
ESPGroup:AddToggle("ESPBox", { Text = "Boxes", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.box = v end)
ESPGroup:AddToggle("ESPName", { Text = "Names", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.name = v end)
ESPGroup:AddToggle("ESPHealth", { Text = "Health", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.healthBar = v end)
ESPGroup:AddToggle("ESPTracer", { Text = "Tracers", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.tracer = v end)

local FlightGroup = Tabs.Movement:AddLeftGroupbox("Flight System")
FlightGroup:AddToggle("FlightEnabled", { Text = "Enable Flight", Default = false }):AddKeyPicker("FlightKey", { Default = "F", Mode = "Toggle", Text = "Toggle" })
FlightGroup:AddDropdown("FlightMode", { Values = {"LinearVelocity", "CFrame", "BodyVelocity"}, Default = 1, Multi = false, Text = "Mode" })
FlightGroup:AddSlider("FlightSpeed", { Text = "Speed", Default = 50, Min = 10, Max = 300, Rounding = 0 })

local SpeedGroup = Tabs.Movement:AddRightGroupbox("Speed Engine")
SpeedGroup:AddToggle("SpeedEnabled", { Text = "Enable Speed", Default = false })
SpeedGroup:AddDropdown("SpeedMode", { Values = {"WalkSpeed", "CFrame", "TP"}, Default = 1, Multi = false, Text = "Mode" })
SpeedGroup:AddSlider("WalkSpeed", { Text = "Factor", Default = 16, Min = 16, Max = 300, Rounding = 0 })

local MiscMove = Tabs.Movement:AddLeftGroupbox("Misc")
MiscMove:AddToggle("InfJump", { Text = "Infinite Jump", Default = false })
MiscMove:AddDropdown("NoclipMode", { Values = {"Collision", "CFrame"}, Default = 1, Text = "Noclip Mode" })
MiscMove:AddToggle("Noclip", { Text = "Noclip", Default = false })

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() 
    getgenv().EvadeLoaded = false
    Library:Unload() 
    Sense.Unload() 
end)
MenuGroup:AddLabel("Keybind"):AddKeyPicker("MenuKey", { Default = "RightShift", NoUI = true, Text = "Menu" })
Library.ToggleKeybind = Library.Options.MenuKey

Evade.ThemeManager:SetLibrary(Library)
Evade.SaveManager:SetLibrary(Library)
Evade.SaveManager:IgnoreThemeSettings()
Evade.SaveManager:SetFolder("Evade")
Evade.SaveManager:SetFolder("Evade/Arsenal")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

local LockedTarget = nil
local FOVCircle = Drawing.new("Circle"); FOVCircle.Thickness = 1; FOVCircle.NumSides = 64; FOVCircle.Filled = false; FOVCircle.Visible = false

local function IsVisible(TargetPart)
    local Origin = Camera.CFrame.Position
    local Direction = (TargetPart.Position - Origin).Unit * (TargetPart.Position - Origin).Magnitude
    local Params = RaycastParams.new()
    Params.FilterDescendantsInstances = {LocalPlayer.Character}
    Params.FilterType = Enum.RaycastFilterType.Exclude
    local Result = Services.Workspace:Raycast(Origin, Direction, Params)
    return Result == nil
end

local function GetClosestPlayer()
    local Closest = nil
    local ShortestDist = math.huge
    local MousePos = Vector2.new(Mouse.X, Mouse.Y)
    local FOV = Library.Options.FOVRadius.Value
    
    for _, Plr in pairs(Services.Players:GetPlayers()) do
        if Plr ~= LocalPlayer then
            local Char = Plr.Character
            if Char then
                if Library.Toggles.TeamCheck.Value and Plr.Team == LocalPlayer.Team then continue end
                
                local Target = Char:FindFirstChild(Library.Options.TargetPart.Value)
                if Target then
                     if not Library.Toggles.WallCheck.Value or IsVisible(Target) then
                        local Pos, OnScreen = Camera:WorldToViewportPoint(Target.Position)
                        if OnScreen then
                            local Dist = (MousePos - Vector2.new(Pos.X, Pos.Y)).Magnitude
                            if Dist < FOV and Dist < ShortestDist then
                                ShortestDist = Dist
                                Closest = Target
                            end
                        end
                     end
                end
            end
        end
    end
    return Closest
end

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if Library.Toggles.AimbotEnabled.Value and Library.Options.AimbotMethod.Value == "Silent" and (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList") then
        if LockedTarget then
            local Origin = args[1].Origin
            local Direction = (LockedTarget.Position - Origin).Unit * 1000
            args[1] = Ray.new(Origin, Direction)
            return oldNamecall(self, unpack(args))
        end
    end
    
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

task.spawn(function()
    while true do
        if Library.Toggles.Ars_NoRecoil.Value or Library.Toggles.Ars_NoSpread.Value or Library.Toggles.Ars_RapidFire.Value then
            if Services.ReplicatedStorage:FindFirstChild("Weapons") then
                for _, v in pairs(Services.ReplicatedStorage.Weapons:GetDescendants()) do
                    if Library.Toggles.Ars_NoRecoil.Value and v.Name == "RecoilControl" then v.Value = 0 end
                    if Library.Toggles.Ars_NoSpread.Value and v.Name == "MaxSpread" then v.Value = 0 end
                    if Library.Toggles.Ars_RapidFire.Value and v.Name == "Auto" then v.Value = true end
                    if Library.Toggles.Ars_RapidFire.Value and v.Name == "FireRate" then v.Value = 0.02 end
                end
            end
        end
        task.wait(2)
    end
end)

Services.RunService.RenderStepped:Connect(function()
    if Library.Toggles.DrawFOV.Value and Library.Toggles.AimbotEnabled.Value then
        FOVCircle.Visible = true
        FOVCircle.Radius = Library.Options.FOVRadius.Value
        FOVCircle.Color = Library.Options.FOVColor.Value
        FOVCircle.Position = Services.UserInputService:GetMouseLocation()
    else
        FOVCircle.Visible = false
    end

    if Library.Toggles.AimbotEnabled.Value and Library.Options.AimbotKey:GetState() then
        if Library.Toggles.StickyAim.Value and LockedTarget and LockedTarget.Parent then
        else
            LockedTarget = GetClosestPlayer()
        end
        
        if LockedTarget then
            if Library.Options.AimbotMethod.Value == "Camera" then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, LockedTarget.Position), Library.Options.Smoothing.Value)
            elseif Library.Options.AimbotMethod.Value == "Mouse" then
                local Pos = Camera:WorldToViewportPoint(LockedTarget.Position)
                mousemoverel((Pos.X - Mouse.X) * Library.Options.Smoothing.Value, ((Pos.Y + 36) - Mouse.Y) * Library.Options.Smoothing.Value)
            end
        end
    else
        LockedTarget = nil
    end

    if Library.Toggles.Ars_Hitbox.Value then
        local Size = Library.Options.Ars_HitboxSize.Value
        local Trans = Library.Options.Ars_HitboxTrans.Value
        for _, v in pairs(Services.Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Team ~= LocalPlayer.Team and v.Character then
                pcall(function()
                    for _, P in pairs({"HeadHB", "HumanoidRootPart", "RightUpperLeg", "LeftUpperLeg"}) do
                        local Part = v.Character:FindFirstChild(P)
                        if Part then Part.CanCollide = false; Part.Transparency = Trans; Part.Size = Vector3.new(Size, Size, Size) end
                    end
                end)
            end
        end
    end
    
    if Library.Toggles.Ars_InfAmmo.Value then
        pcall(function() LocalPlayer.PlayerGui.GUI.Client.Variables.ammocount.Value = 999 end)
    end
    
    if Library.Toggles.Ars_Rainbow.Value and Camera:FindFirstChild("Arms") then
         for _,v in pairs(Camera.Arms:GetDescendants()) do if v:IsA("MeshPart") then v.Color = Color3.fromHSV(tick()%5/5, 1, 1) end end
    end
end)

Services.RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end
    local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")

    if Library.Toggles.FlightEnabled.Value and Library.Options.FlightKey:GetState() and HRP then
        local Mode = Library.Options.FlightMode.Value
        local Speed = Library.Options.FlightSpeed.Value
        local Dir = Vector3.zero
        
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then Dir = Dir + Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then Dir = Dir - Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then Dir = Dir - Camera.CFrame.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then Dir = Dir + Camera.CFrame.RightVector end

        if Mode ~= "LinearVelocity" and HRP:FindFirstChild("SWFly") then HRP.SWFly:Destroy() end
        if Mode ~= "BodyVelocity" and HRP:FindFirstChild("SWBV") then HRP.SWBV:Destroy() end
        if Mode ~= "CFrame" then HRP.Anchored = false end

        if Mode == "LinearVelocity" then
            local LV = HRP:FindFirstChild("SWFly") or Instance.new("LinearVelocity", HRP); LV.Name = "SWFly"
            LV.MaxForce = 999999; LV.RelativeTo = Enum.ActuatorRelativeTo.World
            local Att = HRP:FindFirstChild("SWAtt") or Instance.new("Attachment", HRP); Att.Name = "SWAtt"; LV.Attachment0 = Att
            LV.VectorVelocity = Dir * Speed
            local BV = HRP:FindFirstChild("SWHold") or Instance.new("BodyVelocity", HRP); BV.Name = "SWHold"; BV.MaxForce = Vector3.new(0,math.huge,0); BV.Velocity = Vector3.zero
        elseif Mode == "CFrame" then
            HRP.Anchored = true
            HRP.CFrame = HRP.CFrame + (Dir * (Speed/50))
        elseif Mode == "BodyVelocity" then
            local BV = HRP:FindFirstChild("SWBV") or Instance.new("BodyVelocity", HRP); BV.Name = "SWBV"
            BV.MaxForce = Vector3.new(math.huge,math.huge,math.huge); BV.Velocity = Dir * Speed
        end
    else
        if HRP then
            if HRP:FindFirstChild("SWFly") then HRP.SWFly:Destroy() end
            if HRP:FindFirstChild("SWHold") then HRP.SWHold:Destroy() end
            if HRP:FindFirstChild("SWBV") then HRP.SWBV:Destroy() end
            if HRP:FindFirstChild("SWAtt") then HRP.SWAtt:Destroy() end
            HRP.Anchored = false
        end
    end
    
    if Library.Toggles.SpeedEnabled.Value and Hum then
        local Mode = Library.Options.SpeedMode.Value
        if Mode == "WalkSpeed" then
            Hum.WalkSpeed = Library.Options.WalkSpeed.Value
        elseif Mode == "CFrame" and HRP and Hum.MoveDirection.Magnitude > 0 then
            Hum.WalkSpeed = 16
            HRP.CFrame = HRP.CFrame + (Hum.MoveDirection * (Library.Options.WalkSpeed.Value / 100))
        elseif Mode == "TP" and HRP and Hum.MoveDirection.Magnitude > 0 then
            Hum.WalkSpeed = 16
            HRP.CFrame = HRP.CFrame * CFrame.new(0, 0, -(Library.Options.WalkSpeed.Value / 50))
        end
    else
        if Hum and Hum.WalkSpeed ~= 16 then Hum.WalkSpeed = 16 end
    end
    
    if Library.Toggles.Noclip.Value and HRP then
        if Library.Options.NoclipMode.Value == "Collision" then
            for _,v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
        elseif Library.Options.NoclipMode.Value == "CFrame" then
            if Hum.MoveDirection.Magnitude > 0 then
                HRP.CFrame = HRP.CFrame + (Hum.MoveDirection * 0.5)
            end
        end
    end
end)

Services.UserInputService.JumpRequest:Connect(function()
    if Library.Toggles.InfJump.Value and LocalPlayer.Character then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

Library:Notify("Evade | Arsenal Loaded", 5)
