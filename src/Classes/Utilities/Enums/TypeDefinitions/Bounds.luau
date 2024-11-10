--=======================================================================================================>
--!strict
--=======================================================================================================>

export type Bounds = 'Automatic' | 'PerPart' | 'BoxExact' | 'BoxVoxel'

-- Create and Export Object Type:
export type Bounds_Enum = typeof(
	setmetatable({} :: {
		--===========================================>
		Name: string;
		--===========================================>
		Values: {
			['1']: number;
			['2']: number;
			['3']: number;
			['4']: number;
		};
		Names: {
			['Automatic']: number;
			['PerPart']:   number;
			['BoxExact']:  number;
			['BoxVoxel']:  number;
		};
		--===========================================>
		['Automatic']: number;
		['PerPart']:   number;
		['BoxExact']:  number;
		['BoxVoxel']:  number;
		--===========================================>
	}, {} :: Bounds_EnumTable)
)

-- Create and Export Module Type:
type Bounds_EnumTable = {
	--===========================================>
	GetName: 
		(self: Bounds_Enum, ValueOrProperty: any) -> Bounds | 'Failure',
	GetValue: 
		(self: Bounds_Enum, NameOrProperty: any) -> any,
	GetProperty: 
		(self: Bounds_Enum, NameOrValue: any) -> string?,
	--===========================================>
	__index: Bounds_EnumTable,
	--===========================================>
}
--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>