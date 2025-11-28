local Evade = getgenv().Evade
local Library = Evade.Library
local Services = Evade.Services
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera

-- // 1. ROBUST BOOTSTRAPPER
local Bedwars = {
    Knit = nil,
    Controllers = {}
}

local function Status(msg)
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Evade Loader", Text = msg, Duration = 2})
end

-- A. Safe Upvalue Scanner
local function ScanUpvalues(Func)
    if type(Func) ~= "function" then return nil end
    local Info = debug.getinfo(Func)
    local Nups = Info.nups -- Get exact number of upvalues to avoid "out of range" error
    
    for i = 1, Nups do
        local Val = debug.getupvalue(Func, i)
        if type(Val) == "table" and Val.Controllers and Val.Services then
            return Val
        end
    end
    return nil
end

-- B. Garbage Collection Scanner (Backup)
local function GarbageScan()
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "Controllers") and rawget(v, "Services") then
            -- Verify it's the real Knit by checking for a known controller
            if v.Controllers.SwordController or v.Controllers.AppController then
                return v
            end
        end
    end
    return nil
end

-- C. Initialization Logic
local function Init()
    Status("Waiting for Game...")
    repeat task.wait() until game:IsLoaded()
    
    -- method 1: Hook Require
    local TS = Services.ReplicatedStorage:WaitForChild("TS", 10)
    local KnitScript = TS and TS:WaitForChild("knit", 10)
    
    if KnitScript then
        local KnitPkg = require(KnitScript)
        if KnitPkg and KnitPkg.setup then
            Bedwars.Knit = ScanUpvalues(KnitPkg.setup)
        end
    end
    
    -- method 2: Deep Scan (if method 1 failed)
    if not Bedwars.Knit then
        Status("Standard Hook Failed. Deep Scanning...")
        Bedwars.Knit = GarbageScan()
    end
    
    if not Bedwars.Knit then return false end

    -- D. Controller Mapping
    local Signatures = {
        ["SwordController"] = "swingSwordAtMouse",
        ["BlockController"] = "placeBlock",
        ["SprintController"] = "startSprinting",
        ["ViewmodelController"] = "playAnimation"
    }

    for Name, Cont in pairs(Bedwars.Knit.Controllers) do
        for MyName, Func in pairs(Signatures) do
            if rawget(Cont, Func) then
                Bedwars.Controllers[MyName] = Cont
            end
        end
        -- Disable AC
        if Name:find("AntiCheat") or Name:find("Raven") then
            if rawget(Cont, "disable") then Cont:disable() end
        end
    end
    
    return true
end

local Success = Init()
if not Success then 
    warn("Bedwars Init Failed")
    return -- Let Loader fallback to Universal
end

Status("Bedwars Hooked.")

-- // 2. UI SETUP
local Window = Library:CreateWindow({
    Title = "Evade | Bedwars (Void Logic)",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Game = Window:AddTab("Bedwars"),
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Movement = Window:AddTab("Movement"),
    Settings = Window:AddTab("Settings")
}

-- COMBAT
local Aura = Tabs.Combat:AddLeftGroupbox("Kill Aura")
Aura:AddToggle("Killaura", { Text = "Enabled", Default = false })
Aura:AddSlider("AuraRange", { Text = "Range", Default = 18, Min = 1, Max = 21 })
Aura:AddToggle("AuraAnim", { Text = "Animation", Default = true })

local Vel = Tabs.Combat:AddRightGroupbox("Mods")
Vel:AddToggle("Velocity", { Text = "Anti-Knockback", Default = false })
Vel:AddSlider("VelH", { Text = "Horizontal", Default = 0, Min = 0, Max = 100 })
Vel:AddSlider("VelV", { Text = "Vertical", Default = 0, Min = 0, Max = 100 })

-- MOVEMENT
local Fly = Tabs.Movement:AddLeftGroupbox("Flight")
Fly:AddToggle("Flight", { Text = "Flight", Default = false }):AddKeyPicker("FlyKey", { Default = "F", Mode = "Toggle" })
Fly:AddSlider("FlySpeed", { Text = "Speed", Default = 40, Min = 10, Max = 80 })

local Move = Tabs.Movement:AddRightGroupbox("Movement")
Move:AddToggle("Sprint", { Text = "Omni-Sprint", Default = true })
Move:AddToggle("Speed", { Text = "Speed", Default = false })
Move:AddSlider("SpeedVal", { Text = "Factor", Default = 20, Min = 16, Max = 35 })
Move:AddToggle("NoFall", { Text = "No Fall", Default = true })
Move:AddToggle("Spider", { Text = "Spider", Default = false })

-- WORLD
local World = Tabs.Game:AddLeftGroupbox("World")
World:AddToggle("BedNuker", { Text = "Bed Nuker", Default = false })
World:AddSlider("NukeRange", { Text = "Range", Default = 30, Min = 10, Max = 30 })
World:AddToggle("ChestSteal", { Text = "Chest Stealer", Default = false })

local Build = Tabs.Game:AddRightGroupbox("Building")
Build:AddToggle("Scaffold", { Text = "Scaffold", Default = false })

-- VISUALS
local Vis = Tabs.Visuals:AddLeftGroupbox("ESP")
Vis:AddToggle("BedESP", { Text = "Bed ESP", Default = true })
Vis:AddToggle("PlayerESP", { Text = "Player ESP", Default = true })

-- // 3. LOGIC LOOPS
local function GetTarget(Range)
    local T, D = nil, Range
    for _, p in pairs(Services.Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team ~= LocalPlayer.Team and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            local h = p.Character:FindFirstChild("Humanoid")
            if r and h and h.Health > 0 then
                local dist = (r.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if dist < D then D = dist; T = p.Character end
            end
        end
    end
    return T
end

task.spawn(function()
    while true do
        if not LocalPlayer.Character then task.wait(); continue end
        local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        -- Killaura
        if Library.Toggles.Killaura.Value and HRP then
            local T = GetTarget(Library.Options.AuraRange.Value)
            if T then
                -- Silent Rotate
                HRP.CFrame = CFrame.new(HRP.Position, Vector3.new(T.HumanoidRootPart.Position.X, HRP.Position.Y, T.HumanoidRootPart.Position.Z))
                
                -- Attack via Controller
                local Sword = Bedwars.Controllers.SwordController
                if Sword then
                    if Library.Toggles.AuraAnim.Value then Sword:swingSwordAtMouse() end
                    local args = {
                        ["chargedAttack"] = {["chargeRatio"] = 0},
                        ["entityInstance"] = T,
                        ["validate"] = {
                            ["targetPosition"] = {["value"] = T.HumanoidRootPart.Position},
                            ["selfPosition"] = {["value"] = HRP.Position}
                        }
                    }
                    Services.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.SwordHit:FireServer(args)
                end
            end
        end
        
        -- Bed Nuker
        if Library.Toggles.BedNuker.Value and HRP then
            local Beds = Services.CollectionService:GetTagged("bed")
            for _, B in pairs(Beds) do
                if B and B:FindFirstChild("Covers") and B.Covers.BrickColor ~= LocalPlayer.Team.TeamColor then
                    if (B.Position - HRP.Position).Magnitude < Library.Options.NukeRange.Value then
                        local A = {
                            ["blockRef"] = {["blockPosition"] = Vector3.new(math.round(B.Position.X/3), math.round(B.Position.Y/3), math.round(B.Position.Z/3))},
                            ["hitPosition"] = B.Position, ["hitNormal"] = Vector3.new(0,1,0)
                        }
                        Services.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.DamageBlock:InvokeServer(A)
                    end
                end
            end
        end
        
        task.wait(0.1)
    end
end)

Services.RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end
    local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    
    if Library.Toggles.Flight.Value and Library.Options.FlyKey:GetState() and HRP then
        local LV = HRP:FindFirstChild("VoidFly") or Instance.new("LinearVelocity", HRP); LV.Name = "VoidFly"
        LV.MaxForce = 999999; LV.RelativeTo = Enum.ActuatorRelativeTo.World
        local Att = HRP:FindFirstChild("VoidAtt") or Instance.new("Attachment", HRP); Att.Name = "VoidAtt"; LV.Attachment0 = Att
        
        local Dir = Vector3.zero
        local CF = Camera.CFrame
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then Dir = Dir + CF.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then Dir = Dir - CF.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then Dir = Dir - CF.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then Dir = Dir + CF.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then Dir = Dir + Vector3.new(0,1,0) end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then Dir = Dir - Vector3.new(0,1,0) end
        
        LV.VectorVelocity = Dir * Library.Options.FlySpeed.Value
        if HRP.Position.Y < -10 then HRP.Velocity = Vector3.new(0, 50, 0) end
    else
        if HRP:FindFirstChild("VoidFly") then HRP.VoidFly:Destroy() end
    end
    
    if Library.Toggles.Velocity.Value and HRP then
        if HRP.Velocity.Magnitude > 20 or HRP.Velocity.Y > 10 then
             HRP.Velocity = Vector3.new(HRP.Velocity.X * (Library.Options.VelH.Value/100), HRP.Velocity.Y * (Library.Options.VelV.Value/100), HRP.Velocity.Z * (Library.Options.VelH.Value/100))
        end
    end
    
    if Library.Toggles.Speed.Value and Hum then
        Hum.WalkSpeed = Library.Options.SpeedVal.Value
        if Bedwars.Controllers.SprintController then Bedwars.Controllers.SprintController:startSprinting() end
    end
    
    if Library.Toggles.NoFall.Value then
        Services.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.GroundHit:FireServer()
    end
    
    if Library.Toggles.Scaffold.Value and HRP and Bedwars.Controllers.BlockController then
        local Pos = HRP.Position + Vector3.new(0, -3.5, 0) + (HRP.Velocity * 0.2)
        local BPos = Vector3.new(math.round(Pos.X/3), math.round(Pos.Y/3), math.round(Pos.Z/3))
        Services.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.PlaceBlock:InvokeServer({
            ["blockType"] = "wool_white", ["blockData"] = 0, ["position"] = BPos
        })
    end
end)

local Drawings = {}
Services.RunService.RenderStepped:Connect(function()
    for _, d in pairs(Drawings) do d:Remove() end
    Drawings = {}
    
    if Library.Toggles.BedESP.Value then
        for _, Bed in pairs(Services.CollectionService:GetTagged("bed")) do
            if Bed and Bed:FindFirstChild("Covers") then
                local Pos, Vis = Camera:WorldToViewportPoint(Bed.Position)
                if Vis then
                    local B = Drawing.new("Square"); B.Visible=true; B.Size=Vector2.new(30,30); B.Position=Vector2.new(Pos.X-15,Pos.Y-15)
                    B.Color = Bed.Covers.BrickColor.Color; B.Thickness=2; B.Filled=false; table.insert(Drawings, B)
                end
            end
        end
    end
    
    if Library.Toggles.PlayerESP.Value then
        for _, p in pairs(Services.Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local Pos, Vis = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                if Vis then
                    local B = Drawing.new("Square"); B.Visible=true; B.Size=Vector2.new(2000/Pos.Z, 3000/Pos.Z); B.Position=Vector2.new(Pos.X-B.Size.X/2,Pos.Y-B.Size.Y/2)
                    B.Color = p.TeamColor.Color; B.Thickness=1; B.Filled=false; table.insert(Drawings, B)
                end
            end
        end
    end
end)

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() getgenv().EvadeLoaded = false; Library:Unload(); Sense.Unload() end)
MenuGroup:AddLabel("Keybind"):AddKeyPicker("MenuKey", { Default = "RightShift", NoUI = true, Text = "Menu" })
Library.ToggleKeybind = Library.Options.MenuKey

Evade.ThemeManager:SetLibrary(Library)
Evade.SaveManager:SetLibrary(Library)
Evade.SaveManager:IgnoreThemeSettings()
Evade.SaveManager:SetFolder("Evade")
Evade.SaveManager:SetFolder("Evade/Bedwars")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

Library:Notify("Evade | Bedwars Loaded", 5)
