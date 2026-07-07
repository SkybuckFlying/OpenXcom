unit UFont;

interface

uses
  SysUtils, Classes, SDL, USurface, UUnicode;

type
  TFontImage = record
    Width, Height, Spacing: Integer;
    Surface: TSurface;
  end;

  TFont = class
  private
    FImages: TArray<TFontImage>;
    FChars: TDictionary<UCode, TPair<Integer, TSDL_Rect>>;
    FMonospace: Boolean;
    procedure Init(Index: Integer; const Chars: UString);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode); // YAML stub
    procedure LoadTerminal;
    function GetChar(C: UCode): TSurface;
    function GetWidth: Integer;
    function GetHeight: Integer;
    function GetSpacing: Integer;
    function GetCharSize(C: UCode): TSDL_Rect;
    function GetPalette: PSDL_Color;
    procedure SetPalette(Colors: PSDL_Color; FirstColor, NColors: Integer);
  end;

implementation

uses
  UFileMap, UUnicode;

constructor TFont.Create;
begin
  FChars := TDictionary<UCode, TPair<Integer, TSDL_Rect>>.Create;
  FMonospace := False;
end;

destructor TFont.Destroy;
begin
  for var Img in FImages do
    Img.Surface.Free;
  FChars.Free;
  inherited;
end;

procedure TFont.Load(const Node: TYamlNode);
begin
  // Stub for YAML parsing
end;

procedure TFont.LoadTerminal;
begin
  // Load DOS font
end;

procedure TFont.Init(Index: Integer; const Chars: UString);
begin
  // Calculate character rects
end;

function TFont.GetChar(C: UCode): TSurface;
begin
  // Return surface with crop set
end;

function TFont.GetWidth: Integer;
begin
  if Length(FImages) > 0 then
    Result := FImages[0].Width
  else
    Result := 0;
end;

function TFont.GetHeight: Integer;
begin
  if Length(FImages) > 0 then
    Result := FImages[0].Height
  else
    Result := 0;
end;

function TFont.GetSpacing: Integer;
begin
  if Length(FImages) > 0 then
    Result := FImages[0].Spacing
  else
    Result := 0;
end;

function TFont.GetCharSize(C: UCode): TSDL_Rect;
begin
  // Compute size
end;

function TFont.GetPalette: PSDL_Color;
begin
  if Length(FImages) > 0 then
    Result := FImages[0].Surface.GetPalette
  else
    Result := nil;
end;

procedure TFont.SetPalette(Colors: PSDL_Color; FirstColor, NColors: Integer);
begin
  for var Img in FImages do
    Img.Surface.SetPalette(Colors, FirstColor, NColors);
end;

end.