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

local Options = {
    KillerESP = false,
    SurvivorESP = false,
    WalkSpeed = 16,
    AutoRevive = false -- Variable para controlar el Auto Revive
}

-------------------------------------------------------------------
-- LÓGICA DE AUTO REVIVE (POR ATRIBUTO 'downed')
-------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.1) -- Escaneo constante
        if Options.AutoRevive then
            pcall(function()
                local lp = game.Players.LocalPlayer
                local char = lp.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                
                if not root then return end

                -- Buscamos al Killer para no teletransportarnos si está cerca (Seguridad)
                local killerRoot = nil
                for _, v in pairs(game.Players:GetPlayers()) do
                    if v.Team and v.Team.Name == "Killer" and v.Character then
                        killerRoot = v.Character:FindFirstChild("HumanoidRootPart")
                        break
                    end
                end

                for _, v in pairs(game.Players:GetPlayers()) do
                    if v ~= lp and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                        -- LEER EL ATRIBUTO: Checkeamos en el Player (donde confirmaste que está)
                        local isDowned = v:GetAttribute("downed") == true

                        if isDowned then
                            local targetRoot = v.Character.HumanoidRootPart
                            local distToKiller = killerRoot and (targetRoot.Position - killerRoot.Position).Magnitude or 100

                            -- Si el Killer está a más de 5 studs, procedemos
                            if distToKiller > 5 then
                                -- 1. Teletransporte al herido (detrás de él para no estorbar)
                                root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 1)
                                
                                -- 2. ESPERAR hasta que 'downed' sea falso (ya lo revivieron o murió)
                                -- También se cancela si apagas el Toggle
                                repeat 
                                    task.wait(0.2)
                                    -- Mantenemos la posición por si el herido se mueve (ej. lo cargan)
                                    root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 1)
                                until v:GetAttribute("downed") == false or not Options.AutoRevive or not v.Character
                                
                                print("Jugador " .. v.Name .. " ya no está downed. Buscando siguiente...")
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-------------------------------------------------------------------
-- INTERFAZ (MOVIMIENTO Y VISUALES)
-------------------------------------------------------------------

Tabs.Movement:AddSlider("SpeedSlider", {
    Title = "WalkSpeed", Default = 16, Min = 16, Max = 150, Rounding = 1,
    Callback = function(v) Options.WalkSpeed = v end
})

-- Toggle para activar/desactivar la lógica anterior
Tabs.Movement:AddToggle("ReviveT", {
    Title = "Auto Revive",
    Description = "TP automático usando atributo 'downed'",
    Default = false
}):OnChanged(function(v)
    Options.AutoRevive = v
end)

Tabs.Visuals:AddToggle("KillT", {Title = "ESP Killer"}):OnChanged(function(v) Options.KillerESP = v end)
Tabs.Visuals:AddToggle("SurvT", {Title = "ESP Survivor"}):OnChanged(function(v) Options.SurvivorESP = v end)

-------------------------------------------------------------------
-- BUCLE DE APOYO (SPEED Y ESP)
-------------------------------------------------------------------
game:GetService("RunService").Stepped:Connect(function()
    pcall(function()
        local lp = game.Players.LocalPlayer
        if lp.Character and lp.Character:FindFirstChild("Humanoid") then
            lp.Character.Humanoid.WalkSpeed = Options.WalkSpeed
        end
        -- ESP Lógica simplificada
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= lp and p.Character and p.Team then
                local highlight = p.Character:FindFirstChild("ESPHighlight")
                local isKiller = p.Team.Name == "Killer"
                local color = (Options.KillerESP and isKiller) and Color3.fromRGB(255,0,0) or (Options.SurvivorESP and not isKiller) and Color3.fromRGB(0,255,255) or nil
                
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

-- MANAGERS Y CIERRE
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("STK_Premium_Settings")
SaveManager:SetFolder("STK_Premium_Settings/Configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
Fluent:Notify({Title = "STK Premium", Content = "Detección por atributos 'downed' activa.", Duration = 5})
