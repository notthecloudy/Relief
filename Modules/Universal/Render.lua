local Render = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

Render.Modules = {}

function Render.Init(Relief)
    Render.Relief = Relief
    Render.Thread = getgenv().Thread
    Render.Character = getgenv().Character
    Render.CreateModules()
end

local function getRoot()
    return Render.Character.GetRootPart()
end

local function getHumanoid()
    return Render.Character.GetHumanoid()
end

local function getCharacter()
    return Render.Character.GetCharacter()
end

function Render.CreateModules()
    local ESPEnabled = false
    local ESPConnection = nil
    local ESPBoxes = {}

    Render.Modules.ESP = Relief.addModule("Render", "ESP", function(enabled)
        if enabled then
            ESPEnabled = true
            ESPConnection = RunService.RenderStepped:Connect(function()
                for _, box in pairs(ESPBoxes) do
                    box:Remove()
                end
                ESPBoxes = {}

                for _, player in Players:GetPlayers() do
                    if player ~= LocalPlayer then
                        local char = player.Character
                        if char then
                            local hum = char:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 then
                                local root = char:FindFirstChild("HumanoidRootPart")
                                if root then
                                    local cf, size = char:GetBoundingBox()
                                    local top = cf.Position + Vector3.new(0, size.Y / 2, 0)
                                    local bottom = cf.Position - Vector3.new(0, size.Y / 2, 0)

                                    local top2D, onTop = Camera:WorldToViewportPoint(top)
                                    local bot2D, onBot = Camera:WorldToViewportPoint(bottom)
                                    if onTop and onBot then
                                        local height = math.abs(top2D.Y - bot2D.Y)
                                        local width = height * 0.6

                                        local box = Drawing.new("Square")
                                        box.Thickness = 1
                                        box.Color = Color3.new(1, 0, 0)
                                        box.Size = Vector2.new(width, height)
                                        box.Position = Vector2.new(top2D.X - (width / 2), top2D.Y)

                                        table.insert(ESPBoxes, box)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        else
            ESPEnabled = false
            if ESPConnection then ESPConnection:Disconnect() ESPConnection = nil end
            for _, box in pairs(ESPBoxes) do
                box:Remove()
            end
            ESPBoxes = {}
        end
    end)

    local ZoomEnabled = false
    local ZoomConnection = nil
    local OriginalFOV = Camera.FieldOfView
    local ZoomInfo = TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

    Render.Modules.Zoom = Relief.addModule("Render", "Zoom", function(enabled)
        if enabled then
            local amount = Relief.getSetting("Zoom", "Amount") or 30
            local smooth = Relief.getSetting("Zoom", "Smooth") or false

            if smooth then
                game:GetService("TweenService"):Create(Camera, ZoomInfo, {FieldOfView = amount}):Play()
            else
                Camera.FieldOfView = amount
            end

            local module = Relief.getModule("Zoom")
            local bind = module and module.Keybind
            if bind then
                ZoomConnection = game:GetService("UserInputService").InputEnded:Connect(function(input, gpe)
                    if input.KeyCode == bind then
                        if ZoomConnection then ZoomConnection:Disconnect() ZoomConnection = nil end
                        module.ToggleFunction()
                    end
                end)
            end
        else
            local smooth = Relief.getSetting("Zoom", "Smooth") or false
            if smooth then
                game:GetService("TweenService"):Create(Camera, ZoomInfo, {FieldOfView = OriginalFOV}):Play()
            else
                Camera.FieldOfView = OriginalFOV
            end
            if ZoomConnection then ZoomConnection:Disconnect() ZoomConnection = nil end
        end
    end, {
        {Type = "Toggle", Title = "Smooth", Callback = function() end},
        {Type = "Slider", Title = "Amount", Min = 1, Max = 120, Default = 30, Callback = function() end}
    })

    local R, G, B = 0, 0, 0

    local function lighten(color, amount)
        return color:Lerp(Color3.new(1, 1, 1), amount)
    end

    Render.Modules.Theme = Relief.addModule("Render", "Theme", function(enabled)
        if enabled then
            Relief.Recolor(Color3.fromRGB(R, G, B))
        else
            Relief.Recolor(Color3.fromRGB(75, 156, 255))
        end
    end, {
        {Type = "TextBox", Title = "R", Placeholder = "red", Callback = function(num)
            local new = tonumber(num) or 0
            R = new
            if Relief.isToggled("Theme") then Relief.Recolor(Color3.fromRGB(R, G, B)) end
        end},
        {Type = "TextBox", Title = "G", Placeholder = "green", Callback = function(num)
            local new = tonumber(num) or 0
            G = new
            if Relief.isToggled("Theme") then Relief.Recolor(Color3.fromRGB(R, G, B)) end
        end},
        {Type = "TextBox", Title = "B", Placeholder = "blue", Callback = function(num)
            local new = tonumber(num) or 0
            B = new
            if Relief.isToggled("Theme") then Relief.Recolor(Color3.fromRGB(R, G, B)) end
        end},
        {Type = "Toggle", Title = "Rainbow", Callback = function(toggled)
            if toggled then
                local x = 0
                local rainbowThread = Render.Thread.New("Rainbow", function()
                    if not Relief.isToggled("Theme") then return task.wait() end
                    local dt = RunService.RenderStepped:Wait()
                    x = x + (dt / 3)
                    if Relief.isToggled("Theme") then
                        local rainbow = Color3.fromHSV(x % 1, 1, 1)
                        local brighter = lighten(rainbow, 0.3)
                        Relief.Recolor(rainbow)
                    end
                    task.wait()
                end)
            else
                Render.Thread.Disconnect("Rainbow")
                if Relief.isToggled("Theme") then
                    Relief.Recolor(Color3.fromRGB(R, G, B))
                end
            end
        end},
    })

    Render.Modules.ModuleList = Relief.addModule("Render", "ModuleList", function(toggled)
        Relief.ModuleList.Visible = toggled
    end, {}, nil, true)

    Render.Modules.MobileButton = Relief.addModule("Render", "MobileButton", function(toggled)
        Relief.MobileButton.Visible = toggled
        Relief.Arrow.Visible = toggled
    end, {}, nil, true)

    local CrosshairEnabled = false
    local CrosshairLines = {}

    Render.Modules.Crosshair = Relief.addModule("Render", "Crosshair", function(enabled)
        if enabled then
            CrosshairEnabled = true
            local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local size = 10
            local gap = 3
            local thickness = 1
            local color = Color3.new(1, 1, 1)

            local line1 = Drawing.new("Line")
            line1.From = Vector2.new(center.X - size - gap, center.Y)
            line1.To = Vector2.new(center.X - gap, center.Y)
            line1.Thickness = thickness
            line1.Color = color
            line1.Visible = true

            local line2 = Drawing.new("Line")
            line2.From = Vector2.new(center.X + gap, center.Y)
            line2.To = Vector2.new(center.X + size + gap, center.Y)
            line2.Thickness = thickness
            line2.Color = color
            line2.Visible = true

            local line3 = Drawing.new("Line")
            line3.From = Vector2.new(center.X, center.Y - size - gap)
            line3.To = Vector2.new(center.X, center.Y - gap)
            line3.Thickness = thickness
            line3.Color = color
            line3.Visible = true

            local line4 = Drawing.new("Line")
            line4.From = Vector2.new(center.X, center.Y + gap)
            line4.To = Vector2.new(center.X, center.Y + size + gap)
            line4.Thickness = thickness
            line4.Color = color
            line4.Visible = true

            CrosshairLines = {line1, line2, line3, line4}

            RunService.RenderStepped:Connect(function()
                if not CrosshairEnabled then return end
                center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                for i, line in CrosshairLines do
                    if i == 1 then
                        line.From = Vector2.new(center.X - size - gap, center.Y)
                        line.To = Vector2.new(center.X - gap, center.Y)
                    elseif i == 2 then
                        line.From = Vector2.new(center.X + gap, center.Y)
                        line.To = Vector2.new(center.X + size + gap, center.Y)
                    elseif i == 3 then
                        line.From = Vector2.new(center.X, center.Y - size - gap)
                        line.To = Vector2.new(center.X, center.Y - gap)
                    elseif i == 4 then
                        line.From = Vector2.new(center.X, center.Y + gap)
                        line.To = Vector2.new(center.X, center.Y + size + gap)
                    end
                end
            end)
        else
            CrosshairEnabled = false
            for _, line in CrosshairLines do
                line:Remove()
            end
            CrosshairLines = {}
        end
    end, {
        {Type = "Slider", Title = "Size", Min = 1, Max = 50, Default = 10, Callback = function() end},
        {Type = "Slider", Title = "Gap", Min = 0, Max = 20, Default = 3, Callback = function() end},
        {Type = "Slider", Title = "Thickness", Min = 1, Max = 5, Default = 1, Callback = function() end},
    })

    local FullbrightEnabled = false
    local OriginalLighting = {}

    Render.Modules.Fullbright = Relief.addModule("Render", "Fullbright", function(enabled)
        local Lighting = game:GetService("Lighting")
        if enabled then
            FullbrightEnabled = true
            OriginalLighting.Brightness = Lighting.Brightness
            OriginalLighting.ClockTime = Lighting.ClockTime
            OriginalLighting.FogEnd = Lighting.FogEnd
            OriginalLighting.GlobalShadows = Lighting.GlobalShadows
            OriginalLighting.OutdoorAmbient = Lighting.OutdoorAmbient

            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        else
            FullbrightEnabled = false
            if OriginalLighting.Brightness then Lighting.Brightness = OriginalLighting.Brightness end
            if OriginalLighting.ClockTime then Lighting.ClockTime = OriginalLighting.ClockTime end
            if OriginalLighting.FogEnd then Lighting.FogEnd = OriginalLighting.FogEnd end
            if OriginalLighting.GlobalShadows ~= nil then Lighting.GlobalShadows = OriginalLighting.GlobalShadows end
            if OriginalLighting.OutdoorAmbient then Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient end
        end
    end)

    local NoFogEnabled = false

    Render.Modules.NoFog = Relief.addModule("Render", "NoFog", function(enabled)
        local Lighting = game:GetService("Lighting")
        if enabled then
            NoFogEnabled = true
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0
        else
            NoFogEnabled = false
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0
        end
    end)
end

function Render.Cleanup()
    for name, module in pairs(Render.Modules) do
        if module and module.Toggled then
            pcall(module.Callback, false)
        end
    end
    Render.Modules = {}
end

getgenv().Render = Render

return Render