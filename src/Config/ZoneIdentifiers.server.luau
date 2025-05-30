--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Wait for the Events folder:
local Events_Folder = script.Parent.Parent:WaitForChild('Events')

-- Cache reference both the ZoneId Add and ZoneId Remove RemoteEvents:
local ZoneId_Add    = Events_Folder:WaitForChild('ZoneId_Add')
local ZoneId_Remove = Events_Folder:WaitForChild('ZoneId_Remove')

--===========================================================================================================================>

-- If Streaming is not enabled in this place, then we dont need any server involvement with Ids:
if workspace.StreamingEnabled == false then
	ZoneId_Add:Destroy(); ZoneId_Remove:Destroy(); script:Destroy(); return;
end

--===========================================================================================================================>

-- Connect on the Server to the event to update the tags of the sent instances:
ZoneId_Add.OnServerEvent:Connect(function(Player: Player, Id: string, Parts: {BasePart}, Holders: {Instance}) 
	--======================================================================================================>
	
	-- Runtime type checking:
	if typeof(Id) ~= 'string'     then warn('ZoneId_Add: Id was not a string') return end
	if typeof(Parts) ~= 'table'   then warn('ZoneId_Add: Parts was not a table') return end
	if typeof(Holders) ~= 'table' then warn('ZoneId_Add: Parts was not a table') return end

	-- Dynamically create the Client based Tags:
	local ZonePart_Tag = `{Id}:ZonePart:Client`;
	local Holder_Tag   = `{Id}:Holder:Client`;

	-- Loop through the ZoneParts to add tags:
	for Index: number, Holder: Instance in ipairs(Holders) do
		-- If the Part already has a Tag, then continue:
		-- Add the Holder tag to the Holder:
		if Holder:HasTag(Holder_Tag) then continue else Holder:AddTag(Holder_Tag)end
	end

	for Index: number, Part: BasePart in ipairs(Parts) do
		-- If the Part already has a Tag, then continue:
		-- Add the ZonePart tag to the ZonePart:
		if Part:HasTag(ZonePart_Tag) then continue else Part:AddTag(ZonePart_Tag) end
	end
	--======================================================================================================>
end)

-- Connect on the Server to the event to update the tags of the sent instances:
ZoneId_Remove.OnServerEvent:Connect(function(Player: Player, Id: string, Parts: {BasePart}, Holders: {Instance}) 
	--======================================================================================================>
	
	-- Runtime type checking:
	if typeof(Id) ~= 'string'     then warn('ZoneId_Add: Id was not a string') return end
	if typeof(Parts) ~= 'table'   then warn('ZoneId_Add: Parts was not a table') return end
	if typeof(Holders) ~= 'table' then warn('ZoneId_Add: Parts was not a table') return end

	-- Dynamically create the Client based Tags:
	local ZonePart_Tag = `{Id}:ZonePart:Client`;
	local Holder_Tag   = `{Id}:Holder:Client`;

	-- Loop through the ZoneParts to add tags:
	for Index: number, Holder: Instance in ipairs(Holders) do
		-- If the Part already has a Tag, then continue:
		-- Add the Holder tag to the Holder:
		if Holder:HasTag(Holder_Tag) then continue else Holder:RemoveTag(Holder_Tag)end
	end

	for Index: number, Part: BasePart in ipairs(Parts) do
		-- If the Part already has a Tag, then continue:
		-- Add the ZonePart tag to the ZonePart:
		if Part:HasTag(ZonePart_Tag) then continue else Part:RemoveTag(ZonePart_Tag) end
	end
	--======================================================================================================>
end)

--===========================================================================================================================>