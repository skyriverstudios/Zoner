--===========================================================================================================================>
--!optimize 2
--!strict
--===========================================================================================================================>
-- TrackedItem

-- Author:
-- IISato

-- 7/31/2024
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zone]: Tracker')

-- Define Module table:
local Tracker = {}; Tracker.__index = Tracker

--===========================================================================================================================>
--[ GLOBALS: ]


--[ Global Dependencies: ]

-- Import Service:
local SharedTableRegistry = game:GetService('SharedTableRegistry')

-- [ Local Dependencies: ]
local Constants = require(`../../../Constants`);
local Regions   = require(`../../Regions`);
local Enums     = require(`../../../Enums`);

--===========================================================================================================================>
--[ CONSTANTS: ]


-- Reference to the Holder this Code is run under:
local ZONER_HOLDER

-- Retrieve or Create and Register a new Zoner Trackers Shared Table:
local TRACKER_REGISTRY: SharedTable = SharedTableRegistry:GetSharedTable('Zoner: Tracker Registry')

-- Wait for the Events folder:
local EVENTS_FOLDER = script:FindFirstAncestor('Modules').Parent:WaitForChild('Events')

-- Cache the TrackerId events:
local TRACKER_EVENTS = {
	TrackerId_Get   = EVENTS_FOLDER:WaitForChild('TrackerId_Get', 5);
	TrackerId_Clear = EVENTS_FOLDER:WaitForChild('TrackerId_Clear', 5);
}

--===========================================================================================================================>
--[ TYPES: ]


-- [ Register Types: ]

-- This will inject all types into this context.
local Zoner_Types = require(`../../../../../Types`)

-- Create and Export Type:
export type Trackables = Model | BasePart

export type TrackedPartDetails = {
	Part: BasePart;
	Type: 'Sphere'|'Complex'|'Block';
}

export type TrackedPartsMap  = {[BasePart]: TrackedPartDetails}
export type TrackedPartsList = {BasePart}

-- Just so the type below has a name in the dictionary:
type ZoneId = string;
-- Define the Parts Data Type for passage to functions:
type PartsData = {
	List:   TrackedPartsList;
	Map:    TrackedPartsMap;
	Count:  number;
	Center: BasePart;
};

--- Create and Export the Module's Object Type:
export type Tracker<Tracked> = typeof(setmetatable({} :: {
	--======================================>
	-- Trackable Id:
	_Id: string;
	_RegistryIdMap: SharedTable;
	-- Id map for the Zones this tracker is in, in THIS VM:
	_VMZoneIDMap:   {[string]: boolean};
	-- Reference to the tracked Instance: BasePart | Model
	_Tracked: Tracked & Trackables;
	_IsAModel: boolean;
	-- Internal Parts data table:
	_Parts: PartsData;
	-- Dictionary of connections:
	_Connections: {[any]: RBXScriptConnection};
	--======================================>
}, {} :: typeof(Tracker)))


--===========================================================================================================================>
--[ LOCAL FUNCTIONS: ]


-- Get the CenterPart:
local function GetCenterPart(Tracked: Trackables, TrackedPartsList: TrackedPartsList): BasePart
	--=======================================================================================================>
	-- Define the CenterPart Variable:
	local CenterPart: BasePart
	-- If its a Model find it via all the Parts:
	if Tracked:IsA('Model') then
		-- Set the CenterPart:
		CenterPart = Tracked.PrimaryPart or Regions:GetCenterPartOfParts(TrackedPartsList)
	else
		-- Set the CenterPart:
		CenterPart = Tracked
	end
	-- Warn if its CanQuery is false:
	--if CenterPart.CanQuery == false then warn(`[Zoner]: CenterPart for TrackedItem: {Tracked} has its CanQuery to false!`) end
	-- Return the CenterPart:
	return CenterPart
	--=======================================================================================================>
end

-- Checj if Part is Valid for tracking:
local function IsPartValidForItem(Part: BasePart): boolean
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

-- Function to prioritize a specific instance
local function MovePartToFront(Array: {BasePart}, Target: BasePart): {BasePart}
	-- Loop through the array to find the index of the target
	for Index: number, Item: BasePart in ipairs(Array) do
		if Item == Target then
			-- Remove it from its current position
			table.remove(Array, Index)
			-- Insert it at index 1
			table.insert(Array, 1, Target)
			break -- We're done
		end
	end

	return Array
end

--===========================================================================================================================>

local function Initialize(self: Tracker<Trackables>, Serial: boolean?)
	--=======================================================================================================>
	--warn('Tracker:', self._Tracked, self._Id)
	--warn('ZONER_HOLDER', ZONER_HOLDER)
	--warn('ZONER_HOLDER ID', ZONER_HOLDER:GetAttribute('Id'))
	--warn(self._RegistryIdMap)

	-- Store the Tracker, registered in the Zoner Holder via its Id:
	self._RegistryIdMap[ZONER_HOLDER:GetAttribute('Id')] = true

	-- If the Tracked Instance is a model, then do specific descendant listening and setup:
	if self._Tracked:IsA('Model') then
		--============================================================================================>
		
		-- Get all the current descendants of the Model and Check if its a basepart, if so, add it to the internal data:
		for Index: number, Descendant: Instance in ipairs(self._Tracked:GetDescendants()) do 
			--==================================================================>
			-- Check if Descendant is a BasePart, continue if not:
			if not Descendant:IsA('BasePart') then continue end
			-- Check if BasePart is a valid Part for tracking, continue if not:
			if not IsPartValidForItem(Descendant) then continue end
			--==================================================================>
			-- Add the Part details to the Map:
			self._Parts.Map[Descendant] = Regions:GetPartDetails(Descendant)
			-- Add Part to the List:
			table.insert(self._Parts.List, Descendant)
			--==================================================================>
		end

		-- Get the CenterPart of the Tracker's Parts:
		self._Parts.Center = GetCenterPart(self._Tracked, self._Parts.List)
		-- Move the CenterPart to the FRONT (1) Index of the Part's list:
		self._Parts.List   = MovePartToFront(self._Parts.List, self._Parts.Center)
		-- Get the total number of Parts in the List:
		self._Parts.Count   = #self._Parts.List

		--============================================================================================>
		
		-- Index the Proper Connection Function/Signal based on 'Serial'
		local DescendantAdded_Connect: ((RBXScriptSignal, (Instance) -> ()) -> RBXScriptConnection)  = 
			(if Serial then self._Tracked.DescendantAdded.Connect else self._Tracked.DescendantAdded.ConnectParallel) :: any

		-- Index the Proper Connection Function/Signal based on 'Serial'
		local DescendantRemoving_Connect: ((RBXScriptSignal, (Instance) -> ()) -> RBXScriptConnection)  = 
			(if Serial then self._Tracked.DescendantRemoving.Connect else self._Tracked.DescendantRemoving.ConnectParallel) :: any

		-- Connect a Descendant Added event to the Tracker Model and listen for Added Children:
		self._Connections['Desc_Add'] = DescendantAdded_Connect(self._Tracked.DescendantAdded, function(Descendant: Instance)
			--==================================================================>
			-- Check if Descendant is a BasePart, return if not:
			if not Descendant:IsA('BasePart') then return end
			-- Check if BasePart is a valid Part for tracking, return if not:
			if not IsPartValidForItem(Descendant) then return end
			-- If table has been cleared return:
			if not self._Parts then return end
			-- If Part is already added, then return:
			if self._Parts.Map[Descendant] then return end
			--==================================================================>
			
			-- Add the Part details to the Map:
			self._Parts.Map[Descendant] = Regions:GetPartDetails(Descendant)
			-- Add Part to the List:
			table.insert(self._Parts.List, Descendant)
			
			-- Get the total number of Parts in the List:
			self._Parts.Count   = #self._Parts.List
			
			-- Get the CenterPart of the Tracker's Parts:
			local Center = GetCenterPart(self._Tracked, self._Parts.List)
			
			-- If the CenterPart is a new CenterPart then adjust the list and set the new CenterPart:
			if Center ~= self._Parts.Center then
				-- Update CenterPart:
				self._Parts.Center = Center
				-- Move the CenterPart to the FRONT (1) Index of the Part's list:
				self._Parts.List   = MovePartToFront(self._Parts.List, self._Parts.Center)
			end
			--==================================================================>
		end)

		-- Connect a Descendant Removing event to the Tracker Model and listen for Removing Children:
		self._Connections['Desc_Remove'] = DescendantRemoving_Connect(self._Tracked.DescendantRemoving, function(Descendant: Instance)
			--==================================================================>
			-- Check if Descendant is a BasePart, return if not:
			if not Descendant:IsA('BasePart') then return end
			-- Check if BasePart is a valid Part for tracking, return if not:
			if not IsPartValidForItem(Descendant) then return end
			-- If table has been cleared return:
			if not self._Parts then return end
			-- If Part is already removed, then return:
			if not self._Parts.Map[Descendant] then return end
			--==================================================================>
			
			-- Clear Part from Map:
			self._Parts.Map[Descendant] = nil :: any
			-- Remove the Part from the List:
			table.remove(self._Parts.List, table.find(self._Parts.List, Descendant))

			-- Get the total number of Parts in the List:
			self._Parts.Count   = #self._Parts.List
			
			-- COULD ADD AUTO DESTROY HERE:
			-- PARTS ARE NOW 0, NO CENTERPART CAN EXIST:
			if self._Parts.Count == 0 then self._Parts.Center = nil :: any; return end
			
			-- Get the CenterPart of the Tracker's Parts:
			local Center = GetCenterPart(self._Tracked, self._Parts.List)

			-- If the CenterPart is a new CenterPart then adjust the list and set the new CenterPart:
			if Center ~= self._Parts.Center then
				-- Update CenterPart:
				self._Parts.Center = Center
				-- Move the CenterPart to the FRONT (1) Index of the Part's list:
				self._Parts.List   = MovePartToFront(self._Parts.List, self._Parts.Center)
			end
			--==================================================================>
		end)

		--============================================================================================>
	else
		--============================================================================================>
		
		-- Get the Details of the Tracked Part in the Map:
		self._Parts.Map[self._Tracked :: BasePart] = Regions:GetPartDetails(self._Tracked :: BasePart)
		
		-- Set CenterPart to the Tracked Part:
		self._Parts.Center  = self._Tracked :: BasePart
		-- Set the first index of the list to the TrackedPart, also Center Part:
		self._Parts.List[1] = self._Parts.Center
		-- Set Part count to one:
		self._Parts.Count   = 1
		
		--============================================================================================>
	end

	-- Return the Object:
	return self
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ CONSTRUCTOR FUNCTIONS: ]


-- @Public
-- Constructor Function for this individual object:
function Tracker.New(Tracked: Trackables, Serial: boolean?): Tracker<Trackables>
	--=======================================================================================================>
	-- Assert that the Trackable Item must be an Instance:
	assert(typeof(Tracked) == "Instance", Constants.Logs.Tracker.ItemType)
	-- Assert the Specifics of the Instance Type:
	assert((Tracked :: Trackables):IsA('BasePart') == true or (Tracked :: Trackables):IsA('Model') == true, Constants.Logs.Tracker.InstanceType)
	--=======================================================================================================>
	-- Set a Memory Category:
	debug.setmemorycategory('[Zoner]: Tracker')

	-- Get the Unique Identifier from the Main Zoner Object:
	local Tracker_Id: string = TRACKER_EVENTS.TrackerId_Get:Invoke(Tracked)
	--=======================================================================================================>
	-- Set Metatable to the MetaTable and the current Enum2Table:
	return Initialize(setmetatable({
		--==========================>
		-- Store the unique identifier:
		_Id = Tracker_Id;
		-- Store a reference to the Tracker Registry Table:
		_RegistryIdMap = TRACKER_REGISTRY[Tracker_Id];
		-- Id map for the Zones this tracker is in, in THIS VM:
		_VMZoneIDMap   = {};
		-- Store the tracked Instance:
		_Tracked = Tracked;
		--==========================>
		_IsAModel = (Tracked :: Trackables):IsA('Model');
		--==========================>
		_Connections = {};
		--==========================>
		_Parts = {
			List   = {};
			Map    = {};
			Count  = 0;
			Center = nil :: any;
		};
		--==========================>
		InZones = {};
		--==========================>
	} :: any, Tracker), Serial) :: any
	--=======================================================================================================>
end

-- @Public
-- Destroyer Function which clears the entirity of the Data for the Object:
function Tracker.Destroy(self: Tracker<Trackables>)
	--=======================================================================================================>
	--warn('tracker cleanup')
	
	-- If still in any Zones upon destruction, remove the ZoneIds from the Global Registry map for this Tracker:
	for ZoneId, State in self._VMZoneIDMap do
		self._RegistryIdMap[ZoneId] = nil
	end
	
	-- Clear the ZonerHolder Id from this Tracker's global data as its no longer being tracked in this ZonerHolder:
	self._RegistryIdMap[ZONER_HOLDER:GetAttribute('Id')] = nil

	-- If the Registry is now Empty, we are no longer in any Holder, or in any Zone being tracked by anything
	if SharedTable.size(self._RegistryIdMap) == 0 then
		TRACKER_EVENTS.TrackerId_Clear:Fire(self._Tracked)
	end
	-- Clear connections:
	for Key, Connection in pairs(self._Connections) do self._Connections[Key]:Disconnect() end; table.clear(self._Connections)
	-- Clear all self data:
	for Index, Data in pairs(self) do self[Index] = nil end
	-- Set the Metatable to nil
	setmetatable(self :: any, nil)	
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

-- SCRAPPED. Cant do In parallel.

--===========================================================================================================================>

@native function Tracker.GetAutoDetectionCoverageAndMode(self: Tracker<Trackables>): (number, number)
	--=======================================================================================================>

	-- Predefine Variables:
	local DetectionCoverage: number, DetectionMode: number

	-- Calculate based on Model or Part:
	if self._Tracked:IsA('Model') then
		--=====================================================================================>

		if self._Parts.Count > 1 then

			-- Get the Extent Size of the Model:
			local Size = self._Tracked:GetExtentsSize()
				
			if self._Parts.Count > 20 then
				-- If the Item is bigger than 7 studs, do a more accurate check:
				-- If its less, then just check the Item's Center Position:
				if Size.Magnitude > Vector3.new(7, 7, 7).Magnitude then
					DetectionCoverage = Enums.DetectionCoverage.Center
					DetectionMode     = Enums.DetectionMode.Full
				else
					DetectionCoverage = Enums.DetectionCoverage.Center
					DetectionMode     = Enums.DetectionMode.Point
				end	
			else
				-- If the Item is bigger than 7 studs, do a more accurate check:
				-- If its less, then just check the Item's Center Position:
				if Size.Magnitude > Vector3.new(7, 7, 7).Magnitude then
					DetectionCoverage = Enums.DetectionCoverage.AllParts
					DetectionMode     = Enums.DetectionMode.Point
				else
					DetectionCoverage = Enums.DetectionCoverage.Center
					DetectionMode     = Enums.DetectionMode.Full
				end	
			end

		else
			-- Loop through Part dictionary:
			for Part: BasePart, Details in self._Parts.Map do
				-- If the Item is bigger than 5 studs, do a more accurate check:
				-- If its less, then just check the Item's Center Position:
				if Part.Size.Magnitude > Vector3.new(5, 5, 5).Magnitude then
					DetectionCoverage = Enums.DetectionCoverage.Center
					DetectionMode     = Enums.DetectionMode.Full
				else
					DetectionCoverage = Enums.DetectionCoverage.Center
					DetectionMode     = Enums.DetectionMode.Point
				end	
			end
		end

		--=====================================================================================>
	else
		--=====================================================================================>

		-- Redefine the Item as the Type its supposed to be:
		local Tracked: BasePart = self._Tracked :: BasePart

		-- If the Item is bigger than 5 studs, do a more accurate check:
		-- If its less, then just check the Item's Center Position:
		if Tracked.Size.Magnitude > Vector3.new(5, 5, 5).Magnitude then
			DetectionCoverage = Enums.DetectionCoverage.Center
			DetectionMode     = Enums.DetectionMode.Full
		else
			DetectionCoverage = Enums.DetectionCoverage.Center
			DetectionMode     = Enums.DetectionMode.Point
		end

		--=====================================================================================>
	end
	--=======================================================================================================>
	
	-- Return the new Detection in the Setting Table:
	return DetectionCoverage, DetectionMode
	
	--=======================================================================================================>
end

-- @Public
@native function Tracker.InZone(self: Tracker<Trackables>, ZoneId: ZoneId): boolean?
	return self._RegistryIdMap[ZoneId]
end

-- @Public
@native function Tracker.EnterZone(self: Tracker<Trackables>, ZoneId: ZoneId)
	--=======================================================================================================>
	-- Add ZoneId to the Map for this Handler VM:
	self._VMZoneIDMap[ZoneId] = true;
	-- Add ZoneId to the map:
	self._RegistryIdMap[ZoneId] = true
	--=======================================================================================================>
end

-- @Public
@native function Tracker.ExitZone(self: Tracker<Trackables>, ZoneId: ZoneId)
	--=======================================================================================================>
	-- Remove ZoneId from the Map for this Handler VM:
	self._VMZoneIDMap[ZoneId] = nil;
	-- Remove ZoneId from the map:
	self._RegistryIdMap[ZoneId] = nil
	--=======================================================================================================>
end

-- @Public
@native function Tracker.GetPartsList(self: Tracker<Trackables>): TrackedPartsList
	return self._Parts.List
end

-- @Public
@native function Tracker.GetPartsMap(self: Tracker<Trackables>): TrackedPartsMap
	return self._Parts.Map
end

-- @Public
@native function Tracker.GetCenterPart(self: Tracker<Trackables>): BasePart
	return self._Parts.Center
end

-- @Public
@native function Tracker.GetPartCount(self: Tracker<Trackables>): number
	return self._Parts.Count
end

-- @Public
@native function Tracker.GetPartsData(self: Tracker<Trackables>): PartsData
	return self._Parts
end

-- @Public
-- Initialization function to start/setup the Object's initial data:
@native function Tracker.GetTargetPartsFromHitParts(self: Tracker<Trackables>, HitParts: {[BasePart]: boolean}, HitTargetPartsArray: {BasePart}): {BasePart}
	--=======================================================================================================>
	-- Loop through all the Parts in Tracked Target Item:
	for Index: number, Part: BasePart in ipairs(self._Parts.List) do
		-- Insert the Part from the Array into the HitParts Array and remove it from the sent dictionary:
		if HitParts[Part] then table.insert(HitTargetPartsArray, Part); end
	end
	-- Return False because no Part of this Item is in the passed Dictionary:
	return HitTargetPartsArray
	--=======================================================================================================>
end

--===========================================================================================================================>

-- @Public
-- Initialization function to start/setup the Object's initial data:
@native function Tracker.DictionaryHasTrackedParts(self: Tracker<Trackables>, Dictionary: {[BasePart]: boolean}): boolean
	--=======================================================================================================>
	-- Loop through the Tracked Item Parts Dictionary checking each to see if they are in the passed Dictionary:
	-- If one is, break the loop by returning true:
	for Index: number, Part: BasePart in ipairs(self._Parts.List) do if Dictionary[Part] then return true end end
	-- Return False because no Part of this Item is in the passed Dictionary:
	return false
	--=======================================================================================================>
end

-- @Public
-- Initialization function to start/setup the Object's initial data:
@native function Tracker.GetPosition(self: Tracker<Trackables>): Vector3
	-- If the Item is a Model, get the Position of the Model based on the PrimaryPart or Pivot, else just get the Position of the BasePart:
	if self._Tracked:IsA('Model') then return self._Tracked:GetPivot().Position else return self._Parts.Center.Position end
end

--===========================================================================================================================>

--- Called from the Parent running this Module, to update some global scope:
function Tracker.UpdateGlobalScope(ZonerHolder: Zoner_Types.ZonerHolder)
	ZONER_HOLDER = ZonerHolder
end

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze({New = Tracker.New; UpdateGlobalScope = Tracker.UpdateGlobalScope})

--===========================================================================================================================>