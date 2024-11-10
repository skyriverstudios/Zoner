--=======================================================================================================>
-- EnumName, EnumValue, AdditionalProperty
return {
	--======================================================================>

	-- Serial: Runs zone checks in a single sequence without using 
	-- parallel threads. Can be manually stepped through by the user 
	-- to control the internal logic directly. Suitable for simpler setups 
	-- where step-by-step control is desired.
	{"Serial", 2},

	-- Parallel: Runs zone checks efficiently in separate threads, 
	-- reducing the workload on the main thread. Ideal for setups with 
	-- multiple zones, as it allows concurrent processing to manage 
	-- complex zones with less performance impact.
	{"Parallel", 3},

	--======================================================================>
}
--=======================================================================================================>