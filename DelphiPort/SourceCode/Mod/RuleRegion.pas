unit RuleRegion;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, City, fmath, Engine.RNG, Savegame.WeightedOptions;

type
  TMissionArea = record
    LonMin, LonMax, LatMin, LatMax: Double;
    Texture: Integer;
    Name: string;
    function IsPoint: Boolean;
  end;

  TMissionZone = record
    Areas: TArray<TMissionArea>;
  end;

  TRuleRegion = class
  private
    FType: string;
    FCost: Integer;
    FLonMin, FLonMax, FLatMin, FLatMax: TArray<Double>;
    FCities: TArray<TCity>;
    FMissionWeights: TWeightedOptions;
    FRegionWeight: Integer;
    FMissionZones: TArray<TMissionZone>;
    FMissionRegion: string;
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GetType: string;
    function GetBaseCost: Integer;
    function InsideRegion(Lon, Lat: Double): Boolean;
    function GetCities: TArray<TCity>;
    function GetWeight: Integer;
    function GetAvailableMissions: TWeightedOptions;
    function GetMissionRegion: string;
    function GetRandomPoint(Zone: Integer): TPair<Double, Double>;
    function GetMissionZones: TArray<TMissionZone>;
    function GetLonMin: TArray<Double>;
    function GetLonMax: TArray<Double>;
    function GetLatMin: TArray<Double>;
    function GetLatMax: TArray<Double>;
  end;

implementation

{ TMissionArea }
function TMissionArea.IsPoint: Boolean;
begin
  Result := (Abs(LonMin - LonMax) < 1e-9) and (Abs(LatMin - LatMax) < 1e-9);
end;

{ TRuleRegion }

constructor TRuleRegion.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FCost := 0;
  FRegionWeight := 0;
end;

destructor TRuleRegion.Destroy;
begin
  for var city in FCities do city.Free;
  inherited;
end;

procedure TRuleRegion.Load(const Node: TYamlNode);
var
  areas: TArray<TArray<Double>>;
  i: Integer;
begin
  FType := Node['type'].AsString(FType);
  FCost := Node['cost'].AsInteger(FCost);
  areas := Node['areas'].AsArray<TArray<Double>>;
  SetLength(FLonMin, Length(areas));
  SetLength(FLonMax, Length(areas));
  SetLength(FLatMin, Length(areas));
  SetLength(FLatMax, Length(areas));
  for i := 0 to High(areas) do
  begin
    FLonMin[i] := Deg2Rad(areas[i][0]);
    FLonMax[i] := Deg2Rad(areas[i][1]);
    FLatMin[i] := Deg2Rad(areas[i][2]);
    FLatMax[i] := Deg2Rad(areas[i][3]);
    if FLatMin[i] > FLatMax[i] then
    begin
      var tmp := FLatMin[i];
      FLatMin[i] := FLatMax[i];
      FLatMax[i] := tmp;
    end;
  end;
  FMissionZones := Node['missionZones'].AsArray<TMissionZone>(FMissionZones);
  if Node.Has('missionWeights') then
    FMissionWeights.Load(Node['missionWeights']);
  FRegionWeight := Node['regionWeight'].AsInteger(FRegionWeight);
  FMissionRegion := Node['missionRegion'].AsString(FMissionRegion);
end;

function TRuleRegion.GetType: string;
begin
  Result := FType;
end;

function TRuleRegion.GetBaseCost: Integer;
begin
  Result := FCost;
end;

function TRuleRegion.InsideRegion(Lon, Lat: Double): Boolean;
var
  i: Integer;
  inLon, inLat: Boolean;
begin
  for i := 0 to High(FLonMin) do
  begin
    if FLonMin[i] <= FLonMax[i] then
      inLon := (Lon >= FLonMin[i]) and (Lon < FLonMax[i])
    else
      inLon := ((Lon >= FLonMin[i]) and (Lon < 2*Pi)) or ((Lon >= 0) and (Lon < FLonMax[i]));
    if Lat > 0 then
      inLat := (Lat > FLatMin[i]) and (Lat <= FLatMax[i])
    else
      inLat := (Lat >= FLatMin[i]) and (Lat < FLatMax[i]);
    if inLon and inLat then
      Exit(True);
  end;
  Result := False;
end;

function TRuleRegion.GetCities: TArray<TCity>;
begin
  if Length(FCities) = 0 then
  begin
    for var zone in FMissionZones do
      for var area in zone.Areas do
        if area.IsPoint and not area.Name.IsEmpty then
          FCities := FCities + [TCity.Create(area.Name, area.LonMin, area.LatMin)];
  end;
  Result := FCities;
end;

function TRuleRegion.GetWeight: Integer;
begin
  Result := FRegionWeight;
end;

function TRuleRegion.GetAvailableMissions: TWeightedOptions;
begin
  Result := FMissionWeights;
end;

function TRuleRegion.GetMissionRegion: string;
begin
  Result := FMissionRegion;
end;

function TRuleRegion.GetRandomPoint(Zone: Integer): TPair<Double, Double>;
var
  idx: Integer;
  area: TMissionArea;
  lon, lat: Double;
begin
  if (Zone >= 0) and (Zone < Length(FMissionZones)) then
  begin
    idx := RNG.Generate(0, Length(FMissionZones[Zone].Areas) - 1);
    area := FMissionZones[Zone].Areas[idx];
    if area.LonMin > area.LonMax then
    begin
      var tmp := area.LonMin;
      area.LonMin := area.LonMax;
      area.LonMax := tmp;
    end;
    if area.LatMin > area.LatMax then
    begin
      var tmp := area.LatMin;
      area.LatMin := area.LatMax;
      area.LatMax := tmp;
    end;
    lon := RNG.Generate(area.LonMin, area.LonMax);
    lat := RNG.Generate(area.LatMin, area.LatMax);
    Result := TPair<Double, Double>.Create(lon, lat);
  end
  else
    Result := TPair<Double, Double>.Create(0, 0);
end;

function TRuleRegion.GetMissionZones: TArray<TMissionZone>;
begin
  Result := FMissionZones;
end;

function TRuleRegion.GetLonMin: TArray<Double>; begin Result := FLonMin; end;
function TRuleRegion.GetLonMax: TArray<Double>; begin Result := FLonMax; end;
function TRuleRegion.GetLatMin: TArray<Double>; begin Result := FLatMin; end;
function TRuleRegion.GetLatMax: TArray<Double>; begin Result := FLatMax; end;

end.