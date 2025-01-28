--=======================================================================================================>
--!strict
--=======================================================================================================>

-- Import the Bounds Types:
local BoundsHandlerTypes = require(script.Parent.Classes.BoundsHandler.Types);
-- Import the Target Types:
local TargetHandlerTypes = require(script.Parent.Classes.TargetHandler.Types);
-- Import the Shared Types:
local SharedTypes        = require(script.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Types.SharedTypes)

--=======================================================================================================>

export type ZonePieces        = SharedTypes.ZonePieces
export type ZoneBoxes         = SharedTypes.ZoneBoxes
export type ZoneParts         = SharedTypes.ZoneParts

export type TargetTypes       = TargetHandlerTypes.TargetTypes
export type TargetHandler     = TargetHandlerTypes.DefaultTargetHandler

export type DetectionTypes    = 'Complex'|'Simple'|'Efficient'
export type TrackerStatuses   = 'Entered'|'Exited'|'In'|'Out'
export type TargetTracker     = TargetHandlerTypes.TargetTracker

export type ZoneSettingsTable = SharedTypes.ZoneSettingsTable
export type ZoneContainerType = SharedTypes.ZoneContainerType
export type ZoneStatesTable   = SharedTypes.ZoneStatesTable
export type ZoneFolder        = SharedTypes.ZoneFolder

--=======================================================================================================>

export type ZoneEngineData    = {
	ZoneContainerType: ZoneContainerType;
	ZoneSettings:      ZoneSettingsTable;
	ZoneStates:        ZoneStatesTable;
	ZoneFolder:        ZoneFolder;
	ZonePieces:        ZonePieces;
	ZoneId:            string;
}

export type DetectionHandler = {
	--====================================================>
	DetectionType:   'Complex' | 'Simple' | 'Efficient';
	--====================================================>
	Destroying: boolean;
	Detecting:  boolean;
	--====================================================>
	_Settings: SharedTypes.ZoneSettingsTable;
	_States:   SharedTypes.ZoneStatesTable;
	_Events:   {[string]: BindableEvent};
	_Id: string;
	--====================================================>
	_BoundsHandler:        BoundsHandlerTypes.DefaultHandler;

	-- For Indexing Purposes:
	_Box_BoundsHandler:     BoundsHandlerTypes.BoxBoundsHandler;
	_PerPart_BoundsHandler: BoundsHandlerTypes.PerPartBoundsHandler;

	_TargetHandlers: {
		LocalPlayer: TargetHandlerTypes.LocalPlayerTargetHandler?;
		Players:     TargetHandlerTypes.PlayersTargetHandler?;
		Items:       TargetHandlerTypes.TargetHandlers?;
		Parts:       TargetHandlerTypes.PartsTargetHandler?;
	};
	--====================================================>
	_CurrentParts:  {[BasePart]: boolean};
	_PreviousParts: {[BasePart]: boolean};

	_OverlapParamaters: {
		PartsIncludeList: OverlapParams;
		PartsExcludeList: OverlapParams;
	}?;

	--====================================================>

	SetDetection: 
		(self: DetectionHandler, DetectionCoverage: number, DetectionMode: number, DetectionMethod: number?) -> ();

	AddTargetHandler: 
		(self: DetectionHandler, Target: TargetHandlerTypes.TargetTypes) -> ();
	RemoveTargetHandler: 
		(self: DetectionHandler, Target: TargetHandlerTypes.TargetTypes) -> ();
	AddToCurrentParts: 
		(self: DetectionHandler, Parts: {BasePart}) -> ();
	AddToPreviousParts: 
		(self: DetectionHandler, Parts: {BasePart}) -> ();
	AddOverlapParamaters: 
		(self: DetectionHandler) -> ();
	RemoveOverlapParamaters: 
		(self: DetectionHandler) -> ();
	RemoveCurrentParts: 
		(self: DetectionHandler) -> ();
	RemovePreviousParts: 
		(self: DetectionHandler) -> ();

	GetTrackerStatus: 
		(self: DetectionHandler, TargetTracker: TargetTracker, HitTargetParts: {BasePart}?) -> TrackerStatuses;
	GetBoundsHandler: 
		(self: DetectionHandler) -> BoundsHandlerTypes.DefaultHandler;
	GetDetectionStatus: 
		(self: DetectionHandler) -> boolean;

	RunDetection: 
		(self: DetectionHandler) -> ();

	--- Function that will run the location checking code for the passed in Tracker and set its location status as well as add it to the
	--- Entrance or Exit table on the TargetHandler depending on its location status:
	ComputeTrackerLocation: 
		(self: DetectionHandler, Key: string, TargetHandler: TargetHandler, Tracker: TargetTracker, TrackerHitParts: {BasePart}?) -> ();
	FireSignals: 
		(self: DetectionHandler) -> ();
	--====================================================>
	Destroy: 
		(self: DetectionHandler) -> ();
	--====================================================>
}

export type ComplexDetectionHandler = {
	--====================================================>
	RunDetection: 
		(self: ComplexDetectionHandler) -> ();
	--====================================================>
} & DetectionHandler

export type SimpleDetectionHandler = {
	--====================================================>
	RunDetection: 
		(self: SimpleDetectionHandler) -> ();
	--====================================================>
} & DetectionHandler

export type EfficientDetectionHandler = {
	--====================================================>
	RunDetection: 
		(self: EfficientDetectionHandler) -> ();
	--====================================================>
} & DetectionHandler

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>