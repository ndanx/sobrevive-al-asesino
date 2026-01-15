local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- 1. CONFIGURACIÓN DE LA VENTANA
local Window = Fluent:CreateWindow({
    Title = "MASTER HUB",
    SubTitle = "Premium Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl -- Tecla para ocultar el menú
})

-- 2. PESTAÑAS
local Tabs = {
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "run" })
}

-- 3. VARIABLES DE ESTADO (Para que los bucles sepan qué hacer)
local Options = {
    KillerESP = false,
    SurvivorESP = false,
    Noclip = false,
    InfJump = false,
    WalkSpeed = 16
}

-------------------------------------------------------------------
-- PESTAÑA VISUALS (ESP)
-------------------------------------------------------------------

Tabs.Visuals:AddToggle("KillerToggle", {Title = "ESP Killer", Default = false}):OnChanged(function(Value)
    Options.KillerESP = Value
end)

Tabs.Visuals:AddToggle("SurvivorToggle", {Title = "ESP Survivor", Default = false}):OnChanged(function(Value)
    Options.SurvivorESP = Value
end)

-------------------------------------------------------------------
-- PESTAÑA MOVEMENT (SPEED, JUMP, NOCLIP)
-------------------------------------------------------------------

-- El Slider que pediste (exacto al de tu foto)
Tabs.Movement:AddSlider("SpeedSlider", {
    Title = "WalkSpeed Changer",
    Description = "Ajusta tu velocidad de movimiento",
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

Tabs.Movement:AddToggle("NoclipToggle", {Title = "Noclip Wall", Default = false}):OnChanged(function(Value)
    Options.Noclip = Value
end)

-------------------------------------------------------------------
-- BUCLE PRINCIPAL (LÓGICA)
-------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Bucle para Speed, Noclip y ESP
RunService.Stepped:Connect(function()
    -- Speed
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
                    highlight = Instance.new("Highlight")
                    highlight.Name = "ESPHighlight"
                    highlight.Parent = char
                end
                highlight.FillColor = color
                highlight.OutlineColor = Color3.new(1, 1, 1)
            elseif highlight then
                highlight:Destroy()
            end
        end
    end
end)

-- Salto Infinito
UserInputService.JumpRequest:Connect(function()
    if Options.InfJump and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:ChangeState("Jumping")
    end
end)

-- Notificación al cargar
Fluent:Notify({
    Title = "Master Hub",
    Content = "Script cargado con éxito. Presiona RightControl para cerrar.",
    Duration = 5
})

Window:SelectTab(1)
