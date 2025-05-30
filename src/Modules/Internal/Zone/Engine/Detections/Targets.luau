--===========================================================================================================================>
--!optimize 2
--!native
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: TargetHandler')

-- Define Module table
local TargetHandlers = {
	LocalPlayer   = {};
	Player        = {};
	Item          = {};
	Part          = {};
}

--===========================================================================================================================>
--[ GLOBALS: ]


--[ Global Dependencies: ]

-- Require the Plagger Module:
local Plagger    = require(`../../../Plagger`);
-- Require the SignalHash Module:
local SignalHash = require(`../../SignalHash`);

--[ Local Dependencies: ]

-- Require the Target Tracker Sub Class Module:
local Tracker    = require(`./Tracker`);

--===========================================================================================================================>
--[ CONSTANTS: ]


-- Store SHARED data concerning Plaggers:
local PLAGGER_DATA = {
	--=========================>
	-- Store the Plagger Objects in use:
	Plaggers = {
		Local_Serial    = nil :: Plagger.Plagger?;
		Local_Parallel  = nil :: Plagger.Plagger?;
		Global_Serial   = nil :: Plagger.Plagger?;
		Global_Parallel = nil :: Plagger.Plagger?;
	};
	-- Store the numbers related to the using of those Plagger Objects:
	InUse = {
		Local_Serial    = 0;
		Local_Parallel  = 0;
		Global_Serial   = 0;
		Global_Parallel = 0;
	};
	-- Store Character Add/Remove connections:
	Connections = {};
	--=========================>
}

-- Store the globally used Tracker Objects:
local TRACKERS = {
	Global_Characters = {} :: {[string]: Tracker.Tracker<Model>};
	Local_Characters  = {} :: {[string]: Tracker.Tracker<Model>}
}

--===========================================================================================================================>
--[ TYPES: ]

-- [ Require Types ]

-- This will inject all types into this context.
local Zoner_Types = require(`../../../../../Types`)

-- Export the Handler Types all Together as one:
export type TargetTypes = 'LocalPlayer' | 'Player' | 'Item' | 'Part';

-- Export the Players Target Handler Type:
export type TargetHandler = { 
	--====================================================>
	-- Whether the Zone Logic is running for this Target:
	IsTracking: boolean;
	-- Whether the Handler is being Destroyed:
	Destroying: boolean;
	-- What type of Target it is:
	TargetType: TargetTypes;
	--====================================================>
	EnteredHash: string;
	ExitedHash:  string;
	--====================================================>
	-- Holds Class Objects:
	_Classes: {Plagger: Plagger.Plagger?}?;
	-- Reuseable array for filtering hit target parts on an individual tracker:
	Reused_HitTargetParts: {BasePart};
	--====================================================>
	-- Dictionary to track the Current  Parts in the Zone:
	Current:  {[Instance]: boolean};
	-- Array that is cleared every run. Fires an event for each Part when entering Zone:
	Entered:  {any};
	-- Array that is cleared every run. Fires an event for each Part when exiting Zone:
	Exited:   {any};
	--====================================================>

	AddToEntered: 
		(self: TargetHandler, Object: any) -> ();
	AddToExited: 
		(self: TargetHandler, Object: any) -> ();

	ClearExited: 
		(self: TargetHandler) -> ();
	ClearEntered: 
		(self: TargetHandler) -> ();

	GetTargetItem: 
		(self: TargetHandler, Key: string, Tracker: Tracker.Tracker<Tracker.Trackables>) -> any;

	GetEntered: 
		(self: TargetHandler) -> {any};
	GetExited: 
		(self: TargetHandler) -> {any};

	GetTrackers: 
		(self: TargetHandler) -> {[string]: Tracker.Tracker<Tracker.Trackables>};

	-- Destroy Method:
	Destroy: 
		(self: TargetHandler) -> ();
	--====================================================>
} 

--===========================================================================================================================>
--[ LOCAL FUNCTIONS: ]


local function StartPlaggerEvents(Local: boolean, Serial: boolean)
	--=======================================================================================================>

	-- Grab the first Local or Global Plagger Object:
	local Plagger: Plagger.Plagger = 
		if Local then (PLAGGER_DATA.Plaggers.Local_Serial or PLAGGER_DATA.Plaggers.Local_Parallel) else (PLAGGER_DATA.Plaggers.Global_Serial or PLAGGER_DATA.Plaggers.Global_Parallel) ::any

	-- Dynamically Created the Connection Key, Global or Local:
	local CharacterAdded_Key   = `{if Local then 'Local' else 'Global'}_CharacterAdded`
	local CharacterRemoved_Key = `{if Local then 'Local' else 'Global'}_CharacterRemoved`

	-- Dynamically create the Tracker Key, Local or Global:
	local Tracker_Key = `{if Local then 'Local' else 'Global'}_Characters`

	--=======================================================================================================>

	-- If CharacterAdd/Remove connections already exist for this Plagger Type, return, dont create new Events:
	if PLAGGER_DATA.Connections[CharacterAdded_Key] or PLAGGER_DATA.Connections[CharacterRemoved_Key] then return end

	-- Loop through the already Spawned Characters and Add their Trackers:
	for Name: string, Character: Model in Plagger:GetCharacters() do
		--==============================================================================>
		-- If there is a Player ItemTracker Object for this Character:
		-- Destroy it and clear it from the reference:
		if TRACKERS[Tracker_Key][Character.Name] then continue end
		-- Create a new Tracker Object for this Character:
		TRACKERS[Tracker_Key][Character.Name] = Tracker.New(Character, Serial)
		--==============================================================================>
	end

	-- Connect to the Character Tag Added Signal:
	-- Fires when a Part with the Character Tag is added back to the Workspace:
	PLAGGER_DATA.Connections[CharacterAdded_Key] = Plagger:GetCharacterAddedSignal():Connect(function(Character: Model)
		--==============================================================================>
		-- If there is a Player ItemTracker Object for this Character:
		-- Destroy it and clear it from the reference:
		if TRACKERS[Tracker_Key][Character.Name] then 
			TRACKERS[Tracker_Key][Character.Name]:Destroy(); TRACKERS[Tracker_Key][Character.Name] = nil
		end
		-- Create a new Tracker Object for this Character:
		TRACKERS[Tracker_Key][Character.Name] = Tracker.New(Character, Serial)
		--==============================================================================>
	end)

	-- Connect to the Character Tag Removed Signal:
	-- Fires when a Part with the Character Tag is removed from the Workspace:
	PLAGGER_DATA.Connections[CharacterRemoved_Key] = Plagger:GetCharacterRemovedSignal():Connect(function(Character: Model)
		--==============================================================================>
		-- If there is a Player ItemTracker Object for this Character:
		-- Destroy it and clear it from the reference:
		if TRACKERS[Tracker_Key][Character.Name] then 
			TRACKERS[Tracker_Key][Character.Name]:Destroy(); TRACKERS[Tracker_Key][Character.Name] = nil
		end
		--==============================================================================>
	end)

	--=======================================================================================================>
end

local function StopPlaggerEvents(Local: boolean, Serial: boolean)
	--=======================================================================================================>

	-- Dynamically Created the Connection Key, Global or Local:
	local CharacterAdded_Key   = `{if Local then 'Local' else 'Global'}_CharacterAdded`
	local CharacterRemoved_Key = `{if Local then 'Local' else 'Global'}_CharacterRemoved`

	-- Dynamically create the Tracker Key, Local or Global:
	local Tracker_Key = `{if Local then 'Local' else 'Global'}_Characters`

	--=======================================================================================================>

	-- Clear the Event:
	if PLAGGER_DATA.Connections[CharacterAdded_Key] then 
		PLAGGER_DATA.Connections[CharacterAdded_Key]:Disconnect(); PLAGGER_DATA.Connections[CharacterAdded_Key] = nil :: any
	end

	-- Clear the Event:
	if PLAGGER_DATA.Connections[CharacterRemoved_Key] then 
		PLAGGER_DATA.Connections[CharacterRemoved_Key]:Disconnect(); PLAGGER_DATA.Connections[CharacterRemoved_Key] = nil :: any
	end

	-- Clear/Destroy all existing tracker objects:
	for Name, Tracker in TRACKERS[Tracker_Key] do
		TRACKERS[Tracker_Key][Name]:Destroy(); TRACKERS[Tracker_Key][Name] = nil :: any
	end

	--=======================================================================================================>
end

local function GetPlagger(Local: boolean, Serial: boolean): Plagger.Plagger
	--=======================================================================================================>
	if Local then
		if Serial then
			if PLAGGER_DATA.Plaggers.Local_Serial then
				-- Increment the increase in use:
				PLAGGER_DATA.InUse.Local_Serial += 1
				-- Return the object reference:
				return PLAGGER_DATA.Plaggers.Local_Serial
			else
				-- Construct the new Object:
				PLAGGER_DATA.Plaggers.Local_Serial = Plagger.New(true, true, false); 
				-- Start the Plagger Events if they dont already exist:
				StartPlaggerEvents(Local, Serial)
				-- Return the Plagger Object:
				return GetPlagger(Local, Serial)
			end
		else
			if PLAGGER_DATA.Plaggers.Local_Parallel then
				-- Increment the increase in use:
				PLAGGER_DATA.InUse.Local_Parallel += 1
				-- Return the object reference:
				return PLAGGER_DATA.Plaggers.Local_Parallel
			else
				-- Construct the new Object:
				PLAGGER_DATA.Plaggers.Local_Parallel = Plagger.New(true, true, true); 
				-- Start the Plagger Events if they dont already exist:
				StartPlaggerEvents(Local, Serial)
				-- Return the Plagger Object:
				return GetPlagger(Local, Serial)
			end
		end
	else
		if Serial then
			if PLAGGER_DATA.Plaggers.Global_Serial then
				-- Increment the increase in use:
				PLAGGER_DATA.InUse.Global_Serial += 1
				-- Return the object reference:
				return PLAGGER_DATA.Plaggers.Global_Serial
			else
				-- Construct the new Object:
				PLAGGER_DATA.Plaggers.Global_Serial = Plagger.New(true, false, false);
				-- Start the Plagger Events if they dont already exist:
				StartPlaggerEvents(Local, Serial)
				-- Return the Plagger Object:
				return GetPlagger(Local, Serial)
			end
		else
			if PLAGGER_DATA.Plaggers.Global_Parallel then
				-- Increment the increase in use:
				PLAGGER_DATA.InUse.Global_Parallel += 1
				-- Return the object reference:
				return PLAGGER_DATA.Plaggers.Global_Parallel
			else
				-- Construct the new Object:
				PLAGGER_DATA.Plaggers.Global_Parallel = Plagger.New(true, false, true); 
				-- Start the Plagger Events if they dont already exist:
				StartPlaggerEvents(Local, Serial)
				-- Return the Plagger Object:
				return GetPlagger(Local, Serial)
			end
		end
	end
	--=======================================================================================================>
end

local function RemovePlagger(Local: boolean, Serial: boolean)
	--=======================================================================================================>
	if Local then
		if Serial then
			if PLAGGER_DATA.Plaggers.Local_Serial and PLAGGER_DATA.InUse.Local_Serial > 0 then
				-- Increment the decrease in use:
				PLAGGER_DATA.InUse.Local_Serial -= 1
				-- If there is no 0 Zones using the Plagger Object, destroy it:
				if PLAGGER_DATA.InUse.Local_Serial == 0 then
					PLAGGER_DATA.Plaggers.Local_Serial:Destroy(); PLAGGER_DATA.Plaggers.Local_Serial = nil :: any;
					-- If the other Local Plagger is also no longer in use, stop all Plagger Events:
					if PLAGGER_DATA.InUse.Local_Parallel == 0 then StopPlaggerEvents(Local, Serial) end
				end
			end
		else
			if PLAGGER_DATA.Plaggers.Local_Parallel and PLAGGER_DATA.InUse.Local_Parallel > 0 then
				-- Increment the decrease in use:
				PLAGGER_DATA.InUse.Local_Parallel -= 1
				-- If there is no 0 Zones using the Plagger Object, destroy it:
				if PLAGGER_DATA.InUse.Local_Parallel == 0 then
					PLAGGER_DATA.Plaggers.Local_Parallel:Destroy(); PLAGGER_DATA.Plaggers.Local_Parallel = nil :: any;
					-- If the other Local Plagger is also no longer in use, stop all Plagger Events:
					if PLAGGER_DATA.InUse.Local_Serial == 0 then StopPlaggerEvents(Local, Serial) end
				end
			end
		end
	else
		if Serial then
			if PLAGGER_DATA.Plaggers.Global_Serial and PLAGGER_DATA.InUse.Global_Serial > 0 then
				-- Increment the decrease in use:
				PLAGGER_DATA.InUse.Global_Serial -= 1
				-- If there is no 0 Zones using the Plagger Object, destroy it:
				if PLAGGER_DATA.InUse.Global_Serial == 0 then
					PLAGGER_DATA.Plaggers.Global_Serial:Destroy(); PLAGGER_DATA.Plaggers.Global_Serial = nil :: any;
					-- If the other Global Plagger is also no longer in use, stop all Plagger Events:
					if PLAGGER_DATA.InUse.Global_Parallel == 0 then StopPlaggerEvents(Local, Serial) end
				end
			end
		else
			if PLAGGER_DATA.Plaggers.Global_Parallel and PLAGGER_DATA.InUse.Global_Parallel > 0 then
				-- Increment the decrease in use:
				PLAGGER_DATA.InUse.Global_Parallel -= 1
				-- If there is no 0 Zones using the Plagger Object, destroy it:
				if PLAGGER_DATA.InUse.Global_Parallel == 0 then
					PLAGGER_DATA.Plaggers.Global_Parallel:Destroy(); PLAGGER_DATA.Plaggers.Global_Parallel = nil :: any;
					-- If the other Global Plagger is also no longer in use, stop all Plagger Events:
					if PLAGGER_DATA.InUse.Global_Serial == 0 then StopPlaggerEvents(Local, Serial) end
				end
			end
		end
	end
	--=======================================================================================================>
end

--===========================================================================================================================>
--[ TARGET HANDLER FUNCTIONS: ]


-- Get the Signal Hash based on the paramaters and cache it in the object that calls it:
local function GetSignalHash(Target: TargetTypes, Signal: ('Entered'|'Exited'), HashType: ('Send'|'Recieve')): string
	return SignalHash[HashType][`{Target}{Signal}`]
end

local function GetPlayer(Plagger: Plagger.Plagger, PlayerName: string)
	return Plagger:GetPlayers()[PlayerName]
end

--=======================================================================================================>

-- Return the DEFAULT Player TargetHandler object:
local function PlayerHandler(Serial: boolean, Local: boolean): TargetHandler
	--=======================================================================================================>

	-- Set Memory Category:
	debug.setmemorycategory('[Zoner]: TargetHandler')

	-- Predefine TargetType:
	local TargetType: TargetTypes = if Local then 'LocalPlayer' else 'Player';

	-- Cache the TRACKERS:
	local Trackers = if Local then TRACKERS.Local_Characters else TRACKERS.Global_Characters;

	-- Define the TargetData and Inherit from the Base Class:
	local TargetData: TargetHandler = {
		--====================================================>
		TargetType = TargetType;
		IsTracking = false;
		Destroying = false;

		EnteredHash = GetSignalHash(TargetType, 'Entered', 'Send');
		ExitedHash  = GetSignalHash(TargetType, 'Exited', 'Send');
		--====================================================>
		Current  = {};
		Entered  = {};
		Exited   = {};
		
		-- Reuseable array for filtering hit target parts on an individual tracker:
		Reused_HitTargetParts = {};
		--====================================================>
		-- Classes Dictionary:
		_Classes = {Plagger = GetPlagger(Local, Serial)};
		--====================================================>
	} :: TargetHandler

	--=======================================================================================================>
		
	function TargetData.AddToExited(self: TargetHandler, Object: Player)
		table.insert(self.Exited, Object)
	end

	function TargetData.AddToEntered(self: TargetHandler, Object: Player)
		table.insert(self.Entered, Object)
	end

	function TargetData.ClearEntered(self: TargetHandler)
		table.clear(self.Entered)
	end

	function TargetData.ClearExited(self: TargetHandler)
		table.clear(self.Exited)
	end

	--=======================================================================================================>

	function TargetData.GetTargetItem(self: TargetHandler, Key: string): Player
		return GetPlayer((self._Classes :: {Plagger: Plagger.Plagger}).Plagger, Key)		
	end

	function TargetData.GetEntered(self: TargetHandler): {Player}
		return self.Entered
	end

	function TargetData.GetExited(self: TargetHandler): {Player}
		return self.Exited
	end

	function TargetData.GetTrackers(self: TargetHandler): {[string]: Tracker.Tracker<Tracker.Trackables>}
		return Trackers
	end

	--=======================================================================================================>

	-- Create the Destroy Function:
	function TargetData.Destroy(self: TargetHandler)
		--===============================================================================>
		-- If already destroying, return:
		if self.Destroying == true then return end
		--===============================================================================>
		-- Set Destroying to true:
		self.Destroying = true
		-- Set is Tracking to false:
		self.IsTracking = false
		--===============================================================================>
		table.clear(self.Current)
		table.clear(self.Entered)
		table.clear(self.Exited)
		table.clear(self.Reused_HitTargetParts)
		--===============================================================================>
		-- Remove the Plagger function call:
		RemovePlagger(Local, Serial)
		--===============================================================================>
		-- Clear all self data:
		for Index, Data in pairs(self) do self[Index] = nil end
		--===============================================================================>
	end

	--=======================================================================================================>

	-- Return the TargetHandler Object:
	return TargetData

	--=======================================================================================================>	
end

--=======================================================================================================>

function TargetHandlers.Player.New(Serial: boolean): TargetHandler
	return PlayerHandler(Serial, false)
end

function TargetHandlers.LocalPlayer.New(Serial: boolean): TargetHandler
	return PlayerHandler(Serial, true)
end

function TargetHandlers.Part.New(Serial: boolean): TargetHandler
	--=======================================================================================================>

	-- Set Memory Category:
	debug.setmemorycategory('[Zoner]: TargetHandler')
	
	-- Trackers var
	local Trackers = nil
	
	-- Define the TargetData and Inherit from the Base Class:
	local TargetData: TargetHandler = {
		--====================================================>
		TargetType = 'Part';
		IsTracking = false;
		Destroying = false;
		--====================================================>
		EnteredHash = GetSignalHash('Part', 'Entered', 'Send');
		ExitedHash  = GetSignalHash('Part', 'Exited', 'Send');
		--====================================================>
		Current  = {};
		Entered  = {};
		Exited   = {};
		-- Reuseable array for filtering hit target parts on an individual tracker:
		Reused_HitTargetParts = {};
		--====================================================>
	} :: TargetHandler

	--=======================================================================================================>
	
	function TargetData.AddToExited(self: TargetHandler, Part: BasePart)
		table.insert(self.Exited, Part)
	end

	function TargetData.AddToEntered(self: TargetHandler, Part: BasePart)
		table.insert(self.Entered, Part)
	end

	function TargetData.ClearEntered(self: TargetHandler)
		table.clear(self.Entered)
	end

	function TargetData.ClearExited(self: TargetHandler)
		table.clear(self.Exited)
	end

	--=======================================================================================================>

	function TargetData.GetTargetItem(self: TargetHandler, Key: string): any
		return 		
	end

	function TargetData.GetEntered(self: TargetHandler): {BasePart}
		return self.Entered
	end

	function TargetData.GetExited(self: TargetHandler): {BasePart}
		return self.Exited
	end

	function TargetData.GetTrackers(self: TargetHandler): any
		return TRACKERS
	end

	--=======================================================================================================>
	
	-- Create the Destroy Function:
	function TargetData.Destroy(self: TargetHandler)
		--===============================================================================>
		-- If already destroying, return:
		if self.Destroying == true then return end
		--===============================================================================>
		-- Set Destroying to true:
		self.Destroying = true
		-- Set is Tracking to false:
		self.IsTracking = false
		--===============================================================================>
		table.clear(self.Current)
		table.clear(self.Entered)
		table.clear(self.Exited)
		table.clear(self.Reused_HitTargetParts)
		--===============================================================================>
	end

	--=======================================================================================================>

	-- Return the TargetHandler Object:
	return TargetData

	--=======================================================================================================>
end

--===========================================================================================================================>

--- Called from the Parent running this Module, to update some global scope:
function TargetHandlers.UpdateGlobalScope(ZonerHolder: Zoner_Types.ZonerHolder)
	Tracker.UpdateGlobalScope(ZonerHolder)
end

--===========================================================================================================================>

-- Freeze subtables:
table.freeze(TargetHandlers.Player)
table.freeze(TargetHandlers.LocalPlayer)
table.freeze(TargetHandlers.Part)

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(TargetHandlers) :: typeof(TargetHandlers)

--===========================================================================================================================>