unit RuleMissionScript;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, Savegame.WeightedOptions;

type
  TGenerationType = (genRegion, genMission, genRace);

  TRuleMissionScript = class
  private
    FType: string;
    FVarName: string;
    FFirstMonth: Integer;
    FLastMonth: Integer;
    FLabel: Integer;
    FExecutionOdds: Integer;
    FTargetBaseOdds: Integer;
    FMinDifficulty: Integer;
    FMaxRuns: Integer;
    FAvoidRepeats: Integer;
    FDelay: Integer;
    FConditionals: TArray<Integer>;
    FRegionWeights: TArray<TPair<Integer, TWeightedOptions>>;
    FMissionWeights: TArray<TPair<Integer, TWeightedOptions>>;
    FRaceWeights: TArray<TPair<Integer, TWeightedOptions>>;
    FResearchTriggers: TDictionary<string, Boolean>;
    FUseTable: Boolean;
    FSiteType: Boolean;
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GetType: string;
    function GetVarName: string;
    function GetAllMissionTypes: TArray<string>;
    function GetRegions(Month: Integer): TArray<string>;
    function GetMissionTypes(Month: Integer): TArray<string>;
    function GetFirstMonth: Integer;
    function GetLastMonth: Integer;
    function GetLabel: Integer;
    function GetExecutionOdds: Integer;
    function GetTargetBaseOdds: Integer;
    function GetMinDifficulty: Integer;
    function GetMaxRuns: Integer;
    function GetRepeatAvoidance: Integer;
    function GetDelay: Integer;
    function GetConditionals: TArray<Integer>;
    function HasRaceWeights: Boolean;
    function HasMissionWeights: Boolean;
    function HasRegionWeights: Boolean;
    function GetResearchTriggers: TDictionary<string, Boolean>;
    function GetUseTable: Boolean;
    procedure SetSiteType(ASiteType: Boolean);
    function GetSiteType: Boolean;
    function Generate(MonthsPassed: Integer; GenType: TGenerationType): string;
  end;

implementation

{ TRuleMissionScript }

constructor TRuleMissionScript.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FFirstMonth := 0; FLastMonth := -1; FLabel := 0;
  FExecutionOdds := 100; FTargetBaseOdds := 0; FMinDifficulty := 0;
  FMaxRuns := -1; FAvoidRepeats := 0; FDelay := 0;
  FUseTable := True; FSiteType := False;
  FResearchTriggers := TDictionary<string, Boolean>.Create;
end;

destructor TRuleMissionScript.Destroy;
begin
  for var pair in FRegionWeights do pair.Value.Free;
  for var pair in FMissionWeights do pair.Value.Free;
  for var pair in FRaceWeights do pair.Value.Free;
  FResearchTriggers.Free;
  inherited;
end;

procedure TRuleMissionScript.Load(const Node: TYamlNode);
begin
  FVarName := Node['varName'].AsString(FVarName);
  FFirstMonth := Node['firstMonth'].AsInteger(FFirstMonth);
  FLastMonth := Node['lastMonth'].AsInteger(FLastMonth);
  FLabel := Node['label'].AsInteger(FLabel);
  FExecutionOdds := Node['executionOdds'].AsInteger(FExecutionOdds);
  FTargetBaseOdds := Node['targetBaseOdds'].AsInteger(FTargetBaseOdds);
  FMinDifficulty := Node['minDifficulty'].AsInteger(FMinDifficulty);
  FMaxRuns := Node['maxRuns'].AsInteger(FMaxRuns);
  FAvoidRepeats := Node['avoidRepeats'].AsInteger(FAvoidRepeats);
  FDelay := Node['startDelay'].AsInteger(FDelay);
  FConditionals := Node['conditionals'].AsArray<Integer>(FConditionals);

  // Load weights
  FRegionWeights := [];
  FMissionWeights := [];
  FRaceWeights := [];

  var weights := Node['missionWeights'];
  if not weights.IsNull then
    for var kv in weights do
    begin
      var wo := TWeightedOptions.Create;
      wo.Load(kv.Value);
      FMissionWeights := FMissionWeights + [TPair<Integer, TWeightedOptions>.Create(kv.Key.AsInteger, wo)];
    end;

  weights := Node['raceWeights'];
  if not weights.IsNull then
    for var kv in weights do
    begin
      var wo := TWeightedOptions.Create;
      wo.Load(kv.Value);
      FRaceWeights := FRaceWeights + [TPair<Integer, TWeightedOptions>.Create(kv.Key.AsInteger, wo)];
    end;

  weights := Node['regionWeights'];
  if not weights.IsNull then
    for var kv in weights do
    begin
      var wo := TWeightedOptions.Create;
      wo.Load(kv.Value);
      FRegionWeights := FRegionWeights + [TPair<Integer, TWeightedOptions>.Create(kv.Key.AsInteger, wo)];
    end;

  FResearchTriggers.Clear;
  var trigNode := Node['researchTriggers'];
  if not trigNode.IsNull then
    for var kv in trigNode do
      FResearchTriggers.Add(kv.Key.AsString, kv.Value.AsBoolean);

  FUseTable := Node['useTable'].AsBoolean(FUseTable);
end;

function TRuleMissionScript.GetType: string;
begin
  Result := FType;
end;

function TRuleMissionScript.GetVarName: string;
begin
  Result := FVarName;
end;

function TRuleMissionScript.GetAllMissionTypes: TArray<string>;
var
  list: TArray<string>;
  res: TArray<string>;
begin
  res := [];
  for var pair in FMissionWeights do
  begin
    list := pair.Value.GetNames;
    for var s in list do
      if not (s in res) then
        res := res + [s];
  end;
  Result := res;
end;

function TRuleMissionScript.GetRegions(Month: Integer): TArray<string>;
var
  i: Integer;
begin
  for i := High(FRegionWeights) downto 0 do
    if Month >= FRegionWeights[i].Key then
      Exit(FRegionWeights[i].Value.GetNames);
  Result := [];
end;

function TRuleMissionScript.GetMissionTypes(Month: Integer): TArray<string>;
var
  i: Integer;
begin
  for i := High(FMissionWeights) downto 0 do
    if Month >= FMissionWeights[i].Key then
      Exit(FMissionWeights[i].Value.GetNames);
  Result := [];
end;

function TRuleMissionScript.GetFirstMonth: Integer;
begin
  Result := FFirstMonth;
end;

function TRuleMissionScript.GetLastMonth: Integer;
begin
  Result := FLastMonth;
end;

function TRuleMissionScript.GetLabel: Integer;
begin
  Result := FLabel;
end;

function TRuleMissionScript.GetExecutionOdds: Integer;
begin
  Result := FExecutionOdds;
end;

function TRuleMissionScript.GetTargetBaseOdds: Integer;
begin
  Result := FTargetBaseOdds;
end;

function TRuleMissionScript.GetMinDifficulty: Integer;
begin
  Result := FMinDifficulty;
end;

function TRuleMissionScript.GetMaxRuns: Integer;
begin
  Result := FMaxRuns;
end;

function TRuleMissionScript.GetRepeatAvoidance: Integer;
begin
  Result := FAvoidRepeats;
end;

function TRuleMissionScript.GetDelay: Integer;
begin
  Result := FDelay;
end;

function TRuleMissionScript.GetConditionals: TArray<Integer>;
begin
  Result := FConditionals;
end;

function TRuleMissionScript.HasRaceWeights: Boolean;
begin
  Result := Length(FRaceWeights) > 0;
end;

function TRuleMissionScript.HasMissionWeights: Boolean;
begin
  Result := Length(FMissionWeights) > 0;
end;

function TRuleMissionScript.HasRegionWeights: Boolean;
begin
  Result := Length(FRegionWeights) > 0;
end;

function TRuleMissionScript.GetResearchTriggers: TDictionary<string, Boolean>;
begin
  Result := FResearchTriggers;
end;

function TRuleMissionScript.GetUseTable: Boolean;
begin
  Result := FUseTable;
end;

procedure TRuleMissionScript.SetSiteType(ASiteType: Boolean);
begin
  FSiteType := ASiteType;
end;

function TRuleMissionScript.GetSiteType: Boolean;
begin
  Result := FSiteType;
end;

function TRuleMissionScript.Generate(MonthsPassed: Integer; GenType: TGenerationType): string;
var
  weights: TArray<TPair<Integer, TWeightedOptions>>;
  i: Integer;
begin
  case GenType of
    genRegion: weights := FRegionWeights;
    genMission: weights := FMissionWeights;
    genRace: weights := FRaceWeights;
  else
    Exit('');
  end;
  for i := High(weights) downto 0 do
    if MonthsPassed >= weights[i].Key then
      Exit(weights[i].Value.Choose);
  Result := '';
end;

end.