--===========================================================================================================================>
--!native
--!optimize 2
--!strict
--===========================================================================================================================>
-- REMINDER:
-- FIRST INDEX OF 'TRACKED_PARTS' IS THE 'CENTER_PART' BASEPART OF TRACKER:

-- Define Module table:
-- Have Array Function Maps for Enum indexing:
local Coverages = {InZoneParts = {}; InBox = {}}; 

--===========================================================================================================================>
--[ DEPENDENCIES: ]


-- [ Global Requires: ]

local Regions = require(`../../Regions`);
local Enums   = require(`../../../Enums`);

-- [ Local Requires: ]

local Bounds = require(`./Bounds`);
local Modes  = require(`./Modes`);

--===========================================================================================================================>
--[ CONSTANTS: ]


local BLOCK: 'Block', SPHERE: 'Sphere' = 'Block', 'Sphere'

--===========================================================================================================================>

-- The first BasePart in 'TrackedParts' will always be the "CenterPart", we index that with 1:
local function Center_QuickHit(TrackedParts: {BasePart}, DetectionMode: number, HitTargetParts: {BasePart}?): boolean
	--=======================================================================================================>
	-- If no parts or empty array, return false
	if not HitTargetParts or #HitTargetParts < 1 then return false end

	if table.find(HitTargetParts, TrackedParts[1]) == nil then return false end
	
	if DetectionMode == Enums.DetectionMode.Touch or DetectionMode == Enums.DetectionMode.Point then
		return true
	end
	
	return false
	--=======================================================================================================>
end

local function AllParts_QuickHit(TrackedParts: {BasePart}, DetectionMode: number, HitTargetParts: {BasePart}?): boolean
	--=======================================================================================================>
	-- If no parts or empty array, return false
	if not HitTargetParts or #HitTargetParts < 1 then return false end

	if DetectionMode == Enums.DetectionMode.Touch or DetectionMode == Enums.DetectionMode.Point then
		if #TrackedParts == #HitTargetParts then return true end
	end
	
	return false
	--=======================================================================================================>
end

local function AnyPart_QuickHit(TrackedParts: {BasePart}, DetectionMode: number, HitTargetParts: {BasePart}?): boolean
	--=======================================================================================================>
	-- If no parts or empty array, return false
	if not HitTargetParts or #HitTargetParts < 1 then return false end

	if DetectionMode == Enums.DetectionMode.Touch or DetectionMode == Enums.DetectionMode.Point then
		return true
	end
	
	return false
	--=======================================================================================================>
end

--===========================================================================================================================>

-- The first BasePart in 'TrackedParts' will always be the "CenterPart", we index that with 1:
local function Center_InZoneParts(
	TrackedParts: {BasePart}, DetectionMode: number, ZonePieceDetailsMap: Bounds.ZonePieceDetailsMap, HitTargetParts: {BasePart}?
): boolean
	--=======================================================================================================>
	
	-- Check the Quick Hit function:
	local QuickHit = Center_QuickHit(TrackedParts, DetectionMode, HitTargetParts)
	-- If it returned true then return the Result:
	if QuickHit then return QuickHit end
	
	-- 9/13; Added quick check to make sure 'CorePart' at index 1 is not nil:
	if TrackedParts[1] == nil :: any then return false end

	--=======================================================================================================>
	
	-- Pre index the function:
	local IsPartInZone = Modes.IsPartInZone[DetectionMode]
	-- Loop through each ZonePart first:
	for ZonePart, Details in ZonePieceDetailsMap do
		--===========================================================================================>		
		-- Call Method to Check whether the Part is in the ZonePart, taking into account DetectionMode:
		local InAZonePart: boolean = IsPartInZone(
			TrackedParts[1],
			Details.CFrame or Details.Piece.CFrame,
			Details.Type == BLOCK and Details.HalfSize or nil,
			if Details.Type == SPHERE then Details.Radius or Regions:GetRadius(Details.Size) else nil,
			ZonePieceDetailsMap
		)
		-- If the Item Part is in this ZonePart, set InZone to true, break the loop, and stop checking:
		if InAZonePart then return true end
		--===========================================================================================>
	end
	-- Return the InZone Boolean:
	return false
	--=======================================================================================================>
end

local function AllParts_InZoneParts(
	TrackedParts: {BasePart}, DetectionMode: number, ZonePieceDetailsMap: Bounds.ZonePieceDetailsMap, HitTargetParts: {BasePart}?
): boolean
	--=======================================================================================================>

	-- Check the Quick Hit function:
	local QuickHit = AllParts_QuickHit(TrackedParts, DetectionMode, HitTargetParts)
	-- If it returned true then return the Result:
	if QuickHit then return QuickHit end

	--=======================================================================================================>

	-- Pre index the function:
	local IsPartInZone = Modes.IsPartInZone[DetectionMode]
	-- Loop through all the Parts in Tracked Target Item:
	for Index: number, Part: BasePart in ipairs(TrackedParts) do
		--===========================================================================================>
		-- Boolean on whether the Item Part is in ANY ZonePart in the ZonePieceDetailsMap Dictionary:
		local InAZonePart: boolean = false
		-- Loop through the ZonePart's Dictionary checking if the Item Part is any of them:
		for ZonePart, Details in ZonePieceDetailsMap do
			--======================================================================>
			-- Call Method to Check whether the Part is in the ZonePart, taking into account DetectionMode:
			InAZonePart = IsPartInZone(
				Part,
				Details.CFrame or Details.Piece.CFrame,
				if Details.Type == BLOCK  then Details.HalfSize else nil,
				if Details.Type == SPHERE then Details.Radius or Regions:GetRadius(Details.Size) else nil,
				ZonePieceDetailsMap
			)
			-- If the Item Part is in this ZonePart, break the loop, stop checking:
			if InAZonePart then break end
			--======================================================================>
		end
		-- If the Item Part Checked was not in any of the ZonePieceDetailsMap, then it is outside the Zone, so we break and stop the loop.
		-- Remember, this is the AllParts DetectionCoverage, which means we need every Item Part inside a ZonePart for the Zone:
		if InAZonePart == false then return false end
		--===========================================================================================>
	end
	-- Return the InZone Boolean:
	return true
	--=======================================================================================================>
end

local function AnyPart_InZoneParts(
	TrackedParts: {BasePart}, DetectionMode: number, ZonePieceDetailsMap: Bounds.ZonePieceDetailsMap, HitTargetParts: {BasePart}?
): boolean
	--=======================================================================================================>

	-- Check the Quick Hit function:
	local QuickHit = AnyPart_QuickHit(TrackedParts, DetectionMode, HitTargetParts)
	-- If it returned true then return the Result:
	if QuickHit then return QuickHit end

	--=======================================================================================================>

	-- Pre index the function:
	local IsPartInZone = Modes.IsPartInZone[DetectionMode]
	-- Loop through each ZonePart first:
	for ZonePart, Details in ZonePieceDetailsMap do
		--===========================================================================================>
		-- Loop through all the Parts in Tracked Target Item:
		for Index: number, Part: BasePart in ipairs(HitTargetParts or TrackedParts) do
			--======================================================================>
			-- Call Method to Check whether the Part is in the ZonePart, taking into account DetectionMode:
			local InAZonePart: boolean = IsPartInZone(
				Part,
				Details.CFrame or Details.Piece.CFrame,
				if Details.Type == BLOCK then Details.HalfSize else nil,
				if Details.Type == SPHERE then Details.Radius or Regions:GetRadius(Details.Size) else nil,
				ZonePieceDetailsMap
			)
			-- If the Item Part is in this ZonePart, set InZone to true, break the loop, and stop checking:
			if InAZonePart then return true end
			--======================================================================>
		end
		--===========================================================================================>
	end
	-- Return the InZone Boolean:
	return false
	--=======================================================================================================>
end

--===========================================================================================================================>

local function Center_InBox(TrackedParts: {BasePart}, DetectionMode: number, ZoneCFrame: CFrame, ZoneHalfSize: Vector3, HitTargetParts: {BasePart}?): boolean
	--=======================================================================================================>

	-- Check the Quick Hit function:
	local QuickHit = Center_QuickHit(TrackedParts, DetectionMode, HitTargetParts)
	-- If it returned true then return the Result:
	if QuickHit then return QuickHit end
	
	-- 9/13; Added quick check to make sure 'CorePart' at index 1 is not nil:
	if TrackedParts[1] == nil :: any then return false end
	
	--=======================================================================================================>
	-- Create a InZone boolean to return. This is whether any part of the tracked target is inside any ZonePart:
	local InZone: boolean = Modes.IsPartInZone[DetectionMode](
		TrackedParts[1],
		ZoneCFrame,
		ZoneHalfSize
	) 
	-- Return the InZone Boolean:
	return InZone
	--=======================================================================================================>
end

local function AllParts_InBox(TrackedParts: {BasePart}, DetectionMode: number, ZoneCFrame: CFrame, ZoneHalfSize: Vector3, HitTargetParts: {BasePart}?): boolean
	--=======================================================================================================>

	-- Check the Quick Hit function:
	local QuickHit = AllParts_QuickHit(TrackedParts, DetectionMode, HitTargetParts)
	-- If it returned true then return the Result:
	if QuickHit then return QuickHit end

	--=======================================================================================================>

	-- Pre index the function:
	local IsPartInZone = Modes.IsPartInZone[DetectionMode]
	-- Loop through all the Parts in Tracked Target Item:
	for Index: number, Part: BasePart in ipairs(TrackedParts) do
		--===========================================================================================>
		-- Boolean on whether the Item Part is in ANY ZonePart in the ZonePieceDetailsMap Dictionary:
		-- Call Method to Check whether the Part is in the ZonePart, taking into account DetectionMode:
		local InAZonePart: boolean = IsPartInZone(
			Part,
			ZoneCFrame,
			ZoneHalfSize
		)
		-- If the Item Part Checked was not in any of the ZonePieceDetailsMap, then it is outside the Zone, so we break and stop the loop.
		-- Remember, this is the AllParts DetectionCoverage, which means we need every Item Part inside a ZonePart for the Zone:
		if InAZonePart == false then return false end
		--===========================================================================================>
	end
	-- Return the InZone Boolean:
	return true
	--=======================================================================================================>
end

local function AnyPart_InBox(TrackedParts: {BasePart}, DetectionMode: number, ZoneCFrame: CFrame, ZoneHalfSize: Vector3, HitTargetParts: {BasePart}?): boolean
	--=======================================================================================================>

	-- Check the Quick Hit function:
	local QuickHit = AnyPart_QuickHit(TrackedParts, DetectionMode, HitTargetParts)
	-- If it returned true then return the Result:
	if QuickHit then return QuickHit end

	--=======================================================================================================>

	-- Pre index the function:
	local IsPartInZone = Modes.IsPartInZone[DetectionMode]
	-- Loop through all the Parts in Tracked Target Item:
	for Index: number, Part: BasePart in ipairs(HitTargetParts or TrackedParts) do
		--======================================================================>
		-- Call Method to Check whether the Part is in the ZonePart, taking into account DetectionMode:
		local InAZonePart: boolean = IsPartInZone(
			Part,
			ZoneCFrame,
			ZoneHalfSize
		)
		-- If the Item Part is in this ZonePart, set InZone to true, break the loop, and stop checking:
		if InAZonePart == true then return true end
		--======================================================================>
	end
	-- Return the InZone Boolean:
	return false
	--=======================================================================================================>
end

--===========================================================================================================================>

-- 1 = 'Center'
Coverages.InZoneParts[1] = Center_InZoneParts
-- 2 = 'AllParts'
Coverages.InZoneParts[2] = AllParts_InZoneParts
-- 3 = 'AnyPart'
Coverages.InZoneParts[3] = AnyPart_InZoneParts


-- 1 = 'Center'
Coverages.InBox[1] = Center_InBox
-- 2 = 'AllParts'
Coverages.InBox[2] = AllParts_InBox
-- 3 = 'AnyPart'
Coverages.InBox[3] = AnyPart_InBox

-- Freeze subtables:
table.freeze(Coverages.InZoneParts)
table.freeze(Coverages.InBox)

--===========================================================================================================================>

export type InZoneParts = typeof(Center_InZoneParts)
export type InBox       = typeof(Center_InBox)

--===========================================================================================================================>

-- Return frozen table:
return table.freeze(Coverages)

--===========================================================================================================================>