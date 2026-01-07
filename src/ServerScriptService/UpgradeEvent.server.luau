local UpgradeManager = require(game.ReplicatedStorage:WaitForChild("UpgradeManager"))
local upgradeEvent = Instance.new("RemoteEvent")
upgradeEvent.Name = "UpgradeEvent"
upgradeEvent.Parent = game.ReplicatedStorage

-- Listen for upgrade requests from clients
upgradeEvent.OnServerEvent:Connect(function(player, upgradeButton)
	local playerClass = _G.playerClasses[player.UserId]
	if playerClass then
		UpgradeManager.upgradeCoinsPerClick(player, upgradeButton)
	else
		warn("PlayerClass not found for player: " .. player.Name)
	end
end)