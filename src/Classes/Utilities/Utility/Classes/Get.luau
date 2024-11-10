--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Define Module table
local Get: GetModule = {} :: GetModule

--===========================================================================================================================>

local HttpService = game:GetService('HttpService')

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local TypeDefinitions: {} = require(script:FindFirstAncestor('Utility').TypeDefinitions)

-- Insert the Object Types:
type GetModule = TypeDefinitions.GetModule

-- Insert other types:
type Dictionary = TypeDefinitions.Dictionary
type Array = TypeDefinitions.Array
type Table = TypeDefinitions.Table

--===========================================================================================================================>
--[ GET METHODS: ]


-- Returns a Material Enum converted into a string:
function Get.Material(MaterialEnum: Enum.Material): string
	return string.gsub(tostring(MaterialEnum), "Enum.Material.", "")	
end

-- Returns a State Enum converted into a string:
function Get.HumanoidState(HumanoidStateEnum: Enum.HumanoidStateType): string
	return string.gsub(tostring(HumanoidStateEnum), "Enum.HumanoidStateType.", "")	
end

-- Returns an Array of Strings split from a String seperated by ';' :
function Get.DataFromString(DataString: string): {string}
	return string.split(DataString,";") 
end

-- Method that will return the InputObject's currently using Input Enum to a string:
function Get.InputString(InputObject: InputObject): string
	--===========================================================================================>
	if (InputObject.UserInputType == Enum.UserInputType.Keyboard) then
		return string.gsub(tostring(InputObject.KeyCode), "Enum.KeyCode.", "")	
	else
		return string.gsub(tostring(InputObject.UserInputType), "Enum.UserInputType.", "")
	end
	--===========================================================================================>
end

-- Method that will take in 3 types of Values that could represent a boolean, and convert/return them to the proper type:
function Get.ConvertedBoolean(Value: boolean | string | number):  string | boolean
	--===========================================================================================>
	if typeof(Value) == "boolean" then
		return if Value == true then '1' else '0'
	elseif typeof(Value) == "string" then
		return if Value == '1' then true else false
	elseif typeof(Value) == "number" then
		return if Value == 1 then true else false
	else 
		return false
	end
	--===========================================================================================>
end

-- Method that will take the passed DataTable and turn it into an array, and return the Values needed to C style loop over it:
function Get.ArrayLooperData(DataTable: Table, LoopNum: number): (Array, number, number)
	--===========================================================================================>
	-- If a Table is a Dictionary, create an Array from the Indexs, else use the Array sent:
	local DataTable: Array = if Get._Utility.Table.IsDictionary(DataTable) then Get._Utility.Table.Keys(DataTable) else DataTable
	-- Return the various Values of the DataTable:
	return DataTable, #DataTable, #DataTable * LoopNum
	--===========================================================================================>
end

-- Method that will return the Lighting Status string based on the Time:
@native
function Get.LightingStatus(Time: number): ('None' | 'Night' | 'Day')
	--===========================================================================================>
	-- Minutes after midnight is clocktime x 60
	local Min = math.abs(Time * 60)
	-- Define Number Values for Comparison:
	local N1: number, D1: number, D2: number = 0, 360, 1020
	--===========================================================================================>
	-- Compare the numbers and return the apropriate string:
	return if (Min >= N1 and Min < D1) then 'Night' elseif (Min >= D1 and Min < D2) then 'Day' elseif (Min >= D2) then 'Night' else 'None'
	--===========================================================================================>
end

-- Method that will return a random Child Instance from the Children of the passed Instance: 
@native
function Get.RandomChildFromInstance(SentInstance: Instance): any
	--===========================================================================================>
	-- Get the Children of the Sent Instance:
	local InstanceChildren: {Instance} = SentInstance:GetChildren()
	-- Return a Instance from the Children Array, indexed randomly:
	return InstanceChildren[Get._Utility.Table.RandomIndex(InstanceChildren)]
	--===========================================================================================>
end

--===========================================================================================================================>

-- Method that will return a MetaIndex Function which will Index Functions and such from Child Modules:
function Get.MetaIndexFunction<Module>(Module: Dictionary, ModuleScript: ModuleScript, FrameworkData: {any}): <self, Index>(self: Module, Index: string) -> self
	--=======================================================================================================>
	-- Get the MetaModule Array of Required, Filtered Child Modules:
	local MetaModuleArray: Array = Get.MetaModuleArray(ModuleScript, FrameworkData)

	-- Return a Function that will Index each Child Module's Methods and the ParentModules Methods:
	return function(Self, Index)
		---======================================================================================>
		-- If Index is in the immediate Module tree, return that value:			
		if Module[Index] then return Module[Index] end
		-- Loop through the MetaTableList and return the Function if its being Indexed
		for _, Module in ipairs(MetaModuleArray) do if Module[Index] then return Module[Index] else continue end end
		-- Return False if all else fails!
		return false
		---======================================================================================>
	end
	--=======================================================================================================>
end

-- Method that will get a MetaModule Array which is the Child Modules into a nicely formated Array:
function Get.MetaModuleArray(ModuleScript: ModuleScript, FrameworkData: {any}): Array
	--=======================================================================================================>
	-- Check if ModuleScript has a Children's Folder:
	local ChildFolder: Folder = (ModuleScript:FindFirstChild('Child') or ModuleScript:FindFirstChild('Children')) :: Folder

	-- Get the Filtered ModulesArray and its Length:
	local ModulesArray: Array, ModulesArrayLength: number = Get.LocalModulesArray(ChildFolder or ModuleScript)

	--=======================================================================================================>

	-- Return the ModulesArray once its been Setup with the Framework Data:
	return Get._Utility:SetLocalModulesArray(ModulesArray, ModulesArrayLength, FrameworkData)

	--=======================================================================================================>
end

-- Get all the local Modules of a ModuleScript and return the Array of ModuleScript's and it's array length:
function Get.LocalModulesArray(ChildrenFolder: (Folder | ModuleScript) ): (Array, number)
	--=======================================================================================================>

	-- Check if the Classes Folder is seperated via RunScopes:
	local RunScopesAttribute: string? = ChildrenFolder:GetAttribute('RunScopes') :: string?
	-- Get all the Descendants of the Classes Folder:
	local ChildrenModulesArray: {Instance} = ChildrenFolder:GetDescendants()
	-- Reference the current RunScope String:
	local RunScope: string = Get._Utility._RunScope

	--=======================================================================================================>

	-- Filter the CombinedDescendants array and return a new Array of just ModuleScripts:
	local ModulesArray: {ModuleScript} = Get._Utility.Table.Filter(ChildrenModulesArray, function(Value: Instance, Index: number)
		---======================================================================================>
		-- Check to get the Classes Ancestor Folder of this ModuleScript:
		local ChildrenAncestor: any? = if ChildrenFolder:IsA('Folder') then Value:FindFirstAncestor('Children') else Value.Parent
		---======================================================================================>
		-- Check if the Value is a ModuleScript and if it has a Value: 'ChildModule'
		local IsChildModule: boolean = Value:IsA("ModuleScript") and Value:GetAttribute('ChildModule') :: boolean
		-- If its not a ChildModule, Return false:
		if not IsChildModule then return false end
		---======================================================================================>
		-- Check if the ChildrenAncestor Folder is the Top Level Classes Folder:
		local IsParentChild: boolean? = (ChildrenAncestor and ChildrenAncestor == ChildrenFolder)
		-- If its not of the Parent Children Folder, Return false:
		if not IsParentChild then return false end
		---======================================================================================>
		-- If the Classes are seperated by RunScope and a ModuleParent exists:
		if RunScopesAttribute and Value.Parent then
			-- Check if the Class Module is under the Proper RunScope Organizer:
			local IsRunScope: boolean = if Value.Parent.Name == RunScope or Value.Parent.Name == 'Shared' then true else false 
			-- If the Class is not in the proper RunScope, dont load it:
			if not IsRunScope then return false end
		end
		---======================================================================================>
		-- Return true, the Module is a proper class!!!
		return true
		---======================================================================================>
	end)

	--=======================================================================================================>

	-- Set Children Var to nil:
	ChildrenModulesArray = nil :: any

	--=======================================================================================================>

	-- Return Modules Array and its Length:
	return ModulesArray, #ModulesArray

	--=======================================================================================================>
end

-- Get/Return and Generate a unique GUID
function Get.Identifier(Brackets: boolean, Dashes: boolean?, Shortened: boolean?, Characters: number?): string
	--=======================================================================================================>
	
	-- Generate the Id and if Shortened, Shave off some characters:
	local Identifier: string = HttpService:GenerateGUID(Brackets)
	
	-- If Shortened is true, Shave off some characters:
	if Shortened == true then Identifier = string.sub(Identifier, 1, Characters or 7) end

	-- If Dashes is false, remove/replace the dash characters with nothing in the string:
	if Dashes == false then Identifier = Identifier:gsub('-', '') end
	
	-- Return the Id String:
	return Identifier
	--=======================================================================================================>
end

-- Get/Return a Region3 from these properties:
@native
function Get.Region3FromRegion3(Size: Vector3, CFrame1: CFrame): Region3
	--=======================================================================================================>
	-- Calculate the half size for convenience
	local HalfSize = Size * 0.5
	-- Create the new Region3
	return Region3.new(CFrame1.Position - HalfSize, CFrame1.Position + HalfSize)
	--=======================================================================================================>
end

--===========================================================================================================================>

-- Return the Module table
return Get :: GetModule

--===========================================================================================================================>