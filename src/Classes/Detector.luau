--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Define Module table
local DetectorModule: DetectorModule = {}
DetectorModule.__index = DetectorModule

--===========================================================================================================================>
--[ VARIABLES: ]

-- Require the Trove Module for Cleanup:
local ItemTrackerModule = require(script.Parent.ItemTracker);
local PlaggerModule     = require(script.Parent.Plagger);

--===========================================================================================================================>
--[ DEFINE TYPES: ]


-- Create and Export Object Type:
export type DetectorTypes = 'LocalPlayer' | 'Players' | 'Item';
export type DetectorModule   = typeof(DetectorModule)
export type Detector = { 
    --====================================================>
    _DetectorType: DetectorTypes;
    _Detection:    number;
    --====================================================>
	_Classes: {Plagger: PlaggerModule.Plagger};
    _Events:  {[string]: RBXScriptConnection};
	--==============================================>
	Trackers: {[string]: ItemTrackerModule.ItemTracker};
	Entered:  {Player};
	Exited:   {Player};
	--====================================================>

    Destroy: 
        (self: Detector) -> ();
    SetDetection: 
        (self: Detector, Detection: number) -> ();

    --====================================================>
} 

--===========================================================================================================================>
--[ FUNCTIONS: ]


-- Constructor Function for this individual object:
function DetectorModule.New(DetectorType: DetectorTypes, Detection: number): Detector
	--=======================================================================================================>

	-- Define DetectorData:
	local DetectorData: Detector = {
        --====================================================>
        _DetectorType = DetectorType;
        _Detection    = Detection;
		--====================================================>
        _Classes = {};
        _Events  = {};
        --====================================================>
        Trackers = {};
        Entered  = {};
        Exited   = {};
		--====================================================>
	} :: Detector

    --=======================================================================================================>

    if DetectorType == 'Players' or DetectorType == 'LocalPlayer' then
        --============================================================================================>

        if DetectorType == 'Players' then
            DetectorData._Classes.Plagger = PlaggerModule.New(true, false, true)
        elseif DetectorType == 'LocalPlayer' then
            DetectorData._Classes.Plagger = PlaggerModule.New(true, true, true)
        end

        -- Connect to the Character Tag Added Signal:
        -- Fires when a Part with the Character Tag is added back to the Workspace:
        DetectorData._Events['CharacterAdded'] = DetectorData._Classes.Plagger:GetCharacterAddedSignal():Connect(function(Character: Model)
            --==============================================================================>
            -- If there is a Player ItemTracker Object for this Character:
            -- Destroy it and clear it from the reference:
            if DetectorData.Trackers[Character.Name] then 
                DetectorData.Trackers[Character.Name]:Destroy() 
                DetectorData.Trackers[Character.Name] = nil 
            end
            --==============================================================================>
            DetectorData.Trackers[Character.Name] = ItemTrackerModule.New(Character, DetectorData._Detection)
            --==============================================================================>
        end)

        -- Connect to the Character Tag Removed Signal:
        -- Fires when a Part with the Character Tag is removed from the Workspace:
        DetectorData._Events['CharacterRemoved'] = DetectorData._Classes.Plagger:GetCharacterRemovedSignal():Connect(function(Character: Model)
            --==============================================================================>
            -- If there is a Player ItemTracker Object for this Character:
            -- Destroy it and clear it from the reference:
            if DetectorData.Trackers[Character.Name] then 
                DetectorData.Trackers[Character.Name]:Destroy() 
                DetectorData.Trackers[Character.Name] = nil 
            end
            --==============================================================================>
        end)

        --============================================================================================>
    end

    --=======================================================================================================>

    -- Create the Destroy Function:
    function DetectorData.Destroy(self: Detector)
        --===============================================================================>
        -- Clear all self._Events data:
        for Key, Data in self._Events  do self._Events[Key]:Disconnect(); self._Events[Key]  = nil end
        -- Clear all self._Classes data:
        for Key, Data in self._Classes do self._Classes[Key]:Destroy();   self._Classes[Key] = nil end
        -- Clear all self.Trackers data:
        for Key, Data in self.Trackers do self.Trackers[Key]:Destroy();   self.Trackers[Key] = nil end
        --===============================================================================>
        -- Clear all self data:
        for Index, Data in pairs(self) do self[Index] = nil end
        --===============================================================================>
    end

     -- Create the Destroy Function:
    function DetectorData.SetDetection(self: Detector, Detection: number)
        --===============================================================================>
        -- Set the Internal Value:
        self._Detection = Detection
		-- Loop through the Player ItemTrackers:
        -- Call the Detection Set Method on the Tracked Object:
		for Name: string, ItemTracker in self.Trackers do ItemTracker:SetDetection(Detection) end
        --===============================================================================>
    end

	--=======================================================================================================>

	-- Return the MetaTable Data
	return DetectorData :: any

	--=======================================================================================================>
end

--===========================================================================================================================>

-- Return a Frozen Module Table:
return table.freeze(DetectorModule) :: DetectorModule

--===========================================================================================================================>