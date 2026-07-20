local Whitelist = {}

Whitelist.List = {}
Whitelist.Connections = {}

function Whitelist.Add(userId)
    if type(userId) == "userdata" then
        userId = userId.UserId
    end
    if not table.find(Whitelist.List, userId) then
        table.insert(Whitelist.List, userId)
        return true
    end
    return false
end

function Whitelist.Remove(userId)
    if type(userId) == "userdata" then
        userId = userId.UserId
    end
    local index = table.find(Whitelist.List, userId)
    if index then
        table.remove(Whitelist.List, index)
        return true
    end
    return false
end

function Whitelist.Clear()
    Whitelist.List = {}
end

function Whitelist.IsWhitelisted(target)
    if not target then return false end
    local userId = type(target) == "userdata" and target.UserId or target
    return table.find(Whitelist.List, userId) ~= nil
end

function Whitelist.GetList()
    return Whitelist.List
end

function Whitelist.SetList(list)
    Whitelist.List = list or {}
end

function Whitelist.LoadFromConfig(config)
    if config and config.Whitelist then
        Whitelist.List = config.Whitelist
    end
end

function Whitelist.SaveToConfig(config)
    if config then
        config.Whitelist = Whitelist.List
    end
end

function Whitelist.AddPlayer(player)
    return Whitelist.Add(player.UserId)
end

function Whitelist.RemovePlayer(player)
    return Whitelist.Remove(player.UserId)
end

function Whitelist.GetWhitelistedPlayers()
    local Players = game:GetService("Players")
    local whitelisted = {}
    for _, player in Players:GetPlayers() do
        if Whitelist.IsWhitelisted(player) then
            table.insert(whitelisted, player)
        end
    end
    return whitelisted
end

function Whitelist.IsLocalPlayerWhitelisted()
    local LocalPlayer = game:GetService("Players").LocalPlayer
    return Whitelist.IsWhitelisted(LocalPlayer)
end

function Whitelist.CreateCommand()
    if not getgenv().Commands then getgenv().Commands = {} end
    if not getgenv().AddCommand then
        getgenv().AddCommand = function(names, callback)
            for _, name in ipairs(names) do
                getgenv().Commands[name:lower()] = callback
            end
        end
    end

    getgenv().AddCommand({"whitelist", "wl"}, function(args)
        local targetName = args[1]
        if not targetName then return end

        local Players = game:GetService("Players")
        local target = Players:FindFirstChild(targetName)
        if target then
            Whitelist.AddPlayer(target)
            print("[Whitelist] Added:", target.Name)
        end
    end)

    getgenv().AddCommand({"unwhitelist", "unwl"}, function(args)
        local targetName = args[1]
        if not targetName then return end

        local Players = game:GetService("Players")
        local target = Players:FindFirstChild(targetName)
        if target then
            Whitelist.RemovePlayer(target)
            print("[Whitelist] Removed:", target.Name)
        end
    end)

    getgenv().AddCommand({"whitelistlist", "wllist"}, function()
        print("[Whitelist] Current whitelist:")
        for _, userId in ipairs(Whitelist.List) do
            local Players = game:GetService("Players")
            local player = Players:GetPlayerByUserId(userId)
            print("  -", player and player.Name or "Unknown (" .. userId .. ")")
        end
    end)

    getgenv().AddCommand({"whitelistclear", "wlclear"}, function()
        Whitelist.Clear()
        print("[Whitelist] Cleared")
    end)
end

getgenv().Whitelist = Whitelist.List
getgenv().IsWhitelisted = Whitelist.IsWhitelisted
getgenv().AddToWhitelist = Whitelist.Add
getgenv().RemoveFromWhitelist = Whitelist.Remove

return Whitelist