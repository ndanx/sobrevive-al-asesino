-- Intentamos cargar FluentPlus con seguridad
local success, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/Beta.lua"))()
end)

if not success or not Fluent then
    -- Si falla el link anterior, usamos el estable oficial para que el Hub abra sí o sí
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end

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
    AutoRevive = false
}

-------------------------------------------------------------------
-- LÓGICA DE AUTO REVIVE (DESCODIFICADA)
-------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.1)
        if Options.AutoRevive then
            pcall(function()
                local lp = game.Players.LocalPlayer
                local lpRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                
                if lpRoot then
                    -- Buscar al Killer (K Mayúscula)
                    local killerRoot = nil
                    for _, v in pairs(game.Players:GetPlayers()) do
                        if v.Team and v.Team.Name == "Killer" and v.Character then
                            killerRoot = v.Character:FindFirstChild("HumanoidRootPart")
                            break
                        end
                    end

                    -- Buscar heridos con la lógica del script externo
                    for _, v in pairs(game.Players:GetPlayers()) do
                        if v ~= lp and v.Character then
                            local tChar = v.Character
                            -- Detección por objeto 'Downed' o 'HelpSymbol' en la cabeza
                            local isDowned = tChar:FindFirstChild("Downed") or (tChar:FindFirstChild("Head") and tChar.Head:FindFirstChild("HelpSymbol"))
                            
                            if isDowned then
                                local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                                if tRoot then
                                    -- Seguridad de 5 studs
                                    local distToKiller = killerRoot and (tRoot.Position - killerRoot.Position).Magnitude or 100
                                    
                                    if distToKiller >= 5 then
                                        lpRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 1.2)
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
-- INTERFAZ Y FUNCIONES
-------------------------------------------------------------------

Tabs.Visuals:AddToggle("KillT", {Title = "ESP Killer"}):OnChanged(function(v) Options.KillerESP = v end)
Tabs.Visuals:AddToggle("SurvT", {Title = "ESP Survivor"}):OnChanged(function(v) Options.SurvivorESP = v end)

Tabs.Movement:AddSlider("SpeedSlider", {
    Title = "WalkSpeed", Default = 16, Min = 16, Max = 150, Rounding = 1,
    Callback = function(v) Options.WalkSpeed = v end
})

Tabs.Movement:AddToggle("ReviveT", {
    Title = "Auto Revive",
    Description = "Lógica: Detecta 'Downed' y 'HelpSymbol' (5 studs seguridad)",
    Default = false
}):OnChanged(function(v) Options.AutoRevive = v end)

Tabs.Movement:AddToggle("JumpT", {Title = "Infinite Jump"}):OnChanged(function(v) Options.InfJump = v end)
Tabs.Movement:AddToggle("NocT", {Title = "Noclip"}):OnChanged(function(v) Options.Noclip = v end)

-- BUCLE DE APOYO
game:GetService("RunService").Stepped:Connect(function()
    pcall(function()
        local lp = game.Players.LocalPlayer
        if lp.Character and lp.Character:FindFirstChild("Humanoid") then
            lp.Character.Humanoid.WalkSpeed = Options.WalkSpeed
            if Options.Noclip then
                for _, part in pairs(lp.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end
        -- ESP Lógica
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

-- MANAGERS FINAL
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("FluentSettings")
SaveManager:SetFolder("FluentSettings/STK-Premium")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
Fluent:Notify({Title = "STK Premium", Content = "Hub cargado. Lógica de revive activa.", Duration = 5})
