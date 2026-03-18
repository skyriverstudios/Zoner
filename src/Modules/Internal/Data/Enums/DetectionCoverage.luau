--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Data')

--===========================================================================================================================>

-- Export the Type:
export type DetectionCoverage = 'CENTER'|'ALL_PARTS'|'ANY_PART'|'AUTOMATIC'

-- Export the Type:
export type DetectionCoverageEnum = {Name: DetectionCoverage, Value: number}

-- Table of Enums:
local ENUMS = {
	--===================================>

	-- Detects only the center of the target. Ideal for quick checks.
	Center    = table.freeze({Name = 'CENTER'    :: 'CENTER',    Value = 1} :: DetectionCoverageEnum);

	-- Requires that all parts of the target are within the zone.
	AllParts  = table.freeze({Name = 'ALL_PARTS' :: 'ALL_PARTS', Value = 2} :: DetectionCoverageEnum);

	-- Detects if any part of the target is inside the zone.
	AnyPart   = table.freeze({Name = 'ANY_PART'  :: 'ANY_PART',  Value = 3} :: DetectionCoverageEnum);

	-- Automatically calculates a detection coverage mode.
	Automatic = table.freeze({Name = 'AUTOMATIC' :: 'AUTOMATIC', Value = 4} :: DetectionCoverageEnum);

	--===================================>
};

-- Table of Network Hashes:
local HASH = {
	--===================================>
	Read  = table.freeze({
		[ENUMS.Center.Value]    = ENUMS.Center    :: DetectionCoverageEnum;
		[ENUMS.AllParts.Value]  = ENUMS.AllParts  :: DetectionCoverageEnum;
		[ENUMS.AnyPart.Value]   = ENUMS.AnyPart   :: DetectionCoverageEnum;
		[ENUMS.Automatic.Value] = ENUMS.Automatic :: DetectionCoverageEnum;
	});
	Write = table.freeze({
		[ENUMS.Center    :: DetectionCoverageEnum] = ENUMS.Center.Value;
		[ENUMS.AllParts  :: DetectionCoverageEnum] = ENUMS.AllParts.Value;
		[ENUMS.AnyPart   :: DetectionCoverageEnum] = ENUMS.AnyPart.Value;
		[ENUMS.Automatic :: DetectionCoverageEnum] = ENUMS.Automatic.Value;
	});
	--===================================>
}

--==========================================================================================================================>

-- Return the Frozen Table:
return table.freeze({
	ENUMS = table.freeze(ENUMS);
	HASH  = table.freeze(HASH);
})

--==========================================================================================================================>