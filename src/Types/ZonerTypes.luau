--=======================================================================================================>
--!strict
--=======================================================================================================>

-- Grab the ZonerModule Reference:
local ZonerModule = script.Parent.Parent

-- Require the Trove Module for Cleanup:
local EnumsModule      = require(ZonerModule.Classes.Utilities.Enums);
local TroveModule      = require(ZonerModule.Classes.Utilities.Trove);

--=======================================================================================================>

local GoodSignalTypes = require(ZonerModule.Classes.Utilities.GoodSignal.Types);
local PlaggerTypes    = require(ZonerModule.Classes.Core.Plagger.Types);
local ZoneTypes       = require(ZonerModule.Classes.Core.Zone.Types);

local SharedTypes  = require(script.Parent.SharedTypes);

--=======================================================================================================>

export type ZoneContainer = SharedTypes.ZoneContainer
export type ZoneSettings  = SharedTypes.ZoneSettings
export type ZonerFolder   = SharedTypes.ZonerFolder
export type ZonerHolder   = SharedTypes.ZonerHolder
export type ZonerActor    = SharedTypes.ZonerActor
export type ZonerGroup    = SharedTypes.ZonerGroup

--=======================================================================================================>

--Recreate the Zone Object Type with the Public Versions of the Types.
--We recreate it here because we want the AutoComplete to label the Type as "Zone" and not "Zone_Public"
export type Zone = typeof(
	setmetatable({} :: ZoneMetaData_Public, {} :: ZoneModule_Public)
)

-- Create and Export MetaData Type:
type ZoneMetaData_Public = { 
	--====================================================>
	Container:  SharedTypes.ZoneContainer;
	Identifier: string;
	Id: string;
	--====================================================>
	-- Whether the Zone has Connections:
	Active:         boolean;
	Destroyed:      boolean;
	Relocated:      boolean;
	Paused:         boolean;
	Visible:        boolean;
	
	ZoneParts: {BasePart};
	
	--====================================================>
	Detection:  number;
	Accuracy:   number;
	Simulation: number;
	Rate:       number;
	Execution:  number;
	
	EnterDetectionCoverage: number;
	ExitDetectionCoverage:  number;
	EnterDetectionMode:     number;
	ExitDetectionMode:      number;
	--====================================================>
	PlayerEntered: GoodSignalTypes.Signal;
	PlayerExited: GoodSignalTypes.Signal;

	PartEntered: GoodSignalTypes.Signal;
	PartExited: GoodSignalTypes.Signal;

	ItemEntered: GoodSignalTypes.Signal;
	ItemExited: GoodSignalTypes.Signal;
	--====================================================>
	LocalPlayerEntered: GoodSignalTypes.Signal;
	LocalPlayerExited: GoodSignalTypes.Signal;
	--====================================================>
}

-- Create and Export Module Type:
type ZoneModule_Public = {
	--====================================================>

	Destroy: 
		(self: Zone) -> ();

	SetDetection: 
		(self: Zone, DetectionCoverage: number | EnumsModule.DetectionCoverages, DetectionMode: number | EnumsModule.DetectionModes ) -> ();
	SetSimulation: 
		(self: Zone, Simulation: number | EnumsModule.Simulations) -> ();
	SetRate: 
		(self: Zone, Rate: number | EnumsModule.Rates) -> ();

	Step: 
		(self: Zone) -> ();

	Relocate: 
		(self: Zone) -> Zone;

	--====================================================>

	__index: ZoneModule_Public;

	--====================================================>
}

--=======================================================================================================>

export type ZoneCollector = {
	--====================================================>
	_Id: string;
	_Zones: {[string]: boolean};
	_Zoner: Zoner;
	--====================================================>
	Add:
		(self: ZoneCollector, Zone: Zone) -> ();
	Remove:
		(self: ZoneCollector, Zone: Zone, DestroyZone: boolean?) -> ();
	Clear:
		(self: ZoneCollector, DestroyZones: boolean?) -> ();
	Destroy:
		(self: ZoneCollector, Zone: Zone) -> ();
	--====================================================>
}

--=======================================================================================================>

-- Create and Export Type:
export type ZoneCoreActor = Actor & {
	Scripts: Folder & {['ZoneCore:Server']: Script; ['ZoneCore:Client']: Script; };
	Events:  Folder & {[string]: BindableEvent};
	Properties:  Configuration;
	States:  Configuration;
}

-- Create and Export Object Type:
export type Zoner = typeof(
	setmetatable({} :: ZonerMetaData, {} :: ZonerModule)
)

-- Create and Export MetaData Type:
export type ZonerMetaData = { 
	--====================================================>
	_Trove: TroveModule.Trove;
	_ZoneTrove: TroveModule.Trove;
	--====================================================>
	_RunScope: 'Client' | 'Server';
	_Initialized: boolean;
	--====================================================>
	_Zones: {[string]: ZoneTypes.Zone;};
	--====================================================>
	_ZoneModule: ZoneTypes.ZoneModule;
	_PlayerHandler: PlaggerTypes.Plagger;
	--====================================================>
	_SettingsFolder: typeof(script.Parent.Parent.Settings);
	--====================================================>
	_ZonerFolder: ZonerFolder;
	--====================================================>
	_ZonerHolders: {[ZonerHolder]: 
		{Holder: ZonerHolder; Type: 'G'|'A'; Capacity: NumberRange; IdsEvent: RBXScriptConnection}
	};
	_DefaultZoneSettings: ZoneSettings;
	--====================================================>
	_Enum: typeof(EnumsModule.Enums);
	--====================================================>
}

-- Create and Export Module Type:
export type ZonerModule = {
	--====================================================>

	_Start: 
		() -> Zoner;
	Destroy: 
		(self: Zoner) -> ();

	_Initialize: 
		(self: Zoner) -> ();
	_SetEvents: 
		(self: Zoner) -> ();
	_SetData: 
		(self: Zoner) -> ();

	_OnPostSimulation: 
		(self: Zoner, Type: 'Sync'|'Desync', DeltaTime: number) -> ();

	_RelocateZonerFolder: 
		(self: Zoner, Location: Instance?) -> ();

	_RemoveZonerHolder: 
		(self: Zoner, ZonerHolder: ZonerHolder) -> ();

	_GetZonerHolder: 
		(self: Zoner, Purpose: 'New'|'Open'|'Id', Type: 'G'|'A'|'?', ZoneId: string?) -> ZonerHolder?;

	_AddZone: 
		(self: Zoner, ZoneContainer: ZoneTypes.ZoneContainer, ZoneSettings: ZoneSettings) -> Zone;
	_RemoveZone: 
		(self: Zoner, Identifier: string) -> ();

	--====================================================>

	NewZone: 
		(self: Zoner, ZoneContainer: ZoneTypes.ZoneContainer, ZoneSettings: ZoneSettings?) -> Zone;
	NewZoneFromRegion: 
		(self: Zoner, RegionCFrame: CFrame, RegionSize: Vector3, ZoneSettings: ZoneSettings?) -> Zone;

	NewZoneCollector: 
		(self: Zoner) -> ZoneCollector;


	--====================================================>

	__index: ZonerModule;

	--====================================================>
}

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>