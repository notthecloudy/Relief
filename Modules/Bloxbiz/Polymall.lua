local Polymall = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PolymallRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")
local GetOutfit = PolymallRemotes:WaitForChild("GetOutfit")
local GetLayeredOutfit = PolymallRemotes:WaitForChild("GetLayeredOutfit")
local LayeredAccessory = PolymallRemotes:WaitForChild("LayeredAccessory")
local RemoveLayeredAccessory = PolymallRemotes:WaitForChild("RemoveLayeredAccessory")
local ClearLayeredOutfit = PolymallRemotes:WaitForChild("ClearLayeredOutfit")
local SetOutfit = PolymallRemotes:WaitForChild("SetOutfit")
local GetOwnedAccessories = PolymallRemotes:WaitForChild("GetOwnedAccessories")

Polymall.Outfit = {}
Polymall.Outfit.__index = Polymall.Outfit

function Polymall.Outfit:New()
    local self = setmetatable({}, Polymall.Outfit)
    self.Layered = {}
    return self
end

function Polymall.Outfit:Add(assetId)
    table.insert(self.Layered, assetId)
end

function Polymall.Outfit:Remove(assetId)
    for i, id in ipairs(self.Layered) do
        if id == assetId then
            table.remove(self.Layered, i)
            break
        end
    end
end

function Polymall.Outfit:Scale(properties)
    self.ScaleProperties = properties
end

function Polymall.Outfit:Load()
    if #self.Layered == 0 then return end
    
    local args = {
        [1] = self.Layered,
        [2] = self.ScaleProperties or {}
    }
    
    LayeredAccessory:FireServer(unpack(args))
end

function Polymall.Outfit:Clear()
    ClearLayeredOutfit:FireServer()
    self.Layered = {}
end

function Polymall.IsLayered(accessoryType)
    local layeredTypes = {
        Enum.AccessoryType.Hair,
        Enum.AccessoryType.Face,
        Enum.AccessoryType.Neck,
        Enum.AccessoryType.Shoulders,
        Enum.AccessoryType.Front,
        Enum.AccessoryType.Back,
        Enum.AccessoryType.Waist,
    }
    return table.find(layeredTypes, accessoryType) ~= nil
end

function Polymall:Reset()
    ClearLayeredOutfit:FireServer()
end

function Polymall:GetOwnedAccessories()
    return GetOwnedAccessories:InvokeServer()
end

function Polymall:GetOutfit()
    return GetOutfit:InvokeServer()
end

function Polymall:GetLayeredOutfit()
    return GetLayeredOutfit:InvokeServer()
end

function Polymall:SetOutfit(outfitData)
    SetOutfit:FireServer(outfitData)
end

return Polymall