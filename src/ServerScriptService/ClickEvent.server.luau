local ReplicatedStorage = game:GetService("ReplicatedStorage")
local clickEvent = ReplicatedStorage:WaitForChild("ClickEvent")

clickEvent.OnServerEvent:Connect(function(player)
	local pc = _G.playerClasses and _G.playerClasses[player.UserId]
	if not pc then return end

	local gain = pc.coinsPerClick.Value * pc.multiplier.Value
	pc.doggies.Value += gain

	if _G.SavePlayer then
		_G.SavePlayer(player.UserId, pc)
	end
end)
