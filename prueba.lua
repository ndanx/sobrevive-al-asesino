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
    AutoRevive = false
}

-------------------------------------------------------------------
-- CONFIGURACIÓN DE MANAGERS (Igual a tu versión original)
-------------------------------------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("FluentSettings")
SaveManager:SetFolder("FluentSettings/STK-Premium")

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
    Title = "Auto Revive (Instant)",
    Description = "TP apenas la salud cambie",
    Default = false
}):OnChanged(function(v) 
    Options.AutoRevive = v 
end)

Tabs.Movement:AddToggle("JumpT", {Title = "Infinite Jump"}):OnChanged(function(v) Options.InfJump = v end)
Tabs.Movement:AddToggle("NocT", {Title = "Noclip"}):OnChanged(function(v) Options.Noclip = v end)

-------------------------------------------------------------------
-- LÓGICA DE EVENTO DE SALUD (AÑADIDO SIN CAMBIAR ESTRUCTURA)
-------------------------------------------------------------------
local function monitorHealth(p)
    p.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 10)
        if hum then
            hum:GetPropertyChangedSignal("Health"):Connect(function()
                if Options.AutoRevive and hum.Health <= 1 and hum.Health > 0 then
                    local lp = game.Players.LocalPlayer
                    local targetRoot = char:FindFirstChild("HumanoidRootPart")
                    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and targetRoot then
                        -- Validación de seguridad Killer (K Mayúscula)
                        local killerRoot = nil
                        for _, op in pairs(game.Players:GetPlayers()) do
                            if op.Team and op.Team.Name == "Killer" and op.Character then
                                killerRoot = op.Character:FindFirstChild("HumanoidRootPart")
                                break
                            end
                        end
                        
                        if not killerRoot or (targetRoot.Position - killerRoot.Position).Magnitude >= 10 then
                            lp.Character.HumanoidRootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2)
                        end
                    end
                end
            end)
        end
    end)
end

-- Ejecutar monitoreo
for _, p in pairs(game.Players:GetPlayers()) do
    if p ~= game.Players.LocalPlayer then monitorHealth(p) end
end
game.Players.PlayerAdded:Connect(monitorHealth)

-------------------------------------------------------------------
-- LÓGICA DE BUCLE (SPEED, ESP, NOCLIP)
-------------------------------------------------------------------
game:GetService("RunService").Stepped:Connect(function()
    pcall(function()
        local lp = game.Players.LocalPlayer
        if lp.Character and lp.Character:FindFirstChild("Humanoid") then
            lp.Character.Humanoid.WalkSpeed = Options.WalkSpeed
            if Options.Noclip then
                for _, v in pairs(lp.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end
        
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= lp and p.Character and p.Team then
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

game:GetService("UserInputService").JumpRequest:Connect(function()
    if Options.InfJump and game.Players.LocalPlayer.Character then
        local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState("Jumping") end
    end
end)

SaveManager:LoadAutoloadConfig()
Window:SelectTab(1)
