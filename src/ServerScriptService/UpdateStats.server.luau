local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NumberFormatter = require(ReplicatedStorage:WaitForChild("NumberFormatter"))

-- RemoteEvent for updating stats
local updateStatsEvent = ReplicatedStorage:WaitForChild("UpdateStatsEvent")

local function round(number, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(number * mult + 0.5) / mult
end

-- Listen for update requests from the client
updateStatsEvent.OnServerEvent:Connect(function(player, statType, data)
	local playerStats = _G.playerClasses[player.UserId]
	if not playerStats then
		warn("PlayerClass not found or not initialized for player: " .. player.Name)
		return
	end

	if statType == "RebirthReset" then
		-- Reset stats based on the data received
		playerStats.doggies.Value = data.Doggies
		playerStats.coinsPerClick.Value = data.CoinsPerClick
		playerStats.coinsPerSecond.Value = data.CoinsPerSecond
		playerStats.multiplier.Value = data.Multiplier
		playerStats.rebirths.Value = data.Rebirths

		-- Update leaderboard with formatted values
		playerStats.leaderDoggies.Value = NumberFormatter:FormatNumber(round(data.Doggies), 2)
		playerStats.leaderRebirths.Value = tostring(data.Rebirths)

		-- Optionally, save these new values
		_G.save(player.UserId, playerStats)

	elseif statType == "Doggies" then
		playerStats.doggies.Value = playerStats.doggies.Value + data
		playerStats.leaderDoggies.Value = NumberFormatter:FormatNumber(round(playerStats.doggies.Value), 2)

	elseif statType == "Bones" then
		playerStats.bones.Value = playerStats.bones.Value + data
		playerStats.leaderBones.Value = NumberFormatter:FormatNumber(round(playerStats.bones.Value), 2)

	elseif statType == "Rebirths" then
		playerStats.rebirths.Value = playerStats.rebirths.Value + data
		playerStats.leaderRebirths.Value = tostring(playerStats.rebirths.Value)

	else
		warn("Unknown statType: " .. tostring(statType) .. " or stat not initialized for player: " .. player.Name)
	end

	-- Fire a client event to update the UI with the new values
	updateStatsEvent:FireClient(player, playerStats.doggies.Value, playerStats.bones.Value, playerStats.multiplier.Value, playerStats.rebirths.Value)
end)
