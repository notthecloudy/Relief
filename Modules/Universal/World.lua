local World = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

World.Modules = {}

function World.Init(Relief)
    World.Relief = Relief
    World.Thread = getgenv().Thread
    World.Character = getgenv().Character
    World.CreateModules()
end

local function getRoot()
    return World.Character.GetRootPart()
end

local function getHumanoid()
    return World.Character.GetHumanoid()
end

local function getCharacter()
    return World.Character.GetCharacter()
end