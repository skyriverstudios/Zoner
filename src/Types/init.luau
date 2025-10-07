--=======================================================================================================>
--!strict
--=======================================================================================================>

-- Grab the ZonerModule Reference:
local ZonerModule = script.Parent

-- Require the Trove Module for Cleanup:
local EnumsModule      = require(ZonerModule.Modules.Internal.Enums);

--=======================================================================================================>


--[=[
	@type ZoneBox {CFrame: CFrame, Size: Vector3}
	@tag private_types
	@within Zoner

	A type of Zone "Part". Instanceless representation of a single Zone Box
]=]
export type ZoneBox = {CFrame: CFrame, Size: Vector3}

--[=[
	@type ZoneBoxs {ZoneBox}
	@tag private_types
	@within Zoner

	An array of ZoneBoxes. Useful to create multiple, instanceless Zone boxes as one container
]=]
export type ZoneBoxes = {ZoneBox}

export type ZoneContainer = (Model | Folder | BasePart | {BasePart} | {[string]: BasePart} | ZoneBoxes )
-- Create and Export Type:
export type ZoneContainerType = 'Part' | 'Holder' | 'Parts' | 'Boxes'

-- Create and Export Type:
export type ZoneParts = {BasePart}
-- Create and Export Type:
export type ZonePieces = ZoneBoxes | ZoneParts
-- Create and Export Type:
export type ZonePiece = BasePart | ZoneBox

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

-- For use in the ActiveSignals Table of the Object itself:
export type ZoneActiveSignalsTable = {
	['LocalPlayerEntered']: boolean;
	['LocalPlayerExited']:  boolean;
	['PlayerEntered']:      boolean;
	['PlayerExited']:       boolean;
	['PartEntered']:        boolean;
	['PartExited']:         boolean;
	['ItemEntered']:        boolean;
	['ItemExited']:         boolean;
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

export type ZoneGroupProperties = {Exclusive: boolean};

export type ZoneGroupData = { 
	Zones: {[string]: true}; Properties: ZoneGroupProperties 
}

export type ZoneGroups = {
	[string]: ZoneGroupData
};

-- Create and Export Type:
export type GroupsFolderGroup = Configuration & {Zones: Configuration}
-- Create and Export Type:
export type ZonerFolder = Folder & {
	Holders: Folder & {[string]: ZonerActor};
	Groups:  Folder & {[string]: GroupsFolderGroup};
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
	ActiveSignals: Configuration;
}

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>