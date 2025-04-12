--===========================================================================================================================>
--!optimize 2
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zone]-[Engine]: Detection')

-- Define Module table
local DetectionHandlerModule = {
	Default = {}; Complex  = {}; Simple = {}; Efficient = {}
}

--===========================================================================================================================>
--[ VARIABLES: ]


local WorldModel = require(`../WorldModel`);
local Enums      = require(`../../Enums`);

local Bounds = require(script.Bounds);
local TargetHandler = require(script.Targets);

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local Types = require(`../../../../Types`)

-- Make the Module into a Type:
type DetectionHandlerModule    = typeof(DetectionHandlerModule)

export type EfficientDetectionHandler = DetectionHandler
export type ComplexDetectionHandler   = DetectionHandler
export type SimpleDetectionHandler    = DetectionHandler

export type DetectionTypes    = 'Complex'|'Simple'|'Efficient'
export type TrackerStatuses   = 'Entered'|'Exited'|'In'|'Out'

export type ZoneEngineData    = {
	ZoneContainerType: Types.ZoneContainerType;
	ZoneSettings:      Types.ZoneSettingsTable;
	ZoneStates:        Types.ZoneStatesTable;
	ZoneFolder:        Types.ZoneFolder;
	ZonePieces:        Types.ZonePieces;
	ZoneSignal:        BindableEvent;
	ZoneId:            string;
}

export type DetectionHandler = {
	--====================================================>
	DetectionType:   DetectionTypes;
	--====================================================>
	Destroying: boolean;
	Detecting:  boolean;
	--====================================================>
	_EngineData: ZoneEngineData;
	--====================================================>
	_BoundsHandler:        Bounds.DefaultHandler;

	-- For Indexing Purposes:
	_Box_BoundsHandler:     Bounds.BoxBoundsHandler;
	_PerPart_BoundsHandler: Bounds.PerPartBoundsHandler;

	_TargetHandlers: {
		LocalPlayer: TargetHandler.LocalPlayerTargetHandler?;
		Players:     TargetHandler.PlayersTargetHandler?;
		Items:       TargetHandler.TargetHandlers?;
		Parts:       TargetHandler.PartsTargetHandler?;
	};
	--====================================================>
	_CurrentParts:  {[BasePart]: boolean};
	_PreviousParts: {[BasePart]: boolean};

	_OverlapParamaters: {
		PartsIncludeList: OverlapParams;
		PartsExcludeList: OverlapParams;
	}?;

	--====================================================>

	SetDetection: 
		(self: DetectionHandler, DetectionCoverage: number, DetectionMode: number, DetectionMethod: number?) -> ();

	AddTargetHandler: 
		(self: DetectionHandler, Target: TargetHandler.TargetTypes) -> ();
	RemoveTargetHandler: 
		(self: DetectionHandler, Target: TargetHandler.TargetTypes) -> ();
	AddToCurrentParts: 
		(self: DetectionHandler, Parts: {BasePart}) -> ();
	AddToPreviousParts: 
		(self: DetectionHandler, Parts: {BasePart}) -> ();
	AddOverlapParamaters: 
		(self: DetectionHandler) -> ();
	RemoveOverlapParamaters: 
		(self: DetectionHandler) -> ();
	RemoveCurrentParts: 
		(self: DetectionHandler) -> ();
	RemovePreviousParts: 
		(self: DetectionHandler) -> ();

	GetTrackerStatus: 
		(self: DetectionHandler, TargetTracker: TargetHandler.TargetTracker, HitTargetParts: {BasePart}?) -> TrackerStatuses;
	GetBoundsHandler: 
		(self: DetectionHandler) -> Bounds.DefaultHandler;
	GetDetectionStatus: 
		(self: DetectionHandler) -> boolean;

	RunDetection: 
		(self: DetectionHandler) -> ();

	--- Function that will run the location checking code for the passed in Tracker and set its location status as well as add it to the
	--- Entrance or Exit table on the TargetHandler depending on its location status:
	ComputeTrackerLocation: (
		self: DetectionHandler,
		Key: string,
		TargetHandler: TargetHandler.DefaultTargetHandler,
		Tracker: TargetHandler.TargetTracker,
		TrackerHitParts: {BasePart}?
	) -> ();

	FireSignals: 
		(self: DetectionHandler) -> ();
	--====================================================>
	Destroy: 
		(self: DetectionHandler) -> ();
	--====================================================>
}

--=======================================================================================================>

--- Constructor function which is used by every DetectionHandler type in order to inherit core functions and values shared by all types:
function DetectionHandlerModule.Default.New(EngineData: ZoneEngineData): DetectionHandler
	--=======================================================================================================>

	-- Define the TargetData and Inherit from the Base Class:
	local DetectionData: DetectionHandler = {
		--====================================================>
		DetectionType = Enums.DetectionMethod:GetName(EngineData.ZoneSettings.DetectionMethod) :: DetectionTypes;
		--====================================================>
		Detecting  = false;
		Destroying = false;
		--====================================================>
		_EngineData = EngineData;
		--====================================================>
		_TargetHandlers = {};
		--====================================================>
		_CurrentParts  = {};
		_PreviousParts = {};
		--====================================================>
		-- Construct a new Handler Object with the Trove and Set it in the Table:
		-- Index the Target Specific Table with the Target Name to gets its New Method:
		_BoundsHandler = Bounds[Enums.Bounds:GetName(EngineData.ZoneSettings.Bounds)].New(
			-- Pass in the Current ZonePart's Array:
			EngineData.ZonePieces,
			-- Pass in whether the ZonePieces being sent are of Boxes or Parts:
			(if EngineData.ZoneContainerType == 'TableOBox' then 'Box' else 'Part'),
			-- Pass in the DetectionMethod Number:
			EngineData.ZoneSettings.DetectionMethod,
			-- Send the Zone Id:
			EngineData.ZoneId,
			-- Pass in a Boolean on whether the Execution is Serial or not:
			EngineData.ZoneSettings.Execution == Enums.Execution.Serial
		)
		--====================================================>
	} :: DetectionHandler

	--=======================================================================================================>

	-- Create BoundsHandler Reference Variables:
	do
		--==========================================================================================>
		-- Set the Relocated Variable:
		DetectionData._BoundsHandler.Relocated = EngineData.ZoneStates.Relocated

		if Enums.Bounds:GetName(EngineData.ZoneSettings.Bounds) == 'PerPart' then
			DetectionData._PerPart_BoundsHandler = DetectionData._BoundsHandler :: Bounds.PerPartBoundsHandler
		else
			DetectionData._Box_BoundsHandler = DetectionData._BoundsHandler :: Bounds.BoxBoundsHandler
		end

		--==========================================================================================>

		---- Clear the Paramater Table:
		--table.clear(EngineData)
		-- Set it to nil:
		EngineData = nil :: any

		--==========================================================================================>
	end

	--=======================================================================================================>
	--[ ADDER/REMOVER METHODS: ]


	--- Adds a new TargetHandler Object on this DetectionHandler Object:
	function DetectionData.AddTargetHandler(self: DetectionHandler, Target: TargetHandler.TargetTypes)
		--============================================================================================>
		-- If a TargetHandler Object for this Target exists already, Call the same Function but with State as False to Destroy it,
		-- Then continue to make a new Object:
		if self._TargetHandlers[Target] then self:RemoveTargetHandler(Target) end
		-- Construct a new Handler Object with the Trove and Set it in the Table:
		-- Index the Target Specific Table with the Target Name to gets its New Method:
		self._TargetHandlers[Target] = TargetHandler[Target].New(
			-- Pass in the DetectionCoverage Number:
			self._EngineData.ZoneSettings.DetectionCoverage,
			-- Pass in the DetectionMode Number:
			self._EngineData.ZoneSettings.DetectionMode,
			-- Pass in a Boolean on whether the Execution is Serial or not:
			self._EngineData.ZoneSettings.Execution == Enums.Execution.Serial
		)
		--============================================================================================>
		-- Set the Detection Status based on the Targets:
		self.Detecting = self:GetDetectionStatus()
		--============================================================================================>
		-- When a TargetHandler is added create the Overlap Paramaters if needed:
		if Target == 'Part' or self.DetectionType ~= 'Efficient' then self:AddOverlapParamaters() end
		--============================================================================================>
	end

	--- Function which Adds an Array of Parts to the CurrentParts Dictionary without adding duplicates:
	@native
	function DetectionData.AddToCurrentParts(self: DetectionHandler, Parts: {BasePart})
		--===============================================================================>
		-- Loop through the Results from the Single Part of the Zone, and Check to make sure each Part is not already in the
		-- Global Zone Results Table, if its not already added to the Results Array, Insert it to combine the zone parts:
		for Index: number, Result: BasePart in ipairs(Parts) do
			-- Check to see if the Result is already added, continue if so:
			if self._CurrentParts[Result] then continue end
			-- Insert Result to Results Table:
			self._CurrentParts[Result] = true
		end
		--===============================================================================>
	end

	--- Function which Adds an Array of Parts to the CurrentParts Dictionary without adding duplicates:
	@native
	function DetectionData.AddToPreviousParts(self: DetectionHandler, Parts: {BasePart})
		--===============================================================================>
		-- Loop through the Results from the Single Part of the Zone, and Check to make sure each Part is not already in the
		-- Global Zone Results Table, if its not already added to the Results Array, Insert it to combine the zone parts:
		for Index: number, Result: BasePart in ipairs(Parts) do
			-- Check to see if the Result is already added, continue if so:
			if self._PreviousParts[Result] then continue end
			-- Insert Result to Results Table:
			self._PreviousParts[Result] = true
		end
		--===============================================================================>
	end

	--- Function which will Add OverlapParamater Instances to the Object:
	function DetectionData.AddOverlapParamaters(self: DetectionHandler)
		--===============================================================================>
		-- If they are already created then return:
		if self._OverlapParamaters then return end

		-- Define the OverlapParams Table:
		self._OverlapParamaters = {
			PartsIncludeList = OverlapParams.new();
			PartsExcludeList = OverlapParams.new();
		}

		-- For Type Checking reasons, make sure its not nil:
		if not self._OverlapParamaters then return end

		self._OverlapParamaters.PartsIncludeList.FilterType = Enum.RaycastFilterType.Exclude
		self._OverlapParamaters.PartsIncludeList.FilterDescendantsInstances = {}
		self._OverlapParamaters.PartsIncludeList.CollisionGroup = 'Zoner:ZonePart'

		self._OverlapParamaters.PartsExcludeList.FilterType = Enum.RaycastFilterType.Exclude
		self._OverlapParamaters.PartsExcludeList.FilterDescendantsInstances = {}
		self._OverlapParamaters.PartsExcludeList.CollisionGroup = 'Zoner:ZonePart'

		--===============================================================================>
	end

	--=======================================================================================================>

	--- Function which will Remove OverlapParamater Instances from the Object:
	function DetectionData.RemoveOverlapParamaters(self: DetectionHandler)
		--===============================================================================>
		-- If they are already deleted then return:
		if self._OverlapParamaters == nil then return end
		--===============================================================================>
		self._OverlapParamaters = nil :: any
		--===============================================================================>
	end

	--- Removes an Existing TargetHandler Object from exisistance on this DetectionHandler Object:
	function DetectionData.RemoveTargetHandler(self: DetectionHandler, Target: TargetHandler.TargetTypes)
		--===============================================================================>
		-- If a TargetHandler Object exists, then Remove/Destroy it in the Trove and Set its Table value to nil:
		if self._TargetHandlers[Target] then self._TargetHandlers[Target]:Destroy(); self._TargetHandlers[Target] = nil end
		--===============================================================================>	
		-- Set the Detection Status based on the Targets:
		self.Detecting = self:GetDetectionStatus()
		--===============================================================================>	
		-- If the DetectionType is not 'Efficient', then we need to check if any other Targets are Active.
		-- If any other target is active, then dont remove the overlap, if they're none, then remove overlap:
		if self.DetectionType ~= 'Efficient' then
			-- If none are active, then remove overlap paramaters:
			if self.Detecting == false then self:RemoveOverlapParamaters() end
		else
			if Target == 'Part' then self:RemoveOverlapParamaters() end
		end
		--===============================================================================>
	end

	--- Function which clears the current parts table:
	@native
	function DetectionData.RemoveCurrentParts(self: DetectionHandler)
		table.clear(self._CurrentParts)
	end

	--- Function which clears the previous parts table:
	@native
	function DetectionData.RemovePreviousParts(self: DetectionHandler)
		table.clear(self._PreviousParts)
	end

	--=======================================================================================================>
	--[ SETTER METHODS: ]

	--- Function that will Set the Detection Enums on the TargetHandlers:
	function DetectionData.SetDetection(self: DetectionHandler, DetectionCoverage: number, DetectionMode: number, DetectionMethod: number?)
		for Target, Handler in pairs(self._TargetHandlers) do Handler:SetDetection(DetectionCoverage, DetectionMode, DetectionMethod) end
	end

	--=======================================================================================================>
	--[ GETTER METHODS: ]

	--- Function that return the BoundsHandler Object:
	function DetectionData.GetDetectionStatus(self: DetectionHandler): boolean
		--==============================================================================================>
		-- Boolean to store whether a Target Exists:
		local TargetExists = false
		-- Loop through the Targets, break at the first one in the dictionary if populated:
		for Key, Target in self._TargetHandlers do TargetExists = true break end
		-- If none are active and existing, then detection status is false, else detection status is true:
		if TargetExists == false then return false else return true end
		--==============================================================================================>
	end

	--- Function that return the BoundsHandler Object:
	function DetectionData.GetBoundsHandler(self: DetectionHandler): BoundsHandler.DefaultHandler
		return self._BoundsHandler
	end

	--- Function that will return the Status of the Target relative to the Zone:
	@native
	function DetectionData.GetTrackerStatus(self: DetectionHandler, TargetTracker: TargetHandler.TargetTracker, HitTargetParts: {BasePart}?): TrackerStatuses
		--==============================================================================================>
		-- Get the Boolean as to where this ItemTracker is currently:
		-- If the Player is in the Zone:
		local InZonePrevious, InZoneCurrent: boolean = TargetTracker.InZone, false

		if self.DetectionType == 'Complex' then
			InZoneCurrent = TargetTracker:IsInsideZoneParts(self._BoundsHandler:GetZonePieces(), HitTargetParts)
		elseif self.DetectionType == 'Simple' or self.DetectionType == 'Efficient' then
			if self._PerPart_BoundsHandler then
				InZoneCurrent = TargetTracker:IsInsideZoneParts(self._PerPart_BoundsHandler:GetZonePieces(), HitTargetParts)
			else
				InZoneCurrent = TargetTracker:IsInsideBox(self._Box_BoundsHandler.CFrame, self._Box_BoundsHandler.HalfSize, HitTargetParts)
			end
		end

		-- If the Player is now in the zone, add it to the entered table, else, exited, else do nothing:
		if InZoneCurrent then
			-- If the PlayerInZone State Previously was False as in not in the Zone, then Player is Entering:
			return if InZonePrevious == false then 'Entered' else 'In'
		else
			-- If the PlayerInZone State Previously was True as in was in the Zone, then Player is Exiting:
			return if InZonePrevious == true then 'Exited' else 'Out'
		end
		--==============================================================================================>
	end

	--=======================================================================================================>
	--[ CORE METHODS: ]


	--- Function that will run the location checking code for the passed in Tracker and set its location status as well as add it to the
	--- Entrance or Exit table on the TargetHandler depending on its location status:
	@native
	function DetectionData.ComputeTrackerLocation(self: DetectionHandler, Key: string, TargetHandler: TargetHandler.DefaultTargetHandler, Tracker: TargetHandler.TargetTracker, TrackerHitParts: {BasePart}?)
		--==============================================================================================>
		-- Get the Status of the Tracked Item relative to this Zone:
		local TrackerStatus: TrackerStatuses = self:GetTrackerStatus(Tracker, TrackerHitParts)
		--==============================================================================================>
		if TrackerStatus == 'Entered' then 
			TargetHandler:AddToEntered(TargetHandler:GetTargetItem(Key, Tracker)) 
			Tracker.InZone = true
		elseif TrackerStatus == 'Exited' then 
			TargetHandler:AddToExited(TargetHandler:GetTargetItem(Key, Tracker)) 
			Tracker.InZone = false
		end
		--==============================================================================================>
	end

	@native
	function DetectionData.FireSignals(self: DetectionHandler)
		--==============================================================================================>
		for Target: TargetHandler.TargetTypes, TargetHandler: TargetHandler.DefaultTargetHandler in pairs(self._TargetHandlers) do
			--========================================================================================>

			-- Get a Boolean on Whether Entered is Empty
			local EnteredIsEmpty, ExitedIsEmpty = (TargetHandler:GetEntered()[1] == nil), (TargetHandler:GetExited()[1] == nil)

			-- If Both Entered and Exited Arrays are empty than continue loop:
			if EnteredIsEmpty and ExitedIsEmpty then continue end

			--========================================================================================>

			-- If the Entered Array is not Empty, loop through it and then Clear its Array:
			if EnteredIsEmpty == false then
				-- Loop through the Entered Values:
				for Index: number, Value: any in ipairs(TargetHandler:GetEntered()) do 
					self._EngineData.ZoneSignal:Fire(self._EngineData.ZoneId, TargetHandler.EnteredHash, Value)
				end
				-- Clear Array:
				TargetHandler:ClearEntered()
			end

			-- If the Exited Array is not Empty, loop through it and then Clear its Array:
			if ExitedIsEmpty == false then
				-- Loop through the Exited Values:
				for Index: number, Value: any in ipairs(TargetHandler:GetExited()) do
					self._EngineData.ZoneSignal:Fire(self._EngineData.ZoneId, TargetHandler.ExitedHash, Value)
				end
				-- Clear Array:
				TargetHandler:ClearExited()
			end

			--========================================================================================>
		end
		--==============================================================================================>
	end
	
	--- Method that will destroy the object and clean up all interior data:
	function DetectionData.Destroy(self: DetectionHandler)
		--==============================================================================================>

		-- If Destroying is already true then return:
		if self.Destroying == true then return; else self.Destroying = true; end

		--==============================================================================================>

		-- Remove all Target Handlers:
		for Key, Target in pairs(self._TargetHandlers) do self:RemoveTargetHandler(Key); end

		-- Clear Table:
		self:RemoveCurrentParts()
		-- Clear Table:
		self:RemovePreviousParts()
		-- Remove Table:
		self:RemoveOverlapParamaters()

		-- Destroy the BoundsHandler:
		self._BoundsHandler:Destroy()

		-- Clear all self data:
		for Index, Data in pairs(self) do self[Index] = nil; end

		--==============================================================================================>
	end

	--=======================================================================================================>

	-- Return the DetectionHandler Object:
	return DetectionData :: DetectionHandler

	--=======================================================================================================>
end

--===========================================================================================================================>

--- Constructor function that will create a "Complex" DetectionHandler and return the Object after inheriting from "Default":
function DetectionHandlerModule.Complex.New(ZoneEngineData: ZoneEngineData): ComplexDetectionHandler
	--=======================================================================================================>

	-- Set Memory Category:
	debug.setmemorycategory('[Zoner]: -> Zoner -> Zone -> Engine -> (Detection)')

	-- Define the TargetData and Inherit from the Base Class:
	local DetectionData: ComplexDetectionHandler = DetectionHandlerModule.Default.New(ZoneEngineData) :: ComplexDetectionHandler

	--=======================================================================================================>

	-- Create OverlapParamaters for a Complex Detection Type:
	DetectionData:AddOverlapParamaters()

	--=======================================================================================================>

	@native
	function DetectionData.RunDetection(self: ComplexDetectionHandler)
		--==============================================================================================>
		-- If the Detecting Variable is false then return from this function:
		if self.Detecting == false then return end
		-- If OverlapParamaters are nil, return:
		if not self._OverlapParamaters then return end
		--==============================================================================================>

		-- Loop through the ZoneParts that make up the Zone:
		for ZonePart, Details in self._BoundsHandler:GetZoneParts() do
			--===============================================================================>
			-- Get the Results of the Inidividual Part of the Zone:
			local ZonePartResults = WorldModel:GetPartsInPart(
				self._EngineData.ZoneStates.Relocated, Details.Part, self._OverlapParamaters.PartsIncludeList
			)
			-- Loop through the Results from the Single Part of the Zone, and Check to make sure each Part is not already in the
			-- Global Zone Results Table, if its not already added to the Results Array, Insert it to combine the zone parts:
			self:AddToCurrentParts(ZonePartResults)
			--===============================================================================>
		end

		for Target: TargetHandler.TargetTypes, TargetHandler: TargetHandler.DefaultTargetHandler in pairs(self._TargetHandlers) do
			--========================================================================================>
			-- If the Target is of the Parts variety then continue:
			if Target == 'Part' then continue end

			-- Loop through the TargetHandler's Tracker Dictionary and Compute the Location for each Tracker individualy:
			-- Also use the CurrentParts Dictionary to narrow down the Tracker's Parts:
			for Key: string, Tracker in TargetHandler:GetTrackers() do
				-- Pass in the Array consisting of only the Parts detected in CurrentParts that are apart of this Tracked Object:
				self:ComputeTrackerLocation(Key, TargetHandler, Tracker, Tracker:GetTargetPartsFromHitParts(self._CurrentParts))
			end
			--========================================================================================>
		end

		-- Clear the CurrentParts Array:
		self:RemoveCurrentParts()

		--===============================================================================>
	end

	--=======================================================================================================>


	-- Set it to nil:
	ZoneEngineData = nil :: any

	-- Return the DetectionHandler Object:
	return DetectionData :: ComplexDetectionHandler

	--=======================================================================================================>
end

--- Constructor function that will create a "Simple" DetectionHandler and return the Object after inheriting from "Default":
function DetectionHandlerModule.Simple.New(ZoneEngineData: ZoneEngineData): SimpleDetectionHandler
	--=======================================================================================================>

	-- Set Memory Category:
	debug.setmemorycategory('[Zoner]: -> Zoner -> Zone -> Engine -> (Detection)')

	-- Define the TargetData and Inherit from the Base Class:
	local DetectionData: SimpleDetectionHandler = DetectionHandlerModule.Default.New(ZoneEngineData) :: SimpleDetectionHandler

	--=======================================================================================================>

	-- Create OverlapParamaters for a Complex Detection Type:
	DetectionData:AddOverlapParamaters()

	--=======================================================================================================>

	@native
	function DetectionData.RunDetection(self: SimpleDetectionHandler)
		--==============================================================================================>
		-- If the Detecting Variable is false then return from this function:
		if self.Detecting == false then return end
		-- If OverlapParamaters are nil, return:
		if not self._OverlapParamaters then return end
		--==============================================================================================>

		-- CHECK IF THE GETZONEPIECES LOOP RUNS ONCE WITH BOX BOUNDS HANDLER:

		if self._Box_BoundsHandler then
			--=======================================================================================>
			-- Get the Results of the Inidividual Part of the Zone:
			local ZonePartResults = WorldModel:GetPartBoundsInBox(
				self._EngineData.ZoneStates.Relocated,
				self._Box_BoundsHandler.CFrame,
				self._Box_BoundsHandler.Size,
				self._OverlapParamaters.PartsIncludeList
			)
			-- Loop through the Results from the Single Part of the Zone, and Check to make sure each Part is not already in the
			-- Global Zone Results Table, if its not already added to the Results Array, Insert it to combine the zone parts:
			self:AddToCurrentParts(ZonePartResults)
			--=======================================================================================>
		else
			--=======================================================================================>
			-- Loop through the ZoneParts that make up the Zone:
			for Key, Details in self._BoundsHandler:GetZonePieces() do
				--===============================================================================>
				-- Get the Results of the Inidividual Part of the Zone:
				local ZonePartResults = WorldModel:GetPartBoundsInBox(
					self._EngineData.ZoneStates.Relocated,
					Details.CFrame or Details.Part.CFrame,
					Details.Size,
					self._OverlapParamaters.PartsIncludeList
				)
				-- Loop through the Results from the Single Part of the Zone, and Check to make sure each Part is not already in the
				-- Global Zone Results Table, if its not already added to the Results Array, Insert it to combine the zone parts:
				self:AddToCurrentParts(ZonePartResults)
				--===============================================================================>
			end
			--=======================================================================================>
		end


		for Target: TargetHandler.TargetTypes, TargetHandler: TargetHandler.DefaultTargetHandler in pairs(self._TargetHandlers) do
			--========================================================================================>
			-- If the Target is of the Parts variety then continue:
			if Target == 'Part' then continue end

			-- Loop through the TargetHandler's Tracker Dictionary and Compute the Location for each Tracker individualy:
			-- Also use the CurrentParts Dictionary to narrow down the Tracker's Parts:
			for Key: string, Tracker in TargetHandler:GetTrackers() do
				-- Pass in the Array consisting of only the Parts detected in CurrentParts that are apart of this Tracked Object:
				self:ComputeTrackerLocation(Key, TargetHandler, Tracker, Tracker:GetTargetPartsFromHitParts(self._CurrentParts))
			end
			--========================================================================================>
		end

		-- Clear the CurrentParts Array:
		self:RemoveCurrentParts()

		--===============================================================================>
	end


	-- Set it to nil:
	ZoneEngineData = nil :: any

	--=======================================================================================================>

	-- Return the DetectionHandler Object:
	return DetectionData :: SimpleDetectionHandler

	--=======================================================================================================>
end

--- Constructor function that will create a "Efficient" DetectionHandler and return the Object after inheriting from "Default":
function DetectionHandlerModule.Efficient.New(ZoneEngineData: ZoneEngineData): EfficientDetectionHandler
	--=======================================================================================================>

	-- Set Memory Category:
	debug.setmemorycategory('[Zoner]: -> Zoner -> Zone -> Engine -> (Detection)')

	-- Define the TargetData and Inherit from the Base Class:
	local DetectionData: EfficientDetectionHandler = DetectionHandlerModule.Default.New(ZoneEngineData) :: EfficientDetectionHandler

	--=======================================================================================================>

	@native
	function DetectionData.RunDetection(self: EfficientDetectionHandler)
		--==============================================================================================>
		-- If the Detecting Variable is false then return from this function:
		if self.Detecting == false then return end

		for Target: TargetHandler.TargetTypes, TargetHandler: TargetHandler.DefaultTargetHandler in pairs(self._TargetHandlers) do
			--========================================================================================>
			-- If the Target is of the Parts variety then continue:
			if Target == 'Part' then continue end

			-- Loop through the TargetHandler's Tracker Dictionary and Compute the Location for each Tracker individualy:
			for Key: string, Tracker in TargetHandler:GetTrackers() do
				-- Compute the Location of the passed in Tracker:
				self:ComputeTrackerLocation(Key, TargetHandler, Tracker)
			end
			--========================================================================================>
		end
		--===============================================================================>
	end


	-- Clear the Paramater Table:

	-- Set it to nil:
	ZoneEngineData = nil :: any

	--=======================================================================================================>

	-- Return the DetectionHandler Object:
	return DetectionData :: EfficientDetectionHandler

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(DetectionHandlerModule) :: DetectionHandlerModule

--===========================================================================================================================>