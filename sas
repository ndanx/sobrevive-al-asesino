local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- 1. CONFIGURACIÓN DE LA VENTANA
local Window = Fluent:CreateWindow({
    Title = "SURVIVE THE KILLER",
    SubTitle = "Premium Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl -- Tecla fija para evitar errores
})

-- 2. PESTAÑAS
local Tabs = {
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "user" }), -- Icono de persona
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }) -- Icono de engranaje
}

-- 3. VARIABLES DE CONTROL
local Options = {
    KillerESP = false,
    SurvivorESP = false,
    Noclip = false,
    InfJump = false,
    WalkSpeed = 16
}

-------------------------------------------------------------------
-- PESTAÑA VISUALS
-------------------------------------------------------------------
Tabs.Visuals:AddToggle("KillerToggle", {Title = "ESP Killer", Default = false}):OnChanged(function(Value)
    Options.KillerESP = Value
end)

Tabs.Visuals:AddToggle("SurvivorToggle", {Title = "ESP Survivor", Default = false}):OnChanged(function(Value)
    Options.SurvivorESP = Value
end)

-------------------------------------------------------------------
-- PESTAÑA MOVEMENT
-------------------------------------------------------------------
Tabs.Movement:AddSlider("SpeedSlider", {
    Title = "WalkSpeed Changer",
    Description = "Ajusta tu velocidad",
    Default = 16,
    Min = 16,
    Max = 150,
    Rounding = 1,
    Callback = function(Value) 
        Options.WalkSpeed = Value 
    end
})

Tabs.Movement:AddToggle("JumpToggle", {Title = "Infinite Jump", Default = false}):OnChanged(function(Value)
    Options.InfJump = Value
end)

Tabs.Movement:AddToggle("NoclipToggle", {Title = "Noclip", Default = false}):OnChanged(function(Value)
    Options.Noclip = Value
end)

-------------------------------------------------------------------
-- PESTAÑA SETTINGS (Info fija)
-------------------------------------------------------------------
Tabs.Settings:AddParagraph({
    Title = "Información del Hub",
    Content = "Presiona 'Right Control' para abrir o cerrar el menú.\n\nEste Hub está diseñado para ser estable y fluido."
})

-------------------------------------------------------------------
-- LÓGICA DE FUNCIONAMIENTO
-------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

RunService.Stepped:Connect(function()
    -- Velocidad
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = Options.WalkSpeed
    end

    -- Noclip
    if Options.Noclip and player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    -- ESP
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Team then
            local highlight = p.Character:FindFirstChild("ESPHighlight")
            local color = nil
            if Options.KillerESP and p.Team.Name == "Killer" then 
                color = Color3.fromRGB(255, 0, 0)
            elseif Options.SurvivorESP and p.Team.Name == "Survivor" then 
                color = Color3.fromRGB(0, 255, 255) 
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
        end
    end
end)

-- Salto Infinito
UIS.JumpRequest:Connect(function()
    if Options.InfJump and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:ChangeState("Jumping")
    end
end)

Window:SelectTab(1)
Fluent:Notify({
    Title = "Survive The Killer",
    Content = "Cargado correctamente. Usa Right Control para minimizar.",
    Duration = 5
})
