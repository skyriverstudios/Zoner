--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Cache the Actor Instance
local Actor = script.Parent.Parent

--===========================================================================================================================>

-- Create an Array of all Zones controlled by this script:
local Zones: {[string]: any} = {}

-- Initialize Signal Connection Variables:
local AncestryChanged: RBXScriptConnection
local ConstructEvent:  RBXScriptConnection
local DestroyEvent:    RBXScriptConnection
local RemoveEvent:     RBXScriptConnection

-- Create a Function to call when the Actor is being destroyed or cleaned:
local function ClearActor()
	--==================================================>
	-- Disconnect Events:
	if AncestryChanged then AncestryChanged:Disconnect(); AncestryChanged = nil :: any end
	if ConstructEvent then ConstructEvent:Disconnect(); ConstructEvent = nil :: any end
	if DestroyEvent then DestroyEvent:Disconnect(); DestroyEvent = nil :: any end
	if RemoveEvent then RemoveEvent:Disconnect(); RemoveEvent = nil :: any end
	-- Loop through all of the Zones in the Zones Array to call their Actor Destroy Messages:
	for Id: string, Zone: any in Zones do if Zone.Destroy then Zone:Destroy() end end
	-- Clear the Zones Array:
	table.clear(Zones); Zones = nil :: any
	-- Destroy the Actor:
	if Actor.Parent ~= nil then Actor:Destroy() end
	--==================================================>
end

--===========================================================================================================================>

-- Connect to the AncestryChanged event of the Script:
-- We then check if the Script is still a decendent of the WorldModel, meaning it hasnt been destroyed.
-- We do this to clear the Data in case the Script is Destroyed:
AncestryChanged = Actor.AncestryChanged:Connect(function()
	--====================================================================================>
	if Actor.Parent == nil or Actor:IsDescendantOf(game) == false then ClearActor() end
	--====================================================================================>
end)

-- DYNAMICALLY Bind a DESTROY message so that the individual zone underneath this Actor can be communicated with:
-- Bind a Message to the Actor so that this script can be communicated with via the Actor SendMessage:
ConstructEvent = Actor:BindToMessage('Construct', function(ZoneEngineModule: ModuleScript, Id: string, Folder: Folder, Container: any, RunScope: 'Server'|'Client')
	--==============================================================================================================>
	-- COULD CHANGE THIS TO BE CALLED AT TOP OF SCRIPT
	-- Require the UpdateModule Class:
	local ZoneEngine = require(ZoneEngineModule) :: any

	-- Construct the Object using the Required Module Class:
	Zones[Id] = ZoneEngine.New(Id, Folder, Container, RunScope)
	
	--==============================================================================================================>
end)

-- Bind a Message to the Actor so that this script can be communicated with via the Actor SendMessage:
DestroyEvent = Actor:BindToMessage('Destroy', function(Id: string)
	--==================================================>
	-- If there is a Object, Destroy it:
	if Zones[Id] then if Zones[Id].Destroy then Zones[Id]:Destroy(); end; Zones[Id] = nil; end
	--==================================================>
end)

-- Bind a Message to the Actor so that this script can be communicated with via the Actor SendMessage:
RemoveEvent = Actor:BindToMessage('Remove', ClearActor)

-- Set a Binded Boolean attribute on the Actor to denote that this Actor's Message has been Binded:
Actor:SetAttribute('Binded', true)

--===========================================================================================================================>

-- ADD A ATTRIBUTE CHANGE LISTEN
if Actor.Parent == nil or Actor:IsDescendantOf(game) == false then ClearActor() end

--===========================================================================================================================>