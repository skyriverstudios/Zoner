--===========================================================================================================================>
--!optimize 2
--!strict
--===========================================================================================================================>

-- Define Module table
local DetectionHandlerModule: DetectionHandlerModule = {Default = {}; Complex  = {}; Simple = {}; Efficient = {}}

--===========================================================================================================================>
--[ VARIABLES: ]

-- Require the ZoneUtilities Module:
local ZoneUtilities = require(script:FindFirstAncestor('Zone').Children.ZoneUtilities);

local ZonerModule = script.Parent.Parent.Parent.Parent.Parent.Parent.Parent

local WorldModel = require(ZonerModule.Classes.Core.WorldModel);
local Regions    = require(ZonerModule.Classes.Utilities.Regions);
local Enums      = require(ZonerModule.Classes.Utilities.Enums);

local BoundsHandler = require(script.Classes.BoundsHandler);
local TargetHandler = require(script.Classes.TargetHandler);

-- Import the Shared Types:
local SharedTypes = require(ZonerModule.Types.SharedTypes)

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local TypeDefinitions = require(script.Types)

-- Make the Module into a Type:
export type DetectionHandlerModule = typeof(DetectionHandlerModule)


export type ZonePieces              = SharedTypes.ZonePieces
export type ZoneBoxes               = SharedTypes.ZoneBoxes
export type ZoneParts               = SharedTypes.ZoneParts

export type TargetTypes             = TargetHandler.TargetTypes

type DetectionTypes          = 'Complex'|'Simple'|'Efficient'
type TrackerStatuses         = 'Entered'|'Exited'|'In'|'Out'
type TargetTracker         = TargetHandler.TargetTracker

type ZoneSettingsTable = SharedTypes.ZoneSettingsTable
type ZoneStatesTable   = SharedTypes.ZoneStatesTable



type ZoneContainerType              = SharedTypes.ZoneContainerType

export type DetectionHandler = {
	--====================================================>
	DetectionType:   'Complex' | 'Simple' | 'Efficient';
	--====================================================>
	Destroying: boolean;
	Detecting:  boolean;
	Serial:     boolean;
	--====================================================>
	_Settings: SharedTypes.ZoneSettingsTable;
	_States:   SharedTypes.ZoneStatesTable;
	_Id: string;
	--====================================================>
	_BoundsHandler:        BoundsHandler.DefaultHandler;

	-- For Indexing Purposes:
	_Box_BoundsHandler:     BoundsHandler.BoxBoundsHandler;
	_PerPart_BoundsHandler: BoundsHandler.PerPartBoundsHandler;

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

	SetBoundsHandler: 
		(self: DetectionHandler, Bounds: number, ZonePieces: ZonePieces, ContainerType: ZoneContainerType) -> ();
	SetDetection: 
		(self: DetectionHandler, DetectionCoverage: number, DetectionMode: number, DetectionMethod: number?) -> ();

	AddTargetHandler: 
		(self: DetectionHandler, Target: TargetHandler.TargetTypes) -> ();
	RemoveTargetHandler: 
		(self: DetectionHandler, Target: TargetHandler.TargetTypes) -> ();
	AddToCurrentParts: 
		(self: DetectionHandler, Parts: {BasePart}) -> ();
	AddOverlapParamaters: 
		(self: DetectionHandler) -> ();
	RemoveOverlapParamaters: 
		(self: DetectionHandler) -> ();
	RemoveCurrentParts: 
		(self: DetectionHandler) -> ();

	GetTrackerStatus: 
		(self: DetectionHandler, TargetTracker: TargetTracker, HitTargetParts: {BasePart}?) -> TrackerStatuses;
	GetBoundsHandler: 
		(self: DetectionHandler) -> BoundsHandler.DefaultHandler;
	GetDetectionStatus: 
		(self: DetectionHandler) -> boolean;

	RunDetection: 
		(self: DetectionHandler) -> ();

	--====================================================>
	Destroy: 
		(self: DetectionHandler) -> ();
	--====================================================>
}

export type ComplexDetectionHandler = {

	RunDetection: 
		(self: ComplexDetectionHandler) -> ();

} & DetectionHandler

export type SimpleDetectionHandler = {

	RunDetection: 
		(self: SimpleDetectionHandler) -> ();

} & DetectionHandler

export type EfficientDetectionHandler = {


	RunDetection: 
		(self: EfficientDetectionHandler) -> ();

} & DetectionHandler


--=======================================================================================================>

function DetectionHandlerModule.Default.New(Identifier: string, Settings: ZoneSettingsTable, States: ZoneStatesTable): DetectionHandler
	--=======================================================================================================>

	-- Define the TargetData and Inherit from the Base Class:
	local DetectionData: DetectionHandler = {
		--====================================================>
		DetectionType = Enums.Enums.DetectionMethod:GetName(Settings.DetectionMethod) :: DetectionTypes;

		Detecting = false;

		_Settings = Settings;
		_States   = States;
		_TargetHandlers = {};
		--====================================================>
		_CurrentParts  = {};
		_PreviousParts = {};

		--====================================================>
	} :: DetectionHandler

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
			self._Settings.DetectionCoverage,
			-- Pass in the DetectionMode Number:
			self._Settings.DetectionMode,
			-- Pass in a Boolean on whether the Execution is Serial or not:
			self._Settings.Execution == Enums.Enums.Execution.Serial
		)
		--============================================================================================>
		-- Set the Detection Status based on the Targets:
		self.Detecting = self:GetDetectionStatus()
		--============================================================================================>
		-- When a TargetHandler is added create the Overlap Paramaters if needed:
		if Target == 'Parts' or self.DetectionType ~= 'Efficient' then self:AddOverlapParamaters() end
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

		self._OverlapParamaters.PartsIncludeList.FilterType = Enum.RaycastFilterType.Include
		self._OverlapParamaters.PartsIncludeList.FilterDescendantsInstances = {}

		self._OverlapParamaters.PartsExcludeList.FilterType = Enum.RaycastFilterType.Exclude
		self._OverlapParamaters.PartsExcludeList.FilterDescendantsInstances = {}
		--===============================================================================>
	end

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
			if Target == 'Parts' then self:RemoveOverlapParamaters() end
		end
		--===============================================================================>
	end

	--- Function which clears the current parts table:
	@native
	function DetectionData.RemoveCurrentParts(self: DetectionHandler)
		table.clear(self._CurrentParts)
	end

	--=======================================================================================================>
	--[ SETTER METHODS: ]

	--- Function that will Set Up the BoundsHandler on this Object:
	function DetectionData.SetBoundsHandler(self: DetectionHandler, Bounds: number, ZonePieces: ZonePieces, ContainerType: ZoneContainerType)
		--=======================================================================================================>
		local BoundsName: BoundsHandler.BoundsTypes = Enums.Enums.Bounds:GetName(Bounds) :: BoundsHandler.BoundsTypes
		local PieceType: 'Box' | 'Part' = if ContainerType == 'TableOBox' then 'Box' else 'Part'

		-- Construct a new Handler Object with the Trove and Set it in the Table:
		-- Index the Target Specific Table with the Target Name to gets its New Method:
		self._BoundsHandler = BoundsHandler[BoundsName].New(
			-- Pass in the Current ZonePart's Array:
			ZonePieces,
			-- Pass in whether the ZonePieces being sent are of Boxes or Parts:
			PieceType,
			-- Pass in the DetectionMethod Number:
			self._Settings.DetectionMethod,
			-- Send the Zone Id:
			DetectionData._Id,
			-- Pass in a Boolean on whether the Execution is Serial or not:
			self._Settings.Execution == Enums.Enums.Execution.Serial
		)

		-- Set the Relocated Variable:
		self._BoundsHandler.Relocated = self._States.Relocated

		if BoundsName == 'PerPart' then
			self._PerPart_BoundsHandler = self._BoundsHandler :: BoundsHandler.PerPartBoundsHandler
		else
			self._Box_BoundsHandler = self._BoundsHandler :: BoundsHandler.BoxBoundsHandler
		end
		--=======================================================================================================>
	end

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
	function DetectionData.GetTrackerStatus(self: DetectionHandler, TargetTracker: TargetTracker, HitTargetParts: {BasePart}?): TrackerStatuses
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

	-- Return the DetectionHandler Object:
	return DetectionData :: DetectionHandler

	--=======================================================================================================>
end

--===========================================================================================================================>

function DetectionHandlerModule.Complex.New(Identifier: string, Settings: ZoneSettingsTable, States: ZoneStatesTable): ComplexDetectionHandler
	--=======================================================================================================>

	-- Define the TargetData and Inherit from the Base Class:
	local DetectionData: ComplexDetectionHandler = DetectionHandlerModule.Default.New(Identifier, Settings, States) :: ComplexDetectionHandler

	--=======================================================================================================>

	-- Create OverlapParamaters for a Complex Detection Type:
	DetectionData:AddOverlapParamaters()

	--=======================================================================================================>

	@native
	function DetectionData.RunDetection(self: ComplexDetectionHandler)
		--==============================================================================================>

		if self.Detecting == false then return end

		-- If OverlapParamaters are nil, return:
		if not self._OverlapParamaters then return end

		--==============================================================================================>

		-- Loop through the ZoneParts that make up the Zone:
		for ZonePart, Details in self._BoundsHandler:GetZoneParts() do
			--===============================================================================>
			-- Get the Results of the Inidividual Part of the Zone:
			local ZonePartResults = WorldModel:GetPartsInPart(
				self._States.Relocated, Details.Part, self._OverlapParamaters.PartsIncludeList
			)
			--===============================================================================>
			-- Loop through the Results from the Single Part of the Zone, and Check to make sure each Part is not already in the
			-- Global Zone Results Table, if its not already added to the Results Array, Insert it to combine the zone parts:
			self:AddToCurrentParts(ZonePartResults)
			--===============================================================================>
		end

		for Target: TargetTypes, TargetHandler: TargetHandler.DefaultTargetHandler in pairs(self._TargetHandlers) do
			--========================================================================================>

			-- If the Target is of the Parts variety then continue:
			if Target == 'Parts' then continue end

			for Key: string, Tracker in TargetHandler:GetTrackers() do
				--=================================================================================>
				-- Return an Array consisting of only the Parts detected in CurrentParts that are apart of this Tracked Object:
				local TrackerHitParts: {BasePart} = Tracker:GetTargetPartsFromHitParts(self._CurrentParts)
				-- Get the Status of the Tracked Item relative to this Zone:
				local TrackerStatus: TrackerStatuses = self:GetTrackerStatus(Tracker, TrackerHitParts)
				--=================================================================================>
				if TrackerStatus == 'Entered' then 
					TargetHandler:AddToEntered(TargetHandler:GetTargetItem(Key, Tracker)) 
				elseif TrackerStatus == 'Exited' then 
					TargetHandler:AddToExited(TargetHandler:GetTargetItem(Key, Tracker)) 
				end
				--=================================================================================>
				-- Set whether the Tracker is currently in the Zone or not:
				if TrackerStatus == 'Entered' or TrackerStatus == 'In' then Tracker.InZone = true else Tracker.InZone = false end
				--=================================================================================>
			end

			--========================================================================================>
		end

		-- Clear the CurrentParts Array:
		self:RemoveCurrentParts()

		--===============================================================================>
	end

	--=======================================================================================================>

	-- Return the DetectionHandler Object:
	return DetectionData :: ComplexDetectionHandler

	--=======================================================================================================>
end

function DetectionHandlerModule.Simple.New(Identifier: string, Settings: ZoneSettingsTable, States: ZoneStatesTable): SimpleDetectionHandler
	--=======================================================================================================>

	-- Define the TargetData and Inherit from the Base Class:
	local DetectionData: SimpleDetectionHandler = DetectionHandlerModule.Default.New(Identifier, Settings, States) :: SimpleDetectionHandler

	--=======================================================================================================>

	-- Create OverlapParamaters for a Complex Detection Type:
	DetectionData:AddOverlapParamaters()

	--=======================================================================================================>

	@native
	function DetectionData.RunDetection(self: SimpleDetectionHandler)
		--==============================================================================================>

		if self.Detecting == false then return end

		-- If OverlapParamaters are nil, return:
		if not self._OverlapParamaters then return end

		--==============================================================================================>
		
		-- CHECK IF THE GETZONEPIECES LOOP RUNS ONCE WITH BOX BOUNDS HANDLER:
		
		if self._Box_BoundsHandler then
			--=======================================================================================>
			-- Get the Results of the Inidividual Part of the Zone:
			local ZonePartResults = WorldModel:GetPartBoundsInBox(
				self._States.Relocated, self._Box_BoundsHandler.CFrame, self._Box_BoundsHandler.Size, self._OverlapParamaters.PartsIncludeList
			)
			--=======================================================================================>
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
					self._States.Relocated, Details.CFrame or Details.Part.CFrame, Details.Size, self._OverlapParamaters.PartsIncludeList
				)
				--===============================================================================>
				-- Loop through the Results from the Single Part of the Zone, and Check to make sure each Part is not already in the
				-- Global Zone Results Table, if its not already added to the Results Array, Insert it to combine the zone parts:
				self:AddToCurrentParts(ZonePartResults)
				--===============================================================================>
			end
			--=======================================================================================>
		end
		

		for Target: TargetTypes, TargetHandler: TargetHandler.DefaultTargetHandler in pairs(self._TargetHandlers) do
			--========================================================================================>

			-- If the Target is of the Parts variety then continue:
			if Target == 'Parts' then continue end

			for Key: string, Tracker in TargetHandler:GetTrackers() do
				--=================================================================================>
				-- Return an Array consisting of only the Parts detected in CurrentParts that are apart of this Tracked Object:
				local TrackerHitParts: {BasePart} = Tracker:GetTargetPartsFromHitParts(self._CurrentParts)
				-- Get the Status of the Tracked Item relative to this Zone:
				local TrackerStatus: TrackerStatuses = self:GetTrackerStatus(Tracker, TrackerHitParts)
				--=================================================================================>
				if TrackerStatus == 'Entered' then 
					TargetHandler:AddToEntered(TargetHandler:GetTargetItem(Key, Tracker)) 
				elseif TrackerStatus == 'Exited' then 
					TargetHandler:AddToExited(TargetHandler:GetTargetItem(Key, Tracker)) 
				end
				--=================================================================================>
				-- Set whether the Tracker is currently in the Zone or not:
				if TrackerStatus == 'Entered' or TrackerStatus == 'In' then Tracker.InZone = true else Tracker.InZone = false end
				--=================================================================================>
			end

			--========================================================================================>
		end

		-- Clear the CurrentParts Array:
		self:RemoveCurrentParts()

		--===============================================================================>
	end

	--=======================================================================================================>

	-- Return the DetectionHandler Object:
	return DetectionData :: SimpleDetectionHandler

	--=======================================================================================================>
end

function DetectionHandlerModule.Efficient.New(Identifier: string, Settings: ZoneSettingsTable, States: ZoneStatesTable): EfficientDetectionHandler
	--=======================================================================================================>

	-- Define the TargetData and Inherit from the Base Class:
	local DetectionData: EfficientDetectionHandler = DetectionHandlerModule.Default.New(Identifier, Settings, States) :: EfficientDetectionHandler

	--=======================================================================================================>

	@native
	function DetectionData.RunDetection(self: EfficientDetectionHandler)
		--==============================================================================================>

		if self.Detecting == false then return end

		for Target: TargetTypes, TargetHandler: TargetHandler.DefaultTargetHandler in pairs(self._TargetHandlers) do
			--========================================================================================>

			-- If the Target is of the Parts variety then continue:
			if Target == 'Parts' then continue end

			for Key: string, Tracker in TargetHandler:GetTrackers() do
				--=================================================================================>
				-- Get the Status of the Tracked Item relative to this Zone:
				local TrackerStatus: TrackerStatuses = self:GetTrackerStatus(Tracker)
				--=================================================================================>
				if TrackerStatus == 'Entered' then 
					TargetHandler:AddToEntered(TargetHandler:GetTargetItem(Key, Tracker)) 
				elseif TrackerStatus == 'Exited' then 
					TargetHandler:AddToExited(TargetHandler:GetTargetItem(Key, Tracker)) 
				end
				--=================================================================================>
				-- Set whether the Tracker is currently in the Zone or not:
				if TrackerStatus == 'Entered' or TrackerStatus == 'In' then Tracker.InZone = true else Tracker.InZone = false end
				--=================================================================================>
			end

			--========================================================================================>
		end

		--===============================================================================>
	end

	--=======================================================================================================>

	-- Return the DetectionHandler Object:
	return DetectionData :: EfficientDetectionHandler

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Freeze each Sub Table:
table.freeze(DetectionHandlerModule.Efficient)
table.freeze(DetectionHandlerModule.Default)
table.freeze(DetectionHandlerModule.Complex)
table.freeze(DetectionHandlerModule.Simple)

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(DetectionHandlerModule) :: DetectionHandlerModule

--===========================================================================================================================>