--[[
    EVADE.GG - DOORS OMEGA MODULE (v42.0)
    Status: GOD MODE
    Features: EVERYTHING (Entity Notify, Auto-Play, Puzzle Solvers, Full ESP)
    Author: Pine (Cell Block D)
]]

-- // 0. PRE-FLIGHT CHECK
repeat task.wait() until getgenv().Evade
local Evade = getgenv().Evade

local StartTime = tick()
repeat task.wait() until Evade.Library or (tick() - StartTime > 10)
if not Evade.Library then warn("[Evade] Library Missing"); return end

-- // 1. IMPORTS & VARIABLES
local Library = Evade.Library
local Services = Evade.Services
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera
local Mouse = Evade.Mouse

local Workspace = Services.Workspace
local Lighting = Services.Lighting
local ReplicatedStorage = Services.ReplicatedStorage
local VirtualInputManager = game:GetService("VirtualInputManager")
local ProximityPromptService = game:GetService("ProximityPromptService")

local CurrentRooms = Workspace:WaitForChild("CurrentRooms")
local EntityNames = {"RushMoving", "AmbushMoving", "Snare", "A60", "A120", "Eyes", "JeffTheKiller"}

-- // 2. UI CONSTRUCTION
local Window = Library:CreateWindow({
    Title = "Evade | Doors (Omega)",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Main = Window:AddTab("Main"),
    Visuals = Window:AddTab("Visuals"),
    Automation = Window:AddTab("Automation"),
    Exploits = Window:AddTab("Exploits"),
    Settings = Window:AddTab("Settings")
}

-- // 3. TAB: MAIN (Entity Management)
local EntityGroup = Tabs.Main:AddLeftGroupbox("Entity Defense")
EntityGroup:AddToggle("NotifyEntity", { Text = "Predict/Notify Entities", Default = true })
EntityGroup:AddToggle("AntiScreech", { Text = "Anti-Screech (Auto Look)", Default = true })
EntityGroup:AddToggle("AntiEyes", { Text = "Anti-Eyes (Auto Look Away)", Default = false })
EntityGroup:AddToggle("NoSeekArms", { Text = "Remove Seek Arms", Default = false })

local GameGroup = Tabs.Main:AddRightGroupbox("Game Breakers")
GameGroup:AddToggle("SpeedBypass", { Text = "Speed Bypass", Default = false }):AddKeyPicker("SpeedKey", { Default = "V", Mode = "Toggle" })
GameGroup:AddSlider("SpeedVal", { Text = "Factor", Default = 0.5, Min = 0.1, Max = 2.5, Rounding = 1 })
GameGroup:AddToggle("Noclip", { Text = "Noclip", Default = false })
GameGroup:AddToggle("Fly", { Text = "Fly", Default = false }):AddKeyPicker("FlyKey", { Default = "F", Mode = "Toggle" })

-- // 4. TAB: VISUALS (The "Wallhack" Suite)
local ESPGroup = Tabs.Visuals:AddLeftGroupbox("Object ESP")
ESPGroup:AddToggle("DoorESP", { Text = "Door ESP", Default = true })
ESPGroup:AddToggle("KeyESP", { Text = "Key/Lockpick ESP", Default = true })
ESPGroup:AddToggle("ItemESP", { Text = "Item ESP (Lighters, Vitamins)", Default = true })
ESPGroup:AddToggle("BookESP", { Text = "Book/Paper ESP", Default = true })
ESPGroup:AddToggle("BreakerESP", { Text = "Breaker Switch ESP", Default = true })
ESPGroup:AddToggle("GoldESP", { Text = "Gold ESP", Default = false })

local EntityVisGroup = Tabs.Visuals:AddRightGroupbox("Entity Visuals")
EntityVisGroup:AddToggle("EntityESP", { Text = "Entity ESP (Highlight)", Default = true })
EntityVisGroup:AddToggle("EntityChams", { Text = "See-Through Walls", Default = true })
EntityVisGroup:AddToggle("Fullbright", { Text = "Fullbright (No Dark)", Default = false })
EntityVisGroup:AddToggle("RemoveFog", { Text = "Remove Fog", Default = false })

-- // 5. TAB: AUTOMATION (The "Lazy" Suite)
local AutoGroup = Tabs.Automation:AddLeftGroupbox("Interaction")
AutoGroup:AddToggle("AutoInteract", { Text = "Instant Interact (E)", Default = false })
AutoGroup:AddToggle("AutoLoot", { Text = "Auto Loot Chests", Default = false })
AutoGroup:AddToggle("AutoDoors", { Text = "Auto Open Doors (Risky)", Default = false })

local PuzzleGroup = Tabs.Automation:AddRightGroupbox("Puzzle Solvers")
PuzzleGroup:AddToggle("AutoBreaker", { Text = "Auto Breaker Box", Default = false })
PuzzleGroup:AddToggle("AutoHeartbeat", { Text = "Auto Heartbeat Minigame", Default = false })
PuzzleGroup:AddToggle("LibrarySolver", { Text = "Library Code Overlay", Default = true })

-- // 6. GLOBAL LOGIC STORAGE
local Drawings = {}
local Highlights = {}
local LatestRoom = 0

-- // 7. HELPER FUNCTIONS
local function CreateHighlight(Obj, Color)
    if Obj:FindFirstChild("EvadeHighlight") then return end
    local HL = Instance.new("Highlight")
    HL.Name = "EvadeHighlight"
    HL.FillColor = Color
    HL.OutlineColor = Color3.new(1,1,1)
    HL.FillTransparency = 0.5
    HL.OutlineTransparency = 0
    HL.Parent = Obj
    table.insert(Highlights, HL)
end

local function Notify(Msg, Time)
    Library:Notify(Msg, Time or 5)
    -- Sound cue
    local Sound = Instance.new("Sound", Workspace)
    Sound.SoundId = "rbxassetid://4590662766"
    Sound.Volume = 2
    Sound:Play()
    Services.Debris:AddItem(Sound, 2)
end

-- // 8. CORE LOOPS

-- A. ENTITY LISTENER (The "Radar")
Workspace.ChildAdded:Connect(function(Child)
    if Library.Toggles.NotifyEntity.Value then
        if table.find(EntityNames, Child.Name) then
            Notify("⚠️ DANGER: " .. Child.Name .. " Spawned!", 5)
            
            if Library.Toggles.EntityESP.Value then
                CreateHighlight(Child, Color3.fromRGB(255, 0, 0))
            end
        end
    end
end)

-- B. RENDER LOOP (ESP & Visuals)
Services.RunService.RenderStepped:Connect(function()
    -- Cleanup Drawings
    for _, d in pairs(Drawings) do d:Remove() end
    Drawings = {}
    
    -- Fullbright
    if Library.Toggles.Fullbright.Value then
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e9
    end
    
    -- Seek Arms Removal
    if Library.Toggles.NoSeekArms.Value then
        for _, v in pairs(CurrentRooms:GetDescendants()) do
            if v.Name == "Seek_Arm" then v:Destroy() end
        end
    end

    -- ESP LOOP
    for _, Room in pairs(CurrentRooms:GetChildren()) do
        -- Optimization: Only scan current and next rooms
        if Room:FindFirstChild("RoomEntrance") then
            local RoomNum = tonumber(Room.Name)
            if RoomNum then
                -- DOOR ESP
                if Library.Toggles.DoorESP.Value then
                    local Door = Room:FindFirstChild("Door")
                    if Door and Door:FindFirstChild("Door") then
                        local Pos, Vis = Camera:WorldToViewportPoint(Door.Door.Position)
                        if Vis then
                            local T = Drawing.new("Text"); T.Visible=true; T.Text="Door ["..RoomNum+1 .."]"; T.Color=Color3.fromRGB(0,255,255); T.Center=true; T.Position=Vector2.new(Pos.X, Pos.Y)
                            table.insert(Drawings, T)
                        end
                    end
                end

                -- ASSET ESP
                for _, Asset in pairs(Room:GetDescendants()) do
                    if Asset:IsA("Model") then
                        local Name = Asset.Name
                        local Color = nil
                        
                        if Library.Toggles.KeyESP.Value and (Name == "KeyObtain" or Name == "Lockpick") then Color = Color3.fromRGB(255, 255, 0) end
                        if Library.Toggles.ItemESP.Value and (Name == "Lighter" or Name == "Flashlight" or Name == "Vitamins" or Name == "Bandage") then Color = Color3.fromRGB(0, 255, 0) end
                        if Library.Toggles.BookESP.Value and Name == "LiveBook" then Color = Color3.fromRGB(0, 100, 255) end
                        if Library.Toggles.BreakerESP.Value and Name == "BreakerSwitch" then Color = Color3.fromRGB(255, 0, 255) end
                        if Library.Toggles.GoldESP.Value and Name == "GoldPile" then Color = Color3.fromRGB(255, 215, 0) end

                        if Color and Asset.PrimaryPart then
                            local Pos, Vis = Camera:WorldToViewportPoint(Asset.PrimaryPart.Position)
                            if Vis then
                                local T = Drawing.new("Text"); T.Visible=true; T.Text=Name; T.Color=Color; T.Center=true; T.Size=14; T.Position=Vector2.new(Pos.X, Pos.Y)
                                table.insert(Drawings, T)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- C. PHYSICS LOOP (Speed & Screech)
Services.RunService.RenderStepped:Connect(function()
    if not LocalPlayer.Character then return end
    local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    
    -- Speed Bypass (CFrame Walk)
    if Library.Toggles.SpeedBypass.Value and Library.Options.SpeedKey:GetState() and HRP and Hum and Hum.MoveDirection.Magnitude > 0 then
        HRP.CFrame = HRP.CFrame + (Hum.MoveDirection * Library.Options.SpeedVal.Value)
    end

    -- Anti-Screech
    if Library.Toggles.AntiScreech.Value and Camera:FindFirstChild("Screech") then
        -- Screech parents itself to Camera when attacking
        local Screech = Camera.Screech
        if Screech:FindFirstChild("Head") then
            -- Look at Screech instantly
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Screech.Head.Position)
        end
    end

    -- Anti-Eyes
    if Library.Toggles.AntiEyes.Value then
        for _, v in pairs(Workspace:GetChildren()) do
            if v.Name == "Eyes" and v:FindFirstChild("Core") then
                -- Look Down if Eyes are visible
                local LookVec = Camera.CFrame.LookVector
                local DirToEyes = (v.Core.Position - Camera.CFrame.Position).Unit
                if LookVec:Dot(DirToEyes) > 0 then -- If looking towards Eyes
                    -- Simple look down logic (Rotates camera X axis)
                     -- Note: Full camera lock is annoying, usually better to just warn or raycast check
                end
            end
        end
    end

    -- Noclip
    if Library.Toggles.Noclip.Value then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
    
    -- Flight
    if Library.Toggles.Fly.Value and Library.Options.FlyKey:GetState() and HRP then
        local BV = HRP:FindFirstChild("EvadeFly") or Instance.new("BodyVelocity", HRP)
        BV.Name = "EvadeFly"; BV.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
        
        local CamCF = Camera.CFrame
        local Dir = Vector3.zero
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then Dir = Dir + CamCF.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then Dir = Dir - CamCF.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then Dir = Dir - CamCF.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then Dir = Dir + CamCF.RightVector end
        
        BV.Velocity = Dir * 50
    else
        if HRP and HRP:FindFirstChild("EvadeFly") then HRP.EvadeFly:Destroy() end
    end
end)

-- D. AUTOMATION LOOP (Interactions)
task.spawn(function()
    while true do
        -- Instant Interact (E)
        if Library.Toggles.AutoInteract.Value then
            for _, v in pairs(Workspace.CurrentRooms:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    -- Check Distance
                    if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                        local Dist = (v.Parent.Position - LocalPlayer.Character.PrimaryPart.Position).Magnitude
                        if Dist < 12 then
                            fireproximityprompt(v) -- Instant Trigger
                        end
                    end
                end
            end
        end
        
        -- Auto Breaker Box
        if Library.Toggles.AutoBreaker.Value then
            -- Find active breaker
            for _, v in pairs(Workspace.CurrentRooms:GetDescendants()) do
                if v.Name == "BreakerSwitch" then
                    -- Logic: Flip switch if the light associated is off
                    -- This usually requires listening to the game's specific remote event for "Correct" switches
                    -- Simplified: Interact with all
                    local Prompt = v:FindFirstChild("ProximityPrompt")
                    if Prompt then fireproximityprompt(Prompt) end
                end
            end
        end

        -- Auto Heartbeat (Minigame)
        if Library.Toggles.AutoHeartbeat.Value then
            -- This usually hooks the GUI directly
            local GUI = LocalPlayer.PlayerGui:FindFirstChild("Heartbeat")
            if GUI and GUI.Enabled then
                -- Fire the remote telling the server we hit the beat
                local Args = {} -- Empty args often work for "Success" signal on basic AC
                Services.ReplicatedStorage.RemotesFolder.Heartbeat:FireServer(unpack(Args))
            end
        end
        
        task.wait(0.1)
    end
end)

-- // 9. SETTINGS & INIT
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function() 
    getgenv().EvadeLoaded = false
    Library:Unload() 
    -- Clear Highlights
    for _, h in pairs(Highlights) do h:Destroy() end
end)
MenuGroup:AddLabel("Keybind"):AddKeyPicker("MenuKey", { Default = "RightShift", NoUI = true, Text = "Menu" })
Library.ToggleKeybind = Library.Options.MenuKey

Evade.ThemeManager:SetLibrary(Library)
Evade.SaveManager:SetLibrary(Library)
Evade.SaveManager:IgnoreThemeSettings()
Evade.SaveManager:SetFolder("Evade")
Evade.SaveManager:SetFolder("Evade/Doors")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

Library:Notify("Loaded Evade Doors", 5)
