--=======================================================================================================>
--!strict
--=======================================================================================================>

export type DetectionMethods = 'Automatic' | 'Efficient' | 'Simple' | 'Complex'

-- Create and Export Object Type:
export type DetectionMethod_Enum = typeof(
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
			['Efficient']: number;
			['Simple']:    number;
			['Complex']:   number;
		};
		--===========================================>
		['Automatic']: number;
		['Efficient']: number;
		['Simple']:    number;
		['Complex']:   number;
		--===========================================>
	}, {} :: DetectionMethod_Enum2Table)
)

-- Create and Export Module Type:
type DetectionMethod_Enum2Table = {
	--===========================================>
	GetName: 
		(self: DetectionMethod_Enum, ValueOrProperty: any) -> DetectionMethods | 'Failure',
	GetValue: 
		(self: DetectionMethod_Enum, NameOrProperty: any) -> any,
	GetProperty: 
		(self: DetectionMethod_Enum, NameOrValue: any) -> string?,
	--===========================================>

	__index: DetectionMethod_Enum2Table,
	--===========================================>
}

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>