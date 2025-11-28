-- // MODULE HEADER
repeat task.wait() until getgenv().Evade
local Evade = getgenv().Evade

local StartTime = tick()
repeat task.wait() until Evade.Library or (tick() - StartTime > 10)
if not Evade.Library then warn("[Evade] Library Missing"); return end

-- // IMPORTS
local Library = Evade.Library
local Services = Evade.Services
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera
local Workspace = Services.Workspace
local Lighting = Services.Lighting

-- // UI SETUP
local Window = Library:CreateWindow({
    Title = "Evade | Pressure",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Main = Window:AddTab("Main"),
    Visuals = Window:AddTab("Visuals"),
    Settings = Window:AddTab("Settings")
}

-- // FEATURES
local EntityGroup = Tabs.Main:AddLeftGroupbox("Safety")
EntityGroup:AddToggle("NotifyEntity", { Text = "Entity Radar", Default = true })
EntityGroup:AddToggle("AntiBlind", { Text = "No Blindness", Default = false })

local ESPGroup = Tabs.Visuals:AddLeftGroupbox("ESP")
ESPGroup:AddToggle("LockerESP", { Text = "Locker ESP", Default = true })
ESPGroup:AddToggle("ItemESP", { Text = "Item/Keycard ESP", Default = true })
ESPGroup:AddToggle("MonsterESP", { Text = "Monster ESP", Default = true })

local WorldGroup = Tabs.Visuals:AddRightGroupbox("World")
WorldGroup:AddToggle("Fullbright", { Text = "Fullbright", Default = false })
WorldGroup:AddToggle("NoFog", { Text = "Remove Fog", Default = false })

-- // LOGIC
local EntityNames = {"Angler", "Pandemonium", "Froger", "Pinkie", "WallDweller", "Searchlight"}
local Drawings = {}

-- 1. ENTITY LISTENER
Workspace.ChildAdded:Connect(function(Child)
    if Library.Toggles.NotifyEntity.Value then
        -- Check against known monster names
        for _, Name in pairs(EntityNames) do
            if Child.Name:find(Name) then
                Library:Notify("⚠️ MONSTER DETECTED: " .. Child.Name, 5)
                
                -- Highlight
                if Library.Toggles.MonsterESP.Value then
                    local HL = Instance.new("Highlight")
                    HL.Parent = Child
                    HL.FillColor = Color3.fromRGB(255, 0, 0)
                    HL.OutlineColor = Color3.fromRGB(255, 255, 255)
                end
                break
            end
        end
    end
end)

-- 2. RENDER LOOP
Services.RunService.RenderStepped:Connect(function()
    -- Cleanup
    for _, d in pairs(Drawings) do d:Remove() end
    Drawings = {}

    -- Lighting
    if Library.Toggles.Fullbright.Value then
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
    end
    
    if Library.Toggles.NoFog.Value then
        Lighting.FogEnd = 100000
        -- Pressure uses custom atmosphere sometimes, remove it
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") or v:IsA("FogEnd") then v:Destroy() end
        end
    end

    -- Blindness Removal
    if Library.Toggles.AntiBlind.Value then
        local GUI = LocalPlayer.PlayerGui:FindFirstChild("Main")
        if GUI then
            local Blind = GUI:FindFirstChild("Blindness")
            if Blind then Blind.Visible = false end
        end
    end

    -- ESP Scanning (Rooms)
    -- Pressure uses a similar room generation system to Doors
    -- Usually stored in workspace.Rooms or workspace.CurrentRooms
    local RoomContainer = Workspace:FindFirstChild("Rooms") or Workspace:FindFirstChild("CurrentRooms")
    
    if RoomContainer then
        for _, Room in pairs(RoomContainer:GetChildren()) do
            -- Locker ESP
            if Library.Toggles.LockerESP.Value then
                for _, Obj in pairs(Room:GetDescendants()) do
                    if Obj.Name == "Locker" or Obj.Name:find("Closet") then
                        if Obj.PrimaryPart then
                             local Pos, Vis = Camera:WorldToViewportPoint(Obj.PrimaryPart.Position)
                             if Vis then
                                 local T = Drawing.new("Text"); T.Visible=true; T.Text="Safe Spot"; T.Color=Color3.fromRGB(0,255,0); T.Center=true; T.Position=Vector2.new(Pos.X, Pos.Y)
                                 table.insert(Drawings, T)
                             end
                        end
                    end
                end
            end

            -- Item ESP
            if Library.Toggles.ItemESP.Value then
                for _, Obj in pairs(Room:GetDescendants()) do
                    if Obj:IsA("Model") and (Obj.Name:find("Keycard") or Obj.Name:find("Battery") or Obj.Name:find("Flashlight")) then
                        if Obj.PrimaryPart then
                             local Pos, Vis = Camera:WorldToViewportPoint(Obj.PrimaryPart.Position)
                             if Vis then
                                 local T = Drawing.new("Text"); T.Visible=true; T.Text=Obj.Name; T.Color=Color3.fromRGB(255,255,0); T.Center=true; T.Position=Vector2.new(Pos.X, Pos.Y)
                                 table.insert(Drawings, T)
                             end
                        end
                    end
                end
            end
        end
    end
end)

-- // SETTINGS
Evade.ThemeManager:SetLibrary(Library)
Evade.SaveManager:SetLibrary(Library)
Evade.SaveManager:IgnoreThemeSettings()
Evade.SaveManager:SetFolder("Evade")
Evade.SaveManager:SetFolder("Evade/Pressure")
Evade.SaveManager:BuildConfigSection(Tabs.Settings)
Evade.ThemeManager:ApplyToTab(Tabs.Settings)
Evade.SaveManager:LoadAutoloadConfig()

Library:Notify("Evade | Pressure Loaded", 5)
