--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Types')

--===========================================================================================================================>

-- ZoneTargets
export type ZoneTargets = 'Players'|'LocalPlayer'|'Parts'|'Items'

export type ZoneActiveTargetsTable = {
	['LocalPlayer']: boolean;
	['Player']:      boolean;
	['Item']:        boolean;
	['Part']:        boolean;
}

export type ZoneActiveSignalsTable = {
	['LocalPlayerEntered']: boolean;
	['LocalPlayerExited']:  boolean;
	['PlayerEntered']:      boolean;
	['PlayerExited']:       boolean;
	['PartEntered']:        boolean;
	['PartExited']:         boolean;
	['ItemEntered']:        boolean;
	['ItemExited']:         boolean;
}

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>