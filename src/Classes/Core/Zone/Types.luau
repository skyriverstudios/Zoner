--=======================================================================================================>
--!strict
--=======================================================================================================>

-- Grab the ZonerModule Reference:
local ZonerModule = script.Parent.Parent.Parent.Parent

-- Require the Trove Module for Cleanup:
local GoodSignalTypes  = require(ZonerModule.Classes.Utilities.GoodSignal.Types);
local EnumsModule      = require(ZonerModule.Classes.Utilities.Enums);
local TroveModule      = require(ZonerModule.Classes.Utilities.Trove);

local SharedTypes = require(ZonerModule.Types.SharedTypes)
local ZoneEngineTypes = require(script.Parent.Classes.ZoneEngine.Types)

--=======================================================================================================>

-- Export Types:
export type ZoneContainer      = SharedTypes.ZoneContainer
export type ZoneSettings       = SharedTypes.ZoneSettings
export type ZonerFolder        = SharedTypes.ZonerFolder
export type ZonerHolder        = SharedTypes.ZonerHolder
export type ZoneFolder         = SharedTypes.ZoneFolder
export type ZonerActor         = SharedTypes.ZonerActor
export type ZonerGroup         = SharedTypes.ZonerGroup
export type ZoneBoxes          = SharedTypes.ZoneBoxes

--=======================================================================================================>

-- Create and Export Object Type:
export type Zone = typeof(
	setmetatable({} :: ZoneMetaData, {} :: ZoneModule)
)

-- Create and Export MetaData Type:
export type ZoneMetaData = { 
	--====================================================>
	_Trove: TroveModule.Trove;
	--====================================================>
	_EventTrove:  TroveModule.Trove;
	_PartTrove:   TroveModule.Trove;
	_HolderTrove: TroveModule.Trove;
	--====================================================>
	_RunScope: 'Client' | 'Server';
	--====================================================>
	_ActiveTargets: SharedTypes.ZoneActiveTargetsTable;
	_Settings:      SharedTypes.ZoneSettingsTable;
	_States:        SharedTypes.ZoneStatesTable;
	--====================================================>
	_ZonerHolder:  SharedTypes.ZonerHolder;
	_ZonerHolderType: 'A'|'G';
	_ContainerType: SharedTypes.ZoneContainerType;
	--====================================================>
	_Container:  SharedTypes.ZoneContainer;
	--====================================================>
	_Identifier: string;
	_Classes: {ZoneEngine: ZoneEngineTypes.ZoneEngine?};
	--====================================================>
	_Tags: {
		ZonePart: string;
		Holder:   string;
	};

	_Signals: {
		--=========================================>
		PlayerEntered: GoodSignalTypes.Signal;
		PlayerExited: GoodSignalTypes.Signal;

		PartEntered: GoodSignalTypes.Signal;
		PartExited: GoodSignalTypes.Signal;

		ItemEntered: GoodSignalTypes.Signal;
		ItemExited: GoodSignalTypes.Signal;

		LocalPlayerEntered: GoodSignalTypes.Signal;
		LocalPlayerExited: GoodSignalTypes.Signal;
		--=========================================>
	};

	_Instances: {
		RelocationContainer: SharedTypes.ZoneContainer;
		ZoneFolder:          SharedTypes.ZoneFolder;
		ZoneParts:           {BasePart};
		Holders:             {Instance};
	};

	_Counters: {
		ActivityCheck: {Counter: number; CounterMax: number};
	};

	_ConnectionStats: {
		PlayerConnections:      number;
		ItemConnections:        number;
		LocalPlayerConnections: number;
		PartConnections:        number;
	};

	--====================================================>
	_Holders:   {Instance};
	_ZoneParts: {BasePart};
	_ZoneFolder: ZoneFolder;
	--====================================================>
	-- Meta Indexing:

	_ZonerActor: ZonerActor;
	_ZonerGroup: ZonerGroup;
	_ZoneBoxes: ZoneBoxes;

	--====================================================>
	-- Zone Public Indexes:
	--====================================================>
	Container:  ZoneContainer;
	Identifier: string;
	Id: string;
	--====================================================>
	-- Whether the Zone has Connections:
	Active:         boolean;
	Destroyed:      boolean;
	Relocated:      boolean;
	Paused: boolean;
	--====================================================>
	Detection:  number;
	Accuracy:   number;
	Simulation: number;
	Execution:      number;
	EnterDetection: number;
	ExitDetection:  number;
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
export type ZoneModule = {
	--====================================================>

	New: 
		(
			Container: SharedTypes.ZoneContainer,
			Settings:  SharedTypes.ZoneSettings,
			Holder:    ZonerHolder,
			RunScope:  'Server'|'Client',
			Id:        string
		) -> Zone;

	Destroy: 
		(self: Zone) -> ();

	_Initialize: 
		(self: Zone) -> ();
	_SetData: 
		(self: Zone) -> ();
	_SetInstances: 
		(self: Zone) -> ();
	_SetEvents: 
		(self: Zone) -> ();
	_SetCore: 
		(self: Zone) -> ();

	_CheckActivity: 
		(self: Zone) -> ();

	--====================================================>
	SetDetection: 
		(self: Zone, DetectionCoverage: number | EnumsModule.DetectionCoverages, DetectionMode: number | EnumsModule.DetectionModes ) -> ();
	SetSimulation: 
		(self: Zone, Simulation: number | EnumsModule.Simulations) -> ();
	SetRate: 
		(self: Zone, Rate: number | EnumsModule.Rates) -> ();

	LogSettings: 
		(self: Zone) -> ();



	_SetSetting: 
		(self: Zone, SettingName: any, EnumName: string, NameOrId: number | string) -> ();
	_SetState: 
		(self: Zone, StateName: string, State: boolean) -> ();

	Relocate: 
		(self: Zone) -> Zone;

	--====================================================>

	_OnZonePartUpdate: 
		(self: Zone, Purpose: 'Add'|'Remove', ZonePart: BasePart) -> ();
	_OnHolderInstanceUpdate: 
		(self: Zone, Purpose: 'Add'|'Remove', Holder: Instance) -> ();
	
	_OnPostSimulation: 
		(self: Zone, Type: 'Sync'|'Desync', DeltaTime: number) -> ();

	--====================================================>

	__index: ZoneModule;

	--====================================================>
}

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>