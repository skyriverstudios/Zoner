--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Data')

--===========================================================================================================================>

local DetectionCoverage = require('./DetectionCoverage');
local DetectionMethod   = require('./DetectionMethod');
local DetectionMode     = require('./DetectionMode');
local Simulation        = require('./Simulation');
local Execution         = require('./Execution');
local Bounds            = require('./Bounds');
local Rate              = require('./Rate');

--==========================================================================================================================>

export type DetectionCoverageEnum = DetectionCoverage.DetectionCoverageEnum
export type DetectionMethodEnum   = DetectionMethod.DetectionMethodEnum
export type DetectionModeEnum     = DetectionMode.DetectionModeEnum
export type SimulationEnum        = Simulation.SimulationEnum
export type ExecutionEnum         = Execution.ExecutionEnum
export type RateEnum              = Rate.RateEnum

--==========================================================================================================================>

-- Return the Frozen Table:
return table.freeze({
	DetectionCoverage = DetectionCoverage;
	DetectionMethod   = DetectionMethod;
	DetectionMode     = DetectionMode;
	Simulation        = Simulation;
	Execution         = Execution;
	Bounds            = Bounds;
	Rate              = Rate;
})

--==========================================================================================================================>