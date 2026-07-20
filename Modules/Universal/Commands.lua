local Commands = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Thread = getgenv().Thread
local Character = getgenv().Character or require(script.Parent.Parent.Core.Character)
local Utilities = require(script.Parent.Parent.Core.Utilities)

Commands.List = {}
Commands.Prefix = ";"

function Commands.Init(Relief)
    Commands.Relief = Relief
    Commands.RegisterCommands()
end

function Commands.Register(name, aliases, callback, description)
    local cmd = {
        Name = name,
        Aliases = aliases or {},
        Callback = callback,
        Description = description or ""
    }
    
    Commands.List[name:lower()] = cmd
    for _, alias in ipairs(aliases) do
        Commands.List[alias:lower()] = cmd
    end
end

function Commands.Get(name)
    return Commands.List[name:lower()]
end

function Commands.Execute(input)
    if not input or input == "" then return end
    
    if input:sub(1, #Commands.Prefix) ~= Commands.Prefix then return end
    
    local args = input:sub(#Commands.Prefix + 1):split(" ")
    local cmdName = args[1]:lower()
    table.remove(args, 1)
    
    local cmd = Commands.Get(cmdName)
    if cmd then
        task.spawn(function()
            local success, err = pcall(cmd.Callback, args)
            if not success then
                warn("[Commands] Error executing " .. cmdName .. ": " .. tostring(err))
            end
        end)
        return true
    end
    
    return false
end

local function getPlayer(query)
    return Utilities.GetPlayer(query)
end

function Commands.RegisterCommands()
    Commands.Register("whitelist", {"wl"}, function(args)
        local targets = getPlayer(args[1])
        if not targets then return end
        
        for _, target in targets do
            getgenv().Whitelist.Add(target.UserId)
            print("[Whitelist] Added:", target.Name)
        end
    end, "Add player to whitelist")

    Commands.Register("unwhitelist", {"unwl"}, function(args)
        local targets = getPlayer(args[1])
        if not targets then return end
        
        for _, target in targets do
            getgenv().Whitelist.Remove(target.UserId)
            print("[Whitelist] Removed:", target.Name)
        end
    end, "Remove player from whitelist")

    Commands.Register("whitelistlist", {"wllist"}, function()
        print("[Whitelist] Current whitelist:")
        for _, userId in ipairs(getgenv().Whitelist.List) do
            local player = Players:GetPlayerByUserId(userId)
            print("  -", player and player.Name or "Unknown (" .. userId .. ")")
        end
    end, "List whitelisted players")

    Commands.Register("whitelistclear", {"wlclear"}, function()
        getgenv().Whitelist.Clear()
        print("[Whitelist] Cleared")
    end, "Clear whitelist")

    Commands.Register("fly", {}, function(args)
        local module = Commands.Relief.getModule("Fly")
        if module then module.ToggleFunction() end
    end, "Toggle fly")

    Commands.Register("noclip", {}, function(args)
        local module = Commands.Relief.getModule("Noclip")
        if module then module.ToggleFunction() end
    end, "Toggle noclip")

    Commands.Register("speed", {}, function(args)
        local module = Commands.Relief.getModule("Speed")
        if module then module.ToggleFunction() end
    end, "Toggle speed")

    Commands.Register("infjump", {"infj"}, function(args)
        local module = Commands.Relief.getModule("InfiniteJump")
        if module then module.ToggleFunction() end
    end, "Toggle infinite jump")

    Commands.Register("bhop", {}, function(args)
        local module = Commands.Relief.getModule("Bhop")
        if module then module.ToggleFunction() end
    end, "Toggle bhop")

    Commands.Register("freecam", {"fc"}, function(args)
        local module = Commands.Relief.getModule("Freecam")
        if module then module.ToggleFunction() end
    end, "Toggle freecam")

    Commands.Register("tp", {"teleport"}, function(args)
        local targetName = args[1]
        if not targetName then return end
        
        local targets = getPlayer(targetName)
        if not targets or #targets == 0 then return end
        
        local target = targets[1]
        local char = Character.GetCharacter()
        local root = Character.GetRootPart()
        local tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        
        if root and tRoot then
            root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
        end
    end, "Teleport to player")

    Commands.Register("bring", {}, function(args)
        local targetName = args[1]
        if not targetName then return end
        
        local targets = getPlayer(targetName)
        if not targets or #targets == 0 then return end
        
        local root = Character.GetRootPart()
        if not root then return end
        
        for _, target in targets do
            local tChar = target.Character
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
            if tRoot then
                tRoot.CFrame = root.CFrame * CFrame.new(0, 0, 3)
            end
        end
    end, "Bring player to you")

    Commands.Register("kill", {}, function(args)
        local targetName = args[1]
        if not targetName then return end
        
        local targets = getPlayer(targetName)
        if not targets then return end
        
        for _, target in targets do
            local tChar = target.Character
            local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
            if tHum then
                tHum.Health = 0
            end
        end
    end, "Kill player")

    Commands.Register("loopfling", {"lf"}, function(args)
        local targetName = args[1]
        if not targetName then
            local module = Commands.Relief.getModule("LoopFling")
            if module then module.ToggleFunction() end
            return
        end
        
        local targets = getPlayer(targetName)
        if not targets then return end
        
        local Workspace = game:GetService("Workspace")
        Workspace.FallenPartsDestroyHeight = 0/0
        
        local LoopFlinging = true
        local Thread = getgenv().Thread
        
        Thread.New("LoopFling", function()
            task.wait()
            local old = nil
            local flung = false
            
            local char = Character.GetCharacter()
            if not char then return end
            
            local root = Character.GetRootPart()
            if not root then return end
            
            local oldPos = root.CFrame
            
            for _, target in targets do
                if target ~= LocalPlayer then
                    local isWhitelisted = false
                    if getgenv().IsWhitelisted then
                        isWhitelisted = getgenv().IsWhitelisted(target)
                    end
                    if not isWhitelisted then
                        local tChar = target.Character
                        if tChar then
                            local tHum = tChar:FindFirstChildOfClass("Humanoid")
                            if tHum and not tHum.SeatPart then
                                local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                                if tRoot and tRoot.Velocity.Magnitude <= 500 then
                                    local hum = Character.GetHumanoid()
                                    if hum then
                                        hum:ChangeState(Enum.HumanoidStateType.Physics)
                                        
                                        for _, bp in char:GetChildren() do
                                            if bp:IsA("BasePart") then
                                                bp.Velocity = Vector3.zero
                                                bp.RotVelocity = Vector3.zero
                                            end
                                        end
                                        
                                        local prediction = old and (old.Position - tRoot.Position) * -75 or Vector3.zero
                                        local offset = CFrame.new(math.random(-2, 2), math.random(-2, 2), math.random(-2, 2))
                                        root.CFrame = (tRoot.CFrame * CFrame.Angles(os.clock() * 49218, os.clock() * 1849, os.clock() * 32178) * offset) + prediction
                                        old = tRoot.CFrame
                                        
                                        root.Velocity = Vector3.new(9e7, 9e8, 9e7)
                                        root.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
                                        flung = true
                                        task.wait()
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            if not flung then return end
            
            char = Character.GetCharacter()
            if not char then return end
            
            root = Character.GetRootPart()
            if not root then return end
            
            hum = Character.GetHumanoid()
            if not hum then return end
            
            repeat
                root.CFrame = oldPos
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                
                for _, bp in char:GetDescendants() do
                    if bp:IsA("BasePart") then
                        bp.Velocity = Vector3.zero
                        bp.RotVelocity = Vector3.zero
                    end
                end
            until (root.Position - oldPos.Position).Magnitude < 1
        end)
    end, "Loop fling player(s)")

    Commands.Register("unloopfling", {"unlf"}, function(args)
        local Thread = getgenv().Thread
        Thread.Disconnect("LoopFling")
    end, "Stop loop fling")

    Commands.Register("fling", {}, function(args)
        local targetName = args[1]
        if not targetName then return end
        
        local targets = getPlayer(targetName)
        if not targets then return end
        
        local Workspace = game:GetService("Workspace")
        Workspace.FallenPartsDestroyHeight = 0/0
        
        local old = nil
        local flung = false
        
        local char = Character.GetCharacter()
        if not char then return end
        
        local root = Character.GetRootPart()
        if not root then return end
        
        local oldPos = root.CFrame
        
        for _, target in targets do
            if target ~= LocalPlayer then
                local isWhitelisted = false
                if getgenv().IsWhitelisted then
                    isWhitelisted = getgenv().IsWhitelisted(target)
                end
                if not isWhitelisted then
                    local tChar = target.Character
                    if tChar then
                        local tHum = tChar:FindFirstChildOfClass("Humanoid")
                        if tHum then
                            local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                            if tRoot and tRoot.Velocity.Magnitude <= 500 then
                                local hum = Character.GetHumanoid()
                                if hum then
                                    hum:ChangeState(Enum.HumanoidStateType.Physics)
                                    
                                    for _, bp in char:GetChildren() do
                                        if bp:IsA("BasePart") then
                                            bp.Velocity = Vector3.zero
                                            bp.RotVelocity = Vector3.zero
                                        end
                                    end
                                    
                                    local prediction = old and (old.Position - tRoot.Position) * -75 or Vector3.zero
                                    local offset = CFrame.new(math.random(-2, 2), math.random(-2, 2), math.random(-2, 2))
                                    root.CFrame = (tRoot.CFrame * CFrame.Angles(os.clock() * 49218, os.clock() * 1849, os.clock() * 32178) * offset) + prediction
                                    old = tRoot.CFrame
                                    
                                    root.Velocity = Vector3.new(9e7, 9e8, 9e7)
                                    root.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
                                    flung = true
                                    task.wait()
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if not flung then return end
        
        char = Character.GetCharacter()
        if not char then return end
        
        root = Character.GetRootPart()
        if not root then return end
        
        hum = Character.GetHumanoid()
        if not hum then return end
        
        repeat
            root.CFrame = oldPos
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            
            for _, bp in char:GetDescendants() do
                if bp:IsA("BasePart") then
                    bp.Velocity = Vector3.zero
                    bp.RotVelocity = Vector3.zero
                end
            end
        until (root.Position - oldPos.Position).Magnitude < 5
    end, "Fling player(s) once")

    Commands.Register("void", {}, function(args)
        local targetName = args[1]
        if not targetName then return end
        
        local targets = getPlayer(targetName)
        if not targets then return end
        
        local Workspace = game:GetService("Workspace")
        Workspace.FallenPartsDestroyHeight = 0/0
        
        local old = nil
        local flung = false
        
        local char = Character.GetCharacter()
        if not char then return end
        
        local root = Character.GetRootPart()
        if not root then return end
        
        local oldPos = root.CFrame
        
        for _, target in targets do
            if target ~= LocalPlayer then
                local isWhitelisted = false
                if getgenv().IsWhitelisted then
                    isWhitelisted = getgenv().IsWhitelisted(target)
                end
                if not isWhitelisted then
                    local tChar = target.Character
                    if tChar then
                        local tHum = tChar:FindFirstChildOfClass("Humanoid")
                        if tHum then
                            local tRoot = tChar:FindFirstChild("HumanoidRootPart")
                            if tRoot and tRoot.Velocity.Magnitude <= 500 then
                                local hum = Character.GetHumanoid()
                                if hum then
                                    hum:ChangeState(Enum.HumanoidStateType.Physics)
                                    
                                    for _, bp in char:GetChildren() do
                                        if bp:IsA("BasePart") then
                                            bp.Velocity = Vector3.zero
                                            bp.RotVelocity = Vector3.zero
                                        end
                                    end
                                    
                                    local prediction = old and (old.Position - tRoot.Position) * -75 or Vector3.zero
                                    local offset = CFrame.new(math.random(-2, 2), math.random(-2, 2), math.random(-2, 2))
                                    root.CFrame = (tRoot.CFrame * CFrame.Angles(os.clock() * 49218, os.clock() * 1849, os.clock() * 32178) * offset) + prediction
                                    old = tRoot.CFrame
                                    
                                    root.Velocity = Vector3.new(9e7, 9e8, 9e7)
                                    root.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
                                    flung = true
                                    task.wait()
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if not flung then return end
        
        char = Character.GetCharacter()
        if not char then return end
        
        root = Character.GetRootPart()
        if not root then return end
        
        hum = Character.GetHumanoid()
        if not hum then return end
        
        repeat
            root.CFrame = oldPos
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            
            for _, bp in char:GetDescendants() do
                if bp:IsA("BasePart") then
                    bp.Velocity = Vector3.zero
                    bp.RotVelocity = Vector3.zero
                end
            end
        until (root.Position - oldPos.Position).Magnitude < 5
    end, "Void player(s)")

    Commands.Register("rejoin", {"rj"}, function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end, "Rejoin current server")

    Commands.Register("serverhop", {"sh"}, function()
        local HttpService = game:GetService("HttpService")
        local TeleportService = game:GetService("TeleportService")
        
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
    end, "Hop to another server")

    Commands.Register("cmds", {"commands", "help"}, function()
        print("[Commands] Available commands:")
        local seen = {}
        for name, cmd in pairs(Commands.List) do
            if not seen[cmd.Name] then
                seen[cmd.Name] = true
                local aliases = #cmd.Aliases > 0 and " (" .. table.concat(cmd.Aliases, ", ") .. ")" or ""
                print("  " .. Commands.Prefix .. cmd.Name .. aliases .. " - " .. cmd.Description)
            end
        end
    end, "List all commands")

    Commands.Register("reset", {"rs"}, function()
        LocalPlayer.Character:BreakJoints()
    end, "Reset character")

    Commands.Register("sit", {}, function()
        local hum = Character.GetHumanoid()
        if hum then hum.Sit = true end
    end, "Sit")

    Commands.Register("unsit", {}, function()
        local hum = Character.GetHumanoid()
        if hum then hum.Sit = false end
    end, "Unsit")

    Commands.Register("chat", {"say"}, function(args)
        local message = table.concat(args, " ")
        if message and message ~= "" then
            Utilities.Chat(message)
        end
    end, "Send chat message")

    Commands.Register("bypass", {"by"}, function(args)
        local message = table.concat(args, " ")
        if message and message ~= "" then
            local Utilities = require(script.Parent.Parent.Core.Utilities)
            local Special = utf8.char(0x060D)
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
            Utilities.Chat(ConvertBypass(message))
        end
    end, "Send bypassed chat message")
end

return Commands