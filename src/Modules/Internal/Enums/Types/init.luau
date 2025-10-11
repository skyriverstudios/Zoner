--=======================================================================================================>
--!strict
--=======================================================================================================>

local DetectionCoverageTypes = require(script.DetectionCoverage)
local DetectionMethodTypes   = require(script.DetectionMethod)
local DetectionModeTypes     = require(script.DetectionMode)
local ExecutionTypes         = require(script.Execution)
local BoundsTypes            = require(script.Bounds)


export type DetectionCoverages = DetectionCoverageTypes.DetectionCoverages;
export type DetectionMethods   = DetectionMethodTypes.DetectionMethods;
export type DetectionModes     = DetectionModeTypes.DetectionModes;
export type Executions         = ExecutionTypes.Executions
export type Bounds             = BoundsTypes.Bounds

--[=[
	@type DetectionMethods 'Automatic' | 'Efficient' | 'Simple' | 'Complex'
	@within Enums
]=]
--[=[
	@type DetectionModes 'Full' | 'Touch' | 'Point' | 'Automatic'
	@within Enums
]=]
--[=[
	@type DetectionCoverages 'Center' | 'AllParts' | 'AnyPart' | 'Automatic'
	@within Enums
]=]
--[=[
	@type Rates 'Slow' | 'Moderate' | 'Fast' | 'Immediate'
	@within Enums
]=]
--[=[
	@type Executions 'Parallel' | 'Serial'
	@within Enums
]=]
--[=[
	@type Simulations 'PreRender' | 'PostSimulation' | 'PreSimulation'
	@within Enums
]=]

--=======================================================================================================>

export type Rates = 
	| 'Slow' | 'Moderate' | 'Fast' | 'Immediate' 

-- Create and Export Object Type:
type Rate_Enum = typeof(
	setmetatable({} :: Rate_EnumMetaData, {} :: Rate_Enum2Table)
)

-- Create and Export MetaData Type:
type Rate_EnumMetaData = {
	--===========================================>
	Name: string;

	--===========================================>
	Properties: {
		['0']:   number;
		['0.1']: number;
		['0.5']: number;
		['1']:   number;
	};
	Values: {
		['1']: number;
		['2']: number;
		['3']: number;
		['4']: number;
	};
	Names: {
		['Slow']:      number;
		['Moderate']:  number;
		['Fast']:      number;
		['Immediate']: number;
	};
	--===========================================>
	Slow:      number;
	Moderate:  number;
	Fast:      number;
	Immediate: number;
	--===========================================>
}

-- Create and Export Module Type:
type Rate_Enum2Table = {
	--===========================================>
	GetName: 
		(self: Rate_Enum, ValueOrProperty: any) -> Rates | 'Failure',
	GetValue: 
		(self: Rate_Enum, NameOrProperty: any) -> any,
	GetProperty: 
		(self: Rate_Enum, NameOrValue: any) -> number?,

	--===========================================>

	__index: Rate_Enum2Table,

	--===========================================>
}

--=======================================================================================================>

export type Simulations = 
	| 'PreRender' | 'PostSimulation' | 'PreSimulation'

-- Create and Export Object Type:
type Simulation_Enum = typeof(
	setmetatable({} :: Simulation_EnumMetaData, {} :: Simulation_Enum2Table)
)

-- Create and Export MetaData Type:
type Simulation_EnumMetaData = {
	--===========================================>
	Name: string;
	--===========================================>
	Values: {
		['1']: number;
		['2']: number;
		['3']: number;
	};
	Names: {
		['PreRender']:      number;
		['PostSimulation']: number;
		['PreSimulation']:  number;
	};
	--===========================================>
	PreRender:      number;
	PostSimulation: number;
	PreSimulation:  number;
	--===========================================>
}

-- Create and Export Module Type:
type Simulation_Enum2Table = {

	--===========================================>
	GetName: 
		(self: Simulation_Enum, ValueOrProperty: any) -> Simulations | 'Failure',
	GetValue: 
		(self: Simulation_Enum, NameOrProperty: any) -> any,
	GetProperty: 
		(self: Simulation_Enum, NameOrValue: any) -> string?,

	--===========================================>

	__index: Simulation_Enum2Table,

	--===========================================>
}

--=======================================================================================================>

-- Create and Export Type:
export type Enums = {
	['DetectionCoverage']: DetectionCoverageTypes.DetectionCoverage_Enum;
	['DetectionMethod']:   DetectionMethodTypes.DetectionMethod_Enum;
	['DetectionMode']:     DetectionModeTypes.DetectionMode_Enum;
	['Simulation']:        Simulation_Enum;
	['Execution']:         ExecutionTypes.Execution_Enum;
	['Bounds']:            BoundsTypes.Bounds_Enum;
	['Rate']:              Rate_Enum;
};

-- Create and Export Type:
export type EnumDetails = {{string|number}}

--=======================================================================================================>
-- Create the Object Types:


-- Create and Export Object Type:
export type Enum2 = typeof(
	setmetatable({} :: Enum2MetaData, {} :: Enum2Table)
)

-- Create and Export MetaData Type:
export type Enum2MetaData = {
	--===========================================>
	Name: string;
	--===========================================>
	_Type: 'Enum2';
	--===========================================>
	Properties: {[string]: number};
	Values:     {[string]: number};
	Names:      {[string]: number};
	--===========================================>
	Enums: {{Name: string, Value: number | string, Property: string?}};
	--===========================================>
}

-- Create and Export Module Type:
export type Enum2Table = {
	--===========================================>
	
	New: 
		(EnumName: string, Details: EnumDetails) -> Enum2,
	Destroy: 
		(self: Enum2) -> (),

	--===========================================>
	GetName: 
		(self: Enum2, ValueOrProperty: any) -> string,
	GetValue: 
		(self: Enum2, NameOrProperty: any) -> any,
	GetProperty: 
		(self: Enum2, NameOrValue: any) -> string?,

	--===========================================>

	__index: Enum2Table,

	--===========================================>
}

--=======================================================================================================>

-- Create and Export Module Type:
export type EnumsModule = {
	--===========================================>

	GetEnums: 
		(self: EnumsModule) -> Enums,
	CreateEnum: 
		(self: EnumsModule, EnumName: string, Details: EnumDetails) -> (),
	Start: 
		(self: EnumsModule) -> (),

	--===========================================>

	Enums:   Enums;
	Started: boolean;
	
	--===========================================>

	__index: EnumsModule,

	--===========================================>
}

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>