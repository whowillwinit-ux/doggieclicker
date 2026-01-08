local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rebirthRequest = ReplicatedStorage:FindFirstChild("RebirthRequest")
if not rebirthRequest then
	rebirthRequest = Instance.new("RemoteEvent")
	rebirthRequest.Name = "RebirthRequest"
	rebirthRequest.Parent = ReplicatedStorage
end

local rebirthResult = ReplicatedStorage:FindFirstChild("RebirthResult")
if not rebirthResult then
	rebirthResult = Instance.new("RemoteEvent")
	rebirthResult.Name = "RebirthResult"
	rebirthResult.Parent = ReplicatedStorage
end

local function getPlayerClass(player)
	return _G.playerClasses and _G.playerClasses[player.UserId]
end

local function calcRebirthCost(rebirthCount)
	local initialCost = 50000
	return math.floor(initialCost * (1.17 ^ rebirthCount))
end

local function resetUpgrades(player)
	local upgradesFolder = player:FindFirstChild("Upgrades")
	if not upgradesFolder then return end

	for _, v in ipairs(upgradesFolder:GetChildren()) do
		if v:IsA("IntValue") and string.sub(v.Name, -6) == "_Count" then
			v.Value = 0
		end
	end
end

rebirthRequest.OnServerEvent:Connect(function(player)
	local pc = getPlayerClass(player)
	if not pc then
		rebirthResult:FireClient(player, false, "NoPlayerClass")
		return
	end

	local doggies = pc.doggies
	local cpc = pc.coinsPerClick
	local cps = pc.coinsPerSecond
	local mult = pc.multiplier
	local rebirths = pc.rebirths

	if not (doggies and cpc and cps and mult and rebirths) then
		rebirthResult:FireClient(player, false, "StatsMissing")
		return
	end

	local cost = calcRebirthCost(rebirths.Value)
	if doggies.Value < cost then
		rebirthResult:FireClient(player, false, "NoMoney", cost)
		return
	end

	-- Pay cost + rebirth effects (server authoritative)
	doggies.Value = doggies.Value - cost

	rebirths.Value += 1
	mult.Value += 0.10

	-- Reset progression stats (choose your defaults)
	doggies.Value = 100
	cpc.Value = 1
	cps.Value = 0

	-- Reset upgrade counts (this is what you were missing)
	resetUpgrades(player)

	-- Save
	if _G.SavePlayer then
		_G.SavePlayer(player.UserId, pc)
	end

	rebirthResult:FireClient(player, true, "OK", cost)
end)
