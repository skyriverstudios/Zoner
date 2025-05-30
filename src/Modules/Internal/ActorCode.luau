--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Set a Memory Category for this:
debug.setmemorycategory('[Zoner]: ActorCode')

-- Require the ZoneEngine Module:
local ZoneEngine = require(`./Zone/Engine`)

--===========================================================================================================================>

-- Create a Function to call when the Actor is being destroyed or cleaned:
local function ClearActor(Zones: {[string]: any}, Actor: Actor, Connections: {[string]: RBXScriptConnection})
	--==================================================>
	-- Disconnect Events:
	for Key, Connection in pairs(Connections) do
		Connections[Key]:Disconnect()
	end
	-- Clear table:
	table.clear(Connections)
	-- Loop through all of the Zones in the Zones Array to call their Actor Destroy Messages:
	for Id: string, Zone: any in Zones do if Zone.Destroy then Zone:Destroy() end end
	-- Clear the Zones Array:
	table.clear(Zones); Zones = nil :: any
	-- Destroy the Actor:
	if Actor.Parent ~= nil then Actor:Destroy() end
	--==================================================>
end

--===========================================================================================================================>

-- Call:
return function(Actor: Actor)
	--===========================================================================================================>

	-- Create an Array of all Zones controlled by this script:
	local Zones:       {[string]: ZoneEngine.Engine} = {}
	-- Connections table:
	local Connections: {[string]: RBXScriptConnection}   = {}

	--===========================================================================================================================>

	-- Connect to the AncestryChanged event of the Script:
	-- We then check if the Script is still a decendent of the WorldModel, meaning it hasnt been destroyed.
	-- We do this to clear the Data in case the Script is Destroyed:
	Connections.AncestryChanged = Actor.AncestryChanged:Connect(function()
		if Actor.Parent == nil or Actor:IsDescendantOf(game) == false then ClearActor(Zones, Actor, Connections) end
	end)

	-- DYNAMICALLY Bind a DESTROY message so that the individual zone underneath this Actor can be communicated with:
	-- Bind a Message to the Actor so that this script can be communicated with via the Actor SendMessage:
	Connections.ConstructEvent = Actor:BindToMessage('Construct', function(Id: string, Folder: any, Container: any)
		Zones[Id] = ZoneEngine.New(Id, Folder, Container) -- Construct the Object using the Required Module Class:
	end)

	-- Bind a Message to the Actor so that this script can be communicated with via the Actor SendMessage:
	Connections.DestroyEvent = Actor:BindToMessage('Destroy', function(Id: string)
		if Zones[Id] then if Zones[Id].Destroy then Zones[Id]:Destroy(); end; Zones[Id] = nil; end
	end)

	-- Bind a Message to the Actor so that this script can be communicated with via the Actor SendMessage:
	Connections.RemoveEvent = Actor:BindToMessage('Remove', function()
		ClearActor(Zones, Actor, Connections)
	end)

	--===========================================================================================================================>

	-- Set a Binded Boolean attribute on the Actor to denote that this Actor's Message has been Binded:
	Actor:SetAttribute('Binded', true)

	-- ADD A ATTRIBUTE CHANGE LISTEN
	if Actor.Parent == nil or Actor:IsDescendantOf(game) == false then ClearActor(Zones, Actor, Connections) end

	--===========================================================================================================>
end

--===========================================================================================================================>