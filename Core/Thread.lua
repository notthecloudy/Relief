local Thread = {}

Thread.Cache = {}
Thread.Connections = {}
Thread.Tables = {}
Thread.MaidTables = {}
Thread.Timers = {}
Thread.Running = {}

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local function generateId(prefix)
	return prefix .. "_" .. HttpService:GenerateGUID(false):sub(1, 8)
end

function Thread.New(name, callback, options)
	options = options or {}
	name = options.persistentId or name
	
	if Thread.Cache[name] then
		warn("[Thread] Thread already exists:", name)
		return Thread.Cache[name]
	end
	
	Thread.Cache[name] = true
	Thread.Running[name] = {
		StartTime = tick(),
		Options = options,
	}
	
	task.spawn(function()
		while Thread.Cache[name] do
			local success, err = pcall(callback)
			if not success then
				warn("[Thread] Error in", name, ":", err)
				if options.breakOnError then
					Thread.Disconnect(name)
					break
				end
			end
			
			if options.interval then
				task.wait(options.interval)
			elseif options.renderStepped then
				RunService.RenderStepped:Wait()
			elseif options.heartbeat then
				RunService.Heartbeat:Wait()
			elseif options.stepped then
				RunService.Stepped:Wait()
			else
				task.wait()
			end
		end
	end)
	
	return {
		Name = name,
		Stop = function()
			Thread.Disconnect(name)
		end,
		IsRunning = function()
			return Thread.Cache[name] == true
		end,
	}
end

function Thread.Disconnect(name)
	if Thread.Cache[name] then
		Thread.Cache[name] = nil
		Thread.Running[name] = nil
	end
end

function Thread.IsRunning(name)
	return Thread.Cache[name] == true
end

function Thread.GetRuntime(name)
	local data = Thread.Running[name]
	if data then
		return tick() - data.StartTime
	end
	return 0
end

function Thread.Maid(name, connection)
	if not connection then return nil end
	Thread.Connections[name] = connection
	return connection
end

function Thread.Unmaid(name)
	local connection = Thread.Connections[name]
	if connection then
		pcall(function() connection:Disconnect() end)
		Thread.Connections[name] = nil
	end
end

function Thread.MaidTable(name, connection)
	if not Thread.MaidTables[name] then
		Thread.MaidTables[name] = {}
	end
	table.insert(Thread.MaidTables[name], connection)
end

function Thread.UnmaidTable(name)
	if Thread.MaidTables[name] then
		for _, conn in ipairs(Thread.MaidTables[name]) do
			pcall(function() conn:Disconnect() end)
		end
		Thread.MaidTables[name] = nil
	end
end

function Thread.Table(name, callback, options)
	options = options or {}
	
	if not Thread.Tables[name] then
		Thread.Tables[name] = {}
	end
	
	local running = true
	local index = #Thread.Tables[name] + 1
	Thread.Tables[name][index] = running
	
	task.spawn(function()
		while Thread.Tables[name] and Thread.Tables[name][index] do
			local success, err = pcall(callback)
			if not success then
				warn("[Thread.Table] Error in", name, ":", err)
				if options.breakOnError then break end
			end
			
			if options.interval then
				task.wait(options.interval)
			elseif options.renderStepped then
				RunService.RenderStepped:Wait()
			elseif options.heartbeat then
				RunService.Heartbeat:Wait()
			elseif options.stepped then
				RunService.Stepped:Wait()
			else
				task.wait()
			end
		end
	end)
	
	local controller = {}
	
	function controller:Disconnect()
		running = false
		if Thread.Tables[name] then
			Thread.Tables[name][index] = nil
		end
	end
	
	function controller:IsRunning()
		return running and Thread.Tables[name] and Thread.Tables[name][index] == true
	end
	
	return controller
end

function Thread.Untable(name)
	if Thread.Tables[name] then
		for i = #Thread.Tables[name], 1, -1 do
			Thread.Tables[name][i] = nil
		end
		Thread.Tables[name] = nil
	end
end

function Thread.Delay(name, delay, callback)
	local timerName = name .. "_timer_" .. generateId("delay")
	
	Thread.Timers[timerName] = task.delay(delay, function()
		Thread.Timers[timerName] = nil
		pcall(callback)
	end)
	
	return timerName
end

function Thread.CancelTimer(timerName)
	if Thread.Timers[timerName] then
		task.cancel(Thread.Timers[timerName])
		Thread.Timers[timerName] = nil
	end
end

function Thread.Repeat(name, callback, condition, options)
	options = options or {}
	
	Thread.New(name, function()
		repeat
			pcall(callback)
			if options.interval then task.wait(options.interval) else task.wait() end
		until condition() or not Thread.Cache[name]
	end, options)
end

function Thread.Cleanup()
	for name in pairs(Thread.Cache) do
		Thread.Disconnect(name)
	end
	for name in pairs(Thread.Connections) do
		Thread.Unmaid(name)
	end
	for name in pairs(Thread.MaidTables) do
		Thread.UnmaidTable(name)
	end
	for name in pairs(Thread.Tables) do
		Thread.Untable(name)
	end
	for name in pairs(Thread.Timers) do
		Thread.CancelTimer(name)
	end
	Thread.Cache = {}
	Thread.Connections = {}
	Thread.Tables = {}
	Thread.MaidTables = {}
	Thread.Timers = {}
	Thread.Running = {}
end

getgenv().Thread = Thread

return Thread