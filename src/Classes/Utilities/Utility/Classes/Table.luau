--===========================================================================================================================>
--!native
--!strict
--===========================================================================================================================>

-- Define Module table
local Table: TableModule = {} :: TableModule

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- This will inject all types into this context.
local TypeDefinitions: {} = require(script:FindFirstAncestor('Utility').TypeDefinitions)

-- Insert the Object Types:
type TableModule = TypeDefinitions.TableModule

-- Insert the Extra Types:
type Dictionary  = TypeDefinitions.Dictionary
type Debounces   = TypeDefinitions.Debounces
type Cycler      = TypeDefinitions.Cycler
type Table       = TypeDefinitions.Table
type Array       = TypeDefinitions.Array

--===========================================================================================================================>


-- Method that will take any Instance and get all of its Children recurisvely if needed, and create them all into a dictionary:
function Table.CreateDictionary<SentInstance>(SentInstance: any, Recursive: boolean?): (Dictionary | SentInstance)
	--=======================================================================================================>

	-- Create a new Dictionary:
	local Dictionary: Dictionary = {}

	-- Check if the Instance can have its Children Got:
	local CanGetChildren: boolean = 
		-- Check if it is a Children getting Type:
		SentInstance:IsA("Folder") or 
		SentInstance:IsA("Configuration") or 		
		SentInstance:IsA("ScreenGui") or 
		SentInstance:IsA("ImageLabel") or 
		-- Check if it has an Attribute labeled: "DictionaryStart" or "GetChildren"
		SentInstance:GetAttribute('DictionaryStart') == true or 
		SentInstance:GetAttribute('GetChildren') == true

	--=======================================================================================================>

	-- If Instance is able have its children grabbed:
	if CanGetChildren then
		--==================================================================================>
		-- If Parent has Attribute of NoDictionary, Dont go further into recurrsiveness.
		if SentInstance:GetAttribute("NoDictionary") then return SentInstance end
		-- Get Children of the Instance
		local FolderChildren: {Instance} = SentInstance:GetChildren()
		-- If Folder has nothing in it, return just the Folder
		if #FolderChildren == 0 then return SentInstance end			
		--==================================================================================>
		-- Loop through the FolderChildren, adding each Instance to the new table, or reccursivly
		-- calling the function again, if the Child is a Folder, and returning that table to the new table:
		for Index: number, Child: any in ipairs(FolderChildren) do
			--=====================================================================>
			-- Check if the Instance can have its Children Got:
			local CanGetChildrenOfChild: boolean = 
				-- Check if it is a Children getting Type:
				Child:IsA("Folder") or 
				Child:IsA("Configuration") or 		
				Child:IsA("ScreenGui") or 
				Child:IsA("ImageLabel") or 
				-- Check if it has an Attribute labeled: "DictionaryStart" or "GetChildren"
				Child:GetAttribute('DictionaryStart') == true or 
				Child:GetAttribute('GetChildren') == true
			--=====================================================================>
			-- If ChildIsFolder is true, reccursivly call the function again to build a new sub table:
			-- Set the reccursivly built sub table to the top level table:
			-- Set the Child Instance to the top level table:
			Dictionary[Child.Name] = if CanGetChildrenOfChild and Recursive then Table.CreateDictionary(Child, Recursive) else Child
			--=====================================================================>
		end
		--==================================================================================>
		-- Clear the Array Variable:
		FolderChildren = nil :: any
		--==================================================================================>
	end

	--====================================================================>

	-- Return Table
	return Dictionary

	--====================================================================>

end

function Table.Type(Table1: Table): ('Array' | 'Dictionary' | 'Empty')
	return if Table.IsEmpty(Table1) then 'Empty' elseif Table.IsDictionary(Table1) then 'Dictionary' else 'Array'
end

function Table.Length(Table1: Dictionary): number
	--===========================================================================================>
	-- Create a counter variable:
	local Counter: number = 0
	-- Loop through the table adding incrementing the counter each value:
	for Index, Item in (Table1) do Counter += 1 end
	-- Return the counter:
	return Counter
	--===========================================================================================>
end

function Table.RandomIndexFromLength(TableLength: number): number
	return Table._Utility._RandomPrefix:NextInteger(1, TableLength)
end

function Table.RandomIndex(Table1: Table): any
	--===========================================================================================>

	-- Get the type of table:
	local Type = Table.Type(Table1)

	--===========================================================================================>

	-- Check on the Table type:
	if Type == "Array" then
		--==================================================>
		-- Return the Random Index from Length:
		return Table.RandomIndexFromLength(#Table1)
		--==================================================>
	elseif Type == "Dictionary" then
		--==================================================>
		-- Create a new Array with the Keys from the Dictionary:
		local KeysArray: Array = Table.Keys(Table1)
		-- Get the length of the Array, and use it to get a random Index from the Array. 
		-- Then Index the Array with that Index to return the Random Key from the Dictionary:
		return KeysArray[Table.RandomIndexFromLength(#KeysArray)]
		--==================================================>
	else
		return 1
	end

	--====================================================================>

end

-- Method that will Freeze all Nested tables of the passed Table:
function Table.Freeze(Table1: Table): Table
	--===========================================================================================>
	-- Loop through the Table to Freeze any Nested Tables:
	for Key: string, Child in pairs(Table1) do 
		-- If Child is not a Table, continue:
		if typeof(Child) ~= 'table' then continue end
		-- Recurssive Call on the Child Table:
		Table.Freeze(Child) 
		-- Freeze the Table:
		if not table.isfrozen(Child) then table.freeze(Child) end
	end

	-- Freeze the Table:
	if not table.isfrozen(Table1) then table.freeze(Table1) end

	-- Return the newly frozen table:
	return Table1

	--===========================================================================================>
end

function Table.ShallowCopy(Table1: Table): Table
	return table.clone(Table1)
end

function Table.TupleToTable(...: any): Array
	return table.pack(...)
end


function Table.Move(Original: Table, MovingIntoOriginal: Table)
	--===========================================================================================>

	-- Get the type of table:
	local Type = Table.Type(MovingIntoOriginal)

	--===========================================================================================>

	-- Check on the Table type:
	if Type == "Dictionary" then

		for Index, Value in MovingIntoOriginal do

			if type(Value) == "table" then

				if not Original[Index] then Original[Index] = Value end

				for TableValueName, TableValue in Value do Original[Index][TableValueName] = TableValue end

			else

				Original[Index] = Value

			end


		end

	elseif Type == "Array" then			

		for Index: number, Value: any in ipairs(MovingIntoOriginal) do Original[Index] = Value end

	end

	--====================================================================>

end


--[=[
	This function "deep" copies a table, and all of its contents. This means that it will clone the entire table,
	and tables within that table- as opposed to shallow-copying with table.clone
	
	```lua
	local Dictionary = {
		SomethingInside = {
			A = 1,
			B = 2,
		},
	}
	
	local CopiedDictionary = TableKit.DeepCopy(Dictionary)
	
	print(CopiedDictionary) -- prints { ["SomethingInside"] = { ["A"] = 1, ["B"] = 1 } }
	```
	
	:::caution Recursive Function
	This function is recursive- this can cause stack overflows.

	@within TableKit
	@param tableToClone table
	@return table
]=]
function Table.DeepCopy(Table1: Table): Table
	--===========================================================================================>
	-- Clone the passed Table:
	local Clone: Table = table.clone(Table1)
	-- Loop over the Clone, and Clone any nested tables:
	for Index, Value in Clone do
		if typeof(Value) == "table" then Clone[Index] = Table.DeepCopy(Value) end
	end
	-- Return the Cloned Table:
	return Clone
	--===========================================================================================>
end

--[=[
	This function merges two dictionaries.

	Keys *will* overwrite- if there are duplicate keys, dictionary2 will take priority.

	```lua
	local Dictionary = {
		A = 1,
		B = 2,
	}
	local SecondDictionary = {
		C = 3,
		D = 4,
	}
	
	print(TableKit.MergeDictionary(Dictionary, SecondDictionary)) -- prints { ["A"] = 1, ["B"] = 2, ["C"] = 3, ["D"] = 4 }
	```
	
	:::caution Potential overwrite
	Keys are overwritten when using .MergeDictionary()
	
	@within TableKit
	@param dictionary1 table
	@param dictionary2 table
	@return table
]=]
function Table.MergeDictionary(Dictionary1: Dictionary, Dictionary2: Dictionary): Dictionary
	--===========================================================================================>
	-- Clone the passed Dictionary:
	local NewDictionary: Dictionary = table.clone(Dictionary1)
	-- Loop through the Second Dictionary, adding every Key and Value into the first Dictionary:
	for Key, Value in Dictionary2 do NewDictionary[Key] = Value end
	-- Return the Merged Dictionary:
	return NewDictionary
	--===========================================================================================>
end

--[=[
	This function returns a table with the keys of the passed dictionary.
	
	```lua
	local Dictionary = {
		A = 1,
		B = 2,
		C = 3,
	}
	
	print(TableKit.Keys(Dictionary)) -- prints {"A", "B", "C"}
	```

	@within TableKit
	@param dictionary table
	@return table
]=]
function Table.Keys(Dictionary: Dictionary): Array
	--===========================================================================================>
	-- Create a new Array:
	local KeyArray: Array = {}
	-- Loop through the Dictionary, adding every Key to the Array:
	for Key in Dictionary do table.insert(KeyArray, Key) end
	--  Return the Array:
	return KeyArray
	--===========================================================================================>
end

--[=[
	This function returns a table with the values of the passed dictionary.
	
	```lua
	local Dictionary = {
		A = 1,
		B = 2,
		C = 3,
	}
	
	print(TableKit.Values(Dictionary)) -- prints {1, 2, 3}
	```

	@within TableKit
	@param dictionary table
	@return table
]=]
function Table.Values(Dictionary: Dictionary): Array
	--===========================================================================================>
	-- Create a new Array:
	local ValueArray: Array = {}
	-- Loop through the Dictionary, adding every Value to the Array:
	for Key, Value in Dictionary do table.insert(ValueArray, Value) end
	--  Return the Array:
	return ValueArray
	--===========================================================================================>
end


-- Method which when called will take an Array and return a new Dictionary using the Values of the Array:
function Table.ArrayToDictionary(Array: Array): Dictionary
	--=======================================================================================================>
	-- Initialize a new Dictionary:
	local NewDictionary: Dictionary = {}

	-- Loop through the Array, adding each Value to the Dictionary:
	for Index: number, Value: any in ipairs(Array) do NewDictionary[Value.Name] = Value	end

	-- Return the newly created Dictionary:
	return NewDictionary
	--=======================================================================================================>
end

--[=[
	Merges two arrays; array2 will be added to array1- this means that the indexes of array1 will be the same.
	
	```lua
	local FirstArray = {"A", "B", "C", "D"}
	local SecondArray = {"E", "F", "G", "H"}
	
	print(TableKit.MergeArrays(FirstArray, SecondArray)) -- prints {"A", "B", "C", D", "E", "F", "G", "H"}
	```

	@within TableKit
	@param array1 table
	@param array2 table
	@return table
]=]
function Table.MergeArrays(Array1: Array, Array2: Array): Array
	--===========================================================================================>
	-- Clone the first Array:
	local ClonedArray: Array = table.clone(Array1)
	-- Move the Second Array into the Cloned Array:
	table.move(Array2, 1, #Array2, #ClonedArray + 1, ClonedArray)
	-- Return the ClonedArray now with the Second Array:
	return ClonedArray
	--===========================================================================================>
end

--[=[
	Deep-reconciles a dictionary into another dictionary.
	
	```lua
	local template = {
		A = 0,
		B = 0,
		C = {
			D = "",
		},
	}

	local toReconcile = {
		A = 9,
		B = 8,
		C = {},
	}
	
	print(TableKit.Reconcile(toReconcile, template)) -- prints { A = 9, B = 8, C = { D = "" }
	```

	@within TableKit
	@param original table
	@param reconcile table
	@return table
]=]
function Table.Reconcile(Original: Dictionary, Reconcile: Dictionary)
	--===========================================================================================>
	local tbl = table.clone(Original)

	for key, value in Reconcile do
		if tbl[key] == nil then
			if typeof(value) == "table" then
				tbl[key] = Table.DeepCopy(value)
			else
				tbl[key] = value
			end
		elseif typeof(Reconcile[key]) == "table" then
			if typeof(value) == "table" then
				tbl[key] = Table.Reconcile(value, Reconcile[key])
			else
				tbl[key] = Table.DeepCopy(Reconcile[key])
			end
		end
	end

	return tbl
	--===========================================================================================>
end

--[=[
	Detects if a table is an array, meaning purely number indexes and indexes starting at 1.
	
	```lua
	local Array = {"A", "B", "C", "D"}
	local Dictionary = { NotAnArray = true }
	
	print(TableKit.IsArray(Array), TableKit.IsArray(Dictionary)) -- prints true, false
	```

	@within TableKit
	@param mysteryTable table
	@return boolean
]=]
function Table.IsArray(Table: Table): boolean
	--===========================================================================================>
	-- Create a Count Variable:
	local Count = 0
	-- Loop through the Table:
	for Index, Value in Table do
		Count += 1
		if type(Index) ~= "number" or Index % 1 ~= 0 or Index > Count then return false end
	end
	-- Return true, means its an array:
	return true
	--===========================================================================================>
end

--[=[
	Detects if a table is a dictionary, meaning it is not purely number indexes.
	
	```lua
	local Array = {"A", "B", "C", "D"}
	local Dictionary = { NotAnArray = true }
	
	print(TableKit.IsDictionary(Array), TableKit.IsDictionary(Dictionary)) -- prints false, true
	```

	@within TableKit
	@param mysteryTable table
	@return boolean
]=]
function Table.IsDictionary(Table: Table): boolean
	--===========================================================================================>
	-- Create a Count Variable:
	local Count = 0
	-- Loop through the Table:
	for Index, Value in Table do
		Count += 1
		if type(Index) ~= "number" or Index % 1 ~= 0 or Index > Count then return true end
	end
	-- Return false, means its an array:
	return false
	--===========================================================================================>
end

--[=[
	Detects if a table is empty.
	
	```lua
	local Empty = {}
	local NotEmpty = { "Stuff" }
	
	print(TableKit.IsEmpty(Empty), TableKit.IsEmpty(NotEmpty)) -- prints true, false
	```

	@within TableKit
	@param mysteryTable table
	@return boolean
]=]
function Table.IsEmpty(Table: Table): boolean
	return next(Table) == nil
end

--[=[
	Converts a table into a string.
	
	```lua
	local DictionaryA = {
		A = "Z",
		B = "X",
		C = "Y",
	}
	
	print(TableKit.ToString(DictionaryA)) -- prints {
							--			[A]: Z
							--			[C]: Y
							--			[B]: X
							--		 }
	```

	@within TableKit
	@param obj {}
	@return string
]=]
function Table.ToString(Table: Dictionary): string
	--=======================================================================================================>
	local result = {}
	--=======================================================================================================>
	for key, value in Table do
		local stringifiedKey
		if typeof(key) == "string" then
			stringifiedKey = `"{tostring(key)}"`
		else
			stringifiedKey = tostring(key)
		end

		local stringifiedValue
		local valueToString = tostring(value)
		if typeof(key) == "string" then
			stringifiedValue = `"{valueToString}"`
		else
			stringifiedValue = valueToString
		end

		local newline = `[{stringifiedKey}] = {stringifiedValue}`
		table.insert(result, newline)
	end
	--=======================================================================================================>
	return "{\n" .. table.concat(result, "\n") .. "\n}"
	--=======================================================================================================>
end

--[=[
	Takes in a data type, and returns it in array form.
	
	```lua
	local str = "Test"
	
	print(TableKit.From(str)) -- prints ("T", "e", "s", t")
	```

	@within TableKit
	@param value unknown
	@return { [number]: unknown }
]=]
function Table.From(Value: any): Array
	--===========================================================================================>
	local ValueType = typeof(Value)
	if ValueType == "string" then
		return string.split(Value, "")
	elseif ValueType == "Color3" then
		return { Value.R, Value.G, Value.B }
	elseif ValueType == "Vector2" then
		return { Value.X, Value.Y }
	elseif ValueType == "Vector3" then
		return { Value.X, Value.Y, Value.Z }
	elseif ValueType == "NumberSequence" then
		return Value.Keypoints
	elseif ValueType == "Vector3int16" then
		return { Value.X, Value.Y, Value.Z }
	elseif ValueType == "Vector2int16" then
		return { Value.X, Value.Y }
	else
		return { Value }
	end
	--===========================================================================================>
end

--[=[
	Creates a shallow copy of an array, passed through a filter callback- if the callback returns false, the element is removed.
	
	```lua
	local str = {"a", "b", "c", "d", "e", "f", "g"}
	
	print(TableKit.Filter(str, function(value)
		return value > "c"
	end))
	-- prints {
 		[1] = "d",
 		[2] = "e",
 		[3] = "f",
 		[4] = "g"
 	}
	```

	@within TableKit
	@param arr { [number]: unknown }
	@param callback (value: value) -> boolean
	@return { [number]: unknown }
]=]
function Table.Filter(Array: Array, Callback: (Value: any, Index: number) -> boolean): Array
	--=======================================================================================================>
	-- Construct a new blank Array:
	local NewArray: Array = {}
	-- Loop through the Array and call the Callback and Insert any Values that return the Callback:
	for Index: number, Value: any in ipairs(Array) do
		if Callback(Value, Index) then table.insert(NewArray, Value) end
	end
	-- Return the new Array:"
	return NewArray
	--=======================================================================================================>
end

--[=[
	Loops through every single element, and puts it through a callback. If the callback returns true, the function returns true.
	
	```lua
	local array = {1, 2, 3, 4, 5}
	local even = function(value) return value % 2 == 0 end

	print(TableKit.Some(array, even)) -- Prints true
	```
	
	@within TableKit
	@param tbl table
	@param callback (value) -> boolean
	@return boolean
]=]
function Table.Some(Table: Table, Callback: (Value: any) -> boolean): boolean
	for _, Value in Table do if Callback(Value) == true then return true end end return false
end

--[=[
	Detects if a table has an embedded table as one of its members.
	
	```lua
	local Shallow = {"a", "b"}
	local Deep = {"a", {"b"}}
	
	print(TableKit.IsFlat(Shallow)) -- prints true
	print(TableKit.IsFlat(Deep)) -- prints false
	```
	
	@within TableKit
	@param tbl table
	@return boolean
]=]
function Table.IsFlat(Table: Table): boolean
	for _, V in Table do if typeof(V) == "table" then return false end end return true
end

--[=[
	Loops through every single element, and puts it through a callback. If any of the conditions return false, the function returns false.
	
	```lua
	local array = {1, 2, 3, 4, 5}
	local even = function(value) return value % 2 == 0 end
	local odd = function(value) return value % 2 ~= 0 end
	
	print(TableKit.Every(array, even)) -- Prints false
	print(TableKit.Every(array, odd)) -- Prints false
	```
	
	@within TableKit
	@param tbl table
	@param callback (value) -> boolean
	@return boolean
]=]
function Table.Every(Table: Table, Callback: (any) -> boolean): (boolean, any?)
	for Key, Value in Table do if not Callback(Value) then return false, Key end end return true
end

--[=[
	Detects if a dictionary has a certain key.
	
	```lua
	local Dictionary = {
		Hay = "A",
		MoreHay = "B",
		Needle = "C",
		SomeHay = "D",
	}
	
	print(TableKit.HasKey(Dictionary, "Needle")) -- prints true
	```
	
	@within TableKit
	@param dictionary table
	@param key unknown
	@return boolean
]=]
function Table.HasKey(Dictionary: Dictionary, Key: any): boolean
	return Dictionary[Key] ~= nil
end

--[=[
	Detects if a dictionary has a certain value.
	
	```lua
	local Array = { "Has", "this", "thing" }
	
	print(TableKit.HasValue(Array, "Has")) -- prints true
	```
	
	@within TableKit
	@param tbl table
	@param value unknown
	@return boolean
]=]
function Table.HasValue(Table: Table, Value: any): boolean
	for _, V in Table do if V == Value then return true end end return false
end

--===========================================================================================================================>

-- Return the Module table
return Table :: TableModule

--===========================================================================================================================>