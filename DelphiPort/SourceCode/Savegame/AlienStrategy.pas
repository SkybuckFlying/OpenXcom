unit AlienStrategy;

interface

uses
  Classes, SysUtils, Generics.Collections, YAML, WeightedOptions, Mod, RuleRegion;

type
  TAlienStrategy = class
  private
    FRegionChances: TWeightedOptions;
    FRegionMissions: TDictionary<string, TWeightedOptions>;
    FMissionRuns: TDictionary<string, Integer>;
    FMissionLocations: TDictionary<string, TArray<TPair<string, Integer>>>;
    procedure Init(Mod: TMod);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function Save: TYamlNode;
    function ChooseRandomRegion(Mod: TMod): string;
    function ChooseRandomMission(const Region: string): string;
    function RemoveMission(const Region, Mission: string): Boolean;
    function GetMissionsRun(const VarName: string): Integer;
    procedure AddMissionRun(const VarName: string; Increment: Integer = 1);
    procedure AddMissionLocation(const VarName, RegionName: string; ZoneNumber, Maximum: Integer);
    function ValidMissionLocation(const VarName, RegionName: string; ZoneNumber: Integer): Boolean;
    function ValidMissionRegion(const Region: string): Boolean;
  end;

implementation

uses
  RNG, Assert;

constructor TAlienStrategy.Create;
begin
  FRegionChances := TWeightedOptions.Create;
  FRegionMissions := TDictionary<string, TWeightedOptions>.Create;
  FMissionRuns := TDictionary<string, Integer>.Create;
  FMissionLocations := TDictionary<string, TArray<TPair<string, Integer>>>.Create;
end;

destructor TAlienStrategy.Destroy;
begin
  FRegionChances.Free;
  for var pair in FRegionMissions do
    pair.Value.Free;
  FRegionMissions.Free;
  FMissionRuns.Free;
  FMissionLocations.Free;
  inherited;
end;

procedure TAlienStrategy.Init(Mod: TMod);
begin
  var regions := Mod.RegionsList;
  for var r in regions do
  begin
    var region := Mod.GetRegion(r);
    FRegionChances.SetOption(r, region.Weight);
    var missions := TWeightedOptions.Create;
    missions.Load(region.AvailableMissions); // assuming YAML node
    FRegionMissions.Add(r, missions);
  end;
end;

procedure TAlienStrategy.Load(const Node: TYamlNode);
begin
  for var pair in FRegionMissions do
    pair.Value.Free;
  FRegionMissions.Clear;
  FRegionChances.Clear;
  FRegionChances.Load(Node['regions']);
  var strat := Node['possibleMissions'];
  for var n in strat do
  begin
    var region := n['region'].AsString;
    var missions := TWeightedOptions.Create;
    missions.Load(n['missions']);
    FRegionMissions.Add(region, missions);
  end;
  FMissionLocations := Node['missionLocations'].As<TDictionary<string, TArray<TPair<string, Integer>>>>;
  FMissionRuns := Node['missionsRun'].As<TDictionary<string, Integer>>;
end;

function TAlienStrategy.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['regions'] := FRegionChances.Save;
  for var pair in FRegionMissions do
  begin
    var sub := TYamlNode.Create;
    sub['region'] := pair.Key;
    sub['missions'] := pair.Value.Save;
    Result['possibleMissions'].Add(sub);
  end;
  Result['missionLocations'] := FMissionLocations.ToYaml;
  Result['missionsRun'] := FMissionRuns.ToYaml;
end;

function TAlienStrategy.ChooseRandomRegion(Mod: TMod): string;
begin
  Result := FRegionChances.Choose;
  if Result = '' then
  begin
    for var pair in FRegionMissions do
      pair.Value.Free;
    FRegionMissions.Clear;
    Init(Mod);
    Result := FRegionChances.Choose;
  end;
  Assert(Result <> '');
end;

function TAlienStrategy.ChooseRandomMission(const Region: string): string;
begin
  var found := FRegionMissions[Region];
  Assert(found <> nil);
  Result := found.Choose;
end;

function TAlienStrategy.RemoveMission(const Region, Mission: string): Boolean;
begin
  var found := FRegionMissions[Region];
  if found <> nil then
  begin
    found.SetOption(Mission, 0);
    if found.IsEmpty then
    begin
      FRegionMissions.Remove(Region);
      FRegionChances.SetOption(Region, 0);
    end;
  end;
  Result := FRegionMissions.Count = 0;
end;

function TAlienStrategy.GetMissionsRun(const VarName: string): Integer;
begin
  if not FMissionRuns.TryGetValue(VarName, Result) then
    Result := 0;
end;

procedure TAlienStrategy.AddMissionRun(const VarName: string; Increment: Integer);
begin
  if VarName = '' then Exit;
  var val := GetMissionsRun(VarName);
  FMissionRuns.AddOrSet(VarName, val + Increment);
end;

procedure TAlienStrategy.AddMissionLocation(const VarName, RegionName: string; ZoneNumber, Maximum: Integer);
begin
  if Maximum <= 0 then Exit;
  var arr: TArray<TPair<string, Integer>>;
  if not FMissionLocations.TryGetValue(VarName, arr) then
    arr := [];
  SetLength(arr, Length(arr) + 1);
  arr[High(arr)] := TPair<string, Integer>.Create(RegionName, ZoneNumber);
  if Length(arr) > Maximum then
    Delete(arr, 0, 1);
  FMissionLocations.AddOrSet(VarName, arr);
end;

function TAlienStrategy.ValidMissionLocation(const VarName, RegionName: string; ZoneNumber: Integer): Boolean;
begin
  var arr: TArray<TPair<string, Integer>>;
  if FMissionLocations.TryGetValue(VarName, arr) then
    for var pair in arr do
      if (pair.Key = RegionName) and (pair.Value = ZoneNumber) then
        Exit(False);
  Result := True;
end;

function TAlienStrategy.ValidMissionRegion(const Region: string): Boolean;
begin
  Result := FRegionMissions.ContainsKey(Region);
end;

end.