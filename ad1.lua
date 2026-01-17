local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/Beta.lua"))()

-- 1. CONFIGURACIÓN DE LA VENTANA
local Window = Fluent:CreateWindow({
    Title = "SURVIVE THE KILLER",
    SubTitle = "Premium Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    -- Ponemos una tecla que no exista para que la librería no use sus funciones internas que fallan
    MinimizeKey = Enum.KeyCode.F24 
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
    MenuKey = Enum.KeyCode.G -- Tecla que tú elijas
}

-------------------------------------------------------------------
-- LÓGICA DE LA TECLA (EL FIX DEFINITIVO)
-------------------------------------------------------------------
local UIS = game:GetService("UserInputService")

UIS.InputBegan:Connect(function(input, gameProcessed)
    -- Si no estás escribiendo en el chat y presionas TU tecla elegida
    if not gameProcessed and input.KeyCode == Options.MenuKey then
        local MainFrame = Window.Root:FindFirstChild("Main")
        if MainFrame then
            -- Solo cambiamos la visibilidad. NO usamos Maximize ni Minimize.
            -- Esto mantiene el tamaño 580x460 y la posición intactos.
            MainFrame.Visible = not MainFrame.Visible
        end
    end
end)

-------------------------------------------------------------------
-- PESTAÑA SETTINGS
-------------------------------------------------------------------

Tabs.Settings:AddDropdown("ThemeDropdown", {
    Title = "Theme",
    Values = {"Dark", "Darker", "AMOLED", "Light", "Amethyst", "Aqua", "Rose"},
    Default = "Dark",
    Callback = function(Value) Fluent:SetTheme(Value) end
})

-- Este es el selector de teclas que querías
Tabs.Settings:AddKeybind("WindowActionKey", {
    Title = "Keybind de Menú",
    Description = "Cambia la tecla para abrir/cerrar el Hub",
    Default = "G", 
    ChangedCallback = function(NewKey)
        Options.MenuKey = NewKey -- Actualiza la tecla que detectamos arriba
    end
})

-------------------------------------------------------------------
-- FUNCIONES DE JUEGO (VISUALS & MOVEMENT)
-------------------------------------------------------------------

-- VISUALS
Tabs.Visuals:AddToggle("KillT", {Title = "ESP Killer"}):OnChanged(function(v) Options.KillerESP = v end)
Tabs.Visuals:AddToggle("SurvT", {Title = "ESP Survivor"}):OnChanged(function(v) Options.SurvivorESP = v end)

-- MOVEMENT
Tabs.Movement:AddSlider("SpeedSlider", {
    Title = "WalkSpeed Changer",
    Default = 16, Min = 16, Max = 150, Rounding = 1,
    Callback = function(v) Options.WalkSpeed = v end
})
Tabs.Movement:AddToggle("JumpT", {Title = "Infinite Jump"}):OnChanged(function(v) Options.InfJump = v end)
Tabs.Movement:AddToggle("NocT", {Title = "Noclip"}):OnChanged(function(v) Options.Noclip = v end)

-- Lógica de bucle para WalkSpeed y ESP
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

RunService.Stepped:Connect(function()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = Options.WalkSpeed
    end
    -- [Aquí sigue tu lógica de ESP que ya tenías]
end)

Window:SelectTab(1)
Fluent:Notify({Title = "Sistema Listo", Content = "Usa 'G' para abrir/cerrar sin errores.", Duration = 5})
