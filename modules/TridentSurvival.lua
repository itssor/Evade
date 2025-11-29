-- plugintype = gamesupport
-- Source: Trident V13 (Memory Hook)
-- Logic: Uses debug.getupvalues to steal the internal Entity Table from the game client.

repeat task.wait() until getgenv().Evade
local Evade = getgenv().Evade

local StartTime = tick()
repeat task.wait() until Evade.Library or (tick() - StartTime > 10)
if not Evade.Library then warn("[Evade] Library Missing"); return end

local Library = Evade.Library
local Services = Evade.Services
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera
local Workspace = Services.Workspace

-- // UI SETUP
local Window = Library:CreateWindow({
    Title = "Evade | Trident (Memory)",
    Center = true, AutoShow = true, TabPadding = 8
})

Library.Font = Enum.Font.Ubuntu 

local Tabs = {
    Visuals = Window:AddTab("Visuals"),
    Combat = Window:AddTab("Combat"),
    Settings = Window:AddTab("Settings")
}

-- // FEATURES
local CombatGroup = Tabs.Combat:AddLeftGroupbox("Silent Aim")
CombatGroup:AddToggle("SilentAim", { Text = "Silent Aim", Default = false })
CombatGroup:AddSlider("FOV", { Text = "FOV Radius", Default = 150, Min = 10, Max = 800 })
CombatGroup:AddToggle("DrawFOV", { Text = "Draw FOV", Default = true })

local ESPGroup = Tabs.Visuals:AddLeftGroupbox("Memory ESP")
ESPGroup:AddToggle("ESP", { Text = "Enable ESP", Default = true })
ESPGroup:AddToggle("ESPBox", { Text = "Boxes", Default = true })
ESPGroup:AddToggle("ESPName", { Text = "Names", Default = true })
ESPGroup:AddToggle("ESPHealth", { Text = "Health Bar", Default = true })
ESPGroup:AddToggle("ESPTool", { Text = "Tool Name", Default = true })

local DebugGroup = Tabs.Settings:AddLeftGroupbox("Debug")
DebugGroup:AddLabel("Hook Status: Scanning...")

-- // LOGIC: MEMORY HOOK
local EntityTable = nil

local function AttemptHook()
    -- We scan the Garbage Collector for functions connected to the game's entity system
    -- This allows us to find the table even if we don't know the exact variable name
    
    local Candidates = {}
    
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            -- Heuristic: Look for tables that contain entity-like data
            -- Trident usually keys them by UUID or Name
            if rawget(v, "Health") and rawget(v, "MaxHealth") and rawget(v, "Model") then
                -- This is likely a SINGLE entity. We want the LIST of them.
            end
            
            -- Look for the MASTER LIST
            -- Usually contains many subtables
            local Count = 0
            local HasModel = false
            for _, sub in pairs(v) do
                if type(sub) == "table" and (rawget(sub, "Model") or rawget(sub, "Character")) then
                    Count = Count + 1
                    HasModel = true
                end
            end
            
            if Count > 2 and HasModel then
                -- This looks like the entity cache
                table.insert(Candidates, v)
            end
        end
    end
    
    -- If direct table scan fails, try Upvalues of known scripts
    if #Candidates == 0 then
        -- Look for functions in PlayerScripts
        for _, Func in pairs(getgc()) do
            if type(Func) == "function" and not is_synapse_function(Func) then
                local Info = debug.getinfo(Func)
                if Info.source and Info.source:find("Client") then
                    -- Scan upvalues of client scripts
                    local nups = Info.nups
                    for i = 1, nups do
                        local name, val = debug.getupvalue(Func, i)
                        if type(val) == "table" then
                            -- Check if this table holds entities
                            for _, sub in pairs(val) do
                                if type(sub) == "table" and (rawget(sub, "Model") or rawget(sub, "rootPart")) then
                                    EntityTable = val
                                    Library:Notify("Hooked Entity Table via " .. (name or "upvalue"), 5)
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
    else
        EntityTable = Candidates[1] -- Take best guess
        Library:Notify("Hooked Entity Table via GC", 5)
        return true
    end
    
    return false
end

-- Hook Loop (Retries until found)
task.spawn(function()
    while not EntityTable do
        local success = AttemptHook()
        if success then break end
        task.wait(2)
    end
end)

-- // LOGIC: RENDER LOOP
local Drawings = {}
local FOVCircle = Drawing.new("Circle"); FOVCircle.Thickness=1; FOVCircle.NumSides=64; FOVCircle.Filled=false; FOVCircle.Visible=false

Services.RunService.RenderStepped:Connect(function()
    -- FOV
    if Library.Toggles.DrawFOV.Value and Library.Toggles.SilentAim.Value then
        FOVCircle.Visible = true; FOVCircle.Radius = Library.Options.FOV.Value; FOVCircle.Color = Color3.new(1,1,1); FOVCircle.Position = Services.UserInputService:GetMouseLocation()
    else FOVCircle.Visible = false end

    -- Cleanup
    for _, d in pairs(Drawings) do d:Remove() end
    Drawings = {}

    -- ESP
    if Library.Toggles.ESP.Value and EntityTable then
        -- ITERATE THE INTERNAL TABLE
        for Key, Data in pairs(EntityTable) do
            -- Data usually looks like: {Model = Instance, Health = 100, MaxHealth = 100, ...}
            
            local Model = Data.Model or Data.Character or Data.Entity
            local Root = Model and (Model:FindFirstChild("HumanoidRootPart") or Model:FindFirstChild("Torso"))
            
            if Model and Root and Model ~= LocalPlayer.Character then
                local Pos, Vis = Camera:WorldToViewportPoint(Root.Position)
                
                if Vis then
                    -- Determine Data
                    -- Since we are reading raw memory, we grab the EXACT values
                    local HP = Data.Health or Data.HP or 100
                    local MaxHP = Data.MaxHealth or Data.MHP or 100
                    local Name = Data.Name or Model.Name
                    local Tool = "None"
                    
                    -- Check for Tool in Data first (More reliable)
                    if Data.Equipped or Data.Weapon or Data.Tool then
                        Tool = tostring(Data.Equipped or Data.Weapon or Data.Tool)
                    else
                        -- Fallback to Visual Scan
                         local T = Model:FindFirstChild("HandModel")
                         if T then Tool = "Equipped" end
                    end
                    
                    -- Draw Box
                    if Library.Toggles.ESPBox.Value then
                        local Dist = 1000 / Pos.Z
                        local Box = Drawing.new("Square")
                        Box.Visible = true
                        Box.Size = Vector2.new(2000/Pos.Z, 3500/Pos.Z)
                        Box.Position = Vector2.new(Pos.X - Box.Size.X/2, Pos.Y - Box.Size.Y/2)
                        Box.Color = Color3.fromRGB(255, 0, 0)
                        Box.Thickness = 1
                        Box.Filled = false
                        table.insert(Drawings, Box)
                    end
                    
                    -- Draw Name
                    if Library.Toggles.ESPName.Value then
                        local T = Drawing.new("Text")
                        T.Visible = true
                        T.Text = Name
                        T.Size = 13
                        T.Center = true
                        T.Outline = true
                        T.Color = Color3.new(1,1,1)
                        T.Position = Vector2.new(Pos.X, Pos.Y - (3500/Pos.Z)/2 - 15)
                        table.insert(Drawings, T)
                    end
                    
                    -- Draw Health
                    if Library.Toggles.ESPHealth.Value then
                        local Pct = math.clamp(HP/MaxHP, 0, 1)
                        local BarH = (3500/Pos.Z) * Pct
                        local Bar = Drawing.new("Square")
                        Bar.Visible = true; Bar.Filled = true
                        Bar.Color = Color3.fromHSV(Pct * 0.3, 1, 1)
                        Bar.Size = Vector2.new(2, BarH)
                        Bar.Position = Vector2.new(Pos.X - (2000/Pos.Z)/2 - 5, (Pos.Y - (3500/Pos.Z)/2) + ((3500/Pos.Z) - BarH))
                        table.insert(Drawings, Bar)
                    end
                    
                    -- Draw Tool
                    if Library.Toggles.ESPTool.Value and Tool ~= "None" then
                         local T = Drawing.new("Text")
                        T.Visible = true; T.Text = Tool; T.Size = 12
                        T.Center = true; T.Outline = true; T.Color = Color3.fromRGB(200, 200, 200)
                        T.Position = Vector2.new(Pos.X, (Pos.Y + (3500/Pos.Z)/2) + 5)
                        table.insert(Drawings, T)
                    end
                end
            end
        end
    end
end)

-- // SILENT AIM
local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if Library.Toggles.SilentAim.Value and method == "FindPartOnRayWithIgnoreList" and EntityTable then
        local Closest = nil
        local Shortest = Library.Options.FOV.Value
        local Mouse = Services.UserInputService:GetMouseLocation()
        
        for _, Data in pairs(EntityTable) do
            local Model = Data.Model or Data.Character
            if Model and Model:FindFirstChild("Head") then
                local Pos, Vis = Camera:WorldToViewportPoint(Model.Head.Position)
                if Vis then
                    local Dist = (Vector2.new(Pos.X, Pos.Y) - Mouse).Magnitude
                    if Dist < Shortest then Shortest = Dist; Closest = Model.Head end
                end
            end
        end
        
        if Closest then
            args[1] = Ray.new(args[1].Origin, (Closest.Position - args[1].Origin).Unit * 1000)
            return old(self, unpack(args))
        end
    end
    
    return old(self, ...)
end)
setreadonly(mt, true)

local Settings = Tabs.Settings:AddLeftGroupbox("Menu")
Settings:AddButton("Unload", function() getgenv().EvadeLoaded = false; for _, d in pairs(Drawings) do d:Remove() end; Library:Unload() end)

Library:Notify("Evade | Trident Loaded", 5)
