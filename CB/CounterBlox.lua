--[[
    COUNTER BLOX: WARLORD v9.0
    Source: Remote Skins + NoobHub Logic + Warlord Features
    Status: UNDETECTED
]]

warn("[SorWare] Loading Warlord v9.0...")

-- // 1. SERVICES
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    VirtualUser = game:GetService("VirtualUser"),
    Lighting = game:GetService("Lighting")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- // 2. LIBRARIES
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

-- // 3. UI SETUP
local Window = Library:CreateWindow({
    Title = "Counter Blox | Warlord v9.0",
    Center = true, AutoShow = true, TabPadding = 8
})

local Tabs = {
    Combat = Window:AddTab("Combat"),
    Visuals = Window:AddTab("Visuals"),
    Skins = Window:AddTab("Skins"),
    Misc = Window:AddTab("Misc"),
    Settings = Window:AddTab("Settings")
}

-- // 4. FEATURES

-- Combat
local HitboxGroup = Tabs.Combat:AddLeftGroupbox("Hitbox")
HitboxGroup:AddToggle("HitboxExpander", { Text = "Hitbox Expander", Default = false })
HitboxGroup:AddSlider("HitboxSize", { Text = "Size", Default = 13, Min = 2, Max = 25, Rounding = 1 })
HitboxGroup:AddSlider("HitboxTrans", { Text = "Transparency", Default = 0.5, Min = 0, Max = 1, Rounding = 1 })

local GunGroup = Tabs.Combat:AddRightGroupbox("Gun Mods")
GunGroup:AddToggle("NoRecoil", { Text = "No Recoil", Default = false })
GunGroup:AddToggle("NoSpread", { Text = "No Spread", Default = false })
GunGroup:AddToggle("AutoFire", { Text = "TriggerBot", Default = false })

-- Visuals
local PlayerESP = Tabs.Visuals:AddLeftGroupbox("Players")
PlayerESP:AddToggle("MasterESP", { Text = "Master Switch", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.enabled = v; Sense.Load() end)
PlayerESP:AddToggle("EspBox", { Text = "Boxes", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.box = v end)
PlayerESP:AddToggle("EspName", { Text = "Names", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.name = v end)
PlayerESP:AddToggle("EspHealth", { Text = "Health", Default = false }):OnChanged(function(v) Sense.teamSettings.enemy.healthBar = v end)

local LocalVis = Tabs.Visuals:AddRightGroupbox("Local")
LocalVis:AddToggle("RainbowGun", { Text = "Rainbow Gun/Arms", Default = false })
LocalVis:AddToggle("ArmChams", { Text = "Arm Chams", Default = false }):AddColorPicker("ArmColor", { Default = Color3.fromRGB(0, 255, 0) })
LocalVis:AddSlider("ArmTrans", { Text = "Arm Transparency", Default = 0, Min = 0, Max = 1, Rounding = 1 })
LocalVis:AddToggle("InfAmmoVis", { Text = "Infinite Ammo (Visual)", Default = false })

local EnvGroup = Tabs.Visuals:AddLeftGroupbox("Environment")
EnvGroup:AddToggle("NoFlash", { Text = "No Flash", Default = false })
EnvGroup:AddToggle("NoSmoke", { Text = "No Smoke", Default = false })
EnvGroup:AddToggle("NightMode", { Text = "Night Mode", Default = false })

local CamGroup = Tabs.Visuals:AddRightGroupbox("Camera")
CamGroup:AddToggle("FOVEnabled", { Text = "Custom FOV", Default = false })
CamGroup:AddSlider("BaseFOV", { Text = "Base FOV", Default = 90, Min = 70, Max = 120, Rounding = 0 })
CamGroup:AddToggle("ZoomEnabled", { Text = "Enable Zoom (Z)", Default = false })
CamGroup:AddSlider("ZoomLevel", { Text = "Zoom Amount", Default = 15, Min = 1, Max = 60, Rounding = 0 })

-- Misc
local MoveGroup = Tabs.Misc:AddLeftGroupbox("Movement")
MoveGroup:AddToggle("Bhop", { Text = "Bunny Hop", Default = false })
MoveGroup:AddToggle("ThirdPerson", { Text = "Third Person", Default = false })
MoveGroup:AddSlider("TPDist", { Text = "TP Distance", Default = 10, Min = 5, Max = 30 })

local TrollGroup = Tabs.Misc:AddRightGroupbox("Troll")
TrollGroup:AddToggle("SpamChat", { Text = "Chat Spammer", Default = false })

-- // 5. SKIN CHANGER (REMOTE LOAD + NOOBHUB BYPASS)
local SkinsGroup = Tabs.Skins:AddLeftGroupbox("Unlocker")
SkinsGroup:AddButton("Unlock Skins (Remote)", function()
    Library:Notify("Fetching Skins...", 2)
    
    -- 1. FETCH FROM GITHUB
    local Url = "https://raw.githubusercontent.com/itssor/Evade/refs/heads/main/CB/Skins.lua"
    local Success, Response = pcall(function() return game:HttpGet(Url) end)
    if not Success then Library:Notify("Fetch Failed!", 5) return end
    
    local AllSkins = loadstring(Response)()
    local ClientEnv = getsenv(LocalPlayer.PlayerGui.Client)
    
    -- 2. THE BYPASS HOOK
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local old = mt.__namecall
    local Injected = false

    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()

        -- A. BLOCK HUGH (Integrity Check)
        if method == "InvokeServer" and self.Name == "Hugh" then
            return nil -- Blocks the anti-cheat check
        end

        if method == "FireServer" then
            if args[1] == LocalPlayer.UserId then return end

            -- B. INVENTORY SYNC (Length 38)
            if string.len(self.Name) == 38 and not Injected then
                Injected = true
                -- Insert skins into the table sent to server
                for _, Skin in pairs(AllSkins) do
                    local Exists = false
                    for _, MySkin in pairs(args[1]) do 
                        if Skin[1] == MySkin[1] then Exists = true break end 
                    end
                    if not Exists then table.insert(args[1], Skin) end
                end
                return -- Block original packet to avoid conflicts
            end

            -- C. DATA EVENT (Visual Apply)
            if self.Name == "DataEvent" and args[1][4] then
                local SkinName = string.split(args[1][4][1], "_")[2]
                local Folder = LocalPlayer:WaitForChild("SkinFolder")
                if args[1][2] == "Both" then
                    Folder.CTFolder[args[1][3]].Value = SkinName
                    Folder.TFolder[args[1][3]].Value = SkinName
                else
                    Folder[args[1][2].."Folder"][args[1][3]].Value = SkinName
                end
            end
        end

        return old(self, unpack(args))
    end)
    
    setreadonly(mt, true)
    
    -- 3. UPDATE CLIENT
    if ClientEnv then ClientEnv.CurrentInventory = AllSkins end
    
    -- 4. REFRESH GUI
    pcall(function()
        local T, CT = LocalPlayer.SkinFolder.TFolder:Clone(), LocalPlayer.SkinFolder.CTFolder:Clone()
        LocalPlayer.SkinFolder.TFolder:Destroy(); LocalPlayer.SkinFolder.CTFolder:Destroy()
        T.Parent = LocalPlayer.SkinFolder; CT.Parent = LocalPlayer.SkinFolder
    end)
    
    Library:Notify("Skins Unlocked (Remote Loaded)", 5)
end)

-- // 6. LOGIC LOOPS

-- Zoom & FOV (Thunder Method)
local ProxyFOV = Instance.new("NumberValue"); ProxyFOV.Value = 90
local IsZooming = false

Services.RunService:BindToRenderStep("CB_FOV_Override", Enum.RenderPriority.Camera.Value + 5, function()
    if IsZooming and Library.Toggles.ZoomEnabled.Value then
        Camera.FieldOfView = ProxyFOV.Value
    elseif Library.Toggles.FOVEnabled.Value then
        Camera.FieldOfView = Library.Options.BaseFOV.Value
    end
end)

Services.UserInputService.InputBegan:Connect(function(Input, Proc)
    if Proc then return end
    if Input.KeyCode == Enum.KeyCode.Z then 
        IsZooming = true
        Services.TweenService:Create(ProxyFOV, TweenInfo.new(0.2), {Value = Library.Options.ZoomLevel.Value}):Play()
    end
end)

Services.UserInputService.InputEnded:Connect(function(Input)
    if Input.KeyCode == Enum.KeyCode.Z then 
        IsZooming = false
        -- Return to Base FOV if enabled, else 90
        local Target = Library.Toggles.FOVEnabled.Value and Library.Options.BaseFOV.Value or 90
        Services.TweenService:Create(ProxyFOV, TweenInfo.new(0.2), {Value = Target}):Play()
    end
end)

-- Rainbow Gun / Chams / Visuals
Services.RunService.RenderStepped:Connect(function()
    -- Rainbow
    if Library.Toggles.RainbowGun.Value and Camera:FindFirstChild("Arms") then
        local Hue = tick() % 5 / 5
        local Color = Color3.fromHSV(Hue, 1, 1)
        for _, v in pairs(Camera.Arms:GetDescendants()) do
            if v:IsA("MeshPart") or v:IsA("BasePart") then
                if v.Name ~= "HumanoidRootPart" then
                    v.Color = Color
                    v.Transparency = 0
                end
            end
        end
    end
    
    -- Arm Chams
    if Library.Toggles.ArmChams.Value and Camera:FindFirstChild("Arms") then
        for _, v in pairs(Camera.Arms:GetDescendants()) do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                v.Material = Enum.Material.Neon
                v.Color = Library.Options.ArmColor.Value
                v.Transparency = Library.Options.ArmTrans.Value
            end
        end
    end
    
    -- Infinite Ammo Visual
    if Library.Toggles.InfAmmoVis.Value then
        pcall(function()
            LocalPlayer.PlayerGui.GUI.Client.Variables.ammocount.Value = 999
            LocalPlayer.PlayerGui.GUI.Client.Variables.ammocount2.Value = 999
        end)
    end

    -- Hitbox Expander
    if Library.Toggles.HitboxExpander.Value then
        local Size = Library.Options.HitboxSize.Value
        local Trans = Library.Options.HitboxTrans.Value
        for _, Plr in pairs(Services.Players:GetPlayers()) do
            if Plr ~= LocalPlayer and Plr.Team ~= LocalPlayer.Team and Plr.Character then
                pcall(function()
                    local HB = Plr.Character:FindFirstChild("HeadHB")
                    if HB then
                        HB.CanCollide = false
                        HB.Size = Vector3.new(Size, Size, Size)
                        HB.Transparency = Trans
                    end
                end)
            end
        end
    end
    
    -- Recoil/Spread (Client Env)
    if Library.Toggles.NoRecoil.Value or Library.Toggles.NoSpread.Value then
        local Env = getsenv(LocalPlayer.PlayerGui.Client)
        if Env then
            if Library.Toggles.NoRecoil.Value then
                if Env.RecoilX then Env.RecoilX = 0 end
                if Env.RecoilY then Env.RecoilY = 0 end
            end
            if Library.Toggles.NoSpread.Value then
                if Env.CurrentSpread then Env.CurrentSpread = 0 end
            end
        end
    end
    
    -- Environment Visuals
    if Library.Toggles.NoFlash.Value then pcall(function() LocalPlayer.PlayerGui.Blnd.Blind.Visible = false end) end
    if Library.Toggles.NoSmoke.Value then for _, v in pairs(Services.Workspace:GetDescendants()) do if v.Name == "Smoke" then v.Transparency = 1 end end end
    if Library.Toggles.NightMode.Value then
        Services.Lighting.ClockTime = 0
        Services.Lighting.Brightness = 0.5
    else
        Services.Lighting.ClockTime = 14
    end
    
    -- Third Person
    if Library.Toggles.ThirdPerson.Value then
        LocalPlayer.CameraMaxZoomDistance = Library.Options.TPDist.Value
        LocalPlayer.CameraMinZoomDistance = Library.Options.TPDist.Value
    else
        LocalPlayer.CameraMaxZoomDistance = 0
        LocalPlayer.CameraMinZoomDistance = 0
    end
end)

-- Bhop & Spam
task.spawn(function()
    while true do
        task.wait()
        -- Bhop
        if Library.Toggles.Bhop.Value and LocalPlayer.Character then
             local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
             if Hum and Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) and Hum.FloorMaterial ~= Enum.Material.Air then
                 Hum.Jump = true
             end
        end
        
        -- Spam
        if Library.Toggles.SpamChat.Value then
            Services.ReplicatedStorage.Events.PlayerChatted:FireServer("Evade.GG | Get Good", false)
            task.wait(3)
        end
        
        -- TriggerBot
        if Library.Toggles.AutoFire.Value then
             local Target = Mouse.Target
             if Target and Target.Parent then
                 local P = Services.Players:GetPlayerFromCharacter(Target.Parent)
                 if P and P.Team ~= LocalPlayer.Team then
                     mouse1click()
                 end
             end
        end
    end
end)

-- // 7. SETTINGS
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() Library:Unload(); Sense.Unload(); Services.RunService:UnbindFromRenderStep("CB_FOV_Override") end)
MenuGroup:AddLabel("Keybind"):AddKeyPicker("MenuKey", { Default = "RightShift", NoUI = true })
Library.ToggleKeybind = Library.Options.MenuKey

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKey"})
SaveManager:SetFolder("Warlord_Hybrid")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Library:Notify("Warlord v8.0 Loaded", 5)
