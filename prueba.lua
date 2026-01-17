local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/Beta.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- 1. CONFIGURACIÓN DE LA VENTANA
local Window = Fluent:CreateWindow({
    Title = "SURVIVE THE KILLER",
    SubTitle = "Premium Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

-- 2. PESTAÑAS
local Tabs = {
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "user" }), 
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }) 
}

-- 3. VARIABLES DE CONTROL
local Options = {
    KillerESP = false,
    SurvivorESP = false,
    Noclip = false,
    InfJump = false,
    WalkSpeed = 16,
    AutoRevive = false -- Nueva variable para el toggle
}

-------------------------------------------------------------------
-- CONFIGURACIÓN DE MANAGERS
-------------------------------------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("FluentSettings")
SaveManager:SetFolder("FluentSettings/STK-Premium")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-------------------------------------------------------------------
-- LÓGICA DE AUTO REVIVE (REACCIÓN A CAMBIOS EN HEALTH)
-------------------------------------------------------------------
local function checkAndTeleport(targetChar)
    if not Options.AutoRevive then return end
    
    local lp = game.Players.LocalPlayer
    local hum = targetChar:FindFirstChild("Humanoid")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    local lpRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")

    if hum and targetRoot and lpRoot then
        -- Detectamos si el jugador ha caído (Salud entre 0 y 1)
        if hum.Health <= 1 and hum.Health > 0 then
            
            -- Localizamos al Killer para la distancia de seguridad
            local killerRoot = nil
            for _, p in pairs(game.Players:GetPlayers()) do
                if p.Team and p.Team.Name == "Killer" and p.Character then
                    killerRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    break
                end
            end

            -- REGLA: Distancia de 5 Studs entre el caído y el Killer
            local isSafe = true
            if killerRoot then
                local distance = (targetRoot.Position - killerRoot.Position).Magnitude
                if distance < 5 then
                    isSafe = false
                end
            end

            if isSafe then
                lpRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2)
                Fluent:Notify({
                    Title = "Auto Revive",
                    Content = "Rescatando a " .. targetChar.Name,
                    Duration = 1.5
                })
                task.wait(2.5) -- Pausa para que el servidor registre la reanimación
            end
        end
    end
end

-- Monitor de eventos de salud
local function monitorHealth(p)
    p.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 10)
        if hum then
            hum:GetPropertyChangedSignal("Health"):Connect(function()
                checkAndTeleport(char)
            end)
        end
    end)
    
    if p.Character and p.Character:FindFirstChild("Humanoid") then
        p.Character.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            checkAndTeleport(p.Character)
        end)
    end
end

-- Conectar a jugadores actuales y nuevos
for _, p in pairs(game.Players:GetPlayers()) do
    if p ~= game.Players.LocalPlayer then monitorHealth(p) end
end
game.Players.PlayerAdded:Connect(monitorHealth)

-------------------------------------------------------------------
-- PESTAÑA SETTINGS (TEMAS)
-------------------------------------------------------------------
local ThemeDropdown = Tabs.Settings:AddDropdown("ThemeDropdown", {
    Title = "Theme",
    Description = "Changes the interface theme.",
    Values = {"Dark", "Darker", "AMOLED", "Light", "Balloon", "SoftCream", "Aqua", "Amethyst", "Rose", "Midnight", "Forest", "Sunset", "Ocean", "Emerald", "Sapphire", "Cloud", "Grape", "Bloody", "Arctic" },
    Default = "Dark",
    Callback = function(Value)
        Fluent:SetTheme(Value)
    end
})

-------------------------------------------------------------------
-- PESTAÑAS DE FUNCIONES (VISUALS & MOVEMENT)
-------------------------------------------------------------------

-- VISUALS
Tabs.Visuals:AddToggle("KillT", {Title = "ESP Killer"}):OnChanged(function(v) Options.KillerESP = v end)
Tabs.Visuals:AddToggle("SurvT", {Title = "ESP Survivor"}):OnChanged(function(v) Options.SurvivorESP = v end)

-- MOVEMENT
Tabs.Movement:AddSlider("SpeedSlider", {
    Title = "WalkSpeed Changer",
    Default = 16, Min = 16, Max = 150, Rounding = 1,
    Callback = function(v) Options.WalkSpeed = v end
})
Tabs.Movement:AddToggle("ReviveT", {
    Title = "Auto Revive (Health Event)",
    Description = "TP si el Killer está a +5 studs del herido",
    Default = false
}):OnChanged(function(v) Options.AutoRevive = v end)

Tabs.Movement:AddToggle("JumpT", {Title = "Infinite Jump"}):OnChanged(function(v) Options.InfJump = v end)
Tabs.Movement:AddToggle("NocT", {Title = "Noclip"}):OnChanged(function(v) Options.Noclip = v end)

-------------------------------------------------------------------
-- LÓGICA DE BUCLE (Speed, ESP, etc.)
-------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

RunService.Stepped:Connect(function()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = Options.WalkSpeed
    end

    if Options.Noclip and player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Team then
            local highlight = p.Character:FindFirstChild("ESPHighlight")
            local color = nil
            -- Equipo "Killer" con K mayúscula
            if Options.KillerESP and p.Team.Name == "Killer" then color = Color3.fromRGB(255,0,0)
            elseif Options.SurvivorESP and p.Team.Name == "Survivor" then color = Color3.fromRGB(0,255,255) end
            
            if color then
                if not highlight then
                    highlight = Instance.new("Highlight", p.Character)
                    highlight.Name = "ESPHighlight"
                end
                highlight.FillColor = color
            elseif highlight then highlight:Destroy() end
        end
    end
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
    if Options.InfJump and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:ChangeState("Jumping")
    end
end)

-- Carga automática de la configuración guardada
SaveManager:LoadAutoloadConfig()

Window:SelectTab(1)
Fluent:Notify({Title = "Survive The Killer", Content = "Script cargado con éxito. Distancia de seguridad: 5 studs.", Duration = 5})
