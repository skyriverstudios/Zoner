--=======================================================================================================>
--!strict
--=======================================================================================================>

-- Grab the ZonerModule Reference:
local ZonerModule = script.Parent.Parent

-- Require the Trove Module for Cleanup:
local GoodSignalModule = require(ZonerModule.Utility.GoodSignal);
local EnumsModule      = require(ZonerModule.Utility.Enums);
local TroveModule      = require(ZonerModule.Utility.Trove);

local PlaggerTypes = require(ZonerModule.Classes.Plagger.Types);
local ItemTrackerTypes = require(ZonerModule.Classes.ItemTracker.Types);

local DetectorModule      = require(ZonerModule.Classes.Detector);

local WorldModelTypes    = require(script.Parent.WorldModelTypes);

--=======================================================================================================>

-- Create and Export Type:
export type ZoneContainer = Model | Folder | BasePart | {}

-- Create and Export Type:
export type ZonerFolder = Folder & {
	Ids: Configuration; 
	Zones: Folder & {[string]: ZoneCoreActor};
	WorldModel: WorldModel?
}

-- Create and Export Type:
export type ZoneCoreActor = Actor & {
	Scripts: Folder & {['ZoneCore:Server']: Script; ['ZoneCore:Client']: Script; };
	Events:  Folder & {[string]: BindableEvent};
	Properties:  Configuration;
	States:  Configuration;
	Settings: Configuration;
	ActiveTriggers: Configuration;
}

-- Create and Export Type:
export type ZonePartProperties = {
	--===============================>

	Type: 'Complex' | 'Block' | 'Sphere';
	
	Bounds: {Min: Vector3; Max: Vector3}?;

	Corners: {Vector3}?;
	
	Size:   Vector3;
	CFrame: CFrame;

	Region_Size:   Vector3;
	Region_CFrame: CFrame;
	--===============================>
}

-- Create and Export Type:
export type ZoneParts = {[BasePart]: ZonePartProperties}

-- Create and Export Type:
export type ZoneTriggers = 'Players'|'LocalPlayer'|'Parts'|'Items'

--=======================================================================================================>


-- Create and Export Object Type:
export type Zone_Public = typeof(
	setmetatable({} :: ZoneMetaData_Public, {} :: ZoneModule_Public)
)

-- Create and Export MetaData Type:
export type ZoneMetaData_Public = { 
	--====================================================>
	Container:  ZoneContainer;
	Identifier: string;
	--====================================================>
	-- Whether the Zone has Connections:
	Active:      boolean;
	--====================================================>
	Detection:  number;
	Accuracy:   number;
	Simulation: number;
	--====================================================>
	Region:      Region3;
	ExactRegion: Region3;
	BoundMin:    Vector3;
	BoundMax:    Vector3;
	Volume:      number;
	AllZonePartsAreBlocks: boolean;
	--====================================================>
	PlayerEntered: GoodSignalModule.Signal;
	PlayerExited: GoodSignalModule.Signal;

	PartEntered: GoodSignalModule.Signal;
	PartExited: GoodSignalModule.Signal;

	ItemEntered: GoodSignalModule.Signal;
	ItemExited: GoodSignalModule.Signal;
	--====================================================>
	LocalPlayerEntered: GoodSignalModule.Signal;
	LocalPlayerExited: GoodSignalModule.Signal;
	--====================================================>
}

-- Create and Export Module Type:
export type ZoneModule_Public = {
	--====================================================>

	Destroy: 
		(self: Zone_Public) -> ();

	--====================================================>

	__index: ZoneModule_Public;

	--====================================================>
}

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
	_UpdateTrove: TroveModule.Trove;
	_EventTrove:  TroveModule.Trove;
	_PartTrove:   TroveModule.Trove;
	_HolderTrove: TroveModule.Trove;
	--====================================================>
	_RunScope: 'Client' | 'Server';
	--====================================================>
	_Settings: {
		Detection:  number;
		Accuracy:   number;
		Simulation: number;
		Rate:       number;
	};
	--====================================================>
	_ZonerFolder: ZonerFolder;
	--====================================================>
	_Container:  ZoneContainer;
	--====================================================>
	_Identifier: string;
	--====================================================>
	_Tags: {
		ZonePart: string;
	};
	_States:  {
		Active: boolean;
		Destroyed: boolean;
		Relocated: boolean;
	};

	_Signals: {
		--=========================================>
		PlayerEntered: GoodSignalModule.Signal;
		PlayerExited: GoodSignalModule.Signal;

		PartEntered: GoodSignalModule.Signal;
		PartExited: GoodSignalModule.Signal;

		ItemEntered: GoodSignalModule.Signal;
		ItemExited: GoodSignalModule.Signal;

		LocalPlayerEntered: GoodSignalModule.Signal;
		LocalPlayerExited: GoodSignalModule.Signal;
		--=========================================>
	};

	_Instances: {
		CoreActor: ZoneCoreActor;
		RelocationContainer: ZoneContainer;
		ZoneParts: {BasePart};
		Holders:   {Instance};
	};

	_Properties: {
		--=========================================>
		Region: Region3;
		BoundMin: Vector3;
		BoundMax: Vector3;

		Exact_Region: Region3;
		Exact_BoundMin: Vector3;
		Exact_BoundMax: Vector3;
		Volume: number;
		--=========================================>
		Region_Size: Vector3;
		Region_CFrame: CFrame;
		ExactRegion_Size: Vector3;
		ExactRegion_CFrame: CFrame;
		--=========================================>
		AllZonePartsAreBlocks: boolean;
		--=========================================>
	};

	_Counters: {
		ActivityCheck: {Counter: number; CounterMax: number};
		SettingsCheck: {Counter: number; CounterMax: number};
	};

	_ConnectionStats: {
		PlayerConnections:      number;
		ItemConnections:        number;
		LocalPlayerConnections: number;
		PartConnections:        number;
	};

	_ActiveTriggers: {
		LocalPlayer: boolean;
		Players:     boolean;
		Items:       boolean;
		Parts:       boolean;
	};

	--====================================================>
	_Holders:   {Instance};
	_ZoneParts: {BasePart};

	_AllZonePartsAreBlocks: boolean;

	_OverlapParamaters: {
		PartsIncludeList: OverlapParams;
		PartsExcludeList: OverlapParams;
	};

	--====================================================>
	-- Meta Indexing:

	_CoreActor: ZoneCoreActor;
	-- Whether the Zone has Connections:
	_Active: boolean;

	Region: Region3;
	Exact_Region: Region3;
	BoundMin: Vector3;
	BoundMax: Vector3;
	Volume: number;
	
	Detection:  number;
	Accuracy:   number;
	Simulation: number;
	--====================================================>
	PlayerEntered: GoodSignalModule.Signal;
	PlayerExited: GoodSignalModule.Signal;

	PartEntered: GoodSignalModule.Signal;
	PartExited: GoodSignalModule.Signal;

	ItemEntered: GoodSignalModule.Signal;
	ItemExited: GoodSignalModule.Signal;
	--====================================================>
	LocalPlayerEntered: GoodSignalModule.Signal;
	LocalPlayerExited: GoodSignalModule.Signal;
	--====================================================>
}

-- Create and Export Module Type:
export type ZoneModule = {
	--====================================================>

	New: 
		(
			ZonerFolder: ZonerFolder,
			RunScope: 'Server'|'Client',
			Id: string,
			Container: ZoneContainer,
			Accuracy:  number?,
			Detection: number?
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
		(self: Zone, NameOrId: number | EnumsModule.Detections) -> ();
	SetAccuracy: 
		(self: Zone, NameOrId: number | EnumsModule.Accuracies) -> ();
	SetSimulation: 
		(self: Zone, NameOrId: number | EnumsModule.Simulations) -> ();
	SetRate: 
		(self: Zone, NameOrId: number | EnumsModule.Rates) -> ();

	Relocate: 
		(self: Zone) -> Zone;

	--====================================================>

	_OnZonePartUpdate: 
		(self: Zone, Purpose: 'Add'|'Remove', ZonePart: BasePart) -> ();

	_OnPostSimulation: 
		(self: Zone, Type: 'Sync'|'Desync', DeltaTime: number) -> ();

	--====================================================>

	__index: ZoneModule;

	--====================================================>
}

--=======================================================================================================>

-- Create and Export Object Type:
export type ZoneCore = typeof(
	setmetatable({} :: ZoneCoreMetaData, {} :: ZoneCoreModule)
)

-- Create and Export MetaData Type:
export type ZoneCoreMetaData = { 
	--====================================================>
	_Trove: TroveModule.Trove;
	--====================================================>
	_EventTrove:   TroveModule.Trove;
	_PartTrove:    TroveModule.Trove;
	_HolderTrove:  TroveModule.Trove;
	--====================================================>
	_SimulationTrove:   TroveModule.Trove;
	--====================================================>
	_Identifier: string;
	_Container:  ZoneContainer;
	--====================================================>
	_TriggerTroves: {
		Players     : TroveModule.Trove;
		LocalPlayer : TroveModule.Trove;
		Items       : TroveModule.Trove;
	};
	--====================================================>
	_RunScope: 'Client' | 'Server';
	--====================================================>
	_WorldModel: WorldModelTypes.WorldModelModule;
	--====================================================>
	_ZoneParts: ZoneParts;
	--====================================================>
	_Classes: {
		PlayerHandler: PlayerHandlerTypes.PlayerHandler;
	};

	_Client: {
		LocalPlayerName: string;
	};

	--====================================================>

	_Detectors: {
		LocalPlayer: DetectorModule.Detector?;
		Players:     DetectorModule.Detector?;
		Items:       DetectorModule.Detector?;
	};

	_Instances: {
		Holders:   {Instance};
	};

	_Tags: {
		ZonePart: string;
	};

	_CoreActor: ZoneCoreActor;

	_Properties: {
		--=========================================>
		Region: Region3;
		BoundMin: Vector3;
		BoundMax: Vector3;
		
		Exact_Region: Region3;
		Exact_BoundMin: Vector3;
		Exact_BoundMax: Vector3;
		
		Volume: number;
		--=========================================>
		Region_Size: Vector3;
		Region_CFrame: CFrame;
		ExactRegion_Size: Vector3;
		ExactRegion_CFrame: CFrame;
		--=========================================>
		AllZonePartsAreBlocks: boolean;
		--=========================================>
	};
	_ActiveTriggers: {
		['LocalPlayer']: boolean;
		['Players']:     boolean;
		['Items']:       boolean;
		['Parts']:       boolean;
	};
	_States: {
		Active:     boolean;
		Destroyed: boolean;
	};
	_Settings: {
		Detection:  number;
		Accuracy:   number;
		Simulation: number;
		Rate:       number;
	};
	_Events: {
		--=========================================>
		ZoneSignals: BindableEvent;
		--=========================================>
		HoldersUpdate:      BindableEvent;
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

	_PartData: {
		CurrentPartsInZone:  {[BasePart]: boolean};
		PreviousPartsInZone: {[BasePart]: boolean};
	};

	_Counters: {
		ZoneCalculations: {Counter: number; CounterMax: number};
	};


	--====================================================>
	-- Meta Indexing:

	-- Whether the Zone has Connections:
	_Active: boolean;

	_PlayerHandler: PlayerHandlerTypes.PlayerHandler;

	_Holders:   {Instance};

	Region: Region3;
	ExactRegion: Region3;
	BoundMin: Vector3;
	BoundMax: Vector3;
	Volume: number;

	--====================================================>
}

-- Create and Export Module Type:
export type ZoneCoreModule = {
	--====================================================>

	New: 
		(CoreActor: ZoneCoreActor, Container: ZoneContainer) -> Zone;

	Initialize: 
		(self: ZoneCore) -> ();
	SetEvents: 
		(self: ZoneCore) -> ();
	SetData: 
		(self: ZoneCore) -> ();

	--====================================================>

	GetZoneParts: 
		(self: ZoneCore) -> ({BasePart}, {Instance});
	GetZonePartsArray: 
		(self: ZoneCore, ZoneParts: ZoneParts) -> {BasePart};

	AreZonePartsAllBlocks: 
		(self: ZoneCore, ZoneParts: ZoneParts) -> boolean;

	GetCalculatedRegion: 
		(self: ZoneCore, ZoneParts: ZoneParts, DontRound: boolean?) -> (Region3, Vector3, Vector3);

	UpdateTrigger: 
		(self: ZoneCore, Trigger: ZoneTriggers, State: boolean) -> ();
	UpdateZone: 
		(self: ZoneCore, Purpose: 'Parts'|'Region'|'All'|'Overlap'|'PartConnections'|'HolderConnections') -> ();
	
	UpdateDetection: 
		(self: ZoneCore, Detection: number) -> ();
	UpdateSimulation: 
		(self: ZoneCore, Simulation: number) -> ();
	UpdateAccuracy: 
		(self: ZoneCore, Accuracy: number) -> ();
	UpdateRate: 
		(self: ZoneCore, Rate: number) -> ();

	
	CheckTrigger: 
		(self: ZoneCore, Trigger: ZoneTriggers) -> ();
	CheckZone: 
		(self: ZoneCore, Trigger: ZoneTriggers) -> ();

	--===========================================================================================================================>

	OnZonePartUpdate: 
		(self: ZoneCore, Purpose: 'Add'|'Remove', ZonePart: BasePart) -> ();
	OnPostSimulation: 
		(self: ZoneCore, Type: 'Sync'|'Desync', DeltaTime: number) -> ();
	OnSimulation: 
		(self: ZoneCore, Type: 'Sync'|'Desync', DeltaTime: number) -> ();

	--====================================================>

	__index: ZoneCoreModule;

	--====================================================>
}

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>