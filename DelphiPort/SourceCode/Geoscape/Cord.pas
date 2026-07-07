unit Cord;

interface

type
  TCordPolar = record
    lon, lat: Double;
    constructor Create(plon, plat: Double);
    class operator Implicit(const a: TCord): TCordPolar; // conversion
  end;

  TCord = record
    x, y, z: Double;
    constructor Create(px, py, pz: Double);
    class operator Negative(const a: TCord): TCord;
    class operator Implicit(const a: TCordPolar): TCord;
    function Norm: Double;
    procedure Add(const a: TCord);
    procedure Subtract(const a: TCord);
    procedure Multiply(d: Double);
    procedure Divide(d: Double);
    function Equal(const a: TCord): Boolean;
  end;

implementation

constructor TCordPolar.Create(plon, plat: Double);
begin
  lon := plon;
  lat := plat;
end;

class operator TCordPolar.Implicit(const a: TCord): TCordPolar;
var inv: Double;
begin
  inv := 1.0 / a.Norm;
  Result.lat := Arcsin(a.y * inv);
  Result.lon := ArcTan2(a.x, a.z);
end;

constructor TCord.Create(px, py, pz: Double);
begin
  x := px;
  y := py;
  z := pz;
end;

class operator TCord.Negative(const a: TCord): TCord;
begin
  Result.x := -a.x;
  Result.y := -a.y;
  Result.z := -a.z;
end;

class operator TCord.Implicit(const a: TCordPolar): TCord;
begin
  Result.x := Sin(a.lon) * Cos(a.lat);
  Result.y := Sin(a.lat);
  Result.z := Cos(a.lon) * Cos(a.lat);
end;

function TCord.Norm: Double;
begin
  Result := Sqrt(x*x + y*y + z*z);
end;

procedure TCord.Add(const a: TCord);
begin
  x := x + a.x;
  y := y + a.y;
  z := z + a.z;
end;

procedure TCord.Subtract(const a: TCord);
begin
  x := x - a.x;
  y := y - a.y;
  z := z - a.z;
end;

procedure TCord.Multiply(d: Double);
begin
  x := x * d;
  y := y * d;
  z := z * d;
end;

procedure TCord.Divide(d: Double);
var r: Double;
begin
  r := 1.0 / d;
  x := x * r;
  y := y * r;
  z := z * r;
end;

function TCord.Equal(const a: TCord): Boolean;
begin
  Result := (Abs(x - a.x) < 1e-9) and (Abs(y - a.y) < 1e-9) and (Abs(z - a.z) < 1e-9);
end;

end.