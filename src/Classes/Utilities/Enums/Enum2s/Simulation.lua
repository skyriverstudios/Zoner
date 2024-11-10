--=======================================================================================================>
-- EnumName, EnumValue, AdditionalProperty
return {
	--======================================================================>

	-- PostSimulation: Executes after the physics simulation step.
	-- Useful for handling tasks that require finalized simulation
	-- results or changes after physics calculations.
	{"PostSimulation", 1},

	-- PreSimulation: Executes before the physics simulation step.
	-- Ideal for preparing or adjusting objects prior to simulation, 
	-- such as setting forces or updating physics-related states.
	{"PreSimulation", 2},

	-- PreRender: Executes before the rendering step. Used for preparing
	-- objects or settings that need to be finalized just before 
	-- being drawn on the screen.
	{"PreRender", 3},

	--======================================================================>
}
--=======================================================================================================>