local Init = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

Init.Version = "2.0.0"
Init.LoadTime = tick()
Init.GameId = game.PlaceId
Init.GameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
Init.UserId = LocalPlayer.UserId
Init.Username = LocalPlayer.Name
Init.DisplayName = LocalPlayer.DisplayName
Init.IsStudio = RunService:IsStudio()
Init.IsLoaded = game:IsLoaded()

Init.Env = {}
setmetatable(Init.Env, {
	__index = function(_, k)
		return getgenv()[k]
	end,
	__newindex = function(_, k, v)
		getgenv()[k] = v
	end,
})

Init.LoadedModules = {}
Init.Registry = {}

function Init.LoadModule(path)
	if Init.LoadedModules[path] then
		return Init.LoadedModules[path]
	end
	
	local success, result = pcall(function()
		return loadfile(path)()
	end)
	
	if success then
		Init.LoadedModules[path] = result
		return result
	else
		warn("[ReliefHub] Failed to load module:", path, result)
		return nil
	end
end

function Init.Require(moduleName)
	local path = "C:\\Users\\PC\\Downloads\\ReliefHub\\" .. moduleName .. ".lua"
	return Init.LoadModule(path)
end

function Init.RegisterModule(name, module)
	Init.Registry[name] = module
	return module
end

function Init.GetModule(name)
	return Init.Registry[name]
end

function Init.WaitForGameLoad(timeout)
	timeout = timeout or 30
	local start = tick()
	
	if Init.IsLoaded then
		return true
	end
	
	repeat
		task.wait(0.1)
		Init.IsLoaded = game:IsLoaded()
	until Init.IsLoaded or (tick() - start) > timeout
	
	return Init.IsLoaded
end

function Init.SafeCall(fn, ...)
	local args = {...}
	local success, result = pcall(fn, unpack(args))
	if not success then
		warn("[ReliefHub] SafeCall error:", result)
		return nil, result
	end
	return result
end

function Init.GetTime()
	return tick() - Init.LoadTime
end

function Init.IsAlive(player)
	player = player or LocalPlayer
	local character = player.Character
	if not character then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid.Health > 0
end

function Init.GetCharacter(player)
	player = player or LocalPlayer
	return player.Character or player.CharacterAdded:Wait()
end

function Init.GetHumanoid(player)
	local character = Init.GetCharacter(player)
	return character:FindFirstChildOfClass("Humanoid")
end

function Init.GetRootPart(player)
	local character = Init.GetCharacter(player)
	return character:FindFirstChild("HumanoidRootPart")
end

getgenv().Init = Init

return Init