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
    AutoRevive = false
}

-------------------------------------------------------------------
-- CONFIGURACIÓN DE MANAGERS
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
    Title = "WalkSpeed", Default = 16, Min = 16, Max = 150, Rounding = 1,
    Callback = function(v) Options.WalkSpeed = v end
})

Tabs.Movement:AddToggle("ReviveT", {
    Title = "Auto Revive (TP & Return)",
    Description = "Analiza a todos y regresa a tu lugar",
    Default = false
}):OnChanged(function(v) Options.AutoRevive = v end)

Tabs.Movement:AddToggle("JumpT", {Title = "Infinite Jump"}):OnChanged(function(v) Options.InfJump = v end)
Tabs.Movement:AddToggle("NocT", {Title = "Noclip"}):OnChanged(function(v) Options.Noclip = v end)

-------------------------------------------------------------------
-- LÓGICA DE BUCLE (SPEED, ESP, NOCLIP)
-------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

RunService.Stepped:Connect(function()
    pcall(function()
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = Options.WalkSpeed
            if Options.Noclip then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end
        
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Team then
                local highlight = p.Character:FindFirstChild("ESPHighlight")
                local color = nil
                -- "Killer" con K Mayúscula
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
end)

-------------------------------------------------------------------
-- LÓGICA DE AUTO REVIVE CON RETORNO (CORREGIDA)
-------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.1)
        if Options.AutoRevive and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local myRoot = player.Character.HumanoidRootPart
            
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    -- LEER ATRIBUTO EN EL PLAYER (p:GetAttribute)
                    if p:GetAttribute("downed") == true then
                        
                        -- 1. GUARDAR POSICIÓN ANTES DE IR
                        local posOriginal = myRoot.CFrame
                        
                        -- 2. BUCLE DE REANIMACIÓN (TP CONSTANTE)
                        repeat
                            task.wait()
                            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                                myRoot.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1)
                            end
                        until p:GetAttribute("downed") == false or not Options.AutoRevive or not p.Character
                        
                        -- 3. RETORNO AL PUNTO ORIGINAL
                        task.wait(0.1)
                        myRoot.CFrame = posOriginal
                        
                        Fluent:Notify({
                            Title = "Auto Revive", 
                            Content = "Terminado con " .. p.Name .. ". Regresando...", 
                            Duration = 2
                        })
                        
                        -- Esperamos un poco para no saltar inmediatamente a otro sin procesar el retorno
                        task.wait(0.5)
                    end
                end
            end
        end
    end
end)

-- Infinite Jump
game:GetService("UserInputService").JumpRequest:Connect(function()
    if Options.InfJump and player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:ChangeState("Jumping")
    end
end)

-- CARGA FINAL
SaveManager:LoadAutoloadConfig()
Window:SelectTab(1)
Fluent:Notify({Title = "STK Premium", Content = "Lógica de Atributos con Retorno Activa", Duration = 5})
