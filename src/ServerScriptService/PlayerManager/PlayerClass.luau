local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NumberFormatter = require(ReplicatedStorage:WaitForChild("NumberFormatter"))

local playerClass = {}
playerClass.__index = playerClass

local function round(n, decimals)
	local mult = 10 ^ (decimals or 0)
	return math.floor(n * mult + 0.5) / mult
end

function playerClass.new(player)
	local self = setmetatable({}, playerClass)

	self.player = player
	self.name = player.Name
	self.character = player.Character or player.CharacterAdded:Wait()

	-- Main Values (parented directly under player)
	self.doggies = Instance.new("NumberValue")
	self.doggies.Name = "Doggies"
	self.doggies.Value = 0
	self.doggies.Parent = player

	self.rebirths = Instance.new("IntValue")
	self.rebirths.Name = "Rebirths"
	self.rebirths.Value = 0
	self.rebirths.Parent = player

	self.coinsPerSecond = Instance.new("NumberValue")
	self.coinsPerSecond.Name = "CoinsPerSecond"
	self.coinsPerSecond.Value = 0
	self.coinsPerSecond.Parent = player

	self.coinsPerClick = Instance.new("NumberValue")
	self.coinsPerClick.Name = "CoinsPerClick"
	self.coinsPerClick.Value = 1
	self.coinsPerClick.Parent = player

	self.multiplier = Instance.new("NumberValue")
	self.multiplier.Name = "Multiplier"
	self.multiplier.Value = 1
	self.multiplier.Parent = player

	self.bones = Instance.new("IntValue")
	self.bones.Name = "Bones"
	self.bones.Value = 0
	self.bones.Parent = player

	-- Leaderboard
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	self.leaderDoggies = Instance.new("StringValue")
	self.leaderDoggies.Name = "Doggies"
	self.leaderDoggies.Value = NumberFormatter:FormatNumber(round(self.doggies.Value), 2)
	self.leaderDoggies.Parent = leaderstats

	self.leaderBones = Instance.new("StringValue")
	self.leaderBones.Name = "Bones"
	self.leaderBones.Value = NumberFormatter:FormatNumber(self.bones.Value)
	self.leaderBones.Parent = leaderstats

	self.leaderRebirths = Instance.new("StringValue")
	self.leaderRebirths.Name = "Rebirths"
	self.leaderRebirths.Value = tostring(self.rebirths.Value)
	self.leaderRebirths.Parent = leaderstats

	return self
end

function playerClass:setDoggies(value)
	self.doggies.Value = value
	self.leaderDoggies.Value = NumberFormatter:FormatNumber(round(value), 2)
end

function playerClass:setRebirths(value)
	self.rebirths.Value = value
	self.leaderRebirths.Value = tostring(value)
end

function playerClass:setCoinsPerSecond(value)
	self.coinsPerSecond.Value = value
end

function playerClass:setCoinsPerClick(value)
	self.coinsPerClick.Value = value
end

function playerClass:setMultiplier(value)
	self.multiplier.Value = value
end

function playerClass:setBones(value)
	self.bones.Value = value
	self.leaderBones.Value = NumberFormatter:FormatNumber(value)
end

function playerClass:addDoggies(value)
	local newValue = self.doggies.Value + value
	self.doggies.Value = newValue
	self.leaderDoggies.Value = NumberFormatter:FormatNumber(round(newValue), 2)
end

function playerClass:addBones(value)
	local newValue = self.bones.Value + value
	self.bones.Value = newValue
	self.leaderBones.Value = NumberFormatter:FormatNumber(newValue)
end

return playerClass
