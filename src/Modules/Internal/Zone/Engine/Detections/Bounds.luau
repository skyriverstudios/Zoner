--===========================================================================================================================>
--!optimize 2
--!native
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: BoundsHandler')

-- Define Module table
local BoundsHandlers = {PerPart  = {}; BoxExact = {}; BoxVoxel = {}}

--===========================================================================================================================>
--[ DEPENDENCIES: ]


local WorldModel = require(`../../WorldModel`);
local Regions    = require(`../../Regions`);
local Enums      = require(`../../../Enums`);

--===========================================================================================================================>
--[ CONSTANTS: ]


local CFRAME_ZERO = CFrame.new()
local VECTOR_ZERO = Vector3.zero
local NUMBER_ZERO = 0

--===========================================================================================================================>
--[ TYPES: ]


-- [ Require Types ]

-- This will inject all types into this context.
local Zoner_Types = require(`../../../../../Types`)

-- [ Define Types ]

type ZonePiece = Zoner_Types.ZonePiece

type ZonePieceObjectMap  = {[ZonePiece]: ZonePieceObject}

type ZonePieceObject = {
	--===============================>
	-- Reference to the Details:
	Details: ZonePieceDetails;

	Events: {
		SizeChanged:     RBXScriptConnection?;
		AnchoredChanged: RBXScriptConnection?;
	};

	VisibilityData: {
		Highlight:            Highlight;
		-- Store the original transparency:
		OriginalTransparency: number;
		OriginalMaterial:     Enum.Material;
	}?;

	--===============================>

	ToggleVisibility:  
		(self: ZonePieceObject, State: boolean, Container: Model?) -> ();
	Destroy: 
		(self: ZonePieceObject) -> ();

	--===============================>
};

type ZonePieceDetails = {
	--===============================>
	-- Type of Piece:
	Type: 'Complex' | 'Block' | 'Sphere' | 'Box';

	-- Reference to the ZonePart BASEPART
	Part: BasePart?;
	-- Reference to the ZoneBox TABLE:
	Box:  {CFrame: CFrame, Size: Vector3}?;

	-- Reference to either:
	Piece: ZonePiece;

	-- Values related to the Zone:
	Size:     Vector3;
	HalfSize: Vector3;

	-- Depends on if its static:
	CFrame:   CFrame?;
	-- Depends on if its a sphere:
	Radius:   number?;

	-- Whether Part is Anchored, auto true if Box:
	Anchored: boolean;
	--===============================>
};

-- Define ZoneEngine Data/Profile sent from ZoneEngine:
type ZoneEngineData = {
	ZoneContainer:      Zoner_Types.ZoneContainer;
	ZoneContainerType:  Zoner_Types.ZoneContainerType;
	ZoneConfig:         Zoner_Types.ZoneConfigTable;
	ZoneStates:         Zoner_Types.ZoneStatesTable;
	ZoneFolder:         Zoner_Types.ZoneFolder;
	ZonePieces:         Zoner_Types.ZonePieces;      
	ZoneId:             string;

	ZoneSignalEvent:    BindableEvent?;
	ZoneSignalFunction: ((Purpose: string, ...any) -> ())?; 
}
-- Make the Module into a Type:
export type BoundsTypes = 'PerPart' | 'BoxExact' | 'BoxVoxel'

export type ZonePieceDetailsMap = {[ZonePiece]: ZonePieceDetails}

export type BoundsHandler = {
	--============================================>
	Destroying: boolean;
	Visible:    boolean;

	-- Stores only Pseudoparts for BoxBounds:
	ZoneParts: {
		ObjectMap:  ZonePieceObjectMap;
		DetailsMap: ZonePieceDetailsMap
	};
	
	-- Stores both Boxes and Parts:
	ZonePieces: {
		ObjectMap:  ZonePieceObjectMap;
		DetailsMap: ZonePieceDetailsMap
	};
	
	-- Dictionary storing Data related to the Box that makes up the Zone:
	ZoneBoxData: {
		--===============================>
		Size:     Vector3;
		CFrame:   CFrame;
		HalfSize: Vector3;
		Volume:   number;
		-- Reference to the Container Instance:
		Container: Model?;
		-- Whether a Box Part will be made in reference to the Region:
		Need: boolean;
		--===============================>
	};
	
	--============================================>

	-- Unified runtime interface
	GetZonePieceDetailsMap: 
		(self: BoundsHandler) -> ZonePieceDetailsMap;
	GetZonePieceObjectMap: 
		(self: BoundsHandler) -> ZonePieceObjectMap;
	
	GetZonePartDetailsMap: 
		(self: BoundsHandler) -> ZonePieceDetailsMap;
	GetZonePartObjectMap: 
		(self: BoundsHandler) -> ZonePieceObjectMap;

	
	ToggleVisibility: 
		(self: BoundsHandler, State: boolean) -> ();

	AddZonePiece:     
		(self: BoundsHandler, ZonePiece: ZonePiece) -> ();
	RemoveZonePiece:  
		(self: BoundsHandler, ZonePiece: ZonePiece) -> ();

	GetBoundType:  
		(self: BoundsHandler) -> BoundsTypes;

	Evaluate: 
		(self: BoundsHandler) -> ();
	Relocate: 
		(self: BoundsHandler) -> ();
	
	Destroy: 
		(self: BoundsHandler) -> ();
	--============================================>
}

--=======================================================================================================>

-- Callback Method for Size Property Changing:
local function OnSizeChanged(ZonePieceObject: ZonePieceObject)
	ZonePieceObject.Details.Size, ZonePieceObject.Details.HalfSize = ZonePieceObject.Details.Piece.Size, ZonePieceObject.Details.Piece.Size / 2
end

-- Callback Method for Anchored Property Changing:
local function OnAnchoredChanged(ZonePieceObject: ZonePieceObject)
	--=======================================================================================>
	-- Update the Anchored, and CFrame:
	ZonePieceObject.Details.Anchored, ZonePieceObject.Details.CFrame = (ZonePieceObject.Details.Part :: BasePart).Anchored, nil :: any
	-- Update the CFrame:
	if ZonePieceObject.Details.Anchored == true then ZonePieceObject.Details.CFrame = ZonePieceObject.Details.Piece.CFrame end
	--=======================================================================================>
end

--=======================================================================================================>

-- Function to construct a ZonePiece Details table:
local function GetZonePieceDetails(ZonePiece: ZonePiece): ZonePieceDetails
	--=======================================================================================>
	-- Get the Type of Piece:
	local Type: 'Box'|'Sphere'|'Block'|'Complex' = if typeof(ZonePiece) == 'table' then 'Box' else Regions:GetPartType(ZonePiece);
	-- Define the ZonePartProperties Dictionary:
	return {
		--======================================>
		Type = Type;
		--======================================>
		Piece = ZonePiece;

		Part = if Type ~= 'Box' then ZonePiece :: BasePart else nil;
		Box  = if Type == 'Box' then ZonePiece :: {CFrame: CFrame, Size: Vector3} else nil;

		Size     = ZonePiece.Size;
		HalfSize = ZonePiece.Size / 2;

		Radius = if Type == 'Sphere' then ZonePiece.Size.X / 2 else nil;

		Anchored = if Type ~= 'Box' then (ZonePiece :: BasePart).Anchored else true;
		--======================================>
	} :: ZonePieceDetails
	--=======================================================================================>
end

-- Function to construct a ZonePiece Object:
local function GetZonePieceObject(ZonePiece: ZonePiece, BoundsHandler: BoundsHandler, EngineData: ZoneEngineData, ZonePart: boolean?): ZonePieceObject
	--=======================================================================================>

	-- Define the ZonePartProperties Dictionary:
	local ZonePieceObject: ZonePieceObject = {
		--======================================>
		Details = if ZonePart ~= true then BoundsHandler.ZonePieces.DetailsMap[ZonePiece] else BoundsHandler.ZoneParts.DetailsMap[ZonePiece];
		Events = {};
		--======================================>
	} :: ZonePieceObject

	--=======================================================================================>

	if ZonePart ~= true and 
		EngineData.ZoneConfig.NoZonePartPropertyListening == false and 
		ZonePieceObject.Details.Type ~= 'Box' and 
		ZonePieceObject.Details.Part and 
		ZonePieceObject.Details.Part:IsA('BasePart') 
	then
		--==============================================================================>
		-- Pass in a Boolean on whether the Execution is Serial or not:
		local Serial = EngineData.ZoneConfig.Execution == Enums.Execution.Serial

		-- Make sure in serial:
		task.synchronize()

		-- Connect in Serial or Parallel: Anchored Property Changed Event:
		ZonePieceObject.Events.SizeChanged = 
			if Serial then ZonePieceObject.Details.Part:GetPropertyChangedSignal('Size'):Connect(function() OnSizeChanged(ZonePieceObject) end)
			else ZonePieceObject.Details.Part:GetPropertyChangedSignal('Size'):ConnectParallel(function()   OnSizeChanged(ZonePieceObject) end)

		-- Connect in Serial or Parallel: Anchored Property Changed Event:
		ZonePieceObject.Events.AnchoredChanged = 
			if Serial then ZonePieceObject.Details.Part:GetPropertyChangedSignal('Anchored'):Connect(function() OnAnchoredChanged(ZonePieceObject) end)
			else ZonePieceObject.Details.Part:GetPropertyChangedSignal('Anchored'):ConnectParallel(function() OnAnchoredChanged(ZonePieceObject) end)

		-- Clear:
		Serial = nil :: any
		--==============================================================================>
	end

	-- Set CFrame if Anchored is true:
	if ZonePieceObject.Details.Anchored == true then
		ZonePieceObject.Details.CFrame = ZonePieceObject.Details.Piece.CFrame;
	end

	--=======================================================================================>

	-- Callback Method for Anchored Property Changing:
	function ZonePieceObject.ToggleVisibility(self: ZonePieceObject, State: boolean)
		--===============================================================================>		
		-- If visibility is toggling on:
		if State == true then
			-- Toggle Off if its already on:
			self:ToggleVisibility(false)
			-- If dealing with Part:
			if self.Details.Part then
				--=====================================================>
				
				-- Make sure in serial:
				task.synchronize()

				--=====================================================>
				
				self.VisibilityData = {
					Highlight            = Instance.new('Highlight');
					OriginalTransparency = self.Details.Part.Transparency;
					OriginalMaterial     = self.Details.Part.Material;
				}

				self.Details.Part.Transparency = 1
				self.Details.Part.Material     = Enum.Material.Glass
				
				if self.VisibilityData and self.VisibilityData.Highlight then
					self.VisibilityData.Highlight.Adornee = self.Details.Part
					self.VisibilityData.Highlight.Parent = self.Details.Part
					self.VisibilityData.Highlight.Enabled = true
					self.VisibilityData.Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
					self.VisibilityData.Highlight.FillColor = Color3.fromRGB(0,0,0)
					self.VisibilityData.Highlight.FillTransparency = 1

					self.VisibilityData.Highlight.OutlineColor = Color3.fromRGB(7, 127, 255)
				end
	
			end
		else
			-- If VisibilityData exists and we're dealing with a Part:
			if self.VisibilityData and self.Details.Part then 
				--=====================================================>
				-- Make sure in serial:
				task.synchronize()
				--=====================================================>
				
				-- Set Part back to Previous Material:
				self.Details.Part.Material     = self.VisibilityData.OriginalMaterial
				-- Set Part back to Previous Transparency:
				self.Details.Part.Transparency = self.VisibilityData.OriginalTransparency
				
				-- Destroy Highlight:
				self.VisibilityData.Highlight:Destroy()
				
				--=====================================================>
				
				-- Clear table:
				table.clear(self.VisibilityData)
				
				-- Set table to nil:
				self.VisibilityData = nil
				--=====================================================>
			end
		end
		--===============================================================================>
	end

	-- Destroy Method for easy Destroyin:
	function ZonePieceObject.Destroy(self: ZonePieceObject)
		--===============================================================================>
		-- If a VisibilityData table exists, clear its variables:
		-- Toggle it to false, clearing its Data:
		self:ToggleVisibility(false)
		--===============================================================================>
		-- If the events are connected:
		if self.Events.SizeChanged or self.Events.AnchoredChanged then
			-- Make sure in serial:
			task.synchronize()
			-- Disconnect all Events in Events table:
			for Key, Connection in pairs(self.Events) do Connection:Disconnect() end
			-- Clear Events Table:
			table.clear(self.Events)
		end
		--===============================================================================>
	end

	--=======================================================================================>

	-- Return the ZonePieceObject:
	return ZonePieceObject

	--=======================================================================================>
end

--=======================================================================================================>

local function RemoveZonePiece(BoundsHandler: BoundsHandler, ZonePiece: ZonePiece)
	--===============================================================================>
	-- If already destroying, return:
	if BoundsHandler.Destroying == true then return end
	--===============================================================================>
	if BoundsHandler.ZonePieces.ObjectMap[ZonePiece] then 
		BoundsHandler.ZonePieces.ObjectMap[ZonePiece]:Destroy();
		BoundsHandler.ZonePieces.ObjectMap[ZonePiece] = nil :: any;
	end
	if BoundsHandler.ZonePieces.DetailsMap[ZonePiece] then 
		table.clear(BoundsHandler.ZonePieces.DetailsMap[ZonePiece])
	end
	--===============================================================================>
end

local function AddZonePiece(BoundsHandler: BoundsHandler, EngineData: ZoneEngineData, ZonePiece: ZonePiece)
	--===============================================================================>
	-- If already destroying, return:
	if BoundsHandler.Destroying == true then return end
	--===============================================================================>
	-- If the ZonePart exists already in the table for some reason, Remove it first:
	if BoundsHandler.ZonePieces.DetailsMap[ZonePiece] and BoundsHandler.ZonePieces.ObjectMap[ZonePiece] then 
		RemoveZonePiece(BoundsHandler, ZonePiece)
	end
	-- Add the ZonePart Details to the Dictionary with the Return Value:
	BoundsHandler.ZonePieces.DetailsMap[ZonePiece] = GetZonePieceDetails(ZonePiece)
	BoundsHandler.ZonePieces.ObjectMap[ZonePiece]  = GetZonePieceObject(ZonePiece, BoundsHandler, EngineData)

	-- Toggle Visibility on the Zone if the ZoneBounds Visibility is set to true:
	BoundsHandler.ZonePieces.ObjectMap[ZonePiece]:ToggleVisibility(BoundsHandler.Visible)
	--===============================================================================>
end

local function AddZonePart(BoundsHandler: BoundsHandler, EngineData: ZoneEngineData, ZonePart: BasePart)
	--===============================================================================>
	-- If already destroying, return:
	if BoundsHandler.Destroying == true then return end
	--===============================================================================>
	-- If the ZonePart exists already in the table for some reason, Remove it first:
	if BoundsHandler.ZoneParts.DetailsMap[ZonePart] and BoundsHandler.ZoneParts.ObjectMap[ZonePart] then 
		RemoveZonePiece(BoundsHandler, ZonePart)
	end
	-- Add the ZonePart Details to the Dictionary with the Return Value:
	BoundsHandler.ZoneParts.DetailsMap[ZonePart] = GetZonePieceDetails(ZonePart)
	BoundsHandler.ZoneParts.ObjectMap[ZonePart]  = GetZonePieceObject(ZonePart, BoundsHandler, EngineData, true)

	-- Toggle Visibility on the Zone if the ZoneBounds Visibility is set to true:
	BoundsHandler.ZoneParts.ObjectMap[ZonePart]:ToggleVisibility(BoundsHandler.Visible)
	--===============================================================================>
end

local function RemoveZoneContainer(BoundsHandler: BoundsHandler, EngineData: ZoneEngineData)
	--===============================================================================>
	-- If no Container is found, return:
	if not BoundsHandler.ZoneBoxData.Container then return end
	--===============================================================================>
	-- Create local reference:
	local ZoneBoxData = BoundsHandler.ZoneBoxData

	-- If the Container Exists, cause of Type Checking..
	if ZoneBoxData.Container then
		--================================================================>
		-- Remove the Container:
		ZoneBoxData.Container:Destroy()
		ZoneBoxData.Container = nil
		--================================================================>
		-- All Pseduo Parts go BYE:
		
		-- Clear all self.ZoneParts data:
		for Key, Object in BoundsHandler.ZoneParts.ObjectMap   do Object:Destroy() end; table.clear(BoundsHandler.ZoneParts.ObjectMap);
		-- Clear all self.ZoneParts data:
		for Key, Details in BoundsHandler.ZoneParts.DetailsMap do table.clear(Details) end; table.clear(BoundsHandler.ZoneParts.DetailsMap);
		--================================================================>
	end
	--===============================================================================>
end

local function MakeZoneContainer(BoundsHandler: BoundsHandler, EngineData: ZoneEngineData)
	--===============================================================================>
	
	-- If a container is already found, return:
	if BoundsHandler.ZoneBoxData.Container then return end
	--===============================================================================>
	-- Create local reference:
	local ZoneBoxData = BoundsHandler.ZoneBoxData
	
	-- Create a Relocation Container Folder:
	ZoneBoxData.Container = Instance.new("Model")
	
	-- If the Container Exists, cause of Type Checking..
	if ZoneBoxData.Container then 
		--================================================================>
		-- Set the Container Name:
		ZoneBoxData.Container.Name               = `{EngineData.ZoneId}:ZoneContainer`
		-- Set the Container ModelStreamingMode:
		ZoneBoxData.Container.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		
		-- IF the ZoneContainer isnt really needed in terms of the detection method:
		if BoundsHandler:GetBoundType() ~= 'PerPart' and ZoneBoxData.Need == true then
			--=======================================================>
			-- Parent the Container to the WorldModel:
			ZoneBoxData.Container.Parent = workspace
			
			-- Create a Cube of Parts inside the Zone matching the CFrame and Size:
			Regions:CreateCube(ZoneBoxData.Container, ZoneBoxData.CFrame, ZoneBoxData.Size)
			
			-- Loop through the ContainerChildren Array and Add each BasePart to the Parts Array:
			for Index: number, Part: Instance in ipairs(ZoneBoxData.Container:GetChildren()) do 
				-- If Part is not a BasePart, continue:
				if Part:IsA('BasePart') == false then continue end
				-- Add the Custom ZonePart to the internal map:
				AddZonePart(BoundsHandler, EngineData, Part :: BasePart)
			end
			--=======================================================>
		elseif EngineData.ZoneContainerType == 'Boxes' then
			--=======================================================>
			-- Loop through the ContainerChildren Array and Add each BasePart to the Parts Array:
			for Key, Details in BoundsHandler.ZonePieces.DetailsMap do 
				if Details.Box then
					local PseduoPart = Instance.new('Part')
					PseduoPart.Anchored = true
					PseduoPart.Size = Details.Box.Size
					PseduoPart.CFrame = Details.Box.CFrame
					PseduoPart.CanCollide = false
					PseduoPart.CanQuery = false
					PseduoPart.Parent = ZoneBoxData.Container
					-- Add the PseduoPart to the internal map:
					AddZonePart(BoundsHandler, EngineData, PseduoPart)
				end
			end
			
			-- Parent the Container to the WorldModel:
			ZoneBoxData.Container.Parent = workspace
			
			--=======================================================>
		else
			-- Parent the Container to Workspace:
			ZoneBoxData.Container.Parent = workspace 
		end
		--================================================================>
	end
	--===============================================================================>
end

local function ComputeZoneBox(BoundsHandler: BoundsHandler, EngineData: ZoneEngineData)
	--===============================================================================>
	
	-- Cache the ZoneBoxData:
	local ZoneBoxData = BoundsHandler.ZoneBoxData
	
	-- Store the Previous Region Size:
	local PreviousSize: Vector3 = ZoneBoxData.Size

	--===============================================================================>

	--if #EngineData.ZonePieces < 1 then return end
	if #EngineData.ZonePieces == 1 and BoundsHandler:GetBoundType() ~= 'BoxVoxel' then
		ZoneBoxData.CFrame, ZoneBoxData.Size = EngineData.ZonePieces[1].CFrame, EngineData.ZonePieces[1].Size
	else

		ZoneBoxData.CFrame, ZoneBoxData.Size = 
			Regions:GetBoundingCFrameAndSize(EngineData.ZonePieces, BoundsHandler:GetBoundType() == 'BoxVoxel')
	end

	--===============================================================================>

	-- Set the HalfSize:
	ZoneBoxData.HalfSize = ZoneBoxData.Size / 2
	-- Calculate the Volume of the Region Via the Rounded Region's Size:
	ZoneBoxData.Volume = ZoneBoxData.Size.X * ZoneBoxData.Size.Y * ZoneBoxData.Size.Z
	
	--===============================================================================>
	
	-- If a BoxPart exists, update its CFrame and Size:
	if ZoneBoxData.Container then
		-- If the ZoneContainer Size is the same as the previous size, then just repivot the CFrame:
		if PreviousSize == ZoneBoxData.Size then
			ZoneBoxData.Container:PivotTo(ZoneBoxData.CFrame)
		else
			-- Cache the Visibility:
			local Visibility = BoundsHandler.Visible
			-- If the Visibility is true, then toggle the visibility off:
			if Visibility then BoundsHandler:ToggleVisibility(false) end
			
			-- Remove the current ZoneContainer:
			RemoveZoneContainer(BoundsHandler, EngineData)
			-- Make a new ZoneContainer:
			MakeZoneContainer(BoundsHandler, EngineData)
			
			-- Parent the Container to Workspace:
			ZoneBoxData.Container.Parent = WorldModel:GetWorldModel()
			
			-- If the Visibility is true, then toggle the back on:
			if Visibility then BoundsHandler:ToggleVisibility(true) end
		end
	elseif ZoneBoxData.Need then
		-- Make a new ZoneContainer:
		MakeZoneContainer(BoundsHandler, EngineData)
		
		if ZoneBoxData.Container then
			-- Parent the Container to Workspace:
			ZoneBoxData.Container.Parent = WorldModel:GetWorldModel()
		end
	
	end
	--===============================================================================>
end

--=======================================================================================================>

-- Constructs a default BoundsHandler:
local function BoundsHandler(EngineData: ZoneEngineData, BoundType: BoundsTypes): BoundsHandler
	--=======================================================================================================>
	
	-- Set Memory Category:
	debug.setmemorycategory('[Zoner]: BoundsHandler')
	
	--=======================================================================================================>
	
	-- Pass in whether the ZonePieces being sent are of Boxes or Parts:
	local PieceType = (if EngineData.ZoneContainerType == 'Boxes' then 'Box' else 'Part')
	-- Pass in a Boolean on whether the Execution is Serial or not:
	local Serial = EngineData.ZoneConfig.Execution == Enums.Execution.Serial

	-- Define the TargetData and Inherit from the Base Class:
	local BoundsData: BoundsHandler = {
		--====================================================>		
		Destroying = false;
		Visible    = false;
		--====================================================>
		ZonePieces = {
			ObjectMap  = {};
			DetailsMap = {};
		};
		-- Will only be filled with Pseduoparts via certain bounds and detection types:
		ZoneParts = {
			ObjectMap  = {};
			DetailsMap = {};
		};
		--====================================================>
		-- Dictionary storing Data related to the Box that makes up the Zone:
		ZoneBoxData = {
			-- Properties of the Box:
			Size     = VECTOR_ZERO;
			CFrame   = CFRAME_ZERO;
			HalfSize = VECTOR_ZERO;
			Volume   = NUMBER_ZERO;
			-- Whether a Box Part will be made in reference to the Region:
			Need = EngineData.ZoneConfig.DetectionMethod == Enums.DetectionMethod.Complex;
		};
		--====================================================>
	} :: BoundsHandler
	
	
	local Part_DetailsMap = 
		if BoundType == 'PerPart' then BoundsData.ZonePieces.DetailsMap else BoundsData.ZoneParts.DetailsMap
	local Part_ObjectMap = 
		if BoundType == 'PerPart' then BoundsData.ZonePieces.ObjectMap else BoundsData.ZoneParts.ObjectMap

	--=======================================================================================================>

	function BoundsData.ToggleVisibility(self: BoundsHandler, State: boolean)
		--===============================================================================>
		-- Prevent redundant toggles:
		if self.Visible == State or self.Destroying == true then return end
		--===============================================================================>
		
		-- Set the Visible Status of the Bounds to the passed boolean:
		self.Visible = State
		
		-- If we are activating on true, and we are a boxes zone, then we will create a container and populate it with pseduo parts:
		if State == true and EngineData.ZoneContainerType == 'Boxes' then 
			-- Create Container with Pseduo Parts:
			MakeZoneContainer(self, EngineData) 
			-- Loop through all the Part_ObjectMap to toggle their Visibility:
			for Part, Object in BoundsData.ZoneParts.ObjectMap do Object:ToggleVisibility(State) end;
		end
		
		-- If Visbility is being set to true, we are relocated, and a Box bound:
		-- Create a new Container if one doesnt exist only, Parent container to workspace:
		if State == true and EngineData.ZoneStates.Relocated == true and BoundType ~= 'PerPart' then
			-- Make a new ZoneContainer:
			MakeZoneContainer(self, EngineData) 
			-- If BoxBounds, then Parent the Container to the workspace so that it is visible:
			if self.ZoneBoxData.Container then self.ZoneBoxData.Container.Parent = workspace end
		end
		
		-- Loop through all the Part_ObjectMap to toggle their Visibility:
		for Part, Object in Part_ObjectMap do Object:ToggleVisibility(State) end;
		
		-- If Visbility is being set to true, we are relocated, and a PerPart bound:
		-- Create a new Container for Visibility only, Parent each Part of the Zone to that container:
		if State == true and EngineData.ZoneStates.Relocated == true and BoundType == 'PerPart' then
			-- Make a new ZoneContainer:
			MakeZoneContainer(self, EngineData) 
			-- If we have a container, parent each part to it:
			if self.ZoneBoxData.Container then
				for Key, Details in self.ZonePieces.DetailsMap do
					if Details.Part then Details.Part.Parent = self.ZoneBoxData.Container end
				end	
			end
		end

		-- If the State is false, and the Container is Relocated, then Clear the Visible Version:
		if State == false and EngineData.ZoneStates.Relocated == true then 
			-- If PerPart, then remove the ZoneContainer:
			if BoundType == 'PerPart' then
				-- Parent each Part back from the Visibvility container to the Zone Container:
				if self.ZoneBoxData.Container then
					for Key, Details in self.ZonePieces.DetailsMap do
						if Details.Part and typeof(EngineData.ZoneContainer) == 'Instance' then 
							Details.Part.Parent = EngineData.ZoneContainer
						end
					end
				end
				-- Delete the ZoneContainer:
				RemoveZoneContainer(self, EngineData) 
			else
				-- If BoxBounds, then Parent the Container back to the WorldModel:
				if self.ZoneBoxData.Container then self.ZoneBoxData.Container.Parent = WorldModel:GetWorldModel() end
			end
		elseif State == false and BoundType ~= 'PerPart' then
			-- If we dont need one, and we only made one cause of visibility, remove it:
			RemoveZoneContainer(self, EngineData) 
		end
		
		-- Remove Container made of pseduo parts:
		if State == false and EngineData.ZoneContainerType == 'Boxes' then 
			-- If we dont need one, and we only made one cause of visibility, remove it:
			RemoveZoneContainer(self, EngineData) 
		end
		
		--===============================================================================>
	end

	--=======================================================================================================>
	-- [ Get Methods ]

	-- Return the ZonePieceDetailsMap Table:
	function BoundsData.GetZonePieceDetailsMap(self: BoundsHandler): ZonePieceDetailsMap
		return self.ZonePieces.DetailsMap
	end
	
	-- Return the ZonePieceDetailsMap Table:
	function BoundsData.GetZonePartDetailsMap(self: BoundsHandler): ZonePieceDetailsMap
		return Part_DetailsMap
	end
	
	-- Return the ZonePieceDetailsMap Table:
	function BoundsData.GetZonePartObjectMap(self: BoundsHandler): ZonePieceObjectMap
		return Part_ObjectMap
	end
	
	-- Return the ZonePieceObjectMap Table:
	function BoundsData.GetZonePieceObjectMap(self: BoundsHandler): ZonePieceObjectMap
		return self.ZonePieces.ObjectMap
	end

	-- Return the BoundType:
	function BoundsData.GetBoundType(self: BoundsHandler): BoundsTypes
		return BoundType
	end

	--=======================================================================================================>
	-- [ Add/Remove Methods ]

	function BoundsData.AddZonePiece(self: BoundsHandler, ZonePiece: ZonePiece)
		--===============================================================================>
		-- If already destroying, return:
		if self.Destroying == true then return end
		--===============================================================================>
		-- Add the ZonePiece:
		AddZonePiece(self, EngineData, ZonePiece)
		-- Compute the ZoneBox:
		if BoundType ~= 'PerPart' then
			-- Recalculate the Box since a ZonePiece has been added:
			ComputeZoneBox(self, EngineData)
		end
		--===============================================================================>
	end

	function BoundsData.RemoveZonePiece(self: BoundsHandler, ZonePiece: ZonePiece)
		--===============================================================================>
		-- If already destroying, return:
		if self.Destroying == true then return end
		--===============================================================================>
		-- Remove ZonePiece:
		RemoveZonePiece(self, ZonePiece)
		-- Compute the ZoneBox:
		if BoundType ~= 'PerPart' then
			-- Recalculate the Box since a ZonePiece has been removed:
			ComputeZoneBox(self, EngineData)
		end
		--===============================================================================>
	end

	function BoundsData.Relocate(self: BoundsHandler)
		--===============================================================================>
		if self.ZoneBoxData.Container then
			if self.Visible == false then
				-- Parent the Container to Workspace:
				self.ZoneBoxData.Container.Parent = 
					if EngineData.ZoneStates.Relocated then WorldModel:GetWorldModel() else workspace
			end
		else
			-- if already visible and we dont have a container, redo visibility:
			if self.Visible == true then
				self:ToggleVisibility(false)
				self:ToggleVisibility(true)
			end
		end
		--===============================================================================>
	end
	
	--=======================================================================================================>
	-- [ Cleanup Methods ]

	-- Create the Destroy Function:
	function BoundsData.Destroy(self: BoundsHandler)
		--===============================================================================>
		-- If already destroying, return:
		if self.Destroying == true then return end
		--===============================================================================>
		-- Toggle the Visibility to false:
		self:ToggleVisibility(false)
		-- Set Destroying to true:
		self.Destroying = true
		--===============================================================================>
		-- Clear all self.ZonePieces data:
		for Key, Object in self.ZonePieces.ObjectMap   do Object:Destroy() end; table.clear(self.ZonePieces.ObjectMap);
		-- Clear all self.ZonePieces data:
		for Key, Details in self.ZonePieces.DetailsMap do table.clear(Details) end; table.clear(self.ZonePieces.DetailsMap);
		-- Clear all self.ZoneParts data:
		for Key, Object in self.ZoneParts.ObjectMap   do Object:Destroy() end; table.clear(self.ZoneParts.ObjectMap);
		-- Clear all self.ZoneParts data:
		for Key, Details in self.ZoneParts.DetailsMap do table.clear(Details) end; table.clear(self.ZoneParts.DetailsMap);
		--===============================================================================>
		-- Clear all self data:
		for Index, Data in pairs(self) do self[Index] = nil end
		--===============================================================================>
	end

	--=======================================================================================================>
	-- [ Initialization ]

	-- Add all the Pieces to this BoundsHandler:
	for Index: number, ZonePiece in ipairs(EngineData.ZonePieces) do AddZonePiece(BoundsData, EngineData, ZonePiece) end
	
	-- BoundBox only Computation:
	-- Calculate the Box Initially upon Initialization
	if BoundType ~= 'PerPart' then ComputeZoneBox(BoundsData, EngineData) end

	--=======================================================================================================>
	
	-- Return the BoundsHandler Object:
	return BoundsData

	--=======================================================================================================>
end

--=======================================================================================================>

function BoundsHandlers.PerPart.New(EngineData: ZoneEngineData): BoundsHandler
	return BoundsHandler(EngineData, 'PerPart')
end

function BoundsHandlers.BoxExact.New(EngineData: ZoneEngineData): BoundsHandler
	return BoundsHandler(EngineData, 'BoxExact')
end

function BoundsHandlers.BoxVoxel.New(EngineData: ZoneEngineData): BoundsHandler
	return BoundsHandler(EngineData, 'BoxVoxel')
end

--===========================================================================================================================>

-- Freeze subtables:
table.freeze(BoundsHandlers.PerPart)
table.freeze(BoundsHandlers.BoxExact)
table.freeze(BoundsHandlers.BoxVoxel)

--===========================================================================================================================>

-- Return a Frozen Module Table:d
return table.freeze(BoundsHandlers) :: typeof(BoundsHandlers)

--===========================================================================================================================>