local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local NumberFormatter = require(ReplicatedStorage:WaitForChild("NumberFormatter"))

local upgradeRequest = ReplicatedStorage:WaitForChild("UpgradeRequest")
local upgradeResult = ReplicatedStorage:WaitForChild("UpgradeResult")
local upgradeDefinitions = ReplicatedStorage:WaitForChild("UpgradeDefinitions")

local UpgradeManager = {}

local function round(number, numDecimalPlaces)
	local mult = 10 ^ (numDecimalPlaces or 0)
	return math.floor(number * mult + 0.5) / mult
end

local function calcCost(baseCost, costMult, count)
	return math.floor(baseCost * (costMult ^ count))
end

local function getDef(buttonName)
	local defFolder = upgradeDefinitions:FindFirstChild(buttonName)
	if not defFolder then
		return nil
	end

	local baseCost = defFolder:FindFirstChild("BaseCost")
	local costMult = defFolder:FindFirstChild("CostMult")
	local max = defFolder:FindFirstChild("Max")
	local addCPC = defFolder:FindFirstChild("AddCPC")
	local addCPS = defFolder:FindFirstChild("AddCPS")
	local addMult = defFolder:FindFirstChild("AddMult")

	if not (baseCost and costMult and max and addCPC and addCPS and addMult) then
		return nil
	end

	return {
		baseCost = baseCost.Value,
		costMult = costMult.Value,
		max = max.Value,
		addCPC = addCPC.Value,
		addCPS = addCPS.Value,
		addMult = addMult.Value,
	}
end

local function getCount(player, buttonName)
	local upgradesFolder = player:FindFirstChild("Upgrades")
	if not upgradesFolder then
		return 0
	end

	local countValue = upgradesFolder:FindFirstChild(buttonName .. "_Count")
	if not countValue then
		return 0
	end

	return countValue.Value
end

function UpgradeManager.updateButtonText(button)
	local def = getDef(button.Name)
	if not def then
		warn("Missing/invalid definition for button: " .. button.Name)
		return
	end

	local player = Players.LocalPlayer
	local count = getCount(player, button.Name)
	local cost = calcCost(def.baseCost, def.costMult, count)

	local upgradeNameValue = button:FindFirstChild("UpgradeName")
	local title = upgradeNameValue and upgradeNameValue.Value or button.Name

	local buttonText = "<b><font color=\"#FFD700\">" .. title .. "</font></b>"

	if def.max > 0 then
		buttonText ..= ": <font color=\"#FFFFFF\">" .. count .. "/" .. def.max .. "</font>"
	else
		buttonText ..= "  <font color=\"#FFFFFF\"> " .. count .. "</font>"
	end

	buttonText ..= "\n"

	if def.addCPC > 0 then
		buttonText ..= "<font size=\"24\" color=\"#00FF00\">+" .. def.addCPC .. " Doggies per click</font>\n"
	end

	if def.addCPS > 0 then
		buttonText ..= "<font size=\"22\" color=\"#00BFFF\">+" .. def.addCPS .. " Doggies per second</font>\n"
	end

	if def.addMult > 0 then
		buttonText ..= "<font size=\"22\" color=\"#1E90FF\">+" .. def.addMult .. " Multiplier</font>\n"
	end

	buttonText ..= "<font size=\"30\" color=\"#FFFFFF\">Cost: </font><font size=\"30\" color=\"#FF4500\">" ..
		NumberFormatter:FormatNumber(round(cost, 2)) .. "</font>"

	button.Text = buttonText
end

-- UI hint only (server decides)
function UpgradeManager.checkIfCanAfford(button)
	local player = Players.LocalPlayer
	local coins = player and player:FindFirstChild("Doggies")
	if not coins then
		return false
	end

	local def = getDef(button.Name)
	if not def then
		return false
	end

	local count = getCount(player, button.Name)
	local cost = calcCost(def.baseCost, def.costMult, count)

	return coins.Value >= cost
end

function UpgradeManager.requestUpgrade(button)
	upgradeRequest:FireServer(button.Name)

	local clickSound = button:FindFirstChild("ClickSound")
	if clickSound then
		clickSound:Play()
	end
end

-- Call once from your UI script
-- updateButtonByNameFn should return the button instance by name (or nil)
function UpgradeManager.hookUpgradeResults(updateButtonByNameFn)
	upgradeResult.OnClientEvent:Connect(function(buttonName, success, _code, payload)
		if not success then
			return
		end

		local btn = updateButtonByNameFn(buttonName)
		if btn then
			UpgradeManager.updateButtonText(btn)
		end

		-- If you want, you can also use payload.nextCost/newCount to update
		-- immediately without waiting for replication.
		-- (Not required with our calc-based UI.)
	end)
end

return UpgradeManager
