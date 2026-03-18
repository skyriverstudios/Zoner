--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Data')

--===========================================================================================================================>

-- Export the Type:
export type Rate = 'SLOW'|'MODERATE'|'FAST'|'IMMEDIATE'

-- Export the Type:
export type RateEnum = {Name: Rate, Value: number, DelayBetweenChecks: number}

-- Table of Enums:
local ENUMS = {
	--===================================>

	-- Slow: Runs zone checks every 1.0 second.
	Slow      = table.freeze({Name = 'SLOW'      :: 'SLOW',      Value = 1, DelayBetweenChecks = 1.0} :: RateEnum);

	-- Moderate: Runs zone checks every 0.5 seconds.
	Moderate  = table.freeze({Name = 'MODERATE'  :: 'MODERATE',  Value = 2, DelayBetweenChecks = 0.5} :: RateEnum);

	-- Fast: Runs zone checks every 0.1 second.
	Fast      = table.freeze({Name = 'FAST'      :: 'FAST',      Value = 3, DelayBetweenChecks = 0.1} :: RateEnum);

	-- Immediate: Runs zone checks continuously with zero delay.
	Immediate = table.freeze({Name = 'IMMEDIATE' :: 'IMMEDIATE', Value = 4, DelayBetweenChecks = 0.0} :: RateEnum);

	--===================================>
};

-- Table of Network Hashes:
local HASH = {
	--===================================>
	Read  = table.freeze({
		[ENUMS.Slow.Value]      = ENUMS.Slow      :: RateEnum;
		[ENUMS.Moderate.Value]  = ENUMS.Moderate  :: RateEnum;
		[ENUMS.Fast.Value]      = ENUMS.Fast      :: RateEnum;
		[ENUMS.Immediate.Value] = ENUMS.Immediate :: RateEnum;
	});
	Write = table.freeze({
		[ENUMS.Slow      :: RateEnum] = ENUMS.Slow.Value;
		[ENUMS.Moderate  :: RateEnum] = ENUMS.Moderate.Value;
		[ENUMS.Fast      :: RateEnum] = ENUMS.Fast.Value;
		[ENUMS.Immediate :: RateEnum] = ENUMS.Immediate.Value;
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