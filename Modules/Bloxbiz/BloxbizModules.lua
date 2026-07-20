local BloxbizModules = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")

BloxbizModules.Remotes = {
    GetOutfit = BloxbizRemotes:WaitForChild("GetOutfit"),
    GetLayeredOutfit = BloxbizRemotes:WaitForChild("GetLayeredOutfit"),
    LayeredAccessory = BloxbizRemotes:WaitForChild("LayeredAccessory"),
    RemoveLayeredAccessory = BloxbizRemotes:WaitForChild("RemoveLayeredAccessory"),
    ClearLayeredOutfit = BloxbizRemotes:WaitForChild("ClearLayeredOutfit"),
    SetOutfit = BloxbizRemotes:WaitForChild("SetOutfit"),
    GetOwnedAccessories = BloxbizRemotes:WaitForChild("GetOwnedAccessories"),
}

function BloxbizModules.IsLayered(accessoryType)
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

function BloxbizModules.GetLayeredAccessories()
    return BloxbizModules.Remotes.GetLayeredOutfit:InvokeServer()
end

function BloxbizModules.AddLayeredAccessory(assetId, scale)
    BloxbizModules.Remotes.LayeredAccessory:FireServer({assetId}, scale or {})
end

function BloxbizModules.RemoveLayeredAccessory(assetId)
    BloxbizModules.Remotes.RemoveLayeredAccessory:FireServer(assetId)
end

function BloxbizModules.ClearLayeredOutfit()
    BloxbizModules.Remotes.ClearLayeredOutfit:FireServer()
end

function BloxbizModules.GetOwnedAccessories()
    return BloxbizModules.Remotes.GetOwnedAccessories:InvokeServer()
end

function BloxbizModules.GetOutfit()
    return BloxbizModules.Remotes.GetOutfit:InvokeServer()
end

function BloxbizModules.SetOutfit(outfitData)
    BloxbizModules.Remotes.SetOutfit:FireServer(outfitData)
end

return BloxbizModules