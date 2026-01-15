local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- 1. CONFIGURACIÓN DE LA VENTANA
local Window = Fluent:CreateWindow({
    Title = "Sobrevive al Asesino",
    SubTitle = "Premium Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl -- Tecla inicial
})

-- 2. PESTAÑAS (Con los iconos que pediste)
local Tabs = {
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "user" }), -- Icono de persona
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }) -- Icono de engranaje
}

-- 3. VARIABLES DE ESTADO
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
    Callback = function(Value) Options.WalkSpeed = Value end
})

Tabs.Movement:AddToggle("JumpToggle", {Title = "Infinite Jump", Default = false}):OnChanged(function(Value)
    Options.InfJump = Value
end)

Tabs.Movement:AddToggle("NoclipToggle", {Title = "Noclip", Default = false}):OnChanged(function(Value)
    Options.Noclip = Value
end)

-------------------------------------------------------------------
-- PESTAÑA SETTINGS (Configuración de Tecla)
-------------------------------------------------------------------
Tabs.Settings:AddKeybind("MinimizeBind", {
    Title = "Abrir/Cerrar Menú",
    Mode = "Toggle", 
    Default = "RightControl", -- Tecla por defecto

    Callback = function(Value)
        -- Esta función se encarga de cambiar la tecla real del sistema
        Window:SetMinimizeKey(Value)
    end,

    -- Esto ocurre cuando cambias la tecla en el menú
    ChangedCallback = function(NewBind)
        Fluent:Notify({
            Title = "Ajustes Guardados",
            Content = "Nueva tecla para el Hub: " .. tostring(NewBind),
            Duration = 3
        })
    end
})

-------------------------------------------------------------------
-- BUCLE DE LÓGICA (ESP, Speed, Noclip, Jump)
-------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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
            local char = p.Character
            local highlight = char:FindFirstChild("ESPHighlight")
            local color = nil
            if Options.KillerESP and p.Team.Name == "Killer" then color = Color3.fromRGB(255, 0, 0)
            elseif Options.SurvivorESP and p.Team.Name == "Survivor" then color = Color3.fromRGB(0, 255, 255) end
            
            if color then
                if not highlight then
                    highlight = Instance.new("Highlight", char)
                    highlight.Name = "ESPHighlight"
                end
                highlight.FillColor = color
            elseif highlight then highlight:Destroy() end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Options.InfJump and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:ChangeState("Jumping")
    end
end)

-- Notificación final
Fluent:Notify({
    Title = "Sobrevive al asesino",
    Content = "Hub configurado. Ve a 'Settings' para cambiar la tecla de cerrado.",
    Duration = 5
})

Window:SelectTab(1)
