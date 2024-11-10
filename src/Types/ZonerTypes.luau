--=======================================================================================================>
--!strict
--=======================================================================================================>

-- Grab the ZonerModule Reference:
local ZonerModule = script.Parent.Parent

-- Require the Trove Module for Cleanup:
local EnumsModule      = require(ZonerModule.Utility.Enums);
local TroveModule      = require(ZonerModule.Utility.Trove);

--=======================================================================================================>

local PlaggerTypes = require(ZonerModule.Classes.Plagger.Types);
local ZoneTypes          = require(script.Parent.ZoneTypes);

--=======================================================================================================>

export type ZoneContainer = ZoneTypes.ZoneContainer

--Recreate the Zone Object Type with the Public Versions of the Types.
--We recreate it here because we want the AutoComplete to label the Type as "Zone" and not "Zone_Public"
export type Zone = typeof(
	setmetatable({} :: ZoneTypes.ZoneMetaData_Public, {} :: ZoneModule)
)

-- Create and Export Module Type:
export type ZoneModule = {
	--====================================================>

	Destroy: 
		(self: Zone) -> ();
	
	SetDetection: 
		(self: Zone, NameOrId: number | EnumsModule.Detections) -> ();
	SetAccuracy: 
		(self: Zone, NameOrId: number | EnumsModule.Accuracies) -> ();
	SetSimulation: 
		(self: Zone, NameOrId: number | EnumsModule.Simulations) -> ();
	SetRate: 
		(self: Zone, NameOrId: number | EnumsModule.Rates) -> ();

	Relocate: 
		(self: Zone) -> Zone;
	
	--====================================================>

	__index: ZoneModule;

	--====================================================>
}

--=======================================================================================================>

-- Create and Export Type:
export type ZoneCoreActor = Actor & {
	Scripts: Folder & {['ZoneCore:Server']: Script; ['ZoneCore:Client']: Script; };
	Events:  Folder & {[string]: BindableEvent};
	Properties:  Configuration;
	States:  Configuration;
}

-- Create and Export Type:
export type ZonerFolder = ZoneTypes.ZonerFolder

-- Create and Export Object Type:
export type Zoner = typeof(
	setmetatable({} :: ZonerMetaData, {} :: ZonerModule)
)

-- Create and Export MetaData Type:
export type ZonerMetaData = { 
	--====================================================>
	_Trove: TroveModule.Trove;
	_ZoneTrove: TroveModule.Trove;
	--====================================================>
	_RunScope: 'Client' | 'Server';
	--====================================================>
	_Counters: {
		ActiveZoneCheck: {Counter: number; CounterMax: number};
	};
	--====================================================>
	_Zones: {[string]: ZoneTypes.Zone;};
	--====================================================>
	_ZoneModule: ZoneTypes.ZoneModule;
	_PlayerHandler: PlaggerTypes.Plagger;
	--====================================================>
	_SettingsFolder: typeof(script.Parent.Parent.Settings);
	--====================================================>
	_ZonerFolder: ZonerFolder;
	--====================================================>
	_ZonersFolder: Folder & {[string]: ZonerFolder};
	--====================================================>
}

-- Create and Export Module Type:
export type ZonerModule = {
	--====================================================>

	_Start: 
		() -> Zoner;
	Destroy: 
		(self: Zoner) -> ();

	_Initialize: 
		(self: Zoner) -> ();
	_SetEvents: 
		(self: Zoner) -> ();
	_SetData: 
		(self: Zoner) -> ();

	_OnPostSimulation: 
		(self: Zoner, Type: 'Sync'|'Desync', DeltaTime: number) -> ();

	_AddZone: 
		(self: Zoner, Container: ZoneTypes.ZoneContainer, Accuracy: (number | EnumsModule.Accuracies)?, Detection: (number | EnumsModule.Detections)?) -> Zone;
	_RemoveZone: 
		(self: Zoner, Identifier: string) -> ();

	--====================================================>
	
	NewZone: 
		(self: Zoner, Container: ZoneTypes.ZoneContainer, Accuracy: (number | EnumsModule.Accuracies)?, Detection: (number | EnumsModule.Detections)?) -> Zone;
	
	-- Basically just an alternate name for NewZone:
	NewZoneFromContainer: 
		(self: Zoner, Container: ZoneTypes.ZoneContainer, Accuracy: (number | EnumsModule.Accuracies)?, Detection: (number | EnumsModule.Detections)?) -> Zone;
	NewZoneFromRegion: 
		(self: Zoner, RegionCFrame: CFrame, RegionSize: Vector3, Accuracy: (number | EnumsModule.Accuracies)?, Detection: (number | EnumsModule.Detections)?) -> Zone;

	--====================================================>

	Enum: EnumsModule.Enums;

	--====================================================>

	__index: ZonerModule;

	--====================================================>
}

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>