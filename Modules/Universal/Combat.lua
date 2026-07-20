local Combat = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Thread = getgenv().Thread
local Character = getgenv().Character or require(script.Parent.Parent.Core.Character)

Combat.Modules = {}

function Combat.Init(Relief)
    Combat.Relief = Relief
    Combat.CreateModules()
end

local function getRoot()
    return Character.GetRootPart()
end

local function getHumanoid()
    return Character.GetHumanoid()
end

local function getCharacter()
    return Character.GetCharacter()
end

local AimbotSettings = {
    TargetPart = "Head",
    FOV = 200,
    Strength = 0.25,
    WallCheck = true,
    DrawFOV = true,
}

local AimbotEnabled = false
local AimbotConnection = nil
local FOVCircle = nil

local function GetClosestPlayer()
    local targetDistance = AimbotSettings.FOV
    local target = nil
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in Players:GetPlayers() do
        if player ~= LocalPlayer then
            local tChar = player.Character
            if tChar then
                local tHum = tChar:FindFirstChildOfClass("Humanoid")
                if tHum and tHum.Health > 0 then
                    local targetPart
                    if AimbotSettings.TargetPart == "Closest" then
                        local closest = math.huge
                        for _, bp in tChar:GetChildren() do
                            if bp:IsA("BasePart") then
                                local screenPos, onScreen = Camera:WorldToViewportPoint(bp.Position)
                                if onScreen then
                                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                                    if distance < closest then
                                        closest = distance
                                        targetPart = bp
                                    end
                                end
                            end
                        end
                    else
                        targetPart = tChar:FindFirstChild(AimbotSettings.TargetPart)
                    end

                    if targetPart then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                            if distance <= targetDistance then
                                if AimbotSettings.WallCheck then
                                    local isWall = Workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position)
                                    if not (isWall and not isWall.Instance:IsDescendantOf(tChar)) then
                                        target = targetPart
                                        targetDistance = distance
                                    end
                                else
                                    target = targetPart
                                    targetDistance = distance
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return target
end

local function DrawFOV()
    if FOVCircle then FOVCircle:Remove() end
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 1
    FOVCircle.Color = Color3.fromRGB(255, 0, 0)
    FOVCircle.Filled = false
    FOVCircle.Visible = AimbotSettings.DrawFOV
    FOVCircle.Radius = AimbotSettings.FOV
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

function Combat.CreateModules()
    Combat.Modules.Aimbot = Relief.addModule("Combat", "Aimbot", function(enabled)
        if enabled then
            DrawFOV()
            AimbotEnabled = true
            AimbotConnection = RunService.RenderStepped:Connect(function()
                if not AimbotEnabled then return end
                if Camera.CameraType ~= Enum.CameraType.Scriptable then return end

                local target = GetClosestPlayer()
                if not target then return end

                local camPos = Camera.CFrame.Position
                local targetPos = target.Position

                local currentLook = Camera.CFrame.LookVector
                local desiredLook = (targetPos - camPos).Unit

                local strength = AimbotSettings.Strength
                local smoothLook = currentLook:Lerp(desiredLook, strength)

                Camera.CFrame = CFrame.new(camPos, camPos + smoothLook)

                local char = getCharacter()
                if not char then return end

                local root = getRoot()
                if not root then return end

                local rootPos = root.Position
                local targetPos2 = target.Position

                local flatDir = Vector3.new(
                    targetPos2.X - rootPos.X,
                    0,
                    targetPos2.Z - rootPos.Z
                )

                local desiredCF = CFrame.lookAt(rootPos, rootPos + flatDir)
                root.CFrame = root.CFrame:Lerp(desiredCF, strength)
            end)
        else
            AimbotEnabled = false
            if AimbotConnection then AimbotConnection:Disconnect() AimbotConnection = nil end
            if FOVCircle then FOVCircle:Remove() FOVCircle = nil end
        end
    end, {
        {Type = "Dropdown", Options = {"Head", "HumanoidRootPart", "Closest"}, Default = "Head", Title = "Target Part", Callback = function(v) AimbotSettings.TargetPart = v end},
        {Type = "Slider", Default = 200, Min = 0, Max = 1000, Title = "FOV", Callback = function(v) AimbotSettings.FOV = v if FOVCircle then FOVCircle.Radius = v end end},
        {Type = "Slider", Default = 0.25, Min = 0, Max = 1, Title = "Strength", Callback = function(v) AimbotSettings.Strength = v end},
        {Type = "Toggle", Title = "Wall Check", Default = true, Callback = function(v) AimbotSettings.WallCheck = v end},
        {Type = "Toggle", Title = "Draw FOV", Default = true, Callback = function(v) AimbotSettings.DrawFOV = v if FOVCircle then FOVCircle.Visible = v end end},
    })

    local ViewModels = nil
    task.spawn(function()
        repeat task.wait() until Workspace:FindFirstChild("ViewModels")
        ViewModels = Workspace.ViewModels
    end)

    local function GetPlayerWeapons()
        local Weapons = {}
        if not ViewModels then return Weapons end

        for _, model in ViewModels:GetChildren() do
            if model.Name ~= "FirstPerson" then
                local data = model.Name:split(" - ")
                local target = Players:FindFirstChild(data[1])
                table.insert(Weapons, {
                    Target = target,
                    Name = data[2]
                })
            end
        end

        return Weapons
    end

    local function MouseClick()
        local VirtualInputManager = game:GetService("VirtualInputManager")
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end

    local KatanaCheck = false
    local TriggerDelay = 0.05

    Combat.Modules.TriggerBot = Relief.addModule("Combat", "TriggerBot", function(enabled)
        if enabled then
            local TriggerBotEnabled = true
            local TriggerBotConnection = RunService.Heartbeat:Connect(function()
                if not TriggerBotEnabled then return end
                if Camera.CameraType ~= Enum.CameraType.Scriptable then return end

                local char = getCharacter()
                if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then return end

                local target = LocalPlayer:GetMouse().Target
                if not target then return end

                if KatanaCheck then
                    local weapons = GetPlayerWeapons()
                    if weapons then
                        local hasKatana = false
                        for _, weapon in weapons do
                            if weapon.Target == target and weapon.Name == "Katana" then
                                hasKatana = true
                                break
                            end
                        end
                        if hasKatana then return end
                    end
                end

                local tChar = target.Parent
                local tHum = tChar:FindFirstChildOfClass("Humanoid")
                if not tHum or tHum.Health <= 0 then return end

                local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                if not tRoot then return end
                if tRoot.Velocity.Magnitude >= 75 then return end

                local player = Players:GetPlayerFromCharacter(tChar)
                if not player then return end

                MouseClick()
            end)
        else
        end
    end, {
        {Type = "Toggle", Title = "KatanaCheck", Default = true, Callback = function(v) KatanaCheck = v end},
        {Type = "Slider", Title = "Delay", Default = 0.05, Min = 0, Max = 0.3, Callback = function(v) TriggerDelay = v end},
    })

    local ESPEnabled = false
    local ESPConnection = nil
    local ESPBoxes = {}

    Combat.Modules.ESP = Relief.addModule("Combat", "ESP", function(enabled)
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

    local LoopFlingEnabled = false
    local LoopFlingConnection = nil

    Combat.Modules.LoopFling = Relief.addModule("Combat", "LoopFling", function(enabled)
        if enabled then
            Workspace.FallenPartsDestroyHeight = 0/0
            LoopFlingEnabled = true
            LoopFlingConnection = RunService.Heartbeat:Connect(function()
                if not LoopFlingEnabled then return end

                local char = getCharacter()
                if not char then return end

                local root = getRoot()
                if not root then return end

                local oldPos = root.CFrame
                local flung = false

                for _, target in Players:GetPlayers() do
                    if target ~= LocalPlayer then
                        local isWhitelisted = false
                        if getgenv().IsWhitelisted then
                            isWhitelisted = getgenv().IsWhitelisted(target)
                        end
                        if not isWhitelisted then
                            local tChar = target.Character
                            if tChar then
                                local tHum = tChar:FindFirstChildOfClass("Humanoid")
                                if tHum and not tHum.SeatPart then
                                    local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                                    if tRoot and tRoot.Velocity.Magnitude <= 500 then
                                        local hum = getHumanoid()
                                        if hum then
                                            hum:ChangeState(Enum.HumanoidStateType.Physics)

                                            for _, bp in char:GetChildren() do
                                                if bp:IsA("BasePart") then
                                                    bp.Velocity = Vector3.zero
                                                    bp.RotVelocity = Vector3.zero
                                                end
                                            end

                                            local prediction = Vector3.zero
                                            if oldPos then
                                                prediction = (oldPos.Position - tRoot.Position) * -75
                                            end
                                            local offset = CFrame.new(math.random(-2, 2), math.random(-2, 2), math.random(-2, 2))
                                            root.CFrame = (tRoot.CFrame * CFrame.Angles(os.clock() * 49218, os.clock() * 1849, os.clock() * 32178) * offset) + prediction
                                            oldPos = tRoot.CFrame

                                            root.Velocity = Vector3.new(9e7, 9e8, 9e7)
                                            root.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
                                            flung = true
                                            task.wait()
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                if not flung then return end

                char = getCharacter()
                if not char then return end

                root = getRoot()
                if not root then return end

                hum = getHumanoid()
                if not hum then return end

                repeat
                    root.CFrame = oldPos
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)

                    for _, bp in char:GetDescendants() do
                        if bp:IsA("BasePart") then
                            bp.Velocity = Vector3.zero
                            bp.RotVelocity = Vector3.zero
                        end
                    end
                until (root.Position - oldPos.Position).Magnitude < 1
            end)
        else
            LoopFlingEnabled = false
            if LoopFlingConnection then LoopFlingConnection:Disconnect() LoopFlingConnection = nil end
        end
    end)
end

function Combat.Cleanup()
    for name, module in pairs(Combat.Modules) do
        if module and module.Toggled then
            pcall(module.Callback, false)
        end
    end
    Combat.Modules = {}
end

return Combat