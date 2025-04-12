--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Constants')

-- Return a Frozen Module Table:
return table.freeze({
	--====================================================================================================>
	
	Logs = table.freeze(require(script.Logs));
	
	TrackerData = {
		--=========================================================================================>
		
		-- We ignore these due to their insignificance (e.g. we ignore the lower and
		-- upper torso because the HumanoidRootPart also covers these areas)
		-- This ultimately reduces the burden on the player region checks
		CharacterIgnoreParts = {
			--================================>
			UpperTorso = true,
			LowerTorso = true,
			Torso = true,
			LeftHand = true,
			RightHand = true,
			LeftFoot = true,
			RightFoot = true,
			--================================>
		}
		
		--=========================================================================================>
	};
	
	--====================================================================================================>
})

--===========================================================================================================================>