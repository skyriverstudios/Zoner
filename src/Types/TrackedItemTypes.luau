--=======================================================================================================>
--!strict
--=======================================================================================================>

-- Grab the ZonerModule Reference:
local ZonerModule = script.Parent.Parent

-- Require the Types:
local Trove = require(ZonerModule.Utility.Trove);
-- Require the Types:
local Enums = require(ZonerModule.Utility.Enums);

--=======================================================================================================>

-- Create and Export Type:
export type TrackableItem = Model | BasePart

--=======================================================================================================>
-- Create the Object Types:


-- Create and Export Object Type:
export type ItemTracker = typeof(
	setmetatable({} :: ItemTrackerMetaData, {} :: ItemTrackerModule)
)

-- Create and Export MetaData Type:
export type ItemTrackerMetaData = {
	--===========================================>
	_Trove: Trove.Trove;
	--===========================================>
	_Item: TrackableItem;
	--===========================================>
	_IsAModel: boolean;
	--===========================================>
	_Parts: {[BasePart]: boolean};
	--===========================================>
	_CenterPart: BasePart;
	--===========================================>
	InZone: boolean;
	--===========================================>
	_Detection: number;
	--===========================================>
}

-- Create and Export Module Type:
export type ItemTrackerModule = {
	--===========================================>

	New: 
		(Item: TrackableItem, Detection: number?) -> ItemTracker,
	Destroy: 
		(self: ItemTracker) -> (),

	_Initialize: 
		(self: ItemTracker) -> (),
	_SetData: 
		(self: ItemTracker) -> (),
	_SetEvents: 
		(self: ItemTracker) -> (),

	_GetCenterPart: 
		(self: ItemTracker) -> BasePart,
	_GetDetection: 
		(self: ItemTracker) -> number,
	_GetFilterDescendants: 
		(self: ItemTracker, Parts: {[BasePart]: boolean}) -> {BasePart},

	_IsPartValidForItem: 
		(self: ItemTracker, Part: BasePart) -> boolean,

	GetPosition: 
		(self: ItemTracker, Part: BasePart?) -> Vector3,

	IsInsideRegion: 
		(self: ItemTracker, Region: Region3?, RegionCFrame: CFrame?, RegionSize: Vector3?) -> boolean,
	IsInsideBoundBox: 
		(self: ItemTracker, BoundMin: Vector3, BoundMax: Vector3) -> boolean,


	DictionaryHasTrackedParts: 
		(self: ItemTracker, Dictionary: {[BasePart]: boolean}) -> boolean,

	ArrayHasTrackedParts: 
		(self: ItemTracker, Array: {BasePart}) -> boolean,

	SetDetection: 
		(self: ItemTracker, NameOrId: (number | Enums.Detections)) -> (),

	FindPartInParts: 
		(self: ItemTracker, Part: BasePart, Array: {BasePart}) -> number?,

	--===========================================>

	__index: ItemTrackerModule,

	--===========================================>
}

--=======================================================================================================>

-- Clear from memory:
Trove = nil :: any

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>