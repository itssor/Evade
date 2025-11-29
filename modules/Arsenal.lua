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

-- // 1. GAME TAB
local WepMods = Tabs.Game:AddLeftGroupbox("Weapon Mods")
WepMods:AddToggle("Ars_NoRecoil", { Text = "No Recoil", Default = false })
WepMods:AddToggle("Ars_NoSpread", { Text = "No Spread", Default = false })
WepMods:AddToggle("Ars_RapidFire", { Text = "Rapid Fire", Default = false })
WepMods:AddToggle("Ars_InfAmmo", { Text = "Infinite Ammo", Default = false })
WepMods:AddToggle("Ars_Rainbow", { Text = "Rainbow Gun", Default = false })

local ExploitGroup = Tabs.Game:AddRightGroupbox("Exploits")
ExploitGroup:AddToggle("Ars_Hitbox", { Text = "Hitbox Expander", Default = false })
ExploitGroup:AddSlider("Ars_HitboxSize", { Text = "Size", Default = 13, Min = 2, Max = 25 })
ExploitGroup:AddSlider("Ars_HitboxTrans", { Text = "Transparency", Default = 0.5, Min = 0, Max = 1 })
ExploitGroup:AddToggle("KillSay", { Text = "Kill Say", Default = false })
ExploitGroup:AddToggle("AutoTeam", { Text = "Auto Join Team", Default = false })

-- // 2. COMBAT TAB
local SilentGroup = Tabs.Combat:AddLeftGroupbox("Silent Aim")
SilentGroup:AddToggle("SilentAim", { Text = "Silent Aim", Default = false })
SilentGroup:AddSlider("SilentFOV", { Text = "FOV Radius", Default = 150, Min = 10, Max = 800 })
SilentGroup:AddToggle("DrawSilent", { Text = "Draw FOV", Default = true }):AddColorPicker("SilentColor", { Default = Color3.fromRGB(255, 0, 0) })
SilentGroup:AddToggle("WallCheck", { Text = "Wall Check", Default = true })
SilentGroup:AddSlider("HitChance", { Text = "Hit Chance", Default = 100, Min = 1, Max = 100 })

local TriggerGroup = Tabs.Combat:AddRightGroupbox("Trigger Bot")
TriggerGroup:AddToggle("TriggerBot", { Text = "Trigger Bot", Default = false })
TriggerGroup:AddSlider("TriggerDelay", { Text = "Delay (ms)", Default = 0, Min = 0, Max = 500 })

-- // 3. VISUALS TAB (Restored)
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

-- // 4. MOVEMENT TAB (Restored)
local FlightGroup = Tabs.Movement:AddLeftGroupbox("Flight System")
FlightGroup:AddToggle("FlightEnabled", { Text = "Enable Flight", Default = false }):AddKeyPicker("FlightKey", { Default = "F", Mode = "Toggle", Text = "Toggle" })
FlightGroup:AddDropdown("FlightMode", { Values = {"LinearVelocity", "CFrame", "BodyVelocity"}, Default = 1, Multi = false, Text = "Mode" })
FlightGroup:AddSlider("FlightSpeed", { Text = "Speed", Default = 50, Min = 10, Max = 300 })

local SpeedGroup = Tabs.Movement:AddRightGroupbox("Speed Engine")
SpeedGroup:AddToggle("SpeedEnabled", { Text = "Enable Speed", Default = false })
SpeedGroup:AddDropdown("SpeedMode", { Values = {"WalkSpeed", "CFrame", "TP"}, Default = 1, Multi = false, Text = "Mode" })
SpeedGroup:AddSlider("WalkSpeed", { Text = "Factor", Default = 16, Min = 16, Max = 300 })

local MiscMove = Tabs.Movement:AddLeftGroupbox("Misc")
MiscMove:AddToggle("InfJump", { Text = "Infinite Jump", Default = false })
MiscMove:AddToggle("Noclip", { Text = "Noclip", Default = false })

-- // 5. LOGIC: SILENT AIM
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

local function GetSilentTarget()
    local T = nil; local D = Library.Options.SilentFOV.Value
    local MP = Services.UserInputService:GetMouseLocation()
    
    for _, p in pairs(Services.Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character then
            local Head = p.Character:FindFirstChild("Head")
            if Head then
                if not Library.Toggles.WallCheck.Value or IsVisible(Head) then
                    local Pos, Vis = Camera:WorldToViewportPoint(Head.Position)
                    if Vis then
                        local Dist = (MP - Vector2.new(Pos.X, Pos.Y)).Magnitude
                        if Dist < D then D = Dist; T = Head end
                    end
                end
            end
        end
    end
    return T
end

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if Library.Toggles.SilentAim.Value and (method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay" or method == "Raycast") and not checkcaller() then
        if math.random(1, 100) <= Library.Options.HitChance.Value then
            local Target = GetSilentTarget()
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

-- // 6. LOGIC: KILL SAY (FIXED)
local KillPhrases = {"Evade.GG On Top", "Sit Down", "Owned", "Config Issue?", "Get good"}
local LastKills = 0

local function SendChat(Msg)
    -- Method 1: TextChatService (New)
    if game:GetService("TextChatService").ChatInputBarConfiguration.TargetTextChannel then
        game:GetService("TextChatService").ChatInputBarConfiguration.TargetTextChannel:SendAsync(Msg)
    -- Method 2: Legacy Chat (Old)
    elseif Services.ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") then
        Services.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(Msg, "All")
    end
end

local function SetupKillSay()
    if LocalPlayer:FindFirstChild("Leaderstats") and LocalPlayer.Leaderstats:FindFirstChild("Kills") then
        LastKills = LocalPlayer.Leaderstats.Kills.Value -- Sync initial kills
        LocalPlayer.Leaderstats.Kills.Changed:Connect(function(NewVal)
            if Library.Toggles.KillSay.Value and NewVal > LastKills then
                SendChat(KillPhrases[math.random(#KillPhrases)])
                LastKills = NewVal
            end
        end)
    else
        -- Retry if leaderstats assume late load
        task.delay(1, SetupKillSay)
    end
end
SetupKillSay()

-- // 7. LOGIC: LOOPS
task.spawn(function()
    while true do
        -- Weapon Mods
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
        -- Auto Team
        if Library.Toggles.AutoTeam.Value and LocalPlayer.PlayerGui:FindFirstChild("Menew") then
            for _, v in pairs(Services.ReplicatedStorage:GetDescendants()) do
                if v.Name == "JoinTeam" and v:IsA("RemoteFunction") then v:InvokeServer("TBC") end
            end
        end
        task.wait(2)
    end
end)

task.spawn(function()
    while true do
        if Library.Toggles.TriggerBot.Value then
            local Target = Mouse.Target
            if Target and Target.Parent then
                local Player = Services.Players:GetPlayerFromCharacter(Target.Parent)
                if Player and Player.Team ~= LocalPlayer.Team then
                    task.wait(Library.Options.TriggerDelay.Value / 1000)
                    mouse1click()
                    task.wait(0.1)
                end
            end
        end
        task.wait()
    end
end)

Services.RunService.RenderStepped:Connect(function()
    -- FOV
    if Library.Toggles.DrawSilent.Value and Library.Toggles.SilentAim.Value then
        FOVCircle.Visible = true; FOVCircle.Radius = Library.Options.SilentFOV.Value; FOVCircle.Color = Library.Options.SilentColor.Value; FOVCircle.Position = Services.UserInputService:GetMouseLocation()
    else FOVCircle.Visible = false end

    -- Hitbox
    if Library.Toggles.Ars_Hitbox.Value then
        local Size = Library.Options.Ars_HitboxSize.Value; local Trans = Library.Options.Ars_HitboxTrans.Value
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
    
    -- Ammo
    if Library.Toggles.Ars_InfAmmo.Value then
        pcall(function() LocalPlayer.PlayerGui.GUI.Client.Variables.ammocount.Value = 999 end)
    end
    
    -- Rainbow
    if Library.Toggles.Ars_Rainbow.Value and Camera:FindFirstChild("Arms") then
         for _,v in pairs(Camera.Arms:GetDescendants()) do if v:IsA("MeshPart") then v.Color = Color3.fromHSV(tick()%5/5, 1, 1) end end
    end
end)

Services.RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end
    local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")

    -- Flight
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
            HRP.Anchored = true; HRP.CFrame = HRP.CFrame + (Dir * (Speed/50))
        elseif Mode == "BodyVelocity" then
            local BV = HRP:FindFirstChild("SWBV") or Instance.new("BodyVelocity", HRP); BV.Name = "SWBV"; BV.MaxForce = Vector3.new(math.huge,math.huge,math.huge); BV.Velocity = Dir * Speed
        end
    else
        if HRP then
            if HRP:FindFirstChild("SWFly") then HRP.SWFly:Destroy() end; if HRP:FindFirstChild("SWHold") then HRP.SWHold:Destroy() end; if HRP:FindFirstChild("SWBV") then HRP.SWBV:Destroy() end; if HRP:FindFirstChild("SWAtt") then HRP.SWAtt:Destroy() end; HRP.Anchored = false
        end
    end
    
    -- Speed
    if Library.Toggles.SpeedEnabled.Value and Hum then
        local Mode = Library.Options.SpeedMode.Value
        if Mode == "WalkSpeed" then Hum.WalkSpeed = Library.Options.WalkSpeed.Value
        elseif Mode == "CFrame" and HRP and Hum.MoveDirection.Magnitude > 0 then
            Hum.WalkSpeed = 16; HRP.CFrame = HRP.CFrame + (Hum.MoveDirection * (Library.Options.WalkSpeed.Value / 100))
        elseif Mode == "TP" and HRP and Hum.MoveDirection.Magnitude > 0 then
            Hum.WalkSpeed = 16; HRP.CFrame = HRP.CFrame * CFrame.new(0, 0, -(Library.Options.WalkSpeed.Value / 50))
        end
    else
        if Hum and Hum.WalkSpeed ~= 16 then Hum.WalkSpeed = 16 end
    end
    
    -- Noclip
    if Library.Toggles.Noclip.Value and HRP then
        if Library.Options.NoclipMode.Value == "Collision" then
            for _,v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
        elseif Library.Options.NoclipMode.Value == "CFrame" then
            if Hum.MoveDirection.Magnitude > 0 then HRP.CFrame = HRP.CFrame + (Hum.MoveDirection * 0.5) end
        end
    end
end)

Services.UserInputService.JumpRequest:Connect(function()
    if Library.Toggles.InfJump.Value and LocalPlayer.Character then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
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
Evade.SaveManager:SetFolder("Evade/Arsenal")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

Library:Notify("Evade | Arsenal Loaded", 5)
