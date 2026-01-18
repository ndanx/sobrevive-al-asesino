-- Cargamos Fluent desde el link oficial más estable para evitar errores de 'nil'
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
InterfaceManager:SetFolder("STK_Premium_Settings")
SaveManager:SetFolder("STK_Premium_Settings/Configs")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-------------------------------------------------------------------
-- FUNCIONES DE INTERFAZ
-------------------------------------------------------------------

Tabs.Visuals:AddToggle("KillT", {Title = "ESP Killer", Default = false}):OnChanged(function(v) Options.KillerESP = v end)
Tabs.Visuals:AddToggle("SurvT", {Title = "ESP Survivor", Default = false}):OnChanged(function(v) Options.SurvivorESP = v end)

Tabs.Movement:AddSlider("SpeedSlider", {
    Title = "WalkSpeed", Default = 16, Min = 16, Max = 150, Rounding = 1,
    Callback = function(v) Options.WalkSpeed = v end
})

Tabs.Movement:AddToggle("ReviveT", {
    Title = "Auto Revive",
    Description = "Usa el atributo 'downed' del juego",
    Default = false
}):OnChanged(function(v) Options.AutoRevive = v end)

Tabs.Movement:AddToggle("JumpT", {Title = "Infinite Jump"}):OnChanged(function(v) Options.InfJump = v end)
Tabs.Movement:AddToggle("NocT", {Title = "Noclip"}):OnChanged(function(v) Options.Noclip = v end)

-------------------------------------------------------------------
-- LÓGICA DE AUTO REVIVE (POR ATRIBUTOS)
-------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.2) -- Un poco más lento para no laguear
        if Options.AutoRevive then
            pcall(function()
                local lp = game.Players.LocalPlayer
                local char = lp.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end

                -- Localizar Killer (K Mayúscula por preferencia guardada)
                local killerRoot = nil
                for _, v in pairs(game.Players:GetPlayers()) do
                    if v.Team and v.Team.Name == "Killer" and v.Character then
                        killerRoot = v.Character:FindFirstChild("HumanoidRootPart")
                        break
                    end
                end

                for _, v in pairs(game.Players:GetPlayers()) do
                    if v ~= lp and v.Character then
                        -- DETECCIÓN POR ATRIBUTO 'downed'
                        local isDowned = v.Character:GetAttribute("downed") == true 

                        if isDowned then
                            local tRoot = v.Character:FindFirstChild("HumanoidRootPart")
                            if tRoot then
                                -- Seguridad de 5 studs
                                local distToKiller = killerRoot and (tRoot.Position - killerRoot.Position).Magnitude or 100
                                if distToKiller > 5 then
                                    root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 1)
                                    -- Esperamos a que el atributo sea false (revivido)
                                    repeat task.wait(0.5) until v.Character:GetAttribute("downed") == false or not Options.AutoRevive
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
-- BUCLE GENERAL (SPEED, ESP, NOCLIP)
-------------------------------------------------------------------
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
        -- ESP
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

-- Infinite Jump
game:GetService("UserInputService").JumpRequest:Connect(function()
    if Options.InfJump and game.Players.LocalPlayer.Character then
        local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState("Jumping") end
    end
end)

SaveManager:LoadAutoloadConfig()
Window:SelectTab(1)
Fluent:Notify({Title = "STK Premium", Content = "Detección por atributos 'downed' lista.", Duration = 5})
