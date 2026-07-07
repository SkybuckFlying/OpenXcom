unit OpenXcom.Mod.Impl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, OpenXcom.Mod, OpenXcom.Engine, OpenXcom.Savegame;

type
  TModImpl = class(TMod)
  private
    FDeployments: TStringList;
    FCrafts: TStringList;
    FItems: TStringList;
    FResearch: TStringList;
    FAlienRaces: TStringList;
    FAlienItemLevels: TStringList;
    FTerrains: TStringList;
    FUfos: TStringList;
    FAlienMissions: TStringList;
    FGlobe: TGlobe;
    FPalettes: TDictionary<string, TPalette>;
    FFonts: TDictionary<string, TFont>;
    FSurfaces: TDictionary<string, TSurface>;
    FSounds: TDictionary<string, TSound>;
    FMusics: TDictionary<string, TMusic>;
    FVideos: TDictionary<string, TVideoRule>;
    FStartingBase: TJSONObject;
    FInterfaces: TDictionary<string, TInterface>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadAll;
    function GetDeployment(const AId: string): TAlienDeployment;
    function GetCraft(const AId: string): TRuleCraft;
    function GetItem(const AId: string): TRuleItem;
    function GetResearch(const AId: string): TRuleResearch;
    function GetAlienRace(const AId: string): TAlienRace;
    function GetTerrain(const AId: string): TRuleTerrain;
    function GetUfo(const AId: string): TRuleUfo;
    function GetAlienMission(const AId: string): TRuleAlienMission;
    function GetGlobe: TGlobe;
    function GetSurface(const AId: string): TSurface;
    function GetSound(const ACat: string; AIndex: Integer; ARequired: Boolean = True): TSound;
    function GetMusic(const AId: string): TMusic;
    function GetVideo(const AId: string): TVideoRule;
    function GetPalette(const AId: string): TPalette;
    function GetFont(const AId: string): TFont;
    function GetSoundDefinitions: TStringList;
    function GetInterface(const AId: string): TInterface;
    function GenSoldier(ASave: TSaveGame; const AType: string): TSoldier;
    function NewSave: TSaveGame;
    procedure PlayMusic(const AId: string);
    function GetDeploymentsList: TStringList;
    function GetCraftsList: TStringList;
    function GetItemsList: TStringList;
    function GetResearchList: TStringList;
    function GetAlienRacesList: TStringList;
    function GetAlienItemLevels: TStringList;
    function GetAlienMissionList: TStringList;
    function GetStartingBase: TJSONObject;
  end;

implementation

constructor TModImpl.Create;
begin
  FDeployments := TStringList.Create;
  FCrafts := TStringList.Create;
  FItems := TStringList.Create;
  FResearch := TStringList.Create;
  FAlienRaces := TStringList.Create;
  FAlienItemLevels := TStringList.Create;
  FTerrains := TStringList.Create;
  FUfos := TStringList.Create;
  FAlienMissions := TStringList.Create;
  FGlobe := TGlobe.Create;
  FPalettes := TDictionary<string, TPalette>.Create;
  FFonts := TDictionary<string, TFont>.Create;
  FSurfaces := TDictionary<string, TSurface>.Create;
  FSounds := TDictionary<string, TSound>.Create;
  FMusics := TDictionary<string, TMusic>.Create;
  FVideos := TDictionary<string, TVideoRule>.Create;
  FInterfaces := TDictionary<string, TInterface>.Create;
end;

destructor TModImpl.Destroy;
begin
  FDeployments.Free;
  FCrafts.Free;
  FItems.Free;
  FResearch.Free;
  FAlienRaces.Free;
  FAlienItemLevels.Free;
  FTerrains.Free;
  FUfos.Free;
  FAlienMissions.Free;
  FGlobe.Free;
  FPalettes.Free;
  FFonts.Free;
  FSurfaces.Free;
  FSounds.Free;
  FMusics.Free;
  FVideos.Free;
  FInterfaces.Free;
  inherited;
end;

procedure TModImpl.LoadAll;
begin
  // load YAML rules, surfaces, sounds, etc.
end;

function TModImpl.GetDeployment(const AId: string): TAlienDeployment; begin Result := nil; end;
function TModImpl.GetCraft(const AId: string): TRuleCraft; begin Result := nil; end;
function TModImpl.GetItem(const AId: string): TRuleItem; begin Result := nil; end;
function TModImpl.GetResearch(const AId: string): TRuleResearch; begin Result := nil; end;
function TModImpl.GetAlienRace(const AId: string): TAlienRace; begin Result := nil; end;
function TModImpl.GetTerrain(const AId: string): TRuleTerrain; begin Result := nil; end;
function TModImpl.GetUfo(const AId: string): TRuleUfo; begin Result := nil; end;
function TModImpl.GetAlienMission(const AId: string): TRuleAlienMission; begin Result := nil; end;
function TModImpl.GetGlobe: TGlobe; begin Result := FGlobe; end;
function TModImpl.GetSurface(const AId: string): TSurface; begin Result := nil; end;
function TModImpl.GetSound(const ACat: string; AIndex: Integer; ARequired: Boolean = True): TSound; begin Result := nil; end;
function TModImpl.GetMusic(const AId: string): TMusic; begin Result := nil; end;
function TModImpl.GetVideo(const AId: string): TVideoRule; begin Result := nil; end;
function TModImpl.GetPalette(const AId: string): TPalette; begin Result := nil; end;
function TModImpl.GetFont(const AId: string): TFont; begin Result := nil; end;
function TModImpl.GetSoundDefinitions: TStringList; begin Result := nil; end;
function TModImpl.GetInterface(const AId: string): TInterface; begin Result := nil; end;
function TModImpl.GenSoldier(ASave: TSaveGame; const AType: string): TSoldier; begin Result := nil; end;
function TModImpl.NewSave: TSaveGame; begin Result := TSaveGameImpl.Create; end;
procedure TModImpl.PlayMusic(const AId: string); begin end;
function TModImpl.GetDeploymentsList: TStringList; begin Result := FDeployments; end;
function TModImpl.GetCraftsList: TStringList; begin Result := FCrafts; end;
function TModImpl.GetItemsList: TStringList; begin Result := FItems; end;
function TModImpl.GetResearchList: TStringList; begin Result := FResearch; end;
function TModImpl.GetAlienRacesList: TStringList; begin Result := FAlienRaces; end;
function TModImpl.GetAlienItemLevels: TStringList; begin Result := FAlienItemLevels; end;
function TModImpl.GetAlienMissionList: TStringList; begin Result := FAlienMissions; end;
function TModImpl.GetStartingBase: TJSONObject; begin Result := FStartingBase; end;

end.