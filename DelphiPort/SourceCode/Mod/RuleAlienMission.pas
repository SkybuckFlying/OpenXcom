unit RuleAlienMission;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, Savegame.WeightedOptions;

type
  TMissionWave = record
    UfoType: string;
    UfoCount: Integer;
    Trajectory: string;
    SpawnTimer: Integer;
    Objective: Boolean;
  end;

  TMissionObjective = (moScore, moInfiltration, moBase, moSite, moRetaliation, moSupply);

  TRuleAlienMission = class
  private
    FType: string;
    FPoints: Integer;
    FObjective: TMissionObjective;
    FSpawnUfo: string;
    FSpawnZone: Integer;
    FRetaliationOdds: Integer;
    FSiteType: string;
    FWaves: TArray<TMissionWave>;
    FWeights: TDictionary<Integer, Integer>; // month -> weight
    FRaceDistribution: TArray<TPair<Integer, TWeightedOptions>>; // month -> WeightedOptions
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GenerateRace(MonthsPassed: Integer): string;
    function GetPoints: Integer;
    function GetObjective: TMissionObjective;
    function GetSpawnUfo: string;
    function GetSpawnZone: Integer;
    function GetWeight(MonthsPassed: Integer): Integer;
    function GetRetaliationOdds: Integer;
    function GetSiteType: string;
    function GetWaveCount: Integer;
    function GetWave(Index: Integer): TMissionWave;
    function GetType: string;
  end;

implementation

{ TRuleAlienMission }

constructor TRuleAlienMission.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FPoints := 0;
  FObjective := moScore;
  FSpawnZone := -1;
  FRetaliationOdds := -1;
  FWeights := TDictionary<Integer, Integer>.Create;
end;

destructor TRuleAlienMission.Destroy;
begin
  FWeights.Free;
  for var pair in FRaceDistribution do
    pair.Value.Free;
  inherited;
end;

procedure TRuleAlienMission.Load(const Node: TYamlNode);
begin
  FType := Node['type'].AsString(FType);
  FPoints := Node['points'].AsInteger(FPoints);
  FWaves := Node['waves'].AsArray<TMissionWave>(FWaves);
  FObjective := TMissionObjective(Node['objective'].AsInteger(Integer(FObjective)));
  FSpawnUfo := Node['spawnUfo'].AsString(FSpawnUfo);
  FSpawnZone := Node['spawnZone'].AsInteger(FSpawnZone);
  FRetaliationOdds := Node['retaliationOdds'].AsInteger(FRetaliationOdds);
  FSiteType := Node['siteType'].AsString(FSiteType);

  // Load weights
  var wNode := Node['missionWeights'];
  if not wNode.IsNull then
  begin
    FWeights.Clear;
    for var kv in wNode do
      FWeights.Add(kv.Key.AsInteger, kv.Value.AsInteger);
  end;

  // Load race distribution
  var rNode := Node['raceWeights'];
  if not rNode.IsNull then
  begin
    // Clear old distribution
    for var pair in FRaceDistribution do
      pair.Value.Free;
    FRaceDistribution := [];
    for var kv in rNode do
    begin
      var wo := TWeightedOptions.Create;
      wo.Load(kv.Value);
      FRaceDistribution := FRaceDistribution + [TPair<Integer, TWeightedOptions>.Create(kv.Key.AsInteger, wo)];
    end;
  end;
end;

function TRuleAlienMission.GenerateRace(MonthsPassed: Integer): string;
var
  i: Integer;
begin
  for i := High(FRaceDistribution) downto 0 do
    if MonthsPassed >= FRaceDistribution[i].Key then
      Exit(FRaceDistribution[i].Value.Choose);
  Result := '';
end;

function TRuleAlienMission.GetPoints: Integer;
begin
  Result := FPoints;
end;

function TRuleAlienMission.GetObjective: TMissionObjective;
begin
  Result := FObjective;
end;

function TRuleAlienMission.GetSpawnUfo: string;
begin
  Result := FSpawnUfo;
end;

function TRuleAlienMission.GetSpawnZone: Integer;
begin
  Result := FSpawnZone;
end;

function TRuleAlienMission.GetWeight(MonthsPassed: Integer): Integer;
var
  maxKey: Integer;
begin
  Result := 0;
  maxKey := -1;
  for var kv in FWeights do
    if (kv.Key <= MonthsPassed) and (kv.Key > maxKey) then
    begin
      maxKey := kv.Key;
      Result := kv.Value;
    end;
  if FWeights.Count = 0 then
    Result := 1;
end;

function TRuleAlienMission.GetRetaliationOdds: Integer;
begin
  Result := FRetaliationOdds;
end;

function TRuleAlienMission.GetSiteType: string;
begin
  Result := FSiteType;
end;

function TRuleAlienMission.GetWaveCount: Integer;
begin
  Result := Length(FWaves);
end;

function TRuleAlienMission.GetWave(Index: Integer): TMissionWave;
begin
  Result := FWaves[Index];
end;

function TRuleAlienMission.GetType: string;
begin
  Result := FType;
end;

end.