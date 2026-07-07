unit Texture;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, Savegame.Target, Engine.RNG, fmath;

type
  TTerrainCriteria = record
    Name: string;
    Weight: Integer;
    LonMin, LonMax, LatMin, LatMax: Double;
  end;

  TTexture = class
  private
    FId: Integer;
    FDeployments: TDictionary<string, Integer>;
    FTerrain: TArray<TTerrainCriteria>;
  public
    constructor Create(AId: Integer);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GetTerrain: TArray<TTerrainCriteria>;
    function GetRandomTerrain(Target: TTarget): string;
    function GetDeployments: TDictionary<string, Integer>;
    function GetRandomDeployment: string;
  end;

implementation

{ TTexture }

constructor TTexture.Create(AId: Integer);
begin
  inherited Create;
  FId := AId;
  FDeployments := TDictionary<string, Integer>.Create;
end;

destructor TTexture.Destroy;
begin
  FDeployments.Free;
  inherited;
end;

procedure TTexture.Load(const Node: TYamlNode);
begin
  FId := Node['id'].AsInteger(FId);
  FDeployments.Clear;
  var depNode := Node['deployments'];
  if not depNode.IsNull then
    for var kv in depNode do
      FDeployments.Add(kv.Key.AsString, kv.Value.AsInteger);
  FTerrain := Node['terrain'].AsArray<TTerrainCriteria>(FTerrain);
end;

function TTexture.GetTerrain: TArray<TTerrainCriteria>;
begin
  Result := FTerrain;
end;

function TTexture.GetRandomTerrain(Target: TTarget): string;
var
  totalWeight: Integer;
  possibilities: TDictionary<Integer, string>;
  pick: Integer;
begin
  totalWeight := 0;
  possibilities := TDictionary<Integer, string>.Create;
  try
    for var crit in FTerrain do
    begin
      if (crit.Weight > 0) and
         (Target.GetLongitude >= crit.LonMin) and (Target.GetLongitude < crit.LonMax) and
         (Target.GetLatitude >= crit.LatMin) and (Target.GetLatitude < crit.LatMax) then
      begin
        Inc(totalWeight, crit.Weight);
        possibilities.Add(totalWeight, crit.Name);
      end;
    end;
    if totalWeight > 0 then
    begin
      pick := RNG.Generate(1, totalWeight);
      for var kv in possibilities do
        if pick <= kv.Key then
          Exit(kv.Value);
    end;
  finally
    possibilities.Free;
  end;
  Result := '';
end;

function TTexture.GetDeployments: TDictionary<string, Integer>;
begin
  Result := FDeployments;
end;

function TTexture.GetRandomDeployment: string;
var
  totalWeight: Integer;
  pick: Integer;
begin
  if FDeployments.Count = 0 then Exit('');
  if FDeployments.Count = 1 then
  begin
    var pair := FDeployments.ToArray[0];
    Exit(pair.Key);
  end;
  totalWeight := 0;
  for var kv in FDeployments do Inc(totalWeight, kv.Value);
  if totalWeight >= 1 then
  begin
    pick := RNG.Generate(1, totalWeight);
    for var kv in FDeployments do
    begin
      if pick <= kv.Value then
        Exit(kv.Key)
      else
        Dec(pick, kv.Value);
    end;
  end;
  Result := '';
end;

end.