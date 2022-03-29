uses
	unit_TxyzDouble_version_001,
	unit_TColor_version_001;

type
	PLight = ^TLight;
	TLight = packed record
	public
		Position : TxyzDouble;
		MovementDirection : TxyzDouble;
		Color : TColor;

		Padding : longword;

		Power : double;
		Range : double;
	end;
