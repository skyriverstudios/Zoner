--=======================================================================================================>
--!strict
--=======================================================================================================>

-- Grab the ZonerModule Reference:
local ZonerModule = script.Parent

-- Require the Trove Module for Cleanup:
local EnumsModule      = require(ZonerModule.Modules.Internal.Enums);

--=======================================================================================================>

-- Create and Export Type:
export type ZoneContainer = Model | Folder | BasePart | {BasePart} | {[any]: BasePart} | {{CFrame: CFrame, Size: Vector3}}
-- Create and Export Type:
export type ZoneContainerType = 'Part' | 'Holder' | 'Parts' | 'Boxes'

-- Create and Export Type:
export type ZoneBoxes = {{CFrame: CFrame, Size: Vector3}}
-- Create and Export Type:
export type ZoneParts = {BasePart}
-- Create and Export Type:
export type ZonePieces = ZoneBoxes | ZoneParts
-- Create and Export Type:
export type ZonePiece = BasePart | {CFrame: CFrame, Size: Vector3}

-- Create and Export Type:
export type ZoneTargets = 'Players'|'LocalPlayer'|'Parts'|'Items'

--=======================================================================================================>

-- For use in the States Table of the Object itself:
export type ZoneStatesTable = {
	Active:    boolean;
	Destroyed: boolean;
	Paused:    boolean;
	Relocated: boolean;
	Visible:   boolean;
};

-- For use in the ActiveTargets Table of the Object itself:
export type ZoneActiveTargetsTable = {
	['LocalPlayer']: boolean;
	['Player']:      boolean;
	['Item']:        boolean;
	['Part']:        boolean;
};

-- For use in the Config Table of the Object itself:
export type ZoneConfigTable = {
	--==================================>
	DetectionCoverage: number;
	DetectionMethod:   number;
	DetectionMode:     number;
	Simulation:        number;
	Execution:         number;
	Bounds:            number;
	Rate:              number;
	--==================================>
	ManualStepping:    boolean;
	NoZonePartAddedListening:    boolean;
	NoZonePartPropertyListening: boolean;
	--==================================>
	EnterDetectionMode: number?;
	ExitDetectionMode:  number?;
	
	EnterDetectionCoverage: number?;
	ExitDetectionCoverage:  number?;
	--==================================>
}

-- Create and Export Type:
export type ZoneConfig = {
	--==================================>
	DetectionCoverage: (number | EnumsModule.DetectionCoverages)?;
	DetectionMethod:   (number | EnumsModule.DetectionMethods)?;
	DetectionMode:     (number | EnumsModule.DetectionModes)?;
	Simulation:        (number | EnumsModule.Simulations)?;
	Execution:         (number | EnumsModule.Executions)?;
	Bounds:            (number | EnumsModule.Bounds)?;
	Rate:              (number | EnumsModule.Rates)?;
	
	EnterDetectionMode: (number | EnumsModule.DetectionModes)?;
	ExitDetectionMode:  (number | EnumsModule.DetectionModes)?;

	EnterDetectionCoverage: (number | EnumsModule.DetectionCoverages)?;
	ExitDetectionCoverage:  (number | EnumsModule.DetectionCoverages)?;
	
	NoZonePartAddedListening:    boolean?;
	NoZonePartPropertyListening: boolean?;
	--==================================>
	ManualStepping: boolean?
	--==================================>
}

-- Create and Export Type:
export type ZonerFolder = Folder & {
	Holders: Folder & {[string]: ZonerActor};
	WorldModel: WorldModel?
}

-- Create and Export Type:
export type ZonerGroup = Configuration & {
	Zones:   Folder & {[string]: ZoneFolder};
	Ids: Configuration;
}

-- Create and Export Type:
export type ZonerActor = Actor & {
	Zones:   Folder & {[string]: ZoneFolder};
	Scripts: Folder & {['ZoneCore.Server']: Script; ['ZoneCore.Client']: Script; };
	Ids: Configuration;
}
	
-- Create and Export Type:
export type ZonerHolder = ZonerActor | ZonerGroup

-- Create and Export Type:
export type ZoneFolder = Folder & {
	States:        Configuration;
	Config:        Configuration;
	ActiveTargets: Configuration;
}

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>