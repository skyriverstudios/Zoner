--=======================================================================================================>
-- in this case, AdditionalProperty is the delay between each check

-- EnumName, EnumValue, AdditionalProperty
return {
	--======================================================================>

	-- Slow: Runs zone checks every 1.0 second. Useful for low-priority or 
	-- resource-saving checks where frequent updates are not necessary.
	{"Slow", 1, 1.0},

	-- Moderate: Runs zone checks every 0.5 seconds. Provides a balance 
	-- between performance and responsiveness, suitable for moderate
	-- update needs.
	{"Moderate", 2, 0.5},

	-- Fast: Runs zone checks every 0.1 second. Ideal for more frequent
	-- updates, ensuring timely detection but with higher resource use.
	{"Fast", 3, 0.1},

	-- Immediate: Runs zone checks continuously with zero delay. 
	-- Provides the highest update frequency, suitable for real-time 
	-- detection needs at the expense of more processing power.
	{"Immediate", 4, 0.0},

	--======================================================================>
}

--=======================================================================================================>