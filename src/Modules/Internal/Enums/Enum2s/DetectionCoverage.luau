--=======================================================================================================>
-- EnumName, EnumValue, AdditionalProperty
return {
	--======================================================================>

	-- Detects only the center of the target. Ideal for quick checks or
	-- when the center point is the primary indicator of the target’s
	-- presence in the zone.
	{"Center", 1},

	-- Requires that all parts of the target are within the zone.
	-- Suitable for ensuring full containment of complex or 
	-- multi-part objects.
	{"AllParts", 2},

	-- Detects if any part of the target is inside the zone. Useful
	-- for quick detection when partial entry of the target 
	-- is sufficient.
	{"AnyPart", 3},

	-- Uses the target’s bounding box for detection. This provides a
	-- general area check, useful for larger objects or 
	-- for approximate detection.
	{"BoundingBox", 4},

	-- Automatically calculates a detection mode:
	{"Automatic", 5},
	
	--======================================================================>
}
--=======================================================================================================>