-- Asegurar que el juego cargó para evitar errores de ejecución
if not game:IsLoaded() then game.Loaded:Wait() end

-- Cargamos librerías con enlaces directos y estables para corregir el error de la imagen 53e49b
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
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
    WalkSpeed = 16,
    AutoRevive = false
}

-------------------------------------------------------------------
-- LÓGICA DE AUTO REVIVE (BASADA EN ATRIBUTO 'downed')
-------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.1) -- Escaneo rápido
        if Options.AutoRevive then
            pcall(function()
                local lp = game:GetService("Players").LocalPlayer
                local char = lp.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                
                if not root then return end

                for _, v in pairs(game:GetService("Players"):GetPlayers()) do
                    -- Comprobamos el atributo 'downed' en cada jugador según lo indicado en Discord
                    if v ~= lp and v.Character and v:GetAttribute("downed") == true then
                        local tRoot = v.Character:FindFirstChild("HumanoidRootPart")
                        
                        if tRoot then
                            -- TP Instantáneo sin importar distancia del Killer
                            repeat 
                                task.wait()
                                if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                                    -- Te posiciona exactamente sobre el jugador herido
                                    root.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1)
                                end
                            -- Espera hasta que el atributo pase a ser falso (revivido)
                            until v:GetAttribute("downed") == false or not Options.AutoRevive or not v.Character
                        end
                    end
                end
            end)
        end
    end
end)

-------------------------------------------------------------------
-- INTERFAZ Y FUNCIONES ADICIONALES
-------------------------------------------------------------------

-- Pestaña Movement
Tabs.Movement:AddSlider("SpeedSlider", {
    Title = "WalkSpeed", Default = 16, Min = 16, Max = 150, Rounding = 1,
    Callback = function(v) Options.WalkSpeed = v end
})

Tabs.Movement:AddToggle("ReviveT", {
    Title = "Auto Revive",
    Description = "TP inmediato si 'downed' es true",
    Default = false
}):OnChanged(function(v) 
    Options.AutoRevive = v 
end)

-- Pestaña Visuals
Tabs.Visuals:AddToggle("KillT", {Title = "ESP Killer", Default = false}):OnChanged(function(v) Options.KillerESP = v end)
Tabs.Visuals:AddToggle("SurvT", {Title = "ESP Survivor", Default = false}):OnChanged(function(v) Options.SurvivorESP = v end)

-------------------------------------------------------------------
-- BUCLE DE APOYO (WALKSPEED Y ESP)
-------------------------------------------------------------------
game:GetService("RunService").Stepped:Connect(function()
    pcall(function()
        local lp = game:GetService("Players").LocalPlayer
        if lp.Character and lp.Character:FindFirstChild("Humanoid") then
            lp.Character.Humanoid.WalkSpeed = Options.WalkSpeed
        end
        
        -- ESP con nombre de equipo "Killer" (K mayúscula)
        for _, p in pairs(game:GetService("Players"):GetPlayers()) do
            if p ~= lp and p.Character and p.Team then
                local highlight = p.Character:FindFirstChild("ESPHighlight")
                local isKiller = p.Team.Name == "Killer"
                local color = (Options.KillerESP and isKiller) and Color3.fromRGB(255, 0, 0) or (Options.SurvivorESP and not isKiller) and Color3.fromRGB(0, 255, 255) or nil
                
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

-- Configuración de Managers para Guardado
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("STK_Premium_Settings")
SaveManager:SetFolder("STK_Premium_Settings/Configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Carga final
SaveManager:LoadAutoloadConfig()
Window:SelectTab(1)
Fluent:Notify({Title = "STK Premium", Content = "Script listo. Atributo 'downed' en seguimiento.", Duration = 5})
