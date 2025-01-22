--===========================================================================================================================>
--!optimize 2
--!strict
--===========================================================================================================================>

-- Define Module table
local BoundsHandlerModule: BoundsHandlerModule = {PerPart  = {}; BoxExact = {}; BoxVoxel = {}; BoxDefault = {}}

--===========================================================================================================================>
--[ VARIABLES: ]

-- Require the ZoneUtilities Module:
local ZoneUtilities = require(script:FindFirstAncestor('Zone').Children.ZoneUtilities);

local ZonerModule = script.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent

local WorldModel = require(ZonerModule.Classes.Core.WorldModel);
local Regions    = require(ZonerModule.Classes.Utilities.Regions);
local Enums      = require(ZonerModule.Classes.Utilities.Enums);

-- Import the Shared Types:
local SharedTypes = require(ZonerModule.Types.SharedTypes)

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local TypeDefinitions = require(script.Types)

-- Export the Target Handler Types:
export type BoxExactBoundsHandler = TypeDefinitions.BoxExactBoundsHandler
export type BoxVoxelBoundsHandler = TypeDefinitions.BoxVoxelBoundsHandler
export type PerPartBoundsHandler  = TypeDefinitions.PerPartBoundsHandler
export type BoxBoundsHandler      = TypeDefinitions.BoxBoundsHandler

export type PerPart_ZonePartDetails = TypeDefinitions.PerPart_ZonePartDetails
export type PerPart_ZoneBoxDetails  = TypeDefinitions.PerPart_ZoneBoxDetails
export type Box_ZonePartDetails     = TypeDefinitions.Box_ZonePartDetails
export type BoundsHandlers          = TypeDefinitions.BoundsHandlers
export type BoundsTypes             = TypeDefinitions.BoundsTypes
export type DefaultHandler          = TypeDefinitions.DefaultHandler

export type ZoneDetailBoxes         = TypeDefinitions.ZoneDetailBoxes
export type ZoneDetailParts         = TypeDefinitions.ZoneDetailParts
export type ZoneDetailPieces        = TypeDefinitions.ZoneDetailPieces

export type ZonePartDetails         = TypeDefinitions.ZonePartDetails

export type ZoneBoxPartDetails      = TypeDefinitions.ZoneBoxPartDetails


export type ZonePieces              = SharedTypes.ZonePieces
export type ZoneBoxes               = SharedTypes.ZoneBoxes
export type ZoneParts               = SharedTypes.ZoneParts

-- Make the Module into a Type:
export type BoundsHandlerModule = typeof(BoundsHandlerModule)

--=======================================================================================================>

function BoundsHandlerModule.PerPart.New(ZonePieces: ZonePieces, PieceType: 'Part'|'Box', DetectionMethod: number, Id: string, Serial: boolean): PerPartBoundsHandler
	--=======================================================================================================>

	-- Define the TargetData and Inherit from the Base Class:
	local BoundsData: PerPartBoundsHandler = {
		--====================================================>
		BoundsType = 'PerPart';
		Destroying = false;
		Visible    = false;
		Relocated  = false;
		_Id        = Id;
		--====================================================>
		_DetectionMethod = DetectionMethod;
		--====================================================>
		-- ZonePartDetails Dictionary:
		ZoneBoxes = if PieceType == 'Box'  then {} else nil;
		ZoneParts = if PieceType == 'Part' then {} else nil;
		--====================================================>
		-- Dictionary storing Data related to the Box that makes up the Zone:
		ZoneBoxData = {
			-- Reference to the Container Instance:
			Container = nil;
		};
		--====================================================>
		-- Events Dictionary:
		_Events  = {};
		--====================================================>
	} :: PerPartBoundsHandler

	--=======================================================================================================>

	function BoundsData._GetZonePartDetails(self: PerPartBoundsHandler, Part: BasePart, Serial: boolean): PerPart_ZonePartDetails
		--===============================================================================>
		-- Define the ZonePartProperties Dictionary:
		local ZonePartDetails: PerPart_ZonePartDetails = {} :: PerPart_ZonePartDetails

		--=======================================================================================>

		ZonePartDetails.Part = Part;

		-- Set the ZonePart Type of Block:
		ZonePartDetails.Type = Regions:GetPartType(Part)
		ZonePartDetails.Size, ZonePartDetails.HalfSize = Part.Size, Part.Size / 2

		ZonePartDetails.Radius = if ZonePartDetails.Type == 'Sphere' then ZonePartDetails.Size.X / 2 else nil

		ZonePartDetails.Anchored = Part.Anchored
		ZonePartDetails.Serial = Serial;

		ZonePartDetails._Events = {} :: any;

		--=======================================================================================>

		ZonePartDetails._Events.SizeChanged = 
			if Serial then Part:GetPropertyChangedSignal('Size'):Connect(function() ZonePartDetails:OnSizeChanged() end)
			else Part:GetPropertyChangedSignal('Size'):ConnectParallel(function() ZonePartDetails:OnSizeChanged() end)

		ZonePartDetails._Events.AnchoredChanged = 
			if Serial then Part:GetPropertyChangedSignal('Anchored'):Connect(function() ZonePartDetails:OnAnchoredChanged() end)
			else Part:GetPropertyChangedSignal('Anchored'):ConnectParallel(function() ZonePartDetails:OnAnchoredChanged() end)


		if Part.Anchored == true then

			ZonePartDetails._Events.CFrameChanged = 
				if Serial then Part:GetPropertyChangedSignal('CFrame'):Connect(function() ZonePartDetails:OnCFrameChanged() end)
				else Part:GetPropertyChangedSignal('CFrame'):ConnectParallel(function() ZonePartDetails:OnCFrameChanged() end)

			ZonePartDetails.CFrame = Part.CFrame
		end

		--=======================================================================================>

		-- Callback Method for Size Property Changing:
		function ZonePartDetails.OnSizeChanged(self: PerPart_ZonePartDetails)
			--===============================================================================>
			self.Size, self.HalfSize = self.Part.Size, self.Part.Size / 2
			--===============================================================================>
		end

		-- Callback Method for CFrame Property Changing:
		function ZonePartDetails.OnCFrameChanged(self: PerPart_ZonePartDetails)
			--===============================================================================>
			self.CFrame = self.Part.CFrame
			--===============================================================================>
		end

		-- Callback Method for Anchored Property Changing:
		function ZonePartDetails.OnAnchoredChanged(self: PerPart_ZonePartDetails)
			--===============================================================================>
			self.Anchored, self.CFrame = self.Part.Anchored, nil :: any

			if self._Events.CFrameChanged then
				self._Events.CFrameChanged:Disconnect()
				self._Events.CFrameChanged = nil :: any
			end

			if self.Part.Anchored == true then
				if self.Serial then
					self._Events.CFrameChanged = self.Part:GetPropertyChangedSignal('CFrame'):Connect(function() 
						self.CFrame = self.Part.CFrame
					end);
				else
					self._Events.CFrameChanged = self.Part:GetPropertyChangedSignal('CFrame'):ConnectParallel(function() 
						self.CFrame = self.Part.CFrame 
					end);
				end
				self.CFrame = self.Part.CFrame
			end
			--===============================================================================>
		end

		-- Callback Method for Anchored Property Changing:
		function ZonePartDetails.ToggleVisibility(self: PerPart_ZonePartDetails, State: boolean, Container: Model?)
			--===============================================================================>
			if State == true then
				self:ToggleVisibility(false)

				self.VisibilityData = {
					Highlight            = Instance.new('Highlight');
					PreviousMaterial     = self.Part.Material;
					PreviousTransparency = self.Part.Transparency;
				}


				self.Part.Transparency = 1
				self.Part.Material = Enum.Material.Glass
				if self.VisibilityData then
					self.VisibilityData.Highlight.Adornee = self.Part
					self.VisibilityData.Highlight.Parent = self.Part
					self.VisibilityData.Highlight.Enabled = true
					self.VisibilityData.Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
					self.VisibilityData.Highlight.FillColor = Color3.fromRGB(0,0,0)
					self.VisibilityData.Highlight.FillTransparency = 1

					self.VisibilityData.Highlight.OutlineColor = Color3.fromRGB(7, 127, 255)
				end
				
				
				-- If the Container is passed, make a clone of the part and parent it:
				if Container then 
					local ClonedPart = self.Part:Clone()
					for Index: number, Tag: string in ipairs(ClonedPart:GetTags()) do ClonedPart:RemoveTag(Tag) end
					ClonedPart.Parent = Container
				end
				
			else
				if self.VisibilityData then 

					-- Set Part back to Previous Material:
					self.Part.Material     = self.VisibilityData.PreviousMaterial
					-- Set Part back to Previous Transparency:
					self.Part.Transparency = self.VisibilityData.PreviousTransparency

					self.VisibilityData.Highlight:Destroy()
					self.VisibilityData.Highlight = nil  :: any

					self.VisibilityData.PreviousMaterial     = nil :: any
					self.VisibilityData.PreviousTransparency = nil :: any

					self.VisibilityData = nil
				end
			end
			--===============================================================================>
		end

		-- Destroy Method for easy Destroyin:
		function ZonePartDetails.Destroy(self: PerPart_ZonePartDetails)
			--===============================================================================>
			-- If a VisibilityData table exists, clear its variables:
			-- Toggle it to false, clearing its Data:
			self:ToggleVisibility(false)
			--===============================================================================>
			-- Disconnect all Events in Events table:
			for Key, Connection in pairs(self._Events) do Connection:Disconnect() end
			-- Clear Events Table:
			table.clear(self._Events)
			--===============================================================================>
		end

		--=======================================================================================>

		-- Return the ZonePartDetails Dictionary:
		return ZonePartDetails
		--===============================================================================>
	end

	function BoundsData._GetZoneBoxDetails(self: PerPartBoundsHandler, Box: {CFrame: CFrame, Size: Vector3}, Serial: boolean): PerPart_ZoneBoxDetails
		--===============================================================================>
		-- Define the ZonePartProperties Dictionary:
		local ZoneBoxDetails: PerPart_ZoneBoxDetails = {
			Type = 'Block';
			Size = Box.Size;
			HalfSize = Box.Size/2;
			CFrame = Box.CFrame;
		} :: PerPart_ZoneBoxDetails

		--=======================================================================================>

		-- Callback Method for Anchored Property Changing:
		function ZoneBoxDetails.ToggleVisibility(self: PerPart_ZoneBoxDetails, State: boolean)
			--===============================================================================>
			if true then return end
			--[[
		
			if State == true then
				self:ToggleVisibility(false)

				self.VisibilityData = {
					Highlight            = Instance.new('Highlight');
					PreviousMaterial     = Part.Material;
					PreviousTransparency = Part.Transparency;
				}

				Part.Transparency = 1
				Part.Material = Enum.Material.Glass
				if self.VisibilityData then
					self.VisibilityData.Highlight.Adornee = Part
					self.VisibilityData.Highlight.Parent = Part
					self.VisibilityData.Highlight.Enabled = true
					self.VisibilityData.Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
					self.VisibilityData.Highlight.FillColor = Color3.fromRGB(0,0,0)
					self.VisibilityData.Highlight.FillTransparency = 1

					self.VisibilityData.Highlight.OutlineColor = Color3.fromRGB(7, 127, 255)
				end
			else
				if self.VisibilityData then 

					-- Set Part back to Previous Material:
					self.Part.Material     = self.VisibilityData.PreviousMaterial
					-- Set Part back to Previous Transparency:
					self.Part.Transparency = self.VisibilityData.PreviousTransparency

					self.VisibilityData.Highlight:Destroy()
					self.VisibilityData.Highlight = nil  :: any

					self.VisibilityData.PreviousMaterial     = nil :: any
					self.VisibilityData.PreviousTransparency = nil :: any

					self.VisibilityData = nil
				end
			end
			--]]
			--===============================================================================>
		end

		-- Destroy Method for easy Destroyin:
		function ZoneBoxDetails.Destroy(self: PerPart_ZoneBoxDetails)
			--===============================================================================>
			-- If a VisibilityData table exists, clear its variables:
			-- Toggle it to false, clearing its Data:
			self:ToggleVisibility(false)
			--===============================================================================>
		end

		--=======================================================================================>

		-- Return the ZonePartDetails Dictionary:
		return ZoneBoxDetails
		--===============================================================================>
	end

	function BoundsData._ClearVisibleContainer(self: PerPartBoundsHandler)
		--===============================================================================>
		if not self.ZoneBoxData.Container then return end
		--===============================================================================>
		self.ZoneBoxData.Container:Destroy()
		self.ZoneBoxData.Container = nil
		--===============================================================================>
	end

	function BoundsData._MakeVisibleContainer(self: PerPartBoundsHandler)
		--===============================================================================>
		if self.ZoneBoxData.Container then return end
		--===============================================================================>
		-- Create a Relocation Container Folder:
		self.ZoneBoxData.Container = Instance.new("Model")
		-- If the Container Exists, cause of Type Checking..
		if self.ZoneBoxData.Container then
			self.ZoneBoxData.Container.Name = `{self._Id}:PerPar-Visibility-Container`
			self.ZoneBoxData.Container.Parent = workspace
			self.ZoneBoxData.Container.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		end
		--===============================================================================>
	end

	--=======================================================================================================>

	-- Return the ZonePieces Table:
	function BoundsData.GetZonePieces(self: PerPartBoundsHandler): ZoneDetailPieces
		--===============================================================================>
		return if self.ZoneParts then self.ZoneParts elseif self.ZoneBoxes then self.ZoneBoxes else nil :: any
		--===============================================================================>
	end

	-- Return the ZoneParts Table:
	function BoundsData.GetZoneParts(self: PerPartBoundsHandler): {[BasePart]: ZonePartDetails}
		--===============================================================================>
		return if self.ZoneParts then self.ZoneParts elseif self.ZoneBoxes then self.ZoneBoxes else nil :: any
		--===============================================================================>
	end
	-- Return the ZoneBoxes Table:
	function BoundsData.GetZoneBoxes(self: PerPartBoundsHandler): ZoneDetailBoxes
		--===============================================================================>
		return if self.ZoneParts then self.ZoneParts elseif self.ZoneBoxes then self.ZoneBoxes else nil :: any
		--===============================================================================>
	end

	function BoundsData.AddZonePart(self: PerPartBoundsHandler, ZonePart: BasePart)
		--===============================================================================>
		-- If already destroying, return:
		if self.Destroying == true then return end
		-- If there is no ZoneParts return:
		if not self.ZoneParts then return end
		--===============================================================================>
		-- If the ZonePart exists already in the table for some reason, Remove it first:
		if self.ZoneParts[ZonePart] then self:RemoveZonePart(ZonePart) end
		-- Add the ZonePart Details to the Dictionary with the Return Value:
		self.ZoneParts[ZonePart] = self:_GetZonePartDetails(ZonePart, Serial)
		-- Toggle Visibility on the Zone if the ZoneBounds Visibility is set to true:
		self.ZoneParts[ZonePart]:ToggleVisibility(self.Visible)
		--===============================================================================>
	end

	function BoundsData.RemoveZonePart(self: PerPartBoundsHandler, ZonePart: BasePart)
		--===============================================================================>
		-- If already destroying, return:
		if self.Destroying == true then return end
		-- If there is no ZoneParts return:
		if not self.ZoneParts then return end
		--===============================================================================>
		if self.ZoneParts[ZonePart] then self.ZoneParts[ZonePart]:Destroy(); self.ZoneParts[ZonePart] = nil :: any; end
		--===============================================================================>
	end

	function BoundsData.ToggleVisibility(self: PerPartBoundsHandler, State: boolean)
		--===============================================================================>
		if self.Visible == false and State == false then return end
		if self.Visible == true  and State == true then return end
		-- If already destroying, return:
		if self.Destroying == true then return end
		--===============================================================================>
		
		-- Set the Visible Status of the Bounds to the passed boolean:
		self.Visible = State
		
		-- If the State is true, and the Container is reloacted, create a Visible workspace version:
		if State == true and self.Relocated == true then self:_MakeVisibleContainer() end
		
		-- Loop through all the ZoneParts to toggle their Visibility:
		if self.ZoneParts then for Part: BasePart, Details in self.ZoneParts do Details:ToggleVisibility(State, self.ZoneBoxData.Container) end; end
		
		-- If the State is false, and the Container is Relocated, then Clear the Visible Version:
		if State == false and self.Relocated == true then self:_ClearVisibleContainer() end

		--===============================================================================>
	end

	-- Create the Destroy Function:
	function BoundsData.Destroy(self: PerPartBoundsHandler)
		--===============================================================================>
		-- If already destroying, return:
		if self.Destroying == true then return end
		--===============================================================================>
		-- Toggle the Visibility to false:
		self:ToggleVisibility(false)
		-- Set Destroying to true:
		self.Destroying = true
		--===============================================================================>
		if self.ZoneParts then
			-- Clear all self.ZoneParts data:
			for Key, Details in self.ZoneParts  do Details:Destroy() end; table.clear(self.ZoneParts);
		elseif self.ZoneBoxes then
			-- Clear all self.ZoneBoxes data:
			for Key, Details in self.ZoneBoxes  do Details:Destroy() end; table.clear(self.ZoneBoxes);
		end
		--===============================================================================>
		-- Clear all self data:
		for Index, Data in pairs(self) do self[Index] = nil end
		--===============================================================================>
	end

	--=======================================================================================================>

	if PieceType == 'Box' and BoundsData.ZoneBoxes then
		for Index: number, ZoneBox: {CFrame: CFrame, Size: Vector3} in ipairs(ZonePieces :: ZoneBoxes) do
			BoundsData.ZoneBoxes[ZoneBox] = BoundsData:_GetZoneBoxDetails(ZoneBox, Serial)
		end
	elseif PieceType == 'Part' and BoundsData.ZoneParts then
		for Index: number, ZonePart: BasePart in ipairs(ZonePieces :: any) do
			BoundsData.ZoneParts[ZonePart] = BoundsData:_GetZonePartDetails(ZonePart, Serial)
		end
	end

	--=======================================================================================================>

	-- Return the BoundsHandler Object:
	return BoundsData

	--=======================================================================================================>
end

function BoundsHandlerModule.BoxExact.New(ZonePieces: ZonePieces, PieceType: 'Part'|'Box', DetectionMethod: number, Id: string, Serial: boolean): BoxExactBoundsHandler
	return BoundsHandlerModule.BoxDefault.New(ZonePieces, PieceType, DetectionMethod, Serial, Id, false)
end

function BoundsHandlerModule.BoxVoxel.New(ZonePieces: ZonePieces, PieceType: 'Part'|'Box', DetectionMethod: number, Id: string, Serial: boolean): BoxVoxelBoundsHandler
	return BoundsHandlerModule.BoxDefault.New(ZonePieces, PieceType, DetectionMethod, Serial, Id, true)
end

--=======================================================================================================>

function BoundsHandlerModule.BoxDefault.New(ZonePieces: ZonePieces, PieceType: 'Part'|'Box', DetectionMethod: number, Serial: boolean, Id: string, Voxel: boolean): BoxBoundsHandler
	--=======================================================================================================>

	-- Define the TargetData and Inherit from the Base Class:
	local BoundsData: BoxBoundsHandler = {
		--====================================================>
		BoundsType = if Voxel then 'BoxVoxel' else 'BoxExact';
		Destroying = false;
		Visible    = false;
		Relocated  = false;
		Serial     = Serial;
		_Id        = Id;
		--====================================================>
		CFrame   = nil :: any;
		Size     = nil :: any;
		HalfSize = nil :: any;
		Volume   = nil :: any;
		--====================================================>
		_DetectionMethod = DetectionMethod;
		--====================================================>
		-- Store a reference to the ZoneEngine's ZoneParts Array so that it can be updated for us:
		_ZonePartsArray = if PieceType == 'Part' then ZonePieces else nil :: any;
		_ZoneBoxesArray = if PieceType == 'Box'  then ZonePieces else nil :: any;
		-- ZonePartDetails Dictionary:
		ZoneBoxes = if PieceType == 'Box'  then {} else nil :: any;
		ZoneParts = if PieceType == 'Part' then {} else nil :: any;
		-- Dictionary storing Data related to the Box that makes up the Zone:
		ZoneBoxData = {
			-- Array of Part(s) (most likely will only ever be one unless zone is bigger than 2048 studs) that are under the container:
			Parts = {};
			-- Reference to the Highlight that is on the Container:
			Highlight = nil;
			-- Reference to the Container Instance:
			Container = nil;
			-- Whether a Box Part will be made in reference to the Region:
			Need = DetectionMethod == Enums.Enums.DetectionMethod.Complex;
		}
		--====================================================>
	} :: BoxBoundsHandler

	--=======================================================================================================>

	function BoundsData._GetZonePartDetails(self: BoxBoundsHandler, Part: BasePart): Box_ZonePartDetails
		--=======================================================================================>

		-- Define the ZonePartProperties Dictionary:
		local ZonePartDetails: Box_ZonePartDetails = {} :: Box_ZonePartDetails

		ZonePartDetails.OriginalTransparency = Part.Transparency

		ZonePartDetails._Events = {
			SizeChanged = 
				if self.Serial then Part:GetPropertyChangedSignal('Size'):Connect(function() self:_CalculateBox() end)
				else Part:GetPropertyChangedSignal('Size'):ConnectParallel(function() self:_CalculateBox() end);

			CFrameChanged = 
				if self.Serial then Part:GetPropertyChangedSignal('CFrame'):Connect(function() self:_CalculateBox() end)
				else Part:GetPropertyChangedSignal('CFrame'):ConnectParallel(function() self:_CalculateBox() end)
		};

		--=======================================================================================>

		-- Destroy Method for easy Destroyin:
		function ZonePartDetails.Destroy(self: Box_ZonePartDetails)
			--===============================================================================>
			-- Disconnect all Events in Events table:
			for Key, Connection in pairs(self._Events) do Connection:Disconnect() end
			-- Clear Events Table:
			table.clear(self._Events)
			--===============================================================================>
		end

		--=======================================================================================>

		-- Return the ZonePartDetails Dictionary:
		return ZonePartDetails

		--=======================================================================================>
	end

	function BoundsData._CalculateBox(self: BoxBoundsHandler)
		--===============================================================================>

		-- Store the Previous Region Size:
		local PreviousSize: Vector3 = self.Size

		--===============================================================================>

		if self._ZonePartsArray then
		
			if #self._ZonePartsArray < 1 then return end

			if #self._ZonePartsArray <= 1 and self.BoundsType ~= 'BoxVoxel' then
				self.CFrame, self.Size = self._ZonePartsArray[1].CFrame, self._ZonePartsArray[1].Size
			else
				self.CFrame, self.Size = 
					Regions:GetBoundingCFrameAndSize(self._ZonePartsArray, self.BoundsType == 'BoxVoxel')
			end
			
		elseif self._ZoneBoxesArray then
			
			if #self._ZoneBoxesArray <= 1 and self.BoundsType ~= 'BoxVoxel' then
				self.CFrame, self.Size = self._ZoneBoxesArray[1].CFrame, self._ZoneBoxesArray[1].Size
			else
				self.CFrame, self.Size = 
					Regions:GetBoundingCFrameAndSize(self._ZoneBoxesArray, self.BoundsType == 'BoxVoxel')
			end
		
		end

		--===============================================================================>

		-- Set the HalfSize:
		self.HalfSize = self.Size / 2

		-- Calculate the Volume of the Region Via the Rounded Region's Size:
		self.Volume = self.Size.X * self.Size.Y * self.Size.Z
		--===============================================================================>
		-- If a BoxPart exists, update its CFrame and Size:
		if self.ZoneBoxData.Container then

			if PreviousSize == self.Size then
				if self.Serial then 
					self.ZoneBoxData.Container:PivotTo(self.CFrame)
				else 
					task.defer(function() 
						task.synchronize() 
						self.ZoneBoxData.Container:PivotTo(self.CFrame)
					end) 
				end		
			else
				if self.Serial then 
					local Visibility = self.Visible
					if Visibility then self:ToggleVisibility(false) end

					self:_ClearBoxPart()
					self:_MakeBoxPart()

					if Visibility then self:ToggleVisibility(true) end

				else 
					task.defer(function() 
						task.synchronize() 

						local Visibility = self.Visible
						if Visibility then self:ToggleVisibility(false) end

						self:_ClearBoxPart()
						self:_MakeBoxPart()

						if Visibility then self:ToggleVisibility(true) end

					end) 
				end		
			end
		elseif self.ZoneBoxData.Need then
			if self.Serial then 
				self:_MakeBoxPart() 
			else 
				task.defer(function() task.synchronize(); self:_MakeBoxPart(); end) 
			end		
		end
		--===============================================================================>
	end

	function BoundsData._ClearBoxPart(self: BoxBoundsHandler)
		--===============================================================================>
		if not self.ZoneBoxData.Container then return end
		--===============================================================================>
		if self.ZoneBoxData.Highlight then
			self.ZoneBoxData.Highlight:Destroy()
			self.ZoneBoxData.Highlight = nil
		end

		self.ZoneBoxData.Container:Destroy()
		self.ZoneBoxData.Container = nil

		-- Clear the ZoneBoxData Parts Array:
		table.clear(self.ZoneBoxData.Parts)

		--===============================================================================>
	end

	function BoundsData._MakeBoxPart(self: BoxBoundsHandler)
		--===============================================================================>
		if self.ZoneBoxData.Container then return end
		--===============================================================================>
		-- Create a Relocation Container Folder:
		self.ZoneBoxData.Container = Instance.new("Model")
		-- If the Container Exists, cause of Type Checking..
		if self.ZoneBoxData.Container then
			self.ZoneBoxData.Container.Name = `{self._Id}:BoxPartContainer`
			self.ZoneBoxData.Container.Parent = WorldModel:GetWorldModel()
			self.ZoneBoxData.Container.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
			-- Create a Cube of Parts inside the Zone matching the CFrame and Size:
			Regions:CreateCube(self.ZoneBoxData.Container, self.CFrame, self.Size)

			-- Clear the ZoneBoxData Parts Array:
			table.clear(self.ZoneBoxData.Parts)
			-- Grab the Children of the Container: (should be 1 part if size < 2048)
			local ContainerChildren: {BasePart} = self.ZoneBoxData.Container:GetChildren()
			-- Loop through the ContainerChildren Array and Add each BasePart to the Parts Array:
			for Index: number, Part: BasePart in ipairs(ContainerChildren) do 
				self.ZoneBoxData.Parts[Part] = {Part = Part, Type = 'Block'; CFrame = Part.CFrame, Size = Part.Size, HalfSize = Part.Size/2}
			end
			-- Clear the variable:
			ContainerChildren = nil :: any
		end
		--===============================================================================>
	end

	--=======================================================================================================>

	-- Callback Method for Anchored Property Changing:
	function BoundsData.ToggleVisibility(self: BoxBoundsHandler, State: boolean)
		--===============================================================================>
		if self.Visible == false and State == false then return end
		if self.Visible == true  and State == true then return end
		--===============================================================================>
		-- If already destroying, return:
		if self.Destroying == true then return end
		--===============================================================================>

		if State == true then
			self:ToggleVisibility(false)

			self:_MakeBoxPart()


			self.ZoneBoxData.Container.Parent = workspace

			for Index: number, Part in ipairs(self.ZoneBoxData.Container:GetChildren()) do 
				if not Part:IsA('BasePart') then continue end
				Part.Material = Enum.Material.Glass
			end

			self.ZoneBoxData.Highlight = Instance.new('Highlight');

			self.ZoneBoxData.Highlight.Parent = self.ZoneBoxData.Container
			self.ZoneBoxData.Highlight.Enabled = true
			self.ZoneBoxData.Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			self.ZoneBoxData.Highlight.FillColor = Color3.fromRGB(0,0,0)
			self.ZoneBoxData.Highlight.FillTransparency = 1

			self.ZoneBoxData.Highlight.OutlineColor = Color3.fromRGB(7, 127, 255)

			if self.ZoneParts then
				for ZonePart, Details in self.ZoneParts do
					ZonePart.Transparency = 1
				end
			end


		else
			if self.ZoneBoxData.Need then 
				self.ZoneBoxData.Container.Parent = WorldModel:GetWorldModel()

				for Index: number, Part in ipairs(self.ZoneBoxData.Container:GetChildren()) do
					if not Part:IsA('BasePart') then continue end
					Part.Material = Enum.Material.SmoothPlastic
				end

			else
				self:_ClearBoxPart() 
			end


			if self.ZoneBoxData.Highlight then
				self.ZoneBoxData.Highlight:Destroy()
				self.ZoneBoxData.Highlight = nil  :: any
			end

			if self.ZoneParts then
				for ZonePart, Details in self.ZoneParts do
					ZonePart.Transparency = Details.OriginalTransparency
				end
			end



		end

		-- Set the Visible Status of the Bounds to the passed boolean:
		self.Visible = State

		--===============================================================================>
	end

	-- Return the ZonePieces Table:
	function BoundsData.GetZonePieces(self: BoxBoundsHandler): ZoneBoxPartDetails
		--===============================================================================>
		return if self.ZoneBoxData.Parts then self.ZoneBoxData.Parts else {}
		--===============================================================================>
	end
	
	-- Return the ZoneParts Table:
	function BoundsData.GetZoneParts(self: BoxBoundsHandler): {[BasePart]: ZonePartDetails}
		--===============================================================================>
		return if self.ZoneBoxData.Parts then self.ZoneBoxData.Parts else {}
		--===============================================================================>
	end
	-- Return the ZoneBoxes Table:
	function BoundsData.GetZoneBoxes(self: BoxBoundsHandler): ZoneDetailBoxes
		--===============================================================================>
		return if self.ZoneParts then self.ZoneParts elseif self.ZoneBoxes then self.ZoneBoxes else nil :: any
		--===============================================================================>
	end

	--=======================================================================================================>

	function BoundsData.AddZonePart(self: BoxBoundsHandler, ZonePart: BasePart)
		--===============================================================================>
		-- If already destroying, return:
		if self.Destroying == true then return end
		-- If there is No ZoneParts table return:
		if not self.ZoneParts then return end
		--===============================================================================>
		-- If the ZonePart exists already in the table for some reason, Remove it first:
		if self.ZoneParts[ZonePart] then self:RemoveZonePart(ZonePart) end
		-- Add the ZonePart Details to the Dictionary with the Return Value:
		self.ZoneParts[ZonePart] = self:_GetZonePartDetails(ZonePart)
		--===============================================================================>
		-- Recalculate the Box since a ZonePart has been added:
		self:_CalculateBox()
		--===============================================================================>
	end

	function BoundsData.RemoveZonePart(self: BoxBoundsHandler, ZonePart: BasePart)
		--===============================================================================>
		-- If already destroying, return:
		if self.Destroying == true then return end
		-- If there is No ZoneParts table return:
		if not self.ZoneParts then return end
		--===============================================================================>
		-- If the ZonePart Details Object exists, Destroy and set the ZonePart to nil:
		if self.ZoneParts[ZonePart] then self.ZoneParts[ZonePart]:Destroy(); self.ZoneParts[ZonePart] = nil :: any; end
		--===============================================================================>
		-- Recalculate the Box since a ZonePart has left:
		self:_CalculateBox()
		--===============================================================================>
	end

	--=======================================================================================================>

	-- Create the Destroy Function:
	function BoundsData.Destroy(self: BoxBoundsHandler)
		--===============================================================================>
		-- If already destroying, return:
		if self.Destroying == true then return end
		--===============================================================================>
		-- Set Destroying to true:
		self.Destroying = true
		-- Toggle the Visibility to false:
		self:ToggleVisibility(false)
		--===============================================================================>
		-- If there is No ZoneParts table return:
		if self.ZoneParts then
			-- Clear all self.ZoneParts data:
			for Key, Details in self.ZoneParts do Details:Destroy() end; table.clear(self.ZoneParts);
		end
		--===============================================================================>
		-- Clear all self data:
		for Index, Data in pairs(self) do self[Index] = nil end
		--===============================================================================>
	end

	--=======================================================================================================>

	-- Initilization:
	do
		--===============================================================================>
		-- Loop through all the Passed ZoneParts and Add each to the Internal Data:
		if PieceType == 'Part' and BoundsData.ZoneParts then
			for Index: number, ZonePart: BasePart in ipairs(ZonePieces :: any) do
				BoundsData:AddZonePart(ZonePart) 
			end
		end
		-- Calculate the Box Initially upon Initialization:
		BoundsData:_CalculateBox()
		--===============================================================================>
	end

	--=======================================================================================================>

	-- Return the BoundsHandler Object:
	return BoundsData

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Freeze each Sub Table:
table.freeze(BoundsHandlerModule.BoxDefault)
table.freeze(BoundsHandlerModule.BoxExact)
table.freeze(BoundsHandlerModule.BoxVoxel)
table.freeze(BoundsHandlerModule.PerPart)

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(BoundsHandlerModule) :: BoundsHandlerModule

--===========================================================================================================================>