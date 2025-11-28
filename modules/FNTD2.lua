local Evade = getgenv().Evade
local Library = Evade.Library
local Services = Evade.Services
local Sense = Evade.Sense
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera
local Mouse = Evade.Mouse

local Window = Library:CreateWindow({
    Title = "Evade | FNTD",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Game = Window:AddTab("FNTD"),
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Movement = Window:AddTab("Movement"),
    Settings = Window:AddTab("Settings")
}

local Farm = Tabs.Game:AddLeftGroupbox('Macro Setup')
Farm:AddInput('MacroX', { Default = '1046', Text = 'Pos X', Numeric = true })
Farm:AddInput('MacroY', { Default = '13', Text = 'Pos Y', Numeric = true })
Farm:AddInput('MacroZ', { Default = '-821', Text = 'Pos Z', Numeric = true })

Farm:AddButton('Grab Current Position', function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local Pos = LocalPlayer.Character.HumanoidRootPart.Position
        Library.Options.MacroX:SetValue(tostring(math.floor(Pos.X)))
        Library.Options.MacroY:SetValue(tostring(math.floor(Pos.Y)))
        Library.Options.MacroZ:SetValue(tostring(math.floor(Pos.Z)))
        Library:Notify("Coords Updated", 3)
    end
end)

Farm:AddToggle('Recorder', { Text = 'Record Placements', Default = false, Tooltip = 'Auto-fills slots when you place units' })
Farm:AddToggle('FNTD_AutoFarm', { Text = 'Enable Macro', Default = false })
Farm:AddToggle('AutoRejoin', { Text = 'Reload on Teleport', Default = true })

LocalPlayer.OnTeleport:Connect(function(State)
    if Library.Toggles.AutoRejoin.Value and queue_on_teleport then
        queue_on_teleport(string.format([[repeat task.wait() until game:IsLoaded(); pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/milkisbetter/Evade/main/Loader.lua"))() end)]]))
    end
end)

local SlotsGroup = Tabs.Game:AddRightGroupbox('Unit Loadout')
for i = 1, 6 do
    SlotsGroup:AddLabel("Unit " .. i)
    SlotsGroup:AddInput('GUID'..i, { Default = '', Text = 'GUID', Placeholder = 'Waiting...' })
    SlotsGroup:AddSlider('Prio'..i, { Text = 'Priority', Default = i, Min = 1, Max = 6, Rounding = 0 })
    SlotsGroup:AddDivider()
end

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
Evade.SaveManager:SetFolder("Evade/FNTD")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if method == "FireServer" and string.find(self.Name, "PlaceUnit") and Library.Toggles.Recorder.Value then
        for _, arg in pairs(args) do
            if type(arg) == "table" and rawget(arg, "UnitGUID") then
                local DetectedID = arg.UnitGUID
                local isDuplicate = false
                for i = 1, 6 do
                    if Library.Options["GUID"..i].Value == DetectedID then isDuplicate = true; break end
                end
                
                if not isDuplicate then
                    for i = 1, 6 do
                        local Opt = Library.Options["GUID"..i]
                        if Opt.Value == "" then
                            Opt:SetValue(DetectedID)
                            Library:Notify("Saved to Slot " .. i, 3)
                            break
                        end
                    end
                end
            end
        end
    end
    return oldNamecall(self, unpack(args))
end)
setreadonly(mt, true)

task.spawn(function()
    while true do
        if Library.Toggles.FNTD_AutoFarm.Value then
            local Shared = Services.ReplicatedStorage:FindFirstChild("Shared")
            local Net = nil
            if Shared and Shared:FindFirstChild("Packages") then
                 local Index = Shared.Packages:FindFirstChild("_Index")
                 if Index then
                     for _, c in ipairs(Index:GetChildren()) do
                        if c.Name:match("^sleitnick_net@") then Net = c:FindFirstChild("net"); break end
                     end
                 end
            end

            if Net then
                local Place = Net:FindFirstChild("RE/PlaceUnit")
                local Upg = Net:FindFirstChild("RE/UpgradeAll")
                local Spd = Net:FindFirstChild("RE/UpdateGameSpeed")
                local Vote = Net:FindFirstChild("RE/VoteEvent") 
                
                if Place then 
                    local X = tonumber(Library.Options.MacroX.Value) or 1046
                    local Y = tonumber(Library.Options.MacroY.Value) or 13
                    local Z = tonumber(Library.Options.MacroZ.Value) or -821
                    local TargetCF = CFrame.new(X, Y, Z)
                    
                    local UnitsToPlace = {}
                    for i = 1, 6 do
                        local ID = Library.Options["GUID"..i].Value
                        local Prio = Library.Options["Prio"..i].Value
                        if ID and ID ~= "" then
                            table.insert(UnitsToPlace, {ID = ID, Priority = Prio})
                        end
                    end
                    table.sort(UnitsToPlace, function(a, b) return a.Priority < b.Priority end)
                    
                    for _, Unit in ipairs(UnitsToPlace) do
                        pcall(function() 
                            Place:FireServer(unpack({{PlaceCFrame = TargetCF, UnitGUID = Unit.ID}})) 
                        end)
                        task.wait(0.1)
                    end
                end
                
                if Upg then pcall(function() Upg:FireServer() end) end
                if Spd then pcall(function() Spd:FireServer() end) end
                if Vote then pcall(function() Vote:FireServer("Again") end) end
            end
        end
        task.wait(1)
    end
end)

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

Library:Notify("Evade | FNTD Module Loaded", 5)
