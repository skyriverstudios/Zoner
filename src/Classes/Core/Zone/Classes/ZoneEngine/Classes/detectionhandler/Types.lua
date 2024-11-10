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

--=======================================================================================================>

export type PerPart_ZonePartDetails = {
	--===============================>
	-- Type of Part:
	Type: 'Complex' | 'Block' | 'Sphere';
	Serial:   boolean;

	Part:     BasePart;

	Size:     Vector3;
	HalfSize: Vector3;
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
	ZoneParts: {[BasePart]: PerPart_ZonePartDetails};
	--====================================================>
	_Events: {};

	_VisibilityData: {
		ZoneParts:  {[BasePart]: {PrevMaterial: Enum.Material; Highlight: Highlight}};
	}?;
	
	--====================================================>
	_GetZonePartDetails: 
			(self: PerPartBoundsHandler, Part: BasePart, Serial: boolean) -> PerPart_ZonePartDetails;
	--====================================================>
	AddZonePart: 
		(self: PerPartBoundsHandler, ZonePart: BasePart) -> ();
	RemoveZonePart: 
		(self: PerPartBoundsHandler, ZonePart: BasePart) -> ();

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
	--====================================================>
	CFrame: CFrame;
	Size:   Vector3;
	Volume: number;
	--====================================================>
	_DetectionMethod: number;
	--====================================================>
	_ZonePartsArray: {BasePart};
	ZoneParts:       {[BasePart]: Box_ZonePartDetails};
	--====================================================>
	_BoxData: {
		Highlight: Highlight?;
		Container: Model?;
		-- Whether a Box Part will be made in reference to the Region:
		Need: boolean;
	};
	--====================================================>
	_GetZonePartDetails: 
		(self: BoxBoundsHandler, Part: BasePart) -> Box_ZonePartDetails;
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