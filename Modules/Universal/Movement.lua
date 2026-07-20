local Movement = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

Movement.Modules = {}

function Movement.Init(Relief)
    Movement.Relief = Relief
    -- Get dependencies at init time, not load time
    Movement.Thread = getgenv().Thread
    Movement.Character = getgenv().Character
    Movement.CreateModules()
end

function Movement.CreateModules()
    local Thread = Movement.Thread
    local Character = Movement.Character
    
    local function getRoot()
        return Character.GetRootPart()
    end

    local function getHumanoid()
        return Character.GetHumanoid()
    end

    local function getCharacter()
        return Character.GetCharacter()
    end

    local FlyEnabled = false
    local FlySpeed = 1
    local FlyConnection = nil

    Movement.Modules.Fly = Relief.addModule("Movement", "Fly", function(enabled)
        if enabled then
            local root = getRoot()
            local humanoid = getHumanoid()
            if not root or not humanoid then return end

            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
            Workspace.Gravity = 0

            FlyEnabled = true
            FlyConnection = RunService.Heartbeat:Connect(function()
                if not FlyEnabled then return end
                local char = getCharacter()
                local root = getRoot()
                local hum = getHumanoid()
                if not char or not root or not hum or hum.Health <= 0 then return end

                local moveDir = Vector3.zero
                if not UserInputService:GetFocusedTextBox() then
                    local camCF = Camera.CFrame
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveDir = moveDir + camCF.UpVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveDir = moveDir - camCF.UpVector end
                end

                if moveDir.Magnitude > 0 then
                    moveDir = moveDir.Unit
                    local velocity = moveDir * FlySpeed
                    root.Velocity = velocity
                    root.CFrame = CFrame.new(root.Position, root.Position + camCF.LookVector)
                else
                    root.Velocity = Vector3.zero
                end
            end)
        else
            FlyEnabled = false
            if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
            Workspace.Gravity = 196.2
            local hum = getHumanoid()
            if hum then
                for i = 1, 5 do
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    task.wait()
                end
            end
        end
    end, {
        {Type = "Slider", Title = "Speed", Min = 0, Max = 10, Default = 1, Callback = function(v) FlySpeed = v end}
    })

    local NoclipEnabled = false
    local NoclipConnection = nil
    local OriginalCollisions = {}

    Movement.Modules.Noclip = Relief.addModule("Movement", "Noclip", function(enabled)
        if enabled then
            OriginalCollisions = {}
            NoclipEnabled = true
            NoclipConnection = RunService.Stepped:Connect(function()
                local char = getCharacter()
                if not char then return end
                for _, part in char:GetDescendants() do
                    if part:IsA("BasePart") then
                        if OriginalCollisions[part] == nil then
                            OriginalCollisions[part] = part.CanCollide
                        end
                        part.CanCollide = false
                    end
                end
            end)
        else
            NoclipEnabled = false
            if NoclipConnection then NoclipConnection:Disconnect() NoclipConnection = nil end
            local char = getCharacter()
            if char then
                for part, canCollide in pairs(OriginalCollisions) do
                    if part and part.Parent then
                        part.CanCollide = canCollide
                    end
                end
            end
            OriginalCollisions = {}
        end
    end)

    local SpeedEnabled = false
    local SpeedAmount = 30
    local SpeedConnection = nil

    Movement.Modules.Speed = Relief.addModule("Movement", "Speed", function(enabled)
        if enabled then
            SpeedEnabled = true
            SpeedConnection = RunService.Heartbeat:Connect(function(dt)
                if not SpeedEnabled then return end
                local char = getCharacter()
                local root = getRoot()
                local hum = getHumanoid()
                if not char or not root or not hum or hum.Health <= 0 then return end

                local moveDir = Vector3.zero
                if not UserInputService:GetFocusedTextBox() then
                    local camCF = Camera.CFrame
                    local look = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
                    local right = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
                    if look.Magnitude > 0 then look = look.Unit end
                    if right.Magnitude > 0 then right = right.Unit end
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + look end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - look end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - right end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + right end
                end

                if moveDir.Magnitude > 0 then
                    moveDir = moveDir.Unit
                    root.CFrame = root.CFrame + moveDir * SpeedAmount * dt
                end
            end)
        else
            SpeedEnabled = false
            if SpeedConnection then SpeedConnection:Disconnect() SpeedConnection = nil end
        end
    end, {
        {Type = "Slider", Title = "Amount", Min = 1, Max = 120, Default = 30, Callback = function(v) SpeedAmount = v end}
    })

    local AntiWarpEnabled = false
    local AntiWarpConnection = nil
    local LastPosition = nil

    Movement.Modules.AntiWarp = Relief.addModule("Movement", "AntiWarp", function(enabled)
        if enabled then
            AntiWarpEnabled = true
            LastPosition = nil
            AntiWarpConnection = RunService.Heartbeat:Connect(function()
                if not AntiWarpEnabled then return end
                local root = getRoot()
                if not root then return end

                if not LastPosition then
                    LastPosition = root.CFrame
                    return
                end

                local distance = (root.Position - LastPosition.Position).Magnitude
                if distance >= 15 then
                    root.CFrame = LastPosition
                    LastPosition = nil
                else
                    LastPosition = root.CFrame
                end
            end)
        else
            AntiWarpEnabled = false
            if AntiWarpConnection then AntiWarpConnection:Disconnect() AntiWarpConnection = nil end
            LastPosition = nil
        end
    end)

    local NoClipPlayersEnabled = false
    local NoClipPlayersConnection = nil

    Movement.Modules.NoPlayerCollision = Relief.addModule("Movement", "NoPlayerCollision", function(enabled)
        if enabled then
            NoClipPlayersEnabled = true
            NoClipPlayersConnection = RunService.Stepped:Connect(function()
                for _, player in Players:GetPlayers() do
                    if player ~= LocalPlayer then
                        local char = player.Character
                        if char then
                            for _, part in char:GetDescendants() do
                                if part:IsA("BasePart") then
                                    part.CanCollide = false
                                    part.Velocity = Vector3.zero
                                    part.RotVelocity = Vector3.zero
                                end
                            end
                        end
                    end
                end
            end)
        else
            NoClipPlayersEnabled = false
            if NoClipPlayersConnection then NoClipPlayersConnection:Disconnect() NoClipPlayersConnection = nil end
        end
    end)

    local InfJumpEnabled = false
    local InfJumpConnection = nil

    Movement.Modules.InfiniteJump = Relief.addModule("Movement", "InfiniteJump", function(enabled)
        if enabled then
            InfJumpEnabled = true
            InfJumpConnection = UserInputService.JumpRequest:Connect(function()
                if InfJumpEnabled then
                    local hum = getHumanoid()
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end)
        else
            InfJumpEnabled = false
            if InfJumpConnection then InfJumpConnection:Disconnect() InfJumpConnection = nil end
        end
    end)

    local BhopEnabled = false
    local BhopConnection = nil

    Movement.Modules.Bhop = Relief.addModule("Movement", "Bhop", function(enabled)
        if enabled then
            BhopEnabled = true
            BhopConnection = RunService.Heartbeat:Connect(function()
                if not BhopEnabled then return end
                local hum = getHumanoid()
                if not hum then return end
                if hum:GetState() == Enum.HumanoidStateType.Landed or hum:GetState() == Enum.HumanoidStateType.Running then
                    if hum.FloorMaterial ~= Enum.Material.Air then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        else
            BhopEnabled = false
            if BhopConnection then BhopConnection:Disconnect() BhopConnection = nil end
        end
    end)

    local FreecamEnabled = false
    local FreecamPart = nil
    local FreecamSpeed = 1
    local FreecamConnection = nil
    local OriginalCameraSubject = nil

    Movement.Modules.Freecam = Relief.addModule("Movement", "Freecam", function(enabled)
        local ContextActionService = game:GetService("ContextActionService")
        if enabled then
            local char = getCharacter()
            local hum = getHumanoid()
            if not char or not hum then return end

            FreecamEnabled = true
            OriginalCameraSubject = Camera.CameraSubject

            FreecamPart = Instance.new("Part")
            FreecamPart.Name = "FreecamPart"
            FreecamPart.Transparency = 1
            FreecamPart.Anchored = true
            FreecamPart.CanCollide = false
            FreecamPart.CFrame = Camera.CFrame
            FreecamPart.Parent = Workspace

            Camera.CameraSubject = FreecamPart
            hum.WalkSpeed = 0
            hum.JumpPower = 0

            local keys = {}
            ContextActionService:BindActionAtPriority("Freecam", function(action, state, input)
                keys[input.KeyCode.Name] = state == Enum.UserInputState.Begin
                return Enum.ContextActionResult.Sink
            end, false, Enum.ContextActionPriority.High.Value,
                Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.E, Enum.KeyCode.Q)

            FreecamConnection = RunService.RenderStepped:Connect(function()
                if not FreecamEnabled then return end
                local moveDir = Vector3.zero
                local camCF = Camera.CFrame
                if keys["W"] then moveDir = moveDir + camCF.LookVector end
                if keys["S"] then moveDir = moveDir - camCF.LookVector end
                if keys["A"] then moveDir = moveDir - camCF.RightVector end
                if keys["D"] then moveDir = moveDir + camCF.RightVector end
                if keys["E"] then moveDir = moveDir + camCF.UpVector end
                if keys["Q"] then moveDir = moveDir - camCF.UpVector end

                if moveDir.Magnitude > 0 then
                    moveDir = moveDir.Unit
                    local newPos = FreecamPart.Position + moveDir * FreecamSpeed
                    FreecamPart.CFrame = CFrame.new(newPos, newPos + camCF.LookVector)
                end
            end)
        else
            FreecamEnabled = false
            ContextActionService:UnbindAction("Freecam")
            if FreecamConnection then FreecamConnection:Disconnect() FreecamConnection = nil end
            if FreecamPart then FreecamPart:Destroy() FreecamPart = nil end
            Camera.CameraSubject = OriginalCameraSubject or getHumanoid()
            local hum = getHumanoid()
            if hum then
                hum.WalkSpeed = 16
                hum.JumpPower = 50
            end
        end
    end, {
        {Type = "Slider", Title = "Speed", Min = 0, Max = 10, Default = 1, Callback = function(v) FreecamSpeed = v end}
    })

    local PlayerTPEnabled = false
    local PlayerTPConnection = nil

    Movement.Modules.PlayerTransporter = Relief.addModule("Movement", "PlayerTransporter", function(enabled)
        if enabled then
            local char = getCharacter()
            local root = getRoot()
            local hum = getHumanoid()
            if not char or not root or not hum then return end

            local pos = CFrame.new(root.Position)
            local smooth = 0.03
            local speed = 0.15

            PlayerTPEnabled = true
            PlayerTPConnection = RunService.Heartbeat:Connect(function()
                if not PlayerTPEnabled then return end
                char = getCharacter()
                root = getRoot()
                hum = getHumanoid()
                if not char or not root or not hum then return end

                for _, track in hum:GetPlayingAnimationTracks() do
                    track:Stop()
                end
                hum:ChangeState(Enum.HumanoidStateType.Physics)

                local moveDir = Vector3.zero
                if not UserInputService:GetFocusedTextBox() then
                    local camCF = Camera.CFrame
                    local look = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
                    local right = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + look end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - look end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - right end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + right end
                    if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveDir = moveDir + Vector3.new(0, 1.5, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveDir = moveDir - Vector3.new(0, 1.5, 0) end
                end

                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    moveDir = moveDir * 5
                end

                pos = pos + moveDir * speed
                local angle = pos * CFrame.Angles(math.rad(90), 0, 0)
                root.CFrame = root.CFrame:Lerp(angle, smooth)
                root.Velocity = Vector3.new(9e7, 9e8, 9e7)
            end)

            RunService.Stepped:Connect(function()
                if not PlayerTPEnabled then return end
                char = getCharacter()
                if not char then return end
                for _, part in char:GetDescendants() do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        else
            PlayerTPEnabled = false
            if PlayerTPConnection then PlayerTPConnection:Disconnect() PlayerTPConnection = nil end
            task.wait()
            local char = getCharacter()
            if char then
                for _, part in char:GetDescendants() do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.CanCollide = true
                    end
                end
                local hum = getHumanoid()
                if hum then
                    for i = 1, 5 do
                        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                        task.wait()
                    end
                end
            end
        end
    end)

    local AntiVoidEnabled = false
    local AntiVoidConnection = nil

    Movement.Modules.AntiVoid = Relief.addModule("Movement", "AntiVoid", function(enabled)
        if enabled then
            AntiVoidEnabled = true
            Workspace.FallenPartsDestroyHeight = 0/0
            AntiVoidConnection = Workspace:GetPropertyChangedSignal("FallenPartsDestroyHeight"):Connect(function()
                if Workspace.FallenPartsDestroyHeight ~= 0/0 then
                    Workspace.FallenPartsDestroyHeight = 0/0
                end
            end)
        else
            AntiVoidEnabled = false
            if AntiVoidConnection then AntiVoidConnection:Disconnect() AntiVoidConnection = nil end
        end
    end)

    local BlinkEnabled = false
    local BlinkOriginal = nil
    local BlinkClone = nil
    local BlinkConnection = nil

    Movement.Modules.Blink = Relief.addModule("Movement", "Blink", function(enabled)
        if enabled then
            local char = getCharacter()
            if not char then return end

            BlinkEnabled = true
            BlinkOriginal = char
            char.Archivable = true
            local animate = char:FindFirstChild("Animate")
            if animate then animate.Enabled = false end

            BlinkClone = char:Clone()
            BlinkClone.Parent = Workspace
            Camera.CameraSubject = BlinkClone:FindFirstChild("Humanoid")
            LocalPlayer.Character = BlinkClone
            if BlinkClone:FindFirstChild("Animate") then BlinkClone.Animate.Enabled = true end

            for _, part in BlinkClone:GetDescendants() do
                if part:IsA("BasePart") and part.Transparency == 0 then
                    part.Transparency = 0.5
                end
            end
        else
            BlinkEnabled = false
            if BlinkClone and BlinkOriginal then
                local pos = BlinkClone:GetPivot()
                BlinkClone:Destroy()
                LocalPlayer.Character = BlinkOriginal
                Camera.CameraSubject = BlinkOriginal:FindFirstChild("Humanoid")
                BlinkOriginal:PivotTo(pos)
                local animate = BlinkOriginal:FindFirstChild("Animate")
                if animate then animate.Enabled = true end
            end
        end
    end)
end

function Movement.Cleanup()
    for name, module in pairs(Movement.Modules) do
        if module and module.Toggled then
            pcall(module.Callback, false)
        end
    end
    Movement.Modules = {}
end

getgenv().Movement = Movement

return Movement