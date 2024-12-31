--=======================================================================================================>
--!strict
--=======================================================================================================>

-- Import the TargetTracker:
local TargetTrackerTypes = require(script.Parent.Classes.TargetTracker.Types)
-- Import the PlaggerTypes:
local PlaggerTypes       = require(script.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Parent.Plagger.Types);

--=======================================================================================================>

-- Export the Handler Types all Together as one:
export type TargetHandlers = PlayersTargetHandler | LocalPlayerTargetHandler | PartsTargetHandler
export type TargetTypes    = 'LocalPlayer' | 'Players' | 'Items' | 'Parts';
export type TargetTracker  = TargetTrackerTypes.TargetTracker

--=======================================================================================================>

-- Export the Players Target Handler Type:
export type PlayersTargetHandler = DefaultPlayerHandler

-- Export the LocalPlayer Target Handler Type:
export type LocalPlayerTargetHandler = DefaultPlayerHandler

-- Export the Parts Target Handler Type:
export type PartsTargetHandler = { 
	--====================================================>
	-- Whether the Zone Logic is running for this Target:
	IsTracking: boolean;
	-- Whether the Handler is being Destroyed:
	Destroying: boolean;
	-- What type of Target it is:
	TargetType: 'Parts';
	--====================================================>
	-- DetectionMode Setting:
	_DetectionMode:     number;
	-- DetectionCoverage Setting:
	_DetectionCoverage: number;
	--====================================================>
	-- Dictionary to track the Current  Parts in the Zone:
	CurrentParts:  {[BasePart]: boolean};
	-- Dictionary to track the Previous Parts in the Zone:
	PreviousParts: {[BasePart]: boolean};
	-- Array that is cleared every run. Fires an event for each Part when entering Zone:
	Entered:  {BasePart};
	-- Array that is cleared every run. Fires an event for each Part when exiting Zone:
	Exited:   {BasePart};
	--====================================================>
	-- Destroy Method:
	Destroy: 
		(self: PartsTargetHandler) -> ();
	-- Set Detection Method:
	SetDetection: 
		(self: PartsTargetHandler, DetectionCoverage: number, DetectionMode: number, DetectionMethod: number?) -> ();
	--====================================================>
} 

-- Export the Players Target Handler Type:
export type DefaultPlayerHandler = { 
	--====================================================>
	-- Whether the Zone Logic is running for this Target:
	IsTracking: boolean;
	-- Whether the Handler is being Destroyed:
	Destroying: boolean;
	-- What type of Target it is:
	TargetType: 'Players' | 'LocalPlayer';
	--====================================================>
	-- DetectionMode Setting:
	_DetectionMode:     number;
	-- DetectionCoverage Setting:
	_DetectionCoverage: number;
	--====================================================>
	-- Trackers Dictionary:
	Trackers: {[string]: TargetTrackerTypes.TargetTracker};
	-- Dictionary to track the Current  Parts in the Zone:
	CurrentParts:  {[BasePart]: boolean};
	-- Dictionary to track the Previous Parts in the Zone:
	PreviousParts: {[BasePart]: boolean};
	-- Array that is cleared every run. Fires an event for each Part when entering Zone:
	Entered:  {Player};
	-- Array that is cleared every run. Fires an event for each Part when exiting Zone:
	Exited:   {Player};
	--====================================================>
	-- Holds Event Signal Connections:
	_Events:  {[string]: RBXScriptConnection};
	-- Holds Class Objects:
	_Classes: {Plagger: PlaggerTypes.Plagger};
	--====================================================>
	-- Destroy Method:
	Destroy: 
		(self: DefaultPlayerHandler) -> ();
	GetPlayer: 
		(self: DefaultPlayerHandler, PlayerName: string) -> Player;
	
	GetTargetItem: 
		(self: DefaultPlayerHandler, Key: string, Tracker: TargetTrackerTypes.TargetTracker) -> Player;
	
	AddToEntered: 
		(self: DefaultPlayerHandler, Object: Player) -> ();
	AddToExited: 
		(self: DefaultPlayerHandler, Object: Player) -> ();

	ClearExited: 
		(self: DefaultPlayerHandler) -> ();
	ClearEntered: 
		(self: DefaultPlayerHandler) -> ();
	
	RemoveFromEntered: 
		(self: DefaultPlayerHandler, Object: Player) -> ();
	RemoveFromExited: 
		(self: DefaultPlayerHandler, Object: Player) -> ();

	GetEntered: 
		(self: DefaultPlayerHandler) -> {Player};
	GetExited: 
		(self: DefaultPlayerHandler) -> {Player};

	GetTrackers: 
		(self: DefaultPlayerHandler) -> {[string]: TargetTrackerTypes.TargetTracker};



	-- Set Detection Method:
	SetDetection: 
		(self: DefaultPlayerHandler, DetectionCoverage: number, DetectionMode: number, DetectionMethod: number?) -> ();
	--====================================================>
} 

--=======================================================================================================>

-- Export the Players Target Handler Type:
export type DefaultTargetHandler = { 
	--====================================================>
	-- Whether the Zone Logic is running for this Target:
	IsTracking: boolean;
	-- Whether the Handler is being Destroyed:
	Destroying: boolean;
	-- What type of Target it is:
	TargetType: 'Players' | 'LocalPlayer' | 'Parts';
	--====================================================>
	-- DetectionMode Setting:
	_DetectionMode:     number;
	-- DetectionCoverage Setting:
	_DetectionCoverage: number;
	--====================================================>
	-- Trackers Dictionary:
	Trackers: {[string]: TargetTrackerTypes.TargetTracker};
	-- Dictionary to track the Current  Parts in the Zone:
	CurrentParts:  {[BasePart]: boolean};
	-- Dictionary to track the Previous Parts in the Zone:
	PreviousParts: {[BasePart]: boolean};
	-- Array that is cleared every run. Fires an event for each Part when entering Zone:
	Entered:  {any};
	-- Array that is cleared every run. Fires an event for each Part when exiting Zone:
	Exited:   {any};
	--====================================================>
	
	AddToEntered: 
		(self: DefaultTargetHandler, Object: any) -> ();
	AddToExited: 
		(self: DefaultTargetHandler, Object: any) -> ();

	ClearExited: 
		(self: DefaultTargetHandler) -> ();
	ClearEntered: 
		(self: DefaultTargetHandler) -> ();

	GetTargetItem: 
		(self: DefaultTargetHandler, Key: string, Tracker: TargetTrackerTypes.TargetTracker) -> any;

	RemoveFromEntered: 
		(self: DefaultTargetHandler, Object: any) -> ();
	RemoveFromExited: 
		(self: DefaultTargetHandler, Object: any) -> ();
	
	GetEntered: 
		(self: DefaultTargetHandler) -> {any};
	GetExited: 
		(self: DefaultTargetHandler) -> {any};
	
	GetTrackers: 
		(self: DefaultTargetHandler) -> {[string]: TargetTrackerTypes.TargetTracker};
	
	
	-- Destroy Method:
	Destroy: 
		(self: DefaultTargetHandler) -> ();
	-- Set Detection Method:
	SetDetection: 
		(self: DefaultTargetHandler, DetectionCoverage: number, DetectionMode: number, DetectionMethod: number?) -> ();
	--====================================================>
} 

--=======================================================================================================>

-- Clear from memory:
TargetTrackerTypes = nil :: any
PlaggerTypes       = nil :: any

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>