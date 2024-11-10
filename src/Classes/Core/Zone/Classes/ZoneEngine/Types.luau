--=======================================================================================================>
--!strict
--=======================================================================================================>

-- Grab the ZonerModule Reference:
local ZonerModule = script.Parent.Parent.Parent.Parent.Parent.Parent

local TargetHandlerTypes = require(script.Parent.Classes.TargetHandler.Types);
local BoundsHandlerTypes = require(script.Parent.Classes.BoundsHandler.Types);

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
	_PartTrove:    TroveModule.Trove;
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

	_Connections: {
		Simulation: RBXScriptConnection;
	};

	_Client: {
		LocalPlayerName: string;
	};

	--====================================================>
	
	_BoundsHandler: BoundsHandlerTypes.DefaultHandler;
	
	_BoundsHandlers: {
		PerPart:  BoundsHandlerTypes.PerPartBoundsHandler?;
		BoxExact: BoundsHandlerTypes.BoxExactBoundsHandler?;
		BoxVoxel: BoundsHandlerTypes.BoxVoxelBoundsHandler?;
	};
	
	_TargetHandlers: {
		LocalPlayer: TargetHandlerTypes.LocalPlayerTargetHandler?;
		Players:     TargetHandlerTypes.PlayersTargetHandler?;
		Items:       TargetHandlerTypes.TargetHandlers?;
		Parts:       TargetHandlerTypes.PartsTargetHandler?;
	};

	_Instances: {
		Holders:   {Instance};
		ZoneParts: {BasePart};
	};

	_Tags: {
		ZonePart: string;
		Holder:   string;
	};


	_Properties: {
		--=========================================>
		AllZonePartsAreBlocks: boolean;
		--=========================================>
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

	Initialize: 
		(self: ZoneEngine) -> ();
	SetEvents: 
		(self: ZoneEngine) -> ();
	SetData: 
		(self: ZoneEngine) -> ();
	SetUpdates: 
		(self: ZoneEngine) -> ();

	Destroy:
		(self: ZoneEngine) -> ();

	--====================================================>

	UpdateDetection: 
		(self: ZoneEngine, DetectionCoverage: number, DetectionMode: number, DetectionMethod: number?) -> ();
	UpdateSimulation: 
		(self: ZoneEngine, Simulation: number) -> ();
	UpdateRate: 
		(self: ZoneEngine, Rate: number) -> ();

	--====================================================>

	UpdateTargetHandler: 
		(self: ZoneEngine, Target: TargetHandlerTypes.TargetTypes, State: boolean) -> ();
	
	ToggleVisibility: 
		(self: ZoneEngine, State: boolean) -> ();
	
	--====================================================>

	DetectTarget: 
		(self: ZoneEngine, Target: ZoneTargets) -> ();
	CheckZone: 
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