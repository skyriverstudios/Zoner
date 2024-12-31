--=======================================================================================================>
--!strict
--=======================================================================================================>

-- Grab the ZonerModule Reference:
local ZonerModule = script.Parent.Parent.Parent.Parent.Parent.Parent

local DetectionHandlerTypes = require(script.Parent.Classes.DetectionHandler);

-- Require the Trove Module for Cleanup:
local EnumsModule        = require(ZonerModule.Classes.Utilities.Enums);
local TroveModule        = require(ZonerModule.Classes.Utilities.Trove);

-- Import the Shared Types:
local SharedTypes = require(ZonerModule.Types.SharedTypes)

--=======================================================================================================>

-- Export Types:
export type ZoneContainer      = SharedTypes.ZoneContainer
export type ZoneTargets        = SharedTypes.ZoneTargets
export type ZoneSettings       = SharedTypes.ZoneSettings
export type ZonerFolder        = SharedTypes.ZonerFolder
export type ZoneFolder         = SharedTypes.ZoneFolder
export type ZonerActor         = SharedTypes.ZonerActor
export type ZoneBoxes          = SharedTypes.ZoneBoxes

--=======================================================================================================>

-- Create and Export Object Type:
export type ZoneEngine = typeof(
	setmetatable({} :: ZoneEngineMetaData, {} :: ZoneEngineModule)
)

-- Create and Export MetaData Type:
export type ZoneEngineMetaData = { 
	--====================================================>
	_Trove: TroveModule.Trove;
	--====================================================>
	_Identifier: string;
	_Container:  ZoneContainer;
	_ContainerType: SharedTypes.ZoneContainerType;
	_ZoneFolder: ZoneFolder;
	--====================================================>
	_RunScope: 'Client' | 'Server';
	--====================================================>
	_ZoneParts: {BasePart};
	--====================================================>
	_ActiveTargets: SharedTypes.ZoneActiveTargetsTable;
	_Settings:      SharedTypes.ZoneSettingsTable;
	_States:        SharedTypes.ZoneStatesTable;
	--====================================================>
	_DetectionHandler: DetectionHandlerTypes.DetectionHandler;
	--====================================================>
	_Connections: {
		Simulation: RBXScriptConnection;
	};

	_Client: {
		LocalPlayerName: string;
	};

	--====================================================>
	
	_Instances: {
		Holders:   {Instance};
		ZoneParts: {BasePart};
	};

	_Tags: {
		ZonePart: string;
		Holder:   string;
	};


	_Events: {
		--=========================================>
		ZoneSignals:   BindableEvent;
		HoldersUpdate: BindableEvent;
		--=========================================>
	};


	_Updates: {
		Region: boolean;
		Parts:  boolean;
	};

	_OverlapParamaters: {
		PartsIncludeList: OverlapParams;
		PartsExcludeList: OverlapParams;
	};

	_Counters: {
		ZoneStep: {Counter: number; CounterMax: number};
	};

	--====================================================>
	-- Meta Indexing:

	-- Whether the Zone has Connections:
	_Active: boolean;

	_Holders:   {Instance};
	_ZoneBoxes: ZoneBoxes;

	--====================================================>
}

-- Create and Export Module Type:
export type ZoneEngineModule = {
	--====================================================>

	New: 
		(Id: string, Folder: ZoneFolder, Container: ZoneContainer, RunScope: 'Server'|'Client') -> ZoneEngine;

	_Initialize: 
		(self: ZoneEngine) -> ();
	_SetEvents: 
		(self: ZoneEngine) -> ();
	_SetData: 
		(self: ZoneEngine) -> ();
	_SetValues: 
		(self: ZoneEngine) -> ();

	Destroy:
		(self: ZoneEngine) -> ();

	--====================================================>

	SetDetection: 
		(self: ZoneEngine, DetectionCoverage: number, DetectionMode: number, DetectionMethod: number?) -> ();
	SetSimulation: 
		(self: ZoneEngine, Simulation: number) -> ();
	SetRate: 
		(self: ZoneEngine, Rate: number) -> ();
	SetVisibility: 
		(self: ZoneEngine, State: boolean) -> ();

	--====================================================>

	DetectTarget: 
		(self: ZoneEngine, Target: ZoneTargets) -> ();

	--====================================================>

	OnZonePartUpdate: 
		(self: ZoneEngine, Purpose: 'Add'|'Remove', ZonePart: BasePart) -> ();
	OnHolderInstanceUpdate: 
		(self: ZoneEngine, Purpose: 'Add'|'Remove', Holder: Instance) -> ();

	OnPostSimulation: 
		(self: ZoneEngine, Type: 'Sync'|'Desync', DeltaTime: number) -> ();
	OnSimulation: 
		(self: ZoneEngine, Type: 'Sync'|'Desync', DeltaTime: number) -> ();

	Step: 
		(self: ZoneEngine, DeltaTime: number?) -> ();

	--====================================================>

	__index: ZoneEngineModule;

	--====================================================>
}

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>