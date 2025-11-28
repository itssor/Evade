local Evade = getgenv().Evade
local Library = Evade.Library
local Services = Evade.Services
local Sense = Evade.Sense
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera
local Mouse = Evade.Mouse

local Window = Library:CreateWindow({
    Title = "Evade | MM2",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Game = Window:AddTab("MM2"),
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Movement = Window:AddTab("Movement"),
    Settings = Window:AddTab("Settings")
}

local RoleBox = Tabs.Game:AddLeftGroupbox("Roles")
RoleBox:AddToggle("MM2_ESP", { Text = "Role Colors", Default = true })
RoleBox:AddToggle("MM2_ShowRoles", { Text = "Text Roles", Default = true })

local RageBox = Tabs.Game:AddRightGroupbox("Rage")
RageBox:AddToggle("MM2_KillAll", { Text = "Kill All", Default = false })
RageBox:AddToggle("MM2_Silent", { Text = "Sheriff Silent Aim", Default = false })
RageBox:AddSlider("MM2_SilentFOV", { Text = "Silent FOV", Default = 150, Min = 10, Max = 800, Rounding = 0 })
RageBox:AddToggle("MM2_DrawSilent", { Text = "Draw Silent FOV", Default = false })

local FarmGroup = Tabs.Game:AddRightGroupbox("Farming")
FarmGroup:AddToggle("MM2_GrabGun", { Text = "Auto Grab Gun", Default = true })
FarmGroup:AddToggle("MM2_CoinESP", { Text = "Coin ESP", Default = false })

local AimbotGroup = Tabs.Combat:AddLeftGroupbox("Aimbot Engine")
AimbotGroup:AddToggle("AimbotEnabled", { Text = "Enabled", Default = false })
AimbotGroup:AddLabel("Keybind"):AddKeyPicker("AimbotKey", { Default = "MB2", Mode = "Hold", Text = "Aim Key" })
AimbotGroup:AddDropdown("AimbotMethod", { Values = {"Camera", "Mouse"}, Default = 1, Multi = false, Text = "Method" })
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
    Sense.teamSettings.friendly.enabled = v 
    Sense.Load()
end)
ESPGroup:AddToggle("ESPBox", { Text = "Boxes", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.box = v; Sense.teamSettings.friendly.box = v end)
ESPGroup:AddToggle("ESPName", { Text = "Names", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.name = v; Sense.teamSettings.friendly.name = v end)
ESPGroup:AddToggle("ESPHealth", { Text = "Health", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.healthBar = v; Sense.teamSettings.friendly.healthBar = v end)
ESPGroup:AddToggle("ESPTracer", { Text = "Tracers", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.tracer = v; Sense.teamSettings.friendly.tracer = v end)

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

local FlingGroup = Tabs.Movement:AddRightGroupbox("Fling")
FlingGroup:AddToggle("FlingEnabled", { Text = "Fling Aura", Default = false }):AddKeyPicker("FlingKey", { Default = "X", Mode = "Toggle" })
FlingGroup:AddDropdown("FlingMode", { Values = {"Spin", "Loop"}, Default = 1, Text = "Method" })

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
Evade.SaveManager:SetFolder("Evade/MM2")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

local MM2Roles = {}
local LockedTarget = nil
local FOVCircle = Drawing.new("Circle"); FOVCircle.Thickness = 1; FOVCircle.NumSides = 64; FOVCircle.Filled = false; FOVCircle.Visible = false
local CustomDrawings = {}

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

local function GetRole(p)
    if p.Character then
        if p.Character:FindFirstChild("Knife") then return "Murderer" end
        if p.Character:FindFirstChild("Gun") or p.Character:FindFirstChild("Revolver") then return "Sheriff" end
    end
    if p.Backpack then
        if p.Backpack:FindFirstChild("Knife") then return "Murderer" end
        if p.Backpack:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Revolver") then return "Sheriff" end
    end
    return "Innocent"
end

local function GetMM2Target()
    local C = nil; local M = Library.Options.MM2_SilentFOV.Value
    local MP = Services.UserInputService:GetMouseLocation()
    for p, r in pairs(MM2Roles) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local MyRole = MM2Roles[LocalPlayer] or "Innocent"
            local ShouldShoot = false
            if MyRole == "Murderer" then ShouldShoot = true end
            if MyRole == "Sheriff" and r == "Murderer" then ShouldShoot = true end
            if MyRole == "Innocent" and r == "Murderer" and (LocalPlayer.Backpack:FindFirstChild("Gun") or LocalPlayer.Character:FindFirstChild("Gun")) then ShouldShoot = true end
            
            if ShouldShoot then
                local pos, vis = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if vis then
                    local d = (MP - Vector2.new(pos.X, pos.Y)).Magnitude
                    if d < M then M = d; C = p.Character.Head end
                end
            end
        end
    end
    return C
end

local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)
mt.__index = newcclosure(function(self, k)
    if k == "Hit" and self == Mouse and Library.Toggles.MM2_Silent.Value then
        local T = GetMM2Target()
        if T then return CFrame.new(T.Position) end
    end
    return oldIndex(self, k)
end)
setreadonly(mt, true)

task.spawn(function()
    while true do
        for _, v in pairs(Services.Players:GetPlayers()) do
            if v ~= LocalPlayer then MM2Roles[v] = GetRole(v) end
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        if Library.Toggles.MM2_KillAll.Value and LocalPlayer.Character then
            local K = LocalPlayer.Character:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
            if K then
                if K.Parent == LocalPlayer.Backpack then LocalPlayer.Character.Humanoid:EquipTool(K) end
                for _, T in pairs(Services.Players:GetPlayers()) do
                    if T ~= LocalPlayer and T.Character and T.Character:FindFirstChild("HumanoidRootPart") and T.Character.Humanoid.Health > 0 then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = T.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,2)
                        task.wait(0.1)
                        if LocalPlayer.Character:FindFirstChild("Knife") then LocalPlayer.Character.Knife:Activate() end
                        task.wait(0.2)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if Library.Toggles.MM2_GrabGun.Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local Drop = Services.Workspace:FindFirstChild("GunDrop")
            if Drop then LocalPlayer.Character.HumanoidRootPart.CFrame = Drop.CFrame; task.wait(0.2) end
        end
        task.wait(0.5)
    end
end)

Services.RunService.RenderStepped:Connect(function()
    if Library.Toggles.DrawFOV.Value then
        FOVCircle.Visible = true; FOVCircle.Radius = Library.Options.FOVRadius.Value
        FOVCircle.Color = Library.Options.FOVColor.Value; FOVCircle.Position = Services.UserInputService:GetMouseLocation()
    elseif Library.Toggles.MM2_DrawSilent.Value then
        FOVCircle.Visible = true; FOVCircle.Radius = Library.Options.MM2_SilentFOV.Value
        FOVCircle.Color = Color3.fromRGB(255,0,0); FOVCircle.Position = Services.UserInputService:GetMouseLocation()
    else FOVCircle.Visible = false end

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
            elseif Library.Options.AimbotMethod.Value == "Player" and LocalPlayer.Character then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position, Vector3.new(LockedTarget.Position.X, LocalPlayer.Character.HumanoidRootPart.Position.Y, LockedTarget.Position.Z))
            end
        end
    else
        LockedTarget = nil
    end

    if Library.Toggles.MM2_ESP.Value then
        for _, d in pairs(CustomDrawings) do d:Remove() end
        CustomDrawings = {}
        for p, r in pairs(MM2Roles) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local s, v = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                if v then
                    local c = Color3.fromRGB(0,255,0)
                    if r == "Murderer" then c = Color3.fromRGB(255,0,0) end
                    if r == "Sheriff" then c = Color3.fromRGB(0,0,255) end
                    
                    local b = Drawing.new("Square"); b.Visible=true; b.Color=c; b.Thickness=1; b.Filled=false
                    b.Size = Vector2.new(2000/s.Z, 3000/s.Z); b.Position = Vector2.new(s.X - b.Size.X/2, s.Y - b.Size.Y/2)
                    table.insert(CustomDrawings, b)
                    
                    if Library.Toggles.MM2_ShowRoles.Value then
                        local t = Drawing.new("Text"); t.Visible=true; t.Text=p.Name.." ["..r.."]"; t.Color=c; t.Center=true; t.Outline=true; t.Size=14
                        t.Position = Vector2.new(s.X, s.Y - b.Size.Y/2 - 15)
                        table.insert(CustomDrawings, t)
                    end
                end
            end
        end
    end
    
    if Library.Toggles.MM2_CoinESP.Value then
        local C = Services.Workspace:FindFirstChild("Normal") and Services.Workspace.Normal:FindFirstChild("CoinContainer")
        if C then
            for _, v in pairs(C:GetChildren()) do
                if v.Name == "Coin_Server" and v:FindFirstChild("Coin") then
                    local s, v = Camera:WorldToViewportPoint(v.Coin.Position)
                    if v then
                        local d = Drawing.new("Circle"); d.Visible=true; d.Radius=3; d.Filled=true; d.Color=Color3.fromRGB(255,255,0)
                        d.Position = Vector2.new(s.X, s.Y); table.insert(CustomDrawings, d)
                    end
                end
            end
        end
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
    
    if Library.Toggles.FlingEnabled.Value and Library.Options.FlingKey:GetState() and HRP then
        if Library.Options.FlingMode.Value == "Spin" then
            local AV = HRP:FindFirstChild("SWFling") or Instance.new("BodyAngularVelocity", HRP); AV.Name = "SWFling"
            AV.AngularVelocity = Vector3.new(0, 9999, 0); AV.MaxTorque = Vector3.new(0, math.huge, 0)
            for _,v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
        elseif Library.Options.FlingMode.Value == "Loop" then
            for _, P in pairs(Services.Players:GetPlayers()) do
                if P ~= LocalPlayer and P.Character and P.Character:FindFirstChild("HumanoidRootPart") then
                    HRP.CFrame = P.Character.HumanoidRootPart.CFrame
                    HRP.Velocity = Vector3.new(9000, 9000, 9000)
                    task.wait(0.1)
                end
            end
        end
    else
        if HRP:FindFirstChild("SWFling") then HRP.SWFling:Destroy() end
    end
end)

Services.UserInputService.JumpRequest:Connect(function()
    if Library.Toggles.InfJump.Value and LocalPlayer.Character then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

Library:Notify("Evade | MM2 Module Loaded", 5)
