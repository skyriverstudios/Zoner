--===========================================================================================================================>
--!strict
--===========================================================================================================================>

-- Set Memory Category:
debug.setmemorycategory('[Zone]: SignalHash')

-- Return a Frozen Module Table:
return table.freeze({
	--====================================================================================================>
	Send = table.freeze({
		['PartEntered'] = 'P1';
		['PartExited']  = 'P2';

		['ItemEntered'] = 'I1';
		['ItemExited']  = 'I2';

		['PlayerEntered'] = 'A1';
		['PlayerExited']  = 'A2';

		['LocalPlayerEntered'] = 'L1';
		['LocalPlayerExited']  = 'L2';
	});

	Receive = table.freeze({
		['P1'] = 'PartEntered';
		['P2'] = 'PartExited';

		['I1'] = 'ItemEntered';
		['I2'] = 'ItemExited';

		['A1'] = 'PlayerEntered';
		['A2'] = 'PlayerExited';

		['L1'] = 'LocalPlayerEntered';
		['L2'] = 'LocalPlayerExited';
	})
	--====================================================================================================>
})

--===========================================================================================================================>