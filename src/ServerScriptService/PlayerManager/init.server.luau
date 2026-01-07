local ps = game:GetService("Players")
local dss = game:GetService("DataStoreService")
local http = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerClasses = {}
local saveInterval = 60
local isSaving = false

_G.playerClasses = playerClasses

local playerClassDB = dss:GetDataStore("_1playerClassData")

-- RemoteEvent to notify client when PlayerClass is ready
local playerClassReadyEvent = Instance.new("RemoteEvent")
playerClassReadyEvent.Name = "PlayerClassReady"
playerClassReadyEvent.Parent = ReplicatedStorage

-- RemoteFunction to allow client to retrieve playerClass
local getPlayerClassRemoteFunction = Instance.new("RemoteFunction")
getPlayerClassRemoteFunction.Name = "GetPlayerClass"
getPlayerClassRemoteFunction.Parent = ReplicatedStorage

-- Function to retrieve playerClass for a given player
getPlayerClassRemoteFunction.OnServerInvoke = function(player)
	return playerClasses[player.UserId]
end

-- Function to handle when a player joins the game
function playerJoined(player)
	local playerId = player.UserId
	local success, result = pcall(function()
		return playerClassDB:GetAsync(playerId)
	end)

	local playerClass
	if success and result then
		print("Player data was found, loading data.")
		local decodedData = http:JSONDecode(result)
		playerClass = require(script.PlayerClass).new(player)

		playerClass:setDoggies(decodedData.doggies or 0)
		playerClass:setRebirths(decodedData.rebirths or 0)
		playerClass:setCoinsPerSecond(decodedData.coinsPerSecond or 0)
		playerClass:setCoinsPerClick(decodedData.coinsPerClick or 1)
		playerClass:setMultiplier(decodedData.multiplier or 1)
		playerClass:setBones(decodedData.bones or 1)
	else
		print("No data was found, player joined for the first time.")
		playerClass = require(script.PlayerClass).new(player)
	end

	playerClasses[playerId] = playerClass
	print("PlayerClass initialized for " .. player.Name)

	-- Notify the client that the PlayerClass is ready
	playerClassReadyEvent:FireClient(player)

	-- Start saving data periodically
	spawn(function()
		while player and player.Parent do
			wait(saveInterval)
			save(playerId, playerClass)
		end
	end)
end

-- Function to save player data
function save(playerId, playerClass)
	if isSaving then
		return
	end

	isSaving = true
	local success, err = pcall(function()
		local jsonStructure = http:JSONEncode({
			doggies = playerClass.doggies and playerClass.doggies.Value or 0,
			rebirths = playerClass.rebirths and playerClass.rebirths.Value or 0,
			coinsPerSecond = playerClass.coinsPerSecond and playerClass.coinsPerSecond.Value or 0,
			coinsPerClick = playerClass.coinsPerClick and playerClass.coinsPerClick.Value or 1,
			multiplier = playerClass.multiplier and playerClass.multiplier.Value or 1,
			bones = playerClass.bones and playerClass.bones.Value or 1,
		})
		playerClassDB:SetAsync(playerId, jsonStructure)
	end)

	if not success then
		warn("Failed to save data for player with ID " .. playerId .. ": " .. err)
	else
		print("Data saved for player with ID " .. playerId)
	end

	isSaving = false
end

ps.PlayerAdded:Connect(playerJoined)
ps.PlayerRemoving:Connect(function(player)
	local playerId = player.UserId
	local playerClass = playerClasses[playerId]

	if playerClass then
		save(playerId, playerClass)
	else
		warn("No PlayerClass instance found for player with ID " .. playerId .. " when attempting to save data.")
	end

	playerClasses[playerId] = nil
end)

game:BindToClose(function()
	print("Server Shutdown.")
	for playerId, playerClass in pairs(playerClasses) do
		save(playerId, playerClass)
	end
end)
