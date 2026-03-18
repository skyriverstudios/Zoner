--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Data')

--===========================================================================================================================>

-- Export the Type:
export type DetectionMethod = 'AUTOMATIC'|'EFFICIENT'|'SIMPLE'|'COMPLEX'

-- Export the Type:
export type DetectionMethodEnum = {Name: DetectionMethod, Value: number}

-- Table of Enums:
local ENUMS = {
	--===================================>

	-- Automatically selects the best detection method based on shape,
	-- bounds, and target complexity.
	Automatic = table.freeze({Name = 'AUTOMATIC' :: 'AUTOMATIC', Value = 1} :: DetectionMethodEnum);

	-- Prioritizes speed and efficiency for simpler cases.
	Efficient = table.freeze({Name = 'EFFICIENT' :: 'EFFICIENT', Value = 2} :: DetectionMethodEnum);

	-- Balances between efficiency and accuracy.
	Simple    = table.freeze({Name = 'SIMPLE'    :: 'SIMPLE',    Value = 3} :: DetectionMethodEnum);

	-- Prioritizes accuracy over efficiency for complex shapes.
	Complex   = table.freeze({Name = 'COMPLEX'   :: 'COMPLEX',   Value = 4} :: DetectionMethodEnum);

	--===================================>
};

-- Table of Network Hashes:
local HASH = {
	--===================================>
	Read  = table.freeze({
		[ENUMS.Automatic.Value] = ENUMS.Automatic :: DetectionMethodEnum;
		[ENUMS.Efficient.Value] = ENUMS.Efficient :: DetectionMethodEnum;
		[ENUMS.Simple.Value]    = ENUMS.Simple    :: DetectionMethodEnum;
		[ENUMS.Complex.Value]   = ENUMS.Complex   :: DetectionMethodEnum;
	});
	Write = table.freeze({
		[ENUMS.Automatic :: DetectionMethodEnum] = ENUMS.Automatic.Value;
		[ENUMS.Efficient :: DetectionMethodEnum] = ENUMS.Efficient.Value;
		[ENUMS.Simple    :: DetectionMethodEnum] = ENUMS.Simple.Value;
		[ENUMS.Complex   :: DetectionMethodEnum] = ENUMS.Complex.Value;
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