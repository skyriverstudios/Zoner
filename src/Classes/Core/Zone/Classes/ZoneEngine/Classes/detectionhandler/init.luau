--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Define Module table
local DetectionHandlerModule: DetectionHandlerModule = {Complex  = {}; Simple = {}; Efficient = {}}

--===========================================================================================================================>
--[ VARIABLES: ]

-- Require the ZoneUtilities Module:
local ZoneUtilities = require(script.Parent.Parent.Parent.Parent.Children.ZoneUtilities);

local Regions = require(script.Parent.Parent.Parent.Parent.Parent.Parent.Utilities.Regions);
local Enums   = require(script.Parent.Parent.Parent.Parent.Parent.Parent.Utilities.Enums).Enums;
local WorldModel = require(script.Parent.Parent.Parent.Parent.Parent.Parent.Core.WorldModel);
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
export type Box_ZonePartDetails     = TypeDefinitions.Box_ZonePartDetails
export type BoundsHandlers          = TypeDefinitions.BoundsHandlers
export type BoundsTypes             = TypeDefinitions.BoundsTypes

-- Make the Module into a Type:
export type DetectionHandlerModule = typeof(DetectionHandlerModule)

--=======================================================================================================>

function DetectionHandlerModule.Efficient.New(ZoneParts: {BasePart}, DetectionMethod: number, Serial: boolean): PerPartBoundsHandler
	--=======================================================================================================>

	-- Define the TargetData and Inherit from the Base Class:
	local BoundsData: PerPartBoundsHandler = {
		--====================================================>

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
		ZonePartDetails.Type = ZoneUtilities:GetZonePartType(Part)
		ZonePartDetails.Size, ZonePartDetails.HalfSize = Part.Size, Part.Size / 2
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
		function ZonePartDetails.ToggleVisibility(self: PerPart_ZonePartDetails, State: boolean)
			--===============================================================================>
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

	--=======================================================================================================>

	function BoundsData.AddZonePart(self: PerPartBoundsHandler, ZonePart: BasePart)
		--===============================================================================>
		-- If already destroying, return:
		if self.Destroying == true then return end
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
		--===============================================================================>
		if self.ZoneParts[ZonePart] then self.ZoneParts[ZonePart]:Destroy() self.ZoneParts[ZonePart] = nil :: any end
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
		-- Loop through all the ZoneParts to toggle their Visibility:
		for Part: BasePart, Details in self.ZoneParts do Details:ToggleVisibility(State) end
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
		-- Clear all self.ZoneParts data:
		for Key, Details in self.ZoneParts do Details:Destroy() end; table.clear(self.ZoneParts);
		--===============================================================================>
		-- Clear all self data:
		for Index, Data in pairs(self) do self[Index] = nil end
		--===============================================================================>
	end

	--=======================================================================================================>

	for Index: number, ZonePart: BasePart in ipairs(ZoneParts) do
		BoundsData.ZoneParts[ZonePart] = BoundsData:_GetZonePartDetails(ZonePart, Serial)
	end

	--=======================================================================================================>

	-- Return the BoundsHandler Object:
	return BoundsData

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Freeze each Sub Table:
table.freeze(DetectionHandlerModule.Efficient)
table.freeze(DetectionHandlerModule.Complex)
table.freeze(DetectionHandlerModule.Simple)

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(DetectionHandlerModule) :: DetectionHandlerModule

--===========================================================================================================================>