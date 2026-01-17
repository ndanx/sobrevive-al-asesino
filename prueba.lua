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

local Tabs = {
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "user" }), 
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }) 
}

local Options = { WalkSpeed = 16, AutoRevive = false, KillerESP = false, SurvivorESP = false, InfJump = false, Noclip = false }

-------------------------------------------------------------------
-- FUNCIÓN DE TELETRANSPORTE (REACCIÓN A EVENTO)
-------------------------------------------------------------------
local function instantRevive(targetChar)
    if not Options.AutoRevive then return end
    
    local lp = game.Players.LocalPlayer
    local lpRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if lpRoot and targetRoot then
        -- Buscar al Killer para la distancia de seguridad (10 studs)
        local killerPart = nil
        for _, p in pairs(game.Players:GetPlayers()) do
            -- Uso estricto de "Killer" con mayúscula
            if p.Team and p.Team.Name == "Killer" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                killerPart = p.Character.HumanoidRootPart
                break
            end
        end

        -- Validación de distancia
        local isSafe = true
        if killerPart then
            if (targetRoot.Position - killerPart.Position).Magnitude < 10 then
                isSafe = false
            end
        end

        if isSafe then
            lpRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2)
            Fluent:Notify({Title = "Auto Revive", Content = "Rescate instantáneo activado", Duration = 2})
            task.wait(2.5) -- Tiempo para completar la reanimación
        end
    end
end

-------------------------------------------------------------------
-- MONITOREO DE SALUD (SIN BUCLES, POR EVENTOS)
-------------------------------------------------------------------
local function monitorPlayer(p)
    local function connectHum(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            -- Se activa apenas cambia la propiedad Health
            hum:GetPropertyChangedSignal("Health"):Connect(function()
                if hum.Health <= 1 and hum.Health > 0 then
                    instantRevive(char)
                end
            end)
        end
    end

    p.CharacterAdded:Connect(connectHum)
    if p.Character then connectHum(p.Character) end
end

-- Conectar a todos los jugadores actuales y nuevos
game.Players.PlayerAdded:Connect(monitorPlayer)
for _, p in pairs(game.Players:GetPlayers()) do
    if p ~= game.Players.LocalPlayer then monitorPlayer(p) end
end

-------------------------------------------------------------------
-- PESTAÑAS Y CONTROLES
-------------------------------------------------------------------
Tabs.Movement:AddSlider("SpeedSlider", { Title = "WalkSpeed", Default = 16, Min = 16, Max = 150, Rounding = 1, Callback = function(v) Options.WalkSpeed = v end })

Tabs.Movement:AddToggle("ReviveT", { 
    Title = "Auto Revive (Instant Event)", 
    Description = "TP automático apenas la salud cambia a 1", 
    Default = false 
}):OnChanged(function(v) Options.AutoRevive = v end)

Tabs.Movement:AddToggle("JumpT", {Title = "Infinite Jump"}):OnChanged(function(v) Options.InfJump = v end)
Tabs.Movement:AddToggle("NocT", {Title = "Noclip"}):OnChanged(function(v) Options.Noclip = v end)

Tabs.Visuals:AddToggle("KillT", {Title = "ESP Killer"}):OnChanged(function(v) Options.KillerESP = v end)
Tabs.Visuals:AddToggle("SurvT", {Title = "ESP Survivor"}):OnChanged(function(v) Options.SurvivorESP = v end)

-------------------------------------------------------------------
-- BUCLE DE SOPORTE (SPEED, NOCLIP, ESP)
-------------------------------------------------------------------
game:GetService("RunService").Stepped:Connect(function()
    pcall(function()
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = Options.WalkSpeed
            
            if Options.Noclip then
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end

        -- ESP Logic
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

-- Infinite Jump
game:GetService("UserInputService").JumpRequest:Connect(function()
    if Options.InfJump and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid:ChangeState("Jumping")
    end
end)

-------------------------------------------------------------------
-- CONFIGURACIÓN DE MANAGERS
-------------------------------------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
Window:SelectTab(1)
