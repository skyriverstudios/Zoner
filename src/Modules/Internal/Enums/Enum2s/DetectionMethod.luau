--=======================================================================================================>

-- EnumName, EnumValue, AdditionalProperty
return {
	--======================================================================>

	-- Automatically selects the best detection method based on the zone's shape,
	-- bounds, and target complexity. Uses the most efficient method in simple
	-- cases (e.g., PointInPart), and more complex methods for irregular shapes.
	{"Automatic", 1},

	-- Prioritizes speed and efficiency. Uses fast methods like PointInPart,
	-- best for simple shapes and quick detection where high precision 
	-- isn't required.
	{"Efficient", 2},

	-- Balances between efficiency and accuracy. Methods like PartsInBox or
	-- PartsInSphere offer a middle-ground approach that handles moderately
	-- complex shapes with decent performance and accuracy.
	{"Simple", 3},

	-- Prioritizes accuracy over efficiency. Uses precise methods like 
	-- GetPartsInPart for complex shapes and targets where full containment 
	-- or exact detection is necessary, at the cost of performance.
	{"Complex", 4},

	--======================================================================>
}

--=======================================================================================================>