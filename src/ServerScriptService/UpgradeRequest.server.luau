-- UpgradeRequest (Server-Side)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local upgradeRequest = ReplicatedStorage:WaitForChild("UpgradeRequest")

local function handleUpgradeRequest(player, upgradeName)
	-- Retrieve the PlayerClass instance for the player
	local playerClass = _G.playerClasses[player.UserId]
	if not playerClass then
		warn("PlayerClass not found for player: " .. player.Name)
		return
	end

	local coins = playerClass.doggies
	local coinsPerClick = playerClass.coinsPerClick
	local coinsPerSecond = playerClass.coinsPerSecond
	local multiplier = playerClass.multiplier

	if not coins or not coinsPerClick or not coinsPerSecond or not multiplier then
		warn("Player stats not properly initialized for player: " .. player.Name)
		return
	end

	-- Find the upgrade button corresponding to the upgradeName
	local upgradesGui = player:FindFirstChild("PlayerGui"):FindFirstChild("UpgradesGui")
	if not upgradesGui then
		warn("UpgradesGui not found for player: " .. player.Name)
		return
	end

	local scrollingFrame = upgradesGui:FindFirstChild("UpgradesFrame"):FindFirstChild("ScrollingFrame")
	if not scrollingFrame then
		warn("ScrollingFrame not found in UpgradesGui for player: " .. player.Name)
		return
	end

	local button = scrollingFrame:FindFirstChild(upgradeName)
	if not button then
		warn("Upgrade button not found: " .. upgradeName)
		return
	end

	local costValue = button:FindFirstChild("Cost")
	if not costValue then
		warn("CostValue not found on button: " .. button.Name)
		return
	end

	if coins.Value >= costValue.Value then
		-- Deduct cost
		coins.Value = coins.Value - costValue.Value

		-- Update stats based on the upgrade
		coinsPerClick.Value = coinsPerClick.Value + button.CoinsPerClick.Value
		coinsPerSecond.Value = coinsPerSecond.Value + button.CoinsPerSecond.Value
		multiplier.Value = multiplier.Value + button.Multiplier.Value

		-- Update the upgrade count and cost
		button.UpgradeCount.Value = button.UpgradeCount.Value + 1
		costValue.Value = math.floor(costValue.Value * 1.17)

		-- Save the updated player data
		_G.save(player.UserId, playerClass)
	else
		print("Not enough coins!")
	end
end

upgradeRequest.OnServerEvent:Connect(handleUpgradeRequest)
