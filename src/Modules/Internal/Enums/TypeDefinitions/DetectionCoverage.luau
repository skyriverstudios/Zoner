--=======================================================================================================>
--!strict
--=======================================================================================================>

export type DetectionCoverages = 'Center' | 'AllParts' | 'AnyPart' | 'BoundingBox' | 'Automatic'

-- Create and Export Object Type:
export type DetectionCoverage_Enum = typeof(
	setmetatable({} :: {
		--===========================================>
		Name: string;
		--===========================================>
		Values: {
			['1']: number;
			['2']: number;
			['3']: number;
			['4']: number;
			['5']: number;
		};
		Names: {
			['Center']:      number;
			['AllParts']:    number;
			['AnyPart']:     number;
			['Automatic']:   number;
			['BoundingBox']: number;
		};
		--===========================================>
		['Center']:      number;
		['AllParts']:    number;
		['AnyPart']:     number;
		['BoundingBox']: number;
		['Automatic']:   number;
		--===========================================>
	}, {} :: DetectionCoverage_Enum2Table)
)

-- Create and Export Module Type:
type DetectionCoverage_Enum2Table = {
	--===========================================>
	GetName: 
		(self: DetectionCoverage_Enum, ValueOrProperty: any) -> DetectionCoverages | 'Failure',
	GetValue: 
		(self: DetectionCoverage_Enum, NameOrProperty: any) -> any,
	GetProperty: 
		(self: DetectionCoverage_Enum, NameOrValue: any) -> string?,
	--===========================================>

	__index: DetectionCoverage_Enum2Table,
	--===========================================>
}

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>