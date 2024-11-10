--=======================================================================================================>
-- EnumName, EnumValue, AdditionalProperty
return {
	--======================================================================>

	-- Automatically selects the most appropriate bounds for detection,
	-- based on the zone’s shape and target complexity.
	{"Automatic", 1},

	-- Detects each part of the zone individually. Useful for zones with
	-- complex or irregular shapes where precise detection per part 
	-- is necessary.
	{"PerPart", 2},

	-- Combines all parts of the zone into a single, exact bounding box
	-- without rotation. Provides efficient detection for simpler 
	-- shapes or non-complex zones.
	{"BoxExact", 3},

	-- Combines all parts of the zone into a bounding box aligned to 
	-- the voxel grid. Ideal for efficient detection where some 
	-- approximation is acceptable.
	{"BoxVoxel", 4},

	--======================================================================>
}
--=======================================================================================================>