--=======================================================================================================>
-- EnumName, EnumValue, AdditionalProperty
return {
	--======================================================================>

	-- Requires the target to be fully contained within the zone 
	-- for detection to occur. Best for scenarios where 
	-- total inclusion is necessary.
	{"Full",  1},

	-- Allows detection if the target is touching or partially 
	-- overlapping the zone boundary. Suitable for partial 
	-- entry detection.
	{"Touch", 2},

	-- Detects based on specific points within the target. This is
	-- the most efficient option, ideal for quick checks or when
	-- point-based accuracy is sufficient. (Position Vector3s)
	{"Point", 3},

	-- Automatically calculates a detection mode:
	{"Automatic", 4},
	
	--======================================================================>
}
--=======================================================================================================>