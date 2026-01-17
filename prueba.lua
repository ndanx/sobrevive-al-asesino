local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/Beta.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/Fluent/master/Addons/InterfaceManager.lua"))()

-- 1. CONFIGURACIÓN DE LA VENTANA (Apertura prioritaria)
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
    AutoRevive = false
}

-------------------------------------------------------------------
-- CONFIGURACIÓN DE INTERFAZ (Pestañas y Opciones)
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
    Title = "Auto Revive (Smart)", 
    Description = "TP si detecta señal de ayuda y Killer a +5 studs",
    Default = false 
}):OnChanged(function(v) Options.AutoRevive = v end)

Tabs.Movement:AddToggle("JumpT", {Title = "Infinite Jump"}):OnChanged(function(v) Options.InfJump = v end)
Tabs.Movement:AddToggle("NocT", {Title = "Noclip"}):OnChanged(function(v) Options.Noclip = v end)

-- SETTINGS (Temas)
local ThemeDropdown = Tabs.Settings:AddDropdown("ThemeDropdown", {
    Title = "Theme",
    Values = {"Dark", "Darker", "AMOLED", "Light", "Aqua", "Amethyst", "Midnight", "Bloody"},
    Default = "Dark",
    Callback = function(Value) Fluent:SetTheme(Value) end
})

-------------------------------------------------------------------
-- LÓGICA DE BUCLE (Speed, ESP, Noclip)
-------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

RunService.Stepped:Connect(function()
    pcall(function()
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
                if Options.KillerESP and p.Team.Name == "Killer" then 
                    color = Color3.fromRGB(255,0,0)
                elseif Options.SurvivorESP and p.Team.Name == "Survivor" then 
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
            end
        end
    end)
end)

-------------------------------------------------------------------
-- LÓGICA DE AUTO REVIVE (POR SEÑAL VISUAL "HELP")
-------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.2) -- Un poco más lento para no saturar el juego
        if Options.AutoRevive then
            pcall(function()
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                
                if root then
                    -- Buscar al Killer
                    local killerRoot = nil
                    for _, p in pairs(Players:GetPlayers()) do
                        if p.Team and p.Team.Name == "Killer" and p.Character then
                            killerRoot = p.Character:FindFirstChild("HumanoidRootPart")
                            break
                        end
                    end

                    -- Buscar gente para revivir
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= player and p.Character then
                            local targetChar = p.Character
                            local head = targetChar:FindFirstChild("Head")
                            -- Detecta la barra de "HELP ME" o el icono de ayuda
                            if head and (head:FindFirstChildOfClass("BillboardGui") or head:FindFirstChild("Help")) then
                                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                                if targetRoot then
                                    -- Regla de 5 studs respecto al Killer
                                    local distToKiller = killerRoot and (targetRoot.Position - killerRoot.Position).Magnitude or 100
                                    
                                    if distToKiller >= 5 then
                                        root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 1)
                                        task.wait(0.5)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Salto Infinito
game:GetService("UserInputService").JumpRequest:Connect(function()
    if Options.InfJump and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:ChangeState("Jumping")
    end
end)

-------------------------------------------------------------------
-- INICIALIZACIÓN FINAL
-------------------------------------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("FluentSettings")
SaveManager:SetFolder("FluentSettings/STK-Premium")
SaveManager:IgnoreThemeSettings()

-- Construir secciones de configuración al final
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
Fluent:Notify({Title = "Survive The Killer", Content = "Script cargado correctamente.", Duration = 3})
