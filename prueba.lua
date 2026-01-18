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
    Title = "Auto Revive",
    Description = "TP a los heridos",
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
-- LÓGICA DE AUTO REVIVE 
-------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.1)
        if Options.AutoRevive then
            pcall(function()
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end

                local killerRoot = nil
                for _, v in pairs(Players:GetPlayers()) do
                    if v.Team and v.Team.Name == "Killer" and v.Character then
                        killerRoot = v.Character:FindFirstChild("HumanoidRootPart")
                    end
                end

                for _, v in pairs(Players:GetPlayers()) do
                    if v ~= player and v.Character then
                        -- Detección exacta de Rawscripts:
                        local targetChar = v.Character
                        local isDowned = targetChar:FindFirstChild("Downed") or (targetChar:FindFirstChild("Head") and targetChar.Head:FindFirstChild("HelpSymbol"))
                        
                        if isDowned then
                            local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
                            if tRoot then
                                local distToKiller = killerRoot and (tRoot.Position - killerRoot.Position).Magnitude or 100
                                if distToKiller > 5 then
                                    root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 1)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)
-- CARGA FINAL
SaveManager:LoadAutoloadConfig()
Window:SelectTab(1)
Fluent:Notify({Title = "STK Premium", Content = "Script listo!", Duration = 5})
