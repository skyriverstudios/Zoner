--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Define Module table
local TargetHandlerModule: TargetHandlerModule = {
	DefaultPlayer = {};
	LocalPlayer   = {};
	Players       = {};
	Items         = {};
	Parts         = {};
}

--===========================================================================================================================>
--[ VARIABLES: ]

-- Require the Target Tracker Sub Class Module:
local TargetTrackerModule = require(script.Classes.TargetTracker);
-- Require the Plagger Module:
local PlaggerModule       = require(script.Parent.Parent.Parent.Parent.Parent.Plagger);

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local TypeDefinitions = require(script.Types)

-- Export the Target Handler Types:
export type LocalPlayerTargetHandler = TypeDefinitions.LocalPlayerTargetHandler
export type DefaultPlayerHandler     = TypeDefinitions.DefaultPlayerHandler
export type PlayersTargetHandler     = TypeDefinitions.PlayersTargetHandler
export type PartsTargetHandler       = TypeDefinitions.PartsTargetHandler
export type TargetHandlers           = TypeDefinitions.TargetHandlers
export type TargetTypes              = TypeDefinitions.TargetTypes

-- Make the Module into a Type:
export type TargetHandlerModule = typeof(TargetHandlerModule)

--===========================================================================================================================>
--[ TARGET HANDLER FUNCTIONS: ]


-- Split Destroy Logic into its own Local Function because of Repeat Code:
local function TargetDestroy(Handler: TargetHandlers)
	--=======================================================================================================>
	-- Clear Tables:
	table.clear(Handler.PreviousParts)
	table.clear(Handler.CurrentParts)
	table.clear(Handler.Entered)
	table.clear(Handler.Exited)
	--===============================================================================>
	-- Clear all self._Events data:
	if Handler['_Events'] then 
		for Key, Data in pairs(Handler['_Events']) do Handler['_Events'][Key]:Disconnect(); Handler['_Events'][Key] = nil :: any end
	end
	-- Clear all self._Classes data:
	if Handler['_Classes'] then 
		for Key, Data in pairs(Handler['_Classes']) do Handler['_Classes'][Key]:Destroy();   Handler['_Classes'][Key] = nil :: any end
	end
	-- Clear all self.Trackers data:
	if Handler['Trackers'] then 
		for Key, Data in pairs(Handler['Trackers']) do Handler['Trackers'][Key]:Destroy();   Handler['Trackers'][Key] = nil :: any end
	end
	--===============================================================================>
	-- Clear all self data:
	for Index, Data in pairs(Handler) do Handler[Index] = nil end
	--=======================================================================================================>
end

--=======================================================================================================>

function TargetHandlerModule.Players.New(DetectionCoverage: number, DetectionMode: number, Serial: boolean): PlayersTargetHandler
	--=======================================================================================================>
	return TargetHandlerModule.DefaultPlayer.New(DetectionCoverage, DetectionMode, Serial, false)
	--=======================================================================================================>
end

function TargetHandlerModule.LocalPlayer.New(DetectionCoverage: number, DetectionMode: number, Serial: boolean): LocalPlayerTargetHandler
	--=======================================================================================================>
	return TargetHandlerModule.DefaultPlayer.New(DetectionCoverage, DetectionMode, Serial, true)
	--=======================================================================================================>
end

function TargetHandlerModule.Parts.New(DetectionCoverage: number, DetectionMode: number, Serial: boolean): PartsTargetHandler
	--=======================================================================================================>

	-- Define the TargetData and Inherit from the Base Class:
	local TargetData: PartsTargetHandler = {
		--====================================================>
		TargetType = 'Parts';
		IsTracking = false;
		Destroying = false;
		--====================================================>
		_DetectionMode     = DetectionMode;
		_DetectionCoverage = DetectionCoverage;
		--====================================================>
		Current = {};
		Previous = {};
		Entered = {};
		Exited = {};
		--====================================================>
	} :: PartsTargetHandler

	--=======================================================================================================>

	-- Create the Destroy Function:
	function TargetData.Destroy(self: PartsTargetHandler)
		--===============================================================================>
		-- If already destroying, return:
		if self.Destroying == true then return end
		--===============================================================================>
		-- Set Destroying to true:
		self.Destroying = true
		-- Set is Tracking to false:
		self.IsTracking = false
		--===============================================================================>
		TargetDestroy(self)
		--===============================================================================>
	end

	-- Create the Destroy Function:
	function TargetData.SetDetection(self: PartsTargetHandler, DetectionCoverage: number, DetectionMode: number, DetectionMethod: number?)
		--===============================================================================>
		-- Set the Internal Value:
		self._DetectionCoverage = DetectionCoverage
		self._DetectionMode     = DetectionMode
		--===============================================================================>
	end

	--=======================================================================================================>

	-- Return the TargetHandler Object:
	return TargetData

	--=======================================================================================================>
end

--=======================================================================================================>

function TargetHandlerModule.DefaultPlayer.New(DetectionCoverage: number, DetectionMode: number, Serial: boolean, Local: boolean): DefaultPlayerHandler
	--=======================================================================================================>

	-- Define the TargetData and Inherit from the Base Class:
	local TargetData: DefaultPlayerHandler = {
		--====================================================>
		TargetType = if Local then 'LocalPlayer' else 'Players';
		IsTracking = false;
		Destroying = false;
		--====================================================>
		_DetectionMode     = DetectionMode;
		_DetectionCoverage = DetectionCoverage;
		--====================================================>
		-- Trackers Dictionary:
		Trackers = {};
		CurrentParts  = {};
		PreviousParts = {};
		Entered = {};
		Exited = {};
		--====================================================>
		-- Classes Dictionary:
		_Classes = {Plagger = PlaggerModule.New(true, if Local then true else false, not Serial)};
		-- Events Dictionary:
		_Events  = {};
		--====================================================>
	} :: DefaultPlayerHandler

	--=======================================================================================================>

	-- Connect to the Character Tag Added Signal:
	-- Fires when a Part with the Character Tag is added back to the Workspace:
	TargetData._Events['CharacterAdded'] = TargetData._Classes.Plagger:GetCharacterAddedSignal():Connect(function(Character: Model)
		--==============================================================================>
		-- If there is a Player ItemTracker Object for this Character:
		-- Destroy it and clear it from the reference:
		if TargetData.Trackers[Character.Name] then TargetData.Trackers[Character.Name]:Destroy(); TargetData.Trackers[Character.Name] = nil end
		--==============================================================================>
		TargetData.Trackers[Character.Name] = TargetTrackerModule.New(
			Character, TargetData._DetectionCoverage, TargetData._DetectionMode
		)
		--==============================================================================>
	end)

	-- Connect to the Character Tag Removed Signal:
	-- Fires when a Part with the Character Tag is removed from the Workspace:
	TargetData._Events['CharacterRemoved'] = TargetData._Classes.Plagger:GetCharacterRemovedSignal():Connect(function(Character: Model)
		--==============================================================================>
		-- If there is a Player ItemTracker Object for this Character:
		-- Destroy it and clear it from the reference:
		if TargetData.Trackers[Character.Name] then TargetData.Trackers[Character.Name]:Destroy(); TargetData.Trackers[Character.Name] = nil end
		--==============================================================================>
	end)

	--=======================================================================================================>

	-- Get Individual Player Instance Method:
	function TargetData.GetPlayer(self: DefaultPlayerHandler, PlayerName: string): Player
		--===============================================================================>
		return self._Classes.Plagger:GetPlayers()[PlayerName]
		--===============================================================================>
	end

	-- Create the Destroy Function:
	function TargetData.SetDetection(self: DefaultPlayerHandler, DetectionCoverage: number, DetectionMode: number, DetectionMethod: number?)
		--===============================================================================>
		-- Set the Internal Value:
		self._DetectionCoverage, self._DetectionMode = DetectionCoverage, DetectionMode
		-- Loop through the Player ItemTrackers:
		-- Call the Detection Set Method on the Tracked Object:
		for Name: string, ItemTracker in self.Trackers do ItemTracker:SetDetection(DetectionCoverage, DetectionMode) end
		--===============================================================================>
	end

	--=======================================================================================================>
	
	-- Create the Destroy Function:
	function TargetData.Destroy(self: DefaultPlayerHandler)
		--===============================================================================>
		-- If already destroying, return:
		if self.Destroying == true then return end
		--===============================================================================>
		-- Set Destroying to true:
		self.Destroying = true
		-- Set is Tracking to false:
		self.IsTracking = false
		--===============================================================================>
		TargetDestroy(self)
		--===============================================================================>
	end
	
	--=======================================================================================================>

	-- Loop through the already Spawned Characters and Add their Trackers:
	for Name: string, Character: Model in TargetData._Classes.Plagger:GetCharacters() do
		--==============================================================================>
		-- If there is a Player ItemTracker Object for this Character:
		-- Destroy it and clear it from the reference:
		if TargetData.Trackers[Character.Name] then 
			TargetData.Trackers[Character.Name]:Destroy() 
			TargetData.Trackers[Character.Name] = nil 
		end
		--==============================================================================>
		TargetData.Trackers[Character.Name] = TargetTrackerModule.New(
			Character, TargetData._DetectionCoverage, TargetData._DetectionMode
		)
		--==============================================================================>
	end

	--=======================================================================================================>

	-- Return the TargetHandler Object:
	return TargetData

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Freeze each Sub Table:
table.freeze(TargetHandlerModule.DefaultPlayer)
table.freeze(TargetHandlerModule.LocalPlayer)
table.freeze(TargetHandlerModule.Players)
table.freeze(TargetHandlerModule.Parts)
table.freeze(TargetHandlerModule.Items)

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(TargetHandlerModule) :: TargetHandlerModule

--===========================================================================================================================>