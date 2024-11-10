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
		(self: WorldModelModule, MethodName: string, ...any) -> {Instance},
	--===========================================>
	GetPartsInPart: 
		(self: WorldModelModule, Part: BasePart, OverlapParam: OverlapParams) -> {Instance},
	GetPartBoundsInBox: 
		(self: WorldModelModule, CFrame: CFrame, Size: Vector3, OverlapParam: OverlapParams) -> {Instance},
	GetPartBoundsInRadius: 
		(self: WorldModelModule, Position: Vector3, Radius: number, OverlapParam: OverlapParams) -> {Instance},
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