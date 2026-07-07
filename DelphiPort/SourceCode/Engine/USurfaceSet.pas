unit USurfaceSet;

interface

uses
  SysUtils, Classes, Generics.Collections, USurface, SDL;

type
  TSurfaceSet = class
  private
    FFrames: TDictionary<Integer, TSurface>;
    FWidth, FHeight: Integer;
    FSharedFrames: Integer;
  public
    constructor Create(Width, Height: Integer);
    destructor Destroy; override;
    procedure LoadPck(const Pck, Tab: string);
    procedure LoadDat(const Filename: string);
    function GetFrame(Index: Integer): TSurface;
    function AddFrame(Index: Integer): TSurface;
    function GetWidth: Integer;
    function GetHeight: Integer;
    procedure SetMaxSharedFrames(Value: Integer);
    function GetMaxSharedFrames: Integer;
    function GetTotalFrames: Integer;
    procedure SetPalette(Colors: PSDL_Color; FirstColor, NColors: Integer);
    function GetFrames: TDictionary<Integer, TSurface>;
  end;

implementation

uses
  UException, ULogger, UCrossPlatform;

constructor TSurfaceSet.Create(Width, Height: Integer);
begin
  FWidth := Width;
  FHeight := Height;
  FFrames := TDictionary<Integer, TSurface>.Create;
  FSharedFrames := MaxInt;
end;

destructor TSurfaceSet.Destroy;
begin
  for var F in FFrames.Values do
    F.Free;
  FFrames.Free;
  inherited;
end;

procedure TSurfaceSet.LoadPck(const Pck, Tab: string);
var
  OffsetFile: TFileStream;
  Offsets: TArray<Cardinal>;
  N, I: Integer;
  ImgFile: TFileStream;
  Value: Byte;
  X, Y: Integer;
  Surf: TSurface;
begin
  // Load TAB offsets
  if Tab <> '' then
  begin
    OffsetFile := TFileStream.Create(Tab, fmOpenRead or fmShareDenyWrite);
    try
      // Determine offset size
      var FirstOff: Cardinal;
      OffsetFile.Read(FirstOff, 4);
      if FirstOff <> 0 then // 16-bit offsets
      begin
        N := OffsetFile.Size div 2;
        SetLength(Offsets, N);
        OffsetFile.Seek(0, soBeginning);
        for I := 0 to N-1 do
        begin
          var W: Word;
          OffsetFile.Read(W, 2);
          Offsets[I] := W;
        end;
      end
      else // 32-bit
      begin
        N := OffsetFile.Size div 4;
        SetLength(Offsets, N);
        OffsetFile.Seek(0, soBeginning);
        for I := 0 to N-1 do
          OffsetFile.Read(Offsets[I], 4);
      end;
    finally
      OffsetFile.Free;
    end;
    // Create surfaces
    for I := 0 to N-1 do
    begin
      Surf := TSurface.Create(FWidth, FHeight);
      FFrames.Add(I, Surf);
    end;
  end
  else
  begin
    N := 1;
    Surf := TSurface.Create(FWidth, FHeight);
    FFrames.Add(0, Surf);
  end;

  // Load PCK data
  ImgFile := TFileStream.Create(Pck, fmOpenRead or fmShareDenyWrite);
  try
    for I := 0 to N-1 do
    begin
      X := 0; Y := 0;
      Surf := FFrames[I];
      Surf.Lock;
      // Read leading skip bytes
      ImgFile.Read(Value, 1);
      for var J := 0 to Value-1 do
        for var K := 0 to FWidth-1 do
          Surf.SetPixelIterative(X, Y, 0);
      // Decode RLE
      while ImgFile.Read(Value, 1) = 1 do
      begin
        if Value = 255 then Break;
        if Value = 254 then
        begin
          ImgFile.Read(Value, 1);
          for var J := 0 to Value-1 do
            Surf.SetPixelIterative(X, Y, 0);
        end
        else
          Surf.SetPixelIterative(X, Y, Value);
      end;
      Surf.Unlock;
    end;
  finally
    ImgFile.Free;
  end;
end;

procedure TSurfaceSet.LoadDat(const Filename: string);
var
  F: TFileStream;
  Size: Int64;
  N, I: Integer;
  Surf: TSurface;
  Value: Byte;
  X, Y: Integer;
begin
  F := TFileStream.Create(Filename, fmOpenRead or fmShareDenyWrite);
  try
    Size := F.Size;
    N := Size div (FWidth * FHeight);
    for I := 0 to N-1 do
    begin
      Surf := TSurface.Create(FWidth, FHeight);
      FFrames.Add(I, Surf);
    end;
    X := 0; Y := 0; I := 0;
    if N > 0 then FFrames[0].Lock;
    while F.Read(Value, 1) = 1 do
    begin
      FFrames[I].SetPixelIterative(X, Y, Value);
      if Y >= FHeight then
      begin
        FFrames[I].Unlock;
        Inc(I);
        if I >= N then Break;
        X := 0; Y := 0;
        FFrames[I].Lock;
      end;
    end;
    if I < N then FFrames[I].Unlock;
  finally
    F.Free;
  end;
end;

function TSurfaceSet.GetFrame(Index: Integer): TSurface;
begin
  if FFrames.ContainsKey(Index) then
    Result := FFrames[Index]
  else
    Result := nil;
end;

function TSurfaceSet.AddFrame(Index: Integer): TSurface;
begin
  Result := TSurface.Create(FWidth, FHeight);
  FFrames.Add(Index, Result);
end;

function TSurfaceSet.GetWidth: Integer;
begin
  Result := FWidth;
end;

function TSurfaceSet.GetHeight: Integer;
begin
  Result := FHeight;
end;

procedure TSurfaceSet.SetMaxSharedFrames(Value: Integer);
begin
  if Value < 0 then FSharedFrames := 0
  else FSharedFrames := Value;
end;

function TSurfaceSet.GetMaxSharedFrames: Integer;
begin
  Result := FSharedFrames;
end;

function TSurfaceSet.GetTotalFrames: Integer;
begin
  Result := FFrames.Count;
end;

procedure TSurfaceSet.SetPalette(Colors: PSDL_Color; FirstColor, NColors: Integer);
begin
  for var F in FFrames.Values do
    F.SetPalette(Colors, FirstColor, NColors);
end;

function TSurfaceSet.GetFrames: TDictionary<Integer, TSurface>;
begin
  Result := FFrames;
end;

end.