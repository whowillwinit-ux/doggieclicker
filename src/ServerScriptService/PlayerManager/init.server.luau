local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local saveInterval = 60

local playerClasses = {} -- [userId] = PlayerClass
local savingLocks = {}   -- [userId] = true while saving

_G.playerClasses = playerClasses

local playerClassDB = DataStoreService:GetDataStore("_1playerClassData")

local upgradeDefinitions = ReplicatedStorage:WaitForChild("UpgradeDefinitions")

-- Ready event (optional, but useful)
local playerClassReadyEvent = ReplicatedStorage:FindFirstChild("PlayerClassReady")
if not playerClassReadyEvent then
	playerClassReadyEvent = Instance.new("RemoteEvent")
	playerClassReadyEvent.Name = "PlayerClassReady"
	playerClassReadyEvent.Parent = ReplicatedStorage
end

-- Optional snapshot getter (safe)
local getPlayerDataRemoteFunction = ReplicatedStorage:FindFirstChild("GetPlayerData")
if not getPlayerDataRemoteFunction then
	getPlayerDataRemoteFunction = Instance.new("RemoteFunction")
	getPlayerDataRemoteFunction.Name = "GetPlayerData"
	getPlayerDataRemoteFunction.Parent = ReplicatedStorage
end

local function ensureUpgradesFolder(player)
	local upgradesFolder = player:FindFirstChild("Upgrades")
	if not upgradesFolder then
		upgradesFolder = Instance.new("Folder")
		upgradesFolder.Name = "Upgrades"
		upgradesFolder.Parent = player
	end
	return upgradesFolder
end

local function collectUpgradeCounts(player)
	local upgradesFolder = player:FindFirstChild("Upgrades")
	local counts = {}
	if not upgradesFolder then
		return counts
	end

	for _, v in ipairs(upgradesFolder:GetChildren()) do
		if v:IsA("IntValue") and v.Name:sub(-6) == "_Count" then
			local upgradeName = v.Name:sub(1, #v.Name - 6)
			counts[upgradeName] = v.Value
		end
	end

	return counts
end

local function applyUpgradeCounts(player, upgradeCounts)
	local upgradesFolder = ensureUpgradesFolder(player)

	for upgradeName, count in pairs(upgradeCounts) do
		local n = tonumber(count) or 0
		local v = upgradesFolder:FindFirstChild(upgradeName .. "_Count")
		if not v then
			v = Instance.new("IntValue")
			v.Name = upgradeName .. "_Count"
			v.Parent = upgradesFolder
		end
		v.Value = n
	end
end

local function recalcStatsFromCounts(playerClass)
	local player = playerClass.player
	if not player then return end

	local upgradesFolder = ensureUpgradesFolder(player)

	-- Base stats (match your intended defaults)
	local baseCPC = 1
	local baseCPS = 0
	local baseMult = 1 + (playerClass.rebirths.Value * 0.10)

	local totalCPC = baseCPC
	local totalCPS = baseCPS
	local totalMult = baseMult

	for _, v in ipairs(upgradesFolder:GetChildren()) do
		if v:IsA("IntValue") and v.Name:sub(-6) == "_Count" then
			local upgradeName = v.Name:sub(1, #v.Name - 6)
			local count = v.Value

			if count > 0 then
				local defFolder = upgradeDefinitions:FindFirstChild(upgradeName)
				if defFolder then
					local addCPC = defFolder:FindFirstChild("AddCPC")
					local addCPS = defFolder:FindFirstChild("AddCPS")
					local addMult = defFolder:FindFirstChild("AddMult")

					if addCPC then totalCPC += addCPC.Value * count end
					if addCPS then totalCPS += addCPS.Value * count end
					if addMult then totalMult += addMult.Value * count end
				end
			end
		end
	end

	playerClass.coinsPerClick.Value = totalCPC
	playerClass.coinsPerSecond.Value = totalCPS
	playerClass.multiplier.Value = totalMult
end

local function buildSaveData(playerClass)
	local player = playerClass.player
	return {
		doggies = playerClass.doggies and playerClass.doggies.Value or 0,
		bones = playerClass.bones and playerClass.bones.Value or 0,
		rebirths = playerClass.rebirths and playerClass.rebirths.Value or 0,

		-- Save upgrade state (source of truth for progression)
		upgradeCounts = player and collectUpgradeCounts(player) or {},

		-- Optional legacy fields (keep them to not break older data)
		-- They won’t be used to compute stats on load anymore,
		-- but we keep them in case you want them later.
		coinsPerClick = playerClass.coinsPerClick and playerClass.coinsPerClick.Value or 1,
		coinsPerSecond = playerClass.coinsPerSecond and playerClass.coinsPerSecond.Value or 0,
		multiplier = playerClass.multiplier and playerClass.multiplier.Value or 1,
	}
end

getPlayerDataRemoteFunction.OnServerInvoke = function(player)
	local pc = playerClasses[player.UserId]
	if not pc then
		return nil
	end
	return buildSaveData(pc)
end

local function save(userId, playerClass)
	if savingLocks[userId] then return end
	savingLocks[userId] = true

	local data = buildSaveData(playerClass)

	local ok, err = pcall(function()
		playerClassDB:UpdateAsync(userId, function()
			return data
		end)
	end)

	if not ok then
		warn(("Failed to save data for player %d: %s"):format(userId, tostring(err)))
	end

	savingLocks[userId] = nil
end

_G.SavePlayer = save

local function loadIntoPlayerClass(playerClass, data)
	playerClass:setDoggies(data.doggies or 0)
	playerClass:setBones(data.bones or 0)
	playerClass:setRebirths(data.rebirths or 0)

	-- Apply upgrade counts first, then recalc stats from them
	if type(data.upgradeCounts) == "table" then
		applyUpgradeCounts(playerClass.player, data.upgradeCounts)
	else
		-- Ensure folder exists even if no saved counts
		ensureUpgradesFolder(playerClass.player)
	end

	recalcStatsFromCounts(playerClass)

	-- If this is old data that had no upgradeCounts, keep old stats (fallback)
	if type(data.upgradeCounts) ~= "table" then
		if data.coinsPerClick then playerClass:setCoinsPerClick(data.coinsPerClick) end
		if data.coinsPerSecond then playerClass:setCoinsPerSecond(data.coinsPerSecond) end
		if data.multiplier then playerClass:setMultiplier(data.multiplier) end
	end
end

local function playerJoined(player)
	local userId = player.UserId

	local PlayerClass = require(script.PlayerClass)
	local playerClass = PlayerClass.new(player)

	local ok, data = pcall(function()
		return playerClassDB:GetAsync(userId)
	end)

	if ok and type(data) == "table" then
		loadIntoPlayerClass(playerClass, data)
	else
		-- New player / datastore error
		loadIntoPlayerClass(playerClass, {})
	end

	playerClasses[userId] = playerClass
	playerClassReadyEvent:FireClient(player)

	task.spawn(function()
		while player.Parent do
			task.wait(saveInterval)
			local pc = playerClasses[userId]
			if pc then
				save(userId, pc)
			end
		end
	end)
end

Players.PlayerAdded:Connect(playerJoined)

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	local pc = playerClasses[userId]
	if pc then
		save(userId, pc)
	end

	playerClasses[userId] = nil
	savingLocks[userId] = nil
end)

game:BindToClose(function()
	for userId, pc in pairs(playerClasses) do
		save(userId, pc)
	end
end)
