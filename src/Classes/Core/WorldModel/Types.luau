--=======================================================================================================>
--!strict
--=======================================================================================================>

-- Grab the ZonerModule Reference:
local ZonerModule = script.Parent.Parent.Parent.Parent

-- Require the Types:
local SharedTypes = require(ZonerModule.Types.SharedTypes);

--=======================================================================================================>

-- Export ZonerFolder:
export type ZonerFolder = SharedTypes.ZonerFolder

-- Create and Export Module Type:
export type WorldModelModule = {
	--===========================================>
	GetWorldModel: 
		(self: WorldModelModule) -> WorldModel,
	--===========================================>
	_GetCombinedResults: 
		(self: WorldModelModule, MethodName: string, Relocated: boolean,  ...any) -> {BasePart},
	--===========================================>
	GetPartsInPart: 
		(self: WorldModelModule, Relocated: boolean, Part: BasePart, OverlapParam: OverlapParams) -> {BasePart},
	GetPartBoundsInBox: 
		(self: WorldModelModule, Relocated: boolean, CFrame: CFrame, Size: Vector3, OverlapParam: OverlapParams) -> {BasePart},
	GetPartBoundsInRadius: 
		(self: WorldModelModule, Relocated: boolean, Position: Vector3, Radius: number, OverlapParam: OverlapParams) -> {BasePart},
	--===========================================>


	Values: {WorldModel: WorldModel};
	RunScope: 'Server'|'Client'; 
	--===========================================>

	__index: WorldModelModule,

	--===========================================>
}

--=======================================================================================================>

-- Return an empty table:
return table.freeze({})

--=======================================================================================================>