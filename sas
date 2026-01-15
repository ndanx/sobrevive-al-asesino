local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- 1. CONFIGURACIÓN DE LA VENTANA (Quitamos la tecla de aquí para que no interfiera)
local Window = Fluent:CreateWindow({
    Title = "SOBREVIVE AL ASESINO",
    SubTitle = "Premium Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.Unknown -- Desactivamos la tecla interna de la librería
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
    MenuKey = Enum.KeyCode.RightControl -- ESTA es la tecla que manda
}

-------------------------------------------------------------------
-- SISTEMA DE APERTURA/CIERRE (FORZADO)
-------------------------------------------------------------------
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, processed)
    -- Si no estás escribiendo en el chat y presionas la tecla guardada...
    if not processed and input.KeyCode == Options.MenuKey then
        Window:Minimize()
    end
end)

-------------------------------------------------------------------
-- PESTAÑA SETTINGS
-------------------------------------------------------------------
Tabs.Settings:AddKeybind("MenuBind", {
    Title = "Cambiar Tecla del Menú",
    Mode = "Toggle",
    Default = "RightControl", -- Valor visual inicial
    Callback = function(Value)
        Options.MenuKey = Value -- Aquí es donde se cambia la tecla de verdad
    end,
    ChangedCallback = function(NewBind)
        Fluent:Notify({
            Title = "Ajustes",
            Content = "Nueva tecla asignada: " .. tostring(NewBind),
            Duration = 3
        })
    end
})

-------------------------------------------------------------------
-- PESTAÑAS DE FUNCIONES (MOVIMIENTO Y VISUALES)
-------------------------------------------------------------------

-- MOVEMENT
Tabs.Movement:AddSlider("SpeedSlider", {
    Title = "WalkSpeed Changer",
    Default = 16, Min = 16, Max = 150, Rounding = 1,
    Callback = function(v) Options.WalkSpeed = v end
})
Tabs.Movement:AddToggle("JumpT", {Title = "Infinite Jump"}):OnChanged(function(v) Options.InfJump = v end)
Tabs.Movement:AddToggle("NocT", {Title = "Noclip"}):OnChanged(function(v) Options.Noclip = v end)

-- VISUALS
Tabs.Visuals:AddToggle("KillT", {Title = "ESP Killer"}):OnChanged(function(v) Options.KillerESP = v end)
Tabs.Visuals:AddToggle("SurvT", {Title = "ESP Survivor"}):OnChanged(function(v) Options.SurvivorESP = v end)

-------------------------------------------------------------------
-- LÓGICA DE BUCLE (Speed, Noclip, ESP)
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

UIS.JumpRequest:Connect(function()
    if Options.InfJump and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:ChangeState("Jumping")
    end
end)

Window:SelectTab(1)
Fluent:Notify({Title = "Master Hub", Content = "Listo. Cambia la tecla en Settings y funcionará al instante.", Duration = 5})
