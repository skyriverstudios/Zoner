--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Types')

--===========================================================================================================================>
--==[ DEPENDENCIES ]==--


--=[ Local Requires ]=--

local DetectionCoverage = require('../Data/Enums/DetectionCoverage')
local DetectionMethod   = require('../Data/Enums/DetectionMethod')
local DetectionMode     = require('../Data/Enums/DetectionMode')
local Simulation        = require('../Data/Enums/Simulation')
local Execution         = require('../Data/Enums/Execution')
local Bounds            = require('../Data/Enums/Bounds')
local Rate              = require('../Data/Enums/Rate')

--===========================================================================================================================>

-- ZoneConfigTypes
export type ZoneConfigTable = {
	DetectionCoverage: DetectionCoverage.DetectionCoverageEnum;
	DetectionMethod:   DetectionMethod.DetectionMethodEnum;
	DetectionMode:     DetectionMode.DetectionModeEnum;
	Simulation:        Simulation.SimulationEnum;
	Execution:         Execution.ExecutionEnum;
	Bounds:            Bounds.BoundsEnum;
	Rate:              Rate.RateEnum;

	ManualStepping:              boolean;
	NoZonePartAddedListening:    boolean;
	NoZonePartPropertyListening: boolean;

	EnterDetectionMode: DetectionMode.DetectionModeEnum;
	ExitDetectionMode:  DetectionMode.DetectionModeEnum;

	EnterDetectionCoverage: DetectionCoverage.DetectionCoverageEnum;
	ExitDetectionCoverage:  DetectionCoverage.DetectionCoverageEnum;

}

export type ZoneConfig = {
	DetectionCoverage: DetectionCoverage.DetectionCoverageEnum?;
	DetectionMethod:   DetectionMethod.DetectionMethodEnum?;
	DetectionMode:     DetectionMode.DetectionModeEnum?;
	Simulation:        Simulation.SimulationEnum?;
	Execution:         Execution.ExecutionEnum?;
	Bounds:            Bounds.BoundsEnum?;
	Rate:              Rate.RateEnum?;

	EnterDetectionMode: DetectionMode.DetectionModeEnum?;
	ExitDetectionMode:  DetectionMode.DetectionModeEnum?;

	EnterDetectionCoverage: DetectionCoverage.DetectionCoverageEnum?;
	ExitDetectionCoverage:  DetectionCoverage.DetectionCoverageEnum?;

	NoZonePartAddedListening:    boolean?;
	NoZonePartPropertyListening: boolean?;
	ManualStepping:              boolean?;
}

--===========================================================================================================================>

-- Return an empty table:
return table.freeze({})

--===========================================================================================================================>