local Players = game:GetService("Players")

local function getPlayerClass(player)
	return _G.playerClasses and _G.playerClasses[player.UserId]
end

while true do
	task.wait(1)

	for _, player in ipairs(Players:GetPlayers()) do
		local pc = getPlayerClass(player)
		if pc and pc.doggies and pc.coinsPerSecond and pc.multiplier then
			local gain = pc.coinsPerSecond.Value * pc.multiplier.Value
			if gain ~= 0 then
				pc.doggies.Value += gain
			end
		end
	end
end
