-- // PRE-FLIGHT
repeat task.wait() until getgenv().Evade
local Evade = getgenv().Evade

local StartTime = tick()
repeat task.wait() until Evade.Library or (tick() - StartTime > 10)
if not Evade.Library then warn("[Evade] Library Missing"); return end

-- // IMPORTS
local Library = Evade.Library
local Services = Evade.Services
local Sense = Evade.Sense
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera
local Mouse = Evade.Mouse

-- // UI SETUP
local Window = Library:CreateWindow({
    Title = "Evade | Universal (v2.0)",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Movement = Window:AddTab("Movement"),
    Utility = Window:AddTab("Utility"),
    Settings = Window:AddTab("Settings")
}

-- // 1. COMBAT TAB
local AimbotGroup = Tabs.Combat:AddLeftGroupbox("Aimbot Engine")
AimbotGroup:AddToggle("AimbotEnabled", { Text = "Enabled", Default = false })
AimbotGroup:AddLabel("Keybind"):AddKeyPicker("AimbotKey", { Default = "MB2", Mode = "Hold", Text = "Aim Key" })
-- Added Silent to methods
AimbotGroup:AddDropdown("AimbotMethod", { Values = {"Camera", "Mouse", "Position", "Silent"}, Default = 1, Multi = false, Text = "Method" })
AimbotGroup:AddDropdown("TargetPart", { Values = {"Head", "HumanoidRootPart", "Torso"}, Default = 1, Multi = false, Text = "Target Part" })
AimbotGroup:AddSlider("Smoothing", { Text = "Smoothing", Default = 0.5, Min = 0.01, Max = 1, Rounding = 2 })
AimbotGroup:AddToggle("StickyAim", { Text = "Sticky Aim", Default = false })

local AutoGroup = Tabs.Combat:AddRightGroupbox("Automation")
AutoGroup:AddToggle("TriggerBot", { Text = "Trigger Bot", Default = false, Tooltip = "Auto shoots when aiming at enemy" })
AutoGroup:AddSlider("TriggerDelay", { Text = "Trigger Delay", Default = 0, Min = 0, Max = 500, Suffix = "ms" })
AutoGroup:AddToggle("AutoClicker", { Text = "Auto Clicker (Spam)", Default = false })

local ChecksGroup = Tabs.Combat:AddLeftGroupbox("Settings")
ChecksGroup:AddToggle("TeamCheck", { Text = "Team Check", Default = true })
ChecksGroup:AddToggle("WallCheck", { Text = "Wall Check", Default = false })
ChecksGroup:AddToggle("HitSound", { Text = "Hit Sound", Default = false })

local FovGroup = Tabs.Combat:AddRightGroupbox("FOV")
FovGroup:AddToggle("DrawFOV", { Text = "Draw FOV", Default = true }):AddColorPicker("FOVColor", { Default = Color3.fromRGB(255, 255, 255) })
FovGroup:AddSlider("FOVRadius", { Text = "Radius", Default = 100, Min = 10, Max = 800, Rounding = 0 })

-- // 2. VISUALS TAB
local ESPGroup = Tabs.Visuals:AddLeftGroupbox("ESP")
ESPGroup:AddToggle("MasterESP", { Text = "Master Switch", Default = false }):OnChanged(function(v)
    Sense.teamSettings.enemy.enabled = v
    Sense.teamSettings.friendly.enabled = v 
    Sense.Load()
end)
ESPGroup:AddToggle("ESPBox", { Text = "Boxes", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.box = v; Sense.teamSettings.friendly.box = v end)
ESPGroup:AddToggle("ESPName", { Text = "Names", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.name = v; Sense.teamSettings.friendly.name = v end)
ESPGroup:AddToggle("ESPHealth", { Text = "Health Bar", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.healthBar = v; Sense.teamSettings.friendly.healthBar = v end)
ESPGroup:AddToggle("ESPTracer", { Text = "Tracers", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.tracer = v; Sense.teamSettings.friendly.tracer = v end)
ESPGroup:AddToggle("ESPChams", { Text = "Chams (Highlight)", Default = false })
ESPGroup:AddToggle("ESPSkeleton", { Text = "Skeleton ESP", Default = false })

local WorldGroup = Tabs.Visuals:AddRightGroupbox("World")
WorldGroup:AddToggle("Fullbright", { Text = "Fullbright", Default = false })
WorldGroup:AddToggle("NoFog", { Text = "No Fog", Default = false })
WorldGroup:AddToggle("Crosshair", { Text = "Custom Crosshair", Default = false }):AddColorPicker("CrosshairColor", { Default = Color3.fromRGB(0, 255, 0) })

-- // 3. MOVEMENT TAB
local FlightGroup = Tabs.Movement:AddLeftGroupbox("Flight")
FlightGroup:AddToggle("FlightEnabled", { Text = "Enable Flight", Default = false }):AddKeyPicker("FlightKey", { Default = "F", Mode = "Toggle", Text = "Toggle" })
FlightGroup:AddDropdown("FlightMode", { Values = {"LinearVelocity", "CFrame", "BodyVelocity"}, Default = 1, Multi = false, Text = "Mode" })
FlightGroup:AddSlider("FlightSpeed", { Text = "Speed", Default = 50, Min = 10, Max = 300, Rounding = 0 })

local SpeedGroup = Tabs.Movement:AddRightGroupbox("Speed")
SpeedGroup:AddToggle("SpeedEnabled", { Text = "Enable Speed", Default = false })
SpeedGroup:AddDropdown("SpeedMode", { Values = {"WalkSpeed", "CFrame", "TP"}, Default = 1, Multi = false, Text = "Mode" })
SpeedGroup:AddSlider("WalkSpeed", { Text = "Factor", Default = 16, Min = 16, Max = 300, Rounding = 0 })

local MiscMove = Tabs.Movement:AddLeftGroupbox("Misc")
MiscMove:AddToggle("InfJump", { Text = "Infinite Jump", Default = false })
MiscMove:AddToggle("Noclip", { Text = "Noclip", Default = false })
MiscMove:AddToggle("Spider", { Text = "Spider (Wallclimb)", Default = false })
MiscMove:AddToggle("Bhop", { Text = "Bunny Hop", Default = false })

local TPGroup = Tabs.Movement:AddRightGroupbox("Teleport")
TPGroup:AddToggle("ClickTP", { Text = "Ctrl + Click TP", Default = false })
TPGroup:AddToggle("SpinBot", { Text = "Spinbot", Default = false })
TPGroup:AddSlider("SpinSpeed", { Text = "Spin Speed", Default = 20, Min = 1, Max = 100 })

-- // 4. UTILITY TAB
local ServerGroup = Tabs.Utility:AddLeftGroupbox("Server")
ServerGroup:AddButton("Rejoin Server", function() Services.TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
ServerGroup:AddButton("Server Hop", function() 
    -- Simple Hop Logic
    local Http = game:GetService("HttpService")
    local Servers = Http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    for _, v in pairs(Servers.data) do
        if v.playing < v.maxPlayers then
            Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, LocalPlayer)
            break
        end
    end
end)

local FPSGroup = Tabs.Utility:AddRightGroupbox("Performance")
FPSGroup:AddButton("FPS Booster", function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") then
            v.Material = Enum.Material.SmoothPlastic
            if v:IsA("Texture") or v:IsA("Decal") then v:Destroy() end
        end
    end
end)
FPSGroup:AddToggle("AntiAFK", { Text = "Anti-AFK", Default = true })

-- // LOGIC: AIMBOT & SILENT
local LockedTarget = nil
local FOVCircle = Drawing.new("Circle"); FOVCircle.Thickness=1; FOVCircle.NumSides=64; FOVCircle.Filled=false; FOVCircle.Visible=false

local function IsVisible(TargetPart)
    local Origin = Camera.CFrame.Position
    local Direction = (TargetPart.Position - Origin).Unit * (TargetPart.Position - Origin).Magnitude
    local Params = RaycastParams.new()
    Params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    Params.FilterType = Enum.RaycastFilterType.Exclude
    local Result = Services.Workspace:Raycast(Origin, Direction, Params)
    return Result == nil
end

local function GetClosestPlayer()
    local Closest = nil; local ShortestDist = math.huge
    local MousePos = Services.UserInputService:GetMouseLocation()
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

-- Silent Aim Hook
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if Library.Toggles.AimbotEnabled.Value and Library.Options.AimbotMethod.Value == "Silent" and not checkcaller() then
        if method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay" or method == "Raycast" then
            local Target = GetClosestPlayer()
            if Target then
                if method == "Raycast" then
                    local Origin = args[1]
                    local Direction = (Target.Position - Origin).Unit * 1000
                    args[2] = Direction
                else
                    local Origin = args[1].Origin
                    local Direction = (Target.Position - Origin).Unit * 1000
                    args[1] = Ray.new(Origin, Direction)
                end
                return oldNamecall(self, unpack(args))
            end
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- // LOGIC: TRIGGER BOT & AUTO CLICKER
task.spawn(function()
    while true do
        if Library.Toggles.TriggerBot.Value then
            local Target = Mouse.Target
            if Target and Target.Parent then
                local P = Services.Players:GetPlayerFromCharacter(Target.Parent)
                if P and (not Library.Toggles.TeamCheck.Value or P.Team ~= LocalPlayer.Team) then
                    task.wait(Library.Options.TriggerDelay.Value / 1000)
                    mouse1click()
                    task.wait(0.1)
                end
            end
        end
        if Library.Toggles.AutoClicker.Value then
            mouse1click()
        end
        task.wait(0.05)
    end
end)

-- // LOGIC: VISUALS (Skeleton & Chams)
local Skeletons = {}
local Chams = {}

local function DrawLine()
    local L = Drawing.new("Line"); L.Visible = false; L.Color = Color3.new(1,1,1); L.Thickness = 1
    return L
end

Services.RunService.RenderStepped:Connect(function()
    -- FOV
    if Library.Toggles.DrawFOV.Value and Library.Toggles.AimbotEnabled.Value then
        FOVCircle.Visible = true; FOVCircle.Radius = Library.Options.FOVRadius.Value; FOVCircle.Color = Library.Options.FOVColor.Value; FOVCircle.Position = Services.UserInputService:GetMouseLocation()
    else FOVCircle.Visible = false end
    
    -- Aimbot Calc
    if Library.Toggles.AimbotEnabled.Value and Library.Options.AimbotKey:GetState() then
        if not (Library.Toggles.StickyAim.Value and LockedTarget) then LockedTarget = GetClosestPlayer() end
        if LockedTarget then
            local Method = Library.Options.AimbotMethod.Value
            if Method == "Camera" then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, LockedTarget.Position), Library.Options.Smoothing.Value)
            elseif Method == "Mouse" then
                local Pos = Camera:WorldToViewportPoint(LockedTarget.Position)
                mousemoverel((Pos.X - Mouse.X)*Library.Options.Smoothing.Value, ((Pos.Y+36)-Mouse.Y)*Library.Options.Smoothing.Value)
            elseif Method == "Position" and LocalPlayer.Character then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position, Vector3.new(LockedTarget.Position.X, LocalPlayer.Character.HumanoidRootPart.Position.Y, LockedTarget.Position.Z))
            end
        end
    else LockedTarget = nil end

    -- Skeleton ESP
    for _, v in pairs(Skeletons) do for _, l in pairs(v) do l:Remove() end end
    Skeletons = {}
    
    if Library.Toggles.ESPSkeleton.Value then
        for _, p in pairs(Services.Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local Char = p.Character
                local function Line(p1, p2)
                    local L = DrawLine()
                    local Pos1, Vis1 = Camera:WorldToViewportPoint(p1.Position)
                    local Pos2, Vis2 = Camera:WorldToViewportPoint(p2.Position)
                    if Vis1 and Vis2 then
                        L.From = Vector2.new(Pos1.X, Pos1.Y); L.To = Vector2.new(Pos2.X, Pos2.Y); L.Visible = true
                        if not Skeletons[p] then Skeletons[p] = {} end
                        table.insert(Skeletons[p], L)
                    else L:Remove() end
                end
                
                -- R15 Logic
                if Char:FindFirstChild("UpperTorso") then
                    Line(Char.Head, Char.UpperTorso)
                    Line(Char.UpperTorso, Char.LowerTorso)
                    Line(Char.UpperTorso, Char.LeftUpperArm); Line(Char.LeftUpperArm, Char.LeftLowerArm); Line(Char.LeftLowerArm, Char.LeftHand)
                    Line(Char.UpperTorso, Char.RightUpperArm); Line(Char.RightUpperArm, Char.RightLowerArm); Line(Char.RightLowerArm, Char.RightHand)
                    Line(Char.LowerTorso, Char.LeftUpperLeg); Line(Char.LeftUpperLeg, Char.LeftLowerLeg); Line(Char.LeftLowerLeg, Char.LeftFoot)
                    Line(Char.LowerTorso, Char.RightUpperLeg); Line(Char.RightUpperLeg, Char.RightLowerLeg); Line(Char.RightLowerLeg, Char.RightFoot)
                -- R6 Logic
                elseif Char:FindFirstChild("Torso") then
                    Line(Char.Head, Char.Torso)
                    Line(Char.Torso, Char["Left Arm"]); Line(Char.Torso, Char["Right Arm"])
                    Line(Char.Torso, Char["Left Leg"]); Line(Char.Torso, Char["Right Leg"])
                end
            end
        end
    end
    
    -- Chams
    if Library.Toggles.ESPChams.Value then
        for _, p in pairs(Services.Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                if not p.Character:FindFirstChild("EvadeCham") then
                    local H = Instance.new("Highlight", p.Character)
                    H.Name = "EvadeCham"; H.FillColor = Color3.new(1,0,0); H.OutlineColor = Color3.new(1,1,1); H.FillTransparency = 0.5
                end
            end
        end
    else
        for _, p in pairs(Services.Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("EvadeCham") then p.Character.EvadeCham:Destroy() end
        end
    end

    -- Fullbright
    if Library.Toggles.Fullbright.Value then
        Services.Lighting.Brightness = 2; Services.Lighting.ClockTime = 14; Services.Lighting.FogEnd = 100000
    end
end)

-- // PHYSICS & MISC LOOP
Services.RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end
    local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")

    -- Click TP
    if Library.Toggles.ClickTP.Value and Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and HRP then
        local MousePos = Mouse.Hit.p
        HRP.CFrame = CFrame.new(MousePos + Vector3.new(0, 3, 0))
        task.wait(0.1) -- Anti-Crash
    end

    -- Spider (Wallclimb)
    if Library.Toggles.Spider.Value and HRP then
        local Ray = Ray.new(HRP.Position, HRP.CFrame.LookVector * 2)
        local Part = workspace:FindPartOnRay(Ray, LocalPlayer.Character)
        if Part and Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then
            HRP.Velocity = Vector3.new(HRP.Velocity.X, 30, HRP.Velocity.Z)
        end
    end

    -- Bhop
    if Library.Toggles.Bhop.Value and Hum and Hum.FloorMaterial ~= Enum.Material.Air then
        Hum:ChangeState("Jumping")
    end
    
    -- Spinbot
    if Library.Toggles.SpinBot.Value and HRP then
        HRP.CFrame = HRP.CFrame * CFrame.Angles(0, math.rad(Library.Options.SpinSpeed.Value), 0)
    end
    
    -- Flight & Speed (Same as previous versions)
    if Library.Toggles.FlightEnabled.Value and Library.Options.FlightKey:GetState() and HRP then
        local Mode = Library.Options.FlightMode.Value
        local Speed = Library.Options.FlightSpeed.Value
        local Dir = Vector3.zero
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then Dir = Dir + Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then Dir = Dir - Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then Dir = Dir - Camera.CFrame.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then Dir = Dir + Camera.CFrame.RightVector end
        if Mode == "LinearVelocity" then
            local LV = HRP:FindFirstChild("SWFly") or Instance.new("LinearVelocity", HRP); LV.Name = "SWFly"; LV.MaxForce = 999999; LV.RelativeTo = Enum.ActuatorRelativeTo.World; local Att = HRP:FindFirstChild("SWAtt") or Instance.new("Attachment", HRP); Att.Name = "SWAtt"; LV.Attachment0 = Att
            LV.VectorVelocity = Dir * Speed
            local BV = HRP:FindFirstChild("SWHold") or Instance.new("BodyVelocity", HRP); BV.Name = "SWHold"; BV.MaxForce = Vector3.new(0,math.huge,0); BV.Velocity = Vector3.zero
        elseif Mode == "CFrame" then
            HRP.Anchored = true; HRP.CFrame = HRP.CFrame + (Dir * (Speed/50))
        elseif Mode == "BodyVelocity" then
            local BV = HRP:FindFirstChild("SWBV") or Instance.new("BodyVelocity", HRP); BV.Name = "SWBV"; BV.MaxForce = Vector3.new(math.huge,math.huge,math.huge); BV.Velocity = Dir * Speed
        end
    else
        if HRP then
            if HRP:FindFirstChild("SWFly") then HRP.SWFly:Destroy() end; if HRP:FindFirstChild("SWHold") then HRP.SWHold:Destroy() end; if HRP:FindFirstChild("SWBV") then HRP.SWBV:Destroy() end; if HRP:FindFirstChild("SWAtt") then HRP.SWAtt:Destroy() end; HRP.Anchored = false
        end
    end
    
    if Library.Toggles.SpeedEnabled.Value and Hum then
        local Mode = Library.Options.SpeedMode.Value
        if Mode == "WalkSpeed" then Hum.WalkSpeed = Library.Options.WalkSpeed.Value
        elseif Mode == "CFrame" and HRP and Hum.MoveDirection.Magnitude > 0 then Hum.WalkSpeed = 16; HRP.CFrame = HRP.CFrame + (Hum.MoveDirection * (Library.Options.WalkSpeed.Value / 100))
        elseif Mode == "TP" and HRP and Hum.MoveDirection.Magnitude > 0 then Hum.WalkSpeed = 16; HRP.CFrame = HRP.CFrame * CFrame.new(0, 0, -(Library.Options.WalkSpeed.Value / 50)) end
    else if Hum and Hum.WalkSpeed ~= 16 then Hum.WalkSpeed = 16 end end
    
    if Library.Toggles.Noclip.Value and HRP then
        if Library.Options.NoclipMode.Value == "Collision" then for _,v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
        elseif Library.Options.NoclipMode.Value == "CFrame" and Hum.MoveDirection.Magnitude > 0 then HRP.CFrame = HRP.CFrame + (Hum.MoveDirection * 0.5) end
    end
end)

-- Anti AFK
LocalPlayer.Idled:Connect(function()
    if Library.Toggles.AntiAFK.Value then
        Services.VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        Services.VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

-- // SETTINGS
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() getgenv().EvadeLoaded = false; Library:Unload(); Sense.Unload() end)
MenuGroup:AddLabel("Keybind"):AddKeyPicker("MenuKey", { Default = "RightShift", NoUI = true, Text = "Menu" })
Library.ToggleKeybind = Library.Options.MenuKey

Evade.ThemeManager:SetLibrary(Library)
Evade.SaveManager:SetLibrary(Library)
Evade.SaveManager:IgnoreThemeSettings()
Evade.SaveManager:SetFolder("Evade")
Evade.SaveManager:SetFolder("Evade/Universal")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

Library:Notify("Evade | Universal Loaded", 5)
