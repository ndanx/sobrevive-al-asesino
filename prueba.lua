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
    MinimizeKey = Enum.KeyCode.RightControl -- El InterfaceManager manejará esto después
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
-- CONFIGURACIÓN DE MANAGERS (RECOMENDADO POR EL DEV)
-------------------------------------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("FluentSettings")
SaveManager:SetFolder("FluentSettings/STK-Premium")

-- Construye las secciones automáticas en Settings
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-------------------------------------------------------------------
-- PESTAÑA VISUALS
-------------------------------------------------------------------
Tabs.Visuals:AddToggle("KillT", {Title = "ESP Killer", Default = false}):OnChanged(function(v) Options.KillerESP = v end)
Tabs.Visuals:AddToggle("SurvT", {Title = "ESP Survivor", Default = false}):OnChanged(function(v) Options.SurvivorESP = v end)

-------------------------------------------------------------------
-- PESTAÑA MOVEMENT & AUTO REVIVE
-------------------------------------------------------------------
Tabs.Movement:AddSlider("SpeedSlider", {
    Title = "WalkSpeed",
    Default = 16, Min = 16, Max = 150, Rounding = 1,
    Callback = function(v) Options.WalkSpeed = v end
})

Tabs.Movement:AddToggle("ReviveT", {
    Title = "Auto Revive (Teleport)",
    Description = "TP a caídos solo si el Killer está a +10 studs",
    Default = false
}):OnChanged(function(v) 
    Options.AutoRevive = v 
end)

Tabs.Movement:AddToggle("JumpT", {Title = "Infinite Jump"}):OnChanged(function(v) Options.InfJump = v end)
Tabs.Movement:AddToggle("NocT", {Title = "Noclip"}):OnChanged(function(v) Options.Noclip = v end)

-------------------------------------------------------------------
-- PESTAÑA SETTINGS (TEMAS)
-------------------------------------------------------------------
local ThemeDropdown = Tabs.Settings:AddDropdown("ThemeDropdown", {
    Title = "Theme",
    Description = "Cambia el aspecto visual.",
    Values = {"Dark", "Darker", "AMOLED", "Light", "Balloon", "SoftCream", "Aqua", "Amethyst", "Rose", "Midnight", "Forest", "Sunset", "Ocean", "Emerald", "Sapphire", "Cloud", "Grape", "Bloody", "Arctic" },
    Default = "Dark",
    Callback = function(Value)
        Fluent:SetTheme(Value)
    end
})

-------------------------------------------------------------------
-- LÓGICA DE BUCLE (SPEED, ESP, NOCLIP)
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

-- Infinite Jump
game:GetService("UserInputService").JumpRequest:Connect(function()
    if Options.InfJump and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:ChangeState("Jumping")
    end
end)

-------------------------------------------------------------------
-- LÓGICA DE AUTO REVIVE SEGURO (A 10 STUDS)
-------------------------------------------------------------------
task.spawn(function()
    while task.wait(0.5) do
        if Options.AutoRevive and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            -- Localizar al Killer
            local killerPart = nil
            for _, p in pairs(Players:GetPlayers()) do
                if p.Team and p.Team.Name == "Killer" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    killerPart = p.Character.HumanoidRootPart
                    break
                end
            end

            -- Buscar heridos
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") then
                    local targetChar = p.Character
                    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                    
                    -- Detección de estado caído
                    local isDowned = targetChar.Humanoid.Health <= 1 or targetChar:FindFirstChild("Downed")
                    
                    if isDowned and targetRoot then
                        -- Validar distancia del Killer (10 studs)
                        local killerIsSafe = true
                        if killerPart then
                            local dist = (targetRoot.Position - killerPart.Position).Magnitude
                            if dist < 10 then killerIsSafe = false end
                        end

                        if killerIsSafe then
                            player.Character.HumanoidRootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2)
                            Fluent:Notify({Title = "Auto Revive", Content = "Ayudando a " .. p.Name, Duration = 1.5})
                            task.wait(2.5)
                            break 
                        end
                    end
                end
            end
        end
    end
end)

-- CARGA FINAL
SaveManager:LoadAutoloadConfig()
Window:SelectTab(1)
Fluent:Notify({Title = "STK Premium", Content = "Script cargado con éxito.", Duration = 5})
