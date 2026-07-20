local Utility = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local Thread = getgenv().Thread
local Character = getgenv().Character

Utility.Modules = {}

function Utility.Init(Relief)
    Utility.Relief = Relief
    Utility.CreateModules()
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

local ChatFolder = nil

local function GetChatFolder()
    if ChatFolder then return ChatFolder end
    for _, folder in TextChatService:GetChildren() do
        if folder:IsA("Folder") and folder.Name == "TextChannels" and #folder:GetChildren() >= 1 then
            ChatFolder = folder
            return ChatFolder
        end
    end
    return nil
end

local function Chat(message)
    local folder = GetChatFolder()
    if folder and folder:FindFirstChild("RBXGeneral") then
        folder.RBXGeneral:SendAsync(message)
    end
end

function Utility.CreateModules()
    local ChatSpamEnabled = false
    local ChatSpamConnection = nil
    local ChatSpamMessage = "relief on top"

    local Special = utf8.char(0x060D)

    local Chars = {"0001", "0002", "0003", "0004", "0005", "0006", "0007", "0008", "000C", "000D", "000E", "000F", "0010", "0011", "0012", "0013", "0014", "0015", "0016", "0017", "0018", "0019", "001A", "001B", "001C", "001D", "001E", "001F"}

    local function RandomChars(length)
        local compile = ""
        for i = 1, length do
            compile = compile .. utf8.char("0x" .. Chars[math.random(#Chars)])
        end
        return compile
    end

    local function ConvertBypass(text)
        local reverse = text:reverse()
        local new = {}
        for word in reverse:gmatch("%S+") do
            local letters = {}
            for _, c in utf8.codes(word) do
                table.insert(letters, utf8.char(c))
            end
            local fill = Special .. table.concat(letters, Special)
            table.insert(new, fill)
        end
        return table.concat(new, " ")
    end

    Utility.Modules.ChatSpam = Relief.addModule("Utility", "ChatSpam", function(enabled)
        if enabled then
            ChatSpamEnabled = true
            ChatSpamMessage = Relief.getSetting("ChatSpam", "Message") or "relief on top"
            ChatSpamConnection = Thread.New("ChatSpam", function()
                if not ChatSpamEnabled then return end
                for i = 1, 10 do
                    task.spawn(function()
                        local msg = ChatSpamMessage .. RandomChars(4)
                        Chat(msg)
                    end)
                    task.wait(0.05)
                end
                task.wait(30)
            end)
        else
            ChatSpamEnabled = false
            if ChatSpamConnection then ChatSpamConnection:Disconnect() ChatSpamConnection = nil end
        end
    end, {
        {Type = "TextBox", Title = "Message", Placeholder = "msg here", Default = "relief on top", Callback = function() end}
    })

    local AdvertiseEnabled = false
    local AdvertiseConnection = nil
    local ServerHopEnabled = false
    local ServerHopConnection = nil

    local Link = "gg/aZfFCkqYyA"
    local Ads = {"RELIEF ON TOP", "JOIN US", "WE OWN YOU", "LOL EZ"}

    local function ServerHop()
        local stringData = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local data = HttpService:JSONDecode(stringData).data
        local validServers = {}

        for _, server in data do
            if server.playing < server.maxPlayers and game.JobId ~= server.id then
                table.insert(validServers, server)
            end
        end

        if #validServers == 0 then return end
        local randomServer = validServers[math.random(#validServers)]
        TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer.id)
        Relief.KillScript()
    end

    Utility.Modules.Advertise = Relief.addModule("Utility", "Advertise", function(enabled)
        if enabled then
            AdvertiseEnabled = true
            local x = 0
            AdvertiseConnection = Thread.New("Advertise", function()
                for i = 1, 10 do
                    x = x + 1
                    local i = (x % 4)
                    if i == 0 then i = 4 end
                    Chat(ConvertBypass(Link) .. Special .. "｜" .. Ads[i])
                    task.wait(0.05)
                end
                task.wait(30)
            end)
        else
            AdvertiseEnabled = false
            if AdvertiseConnection then AdvertiseConnection:Disconnect() AdvertiseConnection = nil end
        end
    end, {
        {Type = "Toggle", Title = "AutoServerHop", Callback = function(toggled)
            if toggled then
                ServerHopEnabled = true
                ServerHopConnection = Thread.New("ServerHop", function()
                    repeat task.wait() until #Players:GetPlayers() < 6 or not Relief.isToggled("Advertise") or not ServerHopEnabled
                    if not Relief.isToggled("Advertise") or not ServerHopEnabled then return end
                    ServerHop()
                end)
            else
                ServerHopEnabled = false
                if ServerHopConnection then ServerHopConnection:Disconnect() ServerHopConnection = nil end
            end
        end}
    })

    local AntiVoidEnabled = false

    Utility.Modules.AntiVoid = Relief.addModule("Utility", "AntiVoid", function(enabled)
        local Workspace = game:GetService("Workspace")
        if enabled then
            AntiVoidEnabled = true
            Workspace.FallenPartsDestroyHeight = 0/0
            Thread.Maid("AntiVoid", Workspace:GetPropertyChangedSignal("FallenPartsDestroyHeight"):Connect(function()
                if Workspace.FallenPartsDestroyHeight ~= 0/0 then
                    Workspace.FallenPartsDestroyHeight = 0/0
                end
            end))
        else
            AntiVoidEnabled = false
            Thread.Unmaid("AntiVoid")
        end
    end)

    local RejoinEnabled = false

    Utility.Modules.Rejoin = Relief.addModule("Utility", "Rejoin", function(enabled)
        if enabled then
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)

    local ServerHopModuleEnabled = false

    Utility.Modules.ServerHop = Relief.addModule("Utility", "ServerHop", function(enabled)
        if enabled then
            ServerHop()
        end
    end)

    local AutoRejoinEnabled = false
    local AutoRejoinConnection = nil

    Utility.Modules.AutoRejoin = Relief.addModule("Utility", "AutoRejoin", function(enabled)
        if enabled then
            AutoRejoinEnabled = true
            AutoRejoinConnection = game:GetService("GuiService").ErrorMessageChanged:Connect(function()
                if AutoRejoinEnabled then
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end
            end)
        else
            AutoRejoinEnabled = false
            if AutoRejoinConnection then AutoRejoinConnection:Disconnect() AutoRejoinConnection = nil end
        end
    end)

    local FpsCapEnabled = false
    local FpsCapValue = 60

    Utility.Modules.FpsCap = Relief.addModule("Utility", "FpsCap", function(enabled)
        if enabled then
            FpsCapEnabled = true
            FpsCapValue = Relief.getSetting("FpsCap", "Value") or 60
            setfpscap(FpsCapValue)
        else
            FpsCapEnabled = false
            setfpscap(9999)
        end
    end, {
        {Type = "Slider", Title = "Value", Min = 1, Max = 9999, Default = 60, Callback = function(v)
            FpsCapValue = v
            if FpsCapEnabled then setfpscap(v) end
        end}
    })

    local LagSwitchEnabled = false
    local LagSwitchConnection = nil

    Utility.Modules.LagSwitch = Relief.addModule("Utility", "LagSwitch", function(enabled)
        if enabled then
            LagSwitchEnabled = true
            LagSwitchConnection = RunService.Heartbeat:Connect(function()
                if not LagSwitchEnabled then return end
                task.wait(0.1)
            end)
        else
            LagSwitchEnabled = false
            if LagSwitchConnection then LagSwitchConnection:Disconnect() LagSwitchConnection = nil end
        end
    end)

    local ChatLogsEnabled = false
    local ChatLogsConnection = nil

    Utility.Modules.ChatLogs = Relief.addModule("Utility", "ChatLogs", function(enabled)
        if enabled then
            ChatLogsEnabled = true
            ChatLogsConnection = TextChatService.OnIncomingMessage:Connect(function(message)
                local source = message.TextSource
                if source then
                    local sender = Players:GetPlayerByUserId(source.UserId)
                    if sender then
                        print("[Chat] " .. sender.Name .. ": " .. message.Text)
                    end
                end
            end)
        else
            ChatLogsEnabled = false
            if ChatLogsConnection then ChatLogsConnection:Disconnect() ChatLogsConnection = nil end
        end
    end)

    local JoinLogsEnabled = false
    local JoinLogsConnection = nil

    Utility.Modules.JoinLogs = Relief.addModule("Utility", "JoinLogs", function(enabled)
        if enabled then
            JoinLogsEnabled = true
            JoinLogsConnection = Players.PlayerAdded:Connect(function(player)
                Relief.Notify(player.Name .. " joined the game.", 5, Color3.new(0, 1, 0))
            end)
        else
            JoinLogsEnabled = false
            if JoinLogsConnection then JoinLogsConnection:Disconnect() JoinLogsConnection = nil end
        end
    end)

    local LeaveLogsEnabled = false
    local LeaveLogsConnection = nil

    Utility.Modules.LeaveLogs = Relief.addModule("Utility", "LeaveLogs", function(enabled)
        if enabled then
            LeaveLogsEnabled = true
            LeaveLogsConnection = Players.PlayerRemoving:Connect(function(player)
                Relief.Notify(player.Name .. " left the game.", 5, Color3.new(1, 0, 0))
            end)
        else
            LeaveLogsEnabled = false
            if LeaveLogsConnection then LeaveLogsConnection:Disconnect() LeaveLogsConnection = nil end
        end
    end)

    local ModuleListEnabled = false

    Utility.Modules.ModuleList = Relief.addModule("Utility", "ModuleList", function(toggled)
        Relief.ModuleList.Visible = toggled
    end, {}, nil, true)

    local MobileButtonEnabled = false

    Utility.Modules.MobileButton = Relief.addModule("Utility", "MobileButton", function(toggled)
        Relief.MobileButton.Visible = toggled
        Relief.Arrow.Visible = toggled
    end, {}, nil, true)
end

function Utility.Cleanup()
    for name, module in pairs(Utility.Modules) do
        if module and module.Toggled then
            pcall(module.Callback, false)
        end
    end
    Utility.Modules = {}
end

getgenv().Utility = Utility

return Utility