unit OpenXcom.Savegame.Impl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, OpenXcom.Savegame, OpenXcom.Mod, OpenXcom.Engine;

type
  TSaveGameImpl = class(TSaveGame)
  private
    FName: string;
    FIronman: Boolean;
    FDifficulty: Integer;
    FEnding: Integer;
    FMonthsPassed: Integer;
    FBattleGame: TSavedBattleGame;
    FMods: TStringList;
    FDiscoveredResearch: TStringList;
    FResearchScores: array of Integer;
    FIncomes, FExpenditures: array of Int64;
    FDeadSoldiers: TList;
    FBases: TList;
    FCountries: TList;
    FRegions: TList;
    FAlienBases: TList;
    FAllIds: TDictionary<string, Integer>;
    FMissionStats: TList;
    FUfos: TList;
    FMissionSites: TList;
    FTime: TGameTime;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Save(const AFileName: string); override;
    procedure Load(const AFileName: string; AMod: TMod); override;
    function IsIronman: Boolean; override;
    function GetName: string; override;
    procedure SetName(const AName: string); override;
    function GetEnding: Integer; override;
    function GetDifficulty: Integer; override;
    procedure SetDifficulty(ADiff: Integer); override;
    procedure SetIronman(AIron: Boolean); override;
    function GetMonthsPassed: Integer; override;
    function GetSavedBattle: TSavedBattleGame; override;
    procedure SetBattleGame(ABattle: TSavedBattleGame); override;
  end;

  TSavedBattleGameImpl = class(TSavedBattleGame)
  private
    FAmbientSound: Integer;
    FStates: TList;
    FMapResourcesLoaded: Boolean;
  public
    function GetAmbientSound: Integer;
    procedure SetAmbientSound(AIndex: Integer);
    function GetStates: TList;
    procedure LoadMapResources(AMod: TMod);
    procedure SetBattleState(ABattleState: TState);
  end;

implementation

{ TSaveGameImpl }
constructor TSaveGameImpl.Create;
begin
  FMods := TStringList.Create;
  FDiscoveredResearch := TStringList.Create;
  FDeadSoldiers := TList.Create;
  FBases := TList.Create;
  FCountries := TList.Create;
  FRegions := TList.Create;
  FAlienBases := TList.Create;
  FAllIds := TDictionary<string, Integer>.Create;
  FMissionStats := TList.Create;
  FUfos := TList.Create;
  FMissionSites := TList.Create;
  FTime := TGameTime.Create;
end;

destructor TSaveGameImpl.Destroy;
begin
  FMods.Free;
  FDiscoveredResearch.Free;
  FDeadSoldiers.Free;
  FBases.Free;
  FCountries.Free;
  FRegions.Free;
  FAlienBases.Free;
  FAllIds.Free;
  FMissionStats.Free;
  FUfos.Free;
  FMissionSites.Free;
  FTime.Free;
  inherited;
end;

procedure TSaveGameImpl.Save(const AFileName: string);
begin
  // JSON serialization
end;

procedure TSaveGameImpl.Load(const AFileName: string; AMod: TMod);
begin
  // JSON deserialization
end;

function TSaveGameImpl.IsIronman: Boolean;
begin
  Result := FIronman;
end;

function TSaveGameImpl.GetName: string;
begin
  Result := FName;
end;

procedure TSaveGameImpl.SetName(const AName: string);
begin
  FName := AName;
end;

function TSaveGameImpl.GetEnding: Integer;
begin
  Result := FEnding;
end;

function TSaveGameImpl.GetDifficulty: Integer;
begin
  Result := FDifficulty;
end;

procedure TSaveGameImpl.SetDifficulty(ADiff: Integer);
begin
  FDifficulty := ADiff;
end;

procedure TSaveGameImpl.SetIronman(AIron: Boolean);
begin
  FIronman := AIron;
end;

function TSaveGameImpl.GetMonthsPassed: Integer;
begin
  Result := FMonthsPassed;
end;

function TSaveGameImpl.GetSavedBattle: TSavedBattleGame;
begin
  Result := FBattleGame;
end;

procedure TSaveGameImpl.SetBattleGame(ABattle: TSavedBattleGame);
begin
  FBattleGame := ABattle;
end;

{ TSavedBattleGameImpl }
function TSavedBattleGameImpl.GetAmbientSound: Integer;
begin
  Result := FAmbientSound;
end;

procedure TSavedBattleGameImpl.SetAmbientSound(AIndex: Integer);
begin
  FAmbientSound := AIndex;
end;

function TSavedBattleGameImpl.GetStates: TList;
begin
  Result := FStates;
end;

procedure TSavedBattleGameImpl.LoadMapResources(AMod: TMod);
begin
  FMapResourcesLoaded := True;
end;

procedure TSavedBattleGameImpl.SetBattleState(ABattleState: TState);
begin
  // store reference
end;

end.