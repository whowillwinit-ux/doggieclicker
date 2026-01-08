local ReplicatedStorage = game:GetService("ReplicatedStorage")

local upgradeRequest = ReplicatedStorage:WaitForChild("UpgradeRequest")

local upgradeResult = ReplicatedStorage:FindFirstChild("UpgradeResult")
if not upgradeResult then
	upgradeResult = Instance.new("RemoteEvent")
	upgradeResult.Name = "UpgradeResult"
	upgradeResult.Parent = ReplicatedStorage
end

local defs = ReplicatedStorage:WaitForChild("UpgradeDefinitions")

local function getPlayerClass(player)
	return _G.playerClasses and _G.playerClasses[player.UserId]
end

local function getOrCreateInt(parent, name, defaultValue)
	local v = parent:FindFirstChild(name)
	if not v then
		v = Instance.new("IntValue")
		v.Name = name
		v.Value = defaultValue or 0
		v.Parent = parent
	end
	return v
end

local function calcCost(baseCost, costMult, count)
	return math.floor(baseCost * (costMult ^ count))
end

upgradeRequest.OnServerEvent:Connect(function(player, upgradeName)
	if type(upgradeName) ~= "string" then return end

	local defFolder = defs:FindFirstChild(upgradeName)
	if not defFolder then
		upgradeResult:FireClient(player, upgradeName, false, "UnknownUpgrade")
		return
	end

	local baseCost = defFolder:FindFirstChild("BaseCost")
	local costMult = defFolder:FindFirstChild("CostMult")
	local max = defFolder:FindFirstChild("Max")
	local addCPC = defFolder:FindFirstChild("AddCPC")
	local addCPS = defFolder:FindFirstChild("AddCPS")
	local addMult = defFolder:FindFirstChild("AddMult")

	if not (baseCost and costMult and max and addCPC and addCPS and addMult) then
		upgradeResult:FireClient(player, upgradeName, false, "BadDefinition")
		return
	end

	local pc = getPlayerClass(player)
	if not pc then
		upgradeResult:FireClient(player, upgradeName, false, "NoPlayerClass")
		return
	end

	local coins = pc.doggies
	local cpc = pc.coinsPerClick
	local cps = pc.coinsPerSecond
	local mult = pc.multiplier
	if not (coins and cpc and cps and mult) then
		upgradeResult:FireClient(player, upgradeName, false, "StatsMissing")
		return
	end

	local upgradesFolder = player:FindFirstChild("Upgrades")
	if not upgradesFolder then
		upgradesFolder = Instance.new("Folder")
		upgradesFolder.Name = "Upgrades"
		upgradesFolder.Parent = player
	end

	local countValue = getOrCreateInt(upgradesFolder, upgradeName .. "_Count", 0)
	local count = countValue.Value

	if max.Value > 0 and count >= max.Value then
		upgradeResult:FireClient(player, upgradeName, false, "Maxed")
		return
	end

	local cost = calcCost(baseCost.Value, costMult.Value, count)
	if coins.Value < cost then
		upgradeResult:FireClient(player, upgradeName, false, "NoMoney")
		return
	end

	coins.Value -= cost
	countValue.Value = count + 1

	if addCPC.Value ~= 0 then cpc.Value += addCPC.Value end
	if addCPS.Value ~= 0 then cps.Value += addCPS.Value end
	if addMult.Value ~= 0 then mult.Value += addMult.Value end

	if _G.SavePlayer then
		_G.SavePlayer(player.UserId, pc)
	end

	local nextCost = calcCost(baseCost.Value, costMult.Value, countValue.Value)
	upgradeResult:FireClient(player, upgradeName, true, "OK", {
		newCoins = coins.Value,
		newCount = countValue.Value,
		nextCost = nextCost,
	})
end)
