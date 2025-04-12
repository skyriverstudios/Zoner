--===========================================================================================================================>
--!optimize 2
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zoner]: Plagger')

-- Define Module table
local PlaggerModule = {
	--=========================================================================>
	-- Grab the RunService RunScope that this Code is running on:
	_RunScope = (if game:GetService('RunService'):IsServer() then 'Server' else 'Client' ):: 'Client' | 'Server';
	-- Grab the boolean attribute whether the Module has been Ran Once to connect to the Players Events:
	_CoreRunning = {
		-- Grab the boolean attribute whether the Module has been Ran Once to connect to the Players Events:
		Server = (script:GetAttribute('Server_CoreRunning') or false) :: boolean;
		-- Grab the boolean attribute whether the Module has been Ran Once to connect to the Players Events:
		Client = (script:GetAttribute('Client_CoreRunning') or false) :: boolean;
	};
	--=========================================================================>
	-- Create an Empty Table to Store the Player Dictionaries:
	_Players = {} :: any;	
	--=========================================================================>
	-- Dictionary of Tags:
	_Tags = {
		Player          = 'PH:Player'                :: 'PH:Player';
		ClientCharacter = 'PH:Client:Character'      :: 'PH:Client:Character';
		ServerCharacter = 'PH:Server:Character'      :: 'PH:Server:Character';
		LocalCharacter  = 'PH:Client:LocalCharacter' :: 'PH:Client:LocalCharacter';
	};
	--=========================================================================>
}

--===========================================================================================================================>
--[ SERVICES: ]


-- Grab the CollectionService and Players Service:
local CollectionService, Players = game:GetService('CollectionService'), game:GetService('Players')

--===========================================================================================================================>
--[ DEFINE TYPES: ]


type PlayerObject = {
	Events: { CharacterAdded: RBXScriptConnection; CharacterRemoved: RBXScriptConnection }; 
	Destroy: (self: PlayerObject) -> ()
};

--- Create and Export the Module's Object Type:
export type Plagger = typeof(setmetatable({} :: {
	--======================================>
	_TaggedOnly: boolean?;
	_LocalOnly:  boolean?;
	_InActor:    boolean?;
	--===========================================>
	_LocalPlayerName: string?;
	--===========================================>
	_Events: {[string]: RBXScriptConnection};
	--===========================================>
	_CharacterList: {[string]: Model};
	_PlayerList:    {[string]: Player};
	--===========================================>
	-- Meta Index Variables:
	-- Some External references to internal variable:
	Characters: {[string]: Model};
	Players:    {[string]: Player};
	--======================================>
}, {} :: {__index: typeof(PlaggerModule)}))

--===========================================================================================================================>

-- Function which when called will setup a new Character Object on the Server
function PlaggerModule.New(TaggedOnly: boolean?, LocalOnly: boolean?, InActor: boolean?): Plagger
	--=======================================================================================================>

	-- Set Memory Category:
	debug.setmemorycategory('[Zoner] -> Zoner -> (Plagger)')

	--=======================================================================================================>
	
	-- Initialize Object values and tables:
	local PlaggerData= { 
		--===========================================>
		_TaggedOnly = TaggedOnly;
		_LocalOnly  = LocalOnly;
		_InActor    = InActor;
		--===========================================>
		-- Create an Empty Table to Store the Player Objects:
		_PlayerList = {};
		-- Create an Empty Table to Store the Character Objects:
		_CharacterList = {};
		-- Create an Empty Table to store the Event Connections:
		_Events = {};
		--===========================================>
	} :: any
	
	--=======================================================================================================>
	
	-- If we are running on the Server, and LocalOnly Paramater was set to true, fix it with false, since that paramater is for clients only:
	if PlaggerModule._RunScope == 'Server' and LocalOnly then PlaggerData._LocalOnly = false end

	-- Only Run ONE version of this Module as non Tagged. IE using the Player.Added Events:
	-- And Make all other subsequent calls to this Module use the CollectionService Tagging:
	if (TaggedOnly == false or TaggedOnly == nil) and PlaggerModule._CoreRunning[PlaggerModule._RunScope] ~= true then
		-- Set the RunScope_CoreRunning Attribute to true:
		script:SetAttribute(`{PlaggerModule._RunScope}_CoreRunning`, true)
		-- Update the Module Variable:
		PlaggerModule._CoreRunning[PlaggerModule._RunScope] = true
		-- Set the TaggedOnly to false:
		PlaggerData._TaggedOnly = false
	else
		-- Set the TaggedOnly boolean to true since the Players Events have already been connected to:
		PlaggerData._TaggedOnly = true
	end

	-- If we are Running on the Client and Creating this Object on the Client and LocalOnly boolean is true, Grab the LocalPlayer's Name:
	if PlaggerData._TaggedOnly == false and PlaggerModule._RunScope == 'Client' then
		-- Yield until a LocalPlayer Exists:
		if not Players.LocalPlayer then repeat task.wait() until Players.LocalPlayer end
		-- Set the LocalPlayer Name Variable:
		PlaggerData._LocalPlayerName = Players.LocalPlayer.Name
	end

	--=======================================================================================================>
	
	-- Set the Object metatable:
	setmetatable(PlaggerData, PlaggerModule)

	-- Initialize the Object:
	PlaggerData:_Initialize()

	-- Return the FROZEN Object:
	return table.freeze(PlaggerData) :: Plagger

	--=======================================================================================================>
end

-- Function which whell called will destroy all the local data for this Character Instance
function PlaggerModule.Destroy(self: Plagger)
	--=======================================================================================================>

	-- Loop through all the Events and Disconnect them:
	for Key: string, Connection in self._Events do
		self._Events[Key]:Disconnect()
		self._Events[Key] = nil :: any
	end

	-- If we are the Original CoreRunning Object, clear the Players Table and set Script CoreRunning Attribute back to false:
	if self._TaggedOnly == false then

		-- Loop through all the Player Objects and call their Destroy Method:
		for Player: Player, Data in self._Players do Data:Destroy() end
		-- Clear the Module Players Table:
		table.clear(PlaggerModule._Players) 

		-- Set the RunScope_CoreRunning Attribute to false:
		script:SetAttribute(`{PlaggerModule._RunScope}_CoreRunning`, false)
		-- Update the Module Variable:
		PlaggerModule[`{PlaggerModule._RunScope}_CoreRunning`] = false

	end

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Initialization function to start/setup the Object's initial data:
function PlaggerModule._Initialize(self: Plagger)
	for Index: number, Function: string in ipairs({'_SetObjects', '_SetEvents'}) do self[Function](self) end
end

-- Function to Set up initial Player Object Data:
function PlaggerModule._SetObjects(self: Plagger)
	--=======================================================================================================>

	-- Get all the Current Players in Game:
	-- If Tagged is true, then get the players from the Player Tag, else get the Players from the Players Service:
	local PlayersGot: {Player} = if self._TaggedOnly then
		CollectionService:GetTagged(self._Tags.Player) else Players:GetPlayers()
	
	-- Loop through all the Current In Game Players and Add them to the Data Object:
	for Index: number, Player: Player in ipairs(PlayersGot) do self:_AddPlayer(Player) end

	-- Clear from Memory
	PlayersGot = nil :: any

	--=======================================================================================================>

	-- If we are in a TaggedOnly Object, then Grab the Characters Via the Proper CollectionService Tag:
	if self._TaggedOnly then
		--===============================================================================>
		-- Get all the Current Characters in Game:
		-- Get the Character from the Character Tag:
		local CharactersGot: {Model} = 
			CollectionService:GetTagged(if self._LocalOnly == true then self._Tags.LocalCharacter else self._Tags.ServerCharacter)

		-- Loop through all the Current In Game Characters and Add them to the Data Object:
		for Index: number, Character: Model in ipairs(CharactersGot) do 			
			self:_AddCharacter(self._PlayerList[Character.Name], Character)
		end

		-- Clear from Memory
		CharactersGot = nil :: any
		--===============================================================================>
	end

	--=======================================================================================================>
end

-- Function to Set up Initial Events:
function PlaggerModule._SetEvents(self: Plagger)
	--=======================================================================================================>

	if self._TaggedOnly then 
		--==========================================================================================>
		
		-- Grab the Character Tag based on if we are looking for Local only or not:
		local CharacterTag = if self._LocalOnly == true then self._Tags.LocalCharacter else self._Tags.ServerCharacter
		-- If the InActor Variable is true, then Connect Each Event in Parallel to allow updates in Parallel:
		local ConnectMethod = if self._InActor then 'ConnectParallel' else 'Connect'

		-- Grab the PlayerAdded Signal:
		local PlayerAddedSignal   = CollectionService:GetInstanceAddedSignal(self._Tags.Player)
		-- Grab the PlayerRemoved Signal:
		local PlayerRemovedSignal = CollectionService:GetInstanceRemovedSignal(self._Tags.Player)

		-- Grab the CharacterAdded Signal:
		local CharacterAddedSignal   = CollectionService:GetInstanceAddedSignal(CharacterTag)
		-- Grab the CharacterRemoved Signal:
		local CharacterRemovedSignal = CollectionService:GetInstanceRemovedSignal(CharacterTag)

		--==========================================================================================>

		-- Connect to the Instance Added Event:
		self._Events['PlayerAdded'] = PlayerAddedSignal[ConnectMethod](PlayerAddedSignal, function(Player: Player) self:_AddPlayer(Player) end)
		-- Connect to the Instance Removed Event:
		self._Events['PlayerRemoved'] = PlayerAddedSignal[ConnectMethod](PlayerRemovedSignal, function(Player: Player) self:_RemovePlayer(Player) end)
	
		-- Connect to the Instance Added Event:
		self._Events['CharacterAdded'] = PlayerAddedSignal[ConnectMethod](CharacterAddedSignal, function(Character: Model)
			self:_AddCharacter(self._PlayerList[Character.Name], Character)
		end)

		-- Connect to the Instance Removed Event:
		self._Events['CharacterRemoved'] = PlayerAddedSignal[ConnectMethod](CharacterRemovedSignal, function(Character: Model)
			self:_RemoveCharacter(self._PlayerList[Character.Name], Character)
		end)

		--==========================================================================================>
	else
		--==========================================================================================>

		-- Connect to the PlayerAdded Event:
		self._Events['PlayerAdded'] = Players.PlayerAdded:Connect(function(Player: Player) self:_AddPlayer(Player) end)
		-- Connect to the PlayerRemoving Event:
		self._Events['PlayerRemoving'] = Players.PlayerRemoving:Connect(function(Player: Player) self:_RemovePlayer(Player) end)
		
		--==========================================================================================>
	end

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Method to Add a Player to the Data Object:
function PlaggerModule._AddPlayer(self: Plagger, Player: Player)
	--=======================================================================================================>

	-- If LocalOnly is true, and the LocalPlayerName is not nil, and the Player passed's name does not equal the LocalPlayer's Name, RETURN:
	if self._LocalOnly and self._LocalPlayerName and Player.Name ~= self._LocalPlayerName then return end

	--=======================================================================================================>

	-- If the Player is already Added to the Players Table, then return:
	if self._PlayerList[Player.Name] then return end

	--=======================================================================================================>

	-- If we are running on the Core Object:
	if not self._TaggedOnly then 
		--==============================================================================================>

		-- If the Player is already Added to the Players Table, then return:
		if self._Players[Player] then return end

		--==============================================================================================>
		-- Create a Player Object Table:
		self._Players[Player] = { Events = {} } :: any
		
		-- Create a Destroy function that will Clean up all the Player Events:
		self._Players[Player].Destroy = function(self)
			for Key, Connection in self.Events do self.Events[Key]:Disconnect(); self.Events[Key] = nil :: any end
		end

		-- Connect to the Player Character Added Event to Add Tags to the Character:
		self._Players[Player].Events['CharacterAdded'] = 
			Player.CharacterAdded:Connect(function(Character: Model)    self:_AddCharacter(self._PlayerList[Character.Name], Character)    end)
		
		-- Connect to the Player Character Added Event to Add Tags to the Character:
		self._Players[Player].Events['CharacterRemoved'] = 
			Player.CharacterRemoving:Connect(function(Character: Model) self:_RemoveCharacter(self._PlayerList[Character.Name], Character) end)
		
		--==============================================================================================>
		
		-- Add the Tag to the Player:
		if Player:HasTag(self._Tags.Player) == false then Player:AddTag(self._Tags.Player) end
		
		--==============================================================================================>

		-- Call the AddCharacter Method incase the Player already has a Character:
		self:_AddCharacter(Player, Player.Character)

		--==============================================================================================>
	end
	
	--=======================================================================================================>

	-- Insert the Player into the PlayerList
	self._PlayerList[Player.Name] = Player

	--=======================================================================================================>
end

-- Method to Remove a Player from the Data Object:
function PlaggerModule._RemovePlayer(self: Plagger, Player: Player)
	--=======================================================================================================>

	-- If the Player Name does not have a Player in the table, return:
	if not self._PlayerList[Player.Name] then return end

	--=======================================================================================================>

	-- If we are running on the Core Object:
	if not self._TaggedOnly then 
		--==============================================================================================>
		-- If the Player does not have a Player Object in the table, return:
		if not self._Players[Player] then return end
		--==============================================================================================>
		-- Remove the Tag from the Player if it has it:
		if Player:HasTag(self._Tags.Player) == true then Player:RemoveTag(self._Tags.Player) end
		-- Destroy the Player Object:
		self._Players[Player]:Destroy()
		-- Remove the Reference to the Player in the Table:
		self._Players[Player] = nil
		--==============================================================================================>
	end

	--=======================================================================================================>
	
	-- Remove the Player from the PlayerList
	self._PlayerList[Player.Name] = nil

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Method to Add a tag to the Player's Character:
function PlaggerModule._AddCharacter(self: Plagger, Player: Player, Character: Model?)
	--=======================================================================================================>
	-- If the Character passed is nil then return:
	if Character == nil then return end

	-- If this is not Running in TaggedOnly, and the Character does not already have the Tag, then Add it:
	if self._TaggedOnly == false and Character:HasTag(self._Tags.ServerCharacter) == false then Character:AddTag(self._Tags.ServerCharacter) end

	-- If this is Running in the Core Client Object:
	if self._TaggedOnly == false and self._RunScope == 'Client' then
		-- if the Player Name is the same as the LocalPlayerName, attempt to add the localcharacter tag:
		if Player.Name == self._LocalPlayerName then
			-- If this is Running in LocalOnly, and the Character does not already have the LocalCharacter Tag, then Add it:
			if Character:HasTag(self._Tags.LocalCharacter) == false then Character:AddTag(self._Tags.LocalCharacter) end
		end
	end
	
	-- Insert the Character into the CharacterList:
	self._CharacterList[Player.Name] = Character
	--=======================================================================================================>
end

-- Method to Remove a tag from the Player's Character:
function PlaggerModule._RemoveCharacter(self: Plagger, Player: Player, Character: Model)
	--=======================================================================================================>

	-- If the Character passed is nil then return:
	if Character == nil :: any then return end

	-- If the Character is not in the List, return:
	if not self._CharacterList[Character.Name] then return end

	-- If this is not Running in TaggedOnly, and the Character does have the Tag, then Remove it:
	if self._TaggedOnly == false and Character:HasTag(self._Tags.ServerCharacter) == true then Character:RemoveTag(self._Tags.ServerCharacter) end

		-- If this is Running in the Core Client Object:
	if self._TaggedOnly == false and self._RunScope == 'Client' then
		-- if the Player Name is the same as the LocalPlayerName, attempt to add the localcharacter tag:
		if Player.Name == self._LocalPlayerName then
			-- If this is Running in LocalOnly, and the Character already has the LocalCharacter Tag, then Remove it:
			if Character:HasTag(self._Tags.LocalCharacter) == true then Character:RemoveTag(self._Tags.LocalCharacter) end
		end
	end

	-- Remove the Character from the CharacterList
	self._CharacterList[Character.Name] = nil

	--=======================================================================================================>
end

--===========================================================================================================================>

--- @Public
--- Method to get the PlayersList:
function PlaggerModule.GetPlayers(self: Plagger): {[string]: Player}
	return self._PlayerList
end

--- @Public
--- Method to get the CharacterList:
function PlaggerModule.GetCharacters(self: Plagger): {[string]: Model}
	return self._CharacterList
end

--===========================================================================================================================>

--- @Public
--- Method to get the PlayerAdded (Tagged) Signal:
function PlaggerModule.GetPlayerAddedSignal(self: Plagger): RBXScriptSignal
	return CollectionService:GetInstanceAddedSignal(self._Tags.Player)
end

--- @Public
--- Method to get the PlayerRemoved (Un-Tagged) Signal:
function PlaggerModule.GetPlayerRemovedSignal(self: Plagger): RBXScriptSignal
	return CollectionService:GetInstanceRemovedSignal(self._Tags.Player)
end

--- @Public
--- Method to get the CharacterAdded (Tagged) Signal:
function PlaggerModule.GetCharacterAddedSignal(self: Plagger): RBXScriptSignal
	return CollectionService:GetInstanceAddedSignal(if self._LocalOnly == true then self._Tags.LocalCharacter else self._Tags.ServerCharacter)
end

--- @Public
--- Method to get the CharacterRemoved (Un-Tagged) Signal:
function PlaggerModule.GetCharacterRemovedSignal(self: Plagger): RBXScriptSignal
	return CollectionService:GetInstanceRemovedSignal(if self._LocalOnly == true then self._Tags.LocalCharacter else self._Tags.ServerCharacter)
end

--===========================================================================================================================>

-- Create the MetaIndex function:
function PlaggerModule.__index(self: Plagger, Index: string): any
	--=======================================================================================================>
	-- Specific Indexing:
	--=======================================================================================================>
	if Index == 'Characters' then return self._CharacterList end
	if Index == 'Players'    then return self._PlayerList    end
	--=======================================================================================================>
	-- If Index is in the immediate Module tree, return that value:			
	if PlaggerModule[Index] then return PlaggerModule[Index] end
	--=======================================================================================================>
	-- Return False if all else fails!
	return false 
	--=======================================================================================================>
end

-- Create the MetaIndex function:
function PlaggerModule.__newindex(self: Plagger, Index: string, Value: any)
	error(`{Index} could not be set on the Plagger (PlayerHandler)`)
end

--===========================================================================================================================>

-- Return the Module Object:
return table.freeze({New = PlaggerModule.New; new = PlaggerModule.New}) 

--===========================================================================================================================>