--=======================================================================================================>
--!strict
--=======================================================================================================>

export type DetectionModes = 'Full' | 'Touch' | 'Point' | 'Automatic'

-- Create and Export Object Type:
export type DetectionMode_Enum = typeof(
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
			['Full']:  number;
			['Touch']: number;
			['Point']: number;
			['Automatic']: number;
		};
		--===========================================>
		['Full']:  number;
		['Touch']: number;
		['Point']: number;
		['Automatic']: number;
		--===========================================>
	}, {} :: DetectionMode_Enum2Table)
)

-- Create and Export Module Type:
type DetectionMode_Enum2Table = {
	--===========================================>
	GetName: 
		(self: DetectionMode_Enum, ValueOrProperty: any) -> DetectionModes | 'Failure',
	GetValue: 
		(self: DetectionMode_Enum, NameOrProperty: any) -> any,
	GetProperty: 
		(self: DetectionMode_Enum, NameOrValue: any) -> string?,
	--===========================================>

	__index: DetectionMode_Enum2Table,
	--===========================================>
}

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>