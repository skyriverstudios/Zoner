--===========================================================================================================================>
--!strict
--===========================================================================================================================>
-- TrackedItem

-- Author:
-- IISato

-- 7/31/2024
--===========================================================================================================================>

-- Define Module table:
local TargetTrackerModule = {} -- :: TargetTrackerModule
-- Set the MetaIndex:
TargetTrackerModule.__index = TargetTrackerModule

--===========================================================================================================================>

-- Reference the Top Level Module so that we can easily Index our Modules
-- Use direct parenting instead of Ancestor in case someone changes the Module's name:
local ZonerModule = script.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent

-- Require the Trove Module for Cleanup:
local Utility = require(ZonerModule.Classes.Utilities.Utility);
-- Require the Enum2 Module for Custom Enums:
local Enums   = require(ZonerModule.Classes.Utilities.Enums);
-- Require the Trove Module for Cleanup:
local Trove   = require(ZonerModule.Classes.Utilities.Trove);

-- Require the Trove Module for Cleanup:
local Regions = require(ZonerModule.Classes.Utilities.Regions);

-- Require the Trove Module for Cleanup:
local Constants = require(ZonerModule.Children.Constants);
-- Require the Trove Module for Cleanup:
local WorldModel = require(ZonerModule.Classes.Core.WorldModel);

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local TypeDefinitions = require(script.Types)

-- Insert Object type:
export type TargetTrackerMetaData = TypeDefinitions.TargetTrackerMetaData
export type TargetTrackerModule   = typeof(TargetTrackerModule)
export type TargetTracker         = TypeDefinitions.TargetTracker

export type TrackableInstance     = TypeDefinitions.TrackableInstance
export type ZonePartDetails       = TypeDefinitions.ZonePartDetails

type ZoneParts = {[BasePart]: ZonePartDetails}
--===========================================================================================================================>
--[ CONSTRUCTOR FUNCTIONS: ]


-- @Public
-- Constructor Function for this individual object:
function TargetTrackerModule.New<TrackableInstance>(Item: TrackableInstance, DetectionCoverage: number?, DetectionMode: number?): TargetTracker
	--=======================================================================================================>
	-- Assert that the Trackable Item must be an Instance:
	assert(typeof(Item) == "Instance",                                Constants.Logs.Tracker.ItemType)
	-- Assert the Specifics of the Instance Type:
	assert(Item:IsA('BasePart') == true or Item:IsA('Model') == true, Constants.Logs.Tracker.InstanceType)
	-- Assert that the Accuracy Number sent is the right Enum value:
	--assert((Detection == nil or (math.floor(Detection) >= 1 and math.floor(Detection) <= 12)), Constants.Logs.Tracker.DetectionCoverage)
	--=======================================================================================================>

	-- Set a Memory Category for this Zoner:
	debug.setmemorycategory('Zoner: TrackedItem')

	--=======================================================================================================>

	-- Define Enum2 Data
	local ItemTrackerData: TargetTrackerMetaData = {
		--==========================>
		_Item = Item;
		--==========================>
		_Trove = Trove.New();
		--==========================>
		_IsAModel = Item:IsA('Model');
		--==========================>
		_Parts = {};
		_PartsArray = {};
		_NumberOfParts = 0;
		--==========================>
		_CenterPart = false :: any;
		--==========================>
		InZone = false;
		--==========================>
		-- Set Default Detection to Center:
		_DetectionCoverage = DetectionCoverage or Enums.Enums.DetectionCoverage.Center;
		_DetectionMode     = DetectionMode or Enums.Enums.DetectionMode.Point;
		--==========================>
	} :: TargetTrackerMetaData

	--=======================================================================================================>

	-- Set Metatable to the MetaTable and the current Enum2Table:
	setmetatable(ItemTrackerData, TargetTrackerModule)

	-- Initialize the Object:
	ItemTrackerData:_Initialize()

	--=======================================================================================================>

	-- Return the MetaTable Data
	return ItemTrackerData

	--=======================================================================================================>
end

-- @Public
-- Destroyer Function which clears the entirity of the Data for the Object:
function TargetTrackerModule.Destroy(self: TargetTracker)
	--=======================================================================================================>

	if self._Trove then self._Trove:Destroy() end

	-- Clear all self data:
	for Index, Data in pairs(self) do self[Index] = nil end

	-- Set the Metatable to nil
	setmetatable(self :: any, nil)	

	--=======================================================================================================>
end

--===========================================================================================================================>
--[ METHODS: ]


-- @Private
-- Initialization function to start/setup the Object's initial data:
function TargetTrackerModule._Initialize(self: TargetTracker)
	for Index: number, Function: string in ipairs({'_SetData', '_SetEvents'}) do self[Function](self) end
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function TargetTrackerModule._SetData(self: TargetTracker)
	--=======================================================================================================>


	if self._IsAModel then
		--============================================================================================>

		local ModelDescendants: {Instance} = self._Item:GetDescendants()

		for Index: number, Child: Instance in ipairs(ModelDescendants) do self:_AddPart(Child) end

		-- Clear Variable:
		ModelDescendants = nil :: any

		--============================================================================================>
	else
		--============================================================================================>

		self._Parts[self._Item :: BasePart] = Regions:GetPartDetails(self._Item :: BasePart)

		table.insert(self._PartsArray, self._Item :: BasePart)
		--============================================================================================>
	end


	self._NumberOfParts = #self._PartsArray

	self._CenterPart = self:_GetCenterPart()


	--local FilterDescendants: {BasePart} = self:_GetFilterDescendants(self._Parts)

	--self._OverlapParamaters = OverlapParams.new()
	--self._OverlapParamaters.FilterDescendantsInstances = FilterDescendants
	--self._OverlapParamaters.FilterType = Enum.RaycastFilterType.Include
	--self._OverlapParamaters.MaxParts   = #FilterDescendants

	--self._RaycastParamaters = RaycastParams.new()
	--self._RaycastParamaters.FilterDescendantsInstances = FilterDescendants
	--self._RaycastParamaters.FilterType = Enum.RaycastFilterType.Include


	----self._Trove:Connect(self._Item.AncestryChanged, function()
	----	if not self._Item:IsDescendantOf(game) then
	----		if self._Item.Parent == nil then self._Trove:Destroy() end
	----	end
	----end)


	--print('Detection Before:', Enums.Enums.DetectionCoverage:GetName(self._DetectionCoverage))

	-- Set the new Detection in the Setting Table:
	-- If the Detection is Automatic, calculate what Detection the Item should have Automatically:
	self:SetDetection(self:_GetDetections())

	--print('Detection After:', Enums.Enums.DetectionCoverage:GetName(self._DetectionCoverage))

	--=======================================================================================================>
end


-- @Private
-- Initialization function to start/setup the Object's initial data:
function TargetTrackerModule._AddPart(self: TargetTracker, Part: BasePart)
	--=======================================================================================================>
	if not Part:IsA('BasePart') then return end
	if not self:_IsPartValidForItem(Part) then return end
	if self._Parts[Part] then return end
	--=======================================================================================================>

	self._Parts[Part] = Regions:GetPartDetails(Part)

	--self._RaycastParamaters:AddToFilter(Part)
	--self._OverlapParamaters:AddToFilter(Part)

	self._CenterPart = self:_GetCenterPart()

	table.insert(self._PartsArray, Part)

	self._NumberOfParts = #self._PartsArray

	--=======================================================================================================>
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function TargetTrackerModule._RemovePart(self: TargetTracker, Part: BasePart)
	--=======================================================================================================>
	if not self._Parts[Part] then return end
	--=======================================================================================================>

	self._Parts[Part] = nil

	self._RaycastParamaters.FilterDescendantsInstances = {}
	self._OverlapParamater.FilterDescendantsInstances  = {}

	for Part: BasePart, State: boolean in pairs(self._Parts) do
		--self._RaycastParamaters:AddToFilter(Part)
		--self._OverlapParamaters:AddToFilter(Part)
	end

	self._CenterPart = self:_GetCenterPart()

	table.remove(self._PartsArray, self:_FindPartInArray(Part, self._PartsArray))

	self._NumberOfParts = #self._PartsArray

	--=======================================================================================================>
end

-- @Private
-- Initialization function to start/setup the Object's initial events:
function TargetTrackerModule._SetEvents(self: TargetTracker)
	--=======================================================================================================>

	if self._IsAModel then
		--============================================================================================>

		self._Trove:Connect(self._Item.DescendantAdded, function(Descendant: BasePart)
			self:_AddPart(Descendant)
		end)


		self._Trove:Connect(self._Item.DescendantRemoving, function(Descendant: BasePart)
			self:_RemovePart(Descendant)
		end)

		--============================================================================================>
	else
		--============================================================================================>


		--============================================================================================>
	end

	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Private
-- Initialization function to start/setup the Object's initial data:
function TargetTrackerModule._GetDetections(self: TargetTracker): (number, number)
	--=======================================================================================================>

	-- If both DetectionCoverage and DetectionMode are not set to Automatic, return the originals:
	if self._DetectionCoverage ~= Enums.Enums.DetectionCoverage.Automatic and self._DetectionMode ~= Enums.Enums.DetectionMode.Automatic then
		return self._DetectionCoverage, self._DetectionMode
	end

	--=======================================================================================================>

	-- Predefine Variables:
	local DetectionCoverage: number, DetectionMode: number

	-- Calculate based on Model or Part:
	if self._IsAModel then
		--=====================================================================================>
		-- Get the Total Amount of Parts:
		local AmountOfParts: number = #self._PartsArray

		-- Redefine the Item as the Type its supposed to be:
		local Item: Model = self._Item :: Model

		if AmountOfParts > 1 then

			-- Get the Extent Size of the Model:
			local Size = Item:GetExtentsSize()

			if AmountOfParts > 20 then

				-- If the Item is bigger than 7 studs, do a more accurate check:
				-- If its less, then just check the Item's Center Position:
				if Size.Magnitude > Vector3.new(7, 7, 7).Magnitude then
					DetectionCoverage = Enums.Enums.DetectionCoverage.Center
					DetectionMode     = Enums.Enums.DetectionMode.Full
				else
					DetectionCoverage = Enums.Enums.DetectionCoverage.Center
					DetectionMode     = Enums.Enums.DetectionMode.Point
				end	

			else

				-- If the Item is bigger than 7 studs, do a more accurate check:
				-- If its less, then just check the Item's Center Position:
				if Size.Magnitude > Vector3.new(7, 7, 7).Magnitude then
					DetectionCoverage = Enums.Enums.DetectionCoverage.AllParts
					DetectionMode     = Enums.Enums.DetectionMode.Point
				else
					DetectionCoverage = Enums.Enums.DetectionCoverage.Center
					DetectionMode     = Enums.Enums.DetectionMode.Full
				end	

			end

		else

			for Part: BasePart, Details in self._Parts do
				-- If the Item is bigger than 5 studs, do a more accurate check:
				-- If its less, then just check the Item's Center Position:
				if Part.Size.Magnitude > Vector3.new(5, 5, 5).Magnitude then
					DetectionCoverage = Enums.Enums.DetectionCoverage.Center
					DetectionMode     = Enums.Enums.DetectionMode.Full
				else
					DetectionCoverage = Enums.Enums.DetectionCoverage.Center
					DetectionMode     = Enums.Enums.DetectionMode.Point
				end	
			end

		end

		--=====================================================================================>
	else
		--=====================================================================================>

		-- Redefine the Item as the Type its supposed to be:
		local Item: BasePart = self._Item :: BasePart

		-- If the Item is bigger than 5 studs, do a more accurate check:
		-- If its less, then just check the Item's Center Position:
		if Item.Size.Magnitude > Vector3.new(5, 5, 5).Magnitude then
			DetectionCoverage = Enums.Enums.DetectionCoverage.Center
			DetectionMode     = Enums.Enums.DetectionMode.Full
		else
			DetectionCoverage = Enums.Enums.DetectionCoverage.Center
			DetectionMode     = Enums.Enums.DetectionMode.Point
		end

		--=====================================================================================>
	end

	--=======================================================================================================>

	if self._DetectionCoverage ~= Enums.Enums.DetectionCoverage.Automatic then DetectionCoverage = self._DetectionCoverage end
	if self._DetectionMode     ~= Enums.Enums.DetectionMode.Automatic     then DetectionMode     = self._DetectionMode end

	--=======================================================================================================>

	-- Return the new Detection in the Setting Table:
	return DetectionCoverage :: number, DetectionMode :: number

	--=======================================================================================================>
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function TargetTrackerModule._GetCenterPart(self: TargetTracker): BasePart
	--=======================================================================================================>
	-- Define the CenterPart Variable:
	local CenterPart: BasePart

	-- If its a Model find it via all the Parts:
	if self._IsAModel then
		-- Redefine the Item as the Type its supposed to be:
		local Item: Model = self._Item :: Model
		-- Set the CenterPart:
		CenterPart = Item.PrimaryPart or Regions:GetCenterPartOfParts(self._PartsArray)
	else
		-- Set the CenterPart:
		CenterPart = self._Item :: BasePart
	end

	-- Warn if its CanQuery is false:
	if CenterPart.CanQuery == false then warn(`CenterPart for TrackedItem: {self._Item} has its CanQuery to false!`) end

	-- Return the CenterPart:
	return CenterPart
	--=======================================================================================================>
end

-- @Private
-- Initialization function to start/setup the Object's initial data:
function TargetTrackerModule._GetFilterDescendants(self: TargetTracker, Parts: {[BasePart]: boolean}): {BasePart}
	--=======================================================================================================>

	-- Define the FilterDescendants Array:
	local FilterDescendants: {BasePart} = {}

	if self._Detection == Enums.Enums.Detection.CenterItemPart or self._Detection == Enums.Enums.Detection.CenterItemPoint then
		table.insert(FilterDescendants, self._CenterPart)
	else 

		-- Loop through the Parts Dictionary:
		for Part: BasePart, State: boolean in pairs(Parts) do
			if Part.CanQuery == false then continue end
			table.insert(FilterDescendants, Part)
		end

	end

	return FilterDescendants

	--=======================================================================================================>
end


-- @Private
-- Initialization function to start/setup the Object's initial data:
function TargetTrackerModule._IsPartValidForItem(self: TargetTracker, Part: BasePart): boolean
	--=======================================================================================================>
	-- Dont allow Accessory Parts to be registered and checked:
	if Part.Parent and Part.Parent:IsA('Accessory') then return false end
	-- If the Part is found in the IgnoreParts Dictionary, then we should not add it to the Parts Registry,
	-- and therefore we should not check it:
	if Constants.TrackerData.CharacterIgnoreParts[Part.Name] then return false end
	-- Return true:
	return true
	--=======================================================================================================>
end

-- possible idea:

-- The zone does one overlap call
-- but the zone loops through all trackers and creates a new filterdescendant, adding all the FilterDescendant Arrays 
-- of every trackeritem object, so that it can do one PartsInPart or PartsInRegion call
-- then once theres an Array of all the Parts that it intersected with

-- we loop through all the trackers checking if they have parts in the results array
-- then we check the trackers individually if they have all of them inside of the zone or whatevre depending on the 
-- detection type of the tracker item

-- @Private
-- Initialization function to start/setup the Object's initial data:
function TargetTrackerModule.GetFilterDescendants(self: TargetTracker): {BasePart}
	--=======================================================================================================>

	-- Define the FilterDescendants Array:
	local FilterDescendants: {BasePart} = {}


	for Part, Bool in self._Parts do


	end

	return FilterDescendants

	--=======================================================================================================>
end

function TargetTrackerModule.FillFilterArray(self: TargetTracker, FilterIncludeArray: {Instance}): {Instance}
	--=======================================================================================================>

	for Part, Bool in self._Parts do table.insert(FilterIncludeArray, Part) end

	return FilterIncludeArray

	--=======================================================================================================>
end




@native
function TargetTrackerModule:_IsPartInZonePart(Part: BasePart | {CFrame: CFrame, Size: Vector3}, ZoneCFrame: CFrame, ZoneHalfSize: Vector3?, ZoneRadius: number?, ZoneParts: ZoneParts?): boolean
	--=======================================================================================================>

	-- Check detection mode and handle accordingly
	if self._DetectionMode == Enums.Enums.DetectionMode.Point then
		--=========================================================================================>
		if ZoneRadius then
			return Regions:IsPointInSphere(Part.CFrame.Position, ZoneCFrame, ZoneRadius)
		elseif ZoneHalfSize then
			return Regions:IsPointInBox(Part.CFrame.Position, ZoneCFrame, ZoneHalfSize)
		end
		--=========================================================================================>
	elseif self._DetectionMode == Enums.Enums.DetectionMode.Full or self._DetectionMode == Enums.Enums.DetectionMode.Touch then
		--=========================================================================================>
		-- Create a boolean on whether the DetectionMode is Full and Requires all Corners in the Zone:
		local RequireAllCornersInZone: boolean = self._DetectionMode == Enums.Enums.DetectionMode.Full

		-- Loop through each corner of the part and check if it is within the zone part
		for Index: number, Corner: Vector3 in ipairs(Regions:GetCornersFromPartDetails((Part.Size / 2), Part.CFrame, if ZoneHalfSize then 'Block' else 'Sphere')) do
			--===============================================================================>
			-- Corner In ZonePart:
			local CornerInZonePart: boolean

			if ZoneRadius then
				CornerInZonePart = Regions:IsPointInSphere(Corner, ZoneCFrame, ZoneRadius)
			elseif ZoneHalfSize then
				CornerInZonePart = Regions:IsPointInBox(Corner, ZoneCFrame, ZoneHalfSize)
			end

			-- Logic for `Touch` mode: return true if any corner is inside
			if RequireAllCornersInZone == false and CornerInZonePart == true then return true end

			-- Logic for `Full` mode: return false if any corner is outside
			-- If the Corner is outside the ZonePart, we will then loop over all the other ZoneParts to make sure its not still inside the Zone,
			-- but just under a different ZonePart:
			if RequireAllCornersInZone == true and CornerInZonePart == false and ZoneParts then 
				--=====================================================================>
				-- Corner In ZonePart:
				local CornerInOtherZonePart: boolean

				-- Loop through each ZonePart first:
				for ZonePart, Details in ZoneParts do
					-- If the ZonePart CFrame is the same as the one passed to be Checked here, then its the same Part, and we dont wanna 
					-- check over it again since we already know what the value is going to be, so continue loop:
					if (Details.CFrame or Details.Part.CFrame) == ZoneCFrame then continue end
					-- Check the Corner:
					if ZoneRadius then
						CornerInOtherZonePart = Regions:IsPointInSphere(Corner, Details.CFrame or Details.Part.CFrame, Details.Radius or Regions:GetRadius(Details.Size))
					elseif ZoneHalfSize then
						CornerInOtherZonePart = Regions:IsPointInBox(Corner, Details.CFrame or Details.Part.CFrame, Details.HalfSize)
					end
					-- If the Corner IS in ANOTHER ZonePart, break loop:
					if CornerInOtherZonePart == true then break end
				end

				-- If the Corner is ALSO not in another ZonePart in the ZoneParts Dictionary, then return false this Part does not have all its CORNERS:
				if CornerInOtherZonePart == false then return false end
				--=====================================================================>
			end

			--===============================================================================>
		end

		-- Return based on the mode
		return RequireAllCornersInZone
		--=========================================================================================>
	end

	-- Default return false if no conditions are met
	return false

	--=======================================================================================================>
end



@native
function TargetTrackerModule._BoundingBox_InZoneParts(self: TargetTracker, ZoneParts: ZoneParts, HitTargetParts: {BasePart}?): boolean
	--=======================================================================================================>

	-- Create a InZone boolean to return. This is whether any part of the tracked target is inside any ZonePart:
	local InZone: boolean = false

	-- Loop through each ZonePart first:
	for ZonePart, Details in ZoneParts do
		--===========================================================================================>
		-- Call Method to Check whether the Part is in the ZonePart, taking into account DetectionMode:
		local InAZonePart: boolean = self:_IsPartInZonePart(
			if self._IsAModel then self:_GetBoundingBox() else self._CenterPart,
			Details.CFrame or Details.Part.CFrame,
			if Details.Type == 'Block' then Details.HalfSize else nil,
			if Details.Type == 'Sphere' then Details.Radius or Regions:GetRadius(Details.Size) else nil,
			ZoneParts
		)
		-- If the Item Part is in this ZonePart, set InZone to true, break the loop, and stop checking:
		if InAZonePart then InZone = true break end
		-- If a part has been found in a ZonePart, break the outer loop as well:
		if InZone then break end
		--===========================================================================================>
	end

	-- Return the InZone Boolean:
	return InZone

	--=======================================================================================================>
end

@native
function TargetTrackerModule._BoundingBox_InBox(self: TargetTracker, ZoneCFrame: CFrame, ZoneHalfSize: Vector3, HitTargetParts: {BasePart}?): boolean
	--=======================================================================================================>

	-- Create a InZone boolean to return. This is whether any part of the tracked target is inside any ZonePart:
	local InZone: boolean = self:_IsPartInZonePart(
		if self._IsAModel then self:_GetBoundingBox() else self._CenterPart,
		ZoneCFrame,
		ZoneHalfSize,
		nil
	)

	-- Return the InZone Boolean:
	return InZone

	--=======================================================================================================>
end


@native
function TargetTrackerModule._Center_InZoneParts(self: TargetTracker, ZoneParts: ZoneParts, HitTargetParts: {BasePart}?): boolean
	--=======================================================================================================>

	-- Create a InZone boolean to return. This is whether any part of the tracked target is inside any ZonePart:
	local InZone: boolean = false

	-- Loop through each ZonePart first:
	for ZonePart, Details in ZoneParts do
		--===========================================================================================>
		-- Call Method to Check whether the Part is in the ZonePart, taking into account DetectionMode:
		local InAZonePart: boolean = self:_IsPartInZonePart(
			self._CenterPart,
			Details.CFrame or Details.Part.CFrame,
			if Details.Type == 'Block' then Details.HalfSize else nil,
			if Details.Type == 'Sphere' then Details.Radius or Regions:GetRadius(Details.Size) else nil,
			ZoneParts
		)
		-- If the Item Part is in this ZonePart, set InZone to true, break the loop, and stop checking:
		if InAZonePart then InZone = true break end
		--===========================================================================================>
	end

	-- Return the InZone Boolean:
	return InZone

	--=======================================================================================================>
end

@native
function TargetTrackerModule._Center_InBox(self: TargetTracker, ZoneCFrame: CFrame, ZoneHalfSize: Vector3, HitTargetParts: {BasePart}?): boolean
	--=======================================================================================================>
	-- Create a InZone boolean to return. This is whether any part of the tracked target is inside any ZonePart:
	local InZone: boolean = self:_IsPartInZonePart(
		self._CenterPart,
		ZoneCFrame,
		ZoneHalfSize,
		nil
	)
	-- Return the InZone Boolean:
	return InZone
	--=======================================================================================================>
end


@native
function TargetTrackerModule._AnyPart_InZoneParts(self: TargetTracker, ZoneParts: ZoneParts, HitTargetParts: {BasePart}?): boolean
	--=======================================================================================================>

	-- Create a InZone boolean to return. This is whether any part of the tracked target is inside any ZonePart:
	local InZone: boolean = false

	-- Loop through each ZonePart first:
	for ZonePart, Details in ZoneParts do
		--===========================================================================================>
		-- Loop through all the Parts in Tracked Target Item:
		for Index: number, Part: BasePart in ipairs(HitTargetParts or self._PartsArray) do
			--======================================================================>
			-- Call Method to Check whether the Part is in the ZonePart, taking into account DetectionMode:
			local InAZonePart: boolean = self:_IsPartInZonePart(
				Part,
				Details.CFrame or Details.Part.CFrame,
				if Details.Type == 'Block' then Details.HalfSize else nil,
				if Details.Type == 'Sphere' then Details.Radius or Regions:GetRadius(Details.Size) else nil,
				ZoneParts
			)
			-- If the Item Part is in this ZonePart, set InZone to true, break the loop, and stop checking:
			if InAZonePart then InZone = true break end
			--======================================================================>
		end
		-- If a part has been found in a ZonePart, break the outer loop as well:
		if InZone == true then break end
		--===========================================================================================>
	end

	-- Return the InZone Boolean:
	return InZone

	--=======================================================================================================>
end

@native
function TargetTrackerModule._AnyPart_InBox(self: TargetTracker, ZoneCFrame: CFrame, ZoneHalfSize: Vector3, HitTargetParts: {BasePart}?): boolean
	--=======================================================================================================>

	-- Create a InZone boolean to return. This is whether any part of the tracked target is inside any ZonePart:
	local InZone: boolean = false

	-- Loop through all the Parts in Tracked Target Item:
	for Index: number, Part: BasePart in ipairs(HitTargetParts or self._PartsArray) do
		--======================================================================>
		-- Call Method to Check whether the Part is in the ZonePart, taking into account DetectionMode:
		local InAZonePart: boolean = self:_IsPartInZonePart(
			Part,
			ZoneCFrame,
			ZoneHalfSize,
			nil
		)
		-- If the Item Part is in this ZonePart, set InZone to true, break the loop, and stop checking:
		if InAZonePart == true then InZone = true break end
		--======================================================================>
	end

	-- Return the InZone Boolean:
	return InZone

	--=======================================================================================================>
end


@native
function TargetTrackerModule._AllParts_InZoneParts(self: TargetTracker, ZoneParts: ZoneParts, HitTargetParts: {BasePart}?): boolean
	--=======================================================================================================>

	-- Create a InZone boolean to return. This is whether the Tracked Target has every Part inside the Zone:
	local InZone: boolean = true

	-- Loop through all the Parts in Tracked Target Item:
	for Index: number, Part: BasePart in ipairs(self._PartsArray) do
		--===========================================================================================>
		-- Boolean on whether the Item Part is in ANY ZonePart in the ZoneParts Dictionary:
		local InAZonePart: boolean = false
		-- Loop through the ZonePart's Dictionary checking if the Item Part is any of them:
		for ZonePart, Details in ZoneParts do
			--======================================================================>
			-- Call Method to Check whether the Part is in the ZonePart, taking into account DetectionMode:
			InAZonePart = self:_IsPartInZonePart(
				Part,
				Details.CFrame or Details.Part.CFrame,
				if Details.Type == 'Block'  then Details.HalfSize else nil,
				if Details.Type == 'Sphere' then Details.Radius or Regions:GetRadius(Details.Size) else nil,
				ZoneParts
			)
			-- If the Item Part is in this ZonePart, break the loop, stop checking:
			if InAZonePart then break end
			--======================================================================>
		end
		-- If the Item Part Checked was not in any of the ZoneParts, then it is outside the Zone, so we break and stop the loop.
		-- Remember, this is the AllParts DetectionCoverage, which means we need every Item Part inside a ZonePart for the Zone:
		if InAZonePart == false then InZone = false break end
		--===========================================================================================>
	end

	-- Return the InZone Boolean:
	return InZone

	--=======================================================================================================>
end

@native
function TargetTrackerModule._AllParts_InBox(self: TargetTracker, ZoneCFrame: CFrame, ZoneHalfSize: Vector3, HitTargetParts: {BasePart}?): boolean
	--=======================================================================================================>

	-- Create a InZone boolean to return. This is whether the Tracked Target has every Part inside the Zone:
	local InZone: boolean = true

	-- Loop through all the Parts in Tracked Target Item:
	for Index: number, Part: BasePart in ipairs(self._PartsArray) do
		--===========================================================================================>
		-- Boolean on whether the Item Part is in ANY ZonePart in the ZoneParts Dictionary:
		-- Call Method to Check whether the Part is in the ZonePart, taking into account DetectionMode:
		local InAZonePart: boolean = self:_IsPartInZonePart(
			Part,
			ZoneCFrame,
			ZoneHalfSize,
			nil
		)
		-- If the Item Part Checked was not in any of the ZoneParts, then it is outside the Zone, so we break and stop the loop.
		-- Remember, this is the AllParts DetectionCoverage, which means we need every Item Part inside a ZonePart for the Zone:
		if InAZonePart == false then InZone = false break end
		--===========================================================================================>
	end

	-- Return the InZone Boolean:
	return InZone

	--=======================================================================================================>
end



-- @Public
-- Initialization function to start/setup the Object's initial data:
@native
function TargetTrackerModule.GetTargetPartsFromHitParts(self: TargetTracker, HitParts: {[BasePart]: boolean}): {BasePart}
	--=======================================================================================================>
	-- Define the HitParts Array:
	local HitTargetParts: {BasePart} = {}
	-- Loop through all the Parts in Tracked Target Item:
	for Index: number, Part: BasePart in ipairs(self._PartsArray) do
		--===========================================================================================>
		-- Insert the Part from the Array into the HitParts Array and remove it from the sent dictionary:
		if HitParts[Part] then table.insert(HitTargetParts, Part); end
		--===========================================================================================>
	end
	-- Return False because no Part of this Item is in the passed Dictionary:
	return HitTargetParts
	--=======================================================================================================>
end


-- @Public
-- Initialization function to start/setup the Object's initial data:
@native
function TargetTrackerModule.IsInsideBox(self: TargetTracker, BoxCFrame: CFrame, BoxHalfSize: Vector3, HitTargetParts: {BasePart}?): boolean
	--=======================================================================================================>

	if HitTargetParts then 
		--===========================================================================================>
		-- If there is nothing in the targetpartsarray then return false:
		if #HitTargetParts < 1 then return false end	
		-- Overlap Detection Quick Returns:
		if self._DetectionCoverage == Enums.Enums.DetectionCoverage.Center then
			if self:_FindPartInArray(self._CenterPart, HitTargetParts) == nil then return false end
			if self._DetectionMode == Enums.Enums.DetectionMode.Touch then return true end
			if self._DetectionMode == Enums.Enums.DetectionMode.Point then return true end
		elseif self._DetectionCoverage == Enums.Enums.DetectionCoverage.AnyPart then
			if self._DetectionMode == Enums.Enums.DetectionMode.Touch then return true end
			if self._DetectionMode == Enums.Enums.DetectionMode.Point then return true end
		elseif self._DetectionCoverage == Enums.Enums.DetectionCoverage.BoundingBox then
			if self._DetectionMode == Enums.Enums.DetectionMode.Touch then return true end
			if self:_FindPartInArray(self._CenterPart, HitTargetParts) == nil then return false end
		elseif self._DetectionCoverage == Enums.Enums.DetectionCoverage.AllParts then
			if self._DetectionMode == Enums.Enums.DetectionMode.Touch then 
				if self._NumberOfParts == #HitTargetParts then return true end
			elseif self._DetectionMode == Enums.Enums.DetectionMode.Point then 
				if self._NumberOfParts == #HitTargetParts then return true end
			end
		end
		--===========================================================================================>
	end

	--=======================================================================================================>
	-- Seperate the Get Name and maybe have a variable on Detection Set in order to cache the function not find it every time:
	return self[`_{Enums.Enums.DetectionCoverage:GetName(self._DetectionCoverage)}_InBox`](self, BoxCFrame, BoxHalfSize, HitTargetParts)
	--=======================================================================================================>
end

-- @Public
-- Initialization function to start/setup the Object's initial data:
@native
function TargetTrackerModule.IsInsideZoneParts(self: TargetTracker, ZoneParts: ZoneParts, HitTargetParts: {BasePart}?): boolean
	--=======================================================================================================>
	-- If the CenterPart is not in the HitParts Array, then return false:
	if HitTargetParts then 
		--===========================================================================================>
		-- If there is nothing in the targetpartsarray then return false:
		if #HitTargetParts < 1 then return false end	
		-- Overlap Detection Quick Returns:
		if self._DetectionCoverage == Enums.Enums.DetectionCoverage.Center then
			if self:_FindPartInArray(self._CenterPart, HitTargetParts) == nil then return false end
			if self._DetectionMode == Enums.Enums.DetectionMode.Touch then return true end
			if self._DetectionMode == Enums.Enums.DetectionMode.Point then return true end
		elseif self._DetectionCoverage == Enums.Enums.DetectionCoverage.AnyPart then
			if self._DetectionMode == Enums.Enums.DetectionMode.Touch then return true end
			if self._DetectionMode == Enums.Enums.DetectionMode.Point then return true end
		elseif self._DetectionCoverage == Enums.Enums.DetectionCoverage.BoundingBox then
			if self._DetectionMode == Enums.Enums.DetectionMode.Touch then return true end
			if self:_FindPartInArray(self._CenterPart, HitTargetParts) == nil then return false end
		elseif self._DetectionCoverage == Enums.Enums.DetectionCoverage.AllParts then
			if self._DetectionMode == Enums.Enums.DetectionMode.Touch then 
				if self._NumberOfParts == #HitTargetParts then return true end
			elseif self._DetectionMode == Enums.Enums.DetectionMode.Point then 
				if self._NumberOfParts == #HitTargetParts then return true end
			end
		end
		--===========================================================================================>
	end
	--=======================================================================================================>
	-- Seperate the Get Name and maybe have a variable on Detection Set in order to cache the function not find it every time:
	return self[`_{Enums.Enums.DetectionCoverage:GetName(self._DetectionCoverage)}_InZoneParts`](self, ZoneParts, HitTargetParts)
	--=======================================================================================================>
end


--===========================================================================================================================>

-- @Public
-- Initialization function to start/setup the Object's initial data:
function TargetTrackerModule.DictionaryHasTrackedParts(self: TargetTracker, Dictionary: {[BasePart]: boolean}): boolean
	--=======================================================================================================>
	-- Loop through the Tracked Item Parts Dictionary checking each to see if they are in the passed Dictionary:
	-- If one is, break the loop by returning true:
	for Part: BasePart, Details in pairs(self._Parts) do
		if Dictionary[Part] then return true end
	end
	--=======================================================================================================>
	-- Return False because no Part of this Item is in the passed Dictionary:
	return false
	--=======================================================================================================>
end

-- @Public
-- Initialization function to start/setup the Object's initial data:
function TargetTrackerModule.ArrayHasTrackedParts(self: TargetTracker, Array: {BasePart}): boolean
	--=======================================================================================================>
	-- Loop through the Array checking each to see if they are in the Tracked Parts Dictionary:
	-- If one is, break the loop by returning true:
	for Index: number, Part: BasePart in ipairs(Array) do
		if self._Parts[Part] then return true end
	end
	--=======================================================================================================>
	-- Return False because no Part of this Item is in the passed Array:
	return false
	--=======================================================================================================>
end

--===========================================================================================================================>



-- @Private
-- Initialization function to start/setup the Object's initial data:
@native
function TargetTrackerModule._GetBoundingBox(self: TargetTracker): {CFrame: CFrame, Size: Vector3}
	--=======================================================================================================>

	-- Create the BoundingBox Table:
	local BoundingBox: {CFrame: CFrame, Size: Vector3} = {} :: {CFrame: CFrame, Size: Vector3}

	if self._IsAModel then
		--==============================================================================>
		-- Redefine the Item as the Type its supposed to be:
		local Item: Model = self._Item :: Model
		-- Set the BoundingBox results to the table properties:
		BoundingBox.CFrame, BoundingBox.Size = Regions:GetBoundingCFrameAndSize(self._PartsArray, false)
		--==============================================================================>
	else 
		--==============================================================================>
		BoundingBox.CFrame, BoundingBox.Size = self._CenterPart.CFrame, self._CenterPart.Size
		--==============================================================================>
	end

	return BoundingBox

	--=======================================================================================================>
end

-- @Public
-- Initialization function to start/setup the Object's initial data:
@native
function TargetTrackerModule.GetPosition(self: TargetTracker, Part: BasePart?): Vector3
	--=======================================================================================================>

	-- If the Item is a Model, get the Position of the Model based on the PrimaryPart or Pivot, else just get the Position of the BasePart:
	if Part then
		--==============================================================================>
		-- Return the Position of the BasePart:
		return Part.Position
		--==============================================================================>
	elseif self._CenterPart then
		--==============================================================================>
		return self._CenterPart.Position
		--==============================================================================>
	elseif self._IsAModel then
		--==============================================================================>
		-- Redefine the Item as the Type its supposed to be:
		local Item: Model = self._Item :: Model
		-- If the Item has a PrimaryPart then return the Position of the PrimaryPart, else get the PivotPoint of the Model:
		return if Item.PrimaryPart then Item.PrimaryPart.Position else Item:GetPivot().Position
		--==============================================================================>
	else
		--==============================================================================>
		-- Redefine the Item as the Type its supposed to be:
		local Item: BasePart = self._Item :: BasePart
		-- Return the Position of the BasePart:
		return Item.Position
		--==============================================================================>
	end

	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Public
-- Method to Update/Set the Default Part/TrackedItem Detection of the TrackedItem:
function TargetTrackerModule.SetDetection(self: TargetTracker, Coverage: number, Mode: number)
	--=======================================================================================================>
	self._DetectionCoverage, self._DetectionMode = Coverage, Mode
	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Private
-- Initialization function to start/setup the Object's initial data:
function TargetTrackerModule._FindPartInArray(self: TargetTracker, Part: BasePart, Array: {BasePart}): number?
	return table.find(Array, Part)
end

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(TargetTrackerModule) :: TargetTrackerModule

--===========================================================================================================================>