
local LoaderUrl = "https://raw.githubusercontent.com/milkisbetter/Evade/main/"

-- // 0. SINGLETON
if getgenv().EvadeLoaded then
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Evade.GG", Text = "Already loaded!", Duration = 5})
    return
end
getgenv().EvadeLoaded = true

-- // 1. SERVICES
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    UserInputService = game:GetService("UserInputService"),
    VirtualUser = game:GetService("VirtualUser"),
    TeleportService = game:GetService("TeleportService"),
    HttpService = game:GetService("HttpService"),
    Lighting = game:GetService("Lighting"),
    MarketplaceService = game:GetService("MarketplaceService")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- // 2. LOAD LIBRARIES
local Repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(Repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(Repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(Repo .. 'addons/SaveManager.lua'))()
local Sense = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Sirius/request/library/sense/source.lua'))()

if not Sense.EspInterface then
    Sense.EspInterface = {
        getCharacter = function(Player) return Player.Character end,
        getHealth = function(Character) 
            local Hum = Character and Character:FindFirstChild("Humanoid")
            return Hum and Hum.Health or 100, Hum and Hum.MaxHealth or 100 
        end
    }
end

-- // 3. GAME DETECTION
local PlaceID = game.PlaceId
local GameMode = "Universal"

if PlaceID == 286090429 or PlaceID == 286090429 then GameMode = "Arsenal"
elseif PlaceID == 80550384527033 or PlaceID == 14816132646 then GameMode = "FNTD"
elseif PlaceID == 142823291 or PlaceID == 335132309 then GameMode = "MM2"
elseif PlaceID == 3015403060 or PlaceID == 5796006927 then GameMode = "Trident"
end

-- // 4. UI SETUP
local Window = Library:CreateWindow({
    Title = "Evade | " .. GameMode,
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Game = (GameMode ~= "Universal") and Window:AddTab(GameMode) or nil,
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Movement = Window:AddTab("Movement"),
    Troll = Window:AddTab("Troll"),
    Plugins = Window:AddTab("Plugins"),
    Settings = Window:AddTab("Settings")
}

-- // 5. GLOBAL API
getgenv().Evade = { Library = Library, Window = Window, Tabs = Tabs, Services = Services, Sense = Sense, LocalPlayer = LocalPlayer, LoadedPlugins = {} }

-- // 6. VISUALS TAB
local ESPGroup = Tabs.Visuals:AddLeftGroupbox("Sense ESP")
ESPGroup:AddToggle("MasterESP", { Text = "Master Switch", Default = false }):OnChanged(function(v)
    if GameMode ~= "MM2" and GameMode ~= "Trident" then
        Sense.teamSettings.enemy.enabled = v
        if GameMode == "Universal" then Sense.teamSettings.friendly.enabled = v end
        Sense.Load()
    end
end)
ESPGroup:AddToggle("ESPBox", { Text = "Boxes", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.box = v end)
ESPGroup:AddToggle("ESPName", { Text = "Names", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.name = v end)
ESPGroup:AddToggle("ESPHealth", { Text = "Health", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.healthBar = v end)
ESPGroup:AddToggle("ESPTracer", { Text = "Tracers", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.tracer = v end)

-- // 7. UNIVERSAL COMBAT
local AimbotGroup = Tabs.Combat:AddLeftGroupbox("Aimbot")
AimbotGroup:AddToggle("AimbotEnabled", { Text = "Enabled", Default = false })
AimbotGroup:AddLabel("Keybind"):AddKeyPicker("AimbotKey", { Default = "E", Mode = "Hold", Text = "Aim Key" })
AimbotGroup:AddDropdown("AimbotMethod", { Values = {"Camera", "Mouse"}, Default = 1, Multi = false, Text = "Method" })
AimbotGroup:AddDropdown("TargetPart", { Values = {"Head", "HumanoidRootPart", "Torso"}, Default = 1, Multi = false, Text = "Target Part" })
AimbotGroup:AddSlider("Smoothing", { Text = "Smoothing", Default = 0.5, Min = 0.01, Max = 1, Rounding = 2 })
AimbotGroup:AddToggle("TeamCheck", { Text = "Team Check", Default = true })
AimbotGroup:AddToggle("WallCheck", { Text = "Wall Check", Default = false })

local FOVGroup = Tabs.Combat:AddRightGroupbox("FOV")
FOVGroup:AddToggle("DrawFOV", { Text = "Draw FOV", Default = true }):AddColorPicker("FOVColor", { Default = Color3.fromRGB(255, 255, 255) })
FOVGroup:AddSlider("FOVRadius", { Text = "Radius", Default = 100, Min = 10, Max = 800, Rounding = 0 })

-- // 8. MOVEMENT TAB
local MoveGroup = Tabs.Movement:AddLeftGroupbox("Flight")
MoveGroup:AddToggle("FlightEnabled", { Text = "Enable Flight", Default = false }):AddKeyPicker("FlightKey", { Default = "F", Mode = "Toggle", Text = "Toggle" })
MoveGroup:AddDropdown("FlightMode", { Values = {"LinearVelocity", "CFrame", "BodyVelocity"}, Default = 1, Multi = false, Text = "Mode" })
MoveGroup:AddSlider("FlightSpeed", { Text = "Speed", Default = 50, Min = 10, Max = 300, Rounding = 0 })

local SpeedGroup = Tabs.Movement:AddRightGroupbox("Speed")
SpeedGroup:AddToggle("SpeedEnabled", { Text = "Enable Speed", Default = false })
SpeedGroup:AddDropdown("SpeedMode", { Values = {"WalkSpeed", "CFrame"}, Default = 1, Multi = false, Text = "Mode" })
SpeedGroup:AddSlider("WalkSpeed", { Text = "Factor", Default = 16, Min = 16, Max = 300, Rounding = 0 })

local MiscMove = Tabs.Movement:AddLeftGroupbox("Misc")
MiscMove:AddToggle("InfJump", { Text = "Infinite Jump", Default = false })
MiscMove:AddToggle("Noclip", { Text = "Noclip", Default = false })

-- // 9. TROLL TAB
local TrollGroup = Tabs.Troll:AddLeftGroupbox("Fun")
TrollGroup:AddToggle("Fling", { Text = "Spin Fling", Default = false }):AddKeyPicker("FlingKey", { Default = "X", Mode = "Toggle" })

-- // 10. PLUGINS TAB
local PluginGroup = Tabs.Plugins:AddLeftGroupbox("Loader")
PluginGroup:AddInput("PluginURL", { Default = "", Text = "URL", Placeholder = "raw.github..." })
PluginGroup:AddButton("Execute", function()
    local url = Library.Options.PluginURL.Value
    if url ~= "" then 
        local success, err = pcall(function() loadstring(game:HttpGet(url))() end)
        if not success then Library:Notify("Plugin Error: "..tostring(err), 5) end
    end
end)

PluginGroup:AddButton("List Plugins", function()
    if getgenv().Evade.LoadedPlugins then
        for i,v in pairs(getgenv().Evade.LoadedPlugins) do print(v) end
        Library:Notify("Check Console (F9)", 3)
    end
end)

-- // 11. GAME SPECIFIC MODULES

-- [ ARSENAL ]
if GameMode == "Arsenal" then
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
end

-- [ FNTD ]
if GameMode == "FNTD" then
    local Farm = Tabs.Game:AddLeftGroupbox('Macro Setup')
    Farm:AddInput('MacroX', { Default = '1046', Text = 'Pos X', Numeric = true })
    Farm:AddInput('MacroY', { Default = '13', Text = 'Pos Y', Numeric = true })
    Farm:AddInput('MacroZ', { Default = '-821', Text = 'Pos Z', Numeric = true })
    
    Farm:AddButton('Grab Pos', function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local p = LocalPlayer.Character.HumanoidRootPart.Position
            Library.Options.MacroX:SetValue(tostring(math.floor(p.X)))
            Library.Options.MacroY:SetValue(tostring(math.floor(p.Y)))
            Library.Options.MacroZ:SetValue(tostring(math.floor(p.Z)))
        end
    end)

    Farm:AddToggle('Recorder', { Text = 'Record', Default = false })
    Farm:AddToggle('FNTD_AutoFarm', { Text = 'Enable Macro', Default = false })
    Farm:AddToggle('AutoRejoin', { Text = 'Rejoin', Default = true })

    LocalPlayer.OnTeleport:Connect(function()
        if Library.Toggles.AutoRejoin.Value and queue_on_teleport then
            queue_on_teleport(string.format([[repeat task.wait() until game:IsLoaded(); pcall(function() loadstring(game:HttpGet("%s"))() end)]], LoaderUrl))
        end
    end)
    
    local Slots = Tabs.Game:AddRightGroupbox('Units')
    for i = 1, 6 do
        Slots:AddLabel("Unit " .. i)
        Slots:AddInput('GUID'..i, { Default = '', Text = 'GUID', Placeholder = 'Waiting...' })
        Slots:AddSlider('Prio'..i, { Text = 'Priority', Default = i, Min = 1, Max = 6, Rounding = 0 })
        Slots:AddDivider()
    end

    local mt = getrawmetatable(game); local old = mt.__namecall; setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}; local method = getnamecallmethod()
        if method == "FireServer" and string.find(self.Name, "PlaceUnit") and Library.Toggles.Recorder.Value then
            for _, arg in pairs(args) do
                if type(arg) == "table" and rawget(arg, "UnitGUID") then
                    local det = arg.UnitGUID
                    local dup = false
                    for i=1,6 do if Library.Options["GUID"..i].Value == det then dup = true break end end
                    if not dup then
                        for i=1,6 do
                            if Library.Options["GUID"..i].Value == "" then
                                Library.Options["GUID"..i]:SetValue(det)
                                Library:Notify("Saved Slot "..i, 3)
                                break
                            end
                        end
                    end
                end
            end
        end
        return old(self, unpack(args))
    end); setreadonly(mt, true)

    task.spawn(function()
        while true do
            if Library.Toggles.FNTD_AutoFarm.Value then
                local S = Services.ReplicatedStorage:FindFirstChild("Shared")
                local Net = nil
                if S and S:FindFirstChild("Packages") and S.Packages:FindFirstChild("_Index") then
                     for _, c in ipairs(S.Packages._Index:GetChildren()) do
                        if c.Name:match("^sleitnick_net@") then Net = c:FindFirstChild("net"); break end
                     end
                end
                if Net then
                    local P = Net:FindFirstChild("RE/PlaceUnit")
                    local U = Net:FindFirstChild("RE/UpgradeAll")
                    local S = Net:FindFirstChild("RE/UpdateGameSpeed")
                    local V = Net:FindFirstChild("RE/VoteEvent") 
                    if P then 
                        local x = tonumber(Library.Options.MacroX.Value) or 1046
                        local y = tonumber(Library.Options.MacroY.Value) or 13
                        local z = tonumber(Library.Options.MacroZ.Value) or -821
                        local cf = CFrame.new(x, y, z)
                        local u = {}
                        for i=1,6 do
                            local id = Library.Options["GUID"..i].Value
                            local p = Library.Options["Prio"..i].Value
                            if id ~= "" then table.insert(u, {id=id, p=p}) end
                        end
                        table.sort(u, function(a,b) return a.p < b.p end)
                        for _, unit in ipairs(u) do
                            pcall(function() P:FireServer(unpack({{PlaceCFrame = cf, UnitGUID = unit.id}})) end)
                            task.wait(0.1)
                        end
                    end
                    if U then pcall(function() U:FireServer() end) end
                    if S then pcall(function() S:FireServer() end) end
                    if V then pcall(function() V:FireServer("Again") end) end
                end
            end
            task.wait(1)
        end
    end)
end

-- [ MM2 ]
local MM2Roles = {}
if GameMode == "MM2" then
    local RoleBox = Tabs.Game:AddLeftGroupbox("Roles")
    RoleBox:AddToggle("MM2_ESP", { Text = "Role Colors", Default = true })
    RoleBox:AddToggle("MM2_ShowRoles", { Text = "Text Roles", Default = true })
    
    local RageBox = Tabs.Game:AddRightGroupbox("Rage")
    RageBox:AddToggle("MM2_KillAll", { Text = "Kill All", Default = false })
    RageBox:AddToggle("MM2_Silent", { Text = "Silent Aim", Default = false })
    RageBox:AddSlider("MM2_SilentFOV", { Text = "Silent FOV", Default = 150, Min = 10, Max = 800, Rounding = 0 })
    RageBox:AddToggle("MM2_DrawSilent", { Text = "Draw Silent FOV", Default = false })
    
    local FarmGroup = Tabs.Game:AddRightGroupbox("Farming")
    FarmGroup:AddToggle("MM2_GrabGun", { Text = "Auto Grab Gun", Default = true })

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

    task.spawn(function()
        while true do
            if GameMode == "MM2" then
                for _, v in pairs(Services.Players:GetPlayers()) do
                    if v ~= LocalPlayer then MM2Roles[v] = GetRole(v) end
                end
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
                local D = Services.Workspace:FindFirstChild("GunDrop")
                if D then LocalPlayer.Character.HumanoidRootPart.CFrame = D.CFrame; task.wait(0.2) end
            end
            task.wait(0.5)
        end
    end)
end

-- [ TRIDENT ]
local Tri_Targets = {}
if GameMode == "Trident" then
    local TC = Tabs.Game:AddLeftGroupbox("Combat")
    TC:AddToggle("Tri_Aim", { Text = "Aimbot", Default = false })
    TC:AddDropdown("Tri_Part", { Values = {"Head", "HumanoidRootPart"}, Default = 1, Text = "Aim Part" })
    
    local TV = Tabs.Game:AddRightGroupbox("Visuals")
    TV:AddToggle("Tri_ESP", { Text = "Entity ESP", Default = true })
    TV:AddToggle("Tri_Env", { Text = "Remove Fog/Grass", Default = false })

    task.spawn(function()
        while true do
            table.clear(Tri_Targets)
            local locs = {Services.Workspace, Services.Workspace.CurrentCamera}
            for _, l in pairs(locs) do
                for _, v in pairs(l:GetDescendants()) do
                    if v:IsA("Model") then
                        local r = v:FindFirstChild("HumanoidRootPart")
                        local a = v:FindFirstChild("AnimationController")
                        if r and a and v.Name ~= LocalPlayer.Name then
                            table.insert(Tri_Targets, {obj=v, root=r, name=v.Name})
                        end
                    end
                end
            end
            task.wait(1)
        end
    end)
    
    task.spawn(function()
        while true do
            if Library.Toggles.Tri_Env.Value then
                Services.Lighting.FogEnd = 9e9
                sethiddenproperty(Services.Workspace.Terrain, "Decoration", false)
            end
            task.wait(1)
        end
    end)
end

-- // 12. SETTINGS & INIT
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() getgenv().Evade_loaded = false; Library:Unload(); Sense.Unload() end)
MenuGroup:AddLabel("Keybind"):AddKeyPicker("MenuKey", { Default = "RightShift", NoUI = true, Text = "Menu" })
Library.ToggleKeybind = Library.Options.MenuKey

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("Evade")
SaveManager:SetFolder("Evade/" .. GameMode)
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

-- // 13. MM2 SILENT AIM HOOK
if GameMode == "MM2" then
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
end

-- // 14. GLOBAL RENDER LOOP
local FOVCircle = Drawing.new("Circle"); FOVCircle.Thickness = 1; FOVCircle.NumSides = 64; FOVCircle.Filled = false; FOVCircle.Visible = false
local CustomDrawings = {}

local function IsVisible(Part)
    local O = Camera.CFrame.Position
    local D = (Part.Position - O).Unit * (Part.Position - O).Magnitude
    local P = RaycastParams.new(); P.FilterDescendantsInstances = {LocalPlayer.Character}; P.FilterType = Enum.RaycastFilterType.Exclude
    local R = Services.Workspace:Raycast(O, D, P)
    return R == nil
end

local function GetClosest()
    local C = nil; local M = Library.Options.FOVRadius.Value
    local MP = Vector2.new(Mouse.X, Mouse.Y)
    
    if GameMode == "Trident" then
        for _, t in pairs(Tri_Targets) do
            local p = t.obj:FindFirstChild(Library.Options.Tri_Part.Value)
            if p then
                local s, v = Camera:WorldToViewportPoint(p.Position)
                if v then
                    local d = (MP - Vector2.new(s.X, s.Y)).Magnitude
                    if d < M then M = d; C = p end
                end
            end
        end
    else
        for _, p in pairs(Services.Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local c = Sense.EspInterface.getCharacter(p)
                if c then
                    local pt = c:FindFirstChild(Library.Options.TargetPart.Value)
                    if pt then
                        if not Library.Toggles.WallCheck.Value or IsVisible(pt) then
                            local s, v = Camera:WorldToViewportPoint(pt.Position)
                            if v then
                                local d = (MP - Vector2.new(s.X, s.Y)).Magnitude
                                if d < M then M = d; C = pt end
                            end
                        end
                    end
                end
            end
        end
    end
    return C
end

Services.RunService.RenderStepped:Connect(function()
    -- FOV
    if Library.Toggles.DrawFOV.Value then
        FOVCircle.Visible = true; FOVCircle.Radius = Library.Options.FOVRadius.Value
        FOVCircle.Color = Library.Options.FOVColor.Value; FOVCircle.Position = Services.UserInputService:GetMouseLocation()
    elseif GameMode == "MM2" and Library.Toggles.MM2_DrawSilent.Value then
        FOVCircle.Visible = true; FOVCircle.Radius = Library.Options.MM2_SilentFOV.Value
        FOVCircle.Color = Color3.fromRGB(255,0,0); FOVCircle.Position = Services.UserInputService:GetMouseLocation()
    else FOVCircle.Visible = false end

    -- Aimbot
    local AimOn = (GameMode == "Trident" and Library.Toggles.Tri_Aim.Value) or Library.Toggles.AimbotEnabled.Value
    if AimOn and Library.Options.AimbotKey:GetState() then
        local T = GetClosest()
        if T then
            if Library.Options.AimbotMethod.Value == "Camera" then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, T.Position), Library.Options.Smoothing.Value)
            else
                local s = Camera:WorldToViewportPoint(T.Position)
                mousemoverel((s.X - Mouse.X) * Library.Options.Smoothing.Value, ((s.Y + 36) - Mouse.Y) * Library.Options.Smoothing.Value)
            end
        end
    end

    -- MM2 Visuals
    if GameMode == "MM2" and Library.Toggles.MM2_ESP.Value then
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
                    
                    local t = Drawing.new("Text"); t.Visible=true; t.Text=p.Name.." ["..r.."]"; t.Color=c; t.Center=true; t.Outline=true; t.Size=14
                    t.Position = Vector2.new(s.X, s.Y - b.Size.Y/2 - 15)
                    table.insert(CustomDrawings, t)
                end
            end
        end
    end
    
    -- Trident Visuals
    if GameMode == "Trident" and Library.Toggles.Tri_ESP.Value then
        for _, d in pairs(CustomDrawings) do d:Remove() end
        CustomDrawings = {}
        for _, t in pairs(Tri_Targets) do
            local s, v = Camera:WorldToViewportPoint(t.root.Position)
            if v then
                local b = Drawing.new("Square"); b.Visible=true; b.Color=Color3.new(1,0,0); b.Thickness=1; b.Filled=false
                b.Size = Vector2.new(2000/s.Z, 3500/s.Z); b.Position = Vector2.new(s.X - b.Size.X/2, s.Y - b.Size.Y/2)
                table.insert(CustomDrawings, b)
                local tx = Drawing.new("Text"); tx.Visible=true; tx.Text=t.name; tx.Color=Color3.new(1,1,1); tx.Center=true; tx.Position=Vector2.new(s.X, s.Y - b.Size.Y/2 - 15)
                table.insert(CustomDrawings, tx)
            end
        end
    end

    -- Arsenal Visuals/Logic
    if GameMode == "Arsenal" then
        if Library.Toggles.Ars_Hitbox.Value then
            local S = Library.Options.Ars_HitboxSize.Value
            local T = Library.Options.Ars_HitboxTrans.Value
            for _, v in pairs(Services.Players:GetPlayers()) do
                if v ~= LocalPlayer and v.Team ~= LocalPlayer.Team and v.Character then
                    pcall(function()
                        -- MULTI-PART EXPANSION (Head, Root, Legs)
                        for _, PartName in pairs({"HeadHB", "HumanoidRootPart", "RightUpperLeg", "LeftUpperLeg"}) do
                            local hb = v.Character:FindFirstChild(PartName)
                            if hb then 
                                hb.CanCollide = false
                                hb.Transparency = T
                                hb.Size = Vector3.new(S,S,S) 
                            end
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
    end
end)

-- // 15. PHYSICS LOOP (Stepped)
Services.RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end
    local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")

    -- Flight
    if Library.Toggles.FlightEnabled.Value and Library.Options.FlightKey:GetState() and HRP then
        local Mode = Library.Options.FlightMode.Value
        local Speed = Library.Options.FlightSpeed.Value
        local Dir = Vector3.zero
        local CF = Camera.CFrame
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then Dir = Dir + CF.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then Dir = Dir - CF.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then Dir = Dir - CF.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then Dir = Dir + CF.RightVector end

        -- Cleanup previous modes
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
        -- Full Cleanup
        if HRP then
            if HRP:FindFirstChild("SWFly") then HRP.SWFly:Destroy() end
            if HRP:FindFirstChild("SWHold") then HRP.SWHold:Destroy() end
            if HRP:FindFirstChild("SWBV") then HRP.SWBV:Destroy() end
            if HRP:FindFirstChild("SWAtt") then HRP.SWAtt:Destroy() end
            HRP.Anchored = false
        end
    end
    
    -- Speed
    if Library.Toggles.SpeedEnabled.Value and Hum then
        if Library.Options.SpeedMode.Value == "WalkSpeed" then
            Hum.WalkSpeed = Library.Options.WalkSpeed.Value
        elseif Library.Options.SpeedMode.Value == "CFrame" and HRP and Hum.MoveDirection.Magnitude > 0 then
            if Hum.WalkSpeed ~= 16 then Hum.WalkSpeed = 16 end
            HRP.CFrame = HRP.CFrame + (Hum.MoveDirection * (Library.Options.WalkSpeed.Value/100))
        end
    else
        -- Speed Reset
        if Hum and Hum.WalkSpeed ~= 16 then Hum.WalkSpeed = 16 end
    end
    
    -- Noclip
    if Library.Toggles.Noclip.Value then
        for _,v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
    
    -- Fling
    if Library.Toggles.Fling.Value and Library.Options.FlingKey:GetState() and HRP then
        local AV = HRP:FindFirstChild("SWFling") or Instance.new("BodyAngularVelocity", HRP); AV.Name = "SWFling"
        AV.AngularVelocity = Vector3.new(0, 9999, 0); AV.MaxTorque = Vector3.new(0, math.huge, 0)
        for _,v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    else
        if HRP and HRP:FindFirstChild("SWFling") then HRP.SWFling:Destroy() end
    end
end)

-- Inf Jump
Services.UserInputService.JumpRequest:Connect(function()
    if Library.Toggles.InfJump.Value and LocalPlayer.Character then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

Library:Notify("Evade.GG ON TOP.", 5)
