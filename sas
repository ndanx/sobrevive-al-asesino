local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- 1. CONFIGURACIÓN DE LA VENTANA
local Window = Fluent:CreateWindow({
    Title = "SOBREVIVE AL ASESINO",
    SubTitle = "Inmortal",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl -- Tecla por defecto inicial
})

-- 2. PESTAÑAS CON TUS ICONOS
local Tabs = {
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "user" }), -- Icono de Persona
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }) -- Icono de Engranaje
}

-- 3. VARIABLES DE CONTROL
local Options = {
    KillerESP = false,
    SurvivorESP = false,
    Noclip = false,
    InfJump = false,
    WalkSpeed = 16,
    MenuKey = Enum.KeyCode.RightControl -- Guardamos la tecla aquí para evitar errores
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
-- PESTAÑA SETTINGS (SOLUCIÓN AL ERROR DE CALLBACK)
-------------------------------------------------------------------
Tabs.Settings:AddKeybind("MenuBind", {
    Title = "Cambiar Tecla del Menú",
    Mode = "Toggle",
    Default = "RightControl",
    Callback = function(Value)
        Options.MenuKey = Value -- Actualizamos la tecla manualmente
    end,
    ChangedCallback = function(NewBind)
        Fluent:Notify({
            Title = "Ajustes Guardados",
            Content = "Nueva tecla asignada: " .. tostring(NewBind),
            Duration = 3
        })
    end
})

-- Sistema manual para abrir/cerrar sin que falle el método 'SetMinimizeKey'
game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Options.MenuKey then
        Window:Minimize()
    end
end)

-------------------------------------------------------------------
-- LÓGICA DE FUNCIONAMIENTO (BUCLE PRINCIPAL)
-------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

RunService.Stepped:Connect(function()
    -- Lógica de Velocidad
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = Options.WalkSpeed
    end

    -- Lógica de Noclip
    if Options.Noclip and player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    -- Lógica de ESP (Killer y Survivor)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Team then
            local char = p.Character
            local highlight = char:FindFirstChild("ESPHighlight")
            local color = nil
            
            if Options.KillerESP and p.Team.Name == "Killer" then 
                color = Color3.fromRGB(255, 0, 0)
            elseif Options.SurvivorESP and p.Team.Name == "Survivor" then 
                color = Color3.fromRGB(0, 255, 255) 
            end
            
            if color then
                if not highlight then
                    highlight = Instance.new("Highlight", char)
                    highlight.Name = "ESPHighlight"
                end
                highlight.FillColor = color
            elseif highlight then 
                highlight:Destroy() 
            end
        end
    end
end)

-- Lógica de Salto Infinito
UserInputService.JumpRequest:Connect(function()
    if Options.InfJump and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:ChangeState("Jumping")
    end
end)

-- Notificación de inicio
Window:SelectTab(1)
Fluent:Notify({
    Title = "Master Hub",
    Content = "Script cargado con éxito. Usa Settings para cambiar la tecla.",
    Duration = 5
})
