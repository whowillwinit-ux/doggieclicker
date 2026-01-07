local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NumberFormatter = require(ReplicatedStorage:WaitForChild("NumberFormatter"))
local playerClass = {}
playerClass.__index = playerClass

local function round(number, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(number * mult + 0.5) / mult
end

function playerClass.new(player, self)
	repeat task.wait() until player.Character ~= nil
	if self then return setmetatable(self, playerClass) end
	local self = setmetatable({}, playerClass)
	self.name = player.Name
	self.character = player.Character

	-- Main Values
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

	-- Leaderboard setup
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	self.leaderDoggies = Instance.new("StringValue")  -- Use StringValue to store formatted numbers
	self.leaderDoggies.Name = "Doggies"
	self.leaderDoggies.Value = NumberFormatter:FormatNumber(round(self.doggies.Value), 2)
	self.leaderDoggies.Parent = leaderstats

	self.leaderBones = Instance.new("StringValue")
	self.leaderBones.Name = "Bones"
	self.leaderBones.Value = NumberFormatter:FormatNumber(self.bones.Value)
	self.leaderBones.Parent = leaderstats

	self.leaderRebirths = Instance.new("StringValue")
	self.leaderRebirths.Name = "Rebirths"
	self.leaderRebirths.Value = tostring(self.rebirths.Value)  -- Rebirths usually don't need formatting
	self.leaderRebirths.Parent = leaderstats

	return self
end

-- Setters for updating the leaderboard
function playerClass:setDoggies(value)
	self.doggies.Value = value
	self.leaderDoggies.Value = NumberFormatter:FormatNumber(round(value), 2)
end

function playerClass:setRebirths(value)
	self.rebirths.Value = value
	self.leaderRebirths.Value = tostring(value)  -- No need for formatting with K/M/B, but can be customized if needed
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

-- Example method to add Doggies
function playerClass:addDoggies(value)
	self.doggies.Value += value
	self.leaderDoggies.Value = NumberFormatter:FormatNumber(self.doggies.Value)
end

-- Example method to add Bones
function playerClass:addBones(value)
	self.bones.Value += value
	self.leaderBones.Value = NumberFormatter:FormatNumber(self.bones.Value)
end

return playerClass
