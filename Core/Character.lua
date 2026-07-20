local Character = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

Character.Cache = {}
Character.Connections = {}

function Character.GetLocalPlayer()
    return LocalPlayer
end

function Character.GetCharacter(player)
    player = player or LocalPlayer
    return player.Character or player.CharacterAdded:Wait()
end

function Character.GetHumanoid(player)
    local character = Character.GetCharacter(player)
    return character:FindFirstChildOfClass("Humanoid")
end

function Character.GetRootPart(player)
    local character = Character.GetCharacter(player)
    return character:FindFirstChild("HumanoidRootPart")
end

function Character.GetHead(player)
    local character = Character.GetCharacter(player)
    return character:FindFirstChild("Head")
end

function Character.IsAlive(player)
    player = player or LocalPlayer
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

function Character.WaitForCharacter(player, timeout)
    player = player or LocalPlayer
    timeout = timeout or 10
    local character = player.Character
    if character then return character end

    local start = tick()
    while tick() - start < timeout do
        character = player.Character
        if character then return character end
        task.wait()
    end
    return nil
end

function Character.WaitForHumanoid(player, timeout)
    local character = Character.WaitForCharacter(player, timeout)
    if not character then return nil end

    timeout = timeout or 5
    local start = tick()
    while tick() - start < timeout do
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then return humanoid end
        task.wait()
    end
    return nil
end

function Character.WaitForRootPart(player, timeout)
    local character = Character.WaitForCharacter(player, timeout)
    if not character then return nil end

    timeout = timeout or 5
    local start = tick()
    while tick() - start < timeout do
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then return rootPart end
        task.wait()
    end
    return nil
end

function Character.GetTool(player, toolName)
    player = player or LocalPlayer
    local character = player.Character
    local backpack = player:FindFirstChild("Backpack")

    if character then
        local tool = character:FindFirstChild(toolName)
        if tool and tool:IsA("Tool") then return tool end
    end

    if backpack then
        local tool = backpack:FindFirstChild(toolName)
        if tool and tool:IsA("Tool") then return tool end
    end

    return nil
end

function Character.EquipTool(player, toolName)
    local tool = Character.GetTool(player, toolName)
    if tool then
        local humanoid = Character.GetHumanoid(player)
        if humanoid then
            humanoid:EquipTool(tool)
            return true
        end
    end
    return false
end

function Character.UnequipTools(player)
    player = player or LocalPlayer
    local humanoid = Character.GetHumanoid(player)
    if humanoid then
        humanoid:UnequipTools()
    end
end

function Character.GetTools(player)
    player = player or LocalPlayer
    local tools = {}
    local character = player.Character
    local backpack = player:FindFirstChild("Backpack")

    if character then
        for _, tool in character:GetChildren() do
            if tool:IsA("Tool") then table.insert(tools, tool) end
        end
    end

    if backpack then
        for _, tool in backpack:GetChildren() do
            if tool:IsA("Tool") then table.insert(tools, tool) end
        end
    end

    return tools
end

function Character.SetCollisions(character, canCollide)
    if not character then return end
    for _, part in character:GetDescendants() do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = canCollide
        end
    end
end

function Character.SetVelocity(character, velocity, rotVelocity)
    if not character then return end
    for _, part in character:GetDescendants() do
        if part:IsA("BasePart") then
            part.Velocity = velocity or Vector3.zero
            part.RotVelocity = rotVelocity or Vector3.zero
        end
    end
end

function Character.StopAnimations(humanoid)
    if not humanoid then return end
    for _, track in humanoid:GetPlayingAnimationTracks() do
        track:Stop()
    end
end

function Character.GetState(humanoid)
    return humanoid and humanoid:GetState() or nil
end

function Character.SetState(humanoid, state)
    if humanoid then
        humanoid:ChangeState(state)
    end
end

function Character.SetStateEnabled(humanoid, state, enabled)
    if humanoid then
        humanoid:SetStateEnabled(state, enabled)
    end
end

function Character.GetMoveDirection(humanoid)
    return humanoid and humanoid.MoveDirection or Vector3.zero
end

function Character.GetWalkSpeed(humanoid)
    return humanoid and humanoid.WalkSpeed or 16
end

function Character.SetWalkSpeed(humanoid, speed)
    if humanoid then
        humanoid.WalkSpeed = speed
    end
end

function Character.GetJumpPower(humanoid)
    return humanoid and humanoid.JumpPower or 50
end

function Character.SetJumpPower(humanoid, power)
    if humanoid then
        humanoid.JumpPower = power
    end
end

function Character.GetHipHeight(humanoid)
    return humanoid and humanoid.HipHeight or 0
end

function Character.SetHipHeight(humanoid, height)
    if humanoid then
        humanoid.HipHeight = height
    end
end

function Character.GetMaxHealth(humanoid)
    return humanoid and humanoid.MaxHealth or 100
end

function Character.SetMaxHealth(humanoid, health)
    if humanoid then
        humanoid.MaxHealth = health
        humanoid.Health = health
    end
end

function Character.GetHealth(humanoid)
    return humanoid and humanoid.Health or 0
end

function Character.SetHealth(humanoid, health)
    if humanoid then
        humanoid.Health = health
    end
end

function Character.Heal(humanoid, amount)
    if humanoid then
        humanoid.Health = math.min(humanoid.Health + amount, humanoid.MaxHealth)
    end
end

function Character.Damage(humanoid, amount)
    if humanoid then
        humanoid.Health = math.max(humanoid.Health - amount, 0)
    end
end

function Character.BreakJoints(character)
    character = character or LocalPlayer.Character
    if character then
        character:BreakJoints()
    end
end

function Character.Respawn()
    local humanoid = Character.GetHumanoid()
    if humanoid then
        humanoid.Health = 0
    end
end

function Character.Teleport(cframe, player)
    player = player or LocalPlayer
    local rootPart = Character.GetRootPart(player)
    if rootPart then
        rootPart.CFrame = cframe
    end
end

function Character.TeleportTo(target, player)
    player = player or LocalPlayer
    local rootPart = Character.GetRootPart(player)
    local targetRoot = Character.GetRootPart(target)
    if rootPart and targetRoot then
        rootPart.CFrame = targetRoot.CFrame
    end
end

function Character.GetDistance(player1, player2)
    local root1 = Character.GetRootPart(player1)
    local root2 = Character.GetRootPart(player2)
    if root1 and root2 then
        return (root1.Position - root2.Position).Magnitude
    end
    return math.huge
end

function Character.GetFlatDistance(player1, player2)
    local root1 = Character.GetRootPart(player1)
    local root2 = Character.GetRootPart(player2)
    if root1 and root2 then
        local flat1 = Vector3.new(root1.Position.X, 0, root1.Position.Z)
        local flat2 = Vector3.new(root2.Position.X, 0, root2.Position.Z)
        return (flat1 - flat2).Magnitude
    end
    return math.huge
end

function Character.IsVisible(target, from)
    from = from or workspace.CurrentCamera
    local root = Character.GetRootPart(target)
    if not root then return false end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(from.CFrame.Position, (root.Position - from.CFrame.Position).Unit * 500, raycastParams)
    return result and result.Instance:IsDescendantOf(target.Character)
end

function Character.GetClosestPlayer(maxDistance, teamCheck, aliveCheck)
    local closest = nil
    local closestDist = maxDistance or math.huge

    for _, player in Players:GetPlayers() do
        if player == LocalPlayer then continue end
        if teamCheck and player.Team == LocalPlayer.Team then continue end
        if aliveCheck and not Character.IsAlive(player) then continue end

        local dist = Character.GetDistance(LocalPlayer, player)
        if dist < closestDist then
            closestDist = dist
            closest = player
        end
    end

    return closest, closestDist
end

function Character.GetPlayersInRadius(radius, position, teamCheck, aliveCheck)
    position = position or Character.GetRootPart().Position
    local players = {}

    for _, player in Players:GetPlayers() do
        if player == LocalPlayer then continue end
        if teamCheck and player.Team == LocalPlayer.Team then continue end
        if aliveCheck and not Character.IsAlive(player) then continue end

        local root = Character.GetRootPart(player)
        if root and (root.Position - position).Magnitude <= radius then
            table.insert(players, player)
        end
    end

    return players
end

function Character.OnCharacterAdded(player, callback)
    player = player or LocalPlayer
    local conn = player.CharacterAdded:Connect(callback)
    table.insert(Character.Connections, conn)
    if player.Character then
        callback(player.Character)
    end
    return conn
end

function Character.OnCharacterRemoved(player, callback)
    player = player or LocalPlayer
    local conn = player.CharacterRemoving:Connect(callback)
    table.insert(Character.Connections, conn)
    return conn
end

function Character.Cleanup()
	for _, conn in Character.Connections do
		pcall(function() conn:Disconnect() end)
	end
	Character.Connections = {}
end

getgenv().Character = Character

return Character