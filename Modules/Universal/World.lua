local World = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Thread = getgenv().Thread
local Character = getgenv().Character or require(script.Parent.Parent.Core.Character)

World.Modules = {}

function World.Init(Relief)
    World.Relief = Relief
    World.CreateModules()
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

function World.CreateModules()
    local AntiVoidEnabled = false
    local AntiVoidConnection = nil

    World.Modules.AntiVoid = Relief.addModule("World", "AntiVoid", function(enabled)
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

    local AntiBoundsKillEnabled = false

    World.Modules.AntiBoundsKill = Relief.addModule("World", "AntiBoundsKill", function(enabled)
        local boundsRemote = ReplicatedStorage:FindFirstChild("Remotes", true) and ReplicatedStorage.Remotes.Replication.Fighter.OutOfBounds
        if boundsRemote then
            if enabled then
                AntiBoundsKillEnabled = true
                boundsRemote.Parent = nil
            else
                AntiBoundsKillEnabled = false
                boundsRemote.Parent = ReplicatedStorage.Remotes.Replication.Fighter
            end
        end
    end)

    local VehicleSpamEnabled = false
    local VehicleSpamConnection = nil
    local Vehicles = {}

    for _, model in Workspace:GetChildren() do
        local button = model:FindFirstChild("Button")
        if button and model:FindFirstChildOfClass("IntValue") then
            table.insert(Vehicles, button)
        end
    end

    if #Vehicles > 0 then
        World.Modules.VehicleSpam = Relief.addModule("World", "VehicleSpam", function(enabled)
            if enabled then
                VehicleSpamEnabled = true
                VehicleSpamConnection = RunService.Heartbeat:Connect(function()
                    if not VehicleSpamEnabled then return end
                    local char = getCharacter()
                    if not char then return task.wait() end

                    local root = getRoot()
                    if not root then return end

                    for _, vehicle in Vehicles do
                        vehicle.CFrame = root.CFrame
                    end

                    task.wait()

                    for _, vehicle in Vehicles do
                        vehicle.CFrame = CFrame.new(0, 9e9, 0)
                    end
                end)
            else
                VehicleSpamEnabled = false
                if VehicleSpamConnection then VehicleSpamConnection:Disconnect() VehicleSpamConnection = nil end
            end
        end)
    end

    local PianoConnector = game:FindFirstChild("GlobalPianoConnector", true)
    if PianoConnector then
        World.Modules.PianoCrash = Relief.addModule("World", "PianoCrash", function(enabled)
            if enabled then
                local crashThread = Thread.New("PianoCrash", function()
                    task.wait()
                    if not PianoConnector then return end
                    for i = 1, 61 do
                        PianoConnector:FireServer("play", i, 12, {"18865849300"})
                        PianoConnector:FireServer("stop", i)
                    end
                end)
            else
                Thread.Disconnect("PianoCrash")
            end
        end)
    end

    local ChatSpamEnabled = false
    local ChatSpamConnection = nil

    local Utilities = require(script.Parent.Parent.Core.Utilities)

    World.Modules.ChatSpam = Relief.addModule("World", "ChatSpam", function(enabled)
        if enabled then
            ChatSpamEnabled = true
            ChatSpamConnection = Thread.New("ChatSpam", function()
                if not Relief.isToggled("ChatSpam") then return end

                for i = 1, 10 do
                    task.spawn(function()
                        local message = Relief.getSetting("ChatSpam", "Message") or "relief on top"
                        Utilities.Chat(message .. Utilities.RandomString(4))
                    end)
                    task.wait(0.05)
                end

                task.wait(30)
            end)
        else
            ChatSpamEnabled = false
            if ChatSpamConnection then Thread.Disconnect("ChatSpam") end
        end
    end, {
        {Type = "TextBox", Title = "Message", Placeholder = "msg here", Default = "relief on top", Callback = function() end}
    })

    local AdvertiseEnabled = false
    local AdvertiseConnection = nil
    local ServerHopEnabled = false
    local ServerHopConnection = nil
    local Ads = {"RELIEF ON TOP", "JOIN US", "WE OWN YOU", "LOL EZ"}
    local Link = "gg/msFnMfhuhV"
    local Special = utf8.char(0x060D)

    local function utf8Chars(str)
        local chars = {}
        for _, c in utf8.codes(str) do
            table.insert(chars, utf8.char(c))
        end
        return chars
    end

    local function utf8Reverse(str)
        local chars = utf8Chars(str)
        local rev = {}
        for i = #chars, 1, -1 do
            table.insert(rev, chars[i])
        end
        return table.concat(rev)
    end

    local function convertBypass(text)
        local reverse = utf8Reverse(text)
        local new = {}

        for word in reverse:gmatch("%S+") do
            local letters = utf8Chars(word)
            local fill = Special .. table.concat(letters, Special)
            table.insert(new, fill)
        end

        return table.concat(new, " ")
    end

    local function serverHop()
        local httpService = game:GetService("HttpService")
        local teleportService = game:GetService("TeleportService")
        local stringData = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local data = httpService:JSONDecode(stringData).data
        local validServers = {}

        for _, server in data do
            if server.playing < server.maxPlayers and game.JobId ~= server.id then
                table.insert(validServers, server)
            end
        end

        if #validServers == 0 then return end
        local randomServer = validServers[math.random(#validServers)]
        teleportService:TeleportToPlaceInstance(game.PlaceId, randomServer.id)
        Relief.KillScript()
    end

    World.Modules.Advertise = Relief.addModule("World", "Advertise", function(enabled)
        if enabled then
            AdvertiseEnabled = true
            local x = 0
            AdvertiseConnection = Thread.New("Advertise", function()
                for i = 1, 10 do
                    x = x + 1
                    local i = (x % 4)
                    if i == 0 then i = 4 end
                    Utilities.Chat(convertBypass(Link) .. Special .. "｜" .. Ads[i])
                    task.wait(0.05)
                end
                task.wait(30)
            end)
        else
            AdvertiseEnabled = false
            if AdvertiseConnection then Thread.Disconnect("Advertise") end
            if ServerHopConnection then Thread.Disconnect("ServerHop") end
        end
    end, {
        {Type = "Toggle", Title = "AutoServerHop", Callback = function(toggled)
            if toggled then
                ServerHopEnabled = true
                ServerHopConnection = Thread.New("ServerHop", function()
                    repeat task.wait() until #Players:GetPlayers() < 6 or not Relief.isToggled("Advertise") or not ServerHopEnabled
                    if not Relief.isToggled("Advertise") or not ServerHopEnabled then return end
                    serverHop()
                end)
            else
                ServerHopEnabled = false
                if ServerHopConnection then Thread.Disconnect("ServerHop") end
            end
        end}
    })

    local AutoGrabToolsEnabled = false
    local AutoGrabToolsConnection = nil

    World.Modules.AutoGrabTools = Relief.addModule("World", "AutoGrabTools", function(enabled)
        if enabled then
            AutoGrabToolsEnabled = true
            local char = getCharacter()
            local hum = getHumanoid()
            if char and hum then
                for _, tool in Workspace:GetChildren() do
                    if tool:IsA("Tool") then
                        hum:EquipTool(tool)
                    end
                end
            end

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
end

function World.Cleanup()
    for name, module in pairs(World.Modules) do
        if module and module.Toggled then
            pcall(module.Callback, false)
        end
    end
    World.Modules = {}
end

return World