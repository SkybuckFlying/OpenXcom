unit SerializationHelper;

interface

uses
  SysUtils, Classes, Math;

function UnserializeInt(var Buffer: PByte; SizeKey: Byte): Integer;
procedure SerializeInt(var Buffer: PByte; SizeKey: Byte; Value: Integer);
function SerializeDouble(Value: Double): string;

implementation

function UnserializeInt(var Buffer: PByte; SizeKey: Byte): Integer;
begin
  Result := 0;
  case SizeKey of
    1: Result := Buffer^;
    2: begin
         Move(Buffer^, Result, 2);
       end;
    4: begin
         Move(Buffer^, Result, 4);
       end;
  else
    raise Exception.Create('Invalid size key');
  end;
  Inc(Buffer, SizeKey);
end;

procedure SerializeInt(var Buffer: PByte; SizeKey: Byte; Value: Integer);
begin
  case SizeKey of
    1: begin
         if (Value < 0) or (Value > 255) then
           raise Exception.Create('Value out of range');
         Buffer^ := Byte(Value);
       end;
    2: begin
         if (Value < -32768) or (Value > 65535) then
           raise Exception.Create('Value out of range');
         Move(Value, Buffer^, 2);
       end;
    4: Move(Value, Buffer^, 4);
  else
    raise Exception.Create('Invalid size key');
  end;
  Inc(Buffer, SizeKey);
end;

function SerializeDouble(Value: Double): string;
begin
  Result := FloatToStr(Value);
end;

end.