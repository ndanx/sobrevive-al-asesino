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
-- CONFIGURACIÓN DE MANAGERS (GUARDADO Y KEYBINDS)
-------------------------------------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("STK_Premium_Settings")
SaveManager:SetFolder("STK_Premium_Settings/Configs")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-------------------------------------------------------------------
-- PESTAÑA VISUALS (ESP)
-------------------------------------------------------------------
Tabs.Visuals:AddToggle("KillT", {Title = "ESP Killer", Default = false}):OnChanged(function(v) Options.KillerESP = v end)
Tabs.Visuals:AddToggle("SurvT", {Title = "ESP Survivor", Default = false}):OnChanged(function(v) Options.SurvivorESP = v end)

-------------------------------------------------------------------
-- PESTAÑA MOVEMENT & AUTO REVIVE PRO
-------------------------------------------------------------------
Tabs.Movement:AddSlider("SpeedSlider", {
    Title = "WalkSpeed",
    Default = 16, Min = 16, Max = 150, Rounding = 1,
    Callback = function(v) Options.WalkSpeed = v end
})

local ReviveToggle = Tabs.Movement:AddToggle("ReviveT", {
    Title = "Auto Revive (Visual Check)",
    Description = "TP si ve el icono HELP ME! y el Killer está a +10 studs",
    Default = false
})

ReviveToggle:OnChanged(function()
    Options.AutoRevive = ReviveToggle.Value
end)

Tabs.Movement:AddToggle("JumpT", {Title = "Infinite Jump"}):OnChanged(function(v) Options.InfJump = v end)
Tabs.Movement:AddToggle("NocT", {Title = "Noclip"}):OnChanged(function(v) Options.Noclip = v end)

-------------------------------------------------------------------
-- LÓGICA DE BUCLE PRINCIPAL (SPEED, ESP, NOCLIP)
-------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

RunService.Stepped:Connect(function()
    pcall(function() -- Evita errores de consola
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = Options.WalkSpeed
        end

        if Options.Noclip and player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
        
        -- ESP con nombre de equipo "Killer" exacto
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Team then
                local highlight = p.Character:FindFirstChild("ESPHighlight")
                local isKiller = p.Team.Name == "Killer"
                
                local color = nil
                if Options.KillerESP and isKiller then 
                    color = Color3.fromRGB(255, 0, 0)
                elseif Options.SurvivorESP and not isKiller then 
                    color = Color3.fromRGB(0, 255, 255) 
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

-- Infinite Jump
game:GetService("UserInputService").JumpRequest:Connect(function()
    if Options.InfJump and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:ChangeState("Jumping")
    end
end)

-------------------------------------------------------------------
-- LÓGICA DE AUTO REVIVE (BASADA EN ICONO HELP ME)
-------------------------------------------------------------------
task.spawn(function()
    while task.wait(0.2) do
        if Options.AutoRevive and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            -- Ubicamos al Killer para validar distancia
            local killerRoot = nil
            for _, p in pairs(Players:GetPlayers()) do
                if p.Team and p.Team.Name == "Killer" and p.Character then
                    killerRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    break
                end
            end

            -- Buscamos a alguien con el icono visual de caída
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local char = p.Character
                    -- El juego crea un icono visual arriba del personaje caído
                    local isDowned = char:FindFirstChild("HelpSymbol") or 
                                     char:FindFirstChild("Downed") or 
                                     char:FindFirstChildOfClass("BillboardGui") or
                                     (char:FindFirstChild("Humanoid") and char.Humanoid.Health <= 1)

                    if isDowned then
                        local targetRoot = char:FindFirstChild("HumanoidRootPart")
                        if targetRoot then
                            -- Seguridad de 10 studs respecto al Killer
                            local safe = true
                            if killerRoot then
                                if (targetRoot.Position - killerRoot.Position).Magnitude < 10 then
                                    safe = false
                                end
                            end

                            if safe then
                                player.Character.HumanoidRootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2)
                                Fluent:Notify({Title = "Auto Revive", Content = "Rescatando a " .. p.Name, Duration = 1.5})
                                task.wait(2.5) -- Tiempo de reanimación
                                break 
                            end
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
Fluent:Notify({Title = "STK Premium", Content = "Script listo con detección de icono HELP ME!", Duration = 5})
