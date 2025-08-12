local GameData = {}

-- PlayerName = "TeamX",
GameData["TeamMappings"] = {}


--[[

ID Stars at 0 and grows for every new card
CardID = 
{
	Pos = CardVector3Pos,
	Orientation = CardVector3Ori,
	Lane = Lane#, 
	Team = Team1 or Team2 --SetBYMappings,
	CardData = 
	{
		Name = cardObj.Name, 
		Health = tonumber(cardObj:GetAttribute("Health")), 
		Defense = cardObj:GetAttribute("Defense"), 
		Reference = cardObj:Clone(), 
		Cooldown = cardObj:GetAttribute("Cooldown"),
		AttackAnim = cardObj:GetAttribute("AttackAnim"),
		Range = cardObj:GetAttribute("Range"),
		Speed = cardObj:GetAttribute("Speed"),
		Rarity = cardObj:GetAttribute("Rarity"),
		Attack = cardObj:GetAttribute("Attack"),
		OnCooldown = false		
	}
}


CardID = 
{
	Lane = Lane#, 
	Team = Team1 or Team2 --SetBYMappings,
}

]]--
GameData["Cards"] = {}


--Lane Data May Change
GameData["Lanes"] = {
	Team1 = {
		[1] =  Vector3.new(-6.617, 41.347, -20.701),
		[2] =  Vector3.new(-6.617, 41.347, 29.539),
		[3] =   Vector3.new(-1.287, 41.347, 86.139)
	},
	Team2 = {
		[1] = Vector3.new(162.683, 41.347, -20.701),
		[2] = Vector3.new(162.683, 41.347, 29.539),
		[3] =  Vector3.new(162.683, 41.347, 86.139)
	}
}

--DeckData

--PlayerName = {All Cards Imported},

GameData["Decks"] = {}


GameData["CardImgs"] = {
	
	["Imp"] = "rbxassetid://17590209140",
	["Skeleton"] = "rbxassetid://17164829001",
	["Water Spirit"] = "rbxassetid://17497338710",
	["Fire Spirit"] = "rbxassetid://17497419197",
	["Earth Spirit"] = "rbxassetid://17497854231",
	["Air Spirit"] = "rbxassetid://17497849531",
	["Demon Hound"] = "rbxassetid://18238131582",
	
}

GameData["XP"] = 0

GameData["CardXP"] = {
	
	["Imp"] = 2,
	["Skeleton"] = 1,
	["Water Spirit"] = 2,
	["Fire Spirit"] = 2,
	["Earth Spirit"] = 3,
	["Air Spirit"] = 1,
	["Demon Hound"] = 1,
}
	

return GameData
