--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Default Prefix:
local Zoner = `\n[ ZONER LOG ]`

-- Default Title Prefix:
local Title = `\n[Title]:`
-- Default Error Prefix:
local Error = `\n[Error]:`
-- Default Description Prefix:
local Desc = `\n[Desc]: `

-- Return a Frozen Module Table:
return {
	--====================================================================================================>
	
	Logs = {
		--=========================================================================================>
		
		Zone = {
			--================================>

			Accuracy =
				`{Zoner} {Title} Zone: New {Error} Invalid Accuracy Enum {Desc} Accuracy Paramater must be a number or string from the Accuracy Enum`;

			Detection =
				`{Zoner} {Title} Zone: New {Error} Invalid Detection Enum {Desc} Detection Paramater must be a number or string from the Detection Enum`;

			ContainerType = 
				`{Zoner} {Title} Zone: New {Error} Invalid Container Type {Desc} Container Paramater must be a Table or Instance`;

			InstanceType  = 
				`{Zoner} {Title} Zone: New {Error} Invalid Container Instance Type {Desc} Container Instance Paramater must be a 'BasePart', 'Folder', 'Model', or 'Configuration'`;

			SetDetection =
				`{Zoner} {Title} Zone: SetDetection {Error} Invalid Detection Enum {Desc} Detection Paramater must be a number or string from the Detection Enum`;
			
			SetSimulation1 =
				`{Zoner} {Title} Zone: SetSimulation {Error} Invalid Simulation Enum {Desc} Simulation Paramater must be a number or string from the Simulation Enum`;
			SetSimulation2 =
				`{Zoner} {Title} Zone: SetSimulation {Error} Invalid Simulation Enum {Desc} "PreRender" cannot be used on the Server`;
		
			SetAccuracy =
				`{Zoner} {Title} Zone: SetAccuracy {Error} Invalid Accuracy Enum {Desc} Accuracy Paramater must be a number or string from the Accuracy Enum`;

			SetRate =
				`{Zoner} {Title} Zone: SetRate {Error} Invalid Rate Enum {Desc} Rate Paramater must be a number or string from the Accuracy Enum`;

			--================================>
		};

		TrackedItem = {
			--================================>

			Detection =
				`{Zoner} {Title} TrackedItem: New {Error} Invalid Detection Enum {Desc} Detection Paramater must be a number or string from the Detection Enum`;

			ItemType = 
				`{Zoner} {Title} TrackedItem: New {Error} Invalid Item Type {Desc} CItem Paramater must be an Instance`;

			InstanceType  = 
				`{Zoner} {Title} TrackedItem: New {Error} Invalid Item Instance Type {Desc} Item Instance Paramater must be a 'BasePart' or 'Model'`;

			SetDetection =
				`{Zoner} {Title} TrackedItem: SetDetection {Error} Invalid Detection Enum {Desc} Detection Paramater must be a number or string from the Detection Enum`;

			--================================>
		}
		
		--=========================================================================================>
	};
	
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
}

--===========================================================================================================================>