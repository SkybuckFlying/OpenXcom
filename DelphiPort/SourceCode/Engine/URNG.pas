unit URNG;

interface

uses
  SysUtils, Math;

type
  TRNG = class
  private
    class var FSeed: UInt64;
    class function Next: UInt64;
  public
    class function GetSeed: UInt64;
    class procedure SetSeed(Seed: UInt64);
    class function Generate(Min, Max: Integer): Integer; overload;
    class function Generate(Min, Max: Double): Double; overload;
    class function Seedless(Min, Max: Integer): Integer;
    class function Percent(Value: Integer): Boolean;
    class procedure Shuffle<T>(var List: TArray<T>);
  end;

implementation

uses
  DateUtils;

class function TRNG.Next: UInt64;
begin
  FSeed := FSeed xor (FSeed shr 12);
  FSeed := FSeed xor (FSeed shl 25);
  FSeed := FSeed xor (FSeed shr 27);
  Result := FSeed * 2685821657736338717;
end;

class function TRNG.GetSeed: UInt64;
begin
  Result := FSeed;
end;

class procedure TRNG.SetSeed(Seed: UInt64);
begin
  FSeed := Seed;
end;

class function TRNG.Generate(Min, Max: Integer): Integer;
begin
  Result := Min + (Next mod (Max - Min + 1));
end;

class function TRNG.Generate(Min, Max: Double): Double;
begin
  Result := Min + (Next / $FFFFFFFFFFFFFFFF) * (Max - Min);
end;

class function TRNG.Seedless(Min, Max: Integer): Integer;
begin
  Result := Min + Random(Max - Min + 1);
end;

class function TRNG.Percent(Value: Integer): Boolean;
begin
  Result := Generate(0, 99) < Value;
end;

class procedure TRNG.Shuffle<T>(var List: TArray<T>);
var
  I, J: Integer;
begin
  for I := High(List) downto 1 do
  begin
    J := Generate(0, I);
    var Temp := List[I];
    List[I] := List[J];
    List[J] := Temp;
  end;
end;

initialization
  TRNG.FSeed := DateTimeToUnix(Now) * 1000 + MillisecondsOf(Now);
end.