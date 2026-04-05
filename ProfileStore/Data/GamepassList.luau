local GamepassList = {}

-- A table mapping gamepass names to their corresponding IDs
GamepassList.Names = {
	SealsX2 = "1688599023",
	WinsX2 = "1688501120",
}
-- Function to get the gamepass ID by its name
GamepassList.GetGamepassIDByName = function(name: string)
	return GamepassList.Names[name]
end

--Award Functions
GamepassList.Functions = {

	-- SealsX2
	["1688599023"] = function(player: Player)
		print("Awarding SealsX2 to", player.Name)
	end,
	-- WinsX2
	["1688501120"] = function(player: Player)
		print("Awarding WinsX2 to", player.Name)
	end,
}

return GamepassList
