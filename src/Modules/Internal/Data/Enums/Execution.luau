--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Data')

--===========================================================================================================================>

-- Export the Type:
export type Execution = 'SERIAL'|'PARALLEL'

-- Export the Type:
export type ExecutionEnum = {Name: Execution, Value: number}

-- Table of Enums:
local ENUMS = {
	--===================================>

	-- Runs zone checks in a single sequence without using parallel threads.
	Serial   = table.freeze({Name = 'SERIAL'   :: 'SERIAL',   Value = 1} :: ExecutionEnum);

	-- Runs zone checks efficiently in separate threads.
	Parallel = table.freeze({Name = 'PARALLEL' :: 'PARALLEL', Value = 2} :: ExecutionEnum);

	--===================================>
};

-- Table of Network Hashes:
local HASH = {
	--===================================>
	Read  = table.freeze({
		[ENUMS.Serial.Value]   = ENUMS.Serial   :: ExecutionEnum;
		[ENUMS.Parallel.Value] = ENUMS.Parallel :: ExecutionEnum;
	});
	Write = table.freeze({
		[ENUMS.Serial   :: ExecutionEnum] = ENUMS.Serial.Value;
		[ENUMS.Parallel :: ExecutionEnum] = ENUMS.Parallel.Value;
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