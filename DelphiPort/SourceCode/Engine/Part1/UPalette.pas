unit UPalette;

interface

uses
  SysUtils, SDL;

type
  TPalette = class
  private
    FColors: array[0..255] of TSDL_Color;
    FCount: Integer;
  public
    constructor Create;
    procedure LoadDat(const Filename: string; NColors: Integer; Offset: Integer = 0);
    function GetColors(Offset: Integer = 0): PSDL_Color;
    class function GetRGBA(Pal: PSDL_Color; Color: Byte): UInt32;
    class function PalOffset(Palette: Integer): Integer; inline;
    class function BlockOffset(Block: Byte): Byte; inline;
    const BackPos = 224;
  end;

implementation

constructor TPalette.Create;
begin
  FCount := 0;
  FillChar(FColors, SizeOf(FColors), 0);
end;

procedure TPalette.LoadDat(const Filename: string; NColors, Offset: Integer);
var
  F: File;
  I: Integer;
  R,G,B: Byte;
begin
  FCount := NColors;
  AssignFile(F, Filename);
  Reset(F, 1);
  Seek(F, Offset);
  for I := 0 to NColors-1 do
  begin
    BlockRead(F, R, 1);
    BlockRead(F, G, 1);
    BlockRead(F, B, 1);
    FColors[I].r := R * 4;
    FColors[I].g := G * 4;
    FColors[I].b := B * 4;
    FColors[I].unused := 255;
  end;
  FColors[0].unused := 0;
  CloseFile(F);
end;

function TPalette.GetColors(Offset: Integer): PSDL_Color;
begin
  Result := @FColors[Offset];
end;

class function TPalette.GetRGBA(Pal: PSDL_Color; Color: Byte): UInt32;
begin
  Result := (Pal[Color].r shl 24) or (Pal[Color].g shl 16) or (Pal[Color].b shl 8) or $FF;
end;

class function TPalette.PalOffset(Palette: Integer): Integer;
begin
  Result := Palette * (768 + 6);
end;

class function TPalette.BlockOffset(Block: Byte): Byte;
begin
  Result := Block * 16;
end;

end.