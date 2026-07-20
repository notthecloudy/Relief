local Services = {}

local serviceCache = {}

function Services.Get(name)
	if serviceCache[name] then
		return serviceCache[name]
	end
	
	local success, service = pcall(function()
		return game:GetService(name)
	end)
	
	if success then
		serviceCache[name] = service
		return service
	else
		warn("[ReliefHub] Failed to get service:", name, service)
		return nil
	end
end

function Services.GetAll(names)
	local result = {}
	for _, name in ipairs(names) do
		result[name] = Services.Get(name)
	end
	return result
end

Services.Players = Services.Get("Players")
Services.RunService = Services.Get("RunService")
Services.UserInputService = Services.Get("UserInputService")
Services.TweenService = Services.Get("TweenService")
Services.HttpService = Services.Get("HttpService")
Services.ReplicatedStorage = Services.Get("ReplicatedStorage")
Services.Workspace = Services.Get("Workspace")
Services.Lighting = Services.Get("Lighting")
Services.TextChatService = Services.Get("TextChatService")
Services.TeleportService = Services.Get("TeleportService")
Services.CoreGui = Services.Get("CoreGui")
Services.ContextActionService = Services.Get("ContextActionService")
Services.SoundService = Services.Get("SoundService")
Services.StarterGui = Services.Get("StarterGui")
Services.StarterPlayer = Services.Get("StarterPlayer")
Services.MarketplaceService = Services.Get("MarketplaceService")
Services.VirtualInputManager = Services.Get("VirtualInputManager")
Services.VirtualUser = Services.Get("VirtualUser")
Services.ProximityPromptService = Services.Get("ProximityPromptService")
Services.PathfindingService = Services.Get("PathfindingService")
Services.PhysicsService = Services.Get("PhysicsService")
Services.LocalizationService = Services.Get("LocalizationService")
Services.Chat = Services.Get("Chat")
Services.Teams = Services.Get("Teams")
Services.GroupService = Services.Get("GroupService")
Services.GeoLocationService = Services.Get("GeoLocationService")
Services.GamepadService = Services.Get("GamepadService")
Services.CaptureService = Services.Get("CaptureService")
Services.AnalyticsService = Services.Get("AnalyticsService")
Services.AssetService = Services.Get("AssetService")
Services.BadgeService = Services.Get("BadgeService")
Services.DataStoreService = Services.Get("DataStoreService")
Services.InsertService = Services.Get("InsertService")
Services.MessageService = Services.Get("MessageService")
Services.PointsService = Services.Get("PointsService")
Services.SocialService = Services.Get("SocialService")
Services.StatsService = Services.Get("StatsService")
Services.TestService = Services.Get("TestService")
Services.TimerService = Services.Get("TimerService")
Services.TweenService = Services.Get("TweenService")
Services.Visit = Services.Get("Visit")
Services.LogService = Services.Get("LogService")
Services.ScriptContext = Services.Get("ScriptContext")
Services.GuiService = Services.Get("GuiService")
Services.HapticService = Services.Get("HapticService")
Services.InputMethodService = Services.Get("InputMethodService")
Services.OmniRecommendationsService = Services.Get("OmniRecommendationsService")
Services.PerformanceStats = Services.Get("PerformanceStats")
Services.PermissionsService = Services.Get("PermissionsService")
Services.PurchasePromptService = Services.Get("PurchasePromptService")
Services.VRService = Services.Get("VRService")

Services.LocalPlayer = Services.Players.LocalPlayer
Services.Camera = Services.Workspace.CurrentCamera
Services.Mouse = Services.LocalPlayer:GetMouse()

function Services.WaitForChild(parent, childName, timeout)
	timeout = timeout or 10
	local child = parent:FindFirstChild(childName)
	if child then return child end
	
	local start = tick()
	while tick() - start < timeout do
		child = parent:FindFirstChild(childName)
		if child then return child end
		task.wait()
	end
	warn("[ReliefHub] WaitForChild timeout:", childName)
	return nil
end

function Services.WaitForDescendant(ancestor, name, timeout)
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
	warn("[ReliefHub] WaitForDescendant timeout:", name)
	return nil
end

return Services