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
    AutoRevive = false -- Variable para el toggle
}

-------------------------------------------------------------------
-- LÓGICA DE AUTO REVIVE (Detección por BillboardGui/Help)
-------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.2)
        if Options.AutoRevive then
            pcall(function()
                local lp = game.Players.LocalPlayer
                local char = lp.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                
                if root then
                    -- Buscamos al Killer (K Mayúscula)
                    local killerRoot = nil
                    for _, p in pairs(game.Players:GetPlayers()) do
                        if p.Team and p.Team.Name == "Killer" and p.Character then
                            killerRoot = p.Character:FindFirstChild("HumanoidRootPart")
                            break
                        end
                    end

                    -- Buscamos gente que necesite ayuda
                    for _, p in pairs(game.Players:GetPlayers()) do
                        if p ~= lp and p.Character then
                            local tChar = p.Character
                            local head = tChar:FindFirstChild("Head")
                            
                            -- Detecta la barra "HELP ME" o signo de ayuda que aparece al caer
                            local isDowned = head and (head:FindFirstChildOfClass("BillboardGui") or head:FindFirstChild("Help"))
                            
                            if isDowned then
                                local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                                if tRoot then
                                    -- Regla de distancia de 5 studs
                                    local distToKiller = killerRoot and (tRoot.Position - killerRoot.Position).Magnitude or 100
                                    
                                    if distToKiller >= 5 then
                                        root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 1)
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

-- Nuevo Toggle para Auto Revive
Tabs.Movement:AddToggle("ReviveT", {
    Title = "Auto Revive",
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
Fluent:Notify({Title = "Survive The Killer", Content = "Hub cargado con FluentPlus.", Duration = 5})
