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
    Main = Window:AddTab({ Title = "Movement", Icon = "user" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- 3. VARIABLES DE CONTROL
local Options = {
    WalkSpeed = 16,
    AutoRevive = false,
    KillerESP = false,
    SurvivorESP = false,
    InfJump = false,
    Noclip = false
}

-------------------------------------------------------------------
-- LÓGICA DE AUTO REVIVE (REACCIÓN AL SCRIPT DE HEALTH)
-------------------------------------------------------------------
local function instantRevive(targetChar)
    if not Options.AutoRevive then return end
    
    local lp = game.Players.LocalPlayer
    local hum = targetChar:FindFirstChild("Humanoid")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    local lpRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")

    if hum and targetRoot and lpRoot then
        -- Verificamos si la vida es <= 1 (Caído)
        if hum.Health <= 1 and hum.Health > 0 then
            
            -- Buscamos al Killer (Mayúscula en K)
            local killerRoot = nil
            for _, p in pairs(game.Players:GetPlayers()) do
                if p.Team and p.Team.Name == "Killer" and p.Character then
                    killerRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    break
                end
            end

            -- REGLA DE 10 STUDS: Solo TP si el Killer está lejos del caído
            local safeDistance = true
            if killerRoot then
                if (targetRoot.Position - killerRoot.Position).Magnitude < 10 then
                    safeDistance = false
                end
            end

            if safeDistance then
                lpRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2)
                Fluent:Notify({
                    Title = "Auto Revive",
                    Content = "Rescatando a " .. targetChar.Name,
                    Duration = 2
                })
                task.wait(2.5) -- Pausa para que el juego registre la ayuda
            end
        end
    end
end

-------------------------------------------------------------------
-- DETECTOR DE EVENTOS DE SALUD
-------------------------------------------------------------------
local function monitorHealth(p)
    p.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 10)
        if hum then
            hum:GetPropertyChangedSignal("Health"):Connect(function()
                instantRevive(char)
            end)
        end
    end)
    
    if p.Character and p.Character:FindFirstChild("Humanoid") then
        p.Character.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            instantRevive(p.Character)
        end)
    end
end

for _, p in pairs(game.Players:GetPlayers()) do
    if p ~= game.Players.LocalPlayer then monitorHealth(p) end
end
game.Players.PlayerAdded:Connect(monitorHealth)

-------------------------------------------------------------------
-- INTERFAZ Y CONTROLES
-------------------------------------------------------------------
Tabs.Main:AddSlider("SpeedSlider", { Title = "WalkSpeed", Default = 16, Min = 16, Max = 150, Rounding = 1, Callback = function(v) Options.WalkSpeed = v end })

Tabs.Main:AddToggle("ReviveToggle", { 
    Title = "Auto Revive (Health Event)", 
    Description = "TP si el Killer está a +10 studs del caído",
    Default = false 
}):OnChanged(function(v) Options.AutoRevive = v end)

Tabs.Main:AddToggle("JumpT", { Title = "Infinite Jump" }):OnChanged(function(v) Options.InfJump = v end)
Tabs.Main:AddToggle("NocT", { Title = "Noclip" }):OnChanged(function(v) Options.Noclip = v end)

Tabs.Visuals:AddToggle("KillESP", { Title = "ESP Killer" }):OnChanged(function(v) Options.KillerESP = v end)
Tabs.Visuals:AddToggle("SurvESP", { Title = "ESP Survivor" }):OnChanged(function(v) Options.SurvivorESP = v end)

-------------------------------------------------------------------
-- SOPORTE (SPEED, ESP, NOCLIP)
-------------------------------------------------------------------
game:GetService("RunService").Stepped:Connect(function()
    pcall(function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = Options.WalkSpeed
            if Options.Noclip then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end
        -- ESP Lógica
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= game.Players.LocalPlayer and p.Character and p.Team then
                local highlight = p.Character:FindFirstChild("ESPHighlight")
                local isKiller = p.Team.Name == "Killer"
                local color = (Options.KillerESP and isKiller) and Color3.fromRGB(255,0,0) or (Options.SurvivorESP and not isKiller) and Color3.fromRGB(0,255,255) or nil
                if color then
                    if not highlight then highlight = Instance.new("Highlight", p.Character); highlight.Name = "ESPHighlight" end
                    highlight.FillColor = color
                elseif highlight then highlight:Destroy() end
            end
        end
    end)
end)

-- Salto Infinito
game:GetService("UserInputService").JumpRequest:Connect(function()
    if Options.InfJump and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid:ChangeState("Jumping")
    end
end)

-------------------------------------------------------------------
-- FINALIZACIÓN Y CARGA
-------------------------------------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("FluentSettings")
SaveManager:SetFolder("FluentSettings/STK-Premium")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

SaveManager:LoadAutoloadConfig()
Window:SelectTab(1)
