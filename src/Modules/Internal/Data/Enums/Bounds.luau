--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Data')

--===========================================================================================================================>

-- Export the Type:
export type Bounds = 'AUTOMATIC'|'PER_PART'|'BOX_EXACT'|'BOX_VOXEL'

-- Export the Type:
export type BoundsEnum = {Name: Bounds, Value: number}

-- Table of Enums:
local ENUMS = {
	--===================================>

	-- Automatically selects the most appropriate bounds for detection,
	-- based on the zone’s shape and target complexity.
	Automatic = table.freeze({Name = 'AUTOMATIC' :: 'AUTOMATIC', Value = 1} :: BoundsEnum);

	-- Detects each part of the zone individually. Useful for zones with
	-- complex or irregular shapes where precise detection per part is necessary.
	PerPart = table.freeze({Name = 'PER_PART' :: 'PER_PART', Value = 2} :: BoundsEnum);

	-- Combines all parts of the zone into a single, exact bounding box
	-- without rotation. Provides efficient detection for simpler shapes.
	BoxExact = table.freeze({Name = 'BOX_EXACT' :: 'BOX_EXACT', Value = 3} :: BoundsEnum);

	-- Combines all parts of the zone into a bounding box aligned to
	-- the voxel grid. Ideal where some approximation is acceptable.
	BoxVoxel = table.freeze({Name = 'BOX_VOXEL' :: 'BOX_VOXEL', Value = 4} :: BoundsEnum);

	--===================================>
};

-- Table of Network Hashes:
local HASH = {
	--===================================>
	Read  = table.freeze({
		[ENUMS.Automatic.Value] = ENUMS.Automatic :: BoundsEnum;
		[ENUMS.PerPart.Value]   = ENUMS.PerPart   :: BoundsEnum;
		[ENUMS.BoxExact.Value]  = ENUMS.BoxExact  :: BoundsEnum;
		[ENUMS.BoxVoxel.Value]  = ENUMS.BoxVoxel  :: BoundsEnum;
	});
	Write = table.freeze({
		[ENUMS.Automatic :: BoundsEnum] = ENUMS.Automatic.Value;
		[ENUMS.PerPart   :: BoundsEnum] = ENUMS.PerPart.Value;
		[ENUMS.BoxExact  :: BoundsEnum] = ENUMS.BoxExact.Value;
		[ENUMS.BoxVoxel  :: BoundsEnum] = ENUMS.BoxVoxel.Value;
	});
	--===================================>
}

--==========================================================================================================================>

-- Return the Frozen Table:
return table.freeze({
	ENUMS = table.freeze(ENUMS);
	HASH  = table.freeze(HASH);
})

--==========================================================================================================================>