--=======================================================================================================>
--!strict
--=======================================================================================================>

-- Make the Module into a Type:
export type BoundsTypes = 'PerPart' | 'BoxExact' | 'BoxVoxel'

export type BoundsHandlers = PerPartBoundsHandler | BoxBoundsHandler

--=======================================================================================================>

export type DefaultHandler = {
	Destroying: boolean;
	BoundsType: BoundsTypes;
	_DetectionMethod: number;

	AddZonePart: 
		(self: DefaultHandler, ZonePart: BasePart) -> ();
	RemoveZonePart: 
		(self: DefaultHandler, ZonePart: BasePart) -> ();
	ToggleVisibility: 
		(self: DefaultHandler, State: boolean) -> ();

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

export type ZoneBoxes = {[{any}]: PerPart_ZoneBoxDetails};
export type ZoneParts = {[BasePart]: PerPart_ZonePartDetails};

export type ZonePieces = {[any]: ZoneBoxDetails | ZonePartDetails}

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
		(self: PerPart_ZonePartDetails, State: boolean) -> ();

	Destroy: 
		(self: PerPart_ZonePartDetails) -> ();

	--===============================>
};

export type PerPartBoundsHandler = {
	--====================================================>
	Destroying: boolean;
	Visible:    boolean;
	BoundsType: 'PerPart';
	--====================================================>
	_DetectionMethod: number;
	--====================================================>
	ZoneParts: ZoneParts?;
	ZoneBoxes: ZoneBoxes?;
	--====================================================>
	_Events: {};
	--====================================================>
	_GetZonePartDetails: 
			(self: PerPartBoundsHandler, Part: BasePart, Serial: boolean) -> PerPart_ZonePartDetails;
	_GetZoneBoxDetails: 
		(self: PerPartBoundsHandler, Box: {CFrame: CFrame, Size: Vector3}, Serial: boolean) -> PerPart_ZoneBoxDetails;
	--====================================================>
	AddZonePart: 
		(self: PerPartBoundsHandler, ZonePart: BasePart) -> ();
	RemoveZonePart: 
		(self: PerPartBoundsHandler, ZonePart: BasePart) -> ();
	--====================================================>
	GetZonePieces: 
		(self: PerPartBoundsHandler) -> ZonePieces;
	GetZoneParts: 
		(self: PerPartBoundsHandler) -> ZoneParts;
	GetZoneBoxes: 
		(self: PerPartBoundsHandler) -> ZoneBoxes;

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
	ZoneParts:       ZoneParts?;
	
	_ZoneBoxesArray: {{CFrame: CFrame, Size: Vector3}}?;
	ZoneBoxes:       ZoneBoxes?;
	
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
		(self: BoxBoundsHandler) -> ZonePieces;
	GetZoneParts: 
		(self: BoxBoundsHandler) -> ZoneParts;
	GetZoneBoxes: 
		(self: BoxBoundsHandler) -> ZoneBoxes;

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

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>