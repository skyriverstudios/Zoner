--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Data')

--===========================================================================================================================>

-- Export the Type:
export type DetectionMode = 'FULL'|'TOUCH'|'POINT'|'AUTOMATIC'

-- Export the Type:
export type DetectionModeEnum = {Name: DetectionMode, Value: number}

-- Table of Enums:
local ENUMS = {
	--===================================>

	-- Requires the target to be fully contained within the zone.
	Full      = table.freeze({Name = 'FULL'      :: 'FULL',      Value = 1} :: DetectionModeEnum);

	-- Allows detection if the target is touching or partially overlapping.
	Touch     = table.freeze({Name = 'TOUCH'     :: 'TOUCH',     Value = 2} :: DetectionModeEnum);

	-- Detects based on specific points within the target.
	Point     = table.freeze({Name = 'POINT'     :: 'POINT',     Value = 3} :: DetectionModeEnum);

	-- Automatically calculates a detection mode.
	Automatic = table.freeze({Name = 'AUTOMATIC' :: 'AUTOMATIC', Value = 4} :: DetectionModeEnum);

	--===================================>
};

-- Table of Network Hashes:
local HASH = {
	--===================================>
	Read  = table.freeze({
		[ENUMS.Full.Value]      = ENUMS.Full      :: DetectionModeEnum;
		[ENUMS.Touch.Value]     = ENUMS.Touch     :: DetectionModeEnum;
		[ENUMS.Point.Value]     = ENUMS.Point     :: DetectionModeEnum;
		[ENUMS.Automatic.Value] = ENUMS.Automatic :: DetectionModeEnum;
	});
	Write = table.freeze({
		[ENUMS.Full      :: DetectionModeEnum] = ENUMS.Full.Value;
		[ENUMS.Touch     :: DetectionModeEnum] = ENUMS.Touch.Value;
		[ENUMS.Point     :: DetectionModeEnum] = ENUMS.Point.Value;
		[ENUMS.Automatic :: DetectionModeEnum] = ENUMS.Automatic.Value;
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