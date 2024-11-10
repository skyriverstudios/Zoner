--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Default Prefix:
local Zoner = `\n[ ZONER LOG ]`

-- Default Title Prefix:
local Title = `\n[Title]:`
-- Default Error Prefix:
local Error = `\n[Error]:`
-- Default Description Prefix:
local Desc = `\n[Desc]: `

--===========================================================================================================================>

-- Return Logs table:
return {
	--================================================================================================================>
	
	Zoner = table.freeze({
		--======================================================================================================>
		DetectionCoverage =
			`{Zoner} {Title} Zone: New {Error} Invalid DetectionCoverage Enum {Desc} DetectionCoverage Setting must be a number or string from the DetectionCoverage Enum`;
		DetectionMethod =
			`{Zoner} {Title} Zone: New {Error} Invalid DetectionMethod Enum {Desc} DetectionMethod Setting must be a number or string from the DetectionMethod Enum`;
		DetectionMode =
			`{Zoner} {Title} Zone: New {Error} Invalid DetectionMode Enum {Desc} DetectionMode Setting must be a number or string from the DetectionMode Enum`;
		Execution =
			`{Zoner} {Title} Zone: New {Error} Invalid Execution Enum {Desc} Execution Setting must be a number or string from the Execution Enum`;
		Rate =
			`{Zoner} {Title} Zone: New {Error} Invalid Rate Enum {Desc} Rate Setting must be a number or string from the Rate Enum`;
		ManualStepping =
			`{Zoner} {Title} Zone: New {Error} Invalid ManualStepping boolean {Desc} ManualStepping Setting must be a boolean`;
		Simulation =
			`{Zoner} {Title} Zone: New {Error} Invalid Simulation Enum {Desc} Simulation Setting must be a number or string from the Simulation Enum`;
		Bounds =
			`{Zoner} {Title} Zone: New {Error} Invalid Bounds Enum {Desc} Bounds Setting must be a number or string from the Bounds Enum`;


		ContainerType = 
			`{Zoner} {Title} Zone: New {Error} Invalid Container Type {Desc} Container Paramater must be a Table or Instance`;
		ContainerBoxTable = 
			`{Zoner} {Title} Zone: New {Error} Invalid Container Box Table {Desc} Container Box Table is missing a CFrame or Size property`;
		ContainerPartTable1 = 
			`{Zoner} {Title} Zone: New {Error} Invalid Container Part Table {Desc} Container Part Table does not contain only BaseParts`;
		ContainerPartTable2 = 
			`{Zoner} {Title} Zone: New {Error} Invalid Container Part Table {Desc} Container Part Table does not contain only Instances`;

		ContainerInstanceType  = 
			`{Zoner} {Title} Zone: New {Error} Invalid Container Instance Type {Desc} Container Instance Paramater must be a 'BasePart', 'Folder', 'Model', or 'Configuration'`;
		--======================================================================================================>
	});
	
	Zone = table.freeze({
		--======================================================================================================>
		SetDetection =
			`{Zoner} {Title} Zone: SetDetection {Error} Invalid Detection Enum {Desc} Detection Paramater be a number or string from the Detection Enum`;
		SetEnterDetection =
			`{Zoner} {Title} Zone: SetEnterDetection {Error} Invalid Detection Enum {Desc} Detection Enum must be a number from the Detection Enum`;
		SetExitDetection =
			`{Zoner} {Title} Zone: SetExitDetection {Error} Invalid Detection Enum {Desc} Detection Enum must be a number from the Detection Enum`;

		SetSimulation1 =
			`{Zoner} {Title} Zone: SetSimulation {Error} Invalid Simulation Enum {Desc} Simulation Paramater must be a number or string from the Simulation Enum`;
		SetSimulation2 =
			`{Zoner} {Title} Zone: SetSimulation {Error} Invalid Simulation Enum {Desc} "PreRender" cannot be used on the Server`;

		SetAccuracy =
			`{Zoner} {Title} Zone: SetAccuracy {Error} Invalid Accuracy Enum {Desc} Accuracy Paramater must be a number or string from the Accuracy Enum`;

		SetRate =
			`{Zoner} {Title} Zone: SetRate {Error} Invalid Rate Enum {Desc} Rate Paramater must be a number or string from the Accuracy Enum`;
		
		SetState =
			`{Zoner} {Title} Zone: SetState {Error} Invalid State Value {Desc} State Value must be a boolean`;

		--======================================================================================================>
	});
	
	Tracker = table.freeze({
		--================================>

		DetectionCoverage =
			`{Zoner} {Title} Tracker: New {Error} Invalid DetectionCoverage Enum {Desc} DetectionCoverage Paramater must be a number or string from the DetectionCoverage Enum`;
		DetectionMode =
			`{Zoner} {Title} Tracker: New {Error} Invalid DetectionMode Enum {Desc} DetectionMode Paramater must be a number or string from the DetectionMode Enum`;

		ItemType = 
			`{Zoner} {Title} Tracker: New {Error} Invalid Item Type {Desc} CItem Paramater must be an Instance`;

		InstanceType  = 
			`{Zoner} {Title} Tracker: New {Error} Invalid Item Instance Type {Desc} Item Instance Paramater must be a 'BasePart' or 'Model'`;

		SetDetection1 =
			`{Zoner} {Title} Tracker: SetDetection {Error} Invalid DetectionCoverage Enum {Desc} DetectionCoverage Paramater must be a number or string from the DetectionCoverage Enum`;
		SetDetection2 =
			`{Zoner} {Title} Tracker: SetDetection {Error} Invalid DetectionMode Enum {Desc} DetectionMode Paramater must be a number or string from the DetectionMode Enum`;

		--================================>
	});
	
	--================================================================================================================>
}