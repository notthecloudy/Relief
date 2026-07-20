local Utilities = {}

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local chatFolder = nil

function Utilities.GetChatFolder()
	if chatFolder then return chatFolder end
	
	for _, folder in TextChatService:GetChildren() do
		if folder:IsA("Folder") and folder.Name == "TextChannels" and #folder:GetChildren() >= 1 then
			chatFolder = folder
			return chatFolder
		end
	end
	return nil
end

function Utilities.Chat(message)
	local folder = Utilities.GetChatFolder()
	if folder and folder:FindFirstChild("RBXGeneral") then
		folder.RBXGeneral:SendAsync(message)
	end
end

function Utilities.GetOthers()
	local others = {}
	for _, player in Players:GetPlayers() do
		if player ~= LocalPlayer then
			table.insert(others, player)
		end
	end
	return others
end

function Utilities.GetPlayer(query)
	if not query then return nil end
	
	query = query:lower()
	
	if query == "all" then return Players:GetPlayers() end
	if query == "others" then return Utilities.GetOthers() end
	if query == "me" then return {LocalPlayer} end
	
	local function find(input, output)
		return input:lower():find(output, 1, true)
	end
	
	for _, player in Players:GetPlayers() do
		if find(player.Name, query) or find(player.DisplayName, query) then
			return {player}
		end
	end
	
	return nil
end

function Utilities.GetPlayersByUserId(userIds)
	local result = {}
	for _, player in Players:GetPlayers() do
		if table.find(userIds, player.UserId) then
			table.insert(result, player)
		end
	end
	return result
end

function Utilities.IsAlive(player)
	player = player or LocalPlayer
	local character = player.Character
	if not character then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid.Health > 0
end

function Utilities.GetCharacter(player)
	player = player or LocalPlayer
	return player.Character or player.CharacterAdded:Wait()
end

function Utilities.GetHumanoid(player)
	local character = Utilities.GetCharacter(player)
	return character:FindFirstChildOfClass("Humanoid")
end

function Utilities.GetRootPart(player)
	local character = Utilities.GetCharacter(player)
	return character:FindFirstChild("HumanoidRootPart")
end

function Utilities.GetTool(player, toolName)
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

function Utilities.EquipTool(player, toolName)
	local tool = Utilities.GetTool(player, toolName)
	if tool then
		local humanoid = Utilities.GetHumanoid(player)
		if humanoid then
			humanoid:EquipTool(tool)
			return true
		end
	end
	return false
end

function Utilities.UnequipTools(player)
	player = player or LocalPlayer
	local humanoid = Utilities.GetHumanoid(player)
	if humanoid then
		humanoid:UnequipTools()
	end
end

function Utilities.WaitForChild(parent, childName, timeout)
	timeout = timeout or 10
	local child = parent:FindFirstChild(childName)
	if child then return child end
	
	local start = tick()
	while tick() - start < timeout do
		child = parent:FindFirstChild(childName)
		if child then return child end
		task.wait()
	end
	return nil
end

function Utilities.WaitForDescendant(ancestor, name, timeout)
	timeout = timeout or 10
	local start = tick()
	
	while tick() - start < timeout do
		for _, desc in ancestor:GetDescendants() do
			if desc.Name == name then
				return desc
			end
		end
		task.wait()
	end
	return nil
end

function Utilities.GetDistance(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

function Utilities.GetFlatDistance(pos1, pos2)
	local flat1 = Vector3.new(pos1.X, 0, pos1.Z)
	local flat2 = Vector3.new(pos2.X, 0, pos2.Z)
	return (flat1 - flat2).Magnitude
end

function Utilities.GetDirection(from, to)
	return (to - from).Unit
end

function Utilities.Lerp(a, b, t)
	return a + (b - a) * t
end

function Utilities.Clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

function Utilities.RandomString(length)
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local result = {}
	for i = 1, length do
		result[i] = chars:sub(math.random(1, #chars), math.random(1, #chars))
	end
	return table.concat(result)
end

function Utilities.DeepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			copy[k] = Utilities.DeepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

function Utilities.TableFind(tbl, value)
	for i, v in ipairs(tbl) do
		if v == value then return i end
	end
	return nil
end

function Utilities.TableRemove(tbl, value)
	local index = Utilities.TableFind(tbl, value)
	if index then
		table.remove(tbl, index)
		return true
	end
	return false
end

function Utilities.TableClear(tbl)
	for k in pairs(tbl) do
		tbl[k] = nil
	end
end

function Utilities.MergeTables(...)
	local result = {}
	for _, tbl in ipairs({...}) do
		for k, v in pairs(tbl) do
			result[k] = v
		end
	end
	return result
end

function Utilities.FormatNumber(num)
	local formatted = tostring(num)
	local k = 3
	while k < #formatted do
		formatted = formatted:sub(1, #formatted - k) .. "," .. formatted:sub(#formatted - k + 1)
		k = k + 4
	end
	return formatted
end

function Utilities.FormatTime(seconds)
	if seconds < 60 then
		return string.format("%.1fs", seconds)
	elseif seconds < 3600 then
		local mins = math.floor(seconds / 60)
		local secs = seconds % 60
		return string.format("%dm %.1fs", mins, secs)
	else
		local hours = math.floor(seconds / 3600)
		local mins = math.floor((seconds % 3600) / 60)
		return string.format("%dh %dm", hours, mins)
	end
end

function Utilities.SafeCall(fn, ...)
	local success, result = pcall(fn, ...)
	if not success then
		warn("[Utilities] SafeCall error:", result)
		return nil, result
	end
	return result
end

function Utilities.Retry(fn, maxAttempts, delay)
	maxAttempts = maxAttempts or 3
	delay = delay or 0.5
	
	for attempt = 1, maxAttempts do
		local success, result = pcall(fn)
		if success then return result end
		
		if attempt < maxAttempts then
			task.wait(delay)
		end
	end
	return nil
end

function Utilities.Debounce(fn, cooldown)
	local lastCall = 0
	return function(...)
		local now = tick()
		if now - lastCall >= cooldown then
			lastCall = now
			return fn(...)
		end
	end
end

function Utilities.Throttle(fn, interval)
	local lastCall = 0
	return function(...)
		local now = tick()
		if now - lastCall >= interval then
			lastCall = now
			return fn(...)
		end
	end
end

function Utilities.Once(fn)
	local called = false
	return function(...)
		if not called then
			called = true
			return fn(...)
		end
	end
end

function Utilities.Memoize(fn)
	local cache = {}
	return function(...)
		local key = table.concat({...}, "|")
		if cache[key] == nil then
			cache[key] = fn(...)
		end
		return cache[key]
	end
end

function Utilities.ColorToHex(color)
	return string.format("#%02X%02X%02X", 
		math.floor(color.R * 255), 
		math.floor(color.G * 255), 
		math.floor(color.B * 255)
	)
end

function Utilities.HexToColor(hex)
	hex = hex:gsub("#", "")
	local r = tonumber(hex:sub(1, 2), 16) / 255
	local g = tonumber(hex:sub(3, 4), 16) / 255
	local b = tonumber(hex:sub(5, 6), 16) / 255
	return Color3.new(r, g, b)
end

function Utilities.Rainbow(speed, saturation, value)
	speed = speed or 1
	saturation = saturation or 1
	value = value or 1
	local hue = (tick() * speed) % 1
	return Color3.fromHSV(hue, saturation, value)
end

function Utilities.LightenColor(color, amount)
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

function Utilities.DarkenColor(color, amount)
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

function Utilities.GetSetting(moduleName, settingName, default)
	if getgenv().Relief and getgenv().Relief.getSetting then
		return getgenv().Relief.getSetting(moduleName, settingName) or default
	end
	return default
end

function Utilities.IsModuleToggled(moduleName)
	if getgenv().Relief and getgenv().Relief.isToggled then
		return getgenv().Relief.isToggled(moduleName)
	end
	return false
end

function Utilities.GetModuleEnv(moduleName)
	if getgenv().Relief and getgenv().Relief.getEnv then
		return getgenv().Relief.getEnv(moduleName)
	end
	return {}
end

function Utilities.Notify(text, duration, color)
	if getgenv().Relief and getgenv().Relief.Notify then
		getgenv().Relief.Notify(text, duration, color)
	end
end

getgenv().Utilities = Utilities

return Utilities