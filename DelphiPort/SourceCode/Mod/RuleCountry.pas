unit RuleCountry;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, fmath, Engine.RNG;

type
  TRuleCountry = class
  private
    FType: string;
    FFundingBase: Integer;
    FFundingCap: Integer;
    FLabelLon: Double;
    FLabelLat: Double;
    FLonMin, FLonMax, FLatMin, FLatMax: TArray<Double>;
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GetType: string;
    function GenerateFunding: Integer;
    function GetFundingCap: Integer;
    function GetLabelLongitude: Double;
    function GetLabelLatitude: Double;
    function InsideCountry(Lon, Lat: Double): Boolean;
    function GetLonMin: TArray<Double>;
    function GetLonMax: TArray<Double>;
    function GetLatMin: TArray<Double>;
    function GetLatMax: TArray<Double>;
  end;

implementation

{ TRuleCountry }

constructor TRuleCountry.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FFundingBase := 0;
  FFundingCap := 0;
  FLabelLon := 0;
  FLabelLat := 0;
end;

destructor TRuleCountry.Destroy;
begin
  inherited;
end;

procedure TRuleCountry.Load(const Node: TYamlNode);
var
  areas: TArray<TArray<Double>>;
  i: Integer;
begin
  FType := Node['type'].AsString(FType);
  FFundingBase := Node['fundingBase'].AsInteger(FFundingBase);
  FFundingCap := Node['fundingCap'].AsInteger(FFundingCap);
  if Node.Has('labelLon') then
    FLabelLon := Deg2Rad(Node['labelLon'].AsDouble);
  if Node.Has('labelLat') then
    FLabelLat := Deg2Rad(Node['labelLat'].AsDouble);
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
end;

function TRuleCountry.GetType: string;
begin
  Result := FType;
end;

function TRuleCountry.GenerateFunding: Integer;
begin
  Result := RNG.Generate(FFundingBase, FFundingBase * 2) * 1000;
end;

function TRuleCountry.GetFundingCap: Integer;
begin
  Result := FFundingCap;
end;

function TRuleCountry.GetLabelLongitude: Double;
begin
  Result := FLabelLon;
end;

function TRuleCountry.GetLabelLatitude: Double;
begin
  Result := FLabelLat;
end;

function TRuleCountry.InsideCountry(Lon, Lat: Double): Boolean;
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

function TRuleCountry.GetLonMin: TArray<Double>;
begin
  Result := FLonMin;
end;

function TRuleCountry.GetLonMax: TArray<Double>;
begin
  Result := FLonMax;
end;

function TRuleCountry.GetLatMin: TArray<Double>;
begin
  Result := FLatMin;
end;

function TRuleCountry.GetLatMax: TArray<Double>;
begin
  Result := FLatMax;
end;

end.