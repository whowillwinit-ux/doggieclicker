local NumberFormatter = {}

-- Funktion för att formatera ett nummer med K, M, B, etc.
function NumberFormatter:FormatNumber(number)
	local suffixes = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dd", "Ud", "Dd", "Td", "Qad", "Qid", 
		"Sxd", "Spd", "Ocd", "Nod", "Vg", "Uvg", "Dvg", "Tvg", "Qavg", "Qivg", "Sxvg"} -- Lägg till fler suffixer om nödvändigt
	local index = 1

	while number >= 1000 and index < #suffixes do
		number = number / 1000
		index = index + 1
	end

	-- Formatera numret till en sträng med 1 decimal om nödvändigt
	local formattedNumber = string.format("%.1f", number)

	-- Ta bort ".0" om numret är ett heltal (exempel: 2.0 -> 2)
	if formattedNumber:sub(-2) == ".0" then
		formattedNumber = formattedNumber:sub(1, -3)
	end

	return formattedNumber .. suffixes[index]
end

return NumberFormatter
