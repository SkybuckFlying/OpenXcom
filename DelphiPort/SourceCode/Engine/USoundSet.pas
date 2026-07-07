unit USoundSet;

interface

uses
  SysUtils, Classes, Generics.Collections, USound;

type
  TSoundSet = class
  private
    FSounds: TDictionary<Integer, TSound>;
    FSharedSounds: Integer;
    function ConvertSampleRate(OldSound: PByte; OldSize: Cardinal; NewSound: PByte): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadCat(const Filename: string; Wav: Boolean = True);
    procedure LoadCatByIndex(const Filename: string; Index: Integer);
    function GetSound(Index: Integer): TSound;
    function AddSound(Index: Integer): TSound;
    procedure SetMaxSharedSounds(Value: Integer);
    function GetMaxSharedSounds: Integer;
    function GetTotalSounds: Integer;
  end;

implementation

uses
  UCatFile, UException, ULogger;

constructor TSoundSet.Create;
begin
  FSounds := TDictionary<Integer, TSound>.Create;
  FSharedSounds := MaxInt;
end;

destructor TSoundSet.Destroy;
begin
  for var S in FSounds.Values do
    S.Free;
  FSounds.Free;
  inherited;
end;

function TSoundSet.ConvertSampleRate(OldSound: PByte; OldSize: Cardinal; NewSound: PByte): Integer;
const
  Step16 = (8000 shl 16) div 11025;
var
  Offset16: Cardinal;
  I: Integer;
begin
  Offset16 := 0;
  I := 0;
  while (Offset16 shr 16) < OldSize do
  begin
    NewSound[I] := OldSound[Offset16 shr 16];
    Inc(I);
    Offset16 := Offset16 + Step16;
  end;
  Result := I;
end;

procedure TSoundSet.LoadCat(const Filename: string; Wav: Boolean);
var
  Cat: TCatFile;
  I: Integer;
  SoundData: TBytes;
  Size: Cardinal;
  NewSound: TBytes;
  Header: array[0..43] of Byte;
  NewSize: Integer;
  S: TSound;
begin
  Cat := TCatFile.Create(Filename);
  try
    for I := 0 to Cat.GetAmount - 1 do
    begin
      SoundData := Cat.Load(I, False);
      if SoundData = nil then Continue;
      Size := Length(SoundData);
      if not Wav then
      begin
        // Remove 5-byte name and trailing null
        if Size > 5 then
        begin
          Dec(Size, 5);
          // scale to 8 bits
          for var J := 0 to Size-1 do
            SoundData[5+J] := SoundData[5+J] * 4;
          // Build WAV header
          FillChar(Header, SizeOf(Header), 0);
          Move('RIFF'#0#0#0#0'WAVEfmt '#$10#0#0#0#1#0#1#0#$11#$2B#0#0#$11#$2B#0#0#1#0#8#0'data'#0#0#0#0, Header, 44);
          // Convert sample rate
          SetLength(NewSound, 44 + Size*2);
          Move(Header, NewSound[0], 44);
          NewSize := ConvertSampleRate(@SoundData[5], Size, @NewSound[44]);
          // Update header sizes
          PCardinal(@NewSound[4])^ := NewSize + 36;
          PCardinal(@NewSound[40])^ := NewSize;
          Size := NewSize + 44;
          S := TSound.Create;
          try
            S.LoadFromMemory(@NewSound[0], Size);
            FSounds.Add(I, S);
          except
            S.Free;
          end;
        end;
      end
      else
      begin
        // Check if 8kHz
        if (SoundData[$18] = $40) and (SoundData[$19] = $1F) and (SoundData[$1A] = 0) and (SoundData[$1B] = 0) then
        begin
          // Convert
          SetLength(NewSound, Size*2);
          Move(SoundData[0], NewSound[0], Size);
          // Update samplerate to 11025
          NewSound[$18] := $11; NewSound[$19] := $2B;
          NewSound[$1C] := $11; NewSound[$1D] := $2B;
          NewSize := ConvertSampleRate(@SoundData[44], Size-44, @NewSound[44]);
          PCardinal(@NewSound[$28])^ := NewSize;
          Size := NewSize + 44;
          S := TSound.Create;
          try
            S.LoadFromMemory(@NewSound[0], Size);
            FSounds.Add(I, S);
          except
            S.Free;
          end;
        end
        else
        begin
          S := TSound.Create;
          try
            S.LoadFromMemory(@SoundData[0], Size);
            FSounds.Add(I, S);
          except
            S.Free;
          end;
        end;
      end;
    end;
  finally
    Cat.Free;
  end;
end;

procedure TSoundSet.LoadCatByIndex(const Filename: string; Index: Integer);
var
  Cat: TCatFile;
  SoundData: TBytes;
  Size: Cardinal;
  NewSound: TBytes;
  S: TSound;
  Header: array[0..43] of Byte;
begin
  Cat := TCatFile.Create(Filename);
  try
    if Index >= Cat.GetAmount then
      raise EOpenXcom.Create(Format('%s does not contain index %d', [Filename, Index]));
    SoundData := Cat.Load(Index, False);
    if SoundData = nil then Exit;
    Size := Length(SoundData);
    if Size > 5 then Dec(Size, 5);
    if Size > 0 then Dec(Size); // trailing null
    if Size = 0 then Exit;
    // Build WAV header for TFTD (signed 8-bit, 11025Hz)
    FillChar(Header, SizeOf(Header), 0);
    Move('RIFF'#0#0#0#0'WAVEfmt '#$10#0#0#0#1#0#1#0#$11#$2B#0#0#$11#$2B#0#0#1#0#8#0'data'#0#0#0#0, Header, 44);
    PCardinal(@Header[4])^ := Size + 36;
    PCardinal(@Header[40])^ := Size;
    SetLength(NewSound, 44 + Size);
    Move(Header, NewSound[0], 44);
    // Convert signed to unsigned
    for var J := 0 to Size-1 do
      NewSound[44+J] := SoundData[5+J] + 128;
    S := TSound.Create;
    try
      S.LoadFromMemory(@NewSound[0], 44+Size);
      FSounds.Add(FSounds.Count, S);
    except
      S.Free;
    end;
  finally
    Cat.Free;
  end;
end;

function TSoundSet.GetSound(Index: Integer): TSound;
begin
  if FSounds.ContainsKey(Index) then
    Result := FSounds[Index]
  else
    Result := nil;
end;

function TSoundSet.AddSound(Index: Integer): TSound;
begin
  Result := TSound.Create;
  FSounds.Add(Index, Result);
end;

procedure TSoundSet.SetMaxSharedSounds(Value: Integer);
begin
  if Value < 0 then FSharedSounds := 0
  else FSharedSounds := Value;
end;

function TSoundSet.GetMaxSharedSounds: Integer;
begin
  Result := FSharedSounds;
end;

function TSoundSet.GetTotalSounds: Integer;
begin
  Result := FSounds.Count;
end;

end.