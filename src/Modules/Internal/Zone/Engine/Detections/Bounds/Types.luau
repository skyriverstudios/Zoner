--=======================================================================================================>
--!strict
--=======================================================================================================>

-- This will inject all types into this context.
local Types = require(`../../../../../../Types`)

-- Make the Module into a Type:
export type BoundsTypes = 'PerPart' | 'BoxExact' | 'BoxVoxel'

export type BoundsHandlers = PerPartBoundsHandler | BoxBoundsHandler

export type ZonePieces = Types.ZonePieces
export type ZoneBoxes = Types.ZoneBoxes


--=======================================================================================================>

export type DefaultHandler = {
	Destroying: boolean;
	BoundsType: BoundsTypes;
	Relocated:  boolean;
	Visible:    boolean;
	_DetectionMethod: number;

	AddZonePart: 
		(self: DefaultHandler, ZonePart: BasePart) -> ();
	RemoveZonePart: 
		(self: DefaultHandler, ZonePart: BasePart) -> ();
	ToggleVisibility: 
		(self: DefaultHandler, State: boolean) -> ();

	GetZonePieces: 
		(self: DefaultHandler) -> ZoneDetailPieces;
	GetZoneParts: 
		(self: DefaultHandler) -> {[BasePart]: ZonePartDetails};
	Destroy: 
		(self: DefaultHandler) -> ();
}

export type ZonePartDetails = {
	--===============================>
	-- Type of Part:
	Type: 'Complex' | 'Block' | 'Sphere';

	Part:     BasePart;

	Size:     Vector3;
	HalfSize: Vector3;
	CFrame:   CFrame?;
	Radius:   number?;
	--===============================>
};

export type ZoneBoxDetails = {
	--===============================>
	-- Type of Part:
	Type: 'Block';

	Part:     {CFrame: CFrame, Size: Vector3};

	Size:     Vector3;
	HalfSize: Vector3;
	CFrame:   CFrame?;
	Radius:   number?;
	--===============================>
};

export type ZoneDetailBoxes = {[{any}]: PerPart_ZoneBoxDetails};
export type ZoneDetailParts = {[BasePart]: PerPart_ZonePartDetails};

export type ZoneDetailPieces = {[any]: ZoneBoxDetails | ZonePartDetails}

export type ZoneBoxPartDetails = {[BasePart]: ZonePartDetails};

--=======================================================================================================>


export type PerPart_ZoneBoxDetails = {
	--===============================>
	-- Type of Part:
	Type: 'Block';
	Serial:   boolean;

	Part:     {CFrame: CFrame, Size: Vector3};

	CFrame:   CFrame;

	Size:     Vector3;
	HalfSize: Vector3;

	VisibilityData: {
		Highlight:            Highlight;
		PreviousMaterial:     Enum.Material;
		PreviousTransparency: number;
	}?;

	--===============================>

	ToggleVisibility: 
		(self: PerPart_ZoneBoxDetails, State: boolean) -> ();

	Destroy: 
		(self: PerPart_ZoneBoxDetails) -> ();

	--===============================>
};

export type PerPart_ZonePartDetails = {
	--===============================>
	-- Type of Part:
	Type: 'Complex' | 'Block' | 'Sphere';
	Serial:   boolean;

	Part:     BasePart;

	Size:     Vector3;
	HalfSize: Vector3;
	Radius:   number?;
	Anchored: boolean;

	VisibilityData: {
		Highlight:            Highlight;
		PreviousMaterial:     Enum.Material;
		PreviousTransparency: number;
	}?;

	-- Holds the Part's CFrame only if its Anchored:
	CFrame:   CFrame?;

	-- Holds Update Events for this Part:
	_Events: {
		AnchoredChanged: RBXScriptConnection;
		CFrameChanged:   RBXScriptConnection?;
		SizeChanged:     RBXScriptConnection;
	};

	--===============================>

	OnAnchoredChanged: 
		(self: PerPart_ZonePartDetails) -> ();
	OnCFrameChanged: 
		(self: PerPart_ZonePartDetails) -> ();
	OnSizeChanged: 
		(self: PerPart_ZonePartDetails) -> ();

	ToggleVisibility: 
		(self: PerPart_ZonePartDetails, State: boolean, Container: Model?) -> ();

	Destroy: 
		(self: PerPart_ZonePartDetails) -> ();

	--===============================>
};

export type PerPartBoundsHandler = {
	--====================================================>
	Destroying: boolean;
	Visible:    boolean;
	Relocated:  boolean;
	BoundsType: 'PerPart';
	_Id: string;
	--====================================================>
	_DetectionMethod: number;
	--====================================================>
	ZoneParts: ZoneDetailParts?;
	ZoneBoxes: ZoneDetailBoxes?;
	--====================================================>
	-- Dictionary storing Data related to the Box that makes up the Zone:
	ZoneBoxData: {
		Container: Model?;
	};
	_Events: {};
	--====================================================>
	_GetZonePartDetails: 
		(self: PerPartBoundsHandler, Part: BasePart, Serial: boolean) -> PerPart_ZonePartDetails;
	_GetZoneBoxDetails: 
		(self: PerPartBoundsHandler, Box: {CFrame: CFrame, Size: Vector3}, Serial: boolean) -> PerPart_ZoneBoxDetails;
	--====================================================>
	_ClearVisibleContainer: 
		(self: PerPartBoundsHandler) -> ();
	_MakeVisibleContainer: 
		(self: PerPartBoundsHandler) -> ();
	--====================================================>
	AddZonePart: 
		(self: PerPartBoundsHandler, ZonePart: BasePart) -> ();
	RemoveZonePart: 
		(self: PerPartBoundsHandler, ZonePart: BasePart) -> ();
	--====================================================>
	GetZonePieces: 
		(self: PerPartBoundsHandler) -> ZoneDetailPieces;
	GetZoneParts: 
		(self: PerPartBoundsHandler) -> {[BasePart]: ZonePartDetails};
	GetZoneBoxes: 
		(self: PerPartBoundsHandler) -> ZoneDetailBoxes;

	ToggleVisibility: 
		(self: PerPartBoundsHandler, State: boolean) -> ();
	--====================================================>
	Destroy: 
		(self: PerPartBoundsHandler) -> ();
	--====================================================>
}

--=======================================================================================================>

export type Box_ZonePartDetails = {
	--===============================>
	-- Original Transparency of the ZonePart:
	OriginalTransparency: number;

	-- Holds Update Events for this Part:
	_Events: {
		CFrameChanged:   RBXScriptConnection?;
		SizeChanged:     RBXScriptConnection;
	};

	-- Destroy Method:
	Destroy: 
		(self: Box_ZonePartDetails) -> ();
	--===============================>
};

export type BoxBoundsHandler = {
	--====================================================>
	BoundsType: 'BoxExact' | 'BoxVoxel';
	Destroying: boolean;
	Visible:    boolean;
	Relocated:  boolean;
	Serial:     boolean;
	_Id:        string;
	--====================================================>
	CFrame: CFrame;
	Size:   Vector3;
	HalfSize: Vector3;
	Volume: number;
	--====================================================>
	_DetectionMethod: number;
	--====================================================>
	_ZonePartsArray: {BasePart}?;
	_ZoneBoxesArray: {{CFrame: CFrame, Size: Vector3}}?;

	ZoneParts:       {[BasePart]: Box_ZonePartDetails}?;
	ZoneBoxes:       {[{any}]: PerPart_ZoneBoxDetails}?;

	-- Dictionary storing Data related to the Box that makes up the Zone:
	ZoneBoxData: {
		-- Array of Part(s) (most likely will only ever be one unless zone is bigger than 2048 studs) that are under the container:
		Parts: {[BasePart]: ZonePartDetails};
		-- Reference to the Container Instance:
		Container: Model?;
		Highlight: Highlight?;
		-- Whether a Box Part will be made in reference to the Region:
		Need: boolean;
	};
	--====================================================>
	_GetZonePartDetails: 
		(self: BoxBoundsHandler, Part: BasePart) -> Box_ZonePartDetails;
	_GetZoneBoxDetails: 
		(self: BoxBoundsHandler, Box: {CFrame: CFrame, Size: Vector3}) -> PerPart_ZoneBoxDetails;
	--====================================================>
	_CalculateBox: 
		(self: BoxBoundsHandler) -> ();
	_ClearBoxPart: 
		(self: BoxBoundsHandler) -> ();
	_MakeBoxPart: 
		(self: BoxBoundsHandler) -> ();
	--====================================================>
	AddZonePart: 
		(self: BoxBoundsHandler, ZonePart: BasePart) -> ();
	RemoveZonePart: 
		(self: BoxBoundsHandler, ZonePart: BasePart) -> ();
	--====================================================>
	GetZonePieces: 
		(self: BoxBoundsHandler) -> ZoneBoxPartDetails;
	GetZoneParts: 
		(self: BoxBoundsHandler) -> {[BasePart]: ZonePartDetails};
	GetZoneBoxes: 
		(self: BoxBoundsHandler) -> ZoneDetailBoxes;

	ToggleVisibility: 
		(self: BoxBoundsHandler, State: boolean) -> ();
	--====================================================>
	Destroy: 
		(self: BoxBoundsHandler) -> ();
	--====================================================>
}

--=======================================================================================================>

export type BoxVoxelBoundsHandler = BoxBoundsHandler
export type BoxExactBoundsHandler = BoxBoundsHandler

type BoundTypes = 'BoxExact' | 'BoxVoxel' | 'PerPart'

export type BoundsHandler<Type, PartDetails, BoxDetails> = {
	--====================================================>
	BoundsType: Type;

	Destroying: boolean;
	Visible:    boolean;
	Relocated:  boolean;
	Serial:     boolean;
	Id:         string;
	--====================================================>
	CFrame: CFrame;
	Size:   Vector3;
	HalfSize: Vector3;
	Volume: number;
	--====================================================>
	DetectionMethod: number;
	--====================================================>
	ZonePartsArray: {BasePart}?;
	ZoneBoxesArray: {{CFrame: CFrame, Size: Vector3}}?;

	ZoneParts:       {[BasePart]: PartDetails}?;
	ZoneBoxes:       {[{any}]: BoxDetails}?;

	-- Dictionary storing Data related to the Box that makes up the Zone:
	ZoneBoxData: {
		-- Array of Part(s) (most likely will only ever be one unless zone is bigger than 2048 studs) that are under the container:
		Parts: {[BasePart]: {[BasePart]: PartDetails}};
		-- Reference to the Container Instance:
		Container: Model?;
		Highlight: Highlight?;
		-- Whether a Box Part will be made in reference to the Region:
		Need: boolean;
	};
	--====================================================>
	_GetZonePartDetails: 
		(self: BoundsHandler<Type, PartDetails, BoxDetails>, Part: BasePart) -> PartDetails;
	_GetZoneBoxDetails: 
		(self: BoundsHandler<Type, PartDetails, BoxDetails>, Box: {CFrame: CFrame, Size: Vector3}) -> BoxDetails;
	--====================================================>
	_CalculateBox: 
		(self: BoundsHandler<Type, PartDetails, BoxDetails>) -> ();
	_ClearBoxPart: 
		(self: BoundsHandler<Type, PartDetails, BoxDetails>) -> ();
	_MakeBoxPart: 
		(self: BoundsHandler<Type, PartDetails, BoxDetails>) -> ();
	--====================================================>
	AddZonePart: 
		(self: BoundsHandler<Type, PartDetails, BoxDetails>, ZonePart: BasePart) -> ();
	RemoveZonePart: 
		(self: BoundsHandler<Type, PartDetails, BoxDetails>, ZonePart: BasePart) -> ();
	--====================================================>
	GetZonePieces: 
		(self: BoundsHandler<Type, PartDetails, BoxDetails>) -> {[BasePart]: BoxDetails};
	GetZoneParts: 
		(self: BoundsHandler<Type, PartDetails, BoxDetails>) -> {[BasePart]: PartDetails};
	GetZoneBoxes: 
		(self: BoundsHandler<Type, PartDetails, BoxDetails>) -> {[BasePart]: BoxDetails};

	ToggleVisibility: 
		(self: BoundsHandler<Type, PartDetails, BoxDetails>, State: boolean) -> ();
	--====================================================>
	Destroy: 
		(self: BoundsHandler<Type, PartDetails, BoxDetails>) -> ();
	--====================================================>
}
--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>