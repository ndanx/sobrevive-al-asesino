local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/Beta.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/Fluent/master/Addons/InterfaceManager.lua"))()

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
    AutoRevive = false -- Agregado para el control del nuevo Toggle
}

-------------------------------------------------------------------
-- CONFIGURACIÓN DE MANAGERS (RECOMENDADO POR EL DEV)
-------------------------------------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("FluentSettings")
SaveManager:SetFolder("FluentSettings/STK-Premium")

-- Construimos las secciones de guardado y de interfaz en Settings
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
Tabs.Movement:AddToggle("JumpT", {Title = "Infinite Jump"}):OnChanged(function(v) Options.InfJump = v end)
Tabs.Movement:AddToggle("NocT", {Title = "Noclip"}):OnChanged(function(v) Options.Noclip = v end)

-- AUTO REVIVE TOGGLE (Agregado aquí)
Tabs.Movement:AddToggle("ReviveT", {
    Title = "Auto Revive",
    Description = "TP a jugadores caídos (Lógica Rawscripts)",
    Default = false
}):OnChanged(function(v) Options.AutoRevive = v end)

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

-- LÓGICA DE AUTO REVIVE (Extraída de Rawscripts)
task.spawn(function()
    while task.wait() do
        if Options.AutoRevive then
            pcall(function()
                local killer = nil
                for _, v in pairs(Players:GetPlayers()) do
                    if v.Team and v.Team.Name == "Killer" and v.Character then
                        killer = v.Character:FindFirstChild("HumanoidRootPart")
                    end
                end

                for _, v in pairs(Players:GetPlayers()) do
                    if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                        -- Detección exacta: Valor 'Downed' o 'HelpSymbol' en la cabeza
                        if v.Character:FindFirstChild("Downed") or (v.Character:FindFirstChild("Head") and v.Character.Head:FindFirstChild("HelpSymbol")) then
                            local targetPos = v.Character.HumanoidRootPart.Position
                            local distToKiller = killer and (targetPos - killer.Position).Magnitude or 100
                            
                            -- Mantiene la seguridad de los 5 studs
                            if distToKiller > 5 then
                                player.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1)
                            end
                        end
                    end
                end
            end)
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
Fluent:Notify({Title = "Survive The Killer", Content = "Save Manager e Interface Manager activos.", Duration = 5})
