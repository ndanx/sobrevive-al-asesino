local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/Beta.lua"))()

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
    AutoRevive = false -- Nueva variable para Auto Revive
}

-------------------------------------------------------------------
-- PESTAÑA SETTINGS
-------------------------------------------------------------------

local ThemeDropdown = Tabs.Settings:AddDropdown("ThemeDropdown", {
    Title = "Theme",
    Values = {"Dark", "Darker", "AMOLED", "Light", "Balloon", "SoftCream", "Aqua", "Amethyst", "Rose", "Midnight", "Forest", "Sunset", "Ocean", "Emerald", "Sapphire", "Cloud", "Grape", "Bloody", "Arctic" },
    Default = "Dark",
    Callback = function(Value)
        Fluent:SetTheme(Value)
    end
})

-------------------------------------------------------------------
-- PESTAÑAS DE FUNCIONES
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
Tabs.Movement:AddToggle("JumpT", {Title = "Infinite Jump"}):OnChanged(function(v) Options.InfJump = v end)
Tabs.Movement:AddToggle("NocT", {Title = "Noclip"}):OnChanged(function(v) Options.Noclip = v end)

-- Agregamos el Toggle de Auto Revive aquí
Tabs.Movement:AddToggle("ReviveT", {
    Title = "Auto Revive", 
    Description = "Revive automáticamente a compañeros cercanos."
}):OnChanged(function(v) 
    Options.AutoRevive = v 
end)

-------------------------------------------------------------------
-- LÓGICA DE BUCLE (Speed, ESP, Auto-Revive, etc.)
-------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

RunService.Stepped:Connect(function()
    -- Lógica de WalkSpeed
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = Options.WalkSpeed
    end

    -- Lógica de Noclip
    if Options.Noclip and player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    -- Bucle para ESP y Auto Revive
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            
            -- Lógica de ESP (Killer y Survivor)
            local highlight = p.Character:FindFirstChild("ESPHighlight")
            local color = nil
            if Options.KillerESP and p.Team and p.Team.Name == "Killer" then 
                color = Color3.fromRGB(255,0,0)
            elseif Options.SurvivorESP and p.Team and p.Team.Name == "Survivor" then 
                color = Color3.fromRGB(0,255,255) 
            end
            
            if color then
                if not highlight then
                    highlight = Instance.new("Highlight", p.Character)
                    highlight.Name = "ESPHighlight"
                end
                highlight.FillColor = color
            elseif highlight then 
                highlight:Destroy() 
            end

            -- LÓGICA DE AUTO REVIVE
            if Options.AutoRevive and p.Team and p.Team.Name == "Survivor" then
                -- Verificamos si el jugador está caído (en este juego suelen tener salud baja o un valor "Downed")
                if p.Character.Humanoid.Health <= 30 then 
                    local distance = (player.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if distance < 15 then -- Si estás a menos de 15 studs
                        -- Disparamos el evento de revivir (esto depende de la estructura del juego)
                        -- Normalmente es un RemoteEvent llamado 'Revive' o similar
                        game:GetService("ReplicatedStorage").Events.RevivePlayer:FireServer(p.Name)
                    end
                end
            end
        end
    end
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
    if Options.InfJump and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:ChangeState("Jumping")
    end
end)

Window:SelectTab(1)
Fluent:Notify({Title = "Survive The Killer", Content = "Auto Revive añadido en Movement.", Duration = 5})
