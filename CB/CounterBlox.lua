-- [[ EVADE.GG | COUNTER BLOX CORE (v30.0) ]]
local Evade = getgenv().Evade
if not Evade then return end

local Services = Evade.Services
local Library = Evade.Library
local LocalPlayer = Evade.LocalPlayer
local Camera = Evade.Camera

-- // HELPERS
local Drawings = { World = {}, Tracers = {}, Beams = {} }
local function AddDrawing(Type, Props)
    local D = Drawing.new(Type)
    for k,v in pairs(Props) do D[k] = v end
    table.insert(Drawings.World, D)
    return D
end
local function ClearWorld() for _, d in pairs(Drawings.World) do d:Remove() end; Drawings.World = {} end
local function GetScreenPos(Pos)
    local Vec, Vis = Camera:WorldToViewportPoint(Pos)
    return Vector2.new(Vec.X, Vec.Y), Vis
end

-- // 1. THUNDER FOV & ZOOM (High Priority)
local ProxyFOV = Instance.new("NumberValue"); ProxyFOV.Value = 90
local IsZooming = false

Services.RunService:BindToRenderStep("EvadeFOV", 2001, function() -- Priority > Camera(2000)
    if IsZooming and Library.Toggles.ZoomEnabled.Value then
        Camera.FieldOfView = Library.Options.ZoomFOV.Value
    elseif Library.Toggles.FOVEnabled.Value then
        Camera.FieldOfView = Library.Options.BaseFOV.Value
    end
end)

Services.UserInputService.InputBegan:Connect(function(I, P)
    if not P and I.KeyCode == Enum.KeyCode.Z then IsZooming = true end
end)
Services.UserInputService.InputEnded:Connect(function(I)
    if I.KeyCode == Enum.KeyCode.Z then IsZooming = false end
end)

-- // 2. TRIGGERBOT (New)
task.spawn(function()
    while true do
        task.wait()
        if Library.Toggles.TriggerBot.Value then
            local Mouse = LocalPlayer:GetMouse()
            if Mouse.Target and Mouse.Target.Parent then
                local Plr = Services.Players:GetPlayerFromCharacter(Mouse.Target.Parent)
                if Plr and Plr.Team ~= LocalPlayer.Team then
                    task.wait(Library.Options.TriggerDelay.Value / 1000)
                    mouse1click()
                    task.wait(0.1) -- Refire delay
                end
            end
        end
    end
end)

-- // 3. GUN MODS (Client Env)
task.spawn(function()
    while true do
        task.wait(0.5)
        local Env = getsenv(LocalPlayer.PlayerGui.Client)
        if Env then
            if Library.Toggles.NoRecoil.Value then Env.RecoilX = 0; Env.RecoilY = 0 end
            if Library.Toggles.NoSpread.Value then Env.CurrentSpread = 0 end
            if Library.Toggles.FastPlant.Value then Env.plantprogress = 5 end
            if Library.Toggles.InfAmmo.Value then 
                pcall(function() LocalPlayer.PlayerGui.GUI.Client.Variables.ammocount.Value = 999 end)
            end
        end
    end
end)

-- // 4. MAIN RENDER LOOP
Services.RunService.RenderStepped:Connect(function()
    -- A. HITBOX EXPANDER
    if Library.Toggles.HitboxExpander.Value then
        local Size = Library.Options.HitboxSize.Value
        local Trans = Library.Options.HitboxTrans.Value
        for _, Plr in pairs(Services.Players:GetPlayers()) do
            if Plr ~= LocalPlayer and Plr.Team ~= LocalPlayer.Team and Plr.Character then
                pcall(function()
                    local HB = Plr.Character:FindFirstChild("HeadHB")
                    if HB then HB.CanCollide = false; HB.Size = Vector3.new(Size, Size, Size); HB.Transparency = Trans end
                end)
            end
        end
    end

    -- B. VISUALS
    if Library.Toggles.NoFlash.Value then pcall(function() LocalPlayer.PlayerGui.Blnd.Blind.Visible = false end) end
    
    if Library.Toggles.NoSmoke.Value then
        for _,v in pairs(Services.Workspace:GetDescendants()) do 
            if v.Name == "Smoke" and v:IsA("Part") then v.Transparency = 1; if v:FindFirstChild("SmokeParticle") then v.SmokeParticle.Enabled = false end end
        end
    end
    
    if Library.Toggles.NightMode.Value then Services.Lighting.ClockTime = 0 else Services.Lighting.ClockTime = 14 end
    
    if Library.Toggles.Ambience.Value then Services.Lighting.Ambient = Color3.fromRGB(100,0,255) end

    -- C. ARMS
    local Arms = Camera:FindFirstChild("Arms")
    if Arms then
        for _, v in pairs(Arms:GetChildren()) do
            if v:IsA("MeshPart") then
                if Library.Toggles.WireframeArms.Value then v.Material = Enum.Material.ForceField else v.Material = Enum.Material.Plastic end
                if Library.Toggles.RainbowArms.Value then v.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1) end
            end
        end
    end
    
    if Library.Toggles.NoScope.Value then
        local Scope = LocalPlayer.PlayerGui.GUI.Crosshairs:FindFirstChild("Scope")
        if Scope then Scope.Visible = false end
    end

    -- D. WORLD ESP (New Features)
    ClearWorld()
    if Library.Toggles.DropEsp.Value or Library.Toggles.NadeEsp.Value or Library.Toggles.C4Esp.Value or Library.Toggles.KitEsp.Value or Library.Toggles.HostageEsp.Value then
        local Scan = {}
        if Services.Workspace:FindFirstChild("Debris") then for _,v in pairs(Services.Workspace.Debris:GetChildren()) do table.insert(Scan, v) end end
        for _,v in pairs(Services.Workspace:GetChildren()) do table.insert(Scan, v) end
        -- Hostages usually in Map
        if Services.Workspace:FindFirstChild("Map") then for _,v in pairs(Services.Workspace.Map:GetDescendants()) do if v.Name == "Hostage" then table.insert(Scan, v) end end end

        for _, v in pairs(Scan) do
            -- Guns
            if Library.Toggles.DropEsp.Value and (v.Name == "GunDrop" or v:FindFirstChild("GunState")) then
                local H = v:FindFirstChild("Handle") or v.PrimaryPart
                if H then
                    local Pos, Vis = GetScreenPos(H.Position)
                    if Vis then
                         local Name = "Gun"; for _,c in pairs(v:GetChildren()) do if c:IsA("StringValue") and c.Name=="Weapon" then Name = c.Value end end
                         AddDrawing("Text", {Text=Name, Position=Pos, Size=13, Center=true, Outline=true, Color=Color3.fromRGB(200,200,200), Visible=true})
                    end
                end
            end
            -- C4
            if Library.Toggles.C4Esp.Value and v.Name == "C4" then
                local Pos, Vis = GetScreenPos(v.Position)
                if Vis then AddDrawing("Text", {Text="C4", Position=Pos, Size=14, Center=true, Outline=true, Color=Color3.fromRGB(255,150,0), Visible=true}) end
            end
            -- Nades
            if Library.Toggles.NadeEsp.Value and (v.Name == "HE" or v.Name == "Flash" or v.Name == "Smoke" or v.Name == "Molotov") then
                 local H = v:FindFirstChild("Handle")
                 if H then
                     local Pos, Vis = GetScreenPos(H.Position)
                     if Vis then AddDrawing("Text", {Text=v.Name, Position=Pos, Size=12, Center=true, Outline=true, Color=Color3.fromRGB(255,255,255), Visible=true}) end
                 end
            end
            -- Kits
            if Library.Toggles.KitEsp.Value and v.Name == "Defuse Kit" then
                local Pos, Vis = GetScreenPos(v.Position)
                if Vis then AddDrawing("Text", {Text="KIT", Position=Pos, Size=13, Center=true, Outline=true, Color=Color3.fromRGB(0,150,255), Visible=true}) end
            end
            -- Hostages
            if Library.Toggles.HostageEsp.Value and v.Name == "Hostage" then
                local Pos, Vis = GetScreenPos(v.Position)
                if Vis then AddDrawing("Text", {Text="HOSTAGE", Position=Pos, Size=14, Center=true, Outline=true, Color=Color3.fromRGB(0,255,0), Visible=true}) end
            end
        end
    end
end)

-- // 5. MOVEMENT
Services.RunService.Stepped:Connect(function()
    if Library.Toggles.Bhop.Value and LocalPlayer.Character then
        local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if Hum and Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) and Hum.FloorMaterial ~= Enum.Material.Air then
            Hum.Jump = true
        end
    end
    if Library.Toggles.SpeedHack.Value and LocalPlayer.Character then
        local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if Hum then Hum.WalkSpeed = Library.Options.SpeedVal.Value end
    end
    if Library.Toggles.AutoPistol.Value and Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
         -- Handled via Click release logic if possible, or just let user hold click and we pulse signal
    end
end)

-- // 6. MISC
task.spawn(function()
    while true do
        task.wait(0.1)
        if Library.Toggles.AutoDefuse.Value and LocalPlayer.Team.Name == "Counter-Terrorists" then
            local C4 = Services.Workspace:FindFirstChild("C4")
            if C4 and (LocalPlayer.Character.HumanoidRootPart.Position - C4.Position).Magnitude < 10 then
                -- Simulate Defuse
                keypress(Enum.KeyCode.E)
            end
        end
    end
end)

-- // UNLOAD
getgenv().Evade.UnloadCore = function()
    ClearWorld()
    Services.RunService:UnbindFromRenderStep("EvadeFOV")
end
