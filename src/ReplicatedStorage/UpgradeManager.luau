-- UpgradeManager (Client-Side)
local UpgradeManager = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NumberFormatter = require(ReplicatedStorage:WaitForChild("NumberFormatter"))
local upgradeRequest = ReplicatedStorage:WaitForChild("UpgradeRequest") -- RemoteEvent for upgssrade requests

local function round(number, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(number * mult + 0.5) / mult
end

function UpgradeManager.updateButtonText(button)
	local costValue = button:FindFirstChild("Cost")
	if not costValue then
		warn("CostValue not found on button: " .. button.Name)
		return
	end

	local buttonText = "<b><font color=\"#FFD700\">" .. button.UpgradeName.Value .. "</font></b>"

	if button.MaxUpgrades.Value > 0 then
		buttonText = buttonText .. ": <font color=\"#FFFFFF\">" .. button.UpgradeCount.Value .. "/" .. button.MaxUpgrades.Value .. "</font>"
	else
		buttonText = buttonText .. "  <font color=\"#FFFFFF\"> " .. button.UpgradeCount.Value .. "</font>"
	end

	buttonText = buttonText .. "\n"

	if button.CoinsPerClick and button.CoinsPerClick.Value > 0 then
		buttonText = buttonText .. "<font size=\"24\" color=\"#00FF00\">+" .. button.CoinsPerClick.Value .. " Doggies per click</font>\n"
	end

	if button.CoinsPerSecond and button.CoinsPerSecond.Value > 0 then
		buttonText = buttonText .. "<font size=\"22\" color=\"#00BFFF\">+" .. button.CoinsPerSecond.Value .. " Doggies per second</font>\n"
	end

	if button.Multiplier and button.Multiplier.Value > 0 then
		buttonText = buttonText .. "<font size=\"22\" color=\"#1E90FF\">+" .. button.Multiplier.Value .. " Multiplier</font>\n"
	end

	buttonText = buttonText .. "<font size=\"30\" color=\"#FFFFFF\">Cost: </font><font size=\"30\" color=\"#FF4500\">" .. NumberFormatter:FormatNumber(round(costValue.Value, 2)) .. "</font>"

	button.Text = buttonText
end

function UpgradeManager.checkIfCanAfford(button)
	local player = game.Players.LocalPlayer
	if not player then
		warn("LocalPlayer not found")
		return false
	end

	local costValue = button:FindFirstChild("Cost")
	local coins = player:FindFirstChild("Doggies")

	if not costValue or not coins then
		warn("CostValue or Doggies (Coins) not found for player: " .. player.Name)
		return false
	end

	return coins.Value >= costValue.Value
end

function UpgradeManager.upgradeCoinsPerClick(button)
	if UpgradeManager.checkIfCanAfford(button) then
		upgradeRequest:FireServer(button.Name) -- Send the upgrade request to the server

		if button:FindFirstChild("ClickSound") then
			button.ClickSound:Play()
		end

		UpgradeManager.updateButtonText(button)
	else
		print("Not enough coins!")
	end
end

return UpgradeManager
