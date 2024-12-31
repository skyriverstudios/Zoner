--=======================================================================================================>
--!strict
--=======================================================================================================>

-- Grab the ZonerModule Reference:
local ZonerModule = script.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent

-- Require the Types:
local Trove = require(ZonerModule.Classes.Utilities.Trove);
-- Require the Types:
local Enums = require(ZonerModule.Classes.Utilities.Enums);

local BoundsHandlerTypes = require(script.Parent.Parent.Parent.Parent.BoundsHandler.Types)

--=======================================================================================================>

-- Create and Export Type:
export type TrackableInstance = Model | BasePart

export type ZonePartDetails = 
	BoundsHandlerTypes.ZonePartDetails | BoundsHandlerTypes.ZoneBoxDetails

export type PartDetails = {
	Part: BasePart;
	Type: 'Sphere'|'Complex'|'Block';
}
--=======================================================================================================>
-- Create the Object Types:


-- Create and Export Object Type:
export type TargetTracker = typeof(
	setmetatable({} :: TargetTrackerMetaData, {} :: TargetTrackerModule)
)

-- Create and Export MetaData Type:
export type TargetTrackerMetaData = {
	--===========================================>
	_Trove: Trove.Trove;
	--===========================================>
	_Item: TrackableInstance;
	--===========================================>
	_IsAModel: boolean;
	--===========================================>
	_Parts: {[BasePart]: PartDetails};
	_PartsArray: {BasePart};
	_NumberOfParts: number;
	--===========================================>
	_CenterPart: BasePart;
	--===========================================>
	InZone: boolean;
	--===========================================>
	_DetectionMode:     number;
	_DetectionCoverage: number;
	--===========================================>
}

-- Create and Export Module Type:
export type TargetTrackerModule = {
	--===========================================>

	New: 
		(Item: TrackableInstance, DetectionCoverage: number?, DetectionMode: number?) -> TargetTracker,
	Destroy: 
		(self: TargetTracker) -> (),

	_Initialize: 
		(self: TargetTracker) -> (),
	_SetData: 
		(self: TargetTracker) -> (),
	_SetEvents: 
		(self: TargetTracker) -> (),

	_GetCenterPart: 
		(self: TargetTracker) -> BasePart,
	_GetDetections: 
		(self: TargetTracker) -> (number, number),
	_GetFilterDescendants: 
		(self: TargetTracker, Parts: {[BasePart]: PartDetails}) -> {BasePart},

	_IsPartValidForItem: 
		(self: TargetTracker, Part: BasePart) -> boolean,
	_IsPartInZonePart: 
		(self: TargetTracker, Part: BasePart | {CFrame: CFrame, Size: Vector3}, ZoneCFrame: CFrame, ZoneHalfSize: Vector3?, ZoneRadius: number?, ZoneParts: {[any]: ZonePartDetails}?) -> boolean,


	_FindPartInArray:
		(self: TargetTracker, Part: BasePart, Array: {BasePart}) -> number?;

		
	GetPosition: 
		(self: TargetTracker, Part: BasePart?) -> Vector3,
	_GetBoundingBox: 
		(self: TargetTracker) -> {CFrame: CFrame, Size: Vector3},

		GetTargetPartsFromHitParts: 
			(self: TargetTracker, HitParts: {[BasePart]: boolean}) -> {BasePart},

	IsInsideZoneParts:
		(self: TargetTracker, ZoneParts: {[any]: ZonePartDetails}, HitTargetParts: {BasePart}?) -> boolean;
	IsInsideBox:
		(self: TargetTracker, BoxCFrame: CFrame, BoxHalfSize: Vector3, HitTargetParts: {BasePart}?) -> boolean;
	IsInsideSphere:
		(self: TargetTracker, SphereCFrame: CFrame, SphereRadius: number) -> boolean;

	IsInsideRegion: 
		(self: TargetTracker, Region: Region3?, RegionCFrame: CFrame?, RegionSize: Vector3?) -> boolean,
	IsInsideBoundBox: 
		(self: TargetTracker, BoundMin: Vector3, BoundMax: Vector3) -> boolean,


	DictionaryHasTrackedParts: 
		(self: TargetTracker, Dictionary: {[BasePart]: boolean}) -> boolean,

	ArrayHasTrackedParts: 
		(self: TargetTracker, Array: {BasePart}) -> boolean,

	SetDetection: 
		(self: TargetTracker, DetectionCoverage: number, DetectionMode: number) -> (),

	FindPartInParts: 
		(self: TargetTracker, Part: BasePart, Array: {BasePart}) -> number?,

	--===========================================>

	__index: TargetTrackerModule,

	--===========================================>
}

--=======================================================================================================>

-- Clear from memory:
Trove = nil :: any
Enums = nil :: any

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>