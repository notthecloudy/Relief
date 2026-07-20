local Player = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Thread = getgenv().Thread
local Character = getgenv().Character

Player.Modules = {}

function Player.Init(Relief)
    Player.Relief = Relief
    Player.CreateModules()
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

function Player.CreateModules()
    local AntiAfkEnabled = false
    local AntiAfkConnection = nil

    Player.Modules.AntiAfk = Relief.addModule("Player", "AntiAfk", function(enabled)
        local VirtualUser = game:GetService("VirtualUser")
        if enabled then
            AntiAfkEnabled = true
            AntiAfkConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.zero, Camera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.zero, Camera.CFrame)
                Relief.Notify("Prevented idle timeout.", 5, Color3.new(0, 1, 0))
            end)
        else
            AntiAfkEnabled = false
            if AntiAfkConnection then AntiAfkConnection:Disconnect() AntiAfkConnection = nil end
        end
    end)

    local AutoResetEnabled = false
    local AutoResetConnection = nil

    Player.Modules.AutoReset = Relief.addModule("Player", "AutoReset", function(enabled)
        if enabled then
            AutoResetEnabled = true
            AutoResetConnection = RunService.Heartbeat:Connect(function()
                if not AutoResetEnabled then return end
                local hum = getHumanoid()
                if hum and hum.Health <= 0 then
                    LocalPlayer.Character:BreakJoints()
                end
            end)
        else
            AutoResetEnabled = false
            if AutoResetConnection then AutoResetConnection:Disconnect() AutoResetConnection = nil end
        end
    end)

    local AntiSitEnabled = false

    Player.Modules.AntiSit = Relief.addModule("Player", "AntiSit", function(enabled)
        if enabled then
            AntiSitEnabled = true
            local function handleChar(char)
                local hum = char:WaitForChild("Humanoid")
                hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            end
            handleChar(getCharacter())
            Thread.Maid("AntiSit", LocalPlayer.CharacterAdded:Connect(handleChar))
        else
            AntiSitEnabled = false
            Thread.Unmaid("AntiSit")
            local char = getCharacter()
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end
            end
        end
    end)

    local GodModeEnabled = false
    local GodModeConnection = nil

    Player.Modules.GodMode = Relief.addModule("Player", "GodMode", function(enabled)
        if enabled then
            GodModeEnabled = true
            GodModeConnection = RunService.Heartbeat:Connect(function()
                if not GodModeEnabled then return end
                local hum = getHumanoid()
                if hum then
                    hum.MaxHealth = 9e9
                    hum.Health = 9e9
                end
            end)
        else
            GodModeEnabled = false
            if GodModeConnection then GodModeConnection:Disconnect() GodModeConnection = nil end
            local hum = getHumanoid()
            if hum then
                hum.MaxHealth = 100
                hum.Health = 100
            end
        end
    end)

    local InfHealthEnabled = false
    local InfHealthConnection = nil

    Player.Modules.InfiniteHealth = Relief.addModule("Player", "InfiniteHealth", function(enabled)
        if enabled then
            InfHealthEnabled = true
            InfHealthConnection = RunService.Heartbeat:Connect(function()
                if not InfHealthEnabled then return end
                local hum = getHumanoid()
                if hum then
                    hum.Health = hum.MaxHealth
                end
            end)
        else
            InfHealthEnabled = false
            if InfHealthConnection then InfHealthConnection:Disconnect() InfHealthConnection = nil end
        end
    end)

    local WalkSpeedEnabled = false
    local WalkSpeedValue = 16
    local WalkSpeedConnection = nil

    Player.Modules.WalkSpeed = Relief.addModule("Player", "WalkSpeed", function(enabled)
        if enabled then
            WalkSpeedEnabled = true
            WalkSpeedConnection = RunService.Heartbeat:Connect(function()
                if not WalkSpeedEnabled then return end
                local hum = getHumanoid()
                if hum then
                    hum.WalkSpeed = WalkSpeedValue
                end
            end)
        else
            WalkSpeedEnabled = false
            if WalkSpeedConnection then WalkSpeedConnection:Disconnect() WalkSpeedConnection = nil end
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = 16 end
        end
    end, {
        {Type = "Slider", Title = "Speed", Min = 16, Max = 200, Default = 16, Callback = function(v) WalkSpeedValue = v end}
    })

    local JumpPowerEnabled = false
    local JumpPowerValue = 50
    local JumpPowerConnection = nil

    Player.Modules.JumpPower = Relief.addModule("Player", "JumpPower", function(enabled)
        if enabled then
            JumpPowerEnabled = true
            JumpPowerConnection = RunService.Heartbeat:Connect(function()
                if not JumpPowerEnabled then return end
                local hum = getHumanoid()
                if hum then
                    hum.JumpPower = JumpPowerValue
                end
            end)
        else
            JumpPowerEnabled = false
            if JumpPowerConnection then JumpPowerConnection:Disconnect() JumpPowerConnection = nil end
            local hum = getHumanoid()
            if hum then hum.JumpPower = 50 end
        end
    end, {
        {Type = "Slider", Title = "Power", Min = 50, Max = 300, Default = 50, Callback = function(v) JumpPowerValue = v end}
    })

    local HipHeightEnabled = false
    local HipHeightValue = 0
    local HipHeightConnection = nil

    Player.Modules.HipHeight = Relief.addModule("Player", "HipHeight", function(enabled)
        if enabled then
            HipHeightEnabled = true
            HipHeightConnection = RunService.Heartbeat:Connect(function()
                if not HipHeightEnabled then return end
                local hum = getHumanoid()
                if hum then
                    hum.HipHeight = HipHeightValue
                end
            end)
        else
            HipHeightEnabled = false
            if HipHeightConnection then HipHeightConnection:Disconnect() HipHeightConnection = nil end
            local hum = getHumanoid()
            if hum then hum.HipHeight = 0 end
        end
    end, {
        {Type = "Slider", Title = "Height", Min = -10, Max = 10, Default = 0, Callback = function(v) HipHeightValue = v end}
    })

    local AutoGrabToolsEnabled = false
    local AutoGrabToolsConnection = nil

    Player.Modules.AutoGrabTools = Relief.addModule("Player", "AutoGrabTools", function(enabled)
        if enabled then
            AutoGrabToolsEnabled = true
            local function equipTools()
                local char = getCharacter()
                local hum = getHumanoid()
                if not char or not hum then return end

                for _, tool in Workspace:GetChildren() do
                    if tool:IsA("Tool") then
                        hum:EquipTool(tool)
                    end
                end
            end

            equipTools()
            AutoGrabToolsConnection = Workspace.ChildAdded:Connect(function(obj)
                if obj:IsA("Tool") then
                    local char = getCharacter()
                    local hum = getHumanoid()
                    if char and hum then
                        hum:EquipTool(obj)
                    end
                end
            end)
        else
            AutoGrabToolsEnabled = false
            if AutoGrabToolsConnection then AutoGrabToolsConnection:Disconnect() AutoGrabToolsConnection = nil end
        end
    end)

    local NoClipEnabled = false
    local NoClipConnection = nil

    Player.Modules.NoClip = Relief.addModule("Player", "NoClip", function(enabled)
        if enabled then
            NoClipEnabled = true
            NoClipConnection = RunService.Stepped:Connect(function()
                local char = getCharacter()
                if not char then return end
                for _, part in char:GetDescendants() do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        else
            NoClipEnabled = false
            if NoClipConnection then NoClipConnection:Disconnect() NoClipConnection = nil end
            local char = getCharacter()
            if char then
                for _, part in char:GetDescendants() do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end)

    local FriendLogsEnabled = false
    local FriendLogsLog = {}
    local FriendLogsConnections = {}

    Player.Modules.FriendLogs = Relief.addModule("Player", "FriendLogs", function(enabled)
        if enabled then
            FriendLogsEnabled = true

            local function friendLog(text, color)
                if FriendLogsEnabled then
                    Relief.Notify(text, 8, color)
                end
            end

            local function handlePlayer(player)
                FriendLogsLog[player] = {}

                for _, target in Players:GetPlayers() do
                    FriendLogsLog[player][target] = player:GetFriendStatus(target)
                end

                FriendLogsConnections[player.Name .. "_Added"] = Players.PlayerAdded:Connect(function(target)
                    if not Players:FindFirstChild(player.Name) then
                        if FriendLogsConnections[player.Name] then
                            FriendLogsConnections[player.Name]:Disconnect()
                            FriendLogsConnections[player.Name] = nil
                        end
                        return
                    end
                    repeat task.wait() until Players:FindFirstChild(target.Name)
                    FriendLogsLog[player][target] = player:GetFriendStatus(target)
                end)

                FriendLogsConnections[player.Name .. "_Handle"] = player.FriendStatusChanged:Connect(function(target, newStatus)
                    if newStatus.Value == Enum.FriendStatus.FriendRequestSent then
                        friendLog(("<u>%s</u> sent friend request to <u>%s</u>."):format(target.Name, player.Name), Color3.new(1, 1, 0))
                        FriendLogsConnections[target.Name .. "_" .. player.Name] = player.FriendStatusChanged:Connect(function(newTarget, newNewStatus)
                            if newTarget == target then
                                if newNewStatus.Value == Enum.FriendStatus.Unknown then
                                    friendLog(("<u>%s</u> declined <u>%s</u>'s friend request."):format(player.Name, target.Name), Color3.new(1, 0, 0))
                                end
                                if newNewStatus.Value == Enum.FriendStatus.Friend then
                                    friendLog(("<u>%s</u> accepted <u>%s</u>'s friend request."):format(player.Name, target.Name), Color3.new(0, 1, 0))
                                end
                                if FriendLogsConnections[target.Name .. "_" .. player.Name] then
                                    FriendLogsConnections[target.Name .. "_" .. player.Name]:Disconnect()
                                    FriendLogsConnections[target.Name .. "_" .. player.Name] = nil
                                end
                            end
                        end)
                    end

                    if player == LocalPlayer then return end

                    local old = FriendLogsLog[player][target]
                    if not old then return end

                    if old.Value == Enum.FriendStatus.Friend and newStatus.Value == Enum.FriendStatus.Unknown then
                        friendLog(("<u>%s</u> and <u>%s</u> are no longer friends."):format(target.Name, player.Name), Color3.new(1, 0, 0))
                    end

                    FriendLogsLog[player][target] = newStatus
                end)
            end

            for _, player in Players:GetPlayers() do
                handlePlayer(player)
            end

            FriendLogsConnections["HandleFriend"] = Players.PlayerAdded:Connect(handlePlayer)

            FriendLogsConnections["FriendLeave"] = Players.PlayerRemoving:Connect(function(player)
                FriendLogsLog[player] = nil
                for _, data in FriendLogsLog do
                    data[player] = nil
                end

                if FriendLogsConnections[player.Name .. "_Added"] then
                    FriendLogsConnections[player.Name .. "_Added"]:Disconnect()
                    FriendLogsConnections[player.Name .. "_Added"] = nil
                end
            end)
        else
            FriendLogsEnabled = false
            for _, conn in FriendLogsConnections do
                if conn then conn:Disconnect() end
            end
            FriendLogsConnections = {}
            FriendLogsLog = {}
        end
    end)

    local ForceResetEnabled = false

    Player.Modules.ForceReset = Relief.addModule("Player", "ForceReset", function(enabled)
        if enabled then
            LocalPlayer.Character:BreakJoints()
            Relief.Notify("Character reset.", 3, Color3.new(1, 1, 0))
        end
    end)

    local ViewModels = nil
    task.spawn(function()
        repeat task.wait() until Workspace:FindFirstChild("ViewModels")
        ViewModels = Workspace.ViewModels
    end)

    Player.Modules.ViewModelChanger = Relief.addModule("Player", "ViewModelChanger", function(enabled)
    end, {
        {Type = "TextBox", Title = "Model ID", Placeholder = "rbxassetid://...", Callback = function() end},
        {Type = "Button", Title = "Apply", Callback = function() end},
    })
end

function Player.Cleanup()
    for name, module in pairs(Player.Modules) do
        if module and module.Toggled then
            pcall(module.Callback, false)
        end
    end
    Player.Modules = {}
end

getgenv().Player = Player

return Player