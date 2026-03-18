--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Types')

--===========================================================================================================================>

--[=[
	@type ZoneBox {CFrame: CFrame, Size: Vector3}
	@tag private_types
	@within Zoner

	A type of Zone "Part". Instanceless representation of a single Zone Box
]=]
export type ZoneBox = {CFrame: CFrame, Size: Vector3}

--[=[
	@type ZoneBoxs {ZoneBox}
	@tag private_types
	@within Zoner

	An array of ZoneBoxes. Useful to create multiple, instanceless Zone boxes as one container
]=]
export type ZoneBoxes = {ZoneBox}

export type ZoneContainer = (Model | Folder | BasePart | {BasePart} | {[string]: BasePart} | ZoneBoxes )

--[=[
	@type ZoneContainerType ('Part' | 'Holder' | 'Parts' | 'Boxes')
	@tag private_types
	@within Zone

	Discriminates container representation ("Boxes" or "Instance" flavors)
]=]
export type ZoneContainerType = 'Part' | 'Holder' | 'Parts' | 'Boxes'

--[=[
	@type ZoneParts {BasePart}
	@tag private_types
	@within Zone

	An array of BaseParts
]=]
export type ZoneParts = {BasePart}
-- Create and Export Type:
export type ZonePieces = ZoneBoxes | ZoneParts
-- Create and Export Type:
export type ZonePiece = BasePart | ZoneBox

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>