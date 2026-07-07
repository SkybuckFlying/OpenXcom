unit UCatFile;

interface

uses
  Classes, SysUtils;

type
  TCatFile = class
  private
    FStream: TFileStream;
    FAmount: Cardinal;
    FOffsets: TArray<Cardinal>;
    FSizes: TArray<Cardinal>;
    function SwapEndian32(Value: Cardinal): Cardinal;
  public
    constructor Create(const Path: string);
    destructor Destroy; override;
    function GetAmount: Integer;
    function GetObjectSize(Index: Integer): Cardinal;
    function Load(Index: Integer; IncludeName: Boolean = False): TBytes;
  end;

implementation

constructor TCatFile.Create(const Path: string);
var
  I: Integer;
  Buf: array[0..3] of Byte;
begin
  FStream := TFileStream.Create(Path, fmOpenRead or fmShareDenyWrite);
  FStream.Read(Buf, 4);
  FAmount := SwapEndian32(PCardinal(@Buf)^);
  FAmount := FAmount div 8; // because each entry has offset and size
  SetLength(FOffsets, FAmount);
  SetLength(FSizes, FAmount);
  FStream.Seek(0, soBeginning);
  for I := 0 to FAmount-1 do
  begin
    FStream.Read(Buf, 4);
    FOffsets[I] := SwapEndian32(PCardinal(@Buf)^);
    FStream.Read(Buf, 4);
    FSizes[I] := SwapEndian32(PCardinal(@Buf)^);
  end;
end;

destructor TCatFile.Destroy;
begin
  FStream.Free;
  inherited;
end;

function TCatFile.SwapEndian32(Value: Cardinal): Cardinal;
begin
  Result := (Value shr 24) or ((Value shr 8) and $FF00) or ((Value shl 8) and $FF0000) or (Value shl 24);
end;

function TCatFile.GetAmount: Integer;
begin
  Result := FAmount;
end;

function TCatFile.GetObjectSize(Index: Integer): Cardinal;
begin
  if (Index >= 0) and (Index < FAmount) then
    Result := FSizes[Index]
  else
    Result := 0;
end;

function TCatFile.Load(Index: Integer; IncludeName: Boolean): TBytes;
var
  Offset, Size: Cardinal;
  NameSize: Byte;
begin
  if (Index < 0) or (Index >= FAmount) then Exit(nil);
  Offset := FOffsets[Index];
  Size := FSizes[Index];
  FStream.Seek(Offset, soBeginning);
  FStream.Read(NameSize, 1);
  if not IncludeName then
  begin
    FStream.Seek(NameSize, soCurrent);
    Size := Size - NameSize - 1;
    SetLength(Result, Size);
    FStream.Read(Result[0], Size);
  end
  else
  begin
    SetLength(Result, Size + NameSize + 1);
    Result[0] := NameSize;
    FStream.Read(Result[1], NameSize);
    FStream.Read(Result[1+NameSize], Size);
  end;
end;

end.