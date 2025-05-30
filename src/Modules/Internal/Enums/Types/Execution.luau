--=======================================================================================================>
--!strict
--=======================================================================================================>

export type Executions = 'Parallel' | 'Serial'

-- Create and Export Object Type:
export type Execution_Enum = typeof(
	setmetatable({} :: Execution_EnumMetaData, {} :: Execution_Enum2Table)
)

-- Create and Export MetaData Type:
type Execution_EnumMetaData = {
	--===========================================>
	Name: string;
	--===========================================>
	Properties: {};
	Values: {
		['1']: number;
		['2']: number;
	};
	Names: {
		['Parallel']: number;
		['Serial']:   number;
	};
	--===========================================>
	Parallel: number;
	Serial:   number;
	--===========================================>
}

-- Create and Export Module Type:
type Execution_Enum2Table = {
	--===========================================>
	GetName: 
		(self: Execution_Enum, ValueOrProperty: any) -> Executions | 'Failure',
	GetValue: 
		(self: Execution_Enum, NameOrProperty:  string|number) -> number,
	GetProperty: 
		(self: Execution_Enum, NameOrValue:     string|number) -> number?,

	--===========================================>

	__index: Execution_Enum2Table,

	--===========================================>
}

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>