--===========================================================================================================================>
--!native
--!optimize 2
--!strict
--===========================================================================================================================>
-- REMINDER:
-- FIRST INDEX OF 'TRACKED_PARTS' IS THE 'CENTER_PART' BASEPART OF TRACKER:

-- Define Module table:
-- Have Array Function Maps for Enum indexing:
local Modes = {IsPartInZone = {}}; 

--===========================================================================================================================>
--[ DEPENDENCIES: ]


-- [ Global Requires: ]

local Regions = require(`../../Regions`);

-- [ Local Requires: ]

local Bounds = require(`./Bounds`);

--===========================================================================================================================>
--[ CONSTANTS: ]


local BLOCK: 'Block', SPHERE: 'Sphere' = 'Block', 'Sphere'

--===========================================================================================================================>
--[ TYPES: ]


-- [ Define Types: ]

type ZonePieceDetailsMap = Bounds.ZonePieceDetailsMap

--===========================================================================================================================>
--[ FUNCTIONS: ]


@native
local function EvaluateCornersInZonePart(
	--======================>
	Part: BasePart,
	ZoneCFrame: CFrame, 
	ZoneHalfSize: Vector3?, 
	ZoneRadius: number?, 
	ZonePieceDetailsMap: ZonePieceDetailsMap?,
	RequireAllCornersInZone: boolean
	--======================>
): boolean
	--=======================================================================================================>
	-- Loop through each corner of the part and check if it is within the zone part
	for Index: number, Corner: Vector3 in ipairs(Regions:GetCornersFromPartDetails((Part.Size / 2), Part.CFrame, if ZoneHalfSize then BLOCK else SPHERE)) do
		--===============================================================================>
		-- Corner In ZonePart:
		local CornerInZonePart: boolean

		if ZoneRadius then
			CornerInZonePart = Regions:IsPointInSphere(Corner, ZoneCFrame, ZoneRadius)
		elseif ZoneHalfSize then
			CornerInZonePart = Regions:IsPointInBox(Corner, ZoneCFrame, ZoneHalfSize)
		end

		-- Logic for `Touch` mode: return true if any corner is inside
		if RequireAllCornersInZone == false and CornerInZonePart == true then return true end

		-- Logic for `Full` mode: return false if any corner is outside
		-- If the Corner is outside the ZonePart, we will then loop over all the other ZonePieceDetailsMap to make sure its not still inside the Zone,
		-- but just under a different ZonePart:
		if RequireAllCornersInZone == true and CornerInZonePart == false and ZonePieceDetailsMap then 
			--=====================================================================>
			-- Corner In ZonePart:
			local CornerInOtherZonePart: boolean

			-- Loop through each ZonePart first:
			for ZonePart, Details in ZonePieceDetailsMap do
				-- If the ZonePart CFrame is the same as the one passed to be Checked here, then its the same Part, and we dont wanna 
				-- check over it again since we already know what the value is going to be, so continue loop:
				if (Details.CFrame or Details.Piece.CFrame) == ZoneCFrame then continue end
				-- Check the Corner:
				if ZoneRadius then
					CornerInOtherZonePart = Regions:IsPointInSphere(Corner, Details.CFrame or Details.Piece.CFrame, Details.Radius or Regions:GetRadius(Details.Size))
				elseif ZoneHalfSize then
					CornerInOtherZonePart = Regions:IsPointInBox(Corner, Details.CFrame or Details.Piece.CFrame, Details.HalfSize)
				end
				-- If the Corner IS in ANOTHER ZonePart, break loop:
				if CornerInOtherZonePart == true then break end
			end

			-- If the Corner is ALSO not in another ZonePart in the ZonePieceDetailsMap Dictionary, then return false this Part does not have all its CORNERS:
			if CornerInOtherZonePart == false then return false end
			--=====================================================================>
		end

		--===============================================================================>
	end
	-- Return based on the mode
	return RequireAllCornersInZone
	--=======================================================================================================>
end

--===========================================================================================================================>

@native
local function Point_IsPartInZone(Part: BasePart, ZoneCFrame: CFrame, ZoneHalfSize: Vector3?, ZoneRadius: number?, ZonePieceDetailsMap: ZonePieceDetailsMap?): boolean
	--=======================================================================================================>
	if ZoneRadius then
		return Regions:IsPointInSphere(Part.Position, ZoneCFrame, ZoneRadius)
	elseif ZoneHalfSize then
		return Regions:IsPointInBox(Part.Position, ZoneCFrame, ZoneHalfSize)
	end
	-- Default return false if no conditions are met
	return false
	--=======================================================================================================>
end

@native
local function Touch_IsPartInZone(Part: BasePart, ZoneCFrame: CFrame, ZoneHalfSize: Vector3?, ZoneRadius: number?, ZonePieceDetailsMap: ZonePieceDetailsMap?): boolean
	return EvaluateCornersInZonePart(Part, ZoneCFrame, ZoneHalfSize or nil, ZoneRadius or nil, ZonePieceDetailsMap or nil, false)
end

@native
local function Full_IsPartInZone(Part: BasePart, ZoneCFrame: CFrame, ZoneHalfSize: Vector3?, ZoneRadius: number?, ZonePieceDetailsMap: ZonePieceDetailsMap?): boolean
	return EvaluateCornersInZonePart(Part, ZoneCFrame, ZoneHalfSize or nil, ZoneRadius or nil, ZonePieceDetailsMap or nil, true)
end

--===========================================================================================================================>

-- 1 = 'Full'
Modes.IsPartInZone[1] = Full_IsPartInZone
-- 2 = 'Touch'
Modes.IsPartInZone[2] = Touch_IsPartInZone
-- 3 = 'Point'
Modes.IsPartInZone[3] = Point_IsPartInZone


-- Freeze subtables:
table.freeze(Modes.IsPartInZone)

--===========================================================================================================================>

-- Return frozen table:
return table.freeze(Modes)

--===========================================================================================================================>