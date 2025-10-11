--===========================================================================================================================>
--!optimize 2
--!native
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory("[Zoner]: Detection")

-- Define Module table
local DetectionHandlers = { Complex = {}, Simple = {}, Efficient = {} }

--===========================================================================================================================>
--[ DEPENDENCIES: ]

-- [ Global Requires ]

local WorldModel = require(`../WorldModel`)
local Groups     = require(`../../Groups`)
local Enums      = require(`../../Enums`)

-- [ Sub Requires ]

local Bounds    = require(`@self/Bounds`)
local Targets   = require(`@self/Targets`)
local Tracker   = require(`@self/Tracker`)
local Coverages = require(`@self/Coverages`)

--===========================================================================================================================>
--[ CONSTANTS: ]

-- Constant Enum Variables:
local ENTERED: number, EXITED: number, IN: number, OUT: number = 1, 2, 3, 4

-- Function to use on Evaluate:
local DO_NOTHING = function() end

--===========================================================================================================================>
--[ TYPES: ]

-- [ Require Types ]

-- This will inject all types into this context.
local Zoner_Types = require(`../../../../Types`)

-- [ Define Types ]

-- Define the Tracker Status function used to Get the Specific Status based on bounds:
type TrackerStatusFunction = (
	ZoneId: string,
	Tracker: Tracker.Tracker<Tracker.Trackables>,
	HitTargetParts: { BasePart }?
) -> number

-- Define ZoneEngine Data/Profile sent from ZoneEngine:
type ZoneEngineData = {
	ZoneContainer: Zoner_Types.ZoneContainer,
	ZoneContainerType: Zoner_Types.ZoneContainerType,
	ZoneConfig: Zoner_Types.ZoneConfigTable,
	ZoneStates: Zoner_Types.ZoneStatesTable,
	ZoneFolder: Zoner_Types.ZoneFolder,
	ZonePieces: Zoner_Types.ZonePieces,
	ZoneId: string,

	ZoneSignalEvent: BindableEvent?,
	ZoneSignalFunction: ((Purpose: string, ...any) -> ())?,
}

-- Export the Object:
export type DetectionHandler = {
	--====================================================>
	Destroying: boolean,
	Detecting: boolean,
	--====================================================>
	_BoundsHandler: Bounds.BoundsHandler,

	_TargetHandlers: { [string]: Targets.TargetHandler },

	--====================================================>
	_CurrentParts: { [BasePart]: boolean },

	_OverlapParamaters: {
		PartsExcludeList: OverlapParams,
	}?,

	AddBoundsEvaluateFunction: (self: DetectionHandler, Target: Targets.TargetTypes) -> (),
	AddTargetHandler: (self: DetectionHandler, Target: Targets.TargetTypes) -> (),
	RemoveBoundsEvaluateFunction: (self: DetectionHandler, Target: Targets.TargetTypes) -> (),
	RemoveTargetHandler: (self: DetectionHandler, Target: Targets.TargetTypes) -> (),

	AddToCurrentParts: (self: DetectionHandler, Parts: { BasePart }) -> (),
	AddOverlapParamaters: (self: DetectionHandler) -> (),
	RemoveOverlapParamaters: (self: DetectionHandler) -> (),
	RemoveCurrentParts: (self: DetectionHandler) -> (),

	UpdateDetectionCoverage: (self: DetectionHandler) -> (),

	GetBoundsHandler: (self: DetectionHandler) -> Bounds.BoundsHandler,
	GetDetectionStatus: (self: DetectionHandler) -> boolean,

	-- Function that will run the location checking code for the passed in Tracker and set its location status as well as add it to the
	-- Entrance or Exit table on the TargetHandler depending on its location status:
	ComputeTrackerLocation: (
		self: DetectionHandler,
		Key: string,
		TargetHandler: Targets.TargetHandler,
		Tracker: Tracker.Tracker<Tracker.Trackables>,
		TrackerHitParts: { BasePart }?
	) -> (),

	ComputePartLocations: (self: DetectionHandler, TargetHandler: Targets.TargetHandler) -> (),

	-- We send Active Signals table from the Engine instead of storing it as a reference here:
	FireSignals: (self: DetectionHandler, ActiveSignals: Zoner_Types.ZoneActiveSignalsTable) -> (),

	Evaluate: (self: DetectionHandler) -> (),

	--====================================================>
	Destroy: (self: DetectionHandler) -> (),
	--====================================================>
}

--===========================================================================================================================>

-- Function to Fire Signals in Parallel:
local function FireSignals_Parallel(
	TargetHandlers: { [string]: Targets.TargetHandler },
	ZoneId: string,
	ZoneSignal: BindableEvent,
	ActiveSignals: Zoner_Types.ZoneActiveSignalsTable
)
	--=======================================================================================================>
	-- Loop through all the target handlers to run each of their signals:
	for Target, TargetHandler: Targets.TargetHandler in TargetHandlers do
		--========================================================================================>
		-- Get a Boolean on Whether Entered is Empty
		local EnteredIsEmpty, ExitedIsEmpty =
			(TargetHandler:GetEntered()[1] == nil), (TargetHandler:GetExited()[1] == nil)

		-- If Both Entered and Exited Arrays are empty than continue loop:
		if EnteredIsEmpty and ExitedIsEmpty then
			continue
		end

		--========================================================================================>
		-- We will dynamically index the Active Signal boolean via the Target Name (Part, Item, Player, LocalPlayer)
		-- and then we will concat the type of signal we are checking (Entered or Exited) and check whether its currently activew
		-- before we go ahead with firing its event:

		-- If the Entered Array is not Empty, loop through it and then Clear its Array:
		if EnteredIsEmpty == false then
			-- If the Signal indexed is Active (has connections)
			if ActiveSignals[`{Target}Entered`] == true then
				-- Loop through the Entered Values:
				for Index: number, Value: any in ipairs(TargetHandler:GetEntered()) do
					ZoneSignal:Fire(ZoneId, TargetHandler.EnteredHash, Value)
				end
			end
			-- Clear Array:
			TargetHandler:ClearEntered()
		end

		-- If the Exited Array is not Empty, loop through it and then Clear its Array:
		if ExitedIsEmpty == false then
			-- If the Signal indexed is Active (has connections)
			if ActiveSignals[`{Target}Exited`] == true then
				-- Loop through the Exited Values:
				for Index: number, Value: any in ipairs(TargetHandler:GetExited()) do
					ZoneSignal:Fire(ZoneId, TargetHandler.ExitedHash, Value)
				end
			end
			-- Clear Array:
			TargetHandler:ClearExited()
		end

		--========================================================================================>
	end
	--=======================================================================================================>
end

-- Function to Fire Signals in Serial:
local function FireSignals_Serial(
	TargetHandlers: { [string]: Targets.TargetHandler },
	ZoneId: string,
	ZoneSignalFunction: (Purpose: string, ...any) -> (),
	ActiveSignals: Zoner_Types.ZoneActiveSignalsTable
)
	--=======================================================================================================>
	-- Loop through all the target handlers to run each of their signals:
	for Target, TargetHandler: Targets.TargetHandler in TargetHandlers do
		--========================================================================================>

		-- Get a Boolean on Whether Entered is Empty
		local EnteredIsEmpty, ExitedIsEmpty =
			(TargetHandler:GetEntered()[1] == nil), (TargetHandler:GetExited()[1] == nil)

		-- If Both Entered and Exited Arrays are empty than continue loop:
		if EnteredIsEmpty and ExitedIsEmpty then
			continue
		end

		--========================================================================================>
		-- We will dynamically index the Active Signal boolean via the Target Name (Part, Item, Player, LocalPlayer)
		-- and then we will concat the type of signal we are checking (Entered or Exited) and check whether its currently activew
		-- before we go ahead with firing its event:

		-- If the Entered Array is not Empty, loop through it and then Clear its Array:
		if EnteredIsEmpty == false then
			-- If the Signal indexed is Active (has connections)
			if ActiveSignals[`{Target}Entered`] == true then
				-- Loop through the Entered Values:
				for Index: number, Value: any in ipairs(TargetHandler:GetEntered()) do
					ZoneSignalFunction(TargetHandler.EnteredHash, Value)
				end
			end
			-- Clear Array:
			TargetHandler:ClearEntered()
		end

		-- If the Exited Array is not Empty, loop through it and then Clear its Array:
		if ExitedIsEmpty == false then
			-- If the Signal indexed is Active (has connections)
			if ActiveSignals[`{Target}Exited`] == true then
				-- Loop through the Exited Values:
				for Index: number, Value: any in ipairs(TargetHandler:GetExited()) do
					ZoneSignalFunction(TargetHandler.ExitedHash, Value)
				end
			end
			-- Clear Array:
			TargetHandler:ClearExited()
		end

		--========================================================================================>
	end
	--=======================================================================================================>
end

--===========================================================================================================================>

-- Constructor function which is used by every DetectionHandler type in order to inherit core functions and values shared by all types:
local function DetectionHandler(EngineData: ZoneEngineData): DetectionHandler
	--=======================================================================================================>

	-- Locally define Function references:
	local GetTrackerStatus: TrackerStatusFunction

	-- Define the TargetData and Inherit from the Base Class:
	local DetectionData: DetectionHandler = {
		--====================================================>
		Detecting = false,
		Destroying = false,
		--====================================================>
		_TargetHandlers = {},
		--====================================================>
		_CurrentParts = {},
		--====================================================>
		-- Construct a new Handler Object with the Trove and Set it in the Table:
		-- Index the Target Specific Table with the Target Name to gets its New Method:
		_BoundsHandler = Bounds[Enums.Bounds:GetName(EngineData.ZoneConfig.Bounds)].New(EngineData),
		--====================================================>
	} :: DetectionHandler

	--=======================================================================================================>

	-- Set the Evaluate Function to 'DO_NOTHING':
	DetectionData._BoundsHandler.Evaluate = DO_NOTHING

	-- If the Zone Engine is in Serial, and a ZoneSignal Function is passed, Construct a FireSignals function that is meant
	-- for using the ZoneSignal Callback function:
	-- else use the BindableEvent version. Construct an empty function if nothing is present as a saftey percaution:
	if EngineData.ZoneSignalFunction then
		function DetectionData.FireSignals(self: DetectionHandler, ActiveSignals: Zoner_Types.ZoneActiveSignalsTable)
			FireSignals_Serial(
				DetectionData._TargetHandlers,
				EngineData.ZoneId,
				EngineData.ZoneSignalFunction,
				ActiveSignals
			)
		end
	elseif EngineData.ZoneSignalEvent then
		function DetectionData.FireSignals(self: DetectionHandler, ActiveSignals: Zoner_Types.ZoneActiveSignalsTable)
			FireSignals_Parallel(
				DetectionData._TargetHandlers,
				EngineData.ZoneId,
				EngineData.ZoneSignalEvent,
				ActiveSignals
			)
		end
	else
		function DetectionData.FireSignals(self: DetectionHandler, ActiveSignals: Zoner_Types.ZoneActiveSignalsTable)
			warn("Empty FireSignals Function, something seriously wrong")
		end
	end

	--=======================================================================================================>

	-- Function that return the BoundsHandler Object:
	function DetectionData.UpdateDetectionCoverage(self: DetectionHandler)
		--============================================================================================>
		if
			EngineData.ZoneConfig.DetectionMethod == Enums.DetectionMethod.Complex
			or DetectionData._BoundsHandler:GetBoundType() == "PerPart"
		then
			--=================================================================================>
			-- Cache the Coverage Function:
			local InZoneCoverage = Coverages.InZoneParts[EngineData.ZoneConfig.DetectionCoverage]
			-- Cache the BoundsHandler:
			local BoundsHandler = DetectionData._BoundsHandler
			--=================================================================================>

			-- If Enter and Exit Detection Coverage's are set:
			if EngineData.ZoneConfig.EnterDetectionCoverage or EngineData.ZoneConfig.ExitDetectionCoverage then
				-- Local ExitDetection Coverage var
				local Exit_DetectionCoverage

				-- This will auto swap AllParts and AnyPart detection coverage functionality, because on exit, its the opposite
				-- logic that we want:
				if EngineData.ZoneConfig.ExitDetectionCoverage then
					if Enums.DetectionCoverage:GetName(EngineData.ZoneConfig.ExitDetectionCoverage) == "AllParts" then
						Exit_DetectionCoverage = Enums.DetectionCoverage.AnyPart
					elseif
						Enums.DetectionCoverage:GetName(EngineData.ZoneConfig.ExitDetectionCoverage) == "AnyPart"
					then
						Exit_DetectionCoverage = Enums.DetectionCoverage.AllParts
					else
						Exit_DetectionCoverage = EngineData.ZoneConfig.ExitDetectionCoverage
					end
				end

				-- Cache the Coverage Function:
				local InZoneCoverage_Enter = if EngineData.ZoneConfig.EnterDetectionCoverage
					then Coverages.InZoneParts[EngineData.ZoneConfig.EnterDetectionCoverage]
					else InZoneCoverage
				-- Cache the Coverage Function:
				local InZoneCoverage_Exit = if Exit_DetectionCoverage
					then Coverages.InZoneParts[Exit_DetectionCoverage]
					else InZoneCoverage

				local DetectionMode_Enter = EngineData.ZoneConfig.EnterDetectionMode
					or EngineData.ZoneConfig.DetectionMode
				local DetectionMode_Exit = EngineData.ZoneConfig.ExitDetectionMode
					or EngineData.ZoneConfig.DetectionMode

				-- Create the function for Boxes:
				GetTrackerStatus = function(
					ZoneId: string,
					Tracker: Tracker.Tracker<Tracker.Trackables>,
					HitTargetParts: { BasePart }?
				): number
					--=======================================================================================================>
					-- If the Tracker is NOT currently in the Zone, check its entrance:
					if Tracker:InZone(ZoneId) ~= true then
						-- If the Player is now in the zone, add it to the entered table, else, exited, else do nothing:
						if
							InZoneCoverage_Enter(
								Tracker:GetPartsList(),
								DetectionMode_Enter,
								BoundsHandler:GetZonePartDetailsMap(),
								HitTargetParts
							)
						then
							return ENTERED
						else
							return OUT
						end
					else
						-- If the Player is now in the zone, add it to the entered table, else, exited, else do nothing:
						if
							InZoneCoverage_Exit(
								Tracker:GetPartsList(),
								DetectionMode_Exit,
								BoundsHandler:GetZonePartDetailsMap(),
								HitTargetParts
							)
						then
							return IN
						else
							return EXITED
						end
					end
					--=======================================================================================================>
				end
			else
				-- Create the function for Boxes:
				GetTrackerStatus = function(
					ZoneId: string,
					Tracker: Tracker.Tracker<Tracker.Trackables>,
					HitTargetParts: { BasePart }?
				): number
					--=======================================================================================================>
					-- If the Player is now in the zone, add it to the entered table, else, exited, else do nothing:
					if
						InZoneCoverage(
							Tracker:GetPartsList(),
							EngineData.ZoneConfig.DetectionMode,
							BoundsHandler:GetZonePartDetailsMap(),
							HitTargetParts
						)
					then
						-- If the PlayerInZone State Previously was False as in not in the Zone, then Player is Entering:
						return if Tracker:InZone(ZoneId) ~= true then ENTERED else IN
					else
						-- If the PlayerInZone State Previously was True as in was in the Zone, then Player is Exiting:
						return if Tracker:InZone(ZoneId) == true then EXITED else OUT
					end
					--=======================================================================================================>
				end
			end
			--=================================================================================>
		else
			--=================================================================================>
			-- Cache the Coverage Function:
			local InZoneCoverage = Coverages.InBox[EngineData.ZoneConfig.DetectionCoverage]

			-- Cache the ZoneBoxData:
			local ZoneBoxData = DetectionData._BoundsHandler.ZoneBoxData

			-- If Enter and Exit Detection Coverage's are set:
			if EngineData.ZoneConfig.EnterDetectionCoverage or EngineData.ZoneConfig.ExitDetectionCoverage then
				-- Local ExitDetection Coverage var
				local Exit_DetectionCoverage

				-- This will auto swap AllParts and AnyPart detection coverage functionality, because on exit, its the opposite
				-- logic that we want:
				if EngineData.ZoneConfig.ExitDetectionCoverage then
					if Enums.DetectionCoverage:GetName(EngineData.ZoneConfig.ExitDetectionCoverage) == "AllParts" then
						Exit_DetectionCoverage = Enums.DetectionCoverage.AnyPart
					elseif
						Enums.DetectionCoverage:GetName(EngineData.ZoneConfig.ExitDetectionCoverage) == "AnyPart"
					then
						Exit_DetectionCoverage = Enums.DetectionCoverage.AllParts
					else
						Exit_DetectionCoverage = EngineData.ZoneConfig.ExitDetectionCoverage
					end
				end

				-- Cache the Coverage Function:
				local InZoneCoverage_Enter = if EngineData.ZoneConfig.EnterDetectionCoverage
					then Coverages.InBox[EngineData.ZoneConfig.EnterDetectionCoverage]
					else InZoneCoverage

				-- Cache the Coverage Function:
				local InZoneCoverage_Exit = if Exit_DetectionCoverage
					then Coverages.InBox[Exit_DetectionCoverage]
					else InZoneCoverage

				local DetectionMode_Enter = EngineData.ZoneConfig.EnterDetectionMode
					or EngineData.ZoneConfig.DetectionMode
				local DetectionMode_Exit = EngineData.ZoneConfig.ExitDetectionMode
					or EngineData.ZoneConfig.DetectionMode

				-- Create the function for Boxes:
				GetTrackerStatus = function(
					ZoneId: string,
					Tracker: Tracker.Tracker<Tracker.Trackables>,
					HitTargetParts: { BasePart }?
				): number
					--=======================================================================================================>
					-- If the Tracker is NOT currently in the Zone, check its entrance:
					if Tracker:InZone(ZoneId) ~= true then
						-- If the Player is now in the zone, add it to the entered table, else, exited, else do nothing:
						if
							InZoneCoverage_Enter(
								Tracker:GetPartsList(),
								DetectionMode_Enter,
								ZoneBoxData.CFrame,
								ZoneBoxData.HalfSize,
								HitTargetParts
							)
						then
							return ENTERED
						else
							return OUT
						end
					else
						-- If the Player is now in the zone, add it to the entered table, else, exited, else do nothing:
						if
							InZoneCoverage_Exit(
								Tracker:GetPartsList(),
								DetectionMode_Exit,
								ZoneBoxData.CFrame,
								ZoneBoxData.HalfSize,
								HitTargetParts
							)
						then
							return IN
						else
							return EXITED
						end
					end
					--=======================================================================================================>
				end
			else
				-- Create the function for Boxes:
				GetTrackerStatus = function(
					ZoneId: string,
					Tracker: Tracker.Tracker<Tracker.Trackables>,
					HitTargetParts: { BasePart }?
				): number
					--=======================================================================================================>
					-- If the Player is now in the zone, add it to the entered table, else, exited, else do nothing:
					if
						InZoneCoverage(
							Tracker:GetPartsList(),
							EngineData.ZoneConfig.DetectionMode,
							ZoneBoxData.CFrame,
							ZoneBoxData.HalfSize,
							HitTargetParts
						)
					then
						-- If the PlayerInZone State Previously was False as in not in the Zone, then Player is Entering:
						return if Tracker:InZone(ZoneId) ~= true then ENTERED else IN
					else
						-- If the PlayerInZone State Previously was True as in was in the Zone, then Player is Exiting:
						return if Tracker:InZone(ZoneId) == true then EXITED else OUT
					end
					--=======================================================================================================>
				end
			end

			--=================================================================================>
		end
		--============================================================================================>
	end

	--=======================================================================================================>
	--[ ADDER/REMOVER METHODS: ]

	-- Adds a new TargetHandler Object on this DetectionHandler Object:
	function DetectionData.AddTargetHandler(self: DetectionHandler, Target: Targets.TargetTypes)
		--============================================================================================>
		-- If a TargetHandler Object for this Target exists already, Call the same Function but with State as False to Destroy it,
		-- Then continue to make a new Object:
		if self._TargetHandlers[Target] then
			self:RemoveTargetHandler(Target)
		end
		-- Construct a new Handler Object with the Trove and Set it in the Table:
		-- Index the Target Specific Table with the Target Name to gets its New Method:
		self._TargetHandlers[Target] = Targets[Target].New(
			-- Pass in a Boolean on whether the Execution is Serial or not:
			EngineData.ZoneConfig.Execution == Enums.Execution.Serial
		)
		--============================================================================================>
		-- Set the Detection Status based on the Targets:
		self.Detecting = self:GetDetectionStatus()
		--============================================================================================>
		-- When a TargetHandler is added create the Overlap Paramaters if needed:
		if Target == "Part" or EngineData.ZoneConfig.DetectionMethod ~= Enums.DetectionMethod.Efficient then
			self:AddOverlapParamaters()
			self:AddBoundsEvaluateFunction(Target)
		end
		--============================================================================================>
	end

	-- Function which Adds an Array of Parts to the CurrentParts Dictionary without adding duplicates:
	function DetectionData.AddToCurrentParts(self: DetectionHandler, Parts: { BasePart })
		--===============================================================================>
		-- Loop through the Results from the Single Part of the Zone, and Check to make sure each Part is not already in the
		-- Global Zone Results Table, if its not already added to the Results Array, Insert it to combine the zone parts:
		for Index: number, Result: BasePart in ipairs(Parts) do
			-- Check to see if the Result is already added, continue if so:
			if self._CurrentParts[Result] then
				continue
			end
			-- Insert Result to Results Table:
			self._CurrentParts[Result] = true
		end
		--===============================================================================>
	end

	-- Function which will Add OverlapParamater Instances to the Object:
	function DetectionData.AddOverlapParamaters(self: DetectionHandler)
		--===============================================================================>
		-- If they are already created then return:
		if self._OverlapParamaters then
			return
		end

		-- Define the OverlapParams Table:
		self._OverlapParamaters = {
			PartsExcludeList = OverlapParams.new(),
		}

		-- For Type Checking reasons, make sure its not nil:
		if not self._OverlapParamaters then
			return
		end

		self._OverlapParamaters.PartsExcludeList.FilterType = Enum.RaycastFilterType.Exclude
		self._OverlapParamaters.PartsExcludeList.FilterDescendantsInstances = {}
		self._OverlapParamaters.PartsExcludeList.CollisionGroup = "Zoner:ZonePart"

		--===============================================================================>
	end

	--=======================================================================================================>

	-- Function which will Remove OverlapParamater Instances from the Object:
	function DetectionData.RemoveOverlapParamaters(self: DetectionHandler)
		if self._OverlapParamaters == nil then
			return
		end
		self._OverlapParamaters = nil :: any
	end

	-- Removes an Existing TargetHandler Object from exisistance on this DetectionHandler Object:
	function DetectionData.RemoveTargetHandler(self: DetectionHandler, Target: Targets.TargetTypes)
		--===============================================================================>
		-- If a TargetHandler Object exists, then Remove/Destroy it in the Trove and Set its Table value to nil:
		if self._TargetHandlers[Target] then
			-- Loop through all the still existing Trackers in the Target Handler, and Make each Exit the current Zone:
			for Key, Tracker in self._TargetHandlers[Target]:GetTrackers() do
				if Tracker:InZone(EngineData.ZoneId) then
					Tracker:ExitZone(EngineData.ZoneId)
				end
			end

			self._TargetHandlers[Target]:Destroy()
			self._TargetHandlers[Target] = nil
		end
		--===============================================================================>
		-- Set the Detection Status based on the Targets:
		self.Detecting = self:GetDetectionStatus()
		--===============================================================================>
		-- If the DetectionType is not 'Efficient', then we need to check if any other Targets are Active.
		-- If any other target is active, then dont remove the overlap, if they're none, then remove overlap:
		if Target == "Part" then
			if EngineData.ZoneConfig.DetectionMethod ~= Enums.DetectionMethod.Efficient then
				-- If none are active, then remove overlap paramaters, and remove the evaluatefunction:
				self:RemoveOverlapParamaters()
				self:RemoveBoundsEvaluateFunction(Target)
				-- If we are still Detecting, as in theres other TargetHandlers other than Part active, loop
				-- through them and Add back the OverlapParams and EvaluateFunction that was removed, and break once
				-- it does it once:
				if self.Detecting == true then
					for Key, Handler in self._TargetHandlers do
						self:AddOverlapParamaters()
						self:AddBoundsEvaluateFunction(Target)
						break
					end
				end
			else
				self:RemoveOverlapParamaters()
				self:RemoveBoundsEvaluateFunction(Target)
			end
		else
			if EngineData.ZoneConfig.DetectionMethod ~= Enums.DetectionMethod.Efficient then
				-- If none are active, then remove overlap paramaters:
				if self.Detecting == false then
					self:RemoveOverlapParamaters()
					self:RemoveBoundsEvaluateFunction(Target)
				end
			end
		end
		--===============================================================================>
	end

	-- Function which clears the current parts table:
	function DetectionData.RemoveCurrentParts(self: DetectionHandler)
		table.clear(self._CurrentParts)
	end

	--=======================================================================================================>
	--[ GETTER METHODS: ]

	-- Function that return the BoundsHandler Object:
	function DetectionData.GetDetectionStatus(self: DetectionHandler): boolean
		--==============================================================================================>
		-- Boolean to store whether a Target Exists:
		local TargetExists = false
		-- Loop through the Targets, break at the first one in the dictionary if populated:
		for Key, Target in self._TargetHandlers do
			TargetExists = true
			break
		end
		-- If none are active and existing, then detection status is false, else detection status is true:
		if TargetExists == false then
			return false
		else
			return true
		end
		--==============================================================================================>
	end

	-- Function that return the BoundsHandler Object:
	function DetectionData.GetBoundsHandler(self: DetectionHandler): Bounds.BoundsHandler
		return self._BoundsHandler
	end

	--=======================================================================================================>
	--[ CORE METHODS: ]

	-- Function that will run the location checking code for the passed in Tracker and set its location status as well as add it to the
	-- Entrance or Exit table on the TargetHandler depending on its location status:
	function DetectionData.ComputeTrackerLocation(
		self: DetectionHandler,
		Key: string,
		TargetHandler: Targets.TargetHandler,
		Tracker: Tracker.Tracker<Tracker.Trackables>,
		TrackerHitParts: { BasePart }?
	)
		--==============================================================================================>

		-- 9/13/2025:  Began Exclusive Group Implementation:
		-- 10/10/2025: Finished Exclusive Group Implementation:

		-- Boolean as to whether the TrackerStatus detection code will run:
		-- This is used to skip detection for this Zone if it currently is unable to detect due
		-- to a group exclusivity restriction:
		local CAN_RUN_TRACKER_DETECTION: boolean = true

		-- Loop through all the existing Zone Groups to find which Groups the current Detecting Zone is in:
		-- Since we do not keep a dictionary of Groups the Zone is in on the Engine Object:
		for GroupKey: string, GroupData in Groups.ZoneGroups do
			-- If the TrackerStatus is no longer 'ENTERED' then we Break the Loop to stop schecking for an Out:
			if CAN_RUN_TRACKER_DETECTION == false then break end
			-- If the Current Detector's Parent Zone is not in the iterated group, continue:
			if not (GroupData.Zones[EngineData.ZoneId]) then continue end
			-- Tracker:GetZoneIdMap() -> Get's a Dictionary of all the Zone's this TrackedItem is currently in:
			-- Check if Tracker is in any other Zones that also share the same group, to then check mutal properties of the group:
			for ZoneId: string, Status: boolean in Tracker:GetZoneIDMap() do 
				-- If the ZoneId is the same as the current checking Zone, continue:
				if ZoneId == EngineData.ZoneId then continue end
				-- If the Existing Zone the TrackedItem is currently in matches the Group the Detecting Zone is currently in...
				-- continue on in the scope to check shared properties of the group
				if not (GroupData.Zones[ZoneId]) then continue end
				-- If the Shared Group's Properties have 'Exclusive' as true, then do not allow the detecting Zone to be entered
				-- Since with the 'Exclusive' Property, only one Zone of the Group can be entered at the same time:
				if GroupData.Properties.Exclusive == true then
					-- Set the TrackerStatus to OUT and Break the Loop:
					CAN_RUN_TRACKER_DETECTION = false; break
				end
			end
		end

		-- If the Boolean is false, cancel early and dont do Zone Detection checks:
		if CAN_RUN_TRACKER_DETECTION == false then return end 

		-- Get the Status of the Tracked Item relative to this Zone:
		-- Just realized, this is actually quite performant ngl.
		local TrackerStatus: number = GetTrackerStatus(EngineData.ZoneId, Tracker, TrackerHitParts)

		-- Run Entrance and Exit Logic based on Enum:
		if TrackerStatus == ENTERED then
			-- Add the Tracker to the Entered Array:
			TargetHandler:AddToEntered(TargetHandler:GetTargetItem(Key, Tracker))
			-- Add ZoneId to the map:
			Tracker:EnterZone(EngineData.ZoneId)
		elseif TrackerStatus == EXITED then
			-- Add the Tracker to the Exited Array:
			TargetHandler:AddToExited(TargetHandler:GetTargetItem(Key, Tracker))
			-- Remove ZoneId from the map:
			Tracker:ExitZone(EngineData.ZoneId)
		end
		--==============================================================================================>
	end

	-- Function that will run the location checking code for the passed in Par TargetHandler
	-- and set its location status as well as add it to the
	-- Entrance or Exit table on the TargetHandler depending on its location status:
	function DetectionData.ComputePartLocations(self: DetectionHandler, TargetHandler: Targets.TargetHandler)
		--==============================================================================================>

		-- Cache for quick access
		local CurrentParts: { [BasePart]: boolean } = self._CurrentParts
		local TargetCurrent: { [BasePart]: boolean } = TargetHandler.Current :: any

		-- Exit check — items that were tracked but are no longer present
		for Part: BasePart, _ in TargetCurrent do
			if not CurrentParts[Part] then
				-- Clear the Part from the Current Parts Dictionary
				TargetCurrent[Part] = nil -- Remove from current
				TargetHandler:AddToExited(Part) -- Mark as exited
			end
		end

		-- Entry check — new parts that weren't tracked before
		for Part: BasePart, _ in CurrentParts do
			if not TargetCurrent[Part] then
				-- Add the Part to the Current Parts Dictionary
				TargetCurrent[Part] = true -- Add to current
				TargetHandler:AddToEntered(Part) -- Mark as entered
			end
		end

		-- Clear variables:
		CurrentParts, TargetCurrent = nil :: any, nil :: any

		--==============================================================================================>
	end

	-- Method that will destroy the object and clean up all interior data:
	function DetectionData.Destroy(self: DetectionHandler)
		--==============================================================================================>

		-- If Destroying is already true then return:
		if self.Destroying == true then
			return
		else
			self.Destroying = true
		end

		--==============================================================================================>

		-- Remove all Target Handlers:
		for Key, Target in self._TargetHandlers do
			-- Remove the Target Handler:
			self:RemoveTargetHandler(Key :: any)
		end

		-- Clear Table:
		self:RemoveCurrentParts()
		-- Remove Table:
		self:RemoveOverlapParamaters()

		-- Destroy the BoundsHandler:
		self._BoundsHandler:Destroy()

		-- Clear all self data:
		for Index, Data in pairs(self) do
			self[Index] = nil
		end

		--==============================================================================================>
	end

	--=======================================================================================================>

	-- Update internal Detection Coverage:
	DetectionData:UpdateDetectionCoverage()

	--=======================================================================================================>

	-- Return the DetectionHandler Object:
	return DetectionData :: DetectionHandler

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Constructor function that will create a "Complex" DetectionHandler and return the Object after inheriting from "Default":
function DetectionHandlers.Complex.New(EngineData: ZoneEngineData): DetectionHandler
	--=======================================================================================================>

	-- Set Memory Category:
	debug.setmemorycategory("[Zoner]: Detection")

	-- Define the TargetData and Inherit from the Base Class:
	local DetectionData: DetectionHandler = DetectionHandler(EngineData) :: DetectionHandler

	--=======================================================================================================>

	-- Function which will Add the BoundsHandler's Evaluate function:
	function DetectionData.AddBoundsEvaluateFunction(self: DetectionHandler, TargetTypes: Targets.TargetTypes)
		--==============================================================================================>
		-- If no OverlapParams, return:
		if not self._OverlapParamaters then
			return
		end

		-- if the BoundsHandler Evaluate function is already set, and the TargetTypes is not Part, return:
		if self._BoundsHandler.Evaluate ~= DO_NOTHING and TargetTypes ~= "Part" then
			return
		end

		-- Local reference for less indexing:
		-- If Part is the target type, we will make the Params GRAB everything, vs Player Include list:
		local OverlapParamaters: OverlapParams = if TargetTypes == "Part"
			then self._OverlapParamaters.PartsExcludeList
			else self._OverlapParamaters.PartsExcludeList

		-- Bind Bound Type Specific EvaluateCallbacks for easy runtime function calls:
		self._BoundsHandler.Evaluate = function(BoundsHandler: Bounds.BoundsHandler)
			--=======================================================================================>
			-- Loop through the ZoneParts that make up the Zone:
			for ZonePart, Details in BoundsHandler:GetZonePartDetailsMap() do
				--===============================================================================>
				-- Get the Results of the Inidividual Part of the Zone:
				-- Loop through the Results from the Single Part of the Zone, and Check to make sure each Part is not already in the
				-- Global Zone Results Table, if its not already added to the Results Array, Insert it to combine the zone parts:
				self:AddToCurrentParts(
					WorldModel:GetPartsInPart(
						EngineData.ZoneStates.Relocated,
						Details.Part :: BasePart,
						OverlapParamaters
					)
				)
				--===============================================================================>
			end
			--=======================================================================================>
		end
		--==============================================================================================>
	end

	-- Function which will Remove the BoundsHandler's Evaluate function:

	function DetectionData.RemoveBoundsEvaluateFunction(self: DetectionHandler, TargetTypes: Targets.TargetTypes)
		-- Bind Bound Type Specific EvaluateCallbacks for easy runtime function calls:
		self._BoundsHandler.Evaluate = DO_NOTHING
		-- Clear the CurrentParts Array:
		self:RemoveCurrentParts()
	end

	-- Function ran every frame to evaluate detections:

	function DetectionData.Evaluate(self: DetectionHandler)
		--==============================================================================================>
		-- If the Detecting Variable is false then return from this function:
		if self.Detecting == false then
			return
		end
		-- If OverlapParamaters are nil, return:
		if not self._OverlapParamaters then
			return
		end
		--==============================================================================================>

		-- Begin Profiling:
		debug.profilebegin("[Zoner]: [Complex]: Evaluate: BoundsHandler")

		-- Call Evaluate callback:
		self._BoundsHandler:Evaluate()

		-- End Profiling:
		debug.profileend()

		-- Begin Profiling:
		debug.profilebegin("[Zoner]: [Complex]: Evaluate: TargetHandlers")

		for Target, TargetHandler: Targets.TargetHandler in self._TargetHandlers do
			--========================================================================================>
			-- If the Target is of the Parts variety then:
			if Target == "Part" then
				-- Compute the Locations of the Parts:
				self:ComputePartLocations(TargetHandler)
			else
				-- Loop through all the Objects/Items being stored in the Current Map in the Target Handler.
				-- Check if TargetHandler currently has a Tracker associated with that TrackerItem's Key,
				-- The Key should be the same Key used to store the Tracker Object

				-- If No Tracker is present for the TrackerItem stored in current, then we need to add it to be exited from the Zone
				-- If a Tracker is present, but its ZoneIdMap is Clear for this Zone, then we need to clear from Current and Exit Zone:
				for TrackerKey: any, TrackerItem: any in TargetHandler:GetCurrent() do
					if
						not TargetHandler:GetTrackers()[TrackerKey]
						or TargetHandler:GetTrackers()[TrackerKey]:GetZoneIDMap()[EngineData.ZoneId] == nil
					then
						TargetHandler:AddToExited(TrackerItem)
					end
				end

				-- Loop through the TargetHandler's Tracker Dictionary and Compute the Location for each Tracker individualy:
				-- Also use the Reused_HitTargetParts Dictionary to narrow down the Tracker's Parts:
				for Key: any, Tracker in TargetHandler:GetTrackers() do
					-- Pass in the Array consisting of only the Parts detected in CurrentParts that are apart of this Tracked Object:
					self:ComputeTrackerLocation(
						Key,
						TargetHandler,
						Tracker,
						Tracker:GetTargetPartsFromHitParts(self._CurrentParts, TargetHandler.Reused_HitTargetParts)
					)
					-- Clear the HitTargetParts table after its filled:
					table.clear(TargetHandler.Reused_HitTargetParts)
				end

				-- Loop through the Entered Values and add each to the Current:
				for Index: number, Value: any in ipairs(TargetHandler:GetEntered()) do
					TargetHandler:AddToCurrent(Value)
				end
				-- Loop through the Exited Values and remove each from the Current:
				for Index: number, Value: any in ipairs(TargetHandler:GetExited()) do
					TargetHandler:RemoveFromCurrent(Value)
				end
			end
			--========================================================================================>
		end

		-- End Profiling:
		debug.profileend()

		-- Clear the CurrentParts Array:
		self:RemoveCurrentParts()

		--===============================================================================>
	end

	--=======================================================================================================>

	-- Return the DetectionHandler Object:
	return DetectionData :: DetectionHandler

	--=======================================================================================================>
end

-- Constructor function that will create a "Simple" DetectionHandler and return the Object after inheriting from "Default":
function DetectionHandlers.Simple.New(EngineData: ZoneEngineData): DetectionHandler
	--=======================================================================================================>

	-- Set Memory Category:
	debug.setmemorycategory("[Zoner]: Detection")

	-- Define the TargetData and Inherit from the Base Class:
	local DetectionData: DetectionHandler = DetectionHandler(EngineData) :: DetectionHandler

	--=======================================================================================================>

	-- Function which will Add the BoundsHandler's Evaluate function:
	function DetectionData.AddBoundsEvaluateFunction(self: DetectionHandler, TargetTypes: Targets.TargetTypes)
		--==============================================================================================>
		-- If no OverlapParams, return:
		if not self._OverlapParamaters then
			return
		end

		-- if the BoundsHandler Evaluate function is already set, and the TargetTypes is not Part, return:
		if self._BoundsHandler.Evaluate ~= DO_NOTHING and TargetTypes ~= "Part" then
			return
		end

		-- Local reference for less indexing:
		-- If Part is the target type, we will make the Params GRAB everything, vs Player Include list:
		local OverlapParamaters: OverlapParams = if TargetTypes == "Part"
			then self._OverlapParamaters.PartsExcludeList
			else self._OverlapParamaters.PartsExcludeList

		-- Bind Bound Type Specific EvaluateCallbacks for easy runtime function calls:
		if self._BoundsHandler:GetBoundType() == "PerPart" then
			--================================================================================================>
			-- Set an EvaluateCallback:
			self._BoundsHandler.Evaluate = function(BoundsHandler: Bounds.BoundsHandler)
				--=======================================================================================>
				-- Loop through the ZoneParts that make up the Zone:
				for Key, Details in BoundsHandler:GetZonePieceDetailsMap() do
					--===============================================================================>
					-- Get the Results of the Inidividual Part of the Zone:
					-- Loop through the Results from the Single Part of the Zone, and Check to make sure each Part is not already in the
					-- Global Zone Results Table, if its not already added to the Results Array, Insert it to combine the zone parts:
					DetectionData:AddToCurrentParts(
						WorldModel:GetPartBoundsInBox(
							EngineData.ZoneStates.Relocated,
							Details.CFrame or Details.Piece.CFrame,
							Details.Size,
							OverlapParamaters
						)
					)
					--===============================================================================>
				end
				--=======================================================================================>
			end
			--================================================================================================>
		else
			--================================================================================================>
			-- Set an EvaluateCallback:
			self._BoundsHandler.Evaluate = function(BoundsHandler: Bounds.BoundsHandler)
				--=======================================================================================>
				-- Get the Results of the Inidividual Part of the Zone:
				-- Loop through the Results from the Single Part of the Zone, and Check to make sure each Part is not already in the
				-- Global Zone Results Table, if its not already added to the Results Array, Insert it to combine the zone parts:
				DetectionData:AddToCurrentParts(
					WorldModel:GetPartBoundsInBox(
						EngineData.ZoneStates.Relocated,
						BoundsHandler.ZoneBoxData.CFrame,
						BoundsHandler.ZoneBoxData.Size,
						OverlapParamaters
					)
				)
				--=======================================================================================>
			end
			--================================================================================================>
		end

		--==============================================================================================>
	end

	-- Function which will Remove the BoundsHandler's Evaluate function:
	function DetectionData.RemoveBoundsEvaluateFunction(self: DetectionHandler, TargetTypes: Targets.TargetTypes)
		-- Bind Bound Type Specific EvaluateCallbacks for easy runtime function calls:
		self._BoundsHandler.Evaluate = DO_NOTHING
		-- Clear the CurrentParts Array:
		self:RemoveCurrentParts()
	end

	-- Function ran every frame to evaluate detections:
	function DetectionData.Evaluate(self: DetectionHandler)
		--==============================================================================================>
		-- If the Detecting Variable is false then return from this function:
		if self.Detecting == false then
			return
		end
		--==============================================================================================>

		-- Begin Profiling:
		debug.profilebegin("[Zoner]: [Simple]: Evaluate: BoundsHandler")

		-- Call Evaluate callback:
		self._BoundsHandler:Evaluate()

		-- End Profiling:
		debug.profileend()

		-- Begin Profiling:
		debug.profilebegin("[Zoner]: [Simple]: Evaluate: TargetHandlers")

		for Target, TargetHandler: Targets.TargetHandler in self._TargetHandlers do
			--========================================================================================>
			-- If the Target is of the Parts variety then:
			if Target == "Part" then
				-- Compute the Locations of the Parts:
				self:ComputePartLocations(TargetHandler)
			else
				-- Loop through all the Objects/Items being stored in the Current Map in the Target Handler.
				-- Check if TargetHandler currently has a Tracker associated with that TrackerItem's Key,
				-- The Key should be the same Key used to store the Tracker Object

				-- If No Tracker is present for the TrackerItem stored in current, then we need to add it to be exited from the Zone
				-- If a Tracker is present, but its ZoneIdMap is Clear for this Zone, then we need to clear from Current and Exit Zone:
				for TrackerKey: any, TrackerItem: any in TargetHandler:GetCurrent() do
					if
						not TargetHandler:GetTrackers()[TrackerKey]
						or TargetHandler:GetTrackers()[TrackerKey]:GetZoneIDMap()[EngineData.ZoneId] == nil
					then
						TargetHandler:AddToExited(TrackerItem)
					end
				end

				-- Loop through the TargetHandler's Tracker Dictionary and Compute the Location for each Tracker individualy:
				-- Also use the Reused_HitTargetParts Dictionary to narrow down the Tracker's Parts:
				for Key: string, Tracker in TargetHandler:GetTrackers() do
					-- Pass in the Array consisting of only the Parts detected in CurrentParts that are apart of this Tracked Object:
					self:ComputeTrackerLocation(
						Key,
						TargetHandler,
						Tracker,
						Tracker:GetTargetPartsFromHitParts(self._CurrentParts, TargetHandler.Reused_HitTargetParts)
					)
					-- Clear the HitTargetParts table after its filled:
					table.clear(TargetHandler.Reused_HitTargetParts)
				end

				-- Loop through the Entered Values and add each to the Current:
				for Index: number, Value: any in ipairs(TargetHandler:GetEntered()) do
					TargetHandler:AddToCurrent(Value)
				end
				-- Loop through the Exited Values and remove each from the Current:
				for Index: number, Value: any in ipairs(TargetHandler:GetExited()) do
					TargetHandler:RemoveFromCurrent(Value)
				end
			end
			--========================================================================================>
		end

		-- End Profiling:
		debug.profileend()

		-- Clear the CurrentParts Array:
		self:RemoveCurrentParts()

		--===============================================================================>
	end

	--=======================================================================================================>

	-- Return the DetectionHandler Object:
	return DetectionData :: DetectionHandler

	--=======================================================================================================>
end

-- Constructor function that will create a "Efficient" DetectionHandler and return the Object after inheriting from "Default":
function DetectionHandlers.Efficient.New(EngineData: ZoneEngineData): DetectionHandler
	--=======================================================================================================>

	-- Set Memory Category:
	debug.setmemorycategory("[Zoner]: Detection")

	-- Define the TargetData and Inherit from the Base Class:
	local DetectionData: DetectionHandler = DetectionHandler(EngineData) :: DetectionHandler

	--=======================================================================================================>

	-- Function which will Add the BoundsHandler's Evaluate function:
	function DetectionData.AddBoundsEvaluateFunction(self: DetectionHandler, TargetTypes: Targets.TargetTypes)
		--==============================================================================================>
		-- If no OverlapParams, return:
		if not self._OverlapParamaters then
			return
		end

		-- if the BoundsHandler Evaluate function is already set, and the TargetTypes is not Part, return:
		if self._BoundsHandler.Evaluate ~= DO_NOTHING and TargetTypes ~= "Part" then
			return
		end

		-- Local reference for less indexing:
		-- If Part is the target type, we will make the Params GRAB everything, vs Player Include list:
		local OverlapParamaters: OverlapParams = if TargetTypes == "Part"
			then self._OverlapParamaters.PartsExcludeList
			else self._OverlapParamaters.PartsExcludeList

		-- Bind Bound Type Specific EvaluateCallbacks for easy runtime function calls:
		if self._BoundsHandler:GetBoundType() == "PerPart" then
			--================================================================================================>
			-- Set an EvaluateCallback:
			self._BoundsHandler.Evaluate = function(BoundsHandler: Bounds.BoundsHandler)
				--=======================================================================================>
				-- Loop through the ZoneParts that make up the Zone:
				for Key, Details in BoundsHandler:GetZonePieceDetailsMap() do
					--===============================================================================>
					-- Get the Results of the Inidividual Part of the Zone:
					-- Loop through the Results from the Single Part of the Zone, and Check to make sure each Part is not already in the
					-- Global Zone Results Table, if its not already added to the Results Array, Insert it to combine the zone parts:
					DetectionData:AddToCurrentParts(
						WorldModel:GetPartBoundsInBox(
							EngineData.ZoneStates.Relocated,
							Details.CFrame or Details.Piece.CFrame,
							Details.Size,
							OverlapParamaters
						)
					)
					--===============================================================================>
				end
				--=======================================================================================>
			end
			--================================================================================================>
		else
			--================================================================================================>
			-- Set an EvaluateCallback:
			self._BoundsHandler.Evaluate = function(BoundsHandler: Bounds.BoundsHandler)
				--=======================================================================================>
				-- Get the Results of the Inidividual Part of the Zone:
				-- Loop through the Results from the Single Part of the Zone, and Check to make sure each Part is not already in the
				-- Global Zone Results Table, if its not already added to the Results Array, Insert it to combine the zone parts:
				DetectionData:AddToCurrentParts(
					WorldModel:GetPartBoundsInBox(
						EngineData.ZoneStates.Relocated,
						BoundsHandler.ZoneBoxData.CFrame,
						BoundsHandler.ZoneBoxData.Size,
						OverlapParamaters
					)
				)
				--=======================================================================================>
			end
			--================================================================================================>
		end

		--==============================================================================================>
	end

	-- Function which will Remove the BoundsHandler's Evaluate function:
	function DetectionData.RemoveBoundsEvaluateFunction(self: DetectionHandler, TargetTypes: Targets.TargetTypes)
		-- Bind Bound Type Specific EvaluateCallbacks for easy runtime function calls:
		self._BoundsHandler.Evaluate = DO_NOTHING
		-- Clear the CurrentParts Array:
		self:RemoveCurrentParts()
	end

	-- Function ran every frame to evaluate detections:
	function DetectionData.Evaluate(self: DetectionHandler)
		--==============================================================================================>
		-- If the Detecting Variable is false then return from this function:
		if self.Detecting == false then
			return
		end

		-- Begin Profiling:
		debug.profilebegin("[Zoner]: [Efficient]: Evaluate: BoundsHandler")

		-- Call Evaluate callback:
		self._BoundsHandler:Evaluate()

		-- End Profiling:
		debug.profileend()

		-- Begin Profiling:
		debug.profilebegin("[Zoner]: [Efficient]: Evaluate: TargetHandlers")

		for Target, TargetHandler: Targets.TargetHandler in self._TargetHandlers do
			--========================================================================================>
			-- If the Target is of the Parts variety then continue:
			if Target == "Part" then
				-- Compute the Locations of the Parts:
				self:ComputePartLocations(TargetHandler)
				-- Clear the CurrentParts Array:
				self:RemoveCurrentParts()
			else
				-- Loop through all the Objects/Items being stored in the Current Map in the Target Handler.
				-- Check if TargetHandler currently has a Tracker associated with that TrackerItem's Key,
				-- The Key should be the same Key used to store the Tracker Object

				-- If No Tracker is present for the TrackerItem stored in current, then we need to add it to be exited from the Zone
				-- If a Tracker is present, but its ZoneIdMap is Clear for this Zone, then we need to clear from Current and Exit Zone:
				for TrackerKey: any, TrackerItem: any in TargetHandler:GetCurrent() do
					if
						not TargetHandler:GetTrackers()[TrackerKey]
						or TargetHandler:GetTrackers()[TrackerKey]:GetZoneIDMap()[EngineData.ZoneId] == nil
					then
						TargetHandler:AddToExited(TrackerItem)
					end
				end

				-- Loop through the TargetHandler's Tracker Dictionary and Compute the Location for each Tracker individualy:
				-- Also use the Reused_HitTargetParts Dictionary to narrow down the Tracker's Parts:
				for Key: string, Tracker in TargetHandler:GetTrackers() do
					-- Compute the Location of the passed in Tracker:
					self:ComputeTrackerLocation(Key, TargetHandler, Tracker)
				end

				-- Loop through the Entered Values and add each to the Current:
				for Index: number, Value: any in ipairs(TargetHandler:GetEntered()) do
					TargetHandler:AddToCurrent(Value)
				end
				-- Loop through the Exited Values and remove each from the Current:
				for Index: number, Value: any in ipairs(TargetHandler:GetExited()) do
					TargetHandler:RemoveFromCurrent(Value)
				end
			end
			--========================================================================================>
		end

		-- End Profiling:
		debug.profileend()

		--===============================================================================>
	end

	--=======================================================================================================>

	-- Return the DetectionHandler Object:
	return DetectionData :: DetectionHandler

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Called from the Parent running this Module, to update some global scope:
function DetectionHandlers.UpdateGlobalScope(ZonerHolder: Zoner_Types.ZonerHolder)
	Targets.UpdateGlobalScope(ZonerHolder)
end

--===========================================================================================================================>

-- Freeze subtables:
table.freeze(DetectionHandlers.Efficient)
table.freeze(DetectionHandlers.Complex)
table.freeze(DetectionHandlers.Simple)

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(DetectionHandlers) :: typeof(DetectionHandlers)

--===========================================================================================================================>