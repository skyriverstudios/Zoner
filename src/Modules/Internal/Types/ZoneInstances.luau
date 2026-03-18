--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Types')

--===========================================================================================================================>

export type GroupsFolderGroup = Configuration & {Zones: Configuration}

export type ZoneFolder = Folder & {
	States:        Configuration;
	Config:        Configuration;
	ActiveTargets: Configuration;
	ActiveSignals: Configuration;
}

export type ZonerGroup = Configuration & {
	Zones: Folder & {[string]: ZoneFolder};
	Ids: Configuration;
}

export type ZonerActor = Actor & {
	Zones:   Folder & {[string]: ZoneFolder};
	Scripts: Folder & {['ZoneCore.Server']: Script; ['ZoneCore.Client']: Script; };
	Ids: Configuration;
}

export type ZonerHolder = ZonerActor | ZonerGroup

export type ZonerFolder = Folder & {
	Holders: Folder & {[string]: ZonerActor};
	Groups:  Folder & {[string]: GroupsFolderGroup};
	WorldModel: WorldModel?
}

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>