local GameRegistry = {}

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")

GameRegistry.Games = {}
GameRegistry.LoadedGame = nil
GameRegistry.GameScripts = {}

GameRegistry.Registry = {
    [11137575513] = {Name = "TheChosenOne", Script = "TheChosenOne", DisplayName = "The Chosen One"},
    [12943245078] = {Name = "TheChosenOne", Script = "TheChosenOne", DisplayName = "The Chosen One XL"},
    [96017656548489] = {Name = "BanOrBeBanned", Script = "BanOrBeBanned", DisplayName = "Ban or Get Banned"},
    [17625359962] = {Name = "Rivals", Script = "Rivals", DisplayName = "Rivals"},
    [117398147513099] = {Name = "Rivals", Script = "Rivals", DisplayName = "Rivals Match"},
    [118614517739521] = {Name = "BlindShot", Script = "BlindShot", DisplayName = "BlindShot"},
    [9008985963] = {Name = "DeveloperHub", Script = "DeveloperHub", DisplayName = "Developer Hub"},
}

function GameRegistry.GetCurrentGame()
    local placeId = game.PlaceId
    local entry = GameRegistry.Registry[placeId]
    if entry then
        return entry
    end
    return nil
end

function GameRegistry.LoadGame(entry)
    if not entry then
        warn("[GameRegistry] No game entry found for PlaceId:", game.PlaceId)
        return false
    end
    
    local scriptName = entry.Script
    local url = "https://raw.githubusercontent.com/notthecloudy/Relief/main/Games/" .. scriptName .. ".lua"
    
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success or not result then
        warn("[GameRegistry] HTTP Fetch failed:", result)
        return false
    end
    
    -- Check if response is HTML (404 page)
    if result:find("^%s*<") then
        print("[GameRegistry] Game script not found on GitHub (404):", entry.DisplayName)
        return false
    end
    
    local loadSuccess, loadResult = pcall(function()
        return loadstring(result)()
    end)
    
    if loadSuccess then
        GameRegistry.LoadedGame = entry
        print("[GameRegistry] Loaded game:", entry.DisplayName)
        return true
    else
        warn("[GameRegistry] Failed to execute game script:", loadResult)
        return false
    end
end

function GameRegistry.AutoLoad()
    local entry = GameRegistry.GetCurrentGame()
    if entry then
        return GameRegistry.LoadGame(entry)
    else
        print("[GameRegistry] No specific game script found, running universal only")
        return false
    end
end

function GameRegistry.RegisterGame(placeId, name, scriptName, displayName)
    GameRegistry.Registry[placeId] = {
        Name = name,
        Script = scriptName,
        DisplayName = displayName or name
    }
end

function GameRegistry.GetGameList()
    local list = {}
    for placeId, entry in pairs(GameRegistry.Registry) do
        table.insert(list, {
            PlaceId = placeId,
            Name = entry.Name,
            DisplayName = entry.DisplayName,
            Script = entry.Script
        })
    end
    return list
end

function GameRegistry.IsGameSupported()
    return GameRegistry.GetCurrentGame() ~= nil
end

function GameRegistry.GetLoadedGame()
    return GameRegistry.LoadedGame
end

return GameRegistry