unit RuleConverter;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml;

type
  TRuleConverter = class
  private
    FOffsets: TDictionary<string, Integer>;
    FMarkers: TArray<string>;
    FCountries: TArray<string>;
    FRegions: TArray<string>;
    FFacilities: TArray<string>;
    FItems: TArray<string>;
    FCrews: TArray<string>;
    FCrafts: TArray<string>;
    FUfos: TArray<string>;
    FCraftWeapons: TArray<string>;
    FMissions: TArray<string>;
    FArmor: TArray<string>;
    FAlienRaces: TArray<string>;
    FAlienRanks: TArray<string>;
    FResearch: TArray<string>;
    FManufacture: TArray<string>;
    FUfopaedia: TArray<string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GetOffset(const Id: string): Integer;
    function GetMarkers: TArray<string>;
    function GetCountries: TArray<string>;
    function GetRegions: TArray<string>;
    function GetFacilities: TArray<string>;
    function GetItems: TArray<string>;
    function GetCrews: TArray<string>;
    function GetCrafts: TArray<string>;
    function GetUfos: TArray<string>;
    function GetCraftWeapons: TArray<string>;
    function GetMissions: TArray<string>;
    function GetArmor: TArray<string>;
    function GetAlienRaces: TArray<string>;
    function GetAlienRanks: TArray<string>;
    function GetResearch: TArray<string>;
    function GetManufacture: TArray<string>;
    function GetUfopaedia: TArray<string>;
  end;

implementation

{ TRuleConverter }

constructor TRuleConverter.Create;
begin
  inherited Create;
  FOffsets := TDictionary<string, Integer>.Create;
end;

destructor TRuleConverter.Destroy;
begin
  FOffsets.Free;
  inherited;
end;

procedure TRuleConverter.Load(const Node: TYamlNode);
begin
  var offNode := Node['offsets'];
  if not offNode.IsNull then
  begin
    FOffsets.Clear;
    for var kv in offNode do
      FOffsets.Add(kv.Key.AsString, kv.Value.AsInteger);
  end;
  FMarkers := Node['markers'].AsArray<string>(FMarkers);
  FCountries := Node['countries'].AsArray<string>(FCountries);
  FRegions := Node['regions'].AsArray<string>(FRegions);
  FFacilities := Node['facilities'].AsArray<string>(FFacilities);
  FItems := Node['items'].AsArray<string>(FItems);
  FCrews := Node['crews'].AsArray<string>(FCrews);
  FCrafts := Node['crafts'].AsArray<string>(FCrafts);
  FUfos := Node['ufos'].AsArray<string>(FUfos);
  FCraftWeapons := Node['craftWeapons'].AsArray<string>(FCraftWeapons);
  FMissions := Node['missions'].AsArray<string>(FMissions);
  FArmor := Node['armor'].AsArray<string>(FArmor);
  FAlienRaces := Node['alienRaces'].AsArray<string>(FAlienRaces);
  FAlienRanks := Node['alienRanks'].AsArray<string>(FAlienRanks);
  FResearch := Node['research'].AsArray<string>(FResearch);
  FManufacture := Node['manufacture'].AsArray<string>(FManufacture);
  FUfopaedia := Node['ufopaedia'].AsArray<string>(FUfopaedia);
end;

function TRuleConverter.GetOffset(const Id: string): Integer;
begin
  FOffsets.TryGetValue(Id, Result);
end;

function TRuleConverter.GetMarkers: TArray<string>;
begin
  Result := FMarkers;
end;

function TRuleConverter.GetCountries: TArray<string>;
begin
  Result := FCountries;
end;

function TRuleConverter.GetRegions: TArray<string>;
begin
  Result := FRegions;
end;

function TRuleConverter.GetFacilities: TArray<string>;
begin
  Result := FFacilities;
end;

function TRuleConverter.GetItems: TArray<string>;
begin
  Result := FItems;
end;

function TRuleConverter.GetCrews: TArray<string>;
begin
  Result := FCrews;
end;

function TRuleConverter.GetCrafts: TArray<string>;
begin
  Result := FCrafts;
end;

function TRuleConverter.GetUfos: TArray<string>;
begin
  Result := FUfos;
end;

function TRuleConverter.GetCraftWeapons: TArray<string>;
begin
  Result := FCraftWeapons;
end;

function TRuleConverter.GetMissions: TArray<string>;
begin
  Result := FMissions;
end;

function TRuleConverter.GetArmor: TArray<string>;
begin
  Result := FArmor;
end;

function TRuleConverter.GetAlienRaces: TArray<string>;
begin
  Result := FAlienRaces;
end;

function TRuleConverter.GetAlienRanks: TArray<string>;
begin
  Result := FAlienRanks;
end;

function TRuleConverter.GetResearch: TArray<string>;
begin
  Result := FResearch;
end;

function TRuleConverter.GetManufacture: TArray<string>;
begin
  Result := FManufacture;
end;

function TRuleConverter.GetUfopaedia: TArray<string>;
begin
  Result := FUfopaedia;
end;

end.