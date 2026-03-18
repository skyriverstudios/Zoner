--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Data')

--===========================================================================================================================>

-- Export the Type:
export type Simulation = 'PostSimulation'|'PreSimulation'|'PreRender'

-- Export the Type:
export type SimulationEnum = {Name: Simulation, Value: number}

-- Table of Enums:
local ENUMS = {
	--===================================>

	-- Executes after the physics simulation step.
	PostSimulation = table.freeze({Name = 'PostSimulation' :: 'PostSimulation', Value = 1} :: SimulationEnum);

	-- Executes before the physics simulation step.
	PreSimulation  = table.freeze({Name = 'PreSimulation'  :: 'PreSimulation',  Value = 2} :: SimulationEnum);

	-- Executes before the rendering step.
	PreRender      = table.freeze({Name = 'PreRender'      :: 'PreRender',      Value = 3} :: SimulationEnum);

	--===================================>
};

-- Table of Network Hashes:
local HASH = {
	--===================================>
	Read  = table.freeze({
		[ENUMS.PostSimulation.Value] = ENUMS.PostSimulation :: SimulationEnum;
		[ENUMS.PreSimulation.Value]  = ENUMS.PreSimulation  :: SimulationEnum;
		[ENUMS.PreRender.Value]      = ENUMS.PreRender      :: SimulationEnum;
	});
	Write = table.freeze({
		[ENUMS.PostSimulation :: SimulationEnum] = ENUMS.PostSimulation.Value;
		[ENUMS.PreSimulation  :: SimulationEnum] = ENUMS.PreSimulation.Value;
		[ENUMS.PreRender      :: SimulationEnum] = ENUMS.PreRender.Value;
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