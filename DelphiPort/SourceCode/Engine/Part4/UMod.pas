unit UMod;

interface

uses
  SysUtils, Classes, Generics.Collections, SDL, UPalette, USurfaceSet, USoundSet,
  UMusic, UFont, URuleInterface, UExtraStrings;

type
  TMod = class
  private
    FPalettes: TDictionary<string, TPalette>;
    FSurfaceSets: TDictionary<string, TSurfaceSet>;
    FSoundSets: TDictionary<string, TSoundSet>;
    FMusic: TDictionary<string, TMusic>;
    FFonts: TDictionary<string, TFont>;
    FInterfaces: TDictionary<string, TRuleInterface>;
    FExtraStrings: TDictionary<string, TExtraStrings>;
    FPalette: PSDL_Color;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadAll(const Rulesets: array of string); // simplified
    function GetPalette(const ID: string): TPalette;
    function GetSurface(const ID: string): TSurfaceSet;
    function GetSoundSet(const ID: string): TSoundSet;
    function GetMusic(const ID: string): TMusic;
    function GetFont(const ID: string): TFont;
    function GetInterface(const ID: string): TRuleInterface;
    function GetExtraStrings(const ID: string): TExtraStrings;
    procedure SetPalette(Colors: PSDL_Color);
    procedure PlayMusic(const ID: string);
  end;

implementation

constructor TMod.Create;
begin
  FPalettes := TDictionary<string, TPalette>.Create;
  FSurfaceSets := TDictionary<string, TSurfaceSet>.Create;
  FSoundSets := TDictionary<string, TSoundSet>.Create;
  FMusic := TDictionary<string, TMusic>.Create;
  FFonts := TDictionary<string, TFont>.Create;
  FInterfaces := TDictionary<string, TRuleInterface>.Create;
  FExtraStrings := TDictionary<string, TExtraStrings>.Create;
  FPalette := nil;
end;

destructor TMod.Destroy;
begin
  for var P in FPalettes.Values do P.Free;
  for var S in FSurfaceSets.Values do S.Free;
  for var S in FSoundSets.Values do S.Free;
  for var M in FMusic.Values do M.Free;
  for var F in FFonts.Values do F.Free;
  for var I in FInterfaces.Values do I.Free;
  for var E in FExtraStrings.Values do E.Free;
  FPalettes.Free;
  FSurfaceSets.Free;
  FSoundSets.Free;
  FMusic.Free;
  FFonts.Free;
  FInterfaces.Free;
  FExtraStrings.Free;
  inherited;
end;

procedure TMod.LoadAll(const Rulesets: array of string);
begin
  // Stub: parse each ruleset and load resources
end;

function TMod.GetPalette(const ID: string): TPalette;
begin
  Result := FPalettes[ID];
end;

function TMod.GetSurface(const ID: string): TSurfaceSet;
begin
  Result := FSurfaceSets[ID];
end;

function TMod.GetSoundSet(const ID: string): TSoundSet;
begin
  Result := FSoundSets[ID];
end;

function TMod.GetMusic(const ID: string): TMusic;
begin
  Result := FMusic[ID];
end;

function TMod.GetFont(const ID: string): TFont;
begin
  Result := FFonts[ID];
end;

function TMod.GetInterface(const ID: string): TRuleInterface;
begin
  Result := FInterfaces[ID];
end;

function TMod.GetExtraStrings(const ID: string): TExtraStrings;
begin
  Result := FExtraStrings[ID];
end;

procedure TMod.SetPalette(Colors: PSDL_Color);
begin
  FPalette := Colors;
  // Propagate to all surface sets and fonts
  for var SS in FSurfaceSets.Values do
    SS.SetPalette(Colors, 0, 256);
  for var Font in FFonts.Values do
    Font.SetPalette(Colors, 0, 256);
end;

procedure TMod.PlayMusic(const ID: string);
begin
  if FMusic.ContainsKey(ID) then
    FMusic[ID].Play(-1);
end;

end.